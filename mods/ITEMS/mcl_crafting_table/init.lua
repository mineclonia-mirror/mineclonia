local S = core.get_translator(core.get_current_modname())
local LSN = (1.5/core.settings:get("gui_scaling"))/96 -- Luanti Scaling Negator (Required to negate Luanti's GUI scaling, so that we can implement our own system instead.)
local MCS = math.ceil(core.settings:get("gui_scaling")/0.375) -- Minecraft Scaling
mcl_crafting_table = {}

mcl_crafting_table.formspec = table.concat({ -- NOTE: The numbers below correlate with the amount of pixels!

-- The formspec version.

	"formspec_version[8]", -- Supported by Luanti 5.10, which is currently the latest version on Debian Stable.


-- Prepend default values.

	"size["..(LSN*176*MCS)..","..(LSN*166*MCS).."]", -- The size of the GUI within Minecraft's default "crafting_table.png" texture.

	"no_prepend[]", -- Disable the default prepends, as we want to define our own prepends which are more accurate to Minecraft.

	"bgcolor[;true;#000000BB]", -- How much the background darkens when the GUI is open. Minecraft has a gradient darkening, so this is not 100% accurate.

	"listcolors[#0000;#FFFFFF75;#0000;#0000007F;#FFFFFFFF]", -- The colour of the inventory slots, and the tooltips of items when hovering the cursor over them.

	"style_type[list;".."size="..(LSN*16*MCS)..","..(LSN*16*MCS)..";".."spacing="..(LSN*2*MCS)..","..(LSN*2*MCS).."]", -- The size and spacing of the inventory slots within the GUI.

	"style_type[button;border=false;bgimg=button.png;sound=mesecons_button_push]", -- The default state of the recipe book button.


-- The visual part of the GUI.

	"image[0,0;"..(LSN*256*MCS)..","..(LSN*256*MCS)..";".."crafting_table.png".."]", -- The size of Minecraft's default "crafting_table.png" texture.

	"image["..(LSN*29*MCS)..","..(LSN*6*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:3,4" .."]", -- C
	"image["..(LSN*35*MCS)..","..(LSN*6*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:2,7" .."]", -- r
	"image["..(LSN*41*MCS)..","..(LSN*6*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:1,6" .."]", -- a
	"image["..(LSN*47*MCS)..","..(LSN*6*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:6,6" .."]", -- f
	"image["..(LSN*52*MCS)..","..(LSN*6*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:4,7" .."]", -- t
	"image["..(LSN*56*MCS)..","..(LSN*6*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:9,6" .."]", -- i
	"image["..(LSN*58*MCS)..","..(LSN*6*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:14,6".."]", -- n
	"image["..(LSN*64*MCS)..","..(LSN*6*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:7,6" .."]", -- g

	"style[__mcl_craftguide:hovered,__mcl_craftguide:pressed;bgimg=button_highlighted.png]", -- The recipe book button.

	"image["..(LSN*8*MCS) ..","..(LSN*72*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:9,4" .."]", -- I
	"image["..(LSN*12*MCS)..","..(LSN*72*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:14,6".."]", -- n
	"image["..(LSN*18*MCS)..","..(LSN*72*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:6,7" .."]", -- v
	"image["..(LSN*24*MCS)..","..(LSN*72*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:5,6" .."]", -- e
	"image["..(LSN*30*MCS)..","..(LSN*72*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:14,6".."]", -- n
	"image["..(LSN*36*MCS)..","..(LSN*72*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:4,7" .."]", -- t
	"image["..(LSN*40*MCS)..","..(LSN*72*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:15,6".."]", -- o
	"image["..(LSN*46*MCS)..","..(LSN*72*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:2,7" .."]", -- r
	"image["..(LSN*52*MCS)..","..(LSN*72*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:9,7" .."]", -- y


-- The functional part of the GUI.

	"list[current_player;craft;"       ..(LSN*30*MCS).. ","..(LSN*17*MCS)..";3,3;0]", -- The 3x3 crafting grid.
	"list[current_player;craftpreview;"..(LSN*124*MCS)..","..(LSN*35*MCS)..";1,1;0]", -- The preview of the crafting output.

	"button["..(LSN*5*MCS)..","..(LSN*34*MCS)..";"..(LSN*20*MCS)..","..(LSN*18*MCS)..";__mcl_craftguide;]", -- The recipe book button.

	"list[current_player;main;"..(LSN*8*MCS)..","..(LSN*84*MCS) ..";9,3;9]", -- The player's backpack inventory.
	"list[current_player;main;"..(LSN*8*MCS)..","..(LSN*142*MCS)..";9,1;0]", -- The player's HUD inventory.

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
