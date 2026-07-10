local function update_itemstack_capabilities(itemstack, dig_speed, full_punch_speed)
	local itemname = itemstack:get_name()
	local itemdef = core.registered_items[itemname]

	local efficiency_level = mcl_enchanting and mcl_enchanting.get_enchantment(itemstack, "efficiency")
	-- get_enchantment returns 0 if the item doesn't have the enchantment
	if efficiency_level == 0 then efficiency_level = nil end
	local speed_add_bonus = efficiency_level and efficiency_level*efficiency_level+1 or 0

	local groupcaps = mcl_autogroup.get_groupcaps(itemname, speed_add_bonus, dig_speed)

	-- Override for unbreaking
	-- TODO: Change unbreaking to have a probability of not using durability,
	-- instead of increasing uses

	local unbreaking_level = mcl_enchanting and mcl_enchanting.get_enchantment(itemstack, "unbreaking") or 0
	if unbreaking_level > 0 then
		for _, capability in pairs(groupcaps) do
			capability.uses = capability.uses * (1 + unbreaking_level)
		end
	end

	local toolcaps = itemstack:get_tool_capabilities()
	toolcaps.groupcaps = groupcaps

	local original_punch_interval = mcl_autogroup.get_tool_capabilities(itemdef).full_punch_interval
	toolcaps.full_punch_interval = original_punch_interval / full_punch_speed

	itemstack:get_meta():set_tool_capabilities(toolcaps)
	return itemstack
end

local function is_tool(itemstack)
	return core.registered_tools[itemstack:get_name()] ~= nil
end
mcl_autogroup.is_tool = is_tool

local function try_update_tool_capabilities(itemstack, dig_speed, full_punch_speed)
	-- Only modify for tools
	if is_tool(itemstack) then
		return update_itemstack_capabilities(itemstack, dig_speed, full_punch_speed)
	end
end

local function get_dig_speed(player)
	local haste_level = mcl_potions.get_effect_level(player, "haste")
	local conduit_power_level = mcl_potions.get_effect_level(player, "conduit_power")
	local fatigue_level = mcl_potions.get_effect_level(player, "fatigue")

	local fast_multiplier = 1 + 0.2 * math.max(haste_level, conduit_power_level)
	local slow_multiplier = math.pow(0.3, fatigue_level)
	return fast_multiplier * slow_multiplier
end

local function get_full_punch_speed(player)
	-- TODO: Should use an attribute modifier so that we don't have to hardcode it
	local haste_level = mcl_potions.get_effect_level(player, "haste")
	local fatigue_level = mcl_potions.get_effect_level(player, "fatigue")
	return 1 + 0.1 * (haste_level - fatigue_level)
end

function mcl_autogroup.try_update_tool_capabilities(itemstack, player)
	return try_update_tool_capabilities(
		itemstack,
		get_dig_speed(player),
		get_full_punch_speed(player)
	)
end

local function update_player_capabilities(player)
	-- We only need to update groupcaps for tools which are in places
	-- where a player can use them.
	-- This is: hotbar, offhand
	-- Also, we need to update the player's hand

	local dig_speed = get_dig_speed(player)
	local full_punch_speed = get_full_punch_speed(player)

	local inv = player:get_inventory()
	-- The reason that the whole main list is modified
	-- is that the player's hotbar itemcount can change
	-- so theoretically they could use any item in their main list
	for i, stack in ipairs(inv:get_list("main")) do
		stack = try_update_tool_capabilities(stack, dig_speed, full_punch_speed)
		if stack then mcl_util.set_main_list_item_no_anim(player, i, stack) end
	end

	-- TODO: Test since offhand is useless at the moment
	local offhand = inv:get_stack("offhand", 1)
	offhand = try_update_tool_capabilities(offhand, dig_speed, full_punch_speed)
	if offhand then inv:set_stack("offhand", 1, offhand) end

	local hand = inv:get_stack("hand", 1)
	hand = update_itemstack_capabilities(hand, dig_speed, full_punch_speed)
	inv:set_stack("hand", 1, hand)
end
mcl_autogroup.update_player_capabilities = update_player_capabilities

function mcl_autogroup.update_hand_capabilities(player)
	local dig_speed = get_dig_speed(player)
	local full_punch_speed = get_full_punch_speed(player)
	local inv = player:get_inventory()

	local hand = inv:get_stack("hand", 1)
	hand = update_itemstack_capabilities(hand, dig_speed, full_punch_speed)
	inv:set_stack("hand", 1, hand)
end

local function is_active_slot(listname, index)
	return listname == "offhand"
	or listname == "hand"
	or listname == "main"
end

-- Ideally, we would reset the capabilities of an item when it left the player's inventory
-- However, there seems to be no way to do that, apart from overriding every on_drop and
-- every on_metadata_inventory_* and probably something for detached inventories as well,
-- which would be very fragile to mods.
-- Instead, let's just allow tools which aren't in a player's inventory to have erroneous
-- capabilities, and update the capabilities when they enter a player's hotbar/offhand
core.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
	local to_list, to_index
	if action == "move" then
		-- If item was already in active slot, it should have correct toolcaps
		if is_active_slot(inventory_info.from_list, inventory_info.from_index) then
			return
		end

		to_list = inventory_info.to_list
		to_index = inventory_info.to_index
	elseif action == "put" then
		to_list = inventory_info.listname
		to_index = inventory_info.index
	else return end

	if not is_active_slot(to_list, to_index) then return end
	local itemstack = inventory:get_stack(to_list, to_index)
	mcl_autogroup.try_update_tool_capabilities(itemstack, player)
	inventory:set_stack(to_list, to_index, itemstack)
end)
