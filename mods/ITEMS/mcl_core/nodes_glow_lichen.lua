local S = core.get_translator(core.get_current_modname())

local dirs = {
	{ 1, 0, 0, 1, "z", -1, 3, }, -- Spread north, attaching to a south face.
	{ 2, -1, 0, 0, "x", 1, 4, }, -- Spread west, attaching to an east face.
	{ 3, 0, 0, -1, "z", 1, 1, }, -- Spread south, attaching to a north face.
	{ 4, 1, 0, 0, "x", -1, 2, }, -- Spread east, attaching to a west face.
	{ 5, 0, 1, 0, "y", -1, 6, }, -- Spread down, attaching to a top face.
	{ 6, 0, -1, 0, "y", 1, 5, }, -- Spread up, attaching to a bottom face.
}

local attachments = {
	{ true, false, false, false, false, false, },
	{ false, true, false, false, false, false, },
	{ false, false, true, false, false, false, },
	{ false, false, false, true, false, false, },
	{ false, false, false, false, true, false, },
	{ false, false, false, false, false, true, },
}

local function get_multiface_attachments_as_table (node)
	local north, west, south, east, up, down = mcl_multiface.get_multiface_attachments (node)
	return {
		north, west, south, east, up, down,
	}
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
	_on_bone_meal = function (itemstack, placer, pointed_thing, pos, node)
		local params = get_multiface_attachments_as_table (node)
		local spread_poses = {}

		-- Evaluate where this glow lichen block may spread.  A glow
		-- lichen block is permitted to spread from its current
		-- position to a contacting face or to the sides of any block
		-- to which it is attached except along the axis of its
		-- attachment.

		for i = 1, #dirs do
			local dir = dirs[i]
			if not params[dir[1]] then
				-- Attempt to spread to an adjacent face.
				local off = vector.offset (pos, dir[2], dir[3], dir[4])
				if mcl_multiface.test_wallmounted_face (off, dir[5], dir[6]) then
					table.insert (spread_poses, {
						position = pos,
						spread_dir = i,
					})
				end
			else
				-- Or faces around this node.
				local pos_behind = vector.offset (pos, dir[2], dir[3], dir[4])
				for j = 1, #dirs do
					local dir1 = dirs[j]
					-- But not behind it.
					if j ~= i then
						-- Spread around this node.
						if mcl_multiface.test_wallmounted_face (pos_behind, dir1[5], dir1[6]) then
							table.insert (spread_poses, {
								position = vector.offset (pos_behind, -dir1[2],
											  -dir1[3], -dir1[4]),
								spread_dir = j,
							})
						end

						-- Spread crosswise.
						local off = vector.offset (pos_behind, dir1[2],
									   dir1[3], dir1[4])
						if mcl_multiface.test_wallmounted_face (off, dir[5], dir[6]) then
							local off_parallel_above
								= vector.offset (off, -dir[2], -dir[3],
										 -dir[4])
							table.insert (spread_poses, {
								position = off_parallel_above,
								spread_dir = i,
							})
						end
					end
				end
			end
		end

		if #spread_poses == 0 then
			return false
		end

		table.shuffle (spread_poses)

		-- Iterate through each eligible position and attempt to add a
		-- lichen attachment at that position and in the direction
		-- specified.
		for _, attachment in ipairs (spread_poses) do
			local node = core.get_node (attachment.position)
			local attachments = attachments[attachment.spread_dir]
			if core.get_item_group (node.name, "glow_lichen") > 0 then
				-- Merge attachments.
				local current = get_multiface_attachments_as_table (node)
				for i = 1, #attachments do
					current[i] = attachments[i] or current[i]
				end
				local name, param2 = mcl_multiface.get_multiface_node_data ("mcl_core:glow_lichen", unpack (current))
				if name ~= node.name or param2 ~= node.param2 then
					core.set_node (attachment.position, {
								   name = name,
								   param2 = param2,
					})
					return true
				end
			elseif node.name == "air" then
				local name, param2 = mcl_multiface.get_multiface_node_data ("mcl_core:glow_lichen", unpack (attachments))
				core.set_node (attachment.position, {
							   name = name,
							   param2 = param2,
				})
				return true
			end
		end

		return false
	end
})
