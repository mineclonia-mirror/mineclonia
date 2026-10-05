local shelf_mushroom_tpl = {
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "4dir",
	propagate_light = true,
	groups = {
		dig_by_piston = 1, dig_by_water = 1, destroy_by_lava_flow = 1, stew_mushroom = 1,
		bouncy = 75, fall_damage_add_percent=-50, compostability = 65, unsticky = 1, 
		flammable = 1, fire_encouragement = 60, fire_flammability = 100
	},
	_mcl_hardness = 0
}

core.register_node("mcl_poplar:shelf_mushroom", table.merge(shelf_mushroom_tpl, {
	description = "Shelf mushroom",
	tiles = {
		"mcl_poplar_shelf_mushroom_top.png", "mcl_poplar_shelf_mushroom_bottom.png",
		"mcl_poplar_shelf_mushroom_side.png^[transformFX", "mcl_poplar_shelf_mushroom_side.png",
		"mcl_poplar_shelf_mushroom_back.png", "mcl_poplar_shelf_mushroom_front.png",
	},
	node_box = {
		type = "fixed",
		fixed = {
			{
				5/16, 3/16, 8/16,
				-5/16, 1/16, 1/16
			},
			{
				3/16, 1/16, 8/16,
				-3/16, 0/16, 4/16
			},
		}
	},
	_on_bone_meal = function(itemstack, placer, pointed_thing, pos, node)
		core.swap_node(pos, {name = "mcl_poplar:shelf_mushroom_big", param2 = node.param2})
		return true
	end,
}))

core.register_node("mcl_poplar:shelf_mushroom_big", table.merge(shelf_mushroom_tpl ,{
	description = "Big Shelf Mushroom",
	tiles = {
		"mcl_poplar_shelf_mushroom_big_top.png", "mcl_poplar_shelf_mushroom_big_bottom.png",
		"mcl_poplar_shelf_mushroom_big_side.png^[transformFX", "mcl_poplar_shelf_mushroom_big_side.png",
		"mcl_poplar_shelf_mushroom_big_back.png", "mcl_poplar_shelf_mushroom_big_front.png",
	},
	groups = table.merge(shelf_mushroom_tpl.groups, {not_in_creative_inventory = 1,}),
	drop = "mcl_poplar:shelf_mushroom 2",
	node_box = {
		type = "fixed",
		fixed = {
			{
				7/16, 3/16, 8/16,
				-7/16, 0/16, -2/16
			},
			{
				4/16, 0/16, 8/16,
				-4/16, -2/16, 2/16
			},
		}
	}
}))
