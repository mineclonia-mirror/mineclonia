function mcl_enchanting.get_prior_work_penalty(itemstack)
	local m = itemstack:get_meta()
	return m:get_int("mcl_enchanting:pwp")
end

function mcl_enchanting.add_prior_work_penalty(itemstack, amount)
	amount = amount or 1
	local m = itemstack:get_meta()
	local old_pwp = m:get_int("mcl_enchanting:pwp")
	m:set_int("mcl_enchanting:pwp", old_pwp + amount)
	return itemstack
end

function mcl_enchanting.combine_prior_work_penalty (itemstack, with)
	local p1 = mcl_enchanting.get_prior_work_penalty (itemstack)
	local p2 = mcl_enchanting.get_prior_work_penalty (with)
	local meta = itemstack:get_meta ()
	meta:set_int ("mcl_enchanting:pwp", math.max (p1, p2) + 1)
end

function mcl_enchanting.combine(itemstack, combine_with)
	local itemname = itemstack:get_name()
	local combine_name = combine_with:get_name()
	local enchanted_itemname = mcl_enchanting.get_enchanted_itemstring(itemname)
	if not enchanted_itemname or
		enchanted_itemname ~= mcl_enchanting.get_enchanted_itemstring(combine_name) and
		not mcl_enchanting.is_book(combine_name) then
		return false
	end
	local enchantments = mcl_enchanting.get_enchantments(itemstack)
	local any_new_enchantment = false
	local incompatible_enchants = 0
	local enchantment_modified = {}
	for enchantment, combine_level in pairs(mcl_enchanting.get_enchantments(combine_with)) do
		local enchantment_def = mcl_enchanting.enchantments[enchantment]
		if enchantment_def then
			local enchantment_level = enchantments[enchantment]
			if enchantment_level then -- The enchantment already exists in the provided item.
				if enchantment_level == combine_level then
					enchantment_level = math.min(enchantment_level + 1, enchantment_def.max_level)
				else
					enchantment_level = math.max(enchantment_level, combine_level)
				end
				if enchantment_level ~= enchantments[enchantment] then
					any_new_enchantment = true
					enchantment_modified[enchantment] = true
				end
			elseif mcl_enchanting.item_supports_enchantment(itemname, enchantment) then -- this is a new enchantement to try to add
				local supported = true
				for incompatible, _ in pairs(enchantment_def.incompatible) do
					if enchantments[incompatible] then
						incompatible_enchants = incompatible_enchants + 1
						supported = false
						break
					end
				end
				if supported then
					enchantment_level = combine_level
					any_new_enchantment = true
					enchantment_modified[enchantment] = true
				end
			end
			if enchantment_level and enchantment_level > 0 then
				enchantments[enchantment] = enchantment_level
			end
		end
	end
	local level_requirement = 0
	level_requirement = level_requirement + incompatible_enchants
	mcl_enchanting.combine_prior_work_penalty (itemstack, combine_with)
	if any_new_enchantment then
		itemstack:set_name(enchanted_itemname)
		local book_p = mcl_enchanting.is_book(combine_name)
		for k,v in pairs(enchantments) do
			if enchantment_modified[k] then
				if book_p then
					level_requirement = level_requirement + ( v * ((mcl_enchanting.enchantments[k] and mcl_enchanting.enchantments[k].anvil_book_factor) or 1))
				else
					level_requirement = level_requirement + ( v * ((mcl_enchanting.enchantments[k] and mcl_enchanting.enchantments[k].anvil_item_factor) or 1))
				end
			end
		end
		mcl_enchanting.set_enchantments(itemstack, enchantments)
	end
	return any_new_enchantment, level_requirement
end
