mcl_minecarts.speed_max = 10
mcl_minecarts.check_float_time = 15
mcl_minecarts.passenger_attach_position = vector.new(0, -1.75, 0)

local function hopper_take_item(self)
	local pos = self.object:get_pos()
	if not pos then return end

	if not self or self.name ~= "mcl_minecarts:hopper_minecart" then return end

	local above_pos = vector.offset(pos, 0, 0.9, 0)

	for v in core.objects_inside_radius(above_pos, 1.25) do
		local ent = v:get_luaentity()
		local taken_items = false

		if ent and not ent._removed and ent.itemstring and ent.itemstring ~= "" then
			local inv = mcl_entity_invs.load_inv(self, 5)
			if not inv then	return false end

			local current_itemstack = ItemStack(ent.itemstring)

			if inv:room_for_item("main", current_itemstack) then
				inv:add_item("main", current_itemstack)
				v:get_luaentity().itemstring = ""
				v:remove()
				taken_items = true
			end

			if not taken_items then
				local items_remaining = current_itemstack:get_count()
				for i = 1, self._inv_size, 1 do
					local stack = inv:get_stack("main", i)

					if current_itemstack:get_name() == stack:get_name() then
						local room_for = stack:get_stack_max() - stack:get_count()
						if room_for < items_remaining then
							items_remaining = items_remaining - room_for
							stack:set_count(stack:get_stack_max())
							inv:set_stack("main", i, stack)
							taken_items = true
						elseif room_for ~= 0 then --do nothing if 0
							local new_stack_size = stack:get_count() + items_remaining
							stack:set_count(new_stack_size)
							inv:set_stack("main", i, stack)
							v:get_luaentity().itemstring = ""
							v:remove()
							taken_items = true
							break
						end
					end

					if i == self._inv_size and taken_items then
						current_itemstack:set_count(items_remaining)
						ent.itemstring = current_itemstack:to_string()
					end
				end
			end
		end

		if taken_items then
			mcl_entity_invs.save_inv(ent)
			return taken_items
		end
	end

	return false
end

mcl_minecarts.tpl_entity = {
	initial_properties = {
		physical = false,
		collisionbox = {-10/16, -8/16 -10/16, 10/16, 4/16, 10/16},
		visual = "mesh",
	},

	_driver = nil, -- player who sits in and controls the minecart (only for minecart!)
	_passenger = nil, -- for mobs
	_punched = false, -- used to re-send _velocity and position
	_velocity = vector.zero(), -- only used on punch
	_start_pos = nil, -- Used to calculate distance for “On A Rail” achievement
	_last_float_check = nil, -- timestamp of last time the cart was checked to be still on a rail
	_fueltime = nil, -- how many seconds worth of fuel is left. Only used by minecart with furnace
	_boomtimer = nil, -- how many seconds are left before exploding
	_blinktimer = nil, -- how many seconds are left before TNT blinking
	_blink = false, -- is TNT blink texture active?
	_old_dir = vector.zero(),
	_old_pos = nil,
	_old_vel = vector.zero(),
	_old_switch = 0,
	_railtype = nil,
	_mcl_fishing_hookable = true,
	_mcl_fishing_reelable = true,
}

function mcl_minecarts.tpl_entity:on_activate(staticdata, _)
	-- Initialize
	local data = core.deserialize(staticdata)
	if type(data) == "table" then
		self._railtype = data._railtype
		self._passenger = data._passenger
	end
	self.object:set_armor_groups({immortal=1})

	-- Activate cart if on activator rail
	if self._on_activate_by_rail then
		local pos = self.object:get_pos()
		local node = core.get_node(vector.floor(pos))
		if node.name == "mcl_minecarts:activator_rail_on" then
			self:_on_activate_by_rail()
		end
	end
end

