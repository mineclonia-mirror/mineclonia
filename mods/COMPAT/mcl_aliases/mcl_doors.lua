local doors = {
	["acacia"]		= "mcl_doors",
	["bamboo"]		= "mcl_bamboo",
	["birch"]		= "mcl_doors",
	["cherry_blossom"]	= "mcl_cherry_blossom",
	["crimson"]		= "mcl_crimson",
	["dark_oak"]		= "mcl_doors",
	["iron"]		= "mcl_doors",
	["jungle"]		= "mcl_doors",
	["mangrove"]		= "mcl_mangrove",
	["oak"]			= "mcl_doors",
	["spruce"]		= "mcl_doors",
	["warped"]		= "mcl_crimson",
}
for mat, mod in pairs(doors) do
	local oldmat = mat == "cherry_blossom" and "cherry" or mat == "oak" and "wooden" or mat
	for suf1, suf2 in pairs({
                -- legacy doors
                [""] = "",
                ["_b_1"] = "_b_1",
                ["_t_1"] = "_t_1",
                ["_b_2"] = "_b_2",
                ["_t_2"] = "_t_2",
                -- mcl2/voxelibre's strange _3 and _4 doors
                ["_b_3"] = "_b_1",
                ["_t_3"] = "_t_1",
                ["_b_4"] = "_b_2",
                ["_t_4"] = "_t_2",
        }) do
		core.register_alias(mod..":"..oldmat.."_door"..suf1, "mcl_doors:door_"..mat..suf2)
	end
	-- legacy trapdoors
	oldmat = mat == "oak" and "" or oldmat .. "_"
	core.register_alias(mod..":"..oldmat.."trapdoor","mcl_doors:trapdoor_"..mat)
	core.register_alias(mod..":"..oldmat.."trapdoor_open","mcl_doors:trapdoor_"..mat.."_open")
	core.register_alias(mod..":"..oldmat.."trapdoor_ladder","mcl_doors:trapdoor_"..mat.."_open")
end

core.register_alias("mcl_doors:dark_door","mcl_doors:door_dark_oak") -- realy?

-- ancient doors
local doornames = {
	["door"] = "wooden_door",
	["door_jungle"] = "jungle_door",
	["door_spruce"] = "spruce_door",
	["door_dark_oak"] = "dark_oak_door",
	["door_birch"] = "birch_door",
	["door_acacia"] = "acacia_door",
	["door_iron"] = "iron_door",
}

for oldname, newname in pairs(doornames) do
	core.register_alias("doors:"..oldname, "mcl_doors:"..newname)
	core.register_alias("doors:"..oldname.."_t_1", "mcl_doors:"..newname.."_t_1")
	core.register_alias("doors:"..oldname.."_b_1", "mcl_doors:"..newname.."_b_1")
	core.register_alias("doors:"..oldname.."_t_2", "mcl_doors:"..newname.."_t_2")
	core.register_alias("doors:"..oldname.."_b_2", "mcl_doors:"..newname.."_b_2")
end

core.register_alias("doors:trapdoor", "mcl_doors:trapdoor_oak")
core.register_alias("doors:trapdoor_open", "mcl_doors:trapdoor_oak_open")
core.register_alias("doors:iron_trapdoor", "mcl_doors:iron_trapdoor")
core.register_alias("doors:iron_trapdoor_open", "mcl_doors:iron_trapdoor_open")
