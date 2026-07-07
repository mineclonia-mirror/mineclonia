local S = core.get_translator(core.get_current_modname())

local enchantment_default = {
	max_level = 1,
	primary = {},
	secondary = {},
	disallow = {},
	incompatible = {},
	curse = false,
	on_enchant = function() end,
	requires_tool = false,
	treasure = false,
	inv_combat_tab = false,
	inv_tool_tab = false,
	tradable = true,
}

function mcl_enchanting.register_enchantment(name, def)
	mcl_enchanting.enchantments[name] = setmetatable(def, { __index = enchantment_default })
end

function mcl_enchanting.is_book(itemname)
	return itemname == "mcl_books:book" or itemname == "mcl_enchanting:book_enchanted" or
		itemname == "mcl_books:book_enchanted"
end

function mcl_enchanting.get_enchantments(itemstack)
	if not itemstack then
		return {}
	end
	return core.deserialize(itemstack:get_meta():get_string("mcl_enchanting:enchantments")) or {}
end

function mcl_enchanting.is_curse(enchantment)
	return mcl_enchanting.enchantments[enchantment] and mcl_enchanting.enchantments[enchantment].curse
end

function mcl_enchanting.unload_enchantments(itemstack)
	local itemdef = itemstack:get_definition()
	local meta = itemstack:get_meta()
	if itemdef.tool_capabilities then
		meta:set_tool_capabilities(nil)
		meta:set_string("groupcaps_hash", "")
	end
	if meta:get_string("name") == "" then
		meta:set_string("description", "")
		meta:set_string("groupcaps_hash", "")
	end
end

function mcl_enchanting.load_enchantments(itemstack, enchantments)
	if not mcl_enchanting.is_book(itemstack:get_name()) then
		mcl_enchanting.unload_enchantments(itemstack)
		for enchantment, level in pairs(enchantments or mcl_enchanting.get_enchantments(itemstack)) do
			local enchantment_def = mcl_enchanting.enchantments[enchantment]
			if enchantment_def then
				enchantment_def.on_enchant(itemstack, level)
			end
		end
		mcl_enchanting.update_groupcaps(itemstack, false)
	end
	tt.reload_itemstack_description(itemstack)
end

function mcl_enchanting.set_enchantments(itemstack, enchantments)
	itemstack:get_meta():set_string("mcl_enchanting:enchantments", core.serialize(enchantments))
	mcl_enchanting.load_enchantments(itemstack)
end

function mcl_enchanting.get_enchantment(itemstack, enchantment)
	return mcl_enchanting.get_enchantments(itemstack)[enchantment] or 0
end

function mcl_enchanting.has_enchantment(itemstack, enchantment)
	return mcl_enchanting.get_enchantment(itemstack, enchantment) > 0
end

function mcl_enchanting.get_enchantment_description(enchantment, level)
	local enchantment_def = mcl_enchanting.enchantments[enchantment]
	if enchantment_def then
		return enchantment_def.name ..
			(enchantment_def.max_level == 1 and "" or " " .. mcl_util.to_roman(level))
	end
	return S("Unknown Enchantment")..": "..tostring(enchantment)
end

function mcl_enchanting.get_colorized_enchantment_description(enchantment, level)
	if mcl_enchanting.enchantments[enchantment] then
		return core.colorize(mcl_enchanting.enchantments[enchantment].curse and mcl_colors.RED or mcl_colors.GRAY,
			mcl_enchanting.get_enchantment_description(enchantment, level))
	end
	return core.colorize(mcl_colors.DARK_GRAY, S("Unknown Enchantment")..": "..tostring(enchantment))
end

function mcl_enchanting.get_enchanted_itemstring(itemname)
	local def = core.registered_items[itemname]
	return def and def._mcl_enchanting_enchanted_tool
end

function mcl_enchanting.set_enchanted_itemstring(itemstack)
	itemstack:set_name(mcl_enchanting.get_enchanted_itemstring(itemstack:get_name()))
