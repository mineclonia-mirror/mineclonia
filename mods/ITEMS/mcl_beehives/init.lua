mcl_beehives = {}
local S = core.get_translator(core.get_current_modname())

-- Function to allow harvesting honey and honeycomb from the beehive and bee nest.
local function honey_harvest(pos, node, player, itemstack)
	local inv = player:get_inventory()
	local shears = core.get_item_group(player:get_wielded_item():get_name(), "shears") > 0
	local bottle = player:get_wielded_item():get_name() == "mcl_potions:glass_bottle"
	local original_block = "mcl_beehives:bee_nest"
	local is_creative = core.is_creative_enabled(player:get_player_name())
	if node.name == "mcl_beehives:beehive_5" then
		original_block = "mcl_beehives:beehive"
	end

	local campfire_area = vector.offset(pos, 0, -5, 0)
	local campfire = core.find_nodes_in_area(pos, campfire_area, "group:lit_campfire")

	if bottle or shears then
		local name = player:get_player_name()
		if core.is_protected(pos, name) then
			core.record_protection_violation(pos, name)
			return itemstack
		end
		if bottle then
			local honey = "mcl_honey:honey_bottle"
			if inv:room_for_item("main", honey) then
				inv:add_item("main", "mcl_honey:honey_bottle")
				if not is_creative then
					itemstack:take_item()
				end
				if campfire[1] then
					awards.unlock(player:get_player_name(), "mcl:bee_our_guest")
				end
			end
		else
			core.add_item(pos, "mcl_honey:honeycomb 3")
		end
		--TODO: damage type = "mob" since this is supposed to be done by bee mobs which aren't a thing yet
		--Once bees exist this branch should spawn them and/or make them aggro
		if not campfire[1] then
			mcl_beehives.release_bees(pos, nil, player)
		end
		node.name = original_block
		mcl_redstone.swap_node(pos, node)
	end
	return mcl_util.return_itemstack_if_alive(player, itemstack)
	-- returning the old itemstack here would result in it still being in hand *after* death
end

local function dig_hive(pos, node, oldmeta, digger)
	local wield_item = digger:get_wielded_item()
	local beehive = string.find(node.name, "mcl_beehives:beehive")
	local beenest = string.find(node.name, "mcl_beehives:bee_nest")
	local silk_touch = mcl_enchanting.has_enchantment(wield_item, "silk_touch")
	local is_creative = core.is_creative_enabled(digger:get_player_name())
	local inv = digger:get_inventory()

	if beehive then
		if not is_creative then
			if not silk_touch then
				mcl_beehives.release_bees(pos, tonumber(oldmeta.fields["mobs_mc:bees_present"]) or 0, digger)
			else
				core.add_item(pos, node.name)
			end
		elseif is_creative and inv:room_for_item("main", "mcl_beehives:beehive") and not inv:contains_item("main", "mcl_beehives:beehive") then
			inv:add_item("main", "mcl_beehives:beehive")
		end
	elseif beenest then
		if not is_creative then
			if silk_touch and wield_item:get_name() ~= "mcl_enchanting:book_enchanted" then
				awards.unlock(digger:get_player_name(), "mcl:total_beelocation")
				core.add_item(pos, node.name)
			else
				mcl_beehives.release_bees(pos, tonumber(oldmeta.fields["mobs_mc:bees_present"]) or 0, digger)
			end
		elseif is_creative and inv:room_for_item("main", "mcl_beehives:bee_nest") and not inv:contains_item("main", "mcl_beehives:bee_nest") then
			inv:add_item("main", "mcl_beehives:bee_nest")
		end
	end
end

local tpl_beehive = {
	description = S("Beehive"),
	_doc_items_longdesc = S("Artificial bee nest."),
	tiles = {
		"mcl_beehives_beehive_end.png", "mcl_beehives_beehive_end.png",
		"mcl_beehives_beehive_side.png", "mcl_beehives_beehive_side.png",
		"mcl_beehives_beehive_side.png", "mcl_beehives_beehive_front.png",
	},
	paramtype2 = "facedir",
	groups = { axey = 1, deco_block = 1, flammable = 0, fire_flammability = 5, material_wood = 1, beehive = 1, unmovable_by_piston = 1, comparator_signal = 0},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	_mcl_hardness = 0.6,
	_mcl_burntime = 15,
	_mcl_baseitem = "mcl_beehives:beehive",
	drop = "",
	after_dig_node = dig_hive,
	after_place_node = function(pos)
		local m = core.get_meta(pos)
		m:set_string("mcl_beehives:initialized", "true")
	end,
}

local tpl_bee_nest = table.merge(tpl_beehive, {
	description = S("Bee Nest"),
	_doc_items_longdesc = S("A naturally generating block that houses bees and a tasty treat...if you can get it."),
	tiles = {
		"mcl_beehives_bee_nest_top.png", "mcl_beehives_bee_nest_bottom.png",
		"mcl_beehives_bee_nest_side.png", "mcl_beehives_bee_nest_side.png",
		"mcl_beehives_bee_nest_side.png", "mcl_beehives_bee_nest_front.png",
	},
	groups = { axey = 1, deco_block = 1, flammable = 0, fire_flammability = 30, bee_nest = 1, comparator_signal = 0 },
	_mcl_hardness = 0.3,
	_mcl_baseitem = "mcl_beehives:bee_nest",
})

