local S = core.get_translator("mcl_tools")
-- Spear NYI
--
-- This section of the wiki isn't implemented fully, due to engine limitations. This *could* be implemented with very hacky
-- workarounds (implementing our own ray caster for entity AABB's that are inflated by 0.125)
--
-- > Spears can damage multiple entities with a single attack. Spears inflate the hitboxes of targets by 0.125 when calculating
-- > hit registration, giving them more effective area. It is not possible to break blocks while holding a spear, and instead an
-- > attack is performed. Spears have the unique ability to attack through non-solid blocks like cobwebs and tall grass.
-- > Spears have two methods of attacking:
--
-- Another thing is the fact that spears shouldn't be affected by stength and weakness potions. But there is no way to filter
-- out these effects without also filtering out sharpness or smite
--
-- In addition the "disengaged" phase the charge attack is supposed to deal damage but not knockback, but there is no way
-- to do that
--
-- Yet another thing is the spear visual, the engine doesn't provide a way to animate the wield item like that

local spear_charge_data = {}

local spear_jab_data = {}

-- Workaround the fact that `get_look_dir` may be confusing for touchscreen users that don't have a crosshair
-- So we add a fake one
local spear_crosshair_huds = {}

local spear_reach = 4.5
-- local spear_charge_minimum_speed_for_knockback = 5.1
local spear_charge_minimum_speed_for_damage = 4.6
local spear_lunge_velocity_multiplier = 0.458 / 0.05
local minimum_attack_distance = 2

local function get_next_phase(phase, stack_def)
	if phase == "activation" then
		return "engaged", stack_def._mcl_spear_engaged_phase_duration, "engaged_spear_overlay.png"
	elseif phase == "engaged" then
		return "tired", stack_def._mcl_spear_tired_phase_duration, "tired_spear_overlay.png"
	elseif phase == "tired" then
		return "disengaged", stack_def._mcl_spear_disengaged_phase_duration, "disengaged_spear_overlay.png"
	else
		return "end of charge", math.huge, ""
	end
end

local function can_player_lunge(player)
	local feet_node = core.get_node(player:get_pos())
	local feet_def = core.registered_nodes[feet_node.name]
	return not mcl_player.players[player].elytra.active
		and (not feet_def or feet_def.liquidtype == "none")
		and not player:get_attach()
		and mcl_hunger.get_hunger(player) >= 6
end

local function spear_on_use(stack, user, pointed_thing)
	if spear_charge_data[user] then return end
	local spear_def = core.registered_items[stack:get_name()]

	local timestamp = core.get_us_time()
	if timestamp - (spear_jab_data[user] or 0) < (spear_def._mcl_spear_jab_cooldown * 1000000) then
		return
	end

	spear_jab_data[user] = timestamp

	local enchantments = mcl_enchanting.get_enchantments(stack)
	local user_pos = vector.offset(user:get_pos(), 0, 1.5, 0)
	local user_look = user:get_look_dir()

	if enchantments.lunge and can_player_lunge(user) then
		local lunge_velocity = vector.copy(user_look)
		lunge_velocity.y = 0
		lunge_velocity = vector.multiply(lunge_velocity, spear_lunge_velocity_multiplier * enchantments.lunge)

		mcl_hunger.exhaust(user:get_player_name(), mcl_hunger.EXHAUST_LVL * enchantments.lunge)

		user:add_velocity(lunge_velocity)

		stack:add_wear_by_uses(spear_def.groups.uses)
		return stack
	end

	local ray = core.raycast(user_pos, user_pos + vector.multiply(user_look, spear_reach), true)
	local sharpness_damage = (enchantments.sharpness and 1 + (enchantments.sharpness - 1) / 2) or 0

	for ray_pointed_thing in ray do
		if ray_pointed_thing.type == "node" then
			local node = core.get_node(ray_pointed_thing.under)

			if not core.registered_nodes[node.name] or core.registered_nodes[node.name].walkable then
				break
			end
		elseif ray_pointed_thing.type == "object" and ray_pointed_thing.ref ~= user then
			local distance = vector.distance(user_pos, ray_pointed_thing.ref:get_pos())
			if distance >= minimum_attack_distance then
				ray_pointed_thing.ref:punch(user, spear_def._mcl_spear_jab_cooldown, {
					full_punch_interval = spear_def._mcl_spear_jab_cooldown,
					damage_groups = {fleshy = spear_def.tool_capabilities.damage_groups.fleshy * spear_def._mcl_spear_jab_damage + sharpness_damage},
				}, nil)
			end
		end
	end

	stack:add_wear_by_uses(spear_def.groups.uses)

	return stack
end

function mcl_tools.register_spear(name, spear_def)
	core.register_tool(name, {
		description = spear_def.description,
		longdesc = S("A spear is tool impale your enemies, either by using the jab attack, or charging at them"),
		usagehelp = S("To peform a jab attack, left click the enemy. To peform the charge attach, right-click and run at the enemy"),
		inventory_image = spear_def.inventory_image,
		wield_image = spear_def.wield_image,
		groups = { weapon = 1, enchantability = spear_def.enchantability, spear = 1, tool = 1, uses = spear_def.uses},
		_repair_material = spear_def.repair_material,
		range = spear_reach,

		-- this is only used so that mods that the damage is modified by mods that change tool capabilities (eg. mcl_enchanting)
		-- will proportionally increase the damage
		tool_capabilities = {
			full_punch_interval = 1,
			damage_groups = {fleshy = 1},
		},
		on_use = spear_on_use,
		_mcl_spear_jab_damage = spear_def.jab_damage,
		_mcl_spear_jab_cooldown = spear_def.jab_cooldown,
		_mcl_spear_charge_delay = spear_def.charge_delay,
		_mcl_spear_minimum_dismount_speed = spear_def.charge_minimum_dismount_speed,
		_mcl_spear_engaged_phase_duration = spear_def.engaged_phase_duration,
		_mcl_spear_tired_phase_duration = spear_def.tired_phase_duration,
		_mcl_spear_disengaged_phase_duration = spear_def.disengaged_phase_duration,
		_mcl_spear_charge_damage_multiplier = spear_def.charge_damage_multiplier,
	})

end

core.register_on_leaveplayer(function(player)
	spear_charge_data[player] = nil
	spear_jab_data[player] = nil
	spear_crosshair_huds[player] = nil
end)

local charge_minimum_steps_to_consider_seperate_hits = 2
mcl_player.register_globalstep(function(player, dtime)
	local wielded_stack = player:get_wielded_item()
	local wielded_name = wielded_stack:get_name()

	if core.get_item_group(wielded_name, "spear") == 0 then
		if spear_crosshair_huds[player] then
			player:hud_remove(spear_crosshair_huds[player])
			spear_crosshair_huds[player] = nil
		end
		return
	end

	local controls = player:get_player_control()
	local window_info = core.get_player_window_information(player:get_player_name())
	local is_touchscreen = window_info and window_info.touch_controls

	if is_touchscreen and not spear_crosshair_huds[player] then
		spear_crosshair_huds[player] = player:hud_add({
			type = "image",
			alignment = {x = 0.5, y = 0.5},
			position = {x = 0.5, y = 0.5},
			scale = {x = 5, y = 5},
			text = "mcl_tools_spears_crosshair.png"
		})
	end

	if controls.RMB then
		local stack_def = core.registered_items[wielded_name]
		local spear_head_pos = vector.offset(player:get_pos(), 0, 1.5, 0) + player:get_look_dir()
		local player_velocity = player:get_velocity()
		spear_charge_data[player] = spear_charge_data[player] or {
			phase = "activation", phase_timer = 0,
			phase_duration = stack_def._mcl_spear_charge_delay,
			step_counter = 0,
			object_store = {},
			spear_head_pos = spear_head_pos
		}

		local data = spear_charge_data[player]

		data.step_counter = data.step_counter + 1
		data.phase_timer = data.phase_timer + dtime
		if data.phase_timer >= data.phase_duration then
			local spear_overlay
			data.phase, data.phase_duration, spear_overlay = get_next_phase(data.phase, stack_def)
			data.phase_timer = data.phase_timer - data.phase_duration

			local stack_meta = wielded_stack:get_meta()
			stack_meta:set_string("wield_image", core.registered_items[wielded_name].wield_image .. "^" .. spear_overlay)
		end

		if data.phase == "end of charge" then
			player:set_wielded_item(wielded_stack)
			return
		end

		local ray = core.raycast(data.spear_head_pos, spear_head_pos, true, false)

		for pointed_thing in ray do
			if pointed_thing.type ~= "object" then
				break
			end
			local obj = pointed_thing.ref
			local props = obj:get_properties()
			if obj ~= player and props.physical then
				local speed_diff = vector.distance(player_velocity, obj:get_velocity())
				local step_diff = data.step_counter - (data.object_store[obj] or -2137)

				-- local deal_knockback = speed_diff >= spear_charge_minimum_speed_for_knockback
				-- 	and (
				-- 		data.phase == "engaged"
				-- 		or data.phase == "tired"
				-- 	)

				-- There is a hidden assumption here that `spear_charge_minimum_speed_for_knockback` is ALWAYS bigger than `spear_charge_minimum_speed_for_damage`
				local deal_damage = speed_diff >= spear_charge_minimum_speed_for_damage
					and data.phase ~= "activation"

				if deal_damage and step_diff >= charge_minimum_steps_to_consider_seperate_hits then
					if data.phase == "engaged" and speed_diff >= stack_def._mcl_spear_minimum_dismount_speed and obj:get_attach() then
						obj:set_detach()
					end

					obj:punch(player, 1, {
						full_punch_interval = 1,
						damage_groups = {fleshy = stack_def.tool_capabilities.damage_groups.fleshy * speed_diff * stack_def._mcl_spear_charge_damage_multiplier}
					})

					wielded_stack:add_wear_by_uses(stack_def.groups.uses)
				end

				data.object_store[obj] = data.step_counter
			end
		end

		player:set_wielded_item(wielded_stack)
	elseif spear_charge_data[player] then
		local stack_meta = wielded_stack:get_meta()
		stack_meta:set_string("wield_image", "")
		player:set_wielded_item(wielded_stack)
		spear_charge_data[player] = nil
	end
end)
