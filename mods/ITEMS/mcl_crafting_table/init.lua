local S = core.get_translator(core.get_current_modname())
local F = core.formspec_escape
local C = core.colorize
local GS = (1.5/core.settings:get("gui_scaling")) -- This helps keep the GUI look coherent at every size.
mcl_crafting_table = {}

mcl_crafting_table.formspec = table.concat({
	-- The formspec version.
	"formspec_version[8]", -- Supported by Luanti 5.10, which is currently the latest version on Debian Stable.


	-- Prepend default values.
	"size["..(GS*7.33333333333)..","..(GS*6.91666666667).."]", -- The size of the formspec, in Luanti inventory slots.
	"no_prepend[]", -- Disable the default prepends, as we want to define our own prepends which are more accurate to Minecraft.
	"bgcolor[;true;#000000BB]", -- How much the background darkens when the GUI is open. Minecraft has a gradient darkening, so this is not 100% accurate.
	"listcolors[#0000;#FFFFFF75;#0000;#0000007F;#FFFFFFFF]", -- The colour of the inventory slots, and the tooltips of items when hovering the cursor over them.
	"style_type[label;font_size="..(GS*24).."]", -- The font size of the labels.
	"style_type[list;size="..(GS*0.666666666667)..","..(GS*0.666666666667)..";".."spacing="..(GS*0.0833333333333)..","..(GS*0.0833333333333).."]", -- The size and spacing of the inventory slots within the GUI.
	"style_type[button;border=false;bgimg=button.png;sound=mesecons_button_push]", -- The default state of the recipe book button.


	-- The visual part of the GUI.
	"image[0,0;"..(GS*10.6666666667)..","..(GS*10.6666666667)..";".."crafting_table.png".."]", -- The GUI background.

	"image["..(GS*1.20833333333)..","..(GS*0.25)..";"..(GS*0.333333333333)..","..(GS*0.333333333333)..";".."ascii.png^[colorize:#404040^[sheet:16x16:3,4" .."]", -- C
	"image["..(GS*1.45833333333)..","..(GS*0.25)..";"..(GS*0.333333333333)..","..(GS*0.333333333333)..";".."ascii.png^[colorize:#404040^[sheet:16x16:2,7" .."]", -- r
	"image["..(GS*1.70833333333)..","..(GS*0.25)..";"..(GS*0.333333333333)..","..(GS*0.333333333333)..";".."ascii.png^[colorize:#404040^[sheet:16x16:1,6" .."]", -- a
	"image["..(GS*1.95833333333)..","..(GS*0.25)..";"..(GS*0.333333333333)..","..(GS*0.333333333333)..";".."ascii.png^[colorize:#404040^[sheet:16x16:6,6" .."]", -- f
	"image["..(GS*2.16666666667)..","..(GS*0.25)..";"..(GS*0.333333333333)..","..(GS*0.333333333333)..";".."ascii.png^[colorize:#404040^[sheet:16x16:4,7" .."]", -- t
	"image["..(GS*2.33333333333)..","..(GS*0.25)..";"..(GS*0.333333333333)..","..(GS*0.333333333333)..";".."ascii.png^[colorize:#404040^[sheet:16x16:9,6" .."]", -- i
	"image["..(GS*2.41666666667)..","..(GS*0.25)..";"..(GS*0.333333333333)..","..(GS*0.333333333333)..";".."ascii.png^[colorize:#404040^[sheet:16x16:14,6".."]", -- n
	"image["..(GS*2.66666666667)..","..(GS*0.25)..";"..(GS*0.333333333333)..","..(GS*0.333333333333)..";".."ascii.png^[colorize:#404040^[sheet:16x16:7,6" .."]", -- g

	"style[__mcl_craftguide:hovered,__mcl_craftguide:pressed;bgimg=button_highlighted.png]", -- The recipe book button.

	"image["..(GS*0.333333333333)..","..(GS*3)..";"..(GS*0.333333333333)..","..(GS*0.333333333333)..";".."ascii.png^[colorize:#404040^[sheet:16x16:9,4" .."]", -- I
	"image["..(GS*0.5)           ..","..(GS*3)..";"..(GS*0.333333333333)..","..(GS*0.333333333333)..";".."ascii.png^[colorize:#404040^[sheet:16x16:14,6".."]", -- n
	"image["..(GS*0.75)          ..","..(GS*3)..";"..(GS*0.333333333333)..","..(GS*0.333333333333)..";".."ascii.png^[colorize:#404040^[sheet:16x16:6,7" .."]", -- v
	"image["..(GS*1)             ..","..(GS*3)..";"..(GS*0.333333333333)..","..(GS*0.333333333333)..";".."ascii.png^[colorize:#404040^[sheet:16x16:5,6" .."]", -- e
	"image["..(GS*1.25)          ..","..(GS*3)..";"..(GS*0.333333333333)..","..(GS*0.333333333333)..";".."ascii.png^[colorize:#404040^[sheet:16x16:14,6".."]", -- n
	"image["..(GS*1.5)           ..","..(GS*3)..";"..(GS*0.333333333333)..","..(GS*0.333333333333)..";".."ascii.png^[colorize:#404040^[sheet:16x16:4,7" .."]", -- t
	"image["..(GS*1.66666666667) ..","..(GS*3)..";"..(GS*0.333333333333)..","..(GS*0.333333333333)..";".."ascii.png^[colorize:#404040^[sheet:16x16:15,6".."]", -- o
	"image["..(GS*1.91666666667) ..","..(GS*3)..";"..(GS*0.333333333333)..","..(GS*0.333333333333)..";".."ascii.png^[colorize:#404040^[sheet:16x16:2,7" .."]", -- r
	"image["..(GS*2.16666666667) ..","..(GS*3)..";"..(GS*0.333333333333)..","..(GS*0.333333333333)..";".."ascii.png^[colorize:#404040^[sheet:16x16:9,7" .."]", -- y


	-- The functional part of the GUI.
	"list[current_player;craft;"..(GS*1.25)..","..(GS*0.708333333333)..";3,3;]", -- The 3x3 crafting grid.
	"list[current_player;craftpreview;"..(GS*5.16666666667)..","..(GS*1.45833333333)..";1,1;]", -- The preview of the crafting output.

	"button["..(GS*0.208333333333)..","..(GS*1.41666666667)..";"..(GS*0.833333333333)..","..(GS*0.75)..";__mcl_craftguide;]", -- The recipe book button.

	"list[current_player;main;"..(GS*0.333333333333)..","..(GS*3.5)..";9,3;9]", -- The player's backpack inventory.
	"list[current_player;main;"..(GS*0.333333333333)..","..(GS*5.91666666667)..";9,1;]", -- The player's HUD inventory.

	"listring[current_player;craft]", -- This allows for shift-clicking functionality.
	"listring[current_player;main]", -- This allows for shift-clicking functionality.


	-- The maths behind many of the above values.
		-- Size W = 7.33333333333 (704/96)
		-- Size H = 6.91666666667 (664/96)

		-- List Size = 0.666666666667 (64/96)
		-- List Spacing = 0.0833333333333 (8/96)

		-- Image Size = 10.6666666667 ((256/176)*Size W) MUST BE THE SAME AS ((256/166)*Size H)

		-- Crafting Label X = 1.20833333333 (116/96)
		-- Crafting Label Y = 0.46875 ((24+21)/96) (No idea how to get this to valign bottom, so I had to offset the distance here.)

		-- Inventory Label X = 0.333333333333 (32/96)
		-- Inventory Label Y = 3.21875 ((288+21)/96) (No idea how to get this to valign bottom, so I had to offset the distance here.)

		-- Crafting Grid X = 1.25 (120/96)
		-- Crafting Grid Y = 0.708333333333 (68/96)

		-- Crafting Preview X = 5.16666666667 (496/96)
		-- Crafting Preview Y = 1.45833333333 (140/96)

		-- Backpack Inventory X = 0.333333333333 (32/96)
		-- Backpack Inventory Y = 3.5 (336/96)

		-- HUD Inventory X = 0.333333333333 (32/96)
		-- HUD Inventory Y = 5.91666666667 (568/96)

		-- Recipe Book Button X = 0.208333333333 (20/96)
		-- Recipe Book Button Y = 1.41666666667 (136/96)
		-- Recipe Book Button W = 0.833333333333 (80/96)
		-- Recipe Book Button H = 0.75 (72/96)
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
