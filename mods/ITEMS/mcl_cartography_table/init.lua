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
		"listring[current_player;main]",
		"listring[current_player;cartography_table_sorter]",
		"listring[current_player;cartography_table_input]",
		"listring[current_player;main]",
		"listring[current_player;cartography_table_output]",
		"listring[current_player;main]",
	})

	local inv = player:get_inventory()
	inv:set_stack ("cartography_table_sorter", 1, ItemStack ())
	local stack = inv:get_stack ("cartography_table_input", 1)
	local operation_selected = false
	local texture, id
	local item_name = stack:get_name ()

	if core.get_item_group (item_name, "filled_map") > 0 then
		texture, id = mcl_maps.load_map_item (stack)
		if id then
			local addon = inv:get_stack ("cartography_table_input", 2)
			local map = mcl_maps.load_map_data (id)
			assert (map)

			if map.scale < MAX_MAP_SCALE
				and item_name == "mcl_maps:map"
				and addon:get_name () == "mcl_core:paper" then
				-- Zoom a map
				formspec = formspec .. "image[5.125,0.5;4,4;mcl_cartography_table_scaled_map.png]"
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
					C(mcl_colors.GRAY,
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
					"image[6.125,0.5;3,3;mcl_cartography_table_map.png]",
					"image[6.375,0.75;2.5,2.5;", texture, "]",
					"image[5.125,1.5;3,3;mcl_cartography_table_map.png]",
					"image[5.375,1.75;2.5,2.5;", texture, "]"
				})
				stack:set_count (2)
				inv:set_stack ("cartography_table_output", 1, stack)
				operation_selected = true
			elseif item_name == "mcl_maps:map"
					and addon:get_name () == "mcl_panes:pane_natural_flat" then
				local stack = ItemStack ("mcl_maps:map_locked")
				stack:get_meta ():set_string ("mcl_maps:map_id", id)
				tt.reload_itemstack_description (stack)
				inv:set_stack ("cartography_table_output", 1, stack)
				operation_selected = true

				formspec = table.concat({
					formspec,
					"image[5.125,0.5;4,4;mcl_cartography_table_map.png]",
					"image[5.375,0.75;3.5,3.5;", texture, "]",
					"image[8.3,3.475;0.5,0.7;mcl_cartography_table_locked.png]"
				})
			end
		end
	end

	if not operation_selected then
		formspec = formspec .. "image[5.125,0.5;4,4;mcl_cartography_table_map.png]"
		if texture then
			formspec = formspec
				.. "image[5.375,0.75;3.5,3.5;"
				.. texture
				.. "]"
		end
		inv:set_stack ("cartography_table_output", 1, ItemStack())
	end

	core.show_formspec (player:get_player_name(), formspec_name, formspec)
end

core.register_on_joinplayer(function(player)
	local inv = player:get_inventory()

	inv:set_size("cartography_table_input", 2)
	inv:set_size("cartography_table_output", 1)
	inv:set_size ("cartography_table_sorter", 1)
	inv:set_stack ("cartography_table_sorter", 1, ItemStack ())

	-- The player might have items remaining in the slots from the previous join; this is likely
	-- when the server has been shutdown and the server didn't clean up the player inventories.
	mcl_util.move_player_list(player, "cartography_table_input")
	inv:set_stack("cartography_table_output", 1, ItemStack ())
end)

core.register_on_leaveplayer(function(player)
	mcl_util.move_player_list(player, "cartography_table_input")
	player:get_inventory():set_stack("cartography_table_output", 1, ItemStack())
end)

local function remove_from_input(player, inventory)
	local astack = inventory:get_stack("cartography_table_input", 1)
	if astack then
		astack:set_count(math.max(0, astack:get_count() - 1))
		inventory:set_stack("cartography_table_input", 1, astack)
	end
	local bstack = inventory:get_stack("cartography_table_input", 2)
	if bstack then
		bstack:set_count(math.max(0, bstack:get_count() - 1))
		inventory:set_stack("cartography_table_input", 2, bstack)
	end
	-- Preserve the second output when a map is copied and only one map is taken.
	mcl_util.move_player_list(player, "cartography_table_output")
end

--> "copy"|"zoom"|"lock", ItemStack OR nil, nil
local function get_output_operation(inventory, stack)
	local input = inventory:get_stack("cartography_table_input", 1)
	local addon = inventory:get_stack("cartography_table_input", 2)
	local id = input:get_meta():get_string("mcl_maps:map_id")

	-- Explorer maps are also copiable, so we don't expect ID here and we check
	-- for that larger group rather than the itemstring.
	if core.get_item_group(input:get_name(), "filled_map") > 0
			and addon:get_name() == "mcl_maps:map_empty"
			and input:peek_item():equals(stack:peek_item()) then
		return "copy", input
	end

	if id == "" then return nil, nil end
	if input:get_name() == "mcl_maps:map" and stack:get_name() == "mcl_maps:map"
			and addon:get_name() == "mcl_core:paper" then
		return "zoom", input
	elseif input:get_name() == "mcl_maps:map"
			and stack:get_name() == "mcl_maps:map_locked"
			and addon:get_name() == "mcl_panes:pane_natural_flat"
			and stack:get_meta():get_string("mcl_maps:map_id") == id then
		return "lock", input
	end
