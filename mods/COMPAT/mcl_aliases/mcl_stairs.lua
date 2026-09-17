-- Aliases for backwards-compability with 0.21.0

local materials = {
	"wood", "junglewood", "sprucewood", "acaciawood", "birchwood", "darkwood",
	"cobble", "brick_block", "sandstone", "redsandstone", "stonebrick",
	"quartzblock", "purpur_block", "nether_brick"
}

for m=1, #materials do
	local mat = materials[m]
	core.register_alias("stairs:slab_"..mat, "mcl_stairs:slab_"..mat)
	core.register_alias("stairs:stair_"..mat, "mcl_stairs:stair_"..mat)

	-- corner stairs
	core.register_alias("stairs:stair_"..mat.."_inner", "mcl_stairs:stair_"..mat.."_inner")
	core.register_alias("stairs:stair_"..mat.."_outer", "mcl_stairs:stair_"..mat.."_outer")
end

local old, new
local bamboo_kludge = {
	["wood"] =	"plank",
	["tree_bark"] =	"block"
}

for oldname, newname in pairs({
	[""] = 			"oak",
	["acacia"] = 		"acacia",
	["bamboo_"] =	 	"bamboo",
	["birch"] = 		"birch",
	["crimson_hyphae_"] = 	"crimson",
	["cherry"] = 		"cherry_blossom",
	["dark"] = 		"dark_oak",
	["jungle"] = 		"jungle",
	["mangrove_"] = 	"mangrove",
	["spruce"] = 		"spruce",
	["warped_hyphae_"] = 	"warped",
}) do
	for oldtype, newtype in pairs({
		["wood"]	= "",
		["tree_bark"]	= "_bark"
	}) do
		old = oldname .. (oldname == "bamboo_" and bamboo_kludge[oldtype] or oldtype)
		new = newname .. newtype
		if not (newname == "cherry" and oldtype == "tree_bark") then
			core.register_alias("mcl_stairs:stair_"..old, "mcl_stairs:stair_"..new)
			core.register_alias("mcl_stairs:stair_"..old.."_inner", "mcl_stairs:stair_"..new.."_inner")
			core.register_alias("mcl_stairs:stair_"..old.."_outer", "mcl_stairs:stair_"..new.."_outer")
			core.register_alias("mcl_stairs:slab_"..old, "mcl_stairs:slab_"..new)
			core.register_alias("mcl_stairs:slab_"..old.."_top", "mcl_stairs:slab_"..new.."_top")
			core.register_alias("mcl_stairs:slab_"..old.."_double", "mcl_stairs:slab_"..new.."_double")
		end
	end
end

core.register_alias("stairs:slab_stone", "mcl_stairs:slab_stone")
core.register_alias("stairs:slab_stone_double", "mcl_stairs:slab_stone_double")

core.register_alias("mcl_stairs:slab_blackstone_chiseled_polished_top", "mcl_stairs:slab_blackstone_polished_top")
core.register_alias("mcl_stairs:slab_blackstone_chiseled_polished", "mcl_stairs:slab_blackstone_polished")
core.register_alias("mcl_stairs:slab_blackstone_chiseled_polished_double", "mcl_stairs:slab_blackstone_polished_double")
core.register_alias("mcl_stairs:stair_blackstone_chiseled_polished", "mcl_stairs:stair_blackstone_polished")
core.register_alias("mcl_stairs:stair_blackstone_chiseled_polished_inner", "mcl_stairs:stair_blackstone_polished_inner")
core.register_alias("mcl_stairs:stair_blackstone_chiseled_polished_outer", "mcl_stairs:stair_blackstone_polished_outer")

for _,v in pairs({"","_exposed","_weathered"}) do
	core.register_alias("mcl_stairs:stair_waxed_copper"..v.."_cut","mcl_stairs:stair_copper"..v.."_cut_preserved")
	core.register_alias("mcl_stairs:stair_waxed_copper"..v.."_cut_inner","mcl_stairs:stair_copper"..v.."_cut_inner_preserved")
	core.register_alias("mcl_stairs:stair_waxed_copper"..v.."_cut_outer","mcl_stairs:stair_copper"..v.."_cut_outer_preserved")
	core.register_alias("mcl_stairs:slab_waxed_copper"..v.."_cut","mcl_stairs:slab_copper"..v.."_cut_preserved")
	core.register_alias("mcl_stairs:slab_waxed_copper"..v.."_cut_top","mcl_stairs:slab_copper"..v.."_cut_top_preserved")
	core.register_alias("mcl_stairs:slab_waxed_copper"..v.."_cut_double","mcl_stairs:slab_copper"..v.."_cut_double_preserved")
end

core.register_alias("mcl_stairs:stair_waxed_copper_oxidized_cut","mcl_stairs:stair_copper_oxidized_cut")
core.register_alias("mcl_stairs:stair_waxed_copper_oxidized_cut_inner","mcl_stairs:stair_copper_oxidized_cut_inner")
core.register_alias("mcl_stairs:stair_waxed_copper_oxidized_cut_outer","mcl_stairs:stair_copper_oxidized_cut_outer")
core.register_alias("mcl_stairs:slab_waxed_copper_oxidized_cut","mcl_stairs:slab_copper_oxidized_cut")
core.register_alias("mcl_stairs:slab_waxed_copper_oxidized_cut_top","mcl_stairs:slab_copper_oxidized_cut_top")
core.register_alias("mcl_stairs:slab_waxed_copper_oxidized_cut_double","mcl_stairs:slab_copper_oxidized_cut_double")

local function register_alias_if_not_exists(alias, name)
	if not core.registered_nodes[alias] then
		core.register_alias(alias, name)
	end
end
core.register_on_mods_loaded(function()
	for name, cdef in pairs(mcl_dyes.colors) do
		register_alias_if_not_exists("mcl_stairs:slab_concrete_"..cdef.mcl2, "mcl_stairs:slab_concrete_"..name)
		register_alias_if_not_exists("mcl_stairs:slab_concrete_"..cdef.mcl2.."_double", "mcl_stairs:slab_concrete_"..name.."_double")
		register_alias_if_not_exists("mcl_stairs:stair_concrete_"..cdef.mcl2, "mcl_stairs:stair_concrete_"..name)
		register_alias_if_not_exists("mcl_stairs:stair_concrete_"..cdef.mcl2.."_inner", "mcl_stairs:stair_concrete_"..name.."_inner")
		register_alias_if_not_exists("mcl_stairs:stair_concrete_"..cdef.mcl2.."_outer", "mcl_stairs:stair_concrete_"..name.."_outer")
	end
end)
