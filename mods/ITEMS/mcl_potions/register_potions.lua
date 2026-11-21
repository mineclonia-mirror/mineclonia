local S = core.get_translator(core.get_current_modname())

mcl_potions.register_potion({
	name = "awkward",
	desc_prefix = "Awkward",
	_tt = S("No effect"),
	_longdesc = S("Has an awkward taste and is used for brewing potions."),
	color = "#8091ff",
})

mcl_potions.register_potion({
	name = "mundane",
	desc_prefix = "Mundane",
	_tt = S("No effect"),
	_longdesc = S("Has a terrible taste and is not really useful for brewing potions."),
	color = "#8091ff",
})

mcl_potions.register_potion({
	name = "thick",
	desc_prefix = "Thick",
	_tt = S("No effect"),
	_longdesc = S("Has a bitter taste and is not really useful for brewing potions."),
	color = "#8091ff",
})

mcl_potions.register_potion({
	name = "healing",
	desc_suffix = "of Healing",
	_dynamic_tt = function(level)
		return S("+@1 HP", 4 * level)
	end,
	_longdesc = S("Instantly heals."),
	color = "#f6493a",
	uses_level = true,
	has_arrow = true,
	custom_effect = function(object, level, _, user)
		return mcl_potions.healing_func(object, 4 * level, user)
	end,
})

mcl_potions.register_potion({
	name = "harming",
	desc_suffix = "of Harming",
	_dynamic_tt = function(level)
		return S("-@1 HP", 6 * level)
	end,
	_longdesc = S("Instantly deals damage."),
	color = "#a07669",
	uses_level = true,
	has_arrow = true,
	custom_effect = function(object, level, _, user)
		return mcl_potions.healing_func(object, -6 * level, user)
	end,
})

mcl_potions.register_potion({
	name = "night_vision",
	desc_suffix = "of Night Vision",
	_tt = nil,
	_longdesc = S("Increases the perceived brightness of light under a dark sky."),
	color = "#c8f356",
	_effect_list = {
		night_vision = {},
	},
	has_arrow = true,
})

mcl_potions.register_potion({
	name = "swiftness",
	desc_suffix = "of Swiftness",
	_tt = nil,
	_longdesc = S("Increases walking speed."),
	color = "#5ae9fe",
	_effect_list = {
		swiftness = {},
	},
	has_arrow = true,
})

mcl_potions.register_potion({
	name = "slowness",
	desc_suffix = "of Slowness",
	_tt = nil,
	_longdesc = S("Decreases walking speed."),
	color = "#8bb3de",
	_effect_list = {
		slowness = {dur=mcl_potions.DURATION_INV,
			-- Slowness IV should last 20 seconds.
			potent_factor = math.pow (4.5, 1/3),
		},
	},
	default_potent_level = 4,
	has_arrow = true,
})

mcl_potions.register_potion({
	name = "leaping",
	desc_suffix = "of Leaping",
	_tt = nil,
	_longdesc = S("Increases jump strength."),
	color = "#fafd8e",
	_effect_list = {
		leaping = {},
	},
	has_arrow = true,
})

mcl_potions.register_potion({
	name = "withering",
	desc_suffix = "of Decay",
	_tt = nil,
	_longdesc = S("Applies the withering effect which deals damage at a regular interval and can kill."),
	color = "#6d5c50",
	_effect_list = {
		withering = {dur=mcl_potions.DURATION_POISON},
	},
	has_arrow = true,
})

mcl_potions.register_potion({
	name = "poison",
	desc_suffix = "of Poison",
	_tt = nil,
	_longdesc = S("Applies the poison effect which deals damage at a regular interval."),
	color = "#86a25b",
	_effect_list = {
		poison = {dur=mcl_potions.DURATION_POISON},
	},
	has_arrow = true,
})

mcl_potions.register_potion({
	name = "regeneration",
	desc_suffix = "of Regeneration",
	_tt = nil,
	_longdesc = S("Regenerates health over time."),
	color = "#cb54ba",
	_effect_list = {
		regeneration = {dur=mcl_potions.DURATION_POISON},
	},
	has_arrow = true,
})

