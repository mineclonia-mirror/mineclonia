local fences = {
	["bamboo"]		= "mcl_bamboo:bamboo_",
	["cherry_blossom"]	= "mcl_cherry_blossom:cherry_",
	["crimson"]		= "mcl_crimson:crimson_",
	["warped"]		= "mcl_crimson:warped_",
	["oak"]			= "mcl_fences:",
	["mangrove"]		= "mcl_mangrove:mangrove_wood_",
	["nether_brick"]	= "mclx_fences:nether_brick_",
	["red_nether_brick"]	= "mclx_fences:red_nether_brick_",
}

for new, old in pairs(fences) do
	core.register_alias(old.."fence", "mcl_fences:"..new.."_fence")
	core.register_alias(old.."fence_gate", "mcl_fences:"..new.."_fence_gate")
	core.register_alias(old.."fence_gate_open", "mcl_fences:"..new.."_fence_gate_open")
end
