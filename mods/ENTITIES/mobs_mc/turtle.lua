mcl_mobs.register_mob("mobs_mc:turtle", {
	type = "animal",
	spawn_class = "passive",
	attack_type = "dogfight",
	attacks_monsters = true,
	specific_attack = {
		"mobs_mc:slime_small",
		"mobs_mc:magma_cube_small"
	},
	damage = 8,
	hp_min = 10,
	hp_max = 10,
	xp_min = 1,
	xp_max = 3,
	double_melee_attack = false,
	reach = 2,
	armor = 5,
	collisionbox = { -0.6, -0.05, -0.6, 0.6, 0.5, 0.6 },
	visual = "mesh",
	mesh = "mobs_mc_turtle.b3d",
	visual_size = { x = 1, y = 1},
	textures = { "mobs_mc_turtle.png" },
	makes_footstep_sound = true,
	walk_velocity = 1,
	run_velocity = 4,
	view_range = 16,
	stepheight = 1.1,
	jump = true,
	jump_height = 10,
	--suffocation = true,
	fear_height = 4,
	---
	swims = true,
	spawn_in_group = 5,
	--breathes_in_water = true,
	follow = { "mcl_ocean:seagrass" },
	sounds = {
	   -- random = "",
	},

	drops = {
	   -- {name = "turtle:turtle", min = 1, max = 2},
	},

   animation = {
				-- swing = 145,165
				-- idinging underwater = 175,250
		stand_start = 1, stand_end = 20, stand_speed = 10,
		walk_start = 30, walk_end =85, speed_normal = 10,
		--run_start = 0, run_end = 0, speed_run = 15,
		--punch_start = 0, punch_end = 0, punch_speed =15,
		-- = 145,fly_end = 165,fly_speed = 10,
		--die_start = 0, die_end = 0, die_speed = 0,--die_loop = 0,
	},

	on_rightclick = function(self, clicker)
		local it = clicker:get_wielded_item()
		if it:get_name() == "mcl_ocean:seagrass" then
			self:feed_tame(clicker, 4, true, false, true)
			if not minetest.is_creative_enabled(clicker:get_player_name()) then
				it:take_item()
				clicker:set_wielded_item(it)
			end
		end
	end,

	on_grow = function(self)
		mcl_util.drop_item_stack(self.object:get_pos(), ItemStack("mcl_mobitems:scute"))
	end,

	on_spawn = function(self, pos)
		if math.random(10) == 1 then
			self:make_child()
			self._home_position = vector.copy(pos)
			self._hornytimer = 0
		end
	end,
})

local function start_egg_timer(pos)
	minetest.get_node_timer(pos):start(math.random(3600,24000))
end

minetest.override_item("mcl_mobitems:turtle_egg", {
	on_timer = function(pos)
		local tod = minetest.get_timeofday()
		if tod < 0.14 and tod < 0.18 then
			local o = mcl_mobs.spawn(pos, "mobs_mc:turtle")
			if o then
				o:get_luaentity():make_child()
			end
			minetest.remove_node(pos)
		else
			start_egg_timer(pos)
		end
		return false
	end,
	on_construct = start_egg_timer,
})

local tspawn = {
	name = "mobs_mc:turtle",
	type_of_spawning = "ground",
	dimension = "overworld",
	min_height = mobs_mc.water_level-4,
	max_height = mobs_mc.water_level+3,
	min_light = 0,
	max_light = minetest.LIGHT_MAX + 1,
	aoc = 7,
	chance = 100,
	biomes = {
		"Plains_beach",
		"ExtremeHills_beach",
		"MangroveSwamp_shore",
		"ColdTaiga_beach",
		"ColdTaiga_beach_water",
		"Swampland_shore",
		"Taiga_beach",
		"Forest_beach",
		"FlowerForest_beach",
		"Savanna_beach",
		"Jungle_shore",
		"JungleM_shore",
	},
}
mcl_mobs.spawn_setup(tspawn)
mcl_mobs.spawn_setup(table.merge(tspawn, {
	type_of_spawning = "water",
}))

mcl_mobs.register_egg("mobs_mc:turtle", "turtle", "#516720", "#ded88f", 0)
