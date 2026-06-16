local S = core.get_translator("mcl_tools")

--Wood set
mcl_tools.register_set("wood", {
    craftable = true,
    material = "group:wood",
    uses = 60,
    level = 1,
    speed = 2,
    max_drop_level = 1,
    groups = { dig_speed_class = 2, enchantability = 15 }
}, {
    ["pick"] = {
        description = S("Wooden Pickaxe"),
        inventory_image = "default_tool_woodpick.png",
        tool_capabilities = {
            full_punch_interval = 0.83333333,
            damage_groups = { fleshy = 2 }
        }
    },
    ["shovel"] = {
        description = S("Wooden Shovel"),
        inventory_image = "default_tool_woodshovel.png",
        tool_capabilities = {
            full_punch_interval = 1,
            damage_groups = { fleshy = 2 }
        }
    },
    ["sword"] = {
        description = S("Wooden Sword"),
        inventory_image = "default_tool_woodsword.png",
        tool_capabilities = {
            full_punch_interval = 0.625,
            damage_groups = { fleshy = 4 }
        }
    },
    ["axe"] = {
        description = S("Wooden Axe"),
        inventory_image = "default_tool_woodaxe.png",
        tool_capabilities = {
            full_punch_interval = 1.25,
            damage_groups = { fleshy = 2 }
        }
    },
    ["spear"] = {
        description = S("Wooden Spear"),
        inventory_image = "mcl_tools_wooden_spear.png",
        wield_image = "mcl_tools_wooden_spear_wield.png",

		jab_cooldown = 0.65,
		jab_damage = 1,
		enchantability = 15,
		repair_material = "group:wood",

		uses = 59,
		charge_delay = 0.75,
		charge_minimum_dismount_speed = 14,
		engaged_phase_duration = 5,
		tired_phase_duration = 5,
		disengaged_phase_duration = 5,
		charge_damage_multiplier = 0.7
    }
}, { _doc_items_hidden = false, _mcl_burntime = 10 })

--Stone set
mcl_tools.register_set("stone", {
    craftable = true,
    material = "group:cobble",
    uses = 132,
    level = 3,
    speed = 4,
    max_drop_level = 3,
    groups = { dig_speed_class = 3, enchantability = 5 }
}, {
    ["pick"] = {
        description = S("Stone Pickaxe"),
        inventory_image = "default_tool_stonepick.png",
        tool_capabilities = {
            full_punch_interval = 0.83333333,
            damage_groups = { fleshy = 3 }
        }
    },
    ["shovel"] = {
        description = S("Stone Shovel"),
        inventory_image = "default_tool_stoneshovel.png",
        tool_capabilities = {
            full_punch_interval = 1,
            damage_groups = { fleshy = 3 }
        }
    },
    ["sword"] = {
        description = S("Stone Sword"),
        inventory_image = "default_tool_stonesword.png",
        tool_capabilities = {
            full_punch_interval = 0.625,
            damage_groups = { fleshy = 5 }
        }
    },
    ["axe"] = {
        description = S("Stone Axe"),
        inventory_image = "default_tool_stoneaxe.png",
        tool_capabilities = {
            full_punch_interval = 1.25,
            damage_groups = { fleshy = 9 }
        }
    },
    ["spear"] = {
        description = S("Stone Spear"),
        inventory_image = "mcl_tools_stone_spear.png",
        wield_image = "mcl_tools_stone_spear_wield.png",

		jab_cooldown = 0.75,
		jab_damage = 2,
		enchantability = 5,
		repair_material = "group:stone",

		uses = 131,
		charge_delay = 0.7,
		charge_minimum_dismount_speed = 10,
		engaged_phase_duration = 4.5,
		tired_phase_duration = 4.5,
		disengaged_phase_duration = 4.75,
		charge_damage_multiplier = 0.82
    }
})

