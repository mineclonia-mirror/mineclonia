local modname = core.get_current_modname()
local S = core.get_translator(modname)

mcl_walls = {}

local directions = {
	vector.new(1, 0, 0),
	vector.new(-1, 0, 0),
	vector.new(0, 0, 1),
	vector.new(0, 0, -1),
	vector.new(0, -1, 0)
}

local always_pillar_under = {}

core.register_on_mods_loaded(function()
	for name, _ in pairs(core.registered_nodes) do
		if
				core.get_item_group(name, "torch_ground") > 0
				or core.get_item_group(name, "pressure_plate") > 0
				or core.get_item_group(name, "banner") > 0
				or core.get_item_group(name, "standing_sign") > 0 then
			always_pillar_under[name] = true
		end
	end
end)

local function construct_wall_name(root, is_tall, is_pillar)
	return root .. (is_tall and "_tall" or "_short") .. (is_pillar and "_pillar" or "_flat")
end

function mcl_walls.update_wall(pos)
	local node = core.get_node(pos)

	if core.get_item_group(node.name, "wall") <= 0 then
		return
	end

	local is_pillar = core.get_item_group(node.name, "wall_pillar") > 0
	local is_short = core.get_item_group(node.name, "wall_short") > 0

	local function is_node_connectable(pos, off_x, off_y, off_z)
		pos.x = pos.x + off_x
		pos.y = pos.y + off_y
		pos.z = pos.z + off_z

		local offset_node = core.get_node(pos)
		local ndef = core.registered_nodes[offset_node.name]

		pos.x = pos.x - off_x
		pos.y = pos.y - off_y
		pos.z = pos.z - off_z

		if not ndef then
			return false
		end

		return (ndef.groups.solid or 0) > 0 or (ndef.groups.wall or 0) > 0 or (ndef.groups.pane or 0) > 0
	end

	local top_node = core.get_node(vector.offset(pos, 0, 1, 0))
	local top_node_is_solid = core.get_item_group(top_node.name, "solid") > 0
	local top_node_is_wall = core.get_item_group(top_node.name, "wall") > 0
	local top_node_is_pillar = core.get_item_group(top_node.name, "wall_pillar") > 0

	local is_positive_x_connectable = is_node_connectable(pos, 1, 0, 0)
	local is_negative_x_connectable = is_node_connectable(pos, -1, 0, 0)

	local is_positive_z_connectable = is_node_connectable(pos, 0, 0, 1)
	local is_negative_z_connectable = is_node_connectable(pos, 0, 0, -1)

	local inline_with_x = is_positive_x_connectable and is_negative_x_connectable
	local inline_with_z = is_positive_z_connectable and is_negative_z_connectable

	-- Should be pillar if the top node is a pillar or a block that creates pillars when placed on walls (like walls).
	-- Otherwise should be pillar if it doesn't satisfy the condition to be `flat`
	--
	-- The condition to be flat is as follows:
	-- `Is flat if its inline with X and doesn't connect in -Z or +Z. Or if its inline with Z and doesn't connect in -X or +X`
	local should_be_pillar =
		top_node_is_pillar
		or always_pillar_under[top_node.name]
		or not (
			(inline_with_x and not is_positive_z_connectable and not is_negative_z_connectable)
			or (inline_with_z and not is_positive_x_connectable and not is_negative_x_connectable)
		)

	local should_be_tall
	if top_node_is_wall then
		-- Tall if this wall and the wall above connect on a common side
		local has_shared_connections_with_top_wall = (is_positive_x_connectable and is_node_connectable(pos, 1, 1, 0))
			or (is_negative_x_connectable and is_node_connectable(pos, -1, 1, 0))
			or (is_positive_z_connectable and is_node_connectable(pos, 0, 1, 1))
			or (is_negative_z_connectable and is_node_connectable(pos, 0, 1, -1))
		should_be_tall = has_shared_connections_with_top_wall

		if not has_shared_connections_with_top_wall and not top_node_is_pillar then
			should_be_pillar = true
		end
	else
		should_be_tall = top_node_is_solid
	end

	if (is_pillar ~= should_be_pillar) or ((not is_short) ~= should_be_tall) then
		local node_name_root = core.registered_nodes[node.name]._mcl_walls_name_root
		local new_param2 = (not should_be_pillar and inline_with_z and 1) or 0
		core.swap_node(pos,
			{
				name = construct_wall_name(node_name_root, should_be_tall, should_be_pillar),
				param2 = new_param2
			}
		)

		if is_pillar or should_be_pillar then
			mcl_walls.update_wall(vector.offset(pos, 0, -1, 0))
		end

		mcl_redstone._notify_observer_neighbours(pos)
	end
end

-- XXX: render this asynchronous and move it into nodeprops.lua.
local level_to_minetest_position = mcl_levelgen.level_to_minetest_position
local update_wall = mcl_walls.update_wall
local v = vector.zero ()

mcl_levelgen.register_notification_handler ("mcl_walls:update_walls", function (_, data)
	for _, pos in ipairs (data) do
		local x, y, z = level_to_minetest_position (pos.x, pos.y, pos.z)
		v.x = x
		v.y = y
		v.z = z
		update_wall (v)
	end
end)

local function update_surrounding_walls(pos)
	for i = 1, #directions do
		local dir = directions[i]
		pos.x = pos.x + dir.x
		pos.y = pos.y + dir.y
		pos.z = pos.z + dir.z
		mcl_walls.update_wall(pos)
		pos.x = pos.x - dir.x
		pos.y = pos.y - dir.y
		pos.z = pos.z - dir.z
	end
end

