# `mcl_shelves` API

Note: if you're just registering a new wood kind through `mcl_trees`, you don't need to use `mcl_shelves` API as it's already covered there.

## Functions

* `mcl_shelves.register_shelf(name, def)`
    * Registers a new shelf kind with powered/connected variants.
    * The OFF shelf will use `"mcl_shelves:" .. name` as its node name, and the variants' node names will suffix onto that.
    * `def` is a Node Definition table override that will get applied on top of `mcl_shelves.tpl_shelf`.

## UV format

Shelf meshes use Minecraft's UV mapping, one for all variants, which should be defined in `tiles` of the registered shelf. It's a single 32x32 texture with (left-to-right, top-to-bottom):

1. Top-left 16x16 region used to texture the front (placer-facing) faces of the unpowered shelf mesh, as well as the extruding top/bottom regions (shared for all meshes);
2. Top-right 16x16 region used to texture the back faces of all shelf meshes, as well as the top/bottom/side faces of the extruding regions;
3. Middle-left 16x8 region used to texture the shelf span of a powered shelf mesh positioned left in a shelf row;
4. Middle-right 16x8 region used to texture the shelf span of a powered shelf mesh positioned right in a shelf row;
5. Bottom-left 16x8 region used to texture the shelf span of a powered shelf mesh positioned at the center of a shelf row;
6. Bottom-right 16x8 region used to texture the shelf span of a single unconnected powered shelf mesh.

## Example API usage

```lua
mcl_shelves.register_shelf("stone", {
	description = S("Stone Shelf"),
	sounds = mcl_sounds.node_sound_stone_defaults(),
	tiles = {"my_mod_name_stone_shelf.png"},
	groups = {pickaxey = 1, material_stone = 1},
	_mcl_hardness = 1.5,
	_mcl_blast_resistance = 6,
})
```
