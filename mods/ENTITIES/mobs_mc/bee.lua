mcl_mobs.register_mob("mobs_mc:bee", {
	type = "animal",
	spawn_class = "passive",
	--damage = 1,
	hp_min = 20,
	hp_max = 20,
	xp_min = 5,
	xp_max = 5,
   -- attack_type = "dogshoot",
	reach = 3,
	armor = 10,
	collisionbox = { -0.2, -0.1, -0.2, 0.2, 0.7, 0.2 },
	visual = "mesh",
	mesh = "mobs_mc_bee.b3d",
	visual_size = { x = 1, y = 1},
	textures = {
		{"mobs_mc_bee.png"},
	},
	glow = 4,
	fly = true,
	fly_in = { "air" },
	fly_velocity = 4,
	--walk_velocity = 1,
	--run_velocity = 2,

	sounds = {
	   -- random = "",
	},
	drops = {
	   -- {name = "bee:bee", min = 1, max = 2},
	},

	view_range = 16,
	stepheight = 1.1,
	fall_damage = false,
	--instant_death = true,
	--fire_resistant = true,
	--suffocation = true,

   animation = {
				-- Dacing = 110,185
				-- Holding Item = 200,220
		stand_start = 1, stand_end = 40, stand_speed = 10,
		walk_start =1, walk_end = 40, speed_normal = 10,
		run_start = 1, run_end = 40, speed_run = 15,
		punch_start = 1, punch_end = 40, punch_speed =15,
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

mcl_mobs.register_egg("mobs_mc:bee", "Bee", "#6f4833", "#daa047", 0)
