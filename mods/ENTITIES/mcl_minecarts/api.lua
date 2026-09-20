mcl_minecarts.speed_max = 10
mcl_minecarts.check_float_time = 15
mcl_minecarts.passenger_attach_position = vector.new(0, -1.75, 0)

local S = core.get_translator(core.get_current_modname())

local function cart_is_valid(self)
	return self.object and self.object:is_valid()
end

local function can_always_be_picked_up()
	return true
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
	_old_dir = vector.zero(),
	_old_pos = nil,
	_old_vel = vector.zero(),
	_old_switch = 0,
	_railtype = nil,
	_mcl_fishing_hookable = true,
	_mcl_fishing_reelable = true,
	_can_be_picked_up = can_always_be_picked_up,
}

function mcl_minecarts.activate_by_rail(self)
	mcl_minecarts.detach_driver(self)
	if self._on_activate_by_rail then
		self:_on_activate_by_rail()
	end
end

function mcl_minecarts.tpl_entity:on_activate(staticdata, dtime_s)
	local data = core.deserialize(staticdata)
	if type(data) ~= "table" then data = {} end
	self._railtype = data._railtype

	if self._on_activate then
		self:_on_activate(data, dtime_s)
		if not cart_is_valid(self) then return end
	end

	self.object:set_armor_groups({immortal=1})

	local pos = self.object:get_pos()
	local node = core.get_node(vector.round(pos))
	if node.name == "mcl_minecarts:activator_rail_on" then
		mcl_minecarts.activate_by_rail(self)
	end
end

function mcl_minecarts.tpl_entity:on_rightclick(clicker)
	if self._rideable and clicker and clicker:is_player() then
		local driver = mcl_minecarts.get_driver(self)
		if driver == clicker then
			mcl_minecarts.detach_driver(self)
		elseif not driver and mcl_minecarts.attach_driver(self, clicker) then
			core.after(0.2, function()
				if clicker and cart_is_valid(self) and mcl_minecarts.get_driver(self) == clicker then
					mcl_player.player_set_animation(clicker, "sit", 30)
					mcl_title.set(clicker, "actionbar", {
						text = S("Sneak to dismount"),
						color = "white",
						stay = 60,
					})
				end
			end)
		end
		return
	end

	if self._on_rightclick then
		self:_on_rightclick(clicker)
	end
end

function mcl_minecarts.tpl_entity:on_punch(puncher, time_from_last_punch, tool_capabilities, _)
	local pos = self.object:get_pos()
	if not self._railtype then
		local node = core.get_node(vector.round(pos)).name
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

	-- Punch+sneak: Pick up the minecart when the type permits it.
	local sneak = puncher:get_player_control().sneak
	local can_be_picked_up = false
	if sneak then
		can_be_picked_up = self:_can_be_picked_up(puncher)
		if not cart_is_valid(self) then return end
	end
	if sneak and can_be_picked_up then
		if mcl_minecarts.get_driver(self) then
			if self._old_pos then
				self.object:set_pos(self._old_pos)
			end
			mcl_minecarts.detach_driver(self)
		end
		mcl_minecarts.detach_passenger(self)

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
				if not cart_is_valid(self) then return end
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
	if mcl_minecarts.get_driver(self) == puncher then
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

-- Run environment checks and validate the cart driver/passenger.
-- Returns player controls table and `true` on success; `nil, false` otherwise
local function check_driver_and_environment(self, dtime)
	local player = mcl_minecarts.get_driver(self)
	local ctrl
	if not player then
		mcl_minecarts.detach_driver(self)
	else
		ctrl = player:get_player_control()
		if ctrl.sneak then
			mcl_minecarts.detach_driver(self)
			player = nil
			ctrl = nil
		end
	end

	mcl_minecarts.get_passenger(self)

	if self._last_float_check == nil then
		self._last_float_check = 0
	else
		self._last_float_check = self._last_float_check + dtime
	end

	local pos = self.object:get_pos()
	local r = 0.6
	for _, node_pos in ipairs({{r, 0}, {0, r}, {-r, 0}, {0, -r}}) do
		if core.get_node(vector.offset(pos, node_pos[1], 0, node_pos[2])).name == "mcl_core:cactus" then
			mcl_minecarts.detach_driver(self)
			mcl_minecarts.detach_passenger(self)
			for _, drop in ipairs(self._drop) do
				core.add_item(pos, drop)
			end
			self.object:remove()
			return nil, false
		end
	end

	if self._last_float_check >= mcl_minecarts.check_float_time then
		local node = core.get_node(vector.round(pos))
		local railtype = core.get_item_group(node.name, "connect_to_raillike")
		if self._railtype and railtype ~= self._railtype then
			if player and self._old_pos then
				self.object:set_pos(self._old_pos)
			end
			mcl_minecarts.detach_driver(self)

			if self._on_rail_lost then
				self:_on_rail_lost(pos)
				if not cart_is_valid(self) then return nil, false end
			end

			-- Do not drop minecart. It goes off the rails too frequently, and anyone using them for farms won't
			-- notice and lose their iron and not bother. Not cool until fixed.
		end
		self._last_float_check = 0
	end

	return ctrl, true