--Copper set
mcl_tools.register_set("copper", {
        craftable = true,
        material = "mcl_copper:copper_ingot",
        uses = 191,
        level = 3,
        speed = 5,
        max_drop_level = 3,
        groups = { dig_speed_class = 3, enchantability = 13, blast_furnace_smeltable = 1 }
}, {
    ["pick"] = {
        description = S("Copper Pickaxe"),
        inventory_image = "mcl_copper_tool_pick.png",
        tool_capabilities = {
            full_punch_interval = 0.83333333,
            damage_groups = { fleshy = 3 }
        }
    },
    ["shovel"] = {
        description = S("Copper Shovel"),
        inventory_image = "mcl_copper_tool_shovel.png",
        tool_capabilities = {
            full_punch_interval = 1,
            damage_groups = { fleshy = 3 }
        }
    },
    ["sword"] = {
        description = S("Copper Sword"),
        inventory_image = "mcl_copper_tool_sword.png",
        tool_capabilities = {
            full_punch_interval = 0.625,
            damage_groups = { fleshy = 5 }
        }
    },
    ["axe"] = {
        description = S("Copper Axe"),
        inventory_image = "mcl_copper_tool_axe.png",
        tool_capabilities = {
            full_punch_interval = 1.25,
            damage_groups = { fleshy = 9 }
        },
    },
    ["spear"] = {
        description = S("Copper Spear"),
        inventory_image = "mcl_tools_copper_spear.png",
        wield_image = "mcl_tools_copper_spear_wield.png",

		jab_cooldown = 0.75,
		jab_damage = 2,
		enchantability = 5,
		repair_material = "mcl_copper:copper_ingot",

		uses = 131,
		charge_delay = 0.7,
		charge_minimum_dismount_speed = 10,
		engaged_phase_duration = 4.5,
		tired_phase_duration = 4.5,
		disengaged_phase_duration = 4.75,
		charge_damage_multiplier = 0.82
    }
}, {_mcl_cooking_output = "mcl_copper:copper_nugget"})

--Iron set
mcl_tools.register_set("iron", {
    craftable = true,
    material = "mcl_core:iron_ingot",
    uses = 251,
    level = 4,
    speed = 6,
    max_drop_level = 4,
    groups = { dig_speed_class = 4, enchantability = 14, blast_furnace_smeltable = 1 }
}, {
    ["pick"] = {
        description = S("Iron Pickaxe"),
        inventory_image = "default_tool_steelpick.png",
        tool_capabilities = {
            full_punch_interval = 0.83333333,
            damage_groups = { fleshy = 4 }
        }
    },
    ["shovel"] = {
        description = S("Iron Shovel"),
        inventory_image = "default_tool_steelshovel.png",
        tool_capabilities = {
            full_punch_interval = 1,
            damage_groups = { fleshy = 4 }
        }
    },
    ["sword"] = {
        description = S("Iron Sword"),
        inventory_image = "default_tool_steelsword.png",
        tool_capabilities = {
            full_punch_interval = 0.625,
            damage_groups = { fleshy = 6 }
        }
    },
    ["axe"] = {
        description = S("Iron Axe"),
        inventory_image = "default_tool_steelaxe.png",
        tool_capabilities = {
            full_punch_interval = 1.11111111,
            damage_groups = { fleshy = 9 }
        }
    },
    ["spear"] = {
        description = S("Iron Spear"),
        inventory_image = "mcl_tools_iron_spear.png",
        wield_image = "mcl_tools_iron_spear_wield.png",

		jab_cooldown = 0.95,
		jab_damage = 3,
		enchantability = 14,
		repair_material = "mcl_core:iron_ingot",

		uses = 250,
		charge_delay = 0.6,
		charge_minimum_dismount_speed = 8,
		engaged_phase_duration = 2.5,
		tired_phase_duration = 4.25,
		disengaged_phase_duration = 4.5,
		charge_damage_multiplier = 0.95
    }
}, { _mcl_cooking_output = "mcl_core:iron_nugget" })

--Gold set
mcl_tools.register_set("gold", {
    craftable = true,
    material = "mcl_core:gold_ingot",
    uses = 33,
    level = 2,
    speed = 12,
    max_drop_level = 2,
    groups = { dig_speed_class = 6, enchantability = 22, blast_furnace_smeltable = 1 }
}, {
    ["pick"] = {
        description = S("Golden Pickaxe"),
        inventory_image = "default_tool_goldpick.png",
        tool_capabilities = {
            full_punch_interval = 0.83333333,
            damage_groups = { fleshy = 2 }
        }
    },
    ["shovel"] = {
        description = S("Golden Shovel"),
        inventory_image = "default_tool_goldshovel.png",
        tool_capabilities = {
            full_punch_interval = 1,
            damage_groups = { fleshy = 2 }
        }
    },
    ["sword"] = {
        description = S("Golden Sword"),
        inventory_image = "default_tool_goldsword.png",
        tool_capabilities = {
            full_punch_interval = 0.625,
            damage_groups = { fleshy = 4 }
        }
    },
    ["axe"] = {
        description = S("Golden Axe"),
        inventory_image = "default_tool_goldaxe.png",
        tool_capabilities = {
            full_punch_interval = 1,
            damage_groups = { fleshy = 7 }
        }
    },
    ["spear"] = {
        description = S("Golden Spear"),
        inventory_image = "mcl_tools_golden_spear.png",
        wield_image = "mcl_tools_golden_spear_wield.png",

		jab_cooldown = 0.95,
		jab_damage = 1,
		enchantability = 22,
		repair_material = "mcl_core:gold_ingot",

		uses = 32,
		charge_delay = 0.7,
		charge_minimum_dismount_speed = 10,
		engaged_phase_duration = 3.5,
		tired_phase_duration = 5,
		disengaged_phase_duration = 5.25,
		charge_damage_multiplier = 0.7
    }
}, { _mcl_cooking_output = "mcl_core:gold_nugget" })