end

function mcl_enchanting.is_enchanted(itemname)
	return core.get_item_group(itemname, "enchanted") > 0
end

function mcl_enchanting.not_enchantable_on_enchanting_table(itemname)
	return mcl_enchanting.get_enchantability(itemname) == -1
end

function mcl_enchanting.is_enchantable(itemname)
	return mcl_enchanting.get_enchantability(itemname) > 0 or
		mcl_enchanting.not_enchantable_on_enchanting_table(itemname)
end

function mcl_enchanting.can_enchant_freshly(itemname)
	return mcl_enchanting.is_enchantable(itemname) and not mcl_enchanting.is_enchanted(itemname)
end

function mcl_enchanting.get_enchantability(itemname)
	return core.get_item_group(itemname, "enchantability")
end

function mcl_enchanting.item_supports_enchantment(itemname, enchantment)
	if not mcl_enchanting.is_enchantable(itemname) then
		return false
	end
	local enchantment_def = mcl_enchanting.enchantments[enchantment]
	if not enchantment_def then return false end

	if mcl_enchanting.is_book(itemname) then
		return true, (not enchantment_def.treasure)
	end
	local itemdef = core.registered_items[itemname]
	if itemdef.type ~= "tool" and enchantment_def.requires_tool then
		return false
	end
	for disallow, _ in pairs(enchantment_def.disallow) do
		if core.get_item_group(itemname, disallow) > 0 then
			return false
		end
	end
	for group, _ in pairs(enchantment_def.primary) do
		if core.get_item_group(itemname, group) > 0 then
			return true, true
		end
	end
	for group, _ in pairs(enchantment_def.secondary) do
		if core.get_item_group(itemname, group) > 0 then
			return true, false
		end
	end
	return false
end

function mcl_enchanting.can_enchant(itemstack, enchantment, level)
	local enchantment_def = mcl_enchanting.enchantments[enchantment]
	if not enchantment_def then
		return false, "enchantment invalid"
	end
	local itemname = itemstack:get_name()
	if itemname == "" then
		return false, "item missing"
	end
	local supported, primary = mcl_enchanting.item_supports_enchantment(itemname, enchantment)
	if not supported then
		return false, "item not supported"
	end
	if not level then
		return false, "level invalid"
	end
	if level > enchantment_def.max_level then
		return false, "level too high", enchantment_def.max_level
	elseif level < 1 then
		return false, "level too small", 1
	end
	local item_enchantments = mcl_enchanting.get_enchantments(itemstack)
	local enchantment_level = item_enchantments[enchantment]
	if enchantment_level then
		return false, "incompatible", mcl_enchanting.get_enchantment_description(enchantment, enchantment_level)
	end
	if not mcl_enchanting.is_book(itemname) then
		for incompatible, _ in pairs(enchantment_def.incompatible) do
			local incompatible_level = item_enchantments[incompatible]
			if incompatible_level then
				return false, "incompatible",
					mcl_enchanting.get_enchantment_description(incompatible, incompatible_level)
			end
		end
	end
	return true, nil, nil, primary
end

function mcl_enchanting.enchant(itemstack, enchantment, level)
	mcl_enchanting.set_enchanted_itemstring(itemstack)
	local enchantments = mcl_enchanting.get_enchantments(itemstack)
	enchantments[enchantment] = level
	mcl_enchanting.set_enchantments(itemstack, enchantments)
	return itemstack
end

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

function mcl_enchanting.enchantments_snippet(_, _, itemstack)
	if not itemstack then
		return
	end
	local enchantments = mcl_enchanting.get_enchantments(itemstack)
	local text = ""
	for enchantment, level in pairs(enchantments) do
		text = text .. mcl_enchanting.get_colorized_enchantment_description(enchantment, level) .. "\n"
	end
	if text ~= "" then
		if not itemstack:get_definition()._tt_original_description then
			text = text:sub(1, text:len() - 1)
		end
		return text, false
	end
