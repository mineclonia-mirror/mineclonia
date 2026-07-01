local S = core.get_translator(core.get_current_modname())
local C = core.colorize
local F = core.formspec_escape

local formspec_name = "mcl_cartography_table:cartography_table"

-- Crafting patterns supported:
-- 1. Filled map + paper = zoomed out map
-- 2. Filled map + empty map = two copies of the map
-- 3. Filled map + glass pane = locked filled map

local MAX_MAP_SCALE = mcl_maps.MAX_MAP_SCALE
assert (MAX_MAP_SCALE)

local function update_cartography_table(player)
	if not player or not player:is_player() then return end

	local formspec = table.concat({
		"formspec_version[4]",
		"size[11.75,10.425]",
		"label[0.375,0.375;", F(C(mcl_formspec.label_color, S("Cartography Table"))), "]",

		-- First input slot
		mcl_formspec.get_itemslot_bg_v4(1, 0.75, 1, 1),
		"list[current_player;cartography_table_input;1,0.75;1,1;0]",

		-- Cross icon
		"image[1,2;1,1;mcl_anvils_inventory_cross.png]",

		-- Second input slot
		mcl_formspec.get_itemslot_bg_v4(1, 3.25, 1, 1),
		"list[current_player;cartography_table_input;1,3.25;1,1;1]",

		-- Arrow
		"image[2.7,2;2,1;mcl_anvils_inventory_arrow.png]",

		-- Output slot
		mcl_formspec.get_itemslot_bg_v4(9.75, 2, 1, 1, 0.2),
		"list[current_player;cartography_table_output;9.75,2;1,1;]",

		-- Player inventory
		"label[0.375,4.7;", F(C(mcl_formspec.label_color, S("Inventory"))), "]",
		mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3),
		"list[current_player;main;0.375,5.1;9,3;9]",

		mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1),
		"list[current_player;main;0.375,9.05;9,1;]",
	})

	local inv = player:get_inventory()
	local stack = inv:get_stack ("cartography_table_input", 1)
	local operation_selected = false
	local texture, id

	if stack:get_name () == "mcl_maps:map" then
		texture, id = mcl_maps.load_map_item (stack)
		if id then
			local addon = inv:get_stack ("cartography_table_input", 2)
			local map = mcl_maps.load_map_data (id)
			assert (map)

			if map.scale < MAX_MAP_SCALE
				and addon:get_name () == "mcl_core:paper" then
				-- Zoom a map
				formspec = formspec .. "image[5.125,0.5;4,4;mcl_maps_map_background.png]"
				if texture then
					-- N.B. that the original map
					-- is not displayed where it
					-- would appear in the product
					-- but at the center of the
					-- formspec in Minecraft.
					formspec = formspec
						.. "image[6.25,1.625;1.75,1.75;"
						.. texture .. "]"
				end
				local stack = ItemStack ("mcl_maps:map")
				local def = stack:get_definition ()
				stack:get_meta ():set_string ("description", table.concat {
					def.description, "\n",
					core.colorize (mcl_colors.GRAY,
						       mcl_maps.describe_map (map.x_start,
									      map.z_start,
									      map.scale + 1)),
				})
				inv:set_stack ("cartography_table_output", 1, stack)
				operation_selected = true
			elseif addon:get_name () == "mcl_maps:map_empty" then
				--- Copy a map
				formspec = table.concat ({
					formspec,
					"image[6.125,0.5;3,3;mcl_maps_map_background.png]",
					"image[6.375,0.75;2.5,2.5;", texture, "]",
					"image[5.125,1.5;3,3;mcl_maps_map_background.png]",
					"image[5.375,1.75;2.5,2.5;", texture, "]"
				})
				stack:set_count (2)
				inv:set_stack ("cartography_table_output", 1, stack)
				operation_selected = true
			end
			-- TODO: locking maps.
		end
	end

	-- if mcl_maps.is_map(map) then
	-- 	local texture = not map:is_empty() and mcl_maps.load_map_item(map)
	-- 	local addon = inv:get_stack("cartography_table_input", 2)
	-- 	inv:set_stack("cartography_table_output", 1, nil)

	-- 	local meta
	-- 	local old_zoom = 999 -- Large number to never allow resizing maps that shouldn't be resizable
	-- 	if not map:is_empty() and not mcl_maps.is_empty_map(map) then
	-- 		meta = map:get_meta()
	-- 		old_zoom = meta:get_int("mcl_maps:zoom")
	-- 		if old_zoom < 1 then
	-- 			mcl_maps.convert_legacy_map(map, meta)
	-- 			old_zoom = 1
	-- 		end
	-- 	end

	-- 	if not map:is_empty() and not mcl_maps.is_empty_map(map) and addon:get_name() == "mcl_core:paper"
	-- 	and old_zoom < mcl_maps.max_zoom and meta :get_int("mcl_maps:locked") ~= 1 then
	-- 		---- Zoom a map
	-- 		formspec = formspec .. "image[5.125,0.5;4,4;mcl_maps_map_background.png]"
	-- 		-- TODO: show half size in appropriate position?
	-- 		if texture then formspec = formspec .. "image[6.25,1.625;1.75,1.75;" .. texture .. "]" end
	-- 		-- zoom will be really applied when taking from the stack
	-- 		-- to not cause unnecessary map generation. But the tooltip should be right already:
	-- 		map:get_meta():set_int("mcl_maps:zoom", old_zoom + 1)
	-- 		tt.reload_itemstack_description(map)
	-- 		inv:set_stack("cartography_table_output", 1, map)
	-- 	elseif not map:is_empty() and addon:get_name() == "mcl_maps:empty_map" then
	-- 		---- Copy a map
	-- 		if texture then
	-- 			formspec = table.concat({formspec,
	-- 				"image[6.125,0.5;3,3;mcl_maps_map_background.png]",
	-- 				"image[6.375,0.75;2.5,2.5;", texture, "]",
	-- 				"image[5.125,1.5;3,3;mcl_maps_map_background.png]",
	-- 				"image[5.375,1.75;2.5,2.5;", texture, "]"
	-- 			})
	-- 		else
	-- 			formspec = table.concat({formspec,
	-- 				"image[6.125,0.5;3,3;mcl_maps_map_background.png]",
	-- 				"image[5.125,1.5;3,3;mcl_maps_map_background.png]"
	-- 			})
	-- 		end
	-- 		map:set_count(2)
	-- 		inv:set_stack("cartography_table_output", 1, map)
	-- 	elseif not map:is_empty() and addon:get_name() == "mcl_panes:pane_natural_flat" then
	-- 		---- Lock a map
	-- 		formspec = formspec .. "image[5.125,0.5;4,4;mcl_maps_map_background.png]"
	-- 		if texture then formspec = formspec .. "image[5.375,0.75;3.5,3.5;" .. texture .. "]" end
	-- 		if map:get_meta():get_int("mcl_maps:locked") == 1 then
	-- 			formspec = table.concat({formspec,
	-- 				"image[3.2,2;1,1;mcl_core_barrier.png]",
	-- 				"image[8.375,3.75;0.5,0.5;mcl_core_barrier.png]"
	-- 			})
	-- 		else
	-- 			formspec = formspec .. "image[8.375,3.75;0.5,0.5;mcl_core_barrier.png]"
	-- 			map:get_meta():set_int("mcl_maps:locked", 1)
	-- 			inv:set_stack("cartography_table_output", 1, map)
	-- 		end
	-- 	else
	-- 		---- Not supported
	-- 		formspec = formspec .. "image[5.125,0.5;4,4;mcl_maps_map_background.png]"
	-- 		if texture then formspec = formspec .. "image[5.375,0.75;3.5,3.5;" .. texture .. "]" end
	-- 	end
	-- end

	if not operation_selected then
		formspec = formspec .. "image[5.125,0.5;4,4;mcl_maps_map_background.png]"
		if texture then
			formspec = formspec
				.. "image[5.375,0.75;3.5,3.5;"
				.. texture
				.. "]"
		end
		inv:set_stack ("cartography_table_output", 1, nil)
	end

	core.show_formspec (player:get_player_name(), formspec_name, formspec)
