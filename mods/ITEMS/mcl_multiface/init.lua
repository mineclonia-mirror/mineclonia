mcl_multiface = {}

local SOLID_FACE = mcl_util.decompose_AABBs ({{
	-0.5, -0.5, -0.5,
	0.5, 0.5, 0.5,
}})

local facedir_enum = {
	axis_px = 12,
	axis_nx = 16,
	axis_py = 0,
	axis_ny = 20,
	axis_pz = 4,
	axis_nz = 8,

	axis_mask = 28,
	rotation_mask = 3,
}

local function wallmounted_like_after_place(pos, placer, itemstack, pointed_thing)
	local dir = pointed_thing.under - pointed_thing.above
	local facedir = 0

	if dir.x == 1 then
		facedir = facedir_enum.axis_px
	elseif dir.x == -1 then
		facedir = facedir_enum.axis_nx
	elseif dir.y == 1 then
		facedir = facedir_enum.axis_py
	elseif dir.y == -1 then
		facedir = facedir_enum.axis_ny
	elseif dir.z == 1 then
		facedir = facedir_enum.axis_pz
	elseif dir.z == -1 then
		facedir = facedir_enum.axis_nz
	end

	local node = core.get_node(pos)
	node.param2 = facedir
	core.swap_node(pos, node)
end

function mcl_multiface.test_wallmounted_face (pos, axis, dir)
	local node = core.get_node (pos)
	local def = core.registered_nodes[node.name]
	if not def or not def.walkable then
		return false
	end

	local boxes = core.get_node_boxes ("collision_box", pos)
	local shape = mcl_util.decompose_AABBs (boxes)
	local face = shape and shape:select_face (axis, dir * 0.5)
	return face and face:equal_p (SOLID_FACE)
end

local function test_wallmounted_face_with_pointed_thing (pointed_thing)
	local dir = vector.subtract (pointed_thing.under,
				     pointed_thing.above)
	local axis, param2

	if dir.x == 1 then
		axis, dir = "x", -1
		param2 = 2
	elseif dir.x == -1 then
		axis, dir = "x", 1
		param2 = 3
	elseif dir.z == 1 then
		axis, dir = "z", -1
		param2 = 4
	elseif dir.z == -1 then
		axis, dir = "z", 1
		param2 = 5
	elseif dir.y == 1 then
		axis, dir = "y", -1
		param2 = 0
	elseif dir.y == -1 then
		axis, dir = "y", 1
		param2 = 1
	else
		return nil
	end

	if mcl_multiface.test_wallmounted_face (pointed_thing.under, axis, dir) then
		return param2
	else
		return nil
	end
end

local tpl = {
	drawtype = "nodebox",
	use_texture_alpha = "clip",
	walkable = false,
	paramtype2 = "facedir",
	groups = {
		handy = 1, axey = 1, shearsy = 1, swordy = 1, deco_block = 1, dig_by_piston = 1,
		unsticky = 1, multiface = 1,
	},
	drop = "",
	_mcl_shears_drop = true,
	node_placement_prediction = "",
	paramtype = "light",
	sunlight_propagates = true,
	after_place_node = wallmounted_like_after_place
}

local side_variants = {
	{false, false, false, false},
	{true, false, false, false},
	{true, false, true, false},
	{true, true, false, false},
	{true, true, true, false},
	{true, true, true, true},
}

local function decompose_facedir(facedir)
	return bit.band(facedir, facedir_enum.axis_mask), bit.band(facedir, facedir_enum.rotation_mask)
end

local function compose_facedir(axis, rotation)
	return bit.bor(axis, rotation)
end

local function index_modulo(idx, wraparound)
	-- The mathematical function `f(x) = x % n`, widely used in index related operations,
	-- which was translated by [1, 1] to account for lua indexing starting with 1
	return ((idx - 1) % wraparound) + 1
end

local function value_rotate(rotation, v1, v2, v3, v4)
	assert(rotation < 4 and rotation > -4)
	if rotation == 0 then
		return v1, v2, v3, v4
	elseif rotation == 1 then
		return v4, v1, v2, v3
	elseif rotation == 2 then
		return v3, v4, v1, v2
	elseif rotation == 3 then
		return v2, v3, v4, v1
	elseif rotation < 0 then
		return value_rotate(4 + rotation, v1, v2, v3, v4)
	end
end

local function faces_rotate(faces, rotation)
	faces[1], faces[2], faces[3], faces[4] = value_rotate(rotation, faces[1], faces[2], faces[3], faces[4])
end

