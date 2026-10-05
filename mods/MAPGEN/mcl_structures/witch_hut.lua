if mcl_levelgen.enable_ersatz then
	return false
end

local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)

local function spawn_witch(p1,p2)
	local c = core.find_node_near(p1,15,{"mcl_cauldrons:cauldron"})
	if c then
		local nn = core.find_nodes_in_area_under_air(vector.offset(p1,0,-1,0),vector.offset(p2,0,-1,0),{"mcl_trees:wood_spruce"})
		local witch
		if mcl_vars.difficulty > 0 then
			witch = core.add_entity(vector.offset(nn[math.random(#nn)],0,1,0),"mobs_mc:witch"):get_luaentity()
			witch.can_despawn = false
		end
		local catobject = core.add_entity(vector.offset(nn[math.random(#nn)],0,1,0),"mobs_mc:cat")
		if catobject and catobject:get_pos() then
			local cat=catobject:get_luaentity()
			cat._default_texture = "mobs_mc_cat_all_black.png"
			cat.base_texture = {
				cat._default_texture,
			}
			cat:set_textures (cat.base_texture)
			cat.can_despawn = false
		end
		return
	end
end

local function hut_placement_callback(pos,def,_)
	local hl = def.sidelen / 2
	local legs = core.find_nodes_in_area(vector.offset(pos,-hl,0,-hl),vector.offset(pos,hl,0,hl), {"mcl_trees:tree_oak"})
	local tree = {}
	for _,leg in pairs(legs) do
		while core.get_item_group(mcl_util.get_node_forced(vector.offset(leg,0,-1,0)).name, "water") ~= 0 do
			leg = vector.offset(leg,0,-1,0)
			table.insert(tree,leg)
		end
	end
	core.bulk_swap_node(tree, {name = "mcl_trees:tree_oak", param2 = 2})
	spawn_witch(vector.offset(pos,-hl,-hl,-hl),vector.offset(pos,hl,hl,hl))
end

mcl_structures.register_structure("witch_hut",{
	place_on = {"group:sand","group:grass_block","mcl_core:water_source","group:dirt"},
	flags = "place_center_x, place_center_z, liquid_surface, force_placement",
	sidelen = 8,
	chunk_probability = 8,
	y_max = mcl_vars.mg_overworld_max,
	y_min = -4,
	y_offset = 0,
	biomes = { "Swampland", "Swampland_ocean", "Swampland_shore" },
	filenames = { modpath.."/schematics/mcl_structures_witch_hut.mts" },
	after_place = hut_placement_callback,
})
