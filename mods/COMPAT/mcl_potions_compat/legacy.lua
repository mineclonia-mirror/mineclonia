-- Compatibility with old mcl2 potions functions (before the VL potions rewrite)

local old_lpe = mcl_potions._load_player_effects
function mcl_potions._load_player_effects(player, EF)

	if not player:is_player() then
		return
	end
	local meta = player:get_meta()

	-- handle legacy meta strings
	local legacy_invisible = minetest.deserialize(meta:get_string("_is_invisible"))
	local legacy_poisoned = minetest.deserialize(meta:get_string("_is_poisoned"))
	local legacy_regenerating = minetest.deserialize(meta:get_string("_is_regenerating"))
	local legacy_strong = minetest.deserialize(meta:get_string("_is_strong"))
	local legacy_weak = minetest.deserialize(meta:get_string("_is_weak"))
	local legacy_water_breathing = minetest.deserialize(meta:get_string("_is_water_breathing"))
	local legacy_leaping = minetest.deserialize(meta:get_string("_is_leaping"))
	local legacy_swift = minetest.deserialize(meta:get_string("_is_swift"))
	local legacy_night_vision = minetest.deserialize(meta:get_string("_is_cat"))
	local legacy_fireproof = minetest.deserialize(meta:get_string("_is_fire_proof"))
	local legacy_bad_omen = minetest.deserialize(meta:get_string("_has_bad_omen"))
	local legacy_withering = minetest.deserialize(meta:get_string("_is_withering"))
	if legacy_invisible then
		EF.invisibility[player] = legacy_invisible
		meta:set_string("_is_invisible", "")
	end
	if legacy_poisoned then
		EF.poison[player] = legacy_poisoned
		meta:set_string("_is_poisoned", "")
	end
	if legacy_regenerating then
		EF.regeneration[player] = legacy_regenerating
		meta:set_string("_is_regenerating", "")
	end
	if legacy_strong then
		EF.strength[player] = legacy_strong
		meta:set_string("_is_strong", "")
	end
	if legacy_weak then
		EF.weakness[player] = legacy_weak
		meta:set_string("_is_weak", "")
	end
	if legacy_water_breathing then
		EF.water_breathing[player] = legacy_water_breathing
		meta:set_string("_is_water_breating", "")
	end
	if legacy_leaping then
		EF.leaping[player] = legacy_leaping
		meta:set_string("_is_leaping", "")
	end
	if legacy_swift then
		EF.swiftness[player] = legacy_swift
		meta:set_string("_is_swift", "")
	end
	if legacy_night_vision then
		EF.night_vision[player] = legacy_night_vision
		meta:set_string("_is_cat", "")
	end
	if legacy_fireproof then
		EF.fire_resistance[player] = legacy_fireproof
		meta:set_string("_is_fire_proof", "")
	end
	if legacy_bad_omen then
		EF.bad_omen[player] = legacy_bad_omen
		meta:set_string("_has_bad_omen", "")
	end
	if legacy_withering then
		EF.withering[player] = legacy_withering
		meta:set_string("_is_withering", "")
	end
	return old_lpe(player)
end


function mcl_potions.strength_func(object, factor, duration)
	return mcl_potions.give_effect("strength", object, factor, duration)
end
function mcl_potions.leaping_func(object, factor, duration)
	return mcl_potions.give_effect("leaping", object, factor, duration)
end
function mcl_potions.weakness_func(object, factor, duration)
	return mcl_potions.give_effect("weakness", object, factor, duration)
end
function mcl_potions.swiftness_func(object, factor, duration)
	return mcl_potions.give_effect("swiftness", object, factor, duration)
end
function mcl_potions.slowness_func(object, factor, duration)
	return mcl_potions.give_effect("slowness", object, factor, duration)
end

function mcl_potions.withering_func(object, factor, duration)
	return mcl_potions.give_effect("withering", object, factor, duration)
end

function mcl_potions.poison_func(object, factor, duration)
	return mcl_potions.give_effect("poison", object, factor, duration)
end

function mcl_potions.regeneration_func(object, factor, duration)
	return mcl_potions.give_effect("regeneration", object, factor, duration)
end

function mcl_potions.invisiblility_func(object, null, duration)
	return mcl_potions.give_effect("invisibility", object, null, duration)
end

function mcl_potions.water_breathing_func(object, null, duration)
	return mcl_potions.give_effect("water_breathing", object, null, duration)
end

function mcl_potions.fire_resistance_func(object, null, duration)
	return mcl_potions.give_effect("fire_resistance", object, null, duration)
end

function mcl_potions.night_vision_func(object, null, duration)
	return mcl_potions.give_effect("night_vision", object, null, duration)
end

function mcl_potions.bad_omen_func(object, factor, duration)
	mcl_potions.give_effect("bad_omen", object, factor, duration)
end
