local S = core.get_translator(core.get_current_modname())

local tt_help_end = S("Sneak-click to remove")

local function activate_tnt_minecart(self)
	if self._boomtimer then return end
	self.object:set_armor_groups({immortal = 1})
	self._boomtimer = tnt.BOOMTIMER
	self.object:set_properties({textures = {
		"mcl_tnt_blink.png",
		"mcl_tnt_blink.png",
		"mcl_tnt_blink.png",
		"mcl_tnt_blink.png",
		"mcl_tnt_blink.png",
		"mcl_tnt_blink.png",
		"mcl_minecarts_minecart.png",
	}})
	self._blinktimer = tnt.BLINKTIMER
	core.sound_play("tnt_ignite", {pos = self.object:get_pos(), gain = 1.0, max_hear_distance = 15}, true)
end

-- Minecart
mcl_minecarts.register_minecart("mcl_minecarts:minecart", {
	entity = {
		mesh = "mcl_minecarts_minecart.b3d",
		textures = {"mcl_minecarts_minecart.png"},
		on_rightclick = function(self, clicker)
			if not clicker or not clicker:is_player() then return end
			local name = clicker:get_player_name()
			if self._driver and name == self._driver then
				mcl_minecarts.detach_driver(self)
			elseif not self._driver then
				self._driver = name
				self._start_pos = self.object:get_pos()
				mcl_player.players[clicker].attached = true
				clicker:set_attach(self.object, "", vector.new(0, -1.75, -2), vector.zero())
				mcl_attachments.spawn_attachment_entity(clicker)
				core.after(0.2, function(name)
					local player = core.get_player_by_name(name)
					if player then
						mcl_player.player_set_animation(player, "sit" , 30)
						mcl_title.set(clicker, "actionbar", {text=S("Sneak to dismount"), color="white", stay=60})
					end
				end, name)
			end
		end,
		_drop = {"mcl_minecarts:minecart"},
		_on_activate_by_rail = mcl_minecarts.detach_driver
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
mcl_minecarts.register_minecart("mcl_minecarts:furnace_minecart", {
	entity = {
		mesh = "mcl_minecarts_minecart_block.b3d",
		textures = {
			"default_furnace_top.png",
			"default_furnace_top.png",
			"default_furnace_front.png",
			"default_furnace_side.png",
			"default_furnace_side.png",
			"default_furnace_side.png",
			"mcl_minecarts_minecart.png",
		},
		_drop = {"mcl_minecarts:minecart", "mcl_furnaces:furnace"},
		on_rightclick = function(self, clicker)
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
			self.object:set_properties({textures = {
				"default_furnace_top.png",
				"default_furnace_top.png",
				"default_furnace_front_active.png",
				"default_furnace_side.png",
				"default_furnace_side.png",
				"default_furnace_side.png",
				"mcl_minecarts_minecart.png",
			}})
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

-- Minecart with TNT
mcl_minecarts.register_minecart("mcl_minecarts:tnt_minecart", {
	entity = {
		mesh = "mcl_minecarts_minecart_block.b3d",
		textures = {
			"default_tnt_top.png",
			"default_tnt_bottom.png",
			"default_tnt_side.png",
			"default_tnt_side.png",
			"default_tnt_side.png",
			"default_tnt_side.png",
			"mcl_minecarts_minecart.png",
		},
		_drop = {"mcl_minecarts:minecart", "mcl_tnt:tnt"},
		on_rightclick = function(self, clicker)
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