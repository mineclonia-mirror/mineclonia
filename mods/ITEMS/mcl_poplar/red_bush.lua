local S = core.get_translator(core.get_current_modname())

core.register_node("mcl_poplar:red_shrub", {
	description = S("Red Bush"),
	drop = "mcl_flowers:firefly_bush",
	drawtype = "plantlike",
	waving = 1,
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	buildable_to = true,
	groups = {
		handy = 1, shearsy = 1, attached_node = 1, deco_block = 1,
		plant = 1, place_flowerlike = 2, flammable = 3,
		fire_encouragement = 60, fire_flammability = 100, dig_by_piston = 1,
		dig_by_water = 1, destroy_by_lava_flow = 1, compostability = 30
	},
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	tiles = {"mcl_poplar_red_bush.png"},
	inventory_image = "mcl_poplar_red_bush.png",
	wield_image = "mcl_poplar_red_bush.png",
	selection_box = {
		type = "fixed",
		fixed = {-0.3, -0.5, -0.3, 0.3, 0.4, 0.3}
	},
	node_placement_prediction = "",
	on_place = mcl_util.generate_on_place_plant_function(function(pos)
		local below = vector.offset(pos, 0, -1, 0)
		local soil = core.get_node_or_nil(below)
		if not soil then return end
		local allowed_nodes = {
			"mcl_core:dirt_with_grass", "mcl_core:mycelium", "mcl_core:podzol", "mcl_core:dirt",
			"mcl_core:coarse_dirt", "mcl_lush_caves:rooted_dirt", "mcl_farming:soil", "mcl_farming:soil_wet",
			"mcl_mud:mud", "mcl_mangrove:mangrove_mud_roots", "mcl_lush_caves:moss", "mcl_pale_oak:pale_moss"
		}

		if table.indexof(allowed_nodes, soil.name) ~= -1 then
			return true, 0
		end
	end),
	_on_bone_meal = mcl_flowers.on_bone_meal,
	_mcl_hardness = 0,
})