--Diamond set
mcl_tools.register_set("diamond", {
    craftable = true,
    material = "mcl_core:diamond",
    uses = 1562,
    level = 5,
    speed = 8,
    max_drop_level = 5,
    groups = { dig_speed_class = 5, enchantability = 10 }
}, {
    ["pick"] = {
        description = S("Diamond Pickaxe"),
        inventory_image = "default_tool_diamondpick.png",
        tool_capabilities = {
            full_punch_interval = 0.83333333,
            damage_groups = { fleshy = 5 }
        },
        _mcl_upgradable = true,
        _mcl_upgrade_item = "mcl_tools:pick_netherite"
    },
    ["shovel"] = {
        description = S("Diamond Shovel"),
        inventory_image = "default_tool_diamondshovel.png",
        tool_capabilities = {
            full_punch_interval = 1,
            damage_groups = { fleshy = 5 }
        },
        _mcl_upgradable = true,
        _mcl_upgrade_item = "mcl_tools:shovel_netherite"
    },
    ["sword"] = {
        description = S("Diamond Sword"),
        inventory_image = "default_tool_diamondsword.png",
        tool_capabilities = {
            full_punch_interval = 0.625,
            damage_groups = { fleshy = 7 }
        },
        _mcl_upgradable = true,
        _mcl_upgrade_item = "mcl_tools:sword_netherite"
    },
    ["axe"] = {
        description = S("Diamond Axe"),
        inventory_image = "default_tool_diamondaxe.png",
        tool_capabilities = {
            full_punch_interval = 1,
            damage_groups = { fleshy = 9 }
        },
        _mcl_upgradable = true,
        _mcl_upgrade_item = "mcl_tools:axe_netherite"
    },
    ["spear"] = {
        description = S("Diamond Spear"),
        inventory_image = "mcl_tools_diamond_spear.png",
        wield_image = "mcl_tools_diamond_spear_wield.png",

		jab_cooldown = 1.05,
		jab_damage = 4,
		enchantability = 10,
		repair_material = "mcl_core:diamond",

		uses = 1561,
		charge_delay = 0.5,
		charge_minimum_dismount_speed = 7.5,
		engaged_phase_duration = 3,
		tired_phase_duration = 3.25,
		disengaged_phase_duration = 3.5,
		charge_damage_multiplier = 1.075
    }
})

--Netherite set
mcl_tools.register_set("netherite", {
    craftable = false,
    material = "mcl_nether:netherite_ingot",
    uses = 2031,
    level = 6,
    speed = 9.5,
    max_drop_level = 5,
    groups = { dig_speed_class = 6, enchantability = 10, fire_immune = 1 }
}, {
    ["pick"] = {
        description = S("Netherite Pickaxe"),
        inventory_image = "default_tool_netheritepick.png",
        tool_capabilities = {
            full_punch_interval = 0.83333333,
            damage_groups = { fleshy = 6 }
        }
    },
    ["shovel"] = {
        description = S("Netherite Shovel"),
        inventory_image = "default_tool_netheriteshovel.png",
        tool_capabilities = {
            full_punch_interval = 1,
            damage_groups = { fleshy = 6 }
        }
    },
    ["sword"] = {
        description = S("Netherite Sword"),
        inventory_image = "default_tool_netheritesword.png",
        tool_capabilities = {
            full_punch_interval = 0.625,
            damage_groups = { fleshy = 9 }
        }
    },
    ["axe"] = {
        description = S("Netherite Axe"),
        inventory_image = "default_tool_netheriteaxe.png",
        tool_capabilities = {
            full_punch_interval = 1,
            damage_groups = { fleshy = 10 }
        }
    },
    ["spear"] = {
        description = S("Netherite Spear"),
        inventory_image = "mcl_tools_netherite_spear.png",
        wield_image = "mcl_tools_netherite_spear_wield.png",

		jab_cooldown = 1.15,
		jab_damage = 5,
		enchantability = 15,
		repair_material = "mcl_nether:netherite_ingot",

		uses = 2031,
		charge_delay = 0.4,
		charge_minimum_dismount_speed = 7,
		engaged_phase_duration = 2.5,
		tired_phase_duration = 3,
		disengaged_phase_duration = 3.25,
		charge_damage_multiplier = 1.2
    }
})
