local mob_class = mcl_mobs.mob_class
local bee = {
	type = "animal",
	spawn_class = "passive",
	passive = true,
	pathfinding = 1,
	hp_min = 6,
	hp_max = 6,
	xp_min = 1,
	xp_max = 3,
	damage = 1,
	head_swivel = "head.control",
	bone_eye_height = 1.1,
	horizontal_head_height=0,
	head_eye_height = 0.54,
	curiosity = 10,
	reach = 3,
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
	sounds = {
	   -- random = "",
	},
	drops = {
	   -- {name = "bee:bee", min = 1, max = 2},
	},

	view_range = 16,
	stepheight = 1.1,
	fall_damage = 0,
	animation = {
				-- Holding Item = 200,220
				--
		stand_start = 1, stand_end = 40, stand_speed = 10,
		walk_start =1, walk_end = 40, speed_normal = 10,
		run_start = 1, run_end = 40, speed_run = 15,
		punch_start = 1, punch_end = 40, punch_speed =15,
		dance_start = 110, dance_end = 185, dance_speed = 80,
	},
	attack_type = "melee",
	gravity_drag = 0.6,
	floats = 1,
	physical = true,
	movement_speed = 4.0,
	airborne = true,
	makes_footstep_sound = false,
	chase_owner_distance = 5.0,
	stop_chasing_distance = 1.0,
	pace_height = 7,
	pace_width = 8,
}

function bee:_find_new_home()
	local n = core.find_node_near(self.object:get_pos(), self.view_range, {"group:beehive", "group:bee_nest"})
	if n then
		self._home = n
		return true
	end
end

function bee:_should_go_home()
	return self._got_nectar
end

local bees_per_hive = 3

function bee:_nest()
	if self._home then
		local m = core.get_meta(self._home)
		local bees_current = m:get_int("mobs_mc:bees_present")
		if bees_current < bees_per_hive then
			m:set_int("mobs_mc:bees_present", bees_current + 1)
			self:safe_remove()
			return self._home
		end
	end
end

function bee:_should_sleep(pos)
	if mcl_worlds.pos_to_dimension(pos) ~= "overworld" then return false end

	if mcl_weather.get_weather() == "rain" then return true end

	local tod = core.get_timeofday() * 24000
	if tod < 6000 or tod < 18000 then return true end
	return false
end

function bee:airborne_pacing_target (pos, width, height, groups)
	if self._home and self:_should_sleep(pos) and vector.distance(pos, self._home) < 1 then
		return self:_nest()
	elseif self._home and self:_should_go_home() then
		return self._home
	else
		if not self._home then
			if self:_find_new_home() then return self._home end
		end
		local aa = vector.offset (pos, -3, -6, -3)
		local bb = vector.offset (pos, 3, 6, 3)
		local nodes = core.find_nodes_in_area_under_air (aa, bb, {"group:flower"})
		for _, v in pairs(nodes) do
			if vector.distance(pos, v) < 1 then
				self._got_nectar = true
				break
			end
		end
		if #nodes > 0 then
			return vector.offset (nodes[math.random (#nodes)], 0, 1, 0)
		end
	end
	return mob_class.airborne_pacing_target (self, pos, width, height, groups)
end

bee.ai_functions = {
	mob_class.check_pace,
}

bee.gwp_penalties = table.copy (mob_class.gwp_penalties)
bee.gwp_penalties.DANGER_FIRE = -1.0
bee.gwp_penalties.DAMAGE_FIRE = -1.0

mcl_mobs.register_mob("mobs_mc:bee", bee)

mcl_mobs.register_egg("mobs_mc:bee", "Bee", "#6f4833", "#daa047", 0)
