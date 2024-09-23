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



	--[[
	do_custom = function(self,dtime)

	  --

	end,


	on_spawn = function(self, pos)

		   --local pos = self.object:get_pos()
		end

	  on_die = function(self, pos)
		   --
	end

	]]
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
