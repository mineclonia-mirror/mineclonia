local S = core.get_translator(core.get_current_modname())

local tt_help_end = S("Sneak-click to remove")

-- Minecart
local function board_mob(self)
	if mcl_minecarts.get_passenger(self) or math.random(1, 20) <= 15 then
		return
	end

	for mob in core.objects_inside_radius(self.object:get_pos(), 1.3) do
		local entity = mob:get_luaentity()
		if entity and entity.is_mob and entity.can_ride_cart then
			mcl_minecarts.attach_passenger(self, mob)
			break
		end
	end
end

local function award_long_ride(self)
	local driver = mcl_minecarts.get_driver(self)
	local pos = self.object:get_pos()
	if driver and self._start_pos and pos and vector.distance(self._start_pos, pos) >= 1000 then
		awards.unlock(driver:get_player_name(), "mcl:onARail")
	end
end

mcl_minecarts.register_minecart("mcl_minecarts:minecart", {
	entity = {
		mesh = "mcl_minecarts_minecart.b3d",
		textures = {"mcl_minecarts_minecart.png"},
		_rideable = true,
		_driver_attach_position = vector.new(0, -1.75, -2),
		_passenger_attach_position = mcl_minecarts.passenger_attach_position,
		_on_step = board_mob,
		_after_step = award_long_ride,
		_drop = {"mcl_minecarts:minecart"},
	},
	item = {
		description = S("Minecart"),
		_tt_help = S("Vehicle for fast travel on rails") .. "\n"
			.. tt_help_end,
		_doc_items_longdesc = S("Minecarts can be used for a quick transportion on rails.") .. "\n"
			.. S("Minecarts only ride on rails and always follow the tracks. At a T-junction with no straight way ahead, they turn left. The speed is affected by the rail type.") .. "\n"
			.. tt_help_end,
		_doc_items_usagehelp = S("You can place the minecart on rails. Right-click it to enter it. Punch it to get it moving.") .. "\n"
			.. S("To obtain the minecart, punch it while holding down the sneak key.") .. "\n"
			.. S("If it moves over a powered activator rail, you'll get ejected."),
		inventory_image = "mcl_minecarts_minecart_normal.png",
		wield_image = "mcl_minecarts_minecart_normal.png",
	},
})

core.register_craft({
	output = "mcl_minecarts:minecart",
	recipe = {
		{"mcl_core:iron_ingot", "", "mcl_core:iron_ingot"},
		{"mcl_core:iron_ingot", "mcl_core:iron_ingot", "mcl_core:iron_ingot"},
	},
})

-- Minecart with Chest
mcl_minecarts.register_minecart("mcl_minecarts:chest_minecart", {
	entity = {
		mesh = "mcl_minecarts_minecart_chest.b3d",
		textures = {"mcl_chests_normal.png", "mcl_minecarts_minecart.png"},
		_drop = {"mcl_minecarts:minecart", "mcl_chests:chest"},
		_on_show_entity_inv = function(self, player)
			mobs_mc.enrage_piglins(player, true)
		end,
		_on_destroy_minecart = function(self, player)
			mobs_mc.enrage_piglins(player, true)
		end,
	},
	item = {
		description = S("Minecart with Chest"),
		_tt_help = tt_help_end,
		inventory_image = "mcl_minecarts_minecart_chest.png",
		wield_image = "mcl_minecarts_minecart_chest.png",
	},
})

mcl_entity_invs.register_inv(
	"mcl_minecarts:chest_minecart",
	"Minecart",
	27,
	false,
	true
)

core.register_craft({
	output = "mcl_minecarts:chest_minecart",
	recipe = {
		{"mcl_chests:chest"},
		{"mcl_minecarts:minecart"},
	},
})

mcl_wip.register_wip_item("mcl_minecarts:chest_minecart")

-- Minecart with Furnace
local furnace_textures = {
	"default_furnace_top.png",
	"default_furnace_top.png",
	"default_furnace_front.png",
	"default_furnace_side.png",
	"default_furnace_side.png",
	"default_furnace_side.png",
	"mcl_minecarts_minecart.png",
}

local furnace_active_textures = {
	"default_furnace_top.png",
	"default_furnace_top.png",
	"default_furnace_front_active.png",
	"default_furnace_side.png",
	"default_furnace_side.png",
	"default_furnace_side.png",
	"mcl_minecarts_minecart.png",
}

local function furnace_step(self, dtime)
	if not self._fueltime or self._fueltime <= 0 then return end

	self._fueltime = self._fueltime - dtime
	if self._fueltime <= 0 then
		self.object:set_properties({textures = furnace_textures})
		self._fueltime = 0
	end
end

local function furnace_get_drive(self)
	if self._fueltime and self._fueltime > 0 then return 0.6 end
	return 0
end

