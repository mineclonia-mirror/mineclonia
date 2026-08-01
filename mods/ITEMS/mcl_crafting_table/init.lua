local S = core.get_translator(core.get_current_modname())
local F = core.formspec_escape
local C = core.colorize
mcl_crafting_table = {}

mcl_crafting_table.formspec = table.concat({
	-- The size of an inventory slot is 64x64 pixels, multiplied by the GUI scaling.
	-- The below maths assume a GUI scaling of 1.5, which I have found to be the most "stable" scale.

	"formspec_version[8]", -- Supported by Luanti 5.10, the most recent version on the most recent Debian Stable release.
	"size[7.33333333333,6.91666666667]", -- 704/96 = 7.33333333333 ; 664/96 = 6.91666666667
	"image[0,0;10.6666666667,10.6666666667;crafting_table.png]", -- (256/176)*7.33333333333 = 10.6666666667 ; (256/166)*6.91666666667 = 10.6666666667
	"bgcolor[;;#000000BB]", -- Minecraft has a slight gradient to its background darkening, so getting this perfect isn't currently possible.
	"style_type[list;size=0.666666666667,0.666666666667;spacing=0.0833333333333,0.0833333333333]", -- 64/96 = 0.666666666667 ; 8/96 = 0.0833333333333 (No idea how to change colour of the list tiles.)
	"style_type[button;bgimg=button.png;bgimg_hovered=button_highlighted.png;bgimg_middle=true;bgimg_pressed=button_highlighted.png;sound=mesecons_button_push]",

	-- The crafting part of the crafting table GUI.
	"label[1.20833333333,0.46875;" .. F(C("#404040", S("Crafting"))) .. "]", -- 116/96 = 1.20833333333 ; (24+21)/96 = 0.46875 (No idea how to get this stuff to valign bottom.)

	"list[current_player;craft;1.25,0.708333333333;3,3;]", -- 120/96 = 1.25 ; 68/96 = 0.708333333333
	"list[current_player;craftpreview;5.16666666667,1.45833333333;1,1;]", -- 496/96 = 5.16666666667 ; 140/96 = 1.45833333333

	-- The inventory part of the crafting table GUI.
	"label[0.333333333333,3.21875;" .. F(C("#404040", S("Inventory"))) .. "]", -- 32/96 = 0.333333333333 ;

	"list[current_player;main;0.333333333333,3.5;9,3;9]", -- 32/96 = 0.333333333333 ; 336/96 = 3.5
	"list[current_player;main;0.333333333333,5.91666666667;9,1;]", -- 32/96 = 0.333333333333 ; 568/96 = 5.91666666667

	"listring[current_player;craft]",
	"listring[current_player;main]",

	-- The recipe book button.
	"button[0.208333333333,1.41666666667;0.833333333333,0.75;__mcl_craftguide;]", -- 20/96 = 0.208333333333 ; 136/96 = 1.41666666667 & 80/96 = 0.833333333333 ; 72/96 = 0.75
})

function mcl_crafting_table.has_crafting_table(player)
	if not player or not player:get_pos() then return end
	local wdef = player:get_wielded_item():get_definition()
	local range = wdef and wdef.range or ItemStack():get_definition().range or tonumber(core.settings:get("mcl_hand_range")) or 4.5
	return core.is_creative_enabled(player:get_player_name()) or (core.find_node_near(player:get_pos(), range, { "group:crafting_table" }, true) ~= nil)
end

-- track players that are viewing the crafting table formspec
local formspec_shown = {}

function mcl_crafting_table.show_crafting_form(player)
	if not mcl_crafting_table.has_crafting_table(player) then
		return
	end
	formspec_shown[player] = true
	core.show_formspec(player:get_player_name(), "main", mcl_crafting_table.formspec)
end

core.register_on_player_receive_fields(function(player, formname, fields)
	if fields.quit and formname == "main" then
		formspec_shown[player] = nil
	end
end)

mcl_player.register_globalstep_slow(function(player)
	if formspec_shown[player] and not mcl_crafting_table.has_crafting_table(player) then
		-- Player managed to get out of range of a crafting table
		-- with the crafting formspec still open.
		--
		-- This can happen when using a hacked client, but also
		-- legitimately when the player is moved by the environment,
		-- e.g. sinking in water.
		--
		-- Trigger the actions that would normally be caused by closing
		-- the formspec.
		core.close_formspec(player:get_player_name(), "main")
		core.run_callbacks(core.registered_on_player_receive_fields, 5, player, "main", { quit = true })
	end
end)

core.register_node("mcl_crafting_table:crafting_table", {
	description = S("Crafting Table"),
	_tt_help = S("3×3 crafting grid"),
	_doc_items_longdesc = S("A crafting table is a block which grants you access to a 3×3 crafting grid which allows you to perform advanced crafts."),
	_doc_items_usagehelp = S("Rightclick the crafting table to access the 3×3 crafting grid."),
	_doc_items_hidden = false,
	is_ground_content = false,
	tiles = { "crafting_workbench_top.png", "default_wood.png", "crafting_workbench_side.png",
		"crafting_workbench_side.png", "crafting_workbench_front.png", "crafting_workbench_front.png" },
	paramtype2 = "facedir",
	groups = { handy = 1, axey = 1, deco_block = 1, material_wood = 1, flammable = -1, crafting_table = 9 },
	on_rightclick = function(_, _, player)
		if not player:get_player_control().sneak then
			mcl_crafting_table.show_crafting_form(player)
		end
	end,
	sounds = mcl_sounds.node_sound_wood_defaults(),
	_mcl_hardness = 2.5,
	_mcl_burntime = 15
})

core.register_craft({
	output = "mcl_crafting_table:crafting_table",
	recipe = {
		{ "group:wood", "group:wood" },
		{ "group:wood", "group:wood" }
	},
})

core.register_alias("crafting:workbench", "mcl_crafting_table:crafting_table")
core.register_alias("mcl_inventory:workbench", "mcl_crafting_table:crafting_table")