local function get_multiface_name_from_canonical_faces(nodename_root, canonical_faces)
	local str_buf = {nodename_root, "_"}
	for _, face in pairs(canonical_faces) do
		table.insert(str_buf, face and "1" or "0")
	end
	return table.concat(str_buf)
end

local function map_canonical_faces_to_absolute_faces(faces, axis, rotation)
	faces = table.copy(faces)
	faces_rotate(faces, rotation)

	local back = faces[5]

	--          +X        -X        +Y       -Y         +Z        -Z
	if axis == facedir_enum.axis_py then
		return {faces[4], faces[2], true,     back,     faces[3], faces[1]}
	elseif axis == facedir_enum.axis_ny then
		return {faces[2], faces[4], back,     true,     faces[3], faces[1]}
	elseif axis == facedir_enum.axis_px then
		return {true,     back,     faces[2], faces[4], faces[3], faces[1]}
	elseif axis == facedir_enum.axis_nx then
		return {back,     true,     faces[4], faces[2], faces[3], faces[1]}
	elseif axis == facedir_enum.axis_pz then
		return {faces[4], faces[2], faces[1], faces[3], true,     back}
	elseif axis == facedir_enum.axis_nz then
		return {faces[4], faces[2], faces[3], faces[1], back,     true}
	end
end

local function transform_faces_to_canonical_faces(faces)
	for _, side_variant in pairs(side_variants) do
		for offset_rotation = 0, 3 do
			local matches = true
			for i = 1, 4 do
				local shifted_idx = index_modulo(i + offset_rotation, 4)
				if side_variant[shifted_idx] ~= faces[i] then
					matches = false
					break
				end
			end

			if matches then
				for i = 1, 4 do
					faces[i] = side_variant[i]
				end
				return 4 - offset_rotation
			end
		end
	end

	error("Canonical form could not be found")
end

local function pointed_thing_to_axis(pointed_thing)
	if pointed_thing.under.x - pointed_thing.above.x == 1 then
		return facedir_enum.axis_px
	elseif pointed_thing.under.x - pointed_thing.above.x == -1 then
		return facedir_enum.axis_nx
	elseif pointed_thing.under.y - pointed_thing.above.y == 1 then
		return facedir_enum.axis_py
	elseif pointed_thing.under.y - pointed_thing.above.y == -1 then
		return facedir_enum.axis_ny
	elseif pointed_thing.under.z - pointed_thing.above.z == 1 then
		return facedir_enum.axis_pz
	elseif pointed_thing.under.z - pointed_thing.above.z == -1 then
		return facedir_enum.axis_nz
	end
end

local function map_absolute_faces_to_node(absolute_faces, root_name)
	local selected_idx_as_front = -1

	for i = 1, #absolute_faces do
		if absolute_faces[i] then
			selected_idx_as_front = i
		end
	end

	if selected_idx_as_front == -1 then
		return {name = "air", param2 = 0}
	end

	local selected_axis_as_front

	if selected_idx_as_front == 1 then
		selected_axis_as_front = facedir_enum.axis_px
	elseif selected_idx_as_front == 2 then
		selected_axis_as_front = facedir_enum.axis_nx
	elseif selected_idx_as_front == 3 then
		selected_axis_as_front = facedir_enum.axis_py
	elseif selected_idx_as_front == 4 then
		selected_axis_as_front = facedir_enum.axis_ny
	elseif selected_idx_as_front == 5 then
		selected_axis_as_front = facedir_enum.axis_pz
	elseif selected_idx_as_front == 6 then
		selected_axis_as_front = facedir_enum.axis_nz
	end

	local faces
	-- The below code is an exact inverse of the mapping in `map_canonical_faces_to_absolute_faces`
	if selected_axis_as_front == facedir_enum.axis_px then
		faces = {absolute_faces[6],absolute_faces[3], absolute_faces[5], absolute_faces[4], absolute_faces[2]}
	elseif selected_axis_as_front == facedir_enum.axis_nx then
		faces = {absolute_faces[6], absolute_faces[4], absolute_faces[5], absolute_faces[3], absolute_faces[1]}
	elseif selected_axis_as_front == facedir_enum.axis_py then
		faces = {absolute_faces[6], absolute_faces[2], absolute_faces[5], absolute_faces[1], absolute_faces[4]}
	elseif selected_axis_as_front == facedir_enum.axis_ny then
		faces = {absolute_faces[6], absolute_faces[1], absolute_faces[5], absolute_faces[2], absolute_faces[3]}
	elseif selected_axis_as_front == facedir_enum.axis_pz then
		faces = {absolute_faces[3], absolute_faces[2], absolute_faces[4], absolute_faces[1], absolute_faces[6]}
	elseif selected_axis_as_front == facedir_enum.axis_nz then
		faces = {absolute_faces[4], absolute_faces[2], absolute_faces[3], absolute_faces[1], absolute_faces[5]}
	end

	local rotation = transform_faces_to_canonical_faces(faces)

	local variant_name = get_multiface_name_from_canonical_faces(root_name, faces)

	return {name = variant_name, param2 = compose_facedir(selected_axis_as_front, rotation)}