core.register_node("mcl_beehives:beehive", tpl_beehive)

for l = 1, 4 do
	local name = "mcl_beehives:beehive_" .. l
	core.register_node(name, table.merge(tpl_beehive, {
		groups = { axey = 1, deco_block = 1, flammable = 0, fire_flammability = 5, material_wood = 1, not_in_creative_inventory = 1, beehive = 1, honey_level = l, unmovable_by_piston = 1,  comparator_signal = l},
	}))
end

core.register_node("mcl_beehives:beehive_5", table.merge(tpl_beehive, {
	groups = { axey = 1, deco_block = 1, flammable = 0, fire_flammability = 5, material_wood = 1, not_in_creative_inventory = 1, beehive = 1, honey_level = 5, unmovable_by_piston = 1,  comparator_signal = 5},
	on_rightclick = honey_harvest,
	tiles = {
		"mcl_beehives_beehive_end.png", "mcl_beehives_beehive_end.png",
		"mcl_beehives_beehive_side.png", "mcl_beehives_beehive_side.png",
		"mcl_beehives_beehive_side.png", "mcl_beehives_beehive_front_honey.png",
	},
}))


core.register_node("mcl_beehives:bee_nest", tpl_bee_nest)

for i = 1, 4 do
	local name = "mcl_beehives:bee_nest_"..i
	core.register_node(name, table.merge(tpl_bee_nest, {
		groups = { axey = 1, deco_block = 1, flammable = 0, fire_flammability = 30, not_in_creative_inventory = 1, bee_nest = 1, honey_level = i, comparator_signal = i },
	}))
end

core.register_node("mcl_beehives:bee_nest_5", table.merge(tpl_bee_nest, {
	tiles = {
		"mcl_beehives_bee_nest_top.png", "mcl_beehives_bee_nest_bottom.png",
		"mcl_beehives_bee_nest_side.png", "mcl_beehives_bee_nest_side.png",
		"mcl_beehives_bee_nest_side.png", "mcl_beehives_bee_nest_front_honey.png",
	},
	groups = { axey = 1, deco_block = 1, flammable = 0, fire_flammability = 30, not_in_creative_inventory = 1, bee_nest = 1, honey_level = 5, comparator_signal = 5 },
	on_rightclick = honey_harvest,
}))

core.register_craft({
	output = "mcl_beehives:beehive",
	recipe = {
		{ "group:wood", "group:wood", "group:wood" },
		{ "mcl_honey:honeycomb", "mcl_honey:honeycomb", "mcl_honey:honeycomb" },
		{ "group:wood", "group:wood", "group:wood" },
	},
})

function mcl_beehives.add_level(pos, add_levels)
	local node = core.get_node(pos)
	local def = core.registered_nodes[node.name]
	if def and def._mcl_baseitem then
		local honey_level = core.get_item_group(node.name, "honey_level")
		honey_level = math.min(honey_level + add_levels, 5)
		node.name = def._mcl_baseitem.."_"..honey_level
		mcl_redstone.swap_node(vector.new(pos.x, pos.y, pos.z), node) --make sure mcl_redstone gets a proper vector
	end
end

function mcl_beehives.bees_should_sleep(pos)
	if mcl_worlds.pos_to_dimension(pos) ~= "overworld" then return false end

	if mcl_weather.get_weather() == "rain" then return true end

	local tod = core.get_timeofday() * 24000
	if tod < 6000 or tod > 18000 then return true end
	return false
end

local max_bees = 3

function mcl_beehives.release_bees(pos, bees, digger)
	local m = core.get_meta(pos)
	local bees_current = m:get_int("mobs_mc:bees_present")
	bees = bees or bees_current
	if bees > 0 then
		local node = core.get_node(pos)
		local front = vector.subtract(pos, core.facedir_to_dir(node.param2))
		if core.get_node(front).name =="air" then
			for i = 1, bees do
				if i > bees_current then break end
				local o = mcl_mobs.spawn(front, "mobs_mc:bee", core.serialize({_home = pos}))
				if digger and o then
					local l = o:get_luaentity()
					if l then
						l:do_attack(digger)
					end
				end
			end
			m:set_int("mobs_mc:bees_present", bees_current - bees)
		end
	end
end

core.register_abm({
	label = "Bees exist nest / Initialize Bee nests",
	nodenames = { "group:beehive", "group:bee_nest" },
	interval = 25,
	chance = 2,
	action = function(pos, _)
		local m = core.get_meta(pos)
		if m:get_string("mcl_beehives:initialized") == "" then
			m:set_int("mobs_mc:bees_present", max_bees)
			m:set_int("mobs_mc:bees", max_bees)
			m:set_string("mcl_beehives:initialized", "true")
		end

		if not mcl_beehives.bees_should_sleep(pos) then
			mcl_beehives.release_bees(pos, 1)
		end
	end,
})
