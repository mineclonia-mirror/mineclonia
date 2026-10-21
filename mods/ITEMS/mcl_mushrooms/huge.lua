local S = core.get_translator(core.get_current_modname())

-- Convert a number to a string with 6 binary digits
local function to_binary(num)
	local binary = ""
	while (num > 0) do
		local remainder_binary = (num % 2) > 0 and 1 or 0
		binary = binary .. remainder_binary
		num = math.floor(num/2)
	end
	binary = string.reverse(binary)
	while (string.len(binary) < 6) do
		binary = "0" .. binary
	end
	return binary
end

local function replace_side(node, side)
	local bin = string.sub(node.name, -6)
	if string.sub(bin, side, side) == "1" then
		local new_bin
		if side == 1 then
			new_bin = "0" .. string.sub(bin, side+1, 6)
		elseif side == 6 then
			new_bin = string.sub(bin, 1, side-1) .. "0"
		else
			new_bin = string.sub(bin, 1, side-1) .. "0" .. string.sub(bin, side+1, 6)
		end
		return { name = string.sub(node.name, 1, -7) .. new_bin }
	end
end

local function get_tiles(bin, texture)
	local tiles = {}
	for t = 1, string.len(bin) do
		if string.sub(bin, t, t) == "1" then
			tiles[t] = texture
		else
			tiles[t] = "mcl_mushrooms_mushroom_block_inside.png"
		end
	end
	return tiles
end

local function register_mushroom_block(id, defs)
	local is_cap = defs.is_cap
	local doc_params = {}
	local groups = {
		handy = 1, axey = 1, material_wood = 1, flammable = -1,
		not_in_creative_inventory = 1, not_in_craft_guide = 1
	}
	for i = 0, 63 do
		local full_block_name = "mcl_mushrooms:"..id.."_111111"
		local bin = to_binary(i)
		local name = "mcl_mushrooms:"..id.."_"..bin
		if i == 63 then
			doc_params._doc_items_create_entry = true
			doc_params._doc_items_longdesc = defs.longdesc
			doc_params._doc_items_usagehelp = S("By placing huge mushroom blocks of the same species next to each other, the sides that touch each other will turn into pores permanently.")
			groups.building_block = 1
			groups.not_in_creative_inventory = 0
			groups.not_in_craft_guide = 0
			if not is_cap then
				groups.huge_mushroom_stem = 2
			end
		end
		if is_cap then
			groups.huge_mushroom_cap = i
			groups.compostability = 85
		else
			groups.huge_mushroom_stem = i == 63 and 2 or 1
			groups.compostability = 65
		end
		core.register_node(name, table.merge(doc_params, {
			description = defs.description,
			groups = table.merge(groups, defs.groups or {}),
			tiles = get_tiles(bin, defs.texture),
			drop = defs.drop,
			sounds = mcl_sounds.node_sound_wood_defaults(),
			_mcl_hardness = 0.2,
			_mcl_silk_touch_drop = {full_block_name},
			on_construct = function(pos)
				local sides = {
					{ { x= 0, y= 1, z= 0 }, 2 },
					{ { x= 0, y=-1, z= 0 }, 1 },
					{ { x= 1, y= 0, z= 0 }, 4 },
					{ { x=-1, y= 0, z= 0 }, 3 },
					{ { x= 0, y= 0, z= 1 }, 6 },
					{ { x= 0, y= 0, z=-1 }, 5 },
				}
				local node = core.get_node(pos)
				local node_name = node.name
				local species_self = core.get_item_group(node_name, "huge_mushroom")
				local node_update = table.copy(node)
				local is_cap = core.get_item_group(node_name, "huge_mushroom_cap") ~= 0
				local is_stem = core.get_item_group(node_name, "huge_mushroom_stem") ~= 0
				for i = 1, 6 do
					local neighbor = vector.add(pos, sides[i][1])
					local neighbor_node = core.get_node(neighbor)
					local neighbor_name = neighbor_node.name
					local neighbor_species = core.get_item_group(neighbor_name, "huge_mushroom")
					local same_species = neighbor_species == species_self
					local node_set = false
					if is_cap and same_species or is_stem and node_name == neighbor_name then
						local i2 = sides[i][2]
						local node_return = replace_side(node_update, i)
						if node_return then
							node_update = node_return
							node_set = true
						end
						local new_neighbor = replace_side(neighbor_node, i2)
						if new_neighbor then
							core.set_node(neighbor, new_neighbor)
						end
					end
					if node_set then
						core.set_node(pos, node_update)
					end
				end
			end,
		}))
		doc.add_entry_alias("noodes", full_block_name, "nodes", name)
	end
end

register_mushroom_block("mushroom_stem", {
	description = S("Mushroom Stem"),
	drop = "",
	texture = "mcl_mushrooms_mushroom_block_skin_stem.png"
})
register_mushroom_block("red_mushroom_block", {
	description = S("Red Mushroom Block"),
	drop = {
		items = {
			{ items = {"mcl_mushrooms:mushroom_red"}, rarity = 9 },
			{ items = {"mcl_mushrooms:mushroom_red 2"}, rarity = 9 },
		}
	},
	groups = {huge_mushroom = 1},
	is_cap = true,
	texture = "mcl_mushrooms_mushroom_block_skin_red.png"
})
register_mushroom_block("brown_mushroom_block", {
	description = S("Brown Mushroom Block"),
	drop = {
		items = {
			{ items = {"mcl_mushrooms:mushroom_brown"}, rarity = 9 },
			{ items = {"mcl_mushrooms:mushroom_brown 2"}, rarity = 9 },
		}
	},
	groups = {huge_mushroom = 2},
	is_cap = true,
	texture = "mcl_mushrooms_mushroom_block_skin_brown.png"
})
