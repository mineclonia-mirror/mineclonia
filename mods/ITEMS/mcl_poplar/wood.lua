local S = core.get_translator(core.get_current_modname())

local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)

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
