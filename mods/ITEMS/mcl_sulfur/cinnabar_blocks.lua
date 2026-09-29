local S = core.get_translator(core.get_current_modname())

-- Cinnabar

core.register_node("mcl_sulfur:cinnabar", {
	description = S("Cinnabar"),
	_doc_items_longdesc = S("Variant of stone that can be found in sulfur caves"),
	_doc_items_hidden = false,
	tiles = {"mcl_sulfur_cinnabar.png"},
	groups = {pickaxey=1, cinnabar=1, building_block=1, stonecuttable = 1, overworld_carvable = 1, stone_ore_target = 1, },
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
	_mcl_crafting_output = {square2 = {output = "mcl_sulfur:cinnabar_polished 4"}}
})

mcl_stairs.register_stair_and_slab("cinnabar", {
	baseitem = "mcl_sulfur:cinnabar",
	description_stair = S("Cinnabar Stairs"),
	description_slab = S("Cinnabar Slab"),
	overrides = {_mcl_stonecutter_recipes = {"mcl_sulfur:cinnabar"}},
})

mcl_walls.register_wall_def("mcl_sulfur:cinnabar_wall", {
	description = S("Cinnabar Wall"),
	source = "mcl_sulfur:cinnabar",
	_mcl_stonecutter_recipes = {"mcl_sulfur:cinnabar"},
})

-- Polished Cinnabar
core.register_node("mcl_sulfur:cinnabar_polished", {
	description = S("Polished Cinnabar"),
	_doc_items_longdesc = S("Decorative variant of cinnabar"),
	_doc_items_hidden = false,
	tiles = {"mcl_sulfur_cinnabar_polished.png"},
	groups = {pickaxey=1, cinnabar_polished=1, building_block=1, stonecuttable = 1, overworld_carvable = 1, stone_ore_target = 1, },
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
	_mcl_crafting_output = {square2 = {output = "mcl_sulfur:cinnabar_bricks 4"}},
	_mcl_stonecutter_recipes = { "mcl_sulfur:cinnabar"},
})

mcl_stairs.register_stair_and_slab("cinnabar_polished_polished", {
	baseitem = "mcl_sulfur:cinnabar_polished",
	description_stair = S("Polished Cinnabar Stairs"),
	description_slab = S("Polished Cinnabar Slab"),
	overrides = {_mcl_stonecutter_recipes = {"mcl_sulfur:cinnabar_polished", "mcl_sulfur:cinnabar"}},
})

mcl_walls.register_wall_def("mcl_sulfur:cinnabar_polished_wall", {
	description = S("Cinnabar Wall"),
	source = "mcl_sulfur:cinnabar_polished",
	_mcl_stonecutter_recipes = {"mcl_sulfur:cinnabar_polished", "mcl_sulfur:cinnabar"},
})

-- Cinnabar Bricks

core.register_node("mcl_sulfur:cinnabar_bricks", {
	description = S("Cinnabar Bricks"),
	_doc_items_longdesc = S("Decorative variant of cinnabar"),
	_doc_items_hidden = false,
	tiles = {"mcl_sulfur_cinnabar_bricks.png"},
	groups = {pickaxey=1, cinnabar_bricks=1, building_block=1, stonecuttable = 1, overworld_carvable = 1, stone_ore_target = 1, },
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
	_mcl_stonecutter_recipes = { "mcl_sulfur:cinnabar", "mcl_sulfur:cinnabar_polished"},
})

mcl_stairs.register_stair_and_slab("cinnabar_bricks", {
	baseitem = "mcl_sulfur:cinnabar_bricks",
	description_stair = S("Cinnabar Brick Stairs"),
	description_slab = S("Cinnabar Brick Slab"),
	overrides = {_mcl_stonecutter_recipes = {"mcl_sulfur:cinnabar_bricks", "mcl_sulfur:cinnabar_polished", "mcl_sulfur:cinnabar"}},
})

mcl_walls.register_wall_def("mcl_sulfur:cinnabar_bricks_wall", {
	description = S("Cinnabar Brick Wall"),
	source = "mcl_sulfur:cinnabar_bricks",
	_mcl_stonecutter_recipes = {"mcl_sulfur:cinnabar_bricks", "mcl_sulfur:cinnabar_polished", "mcl_sulfur:cinnabar"},
})

-- Chiseled cinnabar

-- Note: chiseled cinnabar can only be obtained via stone cutter with raw cinnabar in java edition.
-- However, in bedrock polished and bricks can also be used
--
-- This implementation follows the bedrock behavior. Since it feel more useful for players

core.register_node("mcl_sulfur:cinnabar_chiseled", {
	description = S("Chiseled Cinnabar"),
	_doc_items_longdesc = S("Decorative variant of cinnabar"),
	_doc_items_hidden = false,
	tiles = {"mcl_sulfur_cinnabar_chiseled.png"},
	groups = {pickaxey=1, cinnabar_chiseled=1, building_block=1, stonecuttable = 1, overworld_carvable = 1, stone_ore_target = 1, },
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
	_mcl_stonecutter_recipes = { "mcl_sulfur:cinnabar", "mcl_sulfur:cinnabar_bricks", "mcl_sulfur:cinnabar_polished"},
})

core.register_craft({
	output = "mcl_sulfur:cinnabar_chiseled",
	recipe = {
		{ "mcl_stairs:slab_cinnabar" },
		{ "mcl_stairs:slab_cinnabar" },
	},
})