mcl_minecarts.register_minecart("mcl_minecarts:furnace_minecart", {
	entity = {
		mesh = "mcl_minecarts_minecart_block.b3d",
		textures = furnace_textures,
		_drop = {"mcl_minecarts:minecart", "mcl_furnaces:furnace"},
		_fueltime = nil,
		_on_step = furnace_step,
		_get_drive = furnace_get_drive,
		_on_rightclick = function(self, clicker)
			if not clicker or not clicker:is_player() then return end
			if not self._fueltime then
				self._fueltime = 0
			end
			local held = clicker:get_wielded_item()
			if core.get_item_group(held:get_name(), "coal") ~= 1 then return end
			self._fueltime = self._fueltime + 180

			if not core.is_creative_enabled(clicker:get_player_name()) then
				held:take_item()
				local index = clicker:get_wield_index()
				local inv = clicker:get_inventory()
				inv:set_stack("main", index, held)
			end
			self.object:set_properties({textures = furnace_active_textures})
		end,
	},
	item = {
		description = S("Minecart with Furnace"),
		_tt_help = tt_help_end,
		_doc_items_longdesc = S("A minecart with furnace is a vehicle that travels on rails. It can propel itself with fuel."),
		_doc_items_usagehelp = S("Place it on rails. If you give it some coal, the furnace will start burning for a long time and the minecart will be able to move itself. Punch it to get it moving.") .. "\n"
			.. S("To obtain the minecart and furnace, punch them while holding down the sneak key."),
		inventory_image = "mcl_minecarts_minecart_furnace.png",
		wield_image = "mcl_minecarts_minecart_furnace.png",
	},
})

core.register_craft({
	output = "mcl_minecarts:furnace_minecart",
	recipe = {
		{"mcl_furnaces:furnace"},
		{"mcl_minecarts:minecart"},
	},
})

mcl_wip.register_wip_item("mcl_minecarts:furnace_minecart")

-- Minecart with Command Block
mcl_minecarts.register_minecart("mcl_minecarts:command_block_minecart", {
	entity = {
		mesh = "mcl_minecarts_minecart_block.b3d",
		textures = {
			"jeija_commandblock_off.png^[verticalframe:2:0",
			"jeija_commandblock_off.png^[verticalframe:2:0",
			"jeija_commandblock_off.png^[verticalframe:2:0",
			"jeija_commandblock_off.png^[verticalframe:2:0",
			"jeija_commandblock_off.png^[verticalframe:2:0",
			"jeija_commandblock_off.png^[verticalframe:2:0",
			"mcl_minecarts_minecart.png",
		},
		_drop = {"mcl_minecarts:minecart"},
	},
	item = {
		description = S("Minecart with Command Block"),
		_tt_help = tt_help_end,
		inventory_image = "mcl_minecarts_minecart_command_block.png",
		wield_image = "mcl_minecarts_minecart_command_block.png",
		groups = {not_in_creative_inventory = 1},
	},
})

mcl_wip.register_wip_item("mcl_minecarts:command_block_minecart")

-- Minecart with Hopper
local function hopper_take_item(self)
	local pos = self.object:get_pos()
	if not pos then return end

	local above_pos = vector.offset(pos, 0, 0.9, 0)
	for object in core.objects_inside_radius(above_pos, 1.25) do
		local entity = object:get_luaentity()
		local taken_items = false

		if entity and not entity._removed and entity.itemstring and entity.itemstring ~= "" then
			local inv = mcl_entity_invs.load_inv(self, 5)
			if not inv then return false end

			local current_itemstack = ItemStack(entity.itemstring)
			if inv:room_for_item("main", current_itemstack) then
				inv:add_item("main", current_itemstack)
				entity.itemstring = ""
				object:remove()
				taken_items = true
			end

			if not taken_items then
				local items_remaining = current_itemstack:get_count()
				for i = 1, self._inv_size do
					local stack = inv:get_stack("main", i)
					if current_itemstack:get_name() == stack:get_name() then
						local room_for = stack:get_stack_max() - stack:get_count()
						if room_for < items_remaining then
							items_remaining = items_remaining - room_for
							stack:set_count(stack:get_stack_max())
							inv:set_stack("main", i, stack)
							taken_items = true
						elseif room_for ~= 0 then
							stack:set_count(stack:get_count() + items_remaining)
							inv:set_stack("main", i, stack)
							entity.itemstring = ""
							object:remove()
							taken_items = true
							break
						end
					end

					if i == self._inv_size and taken_items then
						current_itemstack:set_count(items_remaining)
						entity.itemstring = current_itemstack:to_string()
					end
				end
			end
		end

		if taken_items then
			mcl_entity_invs.save_inv(entity)
			return taken_items
		end
	end

	return false
end

