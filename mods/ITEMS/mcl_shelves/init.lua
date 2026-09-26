mcl_shelves = {}

local shelf_item_entities = {}

local function rotate_dir_90_deg_clockwise(dir)
	local rotated_dir = vector.copy(dir)

	-- inlined linear transformation to rotate 90 degrees clockwise
	--     i  j
	-- x [-1, 0]
	-- z [ 0, 1]
	rotated_dir.x = -dir.z
	rotated_dir.z = dir.x

	return rotated_dir
end

-- get the powered shelf variant. substrings are returned variant first, base name second.
-- get_shelf_variant("mcl_shelves:oak_powered_left") -> "mcl_shelves:oak", "_powered_left"
local function get_shelf_variant(nodename)
	local base_name, variant = nodename:match("^(mcl_shelves:.*)(_powered.*)$")
	if not (base_name and core.get_item_group(base_name, "shelf") > 0) or
			core.get_item_group(nodename, "shelf") <= 0 then
		return nil, nil
	end
	return variant, base_name
end

local function swap_shelf_variant(pos, node, variant)
	local _, base_name = get_shelf_variant(node.name)
	return core.swap_node(pos, {name = (base_name or node.name) .. variant, param2 = node.param2})
end

local function clear_shelf_entities(pos)
	local hash = core.hash_node_position(pos)
	local objects = shelf_item_entities[hash] or {}

	for _, obj in pairs(objects) do
		if obj:is_valid() then
			local l = obj:get_luaentity()
			l.about_to_be_removed = true
			obj:remove()
		end
	end
end

local function initalize_shelf(pos, inv)
	local node = core.get_node(pos)
	local dir = core.fourdir_to_dir(node.param2)
	local rot_dir = rotate_dir_90_deg_clockwise(dir)

	local objects = {}
	for i = 1, 3 do
		local obj = core.add_entity(
			pos + dir * 0.25 + rot_dir * ((2 - i) * 0.3),
			"mcl_shelves:item_entity"
		)
		obj:set_rotation(vector.dir_to_rotation(dir))

		local stack_name = inv:get_stack("main", i):get_name()
		if stack_name == "" then
			obj:set_properties({visual = "sprite", textures = {"blank.png"}})
		else
			obj:set_properties({textures = {stack_name}})
		end

		table.insert(objects, obj)
	end

	local hash = core.hash_node_position(pos)
	shelf_item_entities[hash] = objects
end

local function set_shelf_entities(pos, inv)
	local hash = core.hash_node_position(pos)

	if not shelf_item_entities[hash] then
		initalize_shelf(pos, inv)
		return
	end

	local objects = shelf_item_entities[hash]

	for i = 1, 3 do
		local obj = objects[i]
		local stack_name = inv:get_stack("main", i):get_name()
		local obj_item = obj:get_properties().textures[1]

		if obj_item ~= stack_name then
			if stack_name == "" then
				obj:set_properties({visual = "sprite", textures = {"blank.png"}})
			else
				obj:set_properties({visual = "wielditem", textures = {stack_name}})
			end
		end
	end
end

local function normal_on_rightclick(pos, node, player, stack)
	if not core.is_player(player) then return end

	local dir = core.facedir_to_dir(node.param2)
	local perpendicular_dir = rotate_dir_90_deg_clockwise(dir)
	local ray_pointed_thing = mcl_util.get_pointed_thing(player, false, false)
	if not ray_pointed_thing or ray_pointed_thing.type ~= "node" or
			not vector.equals(ray_pointed_thing.under, pos) then
		return
	end

	local pos_diff = vector.multiply(ray_pointed_thing.intersection_point - pos, perpendicular_dir)
	local from_left = (pos_diff.x ~= 0 and pos_diff.x) or
			(pos_diff.y ~= 0 and pos_diff.y) or
			(pos_diff.z ~= 0 and pos_diff.z)

	local slot = (from_left >= 0.15 and 1) or (from_left <= -0.15 and 3) or 2

	local player_name = player:get_player_name()
	if core.is_protected(pos, player_name) then
		core.record_protection_violation(pos, player_name)
		return
	end

	local meta = core.get_meta(pos)
	local inv = meta:get_inventory()

	local shelf_stack = inv:get_stack("main", slot)

	inv:set_stack("main", slot, stack)

	set_shelf_entities(pos, inv)
	mcl_redstone.update_comparators(pos)
	mcl_hunger.prevent_eating(player)

	return shelf_stack
