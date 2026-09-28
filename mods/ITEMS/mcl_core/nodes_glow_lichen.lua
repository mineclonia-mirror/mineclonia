local S = core.get_translator(core.get_current_modname())

local absolute_faces_to_dirs = {
	vector.new(1, 0, 0),
	vector.new(-1, 0, 0),
	vector.new(0, 1, 0),
	vector.new(0, -1, 0),
	vector.new(0, 0, 1),
	vector.new(0, 0, -1),
}

-- map each index in absolute_faces to an absolute_faces table that only contains that face
local attachments = {
	{true, false,  false, false, false, false},
	{false, true,  false, false, false, false},
	{false, false, true,  false, false, false},
	{false, false, false, true,  false, false},
	{false, false, false, false, true,  false},
	{false, false, false, false, false, true},
}

-- map each index in absolute_faces to the axis accepted by mcl_multiface.test_wallmounted_face()
local absolute_faces_to_axis = {
	"x",
	"x",
	"y",
	"y",
	"z",
	"z",
}

-- map each index in absolute_faces to the dir accepted by mcl_multiface.test_wallmounted_face()
local absolute_faces_to_axis_dir = {
	-1,
	1,
	-1,
	1,
	-1,
	1
}

-- map each index in absolute_faces to a list of positions "around" that face
local sideways_spread = {
	{
		vector.new(0, 1, 0),
		vector.new(0, -1, 0),
		vector.new(0, 0, 1),
		vector.new(0, 0, -1),
	},
	{
		vector.new(0, 1, 0),
		vector.new(0, -1, 0),
		vector.new(0, 0, 1),
		vector.new(0, 0, -1),
	},
	{
		vector.new(1, 0, 0),
		vector.new(-1, 0, 0),
		vector.new(0, 0, 1),
		vector.new(0, 0, -1),
	},
	{
		vector.new(1, 0, 0),
		vector.new(-1, 0, 0),
		vector.new(0, 0, 1),
		vector.new(0, 0, -1),
	},
	{
		vector.new(1, 0, 0),
		vector.new(-1, 0, 0),
		vector.new(0, 1, 0),
		vector.new(0, -1, 0),
	},
	{
		vector.new(1, 0, 0),
		vector.new(-1, 0, 0),
		vector.new(0, 1, 0),
		vector.new(0, -1, 0),
	}
}

-- map each index in absolute_faces to an entry that describes how it should spread around a block
-- offset - the offset from that block at which the lichen will be placed
-- face - an index in absolute_faces that would connect to that block. E.g if spreading in +X, the face has to be -X
-- opposite_to_face - opposite of `face`. Used by the algorithm so it knows not to spread "through" a block
local block_spread = {
	{
		offset = vector.new(1, 0, 0),
		face = 2,
		opposite_to_face = 1,
	},
	{
		offset = vector.new(-1, 0, 0),
		face = 1,
		opposite_to_face = 2,
	},
	{
		offset = vector.new(0, 1, 0),
		face = 4,
		opposite_to_face = 3,
	},
	{
		offset = vector.new(0, -1, 0),
		face = 3,
		opposite_to_face = 4,
	},
	{
		offset = vector.new(0, 0, 1),
		face = 6,
		opposite_to_face = 5,
	},
	{
		offset = vector.new(0, 0, -1),
		face = 5,
		opposite_to_face = 6,
	}
}

local function lichen_on_bonemeal(itemstack, placer, pointed_thing, pos, node)
	-- The algorithm collects canditate positions for spreading, and the face at which the lichen should connect
	--
	-- The possible canditates fall into three categories:
	-- - If the face isn't occupied yet, its a canditate for spreading
	-- - If the face is occupied, it adds canditates for the 4 positions parallel with it (E.g. for +X, its +-Z and +-Y)
	-- - If the face is occupied, it adds canditates for the positions around the supporting block, except for the opposite face
	--   and the current node (since its already confirmed to be occupied)
	--
	-- This "canditate gathering" step doesn't bother with checking whether the placement is possilble, since that would
	-- require reading map's state for every canditate. But there is a very likely case that one of the first candidates gets
	-- chosen, and all those checks were made in vain. Hence, placement checks are made when attempting to place canditates
	--
	-- Then, the canditate list is shuffled
	--
	-- And finally, it selects canditates, checks whether a canditate is valid, and if so, places it and returns. Otherwise it
	-- move onto another candidate

	local absolute_faces = mcl_multiface.get_node_absolute_faces(node)
	local spread_canditates = {}

	for i, is_occupied in pairs(absolute_faces) do
		if is_occupied then
			local offset_vector = pos + absolute_faces_to_dirs[i]
			-- Spreading to the side
			for _, spread in pairs(sideways_spread[i]) do
				table.insert(spread_canditates, {pos = pos + spread, face = i})
			end

			-- Spreading around the supporting block
			for _, spread in pairs(block_spread) do
				if spread.opposite_to_face ~= i and spread.face ~= i then
					table.insert(spread_canditates, {pos = offset_vector + spread.offset, face = spread.face})
				end
			end
		else
			-- Spreading to another face
			table.insert(spread_canditates, {pos = pos, face = i})
		end
	end

	table.shuffle(spread_canditates)

	while #spread_canditates > 0 do
		local canditate = spread_canditates[#spread_canditates]
		spread_canditates[#spread_canditates] = nil

		local offset_node = core.get_node(canditate.pos)

		if offset_node.name == "air" then
			if mcl_multiface.test_wallmounted_face(canditate.pos + absolute_faces_to_dirs[canditate.face], absolute_faces_to_axis[canditate.face], absolute_faces_to_axis_dir[canditate.face]) then
				local new_node = mcl_multiface.map_absolute_faces_to_node(attachments[canditate.face], "mcl_core:glow_lichen")
				core.swap_node(canditate.pos, new_node)
				return true
			end
		elseif core.get_item_group(offset_node.name, "glow_lichen") > 0 then
			local offset_absolute_faces = mcl_multiface.get_node_absolute_faces(offset_node)
			if not offset_absolute_faces[canditate.face]
					and mcl_multiface.test_wallmounted_face(canditate.pos + absolute_faces_to_dirs[canditate.face], absolute_faces_to_axis[canditate.face], absolute_faces_to_axis_dir[canditate.face]) then

				offset_absolute_faces[canditate.face] = true
				local new_node = mcl_multiface.map_absolute_faces_to_node(offset_absolute_faces, "mcl_core:glow_lichen")
				core.swap_node(canditate.pos, new_node)
				return true
			end
		end
	end

	return false
end

mcl_multiface.register_multiface_node("mcl_core:glow_lichen", {
	description = S ("Glow Lichen"),
	_doc_items_longdesc = S ("Naturally generating non-solid block that emits a faint light and can attach to any surface of a solid block."),
	inventory_image = "mcl_core_glow_lichen.png",
	wield_image = "mcl_core_glow_lichen.png",
	tiles = {"mcl_core_glow_lichen.png",},
	sounds = mcl_sounds.node_sound_leaves_defaults (),
	groups = {compostability = 50, flammable = 2, fire_encouragement = 15, fire_flammability = 100, glow_lichen = 1},
	light_source = 7,
	_mcl_hardness = 0.2,
	_mcl_shears_drop = true,
	_on_bone_meal = lichen_on_bonemeal
})
