mcl_upgrade = {}

local function upgrade_itemstack(stack)
	stack = ItemStack(stack)
	local upgrade = stack:get_definition()._mcl_upgrade
	if upgrade then
		return upgrade(stack)
	end
end
mcl_upgrade.upgrade_itemstack = upgrade_itemstack

function mcl_upgrade.upgrade_in_inventory(inv)
	local modified = false
	for listname, list in pairs(inv:get_lists()) do
		for i, stack in pairs(list) do
			if not stack:is_empty() then
				local upgraded = upgrade_itemstack(stack)
				if upgraded then
					inv:set_stack(listname, i, upgraded)
					modified = true
				end
			end
		end
	end
	return modified
end

-- How can itemstacks be loaded?
-- - Player inventories (handled here)
-- - Node inventories (handled here)
-- - Item entities (in on_activate of item entity)
-- 	- Special case: shulker boxes; th
-- - Detached inventories:
-- These are used for different things in different places:
-- 	- mcl_entity_invs: handled in mcl_entity_invs.load_inv
-- 	- Villager trading: the detached trading formspec inv
-- 		is not saved so don't need to upgrade
-- 	- Horse armor inv: in horse.update_armor_inv
-- 	- Creative inventory: not saved, don't need to upgrade

core.register_on_joinplayer(function(player)
	mcl_upgrade.upgrade_in_inventory(player:get_inventory())
end)

core.register_lbm({
	label = "Upgrade items in node inventories",
	name = "mcl_upgrade:upgrade_node_invs",
	nodenames = {"group:container"},
	run_at_every_load = true,
	action = function(pos)
		local inv = core.get_meta(pos):get_inventory()
		mcl_upgrade.upgrade_in_inventory(inv)
	end
})