end

local function powered_on_rightclick(pos, node, player, stack)
	if not core.is_player(player) then return end

	local dir = core.facedir_to_dir(node.param2)
	local perpendicular_dir = rotate_dir_90_deg_clockwise(dir)

	local left_pos = pos + perpendicular_dir
	local right_pos = pos - perpendicular_dir

	local variant = get_shelf_variant(node.name)

	-- order is significant in this table
	local shelf_positions

	if variant == "_powered_left" then
		local right_node = core.get_node(right_pos)
		local right_variant = get_shelf_variant(right_node.name)

		if right_variant == "_powered_right" then
			shelf_positions = {
				right_pos,
				pos
			}
		elseif right_variant == "_powered_center" then
			shelf_positions = {
				right_pos - perpendicular_dir,
				right_pos,
				pos,
			}
		else
			core.log("error", "Invalid shelf configuration")
			return
		end
	elseif variant == "_powered_right" then
		local left_node = core.get_node(left_pos)
		local left_variant = get_shelf_variant(left_node.name)

		if left_variant == "_powered_left" then
			shelf_positions = {
				pos,
				left_pos,
			}
		elseif left_variant == "_powered_center" then
			shelf_positions = {
				pos,
				left_pos,
				left_pos + perpendicular_dir,
			}
		else
			core.log("error", "Invalid shelf configuration")
			return
		end
	elseif variant == "_powered_center" then
		shelf_positions = {
			right_pos,
			pos,
			left_pos
		}
	else
		shelf_positions = {pos}
	end

	local shelf_invs = {}
	local expected_variants = ({
		{"_powered"},
		{"_powered_right", "_powered_left"},
		{"_powered_right", "_powered_center", "_powered_left"},
	})[#shelf_positions]
	for i, shelf_pos in ipairs(shelf_positions) do
		local shelf_node = core.get_node(shelf_pos)
		local inv = core.get_inventory({type = "node", pos = shelf_pos})
		if shelf_node.param2 ~= node.param2 or
				get_shelf_variant(shelf_node.name) ~= expected_variants[i] or
				not inv or inv:get_size("main") ~= 3 then
			core.log("error", "Invalid shelf configuration")
			return
		end
		shelf_invs[i] = inv
	end

	local player_name = player:get_player_name()
	for _, shelf_pos in ipairs(shelf_positions) do
		if core.is_protected(shelf_pos, player_name) then
			core.record_protection_violation(shelf_pos, player_name)
			return
		end
	end

	local player_inv = player:get_inventory()
	local shelf_inv

	-- workaround the fact that if we set the wieleded item in this function, it will get
	-- overwritten by the return value
	local leftover_index = player:get_wield_index()
	local leftover = stack

	for i = 0, #shelf_positions * 3 - 1 do
		if i % 3 == 0 then
			if shelf_inv then
				set_shelf_entities(shelf_positions[(i / 3)], shelf_inv)
				mcl_redstone.update_comparators(shelf_positions[(i / 3)])
			end
			shelf_inv = shelf_invs[(i / 3) + 1]
		end

		local shelf_inv_slot = 3 - (i % 3)
		local shelf_stack = shelf_inv:get_stack("main", shelf_inv_slot)
		local player_stack = player_inv:get_stack("main", 9 - i)

		if 9 - i == leftover_index then
			leftover = shelf_stack
		else
			player_inv:set_stack("main", 9 - i, shelf_stack)
		end

		shelf_inv:set_stack("main", shelf_inv_slot, player_stack)
	end

	mcl_redstone.update_comparators(shelf_positions[#shelf_positions])
	mcl_hunger.prevent_eating(player)
	set_shelf_entities(shelf_positions[#shelf_positions], shelf_inv)

	return leftover
end

-- I don't like this function...
local function propagate_redstone_update(pos)
	local node = core.get_node(pos)
	if not get_shelf_variant(node.name) and
			-- unpowered shelf; check manually
			(not node.name:match("^mcl_shelves:") or core.get_item_group(node.name, "shelf") <= 0) then
		return
	end

	local connect_left = false
	local connect_right = false

	local dir = core.facedir_to_dir(node.param2)
	local perpendicular_dir = rotate_dir_90_deg_clockwise(dir)

	local pos_left_1 = pos + perpendicular_dir
	local node_left_1 = core.get_node(pos_left_1)
	local node_left_1_variant = get_shelf_variant(node_left_1.name)

	if (node_left_1_variant == "_powered" or node_left_1_variant == "_powered_left") and
			node.param2 == node_left_1.param2 then
		connect_left = true
	elseif node_left_1_variant == "_powered_right" and node.param2 == node_left_1.param2 then
		local pos_left_2 = pos_left_1 + perpendicular_dir
		local node_left_2 = core.get_node(pos_left_2)
		local node_left_2_variant = get_shelf_variant(node_left_2.name)

		if node_left_2_variant == "_powered_left" and node.param2 == node_left_2.param2 then
			swap_shelf_variant(pos_left_2, node_left_2, "_powered_left")
			swap_shelf_variant(pos_left_1, node_left_1, "_powered_center")
			swap_shelf_variant(pos, node, "_powered_right")
			return
		end
	end

	local pos_right_1 = pos - perpendicular_dir
	local node_right_1 = core.get_node(pos_right_1)
	local node_right_1_variant = get_shelf_variant(node_right_1.name)

	if (node_right_1_variant == "_powered" or node_right_1_variant == "_powered_right") and
			node.param2 == node_right_1.param2 then
		if connect_left then
			swap_shelf_variant(pos_left_1, node_left_1, "_powered_left")
			swap_shelf_variant(pos, node, "_powered_center")
			swap_shelf_variant(pos_right_1, node_right_1, "_powered_right")
			return
		end

		connect_right = true
	elseif node_right_1_variant == "_powered_left" and not connect_left and node.param2 == node_right_1.param2 then
		local pos_right_2 = pos_right_1 - perpendicular_dir
		local node_right_2 = core.get_node(pos_right_2)
		local node_right_2_variant = get_shelf_variant(node_right_2.name)

		if node_right_2_variant == "_powered_right" and node.param2 == node_right_2.param2 then
			swap_shelf_variant(pos, node, "_powered_left")
			swap_shelf_variant(pos_right_1, node_right_1, "_powered_center")
			swap_shelf_variant(pos_right_2, node_right_2, "_powered_right")
			return
		end
	end

	if connect_left then
		swap_shelf_variant(pos, node, "_powered_right")
		swap_shelf_variant(pos_left_1, node_left_1, "_powered_left")
		return
	elseif connect_right then
		swap_shelf_variant(pos, node, "_powered_left")
		swap_shelf_variant(pos_right_1, node_right_1, "_powered_right")
		return
	else
		swap_shelf_variant(pos, node, "_powered")
		return
	end
end

local function propagate_redstone_removal(pos)
	local node = core.get_node(pos)
	local root_name = string.gsub(node.name, "_powered.*", "")
	local node_variant = get_shelf_variant(node.name)

	core.swap_node(pos, {name = root_name, param2 = node.param2})

	local dir = core.facedir_to_dir(node.param2)
	local perpendicular_dir = rotate_dir_90_deg_clockwise(dir)

	if node_variant == "_powered_left" then
		propagate_redstone_update(pos - perpendicular_dir)
	elseif node_variant == "_powered_right" then
		propagate_redstone_update(pos + perpendicular_dir)
	elseif node_variant == "_powered_center" then
		propagate_redstone_update(pos + perpendicular_dir)
		propagate_redstone_update(pos - perpendicular_dir)
	end
end

local function comparator_measure(pos)
	local inv = core.get_inventory({type = "node", pos = pos})
	local powerlevel = 0
	for i = 1, 3 do
		local stack = inv:get_stack("main", i)

		if not stack:is_empty() then
			powerlevel = bit.bor(powerlevel, bit.lshift(1, i - 1))
		end
	end

	return powerlevel
end

local shelf_box = {
	type = "fixed",
	fixed = {
		{-8/16, -8/16, 5/16, 8/16, 8/16, 8/16},
		{-8/16, -8/16, 3/16, 8/16, -4/16, 8/16},
		{-8/16, 4/16, 3/16, 8/16, 8/16, 8/16},
	}
}

mcl_shelves.tpl_shelf = {
	drawtype = "mesh", -- mesh applied later
	paramtype2 = "4dir",
	paramtype = "light",
	selection_box = shelf_box,
	collision_box = shelf_box,
	groups = {shelf = 1, deco_block = 1, container = 2, unmovable_by_piston = 1},
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("main", 3)

		initalize_shelf(pos, inv)
	end,
	on_destruct = function(pos)
		local inv = core.get_inventory({type = "node", pos = pos})
		for i = 1, 3 do
			core.add_item(pos, inv:get_stack("main", i))
		end
		clear_shelf_entities(pos)
		propagate_redstone_removal(pos)
	end,
	on_rightclick = normal_on_rightclick,
	_mcl_redstone = {
		update = function(pos, node)
			local power = mcl_redstone.get_power(pos)
			if power > 0 then
				propagate_redstone_update(pos)
			end
		end
	},
	_after_hopper_out = function(pos)
		set_shelf_entities(pos, core.get_inventory({type = "node", pos = pos}))
	end,
	_after_hopper_in = function(pos)
		set_shelf_entities(pos, core.get_inventory({type = "node", pos = pos}))
	end
}

function mcl_shelves.register_shelf(name, def)
	local root_name = "mcl_shelves:" .. name
	local base_def = table.merge(mcl_shelves.tpl_shelf, def, {
		groups = table.merge(mcl_shelves.tpl_shelf.groups, def.groups),
		drop = root_name,
		mesh = "mcl_shelves_shelf.obj"
	})

	local powered_def = table.merge(base_def, {
		on_rightclick = powered_on_rightclick,
		groups = table.merge(base_def.groups, {not_in_creative_inventory = 1}),
		_mcl_redstone = {
			update = function(pos, node)
				local power = mcl_redstone.get_power(pos)
				if power == 0 then
					propagate_redstone_removal(pos)
				end
			end
		}
	})

	core.register_node(":" .. root_name, base_def)

	core.register_node(":" .. root_name .. "_powered", table.merge(powered_def, {
		mesh = "mcl_shelves_shelf_powered.obj"
	}))

	core.register_node(":" .. root_name .. "_powered_left", table.merge(powered_def, {
		mesh = "mcl_shelves_shelf_powered_left.obj",
	}))

	core.register_node(":" .. root_name .. "_powered_center", table.merge(powered_def, {
		mesh = "mcl_shelves_shelf_powered_center.obj",
	}))

	core.register_node(":" .. root_name .. "_powered_right", table.merge(powered_def, {
		mesh = "mcl_shelves_shelf_powered_right.obj",
	}))

	mcl_redstone.register_comparator_measure_func(root_name, comparator_measure)
	mcl_redstone.register_comparator_measure_func(root_name .. "_powered", comparator_measure)
	mcl_redstone.register_comparator_measure_func(root_name .. "_powered_left", comparator_measure)
	mcl_redstone.register_comparator_measure_func(root_name .. "_powered_center", comparator_measure)
	mcl_redstone.register_comparator_measure_func(root_name .. "_powered_right", comparator_measure)
end

core.register_entity("mcl_shelves:item_entity", {
	initial_properties = {
		visual = "wielditem",
		visual_size = {x = 0.18, y = 0.18},
		physical = false,
		pointable = false,
		static_save = false,
		textures = {"blank.png"},
	},
	_mcl_pistons_unmovable = true,
	on_activate = function(self)
		self.object:set_armor_groups({immortal = 1})
	end,
	get_staticdata = function(self)
		if not self.about_to_be_removed then
			clear_shelf_entities(vector.round(self.object:get_pos()))
		end
	end,
})

core.register_lbm({
	label = "Spawn shelf entities",
	name = "mcl_shelves:item_entity_spawner",
	nodenames = {"group:shelf"},
	run_at_every_load = true,
	bulk_action = function(pos_list)
		for _, pos in pairs(pos_list) do
			initalize_shelf(pos, core.get_inventory({type = "node", pos = pos}))
		end
	end
})