end

local function get_movement_state()
	return {
		drive = 0,
		-- to be expanded later as needed
	}
end

local function run_movement(self, ctrl, movement)
	local vel = self.object:get_velocity()
	local pos = self.object:get_pos()
	local update = {}

	if self._punched then
		vel = vector.add(vel, self._velocity)
		self.object:set_velocity(vel)
		self._old_dir.y = 0
	elseif vector.equals(vel, vector.zero()) and movement.drive == 0 then
		return
	end

	local dir, last_switch, restart_pos = nil, nil, nil
	if self._old_pos and not self._punched then
		local rou_pos = vector.round(pos)
		local rou_old = vector.round(self._old_pos)
		local node = core.get_node(rou_pos)
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
		if node_old.name == "mcl_minecarts:activator_rail_on" then
			mcl_minecarts.activate_by_rail(self)
			if not cart_is_valid(self) then return end
		end
	end

	-- Stop cart if velocity vector flips
	if self._old_vel and self._old_vel.y == 0 and
			(self._old_vel.x * vel.x < 0 or self._old_vel.z * vel.z < 0) then
		self._old_vel = vector.zero()
		self._old_pos = pos
		self.object:set_velocity(vector.zero())
		self.object:set_acceleration(vector.zero())
		return
	end
	self._old_vel = vector.copy(vel)

	if self._old_pos then
		local diff = vector.subtract(self._old_pos, pos)
		for _,v in ipairs({"x","y","z"}) do
			if math.abs(diff[v]) > 1.1 then
				local expected_pos = vector.add(self._old_pos, self._old_dir)
				dir, last_switch = mcl_minecarts.get_rail_direction(pos, self._old_dir, ctrl, self._old_switch, self._railtype)
				if vector.equals(dir, vector.zero()) then
					dir = false
					pos = vector.copy(expected_pos)
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
	if vector.equals(dir, vector.zero()) and movement.drive == 0 then
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

		acc = acc - friction + movement.drive

		if speed_mod and speed_mod ~= 0 then
			acc = acc + speed_mod + friction
		end

		new_acc = vector.multiply(dir, acc)
	end

	self.object:set_acceleration(new_acc)
	self._old_pos = vector.copy(pos)
	self._old_dir = vector.copy(dir)
	self._old_switch = last_switch

	-- Limits
	for _,v in ipairs({"x","y","z"}) do
		if math.abs(vel[v]) > max_vel then
			vel[v] = math.sign(vel[v]) * max_vel
			new_acc[v] = 0
			update.vel = true
		end
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

function mcl_minecarts.tpl_entity:on_step(dtime, moveresult)
	local ctrl, valid = check_driver_and_environment(self, dtime)
	if not valid then return end

	if self._on_step then
		self:_on_step(dtime, moveresult)
		if not cart_is_valid(self) then return end
	end

	local movement = get_movement_state()
	if self._get_drive then
		local drive = self:_get_drive()
		if not cart_is_valid(self) then return end
		if type(drive) == "number" then movement.drive = drive end
	end

	run_movement(self, ctrl, movement)
	if not cart_is_valid(self) then return end

	if self._after_step then
		self:_after_step(dtime, moveresult)
	end
end

function mcl_minecarts.tpl_entity:get_staticdata()
	local data = {_railtype = self._railtype}
	if self._get_staticdata then
		self:_get_staticdata(data)
	end
	return core.serialize(data)
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
