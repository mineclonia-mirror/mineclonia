for o, n in pairs({
	["acacia"]		=  "acacia",
	["acaciawood"]		=  "acacia",
	["bamboo"]		=  "bamboo",
	["birch"]		=  "birch",
	["birchwood"]		=  "birch",
	["cherry_blossom"]	=  "cherry_blossom",
	["crimson_hyphae"]	=  "crimson_hyphae",
	["crimson"]		=  "crimson",
	["dark_oak"]		=  "dark_oak",
	["darkwood"]		=  "dark_oak",
	["jungle"]		=  "jungle",
	["junglewood"]		=  "jungle",
	["mangrove"]		=  "mangrove",
	["mangrove_wood"]	=  "mangrove",
	["oak"]			=  "oak",
	["polished_blackstone"]	=  "polished_blackstone",
	["spruce"]		=  "spruce",
	["sprucewood"]		=  "spruce",
	["stone"]		=  "stone",
	["warped_hyphae"]	=  "warped_hyphae",
	["warped"]		=  "warped",
	["wood"]		=  "oak",
}) do
	core.register_alias("mesecons_pressureplates:pressure_plate_"..o.."_off", "mcl_pressureplates:pressure_plate_"..n.."_off")
	core.register_alias("mesecons_pressureplates:pressure_plate_"..o.."_on", "mcl_pressureplates:pressure_plate_"..n.."_on")
end

core.register_alias("mcl_cherry_blossom:pressure_plate_cherrywood_on","mcl_pressureplates:pressure_plate_cherry_blossom_on")
core.register_alias("mcl_cherry_blossom:pressure_plate_cherrywood_off","mcl_pressureplates:pressure_plate_cherry_blossom_off")