function mcl_minecarts.tpl_entity:on_punch(puncher, time_from_last_punch, tool_capabilities, _)
	local pos = self.object:get_pos()
	if not self._railtype then
		local node = core.get_node(vector.floor(pos)).name
		self._railtype = core.get_item_group(node, "connect_to_raillike")
	end

	if not puncher or not puncher:is_player() then
		local cart_dir = mcl_minecarts.get_rail_direction(pos, vector.new(1, 0, 0), nil, nil, self._railtype)
		if vector.equals(cart_dir, vector.zero()) then
			return
		end
		mcl_minecarts.set_velocity(self, cart_dir)
		return
	end

	-- Punch+sneak: Pick up minecart (unless TNT was ignited)
	if puncher:get_player_control().sneak and not self._boomtimer then
		if self._driver then
			if self._old_pos then
				self.object:set_pos(self._old_pos)
			end
			mcl_minecarts.detach_driver(self)
		end

		-- Disable detector rail
		local rou_pos = vector.round(pos)
		local node = core.get_node(rou_pos)
		if node.name == "mcl_minecarts:detector_rail_on" then
			local newnode = {name="mcl_minecarts:detector_rail", param2 = node.param2}
			mcl_redstone.swap_node(rou_pos, newnode)
		end

		-- Drop items and remove cart entity
		local drops = self._drop
		if not core.is_creative_enabled(puncher:get_player_name()) then
			for _, drop in ipairs(drops) do
				core.add_item(self.object:get_pos(), drop)
			end
			if self._on_destroy_minecart then
				self:_on_destroy_minecart(puncher)
			end
		elseif puncher and puncher:is_player() then
			local inv = puncher:get_inventory()
			for _, drop in ipairs(drops) do
				if not inv:contains_item("main", drop) then
					inv:add_item("main", drop)
				end
			end
		end

		self.object:remove()
		return
	end

	local vel = self.object:get_velocity()
	if puncher:get_player_name() == self._driver then
		if math.abs(vel.x + vel.z) > 7 then
			return
		end
	end

	local punch_dir = mcl_minecarts.velocity_to_dir(puncher:get_look_dir())
	punch_dir.y = 0
	local cart_dir = mcl_minecarts.get_rail_direction(pos, punch_dir, nil, nil, self._railtype)
	if vector.equals(cart_dir, vector.zero()) then
		return
	end

	time_from_last_punch = math.min(time_from_last_punch, tool_capabilities.full_punch_interval)
	local f = 3 * (time_from_last_punch / tool_capabilities.full_punch_interval)

	mcl_minecarts.set_velocity(self, cart_dir, f)
end

