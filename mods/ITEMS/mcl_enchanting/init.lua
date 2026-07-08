local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
local S = core.get_translator(modname)

mcl_enchanting = {
	enchantments = {},
	overlay = "^[colorize:purple:50",
	--overlay = "^[invert:rgb^[multiply:#4df44d:50^[invert:rgb",
}

dofile(modpath .. "/engine.lua")
dofile(modpath .. "/groupcaps.lua")
dofile(modpath .. "/enchantments.lua")
dofile(modpath .. "/enchanting_table.lua")
dofile(modpath .. "/anvil.lua")

core.register_chatcommand("enchant", {
	description = S("Enchant an item"),
	params = S("<player> <enchantment> [<level>]"),
	privs = {give = true},
	func = function(_, param)
		local sparam = param:split(" ")
		local target_name = sparam[1]
		local enchantment = sparam[2]
		local level_str = sparam[3]
		local level = tonumber(level_str or "1")
		if not target_name or not enchantment then
			return false, S("Usage: /enchant <player> <enchantment> [<level>]")
		end
		local target = core.get_player_by_name(target_name)
		if not target then
			return false, S("Player '@1' cannot be found.", target_name)
		end
		local itemstack = target:get_wielded_item()
		local can_enchant, errorstring, extra_info = mcl_enchanting.can_enchant(itemstack, enchantment, level)
		if not can_enchant then
			if errorstring == "enchantment invalid" then
				return false, S("There is no such enchantment '@1'.", enchantment)
			elseif errorstring == "item missing" then
				return false, S("The target doesn't hold an item.")
			elseif errorstring == "item not supported" then
				return false, S("The selected enchantment can't be added to the target item.")
			elseif errorstring == "level invalid" then
				return false, S("'@1' is not a valid number", level_str)
			elseif errorstring == "level too high" then
				return false, S("The number you have entered (@1) is too big, it must be at most @2.", level_str, extra_info)
			elseif errorstring == "level too small" then
				return false, S("The number you have entered (@1) is too small, it must be at least @2.", level_str, extra_info)
			elseif errorstring == "incompatible" then
				return false, S("@1 can't be combined with @2.", mcl_enchanting.get_enchantment_description(enchantment, level), extra_info)
			end
		else
			target:set_wielded_item(mcl_enchanting.enchant(itemstack, enchantment, level))
			return true, S("Enchanting succeded.")
		end
	end
})

core.register_chatcommand("forceenchant", {
	description = S("Forcefully enchant an item"),
	params = S("<player> <enchantment> [<level>]"),
	privs = {give = true},
	func = function(_, param)
		local sparam = param:split(" ")
		local target_name = sparam[1]
		local enchantment = sparam[2]
		local level_str = sparam[3]
		local level = tonumber(level_str or "1")
		if not target_name or not enchantment then
			return false, S("Usage: /forceenchant <player> <enchantment> [<level>]")
		end
		local target = core.get_player_by_name(target_name)
		if not target then
			return false, S("Player '@1' cannot be found.", target_name)
		end
		local itemstack = target:get_wielded_item()
		local _, errorstring = mcl_enchanting.can_enchant(itemstack, enchantment, level)
		if errorstring == "enchantment invalid" then
			return false, S("There is no such enchantment '@1'.", enchantment)
		elseif errorstring == "item missing" then
			return false, S("The target doesn't hold an item.")
		elseif errorstring == "item not supported" and not mcl_enchanting.is_enchantable(itemstack:get_name()) then
			return false, S("The target item is not enchantable.")
		elseif errorstring == "level invalid" then
			return false, S("'@1' is not a valid number.", level_str)
		else
			target:set_wielded_item(mcl_enchanting.enchant(itemstack, enchantment, level))
			return true, S("Enchanting succeded.")
		end
	end
})

core.register_craftitem("mcl_enchanting:book_enchanted", {
	description = S("Enchanted Book"),
	inventory_image = "mcl_enchanting_book_enchanted.png" .. mcl_enchanting.overlay,
	groups = {enchanted = 1, not_in_creative_inventory = 1, enchantability = 1, rarity = 1},
	_mcl_enchanting_enchanted_tool = "mcl_enchanting:book_enchanted",
	stack_max = 1,
	_get_all_virtual_items = function()
		local output = {combat = {}, tools = {}}
		for ench, def in pairs(mcl_enchanting.enchantments) do
			for level = 1, def.max_level or 1 do
				local str = mcl_enchanting.enchant(ItemStack("mcl_enchanting:book_enchanted"), ench, level):to_string()
				if def.inv_tool_tab then
					table.insert(output.tools, str)
				end
				if def.inv_combat_tab then
					table.insert(output.combat, str)
				end
			end
		end

		return output
	end
})

core.register_alias("mcl_books:book_enchanted", "mcl_enchanting:book_enchanted")

core.register_on_mods_loaded(mcl_enchanting.initialize)
tt.register_priority_snippet(mcl_enchanting.enchantments_snippet)
