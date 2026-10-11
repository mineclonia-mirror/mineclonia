local S = core.get_translator(core.get_current_modname())

local fourdirs = {
	[0] = vector.new(0, 0, 1),
	[1] = vector.new(1, 0, 0),
	[2] = vector.new(0, 0, -1),
	[3] = vector.new(-1, 0, 0),
}

function mcl_redstone.update_comparators(pos)
	for _, dir in pairs(fourdirs) do
		local pos2 = pos:add(dir)
		local node2 = core.get_node(pos2)

		if dir == core.fourdir_to_dir(node2.param2) and node2.name:find("mcl_comparators:comparator_") then
			mcl_redstone.update_node(pos2)
		elseif mcl_redstone._solid_opaque_tab[node2.name] then
			local pos3 = pos2:add(dir)
			local node3 = core.get_node(pos3)
			if dir == core.fourdir_to_dir(node3.param2) and node3.name:find("mcl_comparators:comparator_") then
				mcl_redstone.update_node(pos3)
			end
		end
	end
end

local measure_inventory = mcl_redstone.get_measure_container_function({"main"})
local measure_furnace = mcl_redstone.get_measure_container_function({"fuel", "src", "dst"})
local measure_brewing_stand = mcl_redstone.get_measure_container_function({"fuel", "input", "stand"})
local measure_double_chest_left = mcl_redstone.get_measure_double_chest_function("left")
local measure_double_chest_right = mcl_redstone.get_measure_double_chest_function("right")

local function measure_constant(power_level)
	return function()
		return power_level
	end
end

local function measure_lectern(pos)
	local meta = core.get_meta(pos)
	local pages = tonumber(meta:get_string("pages")) or 1
	local page = tonumber(meta:get_string("page")) or 1
	local power = 15
	if pages > 1 then
		-- formula copied from wiki
		power = math.floor((14 * (page - 1)) / (pages - 1) + 1)
	end
	return power
end

local function measure_jukebox(pos)
	local inv = core.get_inventory({type="node", pos=pos})
	local record = inv and inv:get_stack("main", 1)
	local def = record and mcl_jukebox.registered_records[record:get_name()]
	return def and def.comparator_signal or 0
end

local function measure_chiseled_bookshelf(pos)
	local meta = core.get_meta(pos)
	return math.floor(meta:get_float("last_slot_used") or 0)
end

local function measure_target(pos)
	return core.get_node(pos).param2
end

local function measure_item_frames(pos)
	local meta = core.get_meta(pos)
	if meta:get_inventory():get_stack("main", 1):get_name() ~= "" then
		return meta:get_int("mcl_item_rotation") + 1
	end
	return 0
end