mcl_minecarts.register_minecart("mcl_minecarts:hopper_minecart", {
	entity = {
		mesh = "mcl_minecarts_minecart_hopper.b3d",
		textures = {
			"mcl_hoppers_hopper_inside.png",
			"mcl_minecarts_minecart.png",
			"mcl_hoppers_hopper_outside.png",
			"mcl_hoppers_hopper_top.png",
		},
		_drop = {"mcl_minecarts:minecart", "mcl_hoppers:hopper"},
		_on_step = hopper_take_item,
	},
	item = {
		description = S("Minecart with Hopper"),
		_tt_help = tt_help_end,
		inventory_image = "mcl_minecarts_minecart_hopper.png",
		wield_image = "mcl_minecarts_minecart_hopper.png",
	},
})

mcl_entity_invs.register_inv(
	"mcl_minecarts:hopper_minecart",
	"Hopper Minecart",
	5,
	false,
	true
)

core.register_craft({
	output = "mcl_minecarts:hopper_minecart",
	recipe = {
		{"mcl_hoppers:hopper"},
		{"mcl_minecarts:minecart"},
	},
})

mcl_wip.register_wip_item("mcl_minecarts:hopper_minecart")

-- Minecart with TNT
local tnt_textures = {
	"default_tnt_top.png",
	"default_tnt_bottom.png",
	"default_tnt_side.png",
	"default_tnt_side.png",
	"default_tnt_side.png",
	"default_tnt_side.png",
	"mcl_minecarts_minecart.png",
}

local tnt_blink_textures = {
	"mcl_tnt_blink.png",
	"mcl_tnt_blink.png",
	"mcl_tnt_blink.png",
	"mcl_tnt_blink.png",
	"mcl_tnt_blink.png",
	"mcl_tnt_blink.png",
	"mcl_minecarts_minecart.png",
}

local function tnt_step(self, dtime)
	if self._boomtimer then
		self._boomtimer = self._boomtimer - dtime
		local pos = self.object:get_pos()
		if self._boomtimer <= 0 then
			mcl_explosions.explode(pos, 4, {}, self.object)
			self.object:remove()
			return
		end
		mcl_tnt.smoke_step(pos)
	end

	if self._blinktimer then
		self._blinktimer = self._blinktimer - dtime
		if self._blinktimer <= 0 then
			self._blink = not self._blink
			self.object:set_properties({textures = self._blink and tnt_textures or tnt_blink_textures})
			self._blinktimer = mcl_tnt.BLINKTIMER
		end
	end
end

local function tnt_can_be_picked_up(self)
	return not self._boomtimer
end

local function tnt_rail_lost(self, pos)
	if not self._boomtimer then return end
	mcl_explosions.explode(pos, 4, {}, self.object)
	self.object:remove()
end

local function activate_tnt_minecart(self)
	if self._boomtimer then return end
	self.object:set_armor_groups({immortal = 1})
	self._boomtimer = mcl_tnt.BOOMTIMER
	self.object:set_properties({textures = tnt_blink_textures})
	self._blinktimer = mcl_tnt.BLINKTIMER
	core.sound_play("tnt_ignite", {pos = self.object:get_pos(), gain = 1.0, max_hear_distance = 15}, true)
end

mcl_minecarts.register_minecart("mcl_minecarts:tnt_minecart", {
	entity = {
		mesh = "mcl_minecarts_minecart_block.b3d",
		textures = tnt_textures,
		_drop = {"mcl_minecarts:minecart", "mcl_tnt:tnt"},
		_boomtimer = nil,
		_blinktimer = nil,
		_blink = false,
		_on_step = tnt_step,
		_can_be_picked_up = tnt_can_be_picked_up,
		_on_rail_lost = tnt_rail_lost,
		_on_rightclick = function(self, clicker)
			if not clicker or not clicker:is_player() or self._boomtimer then return end
			local held = clicker:get_wielded_item()
			if core.get_item_group(held:get_name(), "flint_and_steel") > 0 then
				if not core.is_creative_enabled(clicker:get_player_name()) then
					held:add_wear_by_uses(65)
					local index = clicker:get_wield_index()
					local inv = clicker:get_inventory()
					inv:set_stack("main", index, held)
				end
				activate_tnt_minecart(self)
			end
		end,
		_on_activate_by_rail = activate_tnt_minecart,
	},
	item = {
		description = S("Minecart with TNT"),
		_tt_help = S("Can be ignited by tools or powered activator rail") .. "\n"
			.. tt_help_end,
		_doc_items_longdesc = S("A minecart with TNT is an explosive vehicle that travels on rail."),
		_doc_items_usagehelp = S("Place it on rails. Punch it to move it. The TNT is ignited with a flint and steel or when the minecart is on an powered activator rail.") .. "\n"
			.. S("To obtain the minecart and TNT, punch them while holding down the sneak key. You can't do this if the TNT was ignited."),
		inventory_image = "mcl_minecarts_minecart_tnt.png",
		wield_image = "mcl_minecarts_minecart_tnt.png",
	},
})

core.register_craft({
	output = "mcl_minecarts:tnt_minecart",
	recipe = {
		{"mcl_tnt:tnt"},
		{"mcl_minecarts:minecart"},
	},
})