mcl_pistons.register_on_move(function(moved_nodes)
	for i = 1, #moved_nodes do
		update_surrounding_walls(moved_nodes[i].pos)
		update_surrounding_walls(moved_nodes[i].old_pos)
	end
end)

local main_wall_groups = {
	pickaxey = 1,
	wall = 1,
	deco_block = 1
}

local internal_wall_groups = {
	pickaxey = 1,
	wall = 1,
	not_in_creative_inventory = 1
}

local tall_flat_wall_nodebox = {
	type = "fixed",
	fixed = {
		8/16, 8/16, 3/16,
		-8/16, -8/16, -3/16,
	}
}

local short_flat_wall_nodebox = {
	type = "fixed",
	fixed = {
		8/16, 6/16, 3/16,
		-8/16, -8/16, -3/16,
	}
}

local short_flat_wall_collisionbox = {
	type = "fixed",
	fixed = {
		8/16, 12/16, 3/16,
		-8/16, -8/16, -3/16,
	}
}

local pillar_collisionbox = {
	type = "fixed",
	fixed = {
		6/16, 12/16, 6/16,
		-6/16, -8/16, -6/16,
	}
}

local short_pillar_wall_nodebox = {
	type = "connected",
	fixed = {
		4/16, 8/16, 4/16,
		-4/16, -8/16, -4/16,
	},
	connect_back = {
		3/16, 6/16, 8/16,
		-3/16, -8/16, 0/16,
	},
	connect_front = {
		3/16, 6/16, 0/16,
		-3/16, -8/16, -8/16,
	},
	connect_right = {
		8/16, 6/16, 3/16,
		0/16, -8/16, -3/16,
	},
	connect_left = {
		0/16, 6/16, 3/16,
		-8/16, -8/16, -3/16,
	}
}

local tall_pillar_wall_nodebox = {
	type = "connected",
	fixed = {
		4/16, 8/16, 4/16,
		-4/16, -8/16, -4/16,
	},
	connect_back = {
		3/16, 8/16, 8/16,
		-3/16, -8/16, 0/16,
	},
	connect_front = {
		3/16, 8/16, 0/16,
		-3/16, -8/16, -8/16,
	},
	connect_right = {
		8/16, 8/16, 3/16,
		0/16, -8/16, -3/16,
	},
	connect_left = {
		0/16, 8/16, 3/16,
		-8/16, -8/16, -3/16,
	}
}

local tpl_wall = {
	drawtype = "nodebox",
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 2,
	_pathfinding_class = "FENCE",
}

--[[ Adds a new wall type.
* nodename: Itemstring of base node to add. Must not contain an underscore
* description: Item description (tooltip), visible to user
* source: Source block to craft this thing, for graphics, tiles and crafting (optional)
* tiles: Wall textures table
* inventory_image: Inventory image (optional)
* groups: Base group memberships (optional, default is {pickaxey=1})
* sounds: Sound table (optional, default is stone)
]]
function mcl_walls.register_wall(nodename, description, source, tiles, inventory_image, groups, sounds, overrides)

	if (not tiles) and source and core.registered_nodes[source] then
		tiles = core.registered_nodes[source].tiles
	end

	local wall_instance_shared_def = {
		tiles = tiles,
		drop = nodename,
		_mcl_stonecutter_recipes = {source},
		_mcl_baseitem = nodename,
		_mcl_walls_name_root = nodename,
		sounds = sounds
	}

	core.register_node(":"..nodename.."_tall_flat", table.merge(tpl_wall, wall_instance_shared_def, {
		paramtype2 = "4dir",
		groups = table.merge(internal_wall_groups, groups),
		node_box = tall_flat_wall_nodebox,
	}, overrides or {}))

	core.register_node(":"..nodename.."_short_flat", table.merge(tpl_wall, wall_instance_shared_def , {
		paramtype2 = "4dir",
		groups = table.merge(internal_wall_groups, {wall_short = 1}, groups),
		node_box = short_flat_wall_nodebox,
		collision_box = short_flat_wall_collisionbox,
	}, overrides or {}))

	core.register_node(":"..nodename.."_short_pillar", table.merge(tpl_wall, wall_instance_shared_def, {
		description = description,
		inventory_image = inventory_image,
		_doc_items_longdesc = S("A piece of wall. It cannot be jumped over with a simple jump. When multiple of these are placed to next to each other, they will automatically build a nice wall structure."),
		groups = table.merge(main_wall_groups, {wall_short = 1, wall_pillar = 1}, groups),
		on_construct = function(pos)
			mcl_walls.update_wall(pos)
		end,
		node_box = short_pillar_wall_nodebox,
		collision_box = pillar_collisionbox,
		connects_to = {"group:wall", "group:solid", "group:pane"},
	}, overrides or {}))

	core.register_node(":"..nodename.."_tall_pillar", table.merge(tpl_wall, wall_instance_shared_def, {
		groups = table.merge(internal_wall_groups, {wall_pillar = 1}, groups),
		node_box = tall_pillar_wall_nodebox,
		collision_box = pillar_collisionbox,
		connects_to = {"group:wall", "group:solid", "group:pane"},
	}, overrides or {}))

	if source then
		core.register_craft({
			output = nodename .. "_short_pillar 6",
			recipe = {
				{source, source, source},
				{source, source, source},
			}
		})
	end
end

function mcl_walls.register_wall_def(name,def)
	local source = def.source
	def.source = nil
	mcl_walls.register_wall(name, nil, source, nil, nil, nil, nil, def)
end

core.register_on_placenode(update_surrounding_walls)
core.register_on_dignode(update_surrounding_walls)
