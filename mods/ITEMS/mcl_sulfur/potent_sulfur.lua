local S = core.get_translator(core.get_current_modname())

local POTENT_SULFUR_TIMER_INTERVAL = 0.5

local NOXIOUS_GAS_RADIUS = 3
local NOXIOUS_GAS_STEP_INTERVAL = 0.5

local GEYSER_RADIUS = 1
local GEYSER_RADIUS_SQUARED = GEYSER_RADIUS^2

local noxious_gas_entries = {}
local geyser_eruption_entries = {}

local function add_to_vec(vec, x, y, z)
	vec.x = vec.x + x
	vec.y = vec.y + y
	vec.z = vec.z + z
end

local function subtract_from_vec(vec, x, y, z)
	vec.x = vec.x - x
	vec.y = vec.y - y
	vec.z = vec.z - z
end

-- Courtesy of minecraft wiki:
--
-- > When a block of potent sulfur is placed, two random values are assigned to it based
-- > on the position of the block in the world: a dormant value (between 15 and 30)
-- > and an eruption value (between 1 and 2)
--
-- How these values are derived isn't specified. So instead i implement my own function.
-- It takes a modulo of a position hash by a large prime number, and transforms it into the
-- correct value range
local function get_geyser_dormant_value(phash)
	return ((phash % 6053) % 16) + 15
end

local function get_geyser_eruption_value(phash)
	return ((phash % 13441) % 2) + 1
end

local function geyser_launch_object(object, geyser_entry, dtime)
	local obj_pos = object:get_pos()
	local obj_vel = object:get_velocity()
	local percentage = (obj_pos.y - geyser_entry.potent_sulfur_pos.y) / geyser_entry.geyser_height
	if obj_vel.y > 12 then
		return
	end
	object:add_velocity(vector.new(0, 250 * dtime * (1 - percentage), 0))
end

local function scan_water_column(potent_sulfur_pos)
	local off_pos = vector.offset(potent_sulfur_pos, 0, 1, 0)
	local node = core.get_node(off_pos)
	local water_column_height = 0

	while node.name == "mcl_core:water_source" and water_column_height < 5 do
		water_column_height = water_column_height + 1
		add_to_vec(off_pos, 0, 1, 0)
		node = core.get_node(off_pos)
	end

	local is_valid = water_column_height <= 4
		and water_column_height ~= 0
		and core.registered_nodes[node.name]
		and not core.registered_nodes[node.name].walkable

	return off_pos, water_column_height, is_valid
end

local function add_noxious_gas(potent_sulfur_pos, surface_pos)
	local sulfur_phash = core.hash_node_position(potent_sulfur_pos)

	local entry
	if noxious_gas_entries[sulfur_phash] then
		entry = noxious_gas_entries[sulfur_phash]
	else
		entry = {potent_sulfur_pos = potent_sulfur_pos}
	end

	entry.water_surface_pos = surface_pos
	noxious_gas_entries[sulfur_phash] = entry
end

local function set_geyser_state(meta, state, duration)
	meta:set_float("mcl_sulfur_geyser_timeout", duration)
	meta:set_string("mcl_sulfur_geyser_state", state)
end

local function delete_geyser_eruption_entry(phash)
	local entry = geyser_eruption_entries[phash]
	if entry and entry.particlespawner_handler then
		mcl_player.delete_particlespawner(entry.particlespawner_handler)
	end

	geyser_eruption_entries[phash] = nil
end

local function start_geyser_eruption(potent_sulfur_pos, surface_pos, water_column_height)
	local phash = core.hash_node_position(potent_sulfur_pos)

	-- Counting from the bottom of water
	local geyser_height = water_column_height + 1
	local off_pos = vector.offset(surface_pos, 0, 1, 0)
	local node = core.get_node(off_pos)
	local ndef = core.registered_nodes[node.name]

	while ndef and not ndef.walkable and geyser_height < water_column_height * 5 do
		geyser_height = geyser_height + 1
		add_to_vec(off_pos, 0, 1, 0)
		node = core.get_node(off_pos)
		ndef = core.registered_nodes[node.name]
	end

	local entry = geyser_eruption_entries[phash]
	if entry and entry.geyser_height == geyser_height and entry.surface_pos == surface_pos then
		return
	elseif entry then
		delete_geyser_eruption_entry(phash)
	end

	local particlespawner_handler = mcl_player.add_particlespawner(surface_pos, {
		amount = 4 * (water_column_height * 5),
		time = 0,
		size = {min = 5, max = 15},
		texpool = {
			"mcl_sulfur_geyser_particle_1.png",
			"mcl_sulfur_geyser_particle_2.png"
		},
		pos = surface_pos,
		drag = 0.5,
		acc = {min = vector.new(0, 0, 0), max = vector.new(1.5, 0, 1.5)},
		radius = {
			min = 0,
			max = 0.75,
			bias = 0.25,
		},
		attract = {
			kind = "plane",
			strength = {min = 0.75, max = 2},
			direction = vector.new(0, 1, 0),
			origin = vector.offset(potent_sulfur_pos, 0, geyser_height, 0),
		}
	})

	geyser_eruption_entries[phash] = {
		potent_sulfur_pos = potent_sulfur_pos,
		surface_pos = surface_pos,
		geyser_height = geyser_height,
		particlespawner_handler = particlespawner_handler
	}
end