-- measurable nodes mapped to their measuring function
local measure_tab = {
	["mcl_barrels:barrel_closed"] = measure_inventory,
	["mcl_barrels:barrel_open"] = measure_inventory,
	["mcl_chests:chest_small"] = measure_inventory,
	["mcl_chests:chest_left"] = measure_double_chest_left,
	["mcl_chests:chest_right"] = measure_double_chest_right,
	["mcl_chests:trapped_chest_small"] = measure_inventory,
	["mcl_chests:trapped_chest_left"] = measure_double_chest_left,
	["mcl_chests:trapped_chest_right"] = measure_double_chest_right,
	["mcl_chests:trapped_chest_on_small"] = measure_inventory,
	["mcl_chests:trapped_chest_on_left"] = measure_double_chest_left,
	["mcl_chests:trapped_chest_on_right"] = measure_double_chest_right,
	["mcl_dispensers:dispenser"] = measure_inventory,
	["mcl_dispensers:dispenser_down"] = measure_inventory,
	["mcl_dispensers:dispenser_up"] = measure_inventory,
	["mcl_dispensers:dropper"] = measure_inventory,
	["mcl_dispensers:dropper_down"] = measure_inventory,
	["mcl_dispensers:dropper_up"] = measure_inventory,
	["mcl_furnaces:furnace"] = measure_furnace,
	["mcl_blast_furnace:blast_furnace"] = measure_furnace,
	["mcl_smoker:smoker"] = measure_furnace,
	["mcl_hoppers:hopper"] = measure_inventory,
	["mcl_hoppers:hopper_disabled"] = measure_inventory,
	["mcl_hoppers:hopper_side"] = measure_inventory,
	["mcl_hoppers:hopper_side_disabled"] = measure_inventory,
	["mcl_itemframes:frame"] = measure_item_frames,
	["mcl_itemframes:glow_frame"] = measure_item_frames,
	["mcl_itemframes:invisible_frame"] = measure_item_frames,
	["mcl_itemframes:invisible_glow_frame"] = measure_item_frames,
	["mcl_jukebox:jukebox"] = measure_jukebox,
	["mcl_lectern:lectern_with_book"] = measure_lectern,
	["mcl_target:target_on"] = measure_target,
	--[[ initalized using after_mods_loaded
	["mcl_beds:respawn_anchor"] = measure_constant(comparator_signal),
	["mcl_beds:respawn_anchor_charged_xxx"] = measure_constant(comparator_signal),
	["mcl_beehives:beehive_xxx"] = measure_constant(comparator_signal),
	["mcl_beehives:bee_nest_xxx"] = measure_constant(comparator_signal),
	["mcl_books:chiseled_bookshelf_xxx"] = measure_chiseled_bookshelf,
	["mcl_brewing:stand_xxx"] = measure_brewing_stand,
	["mcl_cake:cake_x"] = measure_constant(comparator_signal),
	["mcl_cauldron:cauldron_xxx"] = measure_constant(comparator_signal),
	["mcl_chests:xxx_shulker_box"] = measure_inventory,
	["mcl_composters:composter_xxx"] = measure_constant(comparator_signal),
	["mcl_copper:bulb_xxx"] = measure_constant(comparator_signal),
	["mcl_portals:end_portal_frame_xxx"] = measure_constant(comparator_signal),
	]]
	-- TODO:
	--["command_block"] = measure_command_block,
	--["copper_golem"] = measure_golem,
	--["crafter"] = measure_crafter,
	--["creaking_heart"] = measure_creaking_heart,
	--["decorated_pot"] = measure_inventory,
	--["minecart_with_chest"] = measure_inventory,
	--["minecart_with_hopper"] = measure_inventory,
	--["sculc_sensor"] = measure_sculc_sensor,
	--["shelf"] = measure_shelf,
}

local function get_measure_function(def)
	local measure = def and def._mcl_redstone and def._mcl_redstone.comparator_readout
	return measure
end

-- compute tile depending on state and mode
local function get_tiles(state, mode)
	local top = "mcl_comparators_"..state..".png^"..
		"mcl_comparators_"..mode..".png"
	local sides = "mcl_comparators_sides_"..state..".png^"..
		"mcl_comparators_sides_"..mode..".png"
	local ends = "mcl_comparators_ends_"..state..".png^"..
		"mcl_comparators_ends_"..mode..".png"
	return {
		top, "mcl_stairs_stone_slab_top.png",
		sides, sides.."^[transformFX",
		ends, ends,
	}
end

local node_boxes = {
	comp = {
		{ -8/16, -8/16, -8/16,
		   8/16, -6/16,  8/16 },	-- the main slab
		{ -1/16, -6/16,  6/16,
		   1/16, -4/16,  4/16 },	-- front torch
		{ -4/16, -6/16, -5/16,
		  -2/16, -1/16, -3/16 },	-- left back torch
		{  2/16, -6/16, -5/16,
		   4/16, -1/16, -3/16 },	-- right back torch
	},
	sub = {
		{ -8/16, -8/16, -8/16,
		   8/16, -6/16,  8/16 },	-- the main slab
		{ -1/16, -6/16,  6/16,
		   1/16, -3/16,  4/16 },	-- front torch (active)
		{ -4/16, -6/16, -5/16,
		  -2/16, -1/16, -3/16 },	-- left back torch
		{  2/16, -6/16, -5/16,
		   4/16, -1/16, -3/16 },	-- right back torch
	},
}

local collision_box = {
	type = "fixed",
	fixed = { -8/16, -8/16, -8/16, 8/16, -6/16, 8/16 },
}