mcl_potions.register_potion({
	name = "invisibility",
	desc_suffix = "of Invisibility",
	_tt = nil,
	_longdesc = S("Grants invisibility."),
	color = "#f7fdfc",
	_effect_list = {
		invisibility = {},
	},
	has_arrow = true,
})

mcl_potions.register_potion({
	name = "water_breathing",
	desc_suffix = "of Water Breathing",
	_tt = nil,
	_longdesc = S("Grants limitless breath underwater."),
	color = "#98dac1",
	_effect_list = {
		water_breathing = {},
	},
	has_arrow = true,
})

mcl_potions.register_potion({
	name = "fire_resistance",
	desc_suffix = "of Fire Resistance",
	_tt = nil,
	_longdesc = S("Grants immunity to damage from heat sources like fire."),
	color = "#fd970e",
	_effect_list = {
		fire_resistance = {},
	},
	has_arrow = true,
})

mcl_potions.register_potion({
	name = "strength",
	desc_suffix = "of Strength",
	_tt = nil,
	_longdesc = S("Increases attack power."),
	color = "#f8c800",
	_effect_list = {
		strength = {},
	},
	has_arrow = true,
})

mcl_potions.register_potion({
	name = "weakness",
	desc_suffix = "of Weakness",
	_tt = nil,
	_longdesc = S("Decreases attack power."),
	color = "#4a4e49",
	_effect_list = {
		weakness = {},
	},
	has_arrow = true,
})

mcl_potions.register_potion({
	name = "slow_falling",
	desc_suffix = "of Slow Falling",
	_tt = nil,
	_longdesc = S("Instead of falling, you descend gracefully."),
	color = "#eed1ba",
	_effect_list = {
		slow_falling = {},
	},
	has_arrow = true,
})

mcl_potions.register_potion({
	name = "turtle_master",
	desc_suffix = "of the Turtle Master",
	_tt = nil,
	_longdesc = S("Decreases damage taken at the cost of speed."),
	color = "#8473dd",
	_effect_list = {
		resistance = {
			level = 3,
			dur = 20,
		},
		slowness = {
			level = 4,
			level_scaling = 2,
			dur = 20,
		},
	},
	has_arrow = true,
})

mcl_potions.register_potion({
	name = "luck",
	desc_suffix = "of Luck",
	_tt = nil,
	_longdesc = S("Increases luck."),
	color = "#59c500",
	_effect_list = {
		luck = {},
	},
	has_arrow = true,
})

mcl_potions.register_potion({
	name = "bad_luck",
	desc_suffix = "of Bad Luck",
	_tt = nil,
	_longdesc = S("Decreases luck."),
	color = "#c9aa56",
	_effect_list = {
		bad_luck = {},
	},
	has_arrow = true,
	nocreative = true,
})

mcl_potions.register_potion({
	name = "infestation",
	desc_suffix = "of Infestation",
	_tt = nil,
	_longdesc = S("Causes 1-3 silverfish to spawn with a 5% chance when damaged. It not applies to silverfishes."),
	color = "#899b8a",
	_effect_list = {infested = {}},
	has_arrow = true
})

mcl_potions.register_potion({
	name = "oozing",
	desc_suffix = "of Oozing",
	_tt = nil,
	_longdesc = S("Causes 2 medium slimes to spawn on death. It not applies to slimes."),
	color = "#a5fda9",
	_effect_list = {oozing = {}},
	has_arrow = true
})

mcl_potions.register_potion({
	name = "weaving",
	desc_suffix = "of Weaving",
	_tt = nil,
	_longdesc = S("Causes 2-3 cobwebs to appear on death. Also increases walking speed when crossing cobwebs."),
	color = "#75675a",
	_effect_list = {weaving = {}},
	has_arrow = true,
})

mcl_potions.register_potion({
	name = "wind_charged",
	desc_suffix = "of Wind Charging",
	_tt = nil,
	_longdesc = S("Causes A wind burst on death."),
	color = "#bcc8ff",
	_effect_list = {wind_charged = {}},
	has_arrow = true,
})