local function geyser_step(potent_sulfur_pos, surface_pos, water_column_height, dtime)
	local meta = core.get_meta(potent_sulfur_pos)
	local phash = core.hash_node_position(potent_sulfur_pos)

	local timeout = meta:get_float("mcl_sulfur_geyser_timeout")
	local geyser_state = meta:get_string("mcl_sulfur_geyser_state")

	if geyser_state == "" then
		local dormant_value = get_geyser_dormant_value(phash)
		local duration = 10 * (water_column_height - 1) + dormant_value

		set_geyser_state(meta, "dormant", duration)

		geyser_state = "dormant"
		timeout = duration
	end

	timeout = timeout - dtime

	if timeout <= 0 then
		if geyser_state == "dormant" then
			local eruption_value = get_geyser_eruption_value(phash)
			local duration = (water_column_height - 1) + eruption_value

			start_geyser_eruption(potent_sulfur_pos, surface_pos, water_column_height)
			set_geyser_state(meta, "eruption", duration)
		elseif geyser_state == "eruption" then
			local dormant_value = get_geyser_dormant_value(phash)

			delete_geyser_eruption_entry(phash)
			set_geyser_state(meta, "dormant", 10 * (water_column_height - 1) + dormant_value)
		end
	else
		meta:set_float("mcl_sulfur_geyser_timeout", timeout)
	end

end

local function potent_sulfur_on_timer(pos, elapsed, node, timeout)
	-- Even though `on_timer` can be automatically restarted by returninng `true
	-- the timer is started manually. This is because a crash in `on_timer` would
	-- put the node in an invalid state
	local timer = core.get_node_timer(pos)
	timer:start(POTENT_SULFUR_TIMER_INTERVAL)


	local surface_pos, water_column_height, is_valid = scan_water_column(pos)
	local phash = core.hash_node_position(pos)

	if not is_valid then
		noxious_gas_entries[phash] = nil
		delete_geyser_eruption_entry(phash)
		return
	end

	add_noxious_gas(pos, surface_pos)

	add_to_vec(pos, 0, -1, 0)
	local node_under = core.get_node(pos)
	subtract_from_vec(pos, 0, -1, 0)


	if node_under.name == "mcl_nether:magma" then
		geyser_step(pos, surface_pos, water_column_height, elapsed)
	elseif node_under.name == "mcl_core:lava_source" then
		start_geyser_eruption(pos, surface_pos, water_column_height)
	else
		delete_geyser_eruption_entry(phash)
	end

	return true
end

local function potent_sulfur_on_construct(pos)
	local timer = core.get_node_timer(pos)
	timer:start(POTENT_SULFUR_TIMER_INTERVAL)
end

local function potent_sulfur_on_destruct(pos)
	local phash = core.hash_node_position(pos)
	delete_geyser_eruption_entry(phash)
	noxious_gas_entries[phash] = nil
end

core.register_node("mcl_sulfur:sulfur_potent", {
	description = S("Potent Sulfur"),
	_doc_items_hidden = false,
	tiles = {"mcl_sulfur_sulfur_potent.png"},
	groups = {pickaxey=1, sulfur_potent=1, building_block=1, unsticky=1, unmovable_by_piston=1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	on_construct = potent_sulfur_on_construct,
	on_timer = potent_sulfur_on_timer,
	on_destruct = potent_sulfur_on_destruct,
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
})

local noxious_gas_time_accumulator = 0
core.register_globalstep(function(dtime)
	noxious_gas_time_accumulator = noxious_gas_time_accumulator + dtime
	if noxious_gas_time_accumulator >= NOXIOUS_GAS_STEP_INTERVAL then
		noxious_gas_time_accumulator = noxious_gas_time_accumulator - NOXIOUS_GAS_STEP_INTERVAL

		for phash, entry in pairs(noxious_gas_entries) do
			local node = core.get_node(entry.potent_sulfur_pos)

			if node.name == "mcl_sulfur:sulfur_potent" then
				for obj in core.objects_inside_radius(entry.water_surface_pos, NOXIOUS_GAS_RADIUS) do
					local obj_pos = obj:get_pos()
					local obj_node = core.get_node(obj_pos)

					-- This is an innacurate heuristic. But it should mostly work
					if obj_node.name == "mcl_core:water_source" then
						mcl_potions.give_effect_by_level("nausea", obj, 1, 4)
					end
				end
			else
				noxious_gas_entries[phash] = nil
			end
		end
	end

	for phash, entry in pairs(geyser_eruption_entries) do
		local node = core.get_node(entry.potent_sulfur_pos)

		if node.name == "mcl_sulfur:sulfur_potent" then
			local geyser_end_y = entry.surface_pos.y + entry.geyser_height
			local min_pos = vector.offset(entry.potent_sulfur_pos, -GEYSER_RADIUS_SQUARED, -1, -GEYSER_RADIUS_SQUARED)
			local max_pos = vector.offset(entry.potent_sulfur_pos, GEYSER_RADIUS_SQUARED, entry.geyser_height + 1, GEYSER_RADIUS_SQUARED)

			for obj in core.objects_in_area(min_pos, max_pos) do
				local obj_pos = obj:get_pos()
				local is_player = obj:is_player()
				local l = obj:get_luaentity()

				local horizontal_distance_squared = ((entry.potent_sulfur_pos.z - obj_pos.z)^2 + (entry.potent_sulfur_pos.x - obj_pos.x)^2)
				if (is_player or (l and (l.is_mob or l.name == "__builtin:item")))
						and obj_pos.y >= entry.potent_sulfur_pos.y
						and obj_pos.y <= geyser_end_y
						and horizontal_distance_squared < GEYSER_RADIUS_SQUARED then
					geyser_launch_object(obj, entry, dtime)
				end
			end
		else
			delete_geyser_eruption_entry(phash)
		end
	end
end)