end

local function multiface_merge (node, itemstack, pos, place_axis, placer)
	if placer:is_player () then
		local name = placer:get_player_name ()
		if core.is_protected (pos, name) then
			core.record_protection_violation (pos, name)
			return itemstack
		end
	end

	local def = core.registered_nodes[node.name]

	local faces = table.copy(def._mcl_multiface_canonical_faces)
	local axis, rotation = decompose_facedir(node.param2)

	local absolute_faces = map_canonical_faces_to_absolute_faces(faces, axis, rotation)

	local face_idx = -1
	if place_axis == facedir_enum.axis_px then
		face_idx = 1
	elseif place_axis == facedir_enum.axis_nx then
		face_idx = 2
	elseif place_axis == facedir_enum.axis_py then
		face_idx = 3
	elseif place_axis == facedir_enum.axis_ny then
		face_idx = 4
	elseif place_axis == facedir_enum.axis_pz then
		face_idx = 5
	elseif place_axis == facedir_enum.axis_nz then
		face_idx = 6
	end

	if absolute_faces[face_idx] then
		return
	end

	absolute_faces[face_idx] = true

	local new_node = map_absolute_faces_to_node(absolute_faces, def._mcl_multiface_name_root)

	core.swap_node(pos, new_node)

	local name = placer:get_player_name()
	if not placer:is_player()
			or not core.is_creative_enabled(name) then
		itemstack:take_item()
	end

	return itemstack
end

function tpl.on_place (itemstack, placer, pointed_thing)
	if pointed_thing.type ~= "node" then
		-- No interaction possible with entities.
		return itemstack
	end

	local name = core.get_node (pointed_thing.under).name
	local def = core.registered_nodes[name]
	if not (def and def.walkable) then
		return itemstack
	end

	local param2 = test_wallmounted_face_with_pointed_thing (pointed_thing)
	if not param2 then
		return itemstack
	end

	local node_at_pos = core.get_node (pointed_thing.above)
	if core.get_item_group (node_at_pos.name, "multiface") > 0 then
		itemstack = multiface_merge (node_at_pos, itemstack,
					       pointed_thing.above, pointed_thing_to_axis(pointed_thing),
					       placer)
		return itemstack
	end

	return core.item_place_node (itemstack, placer,
				     pointed_thing, param2)
end

local front_nodebox = {
		-0.5, 0.495, -0.5,
		0.5, 0.500, 0.5,
	}

local faces_nodeboxes = {
	{
		-0.5, -0.5, -0.500,
		0.5, 0.5, -0.495,
	},
	{
		-0.500, -0.5, -0.5,
		-0.495, 0.5, 0.5,
	},
	{
		-0.5, -0.5, 0.495,
		0.5, 0.5, 0.500,
	},
	{
		0.495, -0.5, -0.5,
		0.500, 0.5, 0.5,
	},
	{
		-0.5, -0.500, -0.5,
		0.5, -0.495, 0.5,
	},
}

function mcl_multiface.register_multiface_node(name, def)
	local first_iteration = true
	for i = 0, 1 do
		for _, side_variant in pairs(side_variants) do
			local faces = {side_variant[1], side_variant[2], side_variant[3], side_variant[4], i == 1}
			local variant_name = get_multiface_name_from_canonical_faces(name, faces)

			local nodeboxes = {front_nodebox}

			for j, nodebox in pairs(faces_nodeboxes) do
				if faces[j] then
					table.insert(nodeboxes, nodebox)
				end
			end

			core.register_node(":" .. variant_name, table.merge(tpl, def, {
				description = def.description .. "(INTERNAL: " .. variant_name:sub(-5) .. ")",
				groups = table.merge (tpl.groups or {}, {
					not_in_creative_inventory = first_iteration and 1 or 0,
				}, def.groups),
				node_box = {
					type = "fixed",
					fixed = nodeboxes,
				},
				-- _mcl_shears_drop = shears_drops,
				_mcl_multiface_canonical_faces = faces,
				_mcl_multiface_name_root = name,
				_mcl_basename = name .. "_00000"
			}))

			first_iteration = false
		end
	end
end