end

local function create_output_map(operation, input)
	local stack
	if operation == "zoom" then
		stack = mcl_maps.scale_map_item(input)
	elseif operation == "lock" then
		stack = mcl_maps.lock_map_item(input)
	end
	if stack then
		tt.reload_itemstack_description(stack)
	end
	return stack
end

core.register_allow_player_inventory_action(function(player, action, inventory, inventory_info)
	if (action == "move" and inventory_info.from_list == "cartography_table_output"
			and inventory_info.from_index == 1)
			or (action == "take" and inventory_info.listname == "cartography_table_output"
			and inventory_info.index == 1) then
		local stack = inventory:get_stack("cartography_table_output", 1)
		local operation, input = get_output_operation(inventory, stack)
		if not operation then return 0 end

		if action == "move" then
			if inventory_info.to_list == "cartography_table_input"
					or inventory_info.to_list == "cartography_table_sorter"
					or inventory_info.to_list == "cartography_table_output"
					or (
						operation ~= "copy" and
						not inventory:get_stack(
							inventory_info.to_list,
							inventory_info.to_index
						):is_empty()
					) then
				return 0
			end
		elseif operation ~= "copy" then
			local processed = create_output_map(operation, input)
			if not processed then return 0 end
			inventory:set_stack("cartography_table_output", 1, processed)
		end

		return stack:get_count()
	end

	if action == "move" or action == "put" then
		if inventory_info.to_list == "cartography_table_output" then
			return 0
		elseif inventory_info.to_list == "cartography_table_sorter" then
			local stack = inventory:get_stack (inventory_info.from_list,
							   inventory_info.from_index)
			local name = stack:get_name ()
			if core.get_item_group (name, "filled_map") > 0 then
				local stack1 = inventory:get_stack ("cartography_table_input", 1)
				if stack1:is_empty () then
					return 1
				end
				return 0
			elseif name == "mcl_core:paper"
				or name == "mcl_maps:map_empty"
				or name == "mcl_panes:pane_natural_flat" then
				local stack2
					= inventory:get_stack ("cartography_table_input", 2)
				local dst_type = stack2:peek_item ()
				if stack2:is_empty ()
					or dst_type:equals (stack:peek_item ()) then
					local cnt = stack2:get_stack_max ()
						- stack2:get_count ()
					return math.max (cnt, 0)
				end
				return 0
			end
		elseif inventory_info.to_list == "cartography_table_input" then
			local index = inventory_info.to_index
			local stack = inventory:get_stack(inventory_info.from_list, inventory_info.from_index)
			if index == 1
				and core.get_item_group (stack:get_name (),
							 "filled_map") > 0 then
				return 1
			end
			local name = stack:get_name()
			if index == 2
					and (
					name == "mcl_core:paper"
					or name == "mcl_maps:map_empty"
					or name == "mcl_panes:pane_natural_flat") then
				return inventory_info.count
			end
			return 0
		elseif inventory_info.from_list == "cartography_table_output"
			and inventory_info.from_index == 1 then
			return inventory_info.count
		end
	end

	-- Forbid all unhandled operations upon the sorter list.
	if inventory_info.from_list == "cartography_table_sorter"
		or inventory_info.to_list == "cartography_table_sorter" then
		return 0
	end
end)

core.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
	if action == "move" then
		if inventory_info.from_list == "cartography_table_output" then
			local stack = inventory:get_stack(inventory_info.to_list, inventory_info.to_index)
			local operation, input = get_output_operation(inventory, stack)
			if operation and operation ~= "copy" then
				local processed = create_output_map(operation, input)
				if processed then
					inventory:set_stack(inventory_info.to_list, inventory_info.to_index, processed)
				end
			end
			remove_from_input(player, inventory)
		end
		if inventory_info.to_list == "cartography_table_input"
			or inventory_info.from_list == "cartography_table_input" then
			update_cartography_table(player)
		end
		if inventory_info.to_list == "cartography_table_sorter" then
			local info = inventory_info
			local stack = inventory:get_stack (info.to_list, info.to_index)

			if core.get_item_group (stack:get_name (), "filled_map") > 0 then
				inventory:set_stack ("cartography_table_input", 1, stack)
			else
				local stack2
					= inventory:get_stack ("cartography_table_input", 2)
				stack2:add_item (stack)
				inventory:set_stack ("cartography_table_input", 2, stack2)
			end

			-- Leftovers should not exist here.
			inventory:set_stack ("cartography_table_sorter", 1, ItemStack ())
			update_cartography_table (player)
		end
	elseif action == "put" then
		if inventory_info.listname == "cartography_table_input" then
			update_cartography_table(player)
		end
	elseif action == "take" then
		if inventory_info.listname == "cartography_table_output" then
			remove_from_input(player, inventory)
		elseif inventory_info.listname == "cartography_table_input" then
			update_cartography_table(player)
		end
	end
end)

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= formspec_name then return end
	if fields.quit then
		mcl_util.move_player_list(player, "cartography_table_input")
		player:get_inventory():set_stack("cartography_table_output", 1, ItemStack())
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
		if player and player:is_player()
			and not player:get_player_control().sneak then
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