end

core.register_on_joinplayer(function(player)
	local inv = player:get_inventory()

	inv:set_size("cartography_table_input", 2)
	inv:set_size("cartography_table_output", 1)

	-- The player might have items remaining in the slots from the previous join; this is likely
	-- when the server has been shutdown and the server didn't clean up the player inventories.
	mcl_util.move_player_list(player, "cartography_table_input")
	player:get_inventory():set_list("cartography_table_output", {})
end)

core.register_on_leaveplayer(function(player)
	mcl_util.move_player_list(player, "cartography_table_input")
	player:get_inventory():set_list("cartography_table_output", {})
end)

local function remove_from_input(player, inventory, count)
	local astack = inventory:get_stack("cartography_table_input", 1)
	if astack then
		astack:set_count(math.max(0, astack:get_count() - count))
		inventory:set_stack("cartography_table_input", 1, astack)
	end
	local bstack = inventory:get_stack("cartography_table_input", 2)
	if bstack then
		bstack:set_count(math.max(0, bstack:get_count() - count))
		inventory:set_stack("cartography_table_input", 2, bstack)
	end
end

core.register_allow_player_inventory_action(function(player, action, inventory, inventory_info)
	-- Generate zoomed map
	if (action == "move" or action == "take")
		and inventory_info.from_list == "cartography_table_output"
		and inventory_info.from_index == 1 then
		local stack = inventory:get_stack ("cartography_table_output", 1)
		local input = inventory:get_stack ("cartography_table_input", 1)
		local addon = inventory:get_stack ("cartography_table_input", 2)
		if stack:get_name () == "mcl_maps:map"
			and addon:get_name () == "mcl_core:paper" then
			local stack = mcl_maps.scale_map_item (input)
			if not stack then
				return 0
			end
			tt.reload_itemstack_description (stack)
			inventory:set_stack ("cartography_table_output", 1, stack)
		end

		-- Always allow taking items from the cartography table output
		return stack:get_count ()
	end

	if action == "move" or action == "put" then
		if inventory_info.to_list == "cartography_table_output" then
			return 0
		elseif inventory_info.to_list == "cartography_table_input" then
			local index = inventory_info.to_index
			local stack = inventory:get_stack(inventory_info.from_list, inventory_info.from_index)
			if index == 1 and stack:get_name() == "mcl_maps:map" then
				return 1
			end
			if index == 2 and stack:get_name() == "mcl_core:paper" then
				return inventory_info.count
			end
			if index == 2 and stack:get_name() == "mcl_maps:map_empty" then
				return inventory_info.count
			end
			-- if index == 2 and stack:get_name() == "mcl_panes:pane_natural_flat" then
			-- 	return inventory_info.count
			-- end
			return 0
		elseif inventory_info.from_list == "cartography_table_output"
			and inventory_info.from_index == 1 then
			return inventory_info.count
		end
	end
end)

