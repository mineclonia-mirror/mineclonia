local trees = {
	["oak"] =		{"mcl_core:",		"",		"oak"},
	["acacia"] =		{"mcl_core:",		"acacia"},
	["birch"] =		{"mcl_core:",		"birch"},
	["dark_oak"] =		{"mcl_core:",		"dark",		"dark_oak"},
	["jungle"] =		{"mcl_core:",		"jungle"},
	["spruce"] =		{"mcl_core:",		"spruce"},
	["cherry_blossom"] =	{"mcl_cherry_blossom:",	"cherry",	"cherrytree"},
}

for t, n in pairs(trees) do
	core.register_alias(n[1]..n[2].."sapling","mcl_trees:sapling_"..t)
	core.register_alias(n[1]..n[2].."leaves","mcl_trees:leaves_"..t)
	core.register_alias(n[1]..n[2].."leaves_orphan","mcl_trees:leaves_"..t.."_orphan")
	core.register_alias(n[1]..n[2].."wood","mcl_trees:wood_"..t)
	core.register_alias(n[1]..n[2].."tree","mcl_trees:tree_"..t)
	core.register_alias(n[1]..n[2].."tree".."_bark","mcl_trees:bark_"..t)
	core.register_alias(n[1].."stripped_"..(n[3] or n[2]),"mcl_trees:stripped_"..t)
	core.register_alias(n[1].."stripped_"..(n[3] or n[2]).."_bark","mcl_trees:bark_stripped_"..t)
end

-- only leaves
core.register_alias("mcl_lush_caves:azalea_leaves", "mcl_trees:leaves_azalea")
core.register_alias("mcl_lush_caves:azalea_leaves_flowering", "mcl_trees:leaves_azalea_flowering")

-- too irregular for simple loop
core.register_alias("mcl_mangrove:mangrove_tree","mcl_trees:tree_mangrove")
core.register_alias("mcl_mangrove:mangroveleaves","mcl_trees:leaves_mangrove")
core.register_alias("mcl_mangrove:mangroveleaves_orphan","mcl_trees:leaves_mangrove_orphan")
core.register_alias("mcl_mangrove:mangrove_wood","mcl_trees:wood_mangrove")
core.register_alias("mcl_mangrove:mangrove_tree_bark","mcl_trees:bark_mangrove")
core.register_alias("mcl_mangrove:mangrove_stripped_trunk","mcl_trees:stripped_mangrove")
core.register_alias("mcl_mangrove:mangrove_stripped_bark","mcl_trees:bark_stripped_mangrove")

core.register_alias("mcl_crimson:crimson_hyphae","mcl_trees:tree_crimson")
core.register_alias("mcl_crimson:crimson_hyphae_wood","mcl_trees:wood_crimson")
core.register_alias("mcl_crimson:crimson_hyphae_bark","mcl_trees:bark_crimson")
core.register_alias("mcl_crimson:stripped_crimson_hyphae","mcl_trees:stripped_crimson")
core.register_alias("mcl_crimson:stripped_crimson_hyphae_bark","mcl_trees:bark_stripped_crimson")

core.register_alias("mcl_crimson:warped_hyphae","mcl_trees:tree_warped")
core.register_alias("mcl_crimson:warped_hyphae_wood","mcl_trees:wood_warped")
core.register_alias("mcl_crimson:warped_hyphae_bark","mcl_trees:bark_warped")
core.register_alias("mcl_crimson:stripped_warped_hyphae","mcl_trees:stripped_warped")
core.register_alias("mcl_crimson:stripped_warped_hyphae_bark","mcl_trees:bark_stripped_warped")

core.register_alias("mcl_bamboo:bamboo_block","mcl_trees:tree_bamboo")
core.register_alias("mcl_bamboo:bamboo_plank","mcl_trees:wood_bamboo")
core.register_alias("mcl_bamboo:bamboo_block_stripped","mcl_trees:stripped_bamboo")

-- legacy dark oak
core.register_alias("mcl_core:big_oakwood","mcl_trees:wood_dark_oak")
core.register_alias("mcl_core:big_oaktree_bark","mcl_trees:bark_dark_oak")
core.register_alias("mcl_core:big_oaksapling","mcl_trees:sapling_dark_oak")

-- ancient mtg legacy
core.register_alias("default:tree","mcl_trees:tree_oak")
core.register_alias("default:leaves","mcl_trees:leaves_oak")
core.register_alias("default:wood","mcl_trees:wood_oak")
core.register_alias("default:sapling","mcl_trees:sapling_oak")
core.register_alias("default:acacia_tree", "mcl_core:acaciatree")
core.register_alias("default:acacia_leaves", "mcl_core:acacialeaves")
