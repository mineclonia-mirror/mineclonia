-- Aliases for hanging signs
-- standing signs conversion in mcl_signs_compat

core.register_alias("mcl_signs:sign","mcl_signs:wall_sign_oak")

for new, old in pairs({
	["acacia"]		= "_acaciawood",
	["birch"]		= "_birchwood",
	["cherry_blossom"]	= "_cherrywood",
	["crimson"]		= "_crimson_hyphae_wood",
	["dark_oak"]		= "_darkwood",
	["jungle"]		= "_junglewood",
	["mangrove"]		= "_mangrove_wood",
	["oak"]			= "",
	["spruce"]		= "_sprucewood",
	["warped"]		= "_warped_hyphae_wood",
}) do
	core.register_alias("mcl_signs:wall_sign"..old, "mcl_signs:wall_sign_"..new)
end