end

-- Returns the after_use callback function to use when registering an enchanted
-- item.  The after_use callback is used to update the tool_capabilities of
-- efficiency enchanted tools with outdated digging times.
--
-- It does this by calling apply_efficiency to reapply the efficiency
-- enchantment.  That function is written to use hash values to only update the
-- tool if neccessary.
--
-- This is neccessary for digging times of tools to be in sync when Mineclonia
-- or mods add new hardness values.
local function get_after_use_callback(itemdef)
	if itemdef.after_use then
		-- If the tool already has an after_use, make sure to call that
		-- one too.
		return function(itemstack, user, node, digparams)
			itemdef.after_use(itemstack, user, node, digparams)
			mcl_enchanting.update_groupcaps(itemstack, false)
		end
	end

	-- If the tool does not have after_use, add wear to the tool as if no
	-- after_use was registered.
	return function(itemstack, user, _, digparams)
		if not core.is_creative_enabled(user:get_player_name()) then
			itemstack:add_wear(digparams.wear)
		end

		--local enchantments = mcl_enchanting.get_enchantments(itemstack)
		mcl_enchanting.update_groupcaps(itemstack, false)
	end
end

function mcl_enchanting.initialize()
	local register_tool_list = {}
	local register_item_list = {}
	for itemname, itemdef in pairs(core.registered_items) do
		if mcl_enchanting.can_enchant_freshly(itemname) and not mcl_enchanting.is_book(itemname) then
			local new_name = itemname .. "_enchanted"
			core.override_item(itemname, { _mcl_enchanting_enchanted_tool = new_name })
			local new_def = table.copy(itemdef)
			new_def.inventory_image = itemdef.inventory_image .. mcl_enchanting.overlay
			if new_def.wield_image then
				new_def.wield_image = new_def.wield_image .. mcl_enchanting.overlay
			end
			new_def.groups.not_in_creative_inventory = 1
			new_def.groups.not_in_craft_guide = 1
			new_def.groups.enchanted = 1

			if new_def._mcl_armor_texture then
				if type(new_def._mcl_armor_texture) == "string" then
					new_def._mcl_armor_texture = new_def._mcl_armor_texture .. mcl_enchanting.overlay
				end
			end

			new_def._mcl_enchanting_enchanted_tool = new_name
			new_def.after_use = get_after_use_callback(itemdef)
			local register_list = register_item_list
			if itemdef.type == "tool" then
				register_list = register_tool_list
			end
			register_list[":" .. new_name] = new_def
		end
	end
	for new_name, new_def in pairs(register_item_list) do
		core.register_craftitem(new_name, new_def)
	end
	for new_name, new_def in pairs(register_tool_list) do
		core.register_tool(new_name, new_def)
	end
end

function mcl_enchanting.random(pr, ...)
	local r = pr and pr:next(...) or math.random(...)

	if pr and not ({ ... })[1] then
		if pr.rand_normal_dist then
			r = (r + 2147483648) / 4294967295
		else
			r = r / 32767
		end
	end

	return r
end

local enchantment_ids = {}

core.register_on_mods_loaded (function ()
	for key, _ in pairs (mcl_enchanting.enchantments) do
		table.insert (enchantment_ids, key)
	end
	table.sort (enchantment_ids)
end)

function mcl_enchanting.get_random_enchantment(itemstack, treasure, weighted, exclude, pr)
	local possible = {}

	for _, enchantment in ipairs (enchantment_ids) do
		local enchantment_def = mcl_enchanting.enchantments[enchantment]
		local can_enchant, _, _, primary = mcl_enchanting.can_enchant(itemstack, enchantment, 1)
		local obtainable_randomly = primary or (treasure and enchantment_def.treasure and enchantment_def.tradable)

		if can_enchant and obtainable_randomly and (not exclude or table.indexof(exclude, enchantment) == -1) then
			local weight = weighted and enchantment_def.weight or 1

			for _ = 1, weight do
				table.insert(possible, enchantment)
			end
		end
	end

	return #possible > 0 and possible[mcl_enchanting.random(pr, 1, #possible)]
