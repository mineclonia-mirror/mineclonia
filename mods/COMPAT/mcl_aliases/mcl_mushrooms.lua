for _, color in ipairs({"red", "brown"}) do
	local prefix = "mcl_mushrooms:"..color.."_mushroom_block_"
	core.register_alias(prefix.."cap_full",   prefix.."cap_111111")
	core.register_alias(prefix.."cap_top",    prefix.."cap_100000")
	core.register_alias(prefix.."pores_full", prefix.."cap_000000")
end

-- Aliases for old MCL2 versions
core.register_alias("mcl_farming:mushroom_red", "mcl_mushrooms:mushroom_red")
core.register_alias("mcl_farming:mushroom_brown", "mcl_mushrooms:mushroom_brown")