core.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
	if action == "move" then
		if inventory_info.from_list == "cartography_table_output" then
			remove_from_input(player, inventory, inventory_info.count)
		end
		if inventory_info.to_list == "cartography_table_input" or inventory_info.from_list == "cartography_table_input" then
			update_cartography_table(player)
		end
	elseif action == "put" then
		if inventory_info.listname == "cartography_table_input" then
			update_cartography_table(player)
		end
	elseif action == "take" then
		if inventory_info.listname == "cartography_table_output" then
			remove_from_input(player, inventory, inventory_info.stack:get_count())
		end
	end
end)

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= formspec_name then return end
	if fields.quit then
		mcl_util.move_player_list(player, "cartography_table_input")
		player:get_inventory():set_list("cartography_table_output", {})
		return
	end
end)

core.register_node("mcl_cartography_table:cartography_table", {
	description = S("Cartography Table"),
	_tt_help = S("Used to copy, lock, and zoom maps"),
	_doc_items_longdesc = S("A cartography tables facilitates copying, locking, and zoomming maps."),
	tiles = {
		"cartography_table_top.png", "cartography_table_side3.png",
		"cartography_table_side3.png", "cartography_table_side2.png",
		"cartography_table_side3.png", "cartography_table_side1.png"
	},
	paramtype2 = "facedir",
	groups = {axey = 2, handy = 1, deco_block = 1, material_wood = 1, flammable = 1},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	_mcl_hardness = 2.5,
	is_ground_content = false,
	_mcl_burntime = 15,
	on_rightclick = function(pos, node, player, itemstack)
		if player and player:is_player() and not player:get_player_control().sneak then
			update_cartography_table(player)
		end
	end,
})

core.register_craft({
	output = "mcl_cartography_table:cartography_table",
	recipe = {
		{"mcl_core:paper", "mcl_core:paper", ""},
		{"group:wood",     "group:wood",     ""},
		{"group:wood",     "group:wood",     ""},
	}
})