local groups = {
	dig_immediate = 3,
	dig_by_water  = 1,
	destroy_by_lava_flow = 1,
	dig_by_piston = 1,
	unsticky = 1,
	attached_node = 1,
	redstone_comparator = 1,
}

for _, mode in pairs{"comp", "sub"} do
	for _, state in pairs{"on", "off"} do
		local nodename = "mcl_comparators:comparator_"..state.."_"..mode

		local longdesc, usagehelp, use_help
		if state == "off" and mode == "comp" then
			longdesc = S("Redstone comparators are multi-purpose redstone components.").."\n"..
			S("They can transmit a redstone signal, detect whether a block contains any items and compare multiple signals.")

			usagehelp = S("A redstone comparator has 1 main input, 2 side inputs and 1 output. The output is in arrow direction, the main input is in the opposite direction. The other 2 sides are the side inputs.").."\n"..
				S("The main input can powered in 2 ways: First, it can be powered directly by redstone power like any other component. Second, it is powered if, and only if a container (like a chest) is placed in front of it and the container contains at least one item.").."\n"..
				S("The side inputs are only powered by normal redstone power. The redstone comparator can operate in two modes: Transmission mode and subtraction mode. It starts in transmission mode and the mode can be changed by using the block.").."\n\n"..
				S("Transmission mode:\nThe front torch is unlit and lowered. The output is powered if, and only if the main input is powered. The two side inputs are ignored.").."\n"..
				S("Subtraction mode:\nThe front torch is lit. The output is powered if, and only if the main input is powered and none of the side inputs is powered.")
		else
			use_help = false
		end

		local nodedef = {
			description = S("Redstone Comparator"),
			_doc_items_create_entry = use_help,
			_doc_items_longdesc = longdesc,
			_doc_items_usagehelp = usagehelp,
			drawtype = "nodebox",
			tiles = get_tiles(state, mode),
			walkable = false, -- Workaround until https://github.com/luanti-org/luanti/issues/16432 is resolved
			selection_box = collision_box,
			collision_box = collision_box,
			node_box = {
				type = "fixed",
				fixed = node_boxes[mode],
			},
			groups = groups,
			paramtype = "light",
			paramtype2 = "4dir",
			sunlight_propagates = false,
			is_ground_content = false,
			drop = "mcl_comparators:comparator_off_comp",
			on_rightclick = function (pos, node, clicker)
				local protname = clicker:get_player_name()
				if core.is_protected(pos, protname) then
					core.record_protection_violation(pos, protname)
					return
				end
				local newmode = mode == "comp" and "sub" or "comp"
				core.set_node(pos, {
					name = "mcl_comparators:comparator_"..state.."_"..newmode,
					param2 = node.param2,
				})
			end,
			sounds = mcl_sounds.node_sound_stone_defaults(),
			on_rotate = screwdriver.disallow,
			_mcl_redstone = {
				connects_to = function(node, dir)
					return true
				end,
				get_power = function(node, dir)
					local fourdir = core.dir_to_fourdir(dir)
					if not fourdir or dir.y ~= 0 then
						return 0
					end
					return node.param2 % 4 == fourdir and math.floor(node.param2 / 4) or 0, true
				end,
				update = function(pos, node)
					local back = -core.fourdir_to_dir(node.param2)
					local left = core.fourdir_to_dir((node.param2 - 1) % 4)
					local right = core.fourdir_to_dir((node.param2 + 1) % 4)
					-- side input does not accept power from opaque nodes
					local side_power = math.max(
						mcl_redstone.get_power(pos, left, "direct"),
						mcl_redstone.get_power(pos, right, "direct")
					)
					local rear_power
					-- first check whether the node in the back pos is measurable
					local pos2 = vector.add(pos, back)
					local node2 = core.get_node(pos2)
					local def2 = core.registered_nodes[node2.name]
					local measure = get_measure_function(def2)
					if measure then
						rear_power = measure(pos2, node2)
					else
						-- Rear input does accept power from opaque nodes, but
						-- ignores it in preference of a measurable node (behind
						-- the opaque node). Java edition makes an exception if
						-- the power level is 15, we do not do so because we
						-- mainly target bedrock.
						if def2 and def2.groups and def2.groups.opaque and (def2.groups.opaque ~= 0) then
							local pos3 = vector.add(pos2, back)
							local node3 = core.get_node(pos3)
							local def3 = core.registered_nodes[node3.name]
							local measure = get_measure_function(def3)
							if measure then
								rear_power = measure(pos3, node3)
							end
						end
					end
					rear_power = rear_power or mcl_redstone.get_power(pos, back)
					if rear_power < 0 or rear_power > 15 then
						core.log("warning", string.format(
							"Comparator at %s received illegal rear value %s!",
							core.pos_to_string(pos), tostring(rear_power)
						))
						rear_power = math.max(0, math.min(15, rear_power))
					end
					local output
					if mode == "comp" then
						output = rear_power >= side_power and rear_power or 0
					else
						output = math.max(rear_power - side_power, 0)
					end

					local newstate = output > 0 and "on" or "off"
					return {
						name = "mcl_comparators:comparator_"..newstate.."_"..mode,
						param2 = 4 * output + node.param2 % 4,
					}
				end,
			},
		}

		if mode == "comp" and state == "off" then
			nodedef._doc_items_create_entry = true
			nodedef.inventory_image = "mcl_comparators_item.png"
			nodedef.wield_image = "mcl_comparators_item.png"
		else
			nodedef.groups = table.copy(nodedef.groups)
			nodedef.groups.not_in_creative_inventory = 1
			if mode == "sub" or state == "on" then
				nodedef.inventory_image = nil
			end
			local desc = nodedef.description
			if mode ~= "sub" and state == "on" then
				desc = S("Redstone Comparator (Powered)")
			elseif mode == "sub" and state ~= "on" then
				desc = S("Redstone Comparator (Subtract)")
			elseif mode == "sub" and state == "on" then
				desc = S("Redstone Comparator (Subtract, Powered)")
			end
			nodedef.description = desc

			doc.add_entry_alias("nodes", "mcl_comparators:comparator_"..state.."_"..mode, "nodes", nodename)
		end

		core.register_node(nodename, nodedef)
	end