function mcl_minecarts.tpl_entity:on_step(dtime)
	hopper_take_item(self)

	local ctrl, player = nil, nil
	if self._driver then
		player = core.get_player_by_name(self._driver)
		if player then
			ctrl = player:get_player_control()
			-- player detach
			if ctrl.sneak then
				mcl_minecarts.detach_driver(self)
				return
			end
		end
	end

	local vel = self.object:get_velocity()
	local update = {}
	if self._last_float_check == nil then
		self._last_float_check = 0
	else
		self._last_float_check = self._last_float_check + dtime
	end

	local pos, rou_pos, node = self.object:get_pos()
	local drops = self._drop
	local r = 0.6
	for _, node_pos in pairs({{r, 0}, {0, r}, {-r, 0}, {0, -r}}) do
		if core.get_node(vector.offset(pos, node_pos[1], 0, node_pos[2])).name == "mcl_core:cactus" then
			mcl_minecarts.detach_driver(self)
			for _, drop in ipairs(drops) do
				core.add_item(pos, drop)
			end
			self.object:remove()
			return
		end
	end

	-- Grab mob
	if math.random(1,20) > 15 and not self._passenger then
		if self.name == "mcl_minecarts:minecart" then
			for mob in core.objects_inside_radius(self.object:get_pos(), 1.3) do
				local entity = mob:get_luaentity()
				if entity and entity.is_mob and entity.can_ride_cart then
					self._passenger = entity
					mob:set_attach(self.object, "", mcl_minecarts.passenger_attach_position, vector.zero())
					mcl_attachments.spawn_attachment_entity(mob)
					break
				end
			end
		end
	elseif self._passenger then
		local passenger_pos = self._passenger.object:get_pos()
		if not passenger_pos then
			self._passenger = nil
		end
	end

	-- Drop minecart if it isn't on a rail anymore
	if self._last_float_check >= mcl_minecarts.check_float_time then
		pos = self.object:get_pos()
		rou_pos = vector.round(pos)
		node = core.get_node(rou_pos)
		local g = core.get_item_group(node.name, "connect_to_raillike")
		if g ~= self._railtype and self._railtype then
			-- Detach driver
			if player then
				if self._old_pos then
					self.object:set_pos(self._old_pos)
				end
				mcl_player.players[player].attached = nil
				player:set_detach()
			end

			-- Explode if already ignited
			if self._boomtimer then
				mcl_explosions.explode(pos, 4, {}, self.object)
				self.object:remove()
				return
			end

			-- Do not drop minecart. It goes off the rails too frequently, and anyone using them for farms won't
			-- notice and lose their iron and not bother. Not cool until fixed.
		end
		self._last_float_check = 0
	end

	-- Update furnace stuff
	if self._fueltime and self._fueltime > 0 then
		self._fueltime = self._fueltime - dtime
		if self._fueltime <= 0 then
			self.object:set_properties({textures = {
				"default_furnace_top.png",
				"default_furnace_top.png",
				"default_furnace_front.png",
				"default_furnace_side.png",
				"default_furnace_side.png",
				"default_furnace_side.png",
				"mcl_minecarts_minecart.png",
			}})
			self._fueltime = 0
		end
	end
	local has_fuel = self._fueltime and self._fueltime > 0

	-- Update TNT stuff
	if self._boomtimer then
		-- Explode
		self._boomtimer = self._boomtimer - dtime
		local pos = self.object:get_pos()
		if self._boomtimer <= 0 then
			mcl_explosions.explode(pos, 4, {}, self.object)
			self.object:remove()
			return
		else
			tnt.smoke_step(pos)
		end
	end
	if self._blinktimer then
		self._blinktimer = self._blinktimer - dtime
		if self._blinktimer <= 0 then
			self._blink = not self._blink
			if self._blink then
				self.object:set_properties({textures =
				{
				"default_tnt_top.png",
				"default_tnt_bottom.png",
				"default_tnt_side.png",
				"default_tnt_side.png",
				"default_tnt_side.png",
				"default_tnt_side.png",
				"mcl_minecarts_minecart.png",
				}})
			else
				self.object:set_properties({textures =
				{
				"mcl_tnt_blink.png",
				"mcl_tnt_blink.png",
				"mcl_tnt_blink.png",
				"mcl_tnt_blink.png",
				"mcl_tnt_blink.png",
				"mcl_tnt_blink.png",
				"mcl_minecarts_minecart.png",
				}})
			end
			self._blinktimer = tnt.BLINKTIMER
		end
	end

	if self._punched then
		vel = vector.add(vel, self._velocity)
		self.object:set_velocity(vel)
		self._old_dir.y = 0
	elseif vector.equals(vel, vector.zero()) and (not has_fuel) then
		return
	end

	local dir, last_switch, restart_pos = nil, nil, nil
	if not pos then
		pos = self.object:get_pos()
	end
	if self._old_pos and not self._punched then
		if not rou_pos then
			rou_pos = vector.round(pos)
		end
		local rou_old = vector.round(self._old_pos)
		if not node then
			node = core.get_node(rou_pos)
		end
		local node_old = core.get_node(rou_old)

		-- Update detector rails
		if node.name == "mcl_minecarts:detector_rail" then
			local newnode = {name="mcl_minecarts:detector_rail_on", param2 = node.param2}
			mcl_redstone.swap_node(rou_pos, newnode)
		end
		if node.name == "mcl_minecarts:golden_rail_on" then
			restart_pos = rou_pos
		end
		if node_old.name == "mcl_minecarts:detector_rail_on" then
			local newnode = {name="mcl_minecarts:detector_rail", param2 = node_old.param2}
			mcl_redstone.swap_node(rou_old, newnode)
		end
		-- Activate minecart if on activator rail
		if node_old.name == "mcl_minecarts:activator_rail_on" and self._on_activate_by_rail then
			self:_on_activate_by_rail()
		end
	end

	-- Stop cart if velocity vector flips
	if self._old_vel and self._old_vel.y == 0 and
			(self._old_vel.x * vel.x < 0 or self._old_vel.z * vel.z < 0) then
		self._old_vel = {x = 0, y = 0, z = 0}
		self._old_pos = pos
		self.object:set_velocity(vector.new())
		self.object:set_acceleration(vector.new())
		return
	end
	self._old_vel = vector.new(vel)

	if self._old_pos then
		local diff = vector.subtract(self._old_pos, pos)
		for _,v in ipairs({"x","y","z"}) do
			if math.abs(diff[v]) > 1.1 then
				local expected_pos = vector.add(self._old_pos, self._old_dir)
				dir, last_switch = mcl_minecarts.get_rail_direction(pos, self._old_dir, ctrl, self._old_switch, self._railtype)
				if vector.equals(dir, vector.zero()) then
					dir = false
					pos = vector.new(expected_pos)
					update.pos = true
				end
				break
			end
		end
	end

	if vel.y == 0 then
		for _,v in ipairs({"x", "z"}) do
			if vel[v] ~= 0 and math.abs(vel[v]) < 0.9 then
				vel[v] = 0
				update.vel = true
			end
		end
	end

	local cart_dir = mcl_minecarts.velocity_to_dir(vel)
	local max_vel = mcl_minecarts.speed_max
	if not dir then
		dir, last_switch = mcl_minecarts.get_rail_direction(
			pos,
			cart_dir,
			ctrl,
			self._old_switch,
			self._railtype
		)
	end

	local new_acc = vector.zero()
	if vector.equals(dir, vector.zero()) and not has_fuel then
		vel = vector.zero()
		update.vel = true
	else
		-- If the direction changed
		if dir.x ~= 0 and self._old_dir.z ~= 0 then
			vel.x = dir.x * math.abs(vel.z)
			vel.z = 0
			pos.z = math.floor(pos.z + 0.5)
			update.pos = true
		end
		if dir.z ~= 0 and self._old_dir.x ~= 0 then
			vel.z = dir.z * math.abs(vel.x)
			vel.x = 0
			pos.x = math.floor(pos.x + 0.5)
			update.pos = true
		end
		-- Up, down?
		if dir.y ~= self._old_dir.y then
			vel.y = dir.y * math.abs(vel.x + vel.z)
			pos = vector.round(pos)
			update.pos = true
		end

		-- Slow down or speed up
		local acc = dir.y * -1.8
		local friction = 0.4
		local ndef = core.registered_nodes[core.get_node(pos).name]
		local speed_mod = ndef and ndef._rail_acceleration

		acc = acc - friction

		if has_fuel then
			acc = acc + 0.6
		end

		if speed_mod and speed_mod ~= 0 then
			acc = acc + speed_mod + friction
		end

		new_acc = vector.multiply(dir, acc)
	end

	self.object:set_acceleration(new_acc)
	self._old_pos = vector.new(pos)
	self._old_dir = vector.new(dir)
	self._old_switch = last_switch

	-- Limits
	for _,v in ipairs({"x","y","z"}) do
		if math.abs(vel[v]) > max_vel then
			vel[v] = math.sign(vel[v]) * max_vel
			new_acc[v] = 0
			update.vel = true
		end
	end

	-- Give achievement when player reached a distance of 1000 nodes from the start position
	if self._driver and (vector.distance(self._start_pos, pos) >= 1000) then
		awards.unlock(self._driver, "mcl:onARail")
	end


	if update.pos or self._punched then
		local yaw = 0
		if dir.x < 0 then
			yaw = 0.5
		elseif dir.x > 0 then
			yaw = 1.5
		elseif dir.z < 0 then
			yaw = 1
		end
		self.object:set_yaw(yaw * math.pi)

		-- Handle tilting on slopes
		local yaw_rad = yaw * math.pi
		local target_pitch = 0
		if dir.y ~= 0 then
			target_pitch = dir.y * (math.pi / 4)
		end

		self.object:set_rotation(vector.new(target_pitch, yaw_rad, 0))
	end

	if self._punched then
		self._punched = false
	end

	if not (update.vel or update.pos) then
		return
	end


	local anim = {x=0, y=0}
	if dir.y == -1 then
		anim = {x=1, y=1}
	elseif dir.y == 1 then
		anim = {x=2, y=2}
	end
	self.object:set_animation(anim, 1, 0)

	self.object:set_velocity(vel)
	if update.pos then
		self.object:set_pos(pos)
	end

	-- stopped on "mcl_minecarts:golden_rail_on"
	if vector.equals(vel, vector.zero()) and restart_pos then
		local dir = mcl_minecarts.get_start_direction(restart_pos)
		if dir then
			mcl_minecarts.set_velocity(self, dir)
		end
	end
