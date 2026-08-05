local S = core.get_translator(core.get_current_modname())

local LSM = (1.5/core.settings:get("gui_scaling"))/96 -- Luanti Scaling Minimiser (Minimises Luanti's GUI scaling, but this isn't yet perfect.)
local MCS = math.round(core.settings:get("gui_scaling")/0.375) -- Minecraft Scaling (For MClike scaling.)

local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
dofile(modpath.."/label.lua")

mcl_crafting_table = {}

mcl_crafting_table.formspec = table.concat({ -- NOTE: The numbers below correlate with the amount of pixels!

-- The formspec version.

	"formspec_version[8]", -- Supported by Luanti 5.10, which is currently the latest version on Debian Stable.


-- Prepend default values.

	"size["..(LSM*176*MCS)..","..(LSM*166*MCS).."]", -- The size of the GUI within Minecraft's default "crafting_table.png" texture.

	"no_prepend[]", -- Disable the default prepends, as we want to define our own prepends which are more accurate to Minecraft.

	"bgcolor[;true;#000000BB]", -- How much the background darkens when the GUI is open. Minecraft has a gradient darkening, so this is not 100% accurate.

	"listcolors[#0000;#FFFFFF75;#0000;#0000007F;#FFFFFFFF]", -- The colour of the inventory slots, and the tooltips of items when hovering the cursor over them.

	"style_type[list;".."size="..(LSM*16*MCS)..","..(LSM*16*MCS)..";".."spacing="..(LSM*2*MCS)..","..(LSM*2*MCS).."]", -- The size and spacing of the inventory slots within the GUI.

	"style_type[button;border=false;bgimg=button.png;sound=mesecons_button_push]", -- The default state of the recipe book button.


-- The visual part of the GUI.

	"image[0,0;"..(LSM*256*MCS)..","..(LSM*256*MCS)..";".."crafting_table.png".."]", -- The size of Minecraft's default "crafting_table.png" texture.

	get_gui_label(29, 6, "Crafting"), -- The "Crafting" label.

	"style[__mcl_craftguide:hovered,__mcl_craftguide:pressed;bgimg=button_highlighted.png]", -- The recipe book button.

	get_gui_label(8, 72, "Inventory"), -- The "Inventory" label.


-- The functional part of the GUI.

	"list[current_player;craft;"       ..(LSM*30*MCS).. ","..(LSM*17*MCS)..";3,3;0]", -- The 3x3 crafting grid.
	"list[current_player;craftpreview;"..(LSM*124*MCS)..","..(LSM*35*MCS)..";1,1;0]", -- The preview of the crafting output.

	"button["..(LSM*5*MCS)..","..(LSM*34*MCS)..";"..(LSM*20*MCS)..","..(LSM*18*MCS)..";__mcl_craftguide;]", -- The recipe book button.

	"list[current_player;main;"..(LSM*8*MCS)..","..(LSM*84*MCS) ..";9,3;9]", -- The player's backpack inventory.
	"list[current_player;main;"..(LSM*8*MCS)..","..(LSM*142*MCS)..";9,1;0]", -- The player's HUD inventory.

	"listring[current_player;craft]", -- This allows for shift-clicking functionality.
	"listring[current_player;main]", -- This allows for shift-clicking functionality.

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
