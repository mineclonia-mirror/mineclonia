local S = core.get_translator(core.get_current_modname())

-- Sulur

core.register_node("mcl_sulfur:sulfur", {
	description = S("Sulfur"),
	_doc_items_longdesc = S("Variant of stone that can be found in sulfur caves"),
	_doc_items_hidden = false,
	tiles = {"mcl_sulfur_sulfur.png"},
	groups = {pickaxey=1, sulfur=1, building_block=1, stonecuttable = 1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
	_mcl_crafting_output = {
		square2 = {output = "mcl_sulfur:sulfur_polished 4"},
		square3 = {output = "mcl_sulfur:sulfur_potent"}
	}
})

mcl_stairs.register_stair_and_slab("sulfur", {
	baseitem = "mcl_sulfur:sulfur",
	description_stair = S("Sulfur Stairs"),
	description_slab = S("Sulfur Slab"),
	overrides = {_mcl_stonecutter_recipes = {"mcl_sulfur:sulfur"}},
})

mcl_walls.register_wall_def("mcl_sulfur:sulfur_wall", {
	description = S("Sulfur Wall"),
	source = "mcl_sulfur:sulfur",
	_mcl_stonecutter_recipes = {"mcl_sulfur:sulfur"},
})

-- Polished Sulfur
core.register_node("mcl_sulfur:sulfur_polished", {
	description = S("Polished Sulfur"),
	_doc_items_longdesc = S("Decorative variant of sulfur"),
	_doc_items_hidden = false,
	tiles = {"mcl_sulfur_sulfur_polished.png"},
	groups = {pickaxey=1, sulfur_polished=1, building_block=1, stonecuttable = 1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
	_mcl_crafting_output = {square2 = {output = "mcl_sulfur:sulfur_bricks 4"}},
	_mcl_stonecutter_recipes = { "mcl_sulfur:sulfur"},
})

mcl_stairs.register_stair_and_slab("sulfur_polished_polished", {
	baseitem = "mcl_sulfur:sulfur_polished",
	description_stair = S("Polished Sulfur Stairs"),
	description_slab = S("Polished Sulfur Slab"),
	overrides = {_mcl_stonecutter_recipes = {"mcl_sulfur:sulfur_polished", "mcl_sulfur:sulfur"}},
})

mcl_walls.register_wall_def("mcl_sulfur:sulfur_polished_wall", {
	description = S("Sulfur Wall"),
	source = "mcl_sulfur:sulfur_polished",
	_mcl_stonecutter_recipes = {"mcl_sulfur:sulfur_polished", "mcl_sulfur:sulfur"},
})

-- Sulfur Bricks

core.register_node("mcl_sulfur:sulfur_bricks", {
	description = S("Sulfur Bricks"),
	_doc_items_longdesc = S("Decorative variant of sulfur"),
	_doc_items_hidden = false,
	tiles = {"mcl_sulfur_sulfur_bricks.png"},
	groups = {pickaxey=1, sulfur_bricks=1, building_block=1, stonecuttable = 1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
	_mcl_stonecutter_recipes = { "mcl_sulfur:sulfur", "mcl_sulfur:sulfur_polished"},
})

mcl_stairs.register_stair_and_slab("sulfur_bricks", {
	baseitem = "mcl_sulfur:sulfur_bricks",
	description_stair = S("Sulfur Brick Stairs"),
	description_slab = S("Sulfur Brick Slab"),
	overrides = {_mcl_stonecutter_recipes = {"mcl_sulfur:sulfur_bricks", "mcl_sulfur:sulfur_polished", "mcl_sulfur:sulfur"}},
})

mcl_walls.register_wall_def("mcl_sulfur:sulfur_bricks_wall", {
	description = S("Sulfur Brick Wall"),
	source = "mcl_sulfur:sulfur_bricks",
	_mcl_stonecutter_recipes = {"mcl_sulfur:sulfur_bricks", "mcl_sulfur:sulfur_polished", "mcl_sulfur:sulfur"},
})

-- Chiseled Sulfur

-- Note: chiseled sulfur can only be obtained via stone cutter with raw sulfur in java edition.
-- However, in bedrock polished and bricks can also be used
--
-- This implementation follows the bedrock behavior. Since it feel more useful for players

core.register_node("mcl_sulfur:sulfur_chiseled", {
	description = S("Chiseled Sulfur"),
	_doc_items_longdesc = S("Decorative variant of sulfur"),
	_doc_items_hidden = false,
	tiles = {"mcl_sulfur_sulfur_chiseled.png"},
	groups = {pickaxey=1, sulfur_chiseled=1, building_block=1, stonecuttable = 1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
	_mcl_stonecutter_recipes = { "mcl_sulfur:sulfur", "mcl_sulfur:sulfur_bricks", "mcl_sulfur:sulfur_polished"},
})

core.register_craft({
	output = "mcl_sulfur:sulfur_chiseled",
	recipe = {
		{ "mcl_stairs:slab_sulfur" },
		{ "mcl_stairs:slab_sulfur" },
	},
})

-- Potent sulfur

-- TOOD: potent sulfur's mechanics are not implemented

core.register_node("mcl_sulfur:sulfur_potent", {
	description = S("Potent Sulfur"),
	_doc_items_hidden = false,
	tiles = {"mcl_sulfur_sulfur_potent.png"},
	groups = {pickaxey=1, sulfur_potent=1, building_block=1, unsticky=1 , unmovable_by_piston=1},
	_mcl_stonecutter_recipes = { "mcl_sulfur:sulfur", "mcl_sulfur:sulfur_bricks", "mcl_sulfur:sulfur_polished"},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
})

mcl_wip.register_wip_item("mcl_sulfur:sulfur_potent")