end

core.register_craft({
	output = "mcl_comparators:comparator_off_comp",
	recipe = {
		{ "",      "mcl_redstone_torch:redstone_torch_on", ""      },
		{ "mcl_redstone_torch:redstone_torch_on", "mcl_nether:quartz",  "mcl_redstone_torch:redstone_torch_on" },
		{ "mcl_core:stone",   "mcl_core:stone",   "mcl_core:stone"   },
	}
})

local function check_for_update(pos, node)
	local def = core.registered_nodes[node.name]
	if get_measure_function(def) then
		mcl_redstone.update_comparators(pos)
	end
	-- double chest support
	local other_pos
	local container_type = core.get_item_group(node.name, "container")
	if container_type == 5 then
		other_pos = mcl_util.get_double_container_neighbor_pos(pos, node.param2, "left")
	elseif container_type == 6 then
		other_pos = mcl_util.get_double_container_neighbor_pos(pos, node.param2, "right")
	end
	if other_pos then
		mcl_redstone.update_comparators(other_pos)
	end
end

core.register_on_dignode(function (pos, node)
	check_for_update(pos, node)
end)

core.register_on_placenode(function (pos, newnode, _, oldnode)
	local olddef = core.registered_nodes[oldnode.name]
	local newdef = core.registered_nodes[newnode.name]
	if get_measure_function(newdef) or get_measure_function(olddef) then
		mcl_redstone.update_comparators(pos)
	end
end)

mcl_pistons.register_on_move(function(moved_nodes)
	for i = 1, #moved_nodes do
		local moved_node = moved_nodes[i]
		check_for_update(moved_node.old_pos, moved_node.node)
		check_for_update(moved_node.pos, moved_node.node)
	end
end)

core.register_on_mods_loaded(function()
	local measureable_nodes = {}
	for name, def in pairs(core.registered_nodes) do
		if get_measure_function(def) then
			table.insert(measureable_nodes, name)
		end
	end
	mcl_redstone.register_action(mcl_redstone.update_comparators, measureable_nodes)
end)
