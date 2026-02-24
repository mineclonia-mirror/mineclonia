## Shelves API

### Functions:
`mcl_shelves.register_shelf(name, def)`: Register a new shelf. The _**name**_ parameter must be a string that will be used as part of the shelf itemstring, registered as
```lua
"mcl_shelves:"..name
```
_**def**_ must be a table containing node definitions, such as description, tiles, groups and others. Some parameters are defined by the mcl_shelves API (models, drawtype, paramtypes, some groups). Those parameters can be overrided using _**def**_, however, we do not recommend overwriting them as this may break the shelf's functionality. If you are defining a shelf along with defining a set of nodes related to a tree using `mcl_trees.register_wood`, you can use the _**shelf**_ parameter as a table containing node definitions, or you can simply omit the parameter and let the mcl_trees API handle some of the definitions. Two examples of where _**shelf**_ is used as a table to define certain parameters are in [mcl_crimson, line 129](../mcl_crimson/init.lua#L129) and [mcl_crimson, line 198](../mcl_crimson/init.lua#L198). Using the _**shelf**_ parameter as a table when using `mcl_trees.register_wood` can override parameters that would be automatically set by the mcl_trees API. If the _**shelf**_ parameter is omitted, the [mcl_trees API](../mcl_trees/api.lua#L507) will automatically set the following parameters:
* description
* sounds
* _mcl_burntime
* _mcl_hardness
* _mcl_blast_resistance
* groups
* tiles

Remember that all these parameters can be overridden using the _**shelf**_ parameter as a table during the registration of a wood using `mcl_trees.register_wood` as in the examples linked above. Also note that if you want to override certain parameters but want to allow the _**tiles**_ parameter to be set automatically, simply name the shelf texture following the pattern _modname_name_shelf.png_, that is, if your mod is called *"mymod"* and the name you chose for your shelf is *"stone"*, your texture should be named **mymod_stone_shelf.png**

### Silly example
```lua
mcl_shelves.register_shelf("stone", {
    description = S("Stone Shelf"),
    sounds = mcl_sounds.node_sound_stone_defaults(),
    tiles = {"my_mod_name_stone_shelf.png"},
    _mcl_hardness = 1.5,
    _mcl_blast_resistance = 6,
    groups = {pickaxey = 1, material_stone = 1},
})
```
### Note
mcl_shelves uses models whose UV mappings are designed to utilize textures appropriate for them. If you plan to add a new bookshelf, follow the examples of the original mod textures. Below is a list of the texture files.
* [Acacia shelf](../mcl_core/textures/mcl_core_acacia_shelf.png)
* [Bamboo shelf](../mcl_bamboo/textures/mcl_bamboo_shelf.png)
* [Birch shelf](../mcl_core/textures/mcl_core_birch_shelf.png)
* [Cherry shelf](../mcl_cherry_blossom/textures/mcl_cherry_blossom_shelf.png)
* [Crimson shelf](../mcl_crimson/textures/mcl_crimson_crimson_shelf.png)
* [Dark oak shelf](../mcl_core/textures/mcl_core_dark_oak_shelf.png)
* [Jungle shelf](../mcl_core/textures/mcl_core_jungle_shelf.png)
* [Mangrove shelf](../mcl_mangrove/textures/mcl_mangrove_shelf.png)
* [Oak shelf](../mcl_core/textures/mcl_core_oak_shelf.png)
* [Pale oak shelf](../mcl_pale_oak/textures/mcl_pale_oak_shelf.png)
* [Spruce shelf](../mcl_core/textures/mcl_core_spruce_shelf.png)
* [Warped shelf](../mcl_crimson/textures/mcl_crimson_warped_shelf.png)