end

function mcl_enchanting.generate_random_enchantments(itemstack, enchantment_level, treasure, no_reduced_bonus_chance,
													 ignore_already_enchanted, pr)
	local itemname = itemstack:get_name()

	if (not mcl_enchanting.can_enchant_freshly(itemname) and not ignore_already_enchanted) or
		mcl_enchanting.not_enchantable_on_enchanting_table(itemname) then
		return
	end

	itemstack = ItemStack(itemstack)

	local enchantability = core.get_item_group(itemname, "enchantability")
	enchantability = 1 + mcl_enchanting.random(pr, 0, math.floor(enchantability / 4)) +
		mcl_enchanting.random(pr, 0, math.floor(enchantability / 4))

	enchantment_level = enchantment_level + enchantability
	enchantment_level = enchantment_level +
		enchantment_level * (mcl_enchanting.random(pr) + mcl_enchanting.random(pr) - 1) * 0.15
	enchantment_level = math.max(math.floor(enchantment_level + 0.5), 1)

	local enchantments = {}
	local description

	enchantment_level = enchantment_level * 2

	repeat
		enchantment_level = math.floor(enchantment_level / 2)

		if enchantment_level == 0 then
			break
		end

		local selected_enchantment = mcl_enchanting.get_random_enchantment(itemstack, treasure, true, nil, pr)

		if not selected_enchantment then
			break
		end

		local enchantment_def = mcl_enchanting.enchantments[selected_enchantment]
		local power_range_table = enchantment_def.power_range_table

		local enchantment_power

		for i = enchantment_def.max_level, 1, -1 do
			local power_range = power_range_table[i]
			if enchantment_level >= power_range[1] and enchantment_level <= power_range[2] then
				enchantment_power = i
				break
			end
		end

		if not description then
			if not enchantment_power then
				return
			end

			description = mcl_enchanting.get_enchantment_description(selected_enchantment, enchantment_power)
		end

		if enchantment_power then
			enchantments[selected_enchantment] = enchantment_power
			mcl_enchanting.enchant(itemstack, selected_enchantment, enchantment_power)
		end
	until not no_reduced_bonus_chance and mcl_enchanting.random(pr) >= (enchantment_level + 1) / 50

	return enchantments, description
end

function mcl_enchanting.generate_random_enchantments_reliable(itemstack, enchantment_level, treasure, no_reduced_bonus_chance, ignore_already_enchanted, pr)
	local enchantments

	repeat
		enchantments = mcl_enchanting.generate_random_enchantments(itemstack, enchantment_level, treasure,
			no_reduced_bonus_chance, ignore_already_enchanted, pr)
	until enchantments

	return enchantments
end

function mcl_enchanting.enchant_randomly(itemstack, enchantment_level, treasure, no_reduced_bonus_chance,
										 ignore_already_enchanted, pr)
	local enchantments = mcl_enchanting.generate_random_enchantments_reliable(itemstack, enchantment_level, treasure, no_reduced_bonus_chance, ignore_already_enchanted, pr)

	mcl_enchanting.set_enchanted_itemstring(itemstack)
	mcl_enchanting.set_enchantments(itemstack, enchantments)

	return itemstack
end

function mcl_enchanting.enchant_uniform_randomly(stack, exclude, pr)
	local enchantment = mcl_enchanting.get_random_enchantment(stack, true, false, exclude, pr)

	if enchantment then
		mcl_enchanting.enchant(stack, enchantment,
			mcl_enchanting.random(pr, 1, mcl_enchanting.enchantments[enchantment].max_level))
	end

	return stack
end

