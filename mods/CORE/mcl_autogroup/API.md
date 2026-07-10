# mcl_autogroup
This mod emulate digging times from mc.

## General API functions

### mcl_autogroup.can_harvest(nodename, toolname, player)
Return true if <nodename> can be dig with <toolname> by <player>.
* nodename: string, valid nodename
* toolname: (optional) string, valid toolname
* player: (optinal) ObjectRef, valid player

### mcl_autogroup.get_groupcaps(toolname, speed_add_bonus, speed_multiplier)
This function is used to calculate diggroups for tools.
WARNING: This function can only be called after mod initialization.
WARNING: You probably don't need to call this function outside _mcl_autogroup; see below section on toolcaps overrides
* toolname: string, name of the tool being enchanted (like "mcl_tools:pick_diamond")
* speed_add_bonus: (optional) number, to be added to the dig speed
* speed_multiplier: (optional) number, dig speed is multiplied by this after speed_add_bonus is added

### mcl_autogroup.get_wear(toolname, diggroup)
Return the max wear of <toolname> with <diggroup>
WARNING: This function can only be called after mod initialization.
* toolname: string, name of the tool used
* diggroup: string, the name of the diggroup the tool is used on

### mcl_autogroup.register_diggroup(group, def)
* group: string, name of the group to register as a digging group
* def: (optional) table, table with information about the diggroup (defaults to {} if unspecified)
    * level: (optional) string, if specified it is an array containing the names of the different digging levels the digging group supports

### mcl_autogroup.registered_diggroups
List of registered diggroups, indexed by name.

## Tool capabilities overrides

### Explanation
The only way that the engine allows us to change the player's digging time or full punch time is to change the tool capabilities of the item they are using.
We need to change the digging time based on which player is using the tool, since:
- The player could have the haste or fatigue effects
- The player could be underwater (not yet implemented, but should slow digging)

We can change the tool capabilities of any item, but we shouldn't change the tool capabilities for any stackable item since items with different tool capabilities don't stack together, so the player could notice that they can't pick up an item from the floor to stack with one in their inventory. Instead, we change the tool capabilities only of tools registered with `core.register_tool`. Also, we must change the tool capabilities of the player's hand, but this is quite simple since the hand never leaves/enters the inventory.

In order to change the digging speed based on who is using the tool, we set the tool capabilities of tools when they enter the player's inventory and when the player's digging speed changes. Ideally, we would also reset the tool capabilities to some default value when the tool leaves the player's inventory, but there doesn't seem to be a robust way to modify items as they leave the player's inventory. Therefore, we treat all tools not in the player's inventory as having unreliable tool capabilities, and we must correct them when they enter a player's inventory.

Although the paragraph above refers to the player's inventory, in fact it is only when tools enter the "main", "hand" and "offhand" lists that their tool capabilities are reset. This is to avoid bugs where the tool's capabilities aren't properly reset when crafting/enchanting (as these are player inv lists).

How above 2 paragraphs are implemented:
- In an on_player_inventory_action callback in _mcl_autogroup which updates the tool capabilities of any itemstack entering the relevant inventory lists
- In mcl_item_entity, to detect when a tool is picked up. Since we don't know where in the inventory the tool went, the whole inventory's tool capabilities are updated whenever a tool is picked up. For some reason picking up an item doesn't trigger inventory action callbacks.
This has a minor shortcoming in that if a mod manually adds an item to the player's inventory, it won't have its tool capabilities updated because it doesn't trigger either of the above.
For example, the definition of the "enchant" chatcommand must manually tell mcl_autogroup to update the tool's capabilities, and there may be other places this should happen that have been missed out.
TODO: Maybe we need a more general wrapper around setting player inventory slots that also updates stuff like this?

How the tool capabilities modifications are implemented:
These factors affecting tool capabilities are currently hardcoded in mcl_autogroup:
- Haste, conduit power and fatigue: the effects on dig speed and full punch interval are hardcoded.
- Unbreaking enchantment (changes uses field of each groupcap). This should be changed to match MC by not changing uses but having a fixed probability of not incurring wear each time the tool is used.
- Efficiency enchantment.

### Exposed functions
None of these functions should be used by external mods, these are only for use inside Mineclonia. This is because the structure of this mod could change later, breaking mods that depend upon these functions. If you are writing an external mod and would like to use one of these functions, please make an issue on the Mineclonia issue tracker, and someone will make sure that this is ready to use. For more information see Mineclonia's API.md.

#### mcl_autogroup.is_tool(itemstack)
* itemstack: ItemStack
Returns: boolean; should this itemstack (ItemStack) have its tool capabilities overridden when it enters the player's inventory?

#### mcl_autogroup.update_player_capabilities(player)
Updates the tool capabilities of all tools in the "main" and "offhand" inventory lists, and also of the player's hand, taking into account anything affecting the dig speed / full punch interval of `player`
* player: ObjectRef (must be player)

#### mcl_autogroup.update_hand_capabilities(player)
Like `update_player_capabilities`, but only update the tool capabilities of the hand.

#### mcl_autogroup.try_update_tool_capabilities(itemstack, player)
Updates the tool capabilities of `itemstack` taking into account anything affecting the dif speed / full punch interval of `player`.
* itemstack: ItemStack
* player: ObjectRef (must be player)
Returns: ItemStack; the itemstack with correct tool capabilities applied