end

function mcl_minecarts.tpl_entity:get_staticdata()
	return core.serialize({_railtype = self._railtype})
end

function mcl_minecarts.register_entity(entity_id, entity_def)
	local cart = table.merge(mcl_minecarts.tpl_entity, entity_def)
	core.register_entity(entity_id, cart)
	return core.registered_entities[entity_id]
end

-- Place a minecart at pointed_thing
function mcl_minecarts.place_minecart(itemstack, pointed_thing, placer)
	if pointed_thing.type ~= "node" then
		return
	end

	local railpos, node
	if mcl_minecarts.is_rail(pointed_thing.under) then
		railpos = pointed_thing.under
		node = core.get_node(pointed_thing.under)
	elseif mcl_minecarts.is_rail(pointed_thing.above) then
		railpos = pointed_thing.above
		node = core.get_node(pointed_thing.above)
	else
		return
	end

	-- Activate detector rail
	if node.name == "mcl_minecarts:detector_rail" then
		local newnode = {name="mcl_minecarts:detector_rail_on", param2 = node.param2}
		mcl_redstone.swap_node(railpos, newnode)
	end

	local entity_id = itemstack:get_name()
	local cart = core.add_entity(railpos, entity_id)
	if not cart or not cart:get_pos() then return end
	local railtype = core.get_item_group(node.name, "connect_to_raillike")
	local le = cart:get_luaentity()
	if le then
		le._railtype = railtype
	end
	local cart_dir
	if node.name == "mcl_minecarts:golden_rail_on" then
		cart_dir = mcl_minecarts.get_start_direction(railpos)
	end
	if cart_dir then
		mcl_minecarts.set_velocity(le, cart_dir)
	else
		cart_dir = mcl_minecarts.get_rail_direction(railpos, vector.new(1, 0, 0), nil, nil, railtype)
	end
	cart:set_yaw(core.dir_to_yaw(cart_dir))

	local pname = ""
	if placer then
		pname = placer:get_player_name()
	end
	if not core.is_creative_enabled(pname) then
		itemstack:take_item()
	end
	return itemstack
