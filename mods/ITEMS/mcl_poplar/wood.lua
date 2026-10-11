local S = core.get_translator(core.get_current_modname())

local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)

local shelf_mushroom_canditates = {
	{
		offset_x = 1,
		offset_z = 0,
		param2 = 3,
	},
	{
		offset_x = -1,
		offset_z = 0,
		param2 = 1,
	},
	{
		offset_x = 0,
		offset_z = 1,
		param2 = 2,
	},
	{
		offset_x = 0,
		offset_z = -1,
		param2 = 0,
	}
}

-- This function's implementation is completely arbitrary and doesn't reflect how minecraft actually does it
local function poplar_sapling_after_grow(pos)
	for y_offset = 2, 3 do
		for candidate_idx = 1, 4 do
			if math.random() > 0.85 then
				local candidate = shelf_mushroom_canditates[candidate_idx]
				local offset_pos = vector.offset(pos, candidate.offset_x, y_offset, candidate.offset_z)
				local node = core.get_node(offset_pos)

				if node.name == "air" then
					core.set_node(offset_pos, {
						name = math.random() > 0.66 and "mcl_poplar:shelf_mushroom_big" or "mcl_poplar:shelf_mushroom",
						param2 = candidate.param2
					})
				end
			end
		end
	end
end

mcl_trees.register_wood("poplar",{
	readable_name = "Poplar",
	sign_color = "#9f8d83",
	tree_schems = {
		-- yellow
		{file = modpath .. "/schematics/mcl_poplar_tree_1_yellow.mts"},
		{file = modpath .. "/schematics/mcl_poplar_tree_2_yellow.mts"},
		{file = modpath .. "/schematics/mcl_poplar_tree_3_yellow.mts"},

		-- orange
		{file = modpath .. "/schematics/mcl_poplar_tree_1_orange.mts"},
		{file = modpath .. "/schematics/mcl_poplar_tree_2_orange.mts"},
		{file = modpath .. "/schematics/mcl_poplar_tree_3_orange.mts"},

		-- red
		{file = modpath .. "/schematics/mcl_poplar_tree_1_red.mts"},
		{file = modpath .. "/schematics/mcl_poplar_tree_2_red.mts"},
		{file = modpath .. "/schematics/mcl_poplar_tree_3_red.mts"},
	},
	tree = { tiles = {"mcl_poplar_log_top.png", "mcl_poplar_log_top.png","mcl_poplar_log.png" }},
	bark = { tiles = {"mcl_poplar_log.png"}},
	sapling = {
		tiles = {"mcl_poplar_sapling.png"},
		inventory_image = "mcl_poplar_sapling.png",
		wield_image = "mcl_poplar_sapling.png",
		_after_grow = poplar_sapling_after_grow,
	},
	potted_sapling = {
		image = "mcl_poplar_sapling.png",
	},
	leaves = false,
	wood = { tiles = {"mcl_poplar_planks.png"}},
	stripped = {
		tiles = {"mcl_poplar_stripped_log_top.png", "mcl_poplar_stripped_log_top.png", "mcl_poplar_stripped_log.png"}
	},
	stripped_bark = {
		tiles = {"mcl_poplar_stripped_log.png"}
	},
	fence = {
		tiles = { "mcl_poplar_planks.png" },
	},
	fence_gate = {
		tiles = { "mcl_poplar_planks.png" },
	},
	door = {
		inventory_image = "mcl_poplar_door_item.png",
		tiles_bottom = {"mcl_poplar_door_bottom.png", "mcl_poplar_door_bottom.png"},
		tiles_top = {"mcl_poplar_door_top.png", "mcl_poplar_door_top.png"}
	},
	trapdoor = {
		tile_front = "mcl_poplar_trapdoor.png",
		tile_side = "mcl_poplar_trapdoor_side.png",
		wield_image = "mcl_poplar_trapdoor.png",
	},
	hanging_sign = true,
})

mcl_trees.register_leaves("leaves_poplar_yellow",
	{
		description = S("Yellow Poplar Leaves"),
		tiles = {"mcl_poplar_leaves_yellow.png"},
		palette = "",
		paramtype2 = "none",
	},
	"mcl_trees:sapling_poplar",
	false,
	{},
	{20, 16, 12, 10}
)

mcl_trees.register_leaves("leaves_poplar_red",
	{
		description = S("Red Poplar Leaves"),
		tiles = {"mcl_poplar_leaves_red.png"},
		palette = "",
		paramtype2 = "none",
	},
	"mcl_trees:sapling_poplar",
	false,
	{},
	{20, 16, 12, 10}
)

mcl_trees.register_leaves("leaves_poplar_orange",
	{
		description = S("Orange Poplar Leaves"),
		tiles = {"mcl_poplar_leaves_orange.png"},
		palette = "",
		paramtype2 = "none",
	},
	"mcl_trees:sapling_poplar",
	false,
	{},
	{20, 16, 12, 10}
)
