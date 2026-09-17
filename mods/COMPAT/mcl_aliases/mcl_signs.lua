-- Aliases for hanging signs
-- standing signs conversion in mcl_signs_compat

core.register_alias("mcl_signs:sign","mcl_signs:wall_sign_oak")

local woods = {
	["oak"]			= "",
	["acacia"]		= "_acaciawood",
	["jungle"]		= "_junglewood",
	["birch"]		= "_birchwood",
	["dark_oak"]		= "_darkwood",
	["spruce"]		= "_sprucewood",
	["mangrove"]		= "_mangrove_wood",
	["crimson"]		= "_crimson_hyphae_wood",
	["warped"]		= "_warped_hyphae_wood",
	["cherry_blossom"]	= "_cherrywood",
}

for new, old in pairs(woods) do
	core.register_alias("mcl_signs:wall_sign"..old, "mcl_signs:wall_sign_"..new)
end