end

mcl_minecarts.tpl_item = {
	stack_max = 1,
	groups = {minecart = 1, transport = 1},
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end

		-- Call on_rightclick if the pointed node defines it
		local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
		if rc then return rc end

		return mcl_minecarts.place_minecart(itemstack, pointed_thing, placer)
	end,
	_on_dispense = function(stack, _, droppos, dropnode, _)
		-- Place minecart as entity on rail. If there's no rail, just drop it.
		local placed
		if core.get_item_group(dropnode.name, "rail") ~= 0 then
			-- FIXME: This places minecarts even if the spot is already occupied
			local pointed_thing = {under = droppos, above = vector.offset(droppos, 0, 1, 0)}
			placed = mcl_minecarts.place_minecart(stack, pointed_thing)
		end
		if placed == nil then
			-- Drop item
			core.add_item(droppos, stack)
		end
	end,
}

function mcl_minecarts.register_craftitem(item_name, item_def)
	core.register_craftitem(item_name, table.merge(mcl_minecarts.tpl_item, item_def, {
		groups = table.merge(mcl_minecarts.tpl_item.groups, item_def.groups or {}),
	}))
end

function mcl_minecarts.register_minecart(name, def)
	local entity = mcl_minecarts.register_entity(name, def.entity)
	mcl_minecarts.register_craftitem(name, def.item)
	doc.sub.identifier.register_object(name, "craftitems", name)
	return entity
end
