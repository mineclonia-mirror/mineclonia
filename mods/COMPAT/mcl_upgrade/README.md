# mcl_upgrade: Upgrade old things

This mod is for code that helps upgrade old things from previous versions of Mineclonia, so that worlds don't break when they are upgraded.

Currently, it only has functionality to upgrade itemstacks.

## Upgrading items

This mod allows an itemstack to register a function that upgrades it to a new itemstack

Items can add an _mcl_upgrade function to their definition, which takes in the old itemstack:
`_mcl_upgrade = function(stack) end`
The function should return `nil` if the itemstack doesn't need to be upgraded, or the new itemstack if it does.

Mods which process itemstacks shouldn't call the `_mcl_upgrade` field directly, instead they should use one of the provided api functions:

### `mcl_upgrade.upgrade_itemstack(stack)`
`stack` must be convertible to ItemStack via `ItemStack(stack)` (i.e. itemstring, ItemStack, table)
returns: upgraded stack if item should be upgraded, otherwise `nil`

### `mcl_upgrade.upgrade_in_inventory(inv)`
`inv` should be an InvRef
Every item in every list of the inventory is upgraded if required.
Returns a boolean which if true iff anything was upgraded.

### Current uses in MCLA

Items only need to be upgraded once per restart of the server, as the server can't change versions while it's running. These are all the ways that itemstacks are currently upgraded in MCLA:

- In player inventories in an on_joinplayer callback (in mcl_upgrade)
- In node inventories in an LBM on `group:container` (in mcl_upgrade)
- Item entities in on_activate of item entity (in mcl_item_entity)
- Detached inventories:
    - In `mcl_entity_invs.load_inv` (in mcl_entity_invs)
    - Horse armor inv: in `horse.update_armor_inv` (in mobs_mc)
    - Items in the following inventories are *not* upgraded:
        - Villager trading inv: this is reset on rejoin, so never contains outdated items
        - Creative inventory: also reset on rejoin

Also, shulker boxes have an `_mcl_upgrade` which calls `_mcl_upgrade` on their contents.
