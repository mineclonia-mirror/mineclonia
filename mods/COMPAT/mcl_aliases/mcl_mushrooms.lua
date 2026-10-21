for _, color in ipairs({"red", "brown"}) do
	local prefix = "mcl_mushrooms:"..color.."_mushroom_block_"
	core.register_alias(prefix.."cap_full",   prefix.."cap_111111")
	core.register_alias(prefix.."cap_top",    prefix.."cap_100000")
	core.register_alias(prefix.."pores_full", prefix.."cap_000000")
end

-- Aliases for old MCL2 versions
core.register_alias("mcl_farming:mushroom_red", "mcl_mushrooms:mushroom_red")
core.register_alias("mcl_farming:mushroom_brown", "mcl_mushrooms:mushroom_brown")
core.register_alias("mcl_mushrooms:mushroom_block_stem", "mcl_mushrooms:red_mushroom_block_stem")

local function to_binary(num)
	local binary = ""
	while (num > 0) do
		local remainder_binary = (num % 2) > 0 and 1 or 0
		binary = binary .. remainder_binary
		num = math.floor(num/2)
	end
	binary = string.reverse(binary)
	while (string.len(binary) < 6) do
		binary = "0" .. binary
	end
	return binary
end

for i = 0, 63 do
	local bin = to_binary(i)

	core.register_alias("mcl_mushrooms:red_mushroom_block_cap_"..bin, "mcl_mushrooms:red_mushroom_block_"..bin)
	core.register_alias("mcl_mushrooms:brown_mushroom_block_cap_"..bin, "mcl_mushrooms:brown_mushroom_block_"..bin)
end

core.register_alias("mcl_mushrooms:red_mushroom_block_stem_full", "mcl_mushrooms:mushroom_stem_111111")
core.register_alias("mcl_mushrooms:brown_mushroom_block_stem_full", "mcl_mushrooms:mushroom_stem_111111")
core.register_alias("mcl_mushrooms:red_mushroom_block_stem", "mcl_mushrooms:mushroom_stem_001111")
core.register_alias("mcl_mushrooms:brown_mushroom_block_stem", "mcl_mushrooms:mushroom_stem_001111")
