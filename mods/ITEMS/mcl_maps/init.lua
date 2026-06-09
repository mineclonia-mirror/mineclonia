mcl_maps = {}

local pairs = pairs
local ipairs = ipairs

local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
local S = core.get_translator(modname)

local storage = core.get_mod_storage()
local worldpath = core.get_worldpath()
local map_textures_path = worldpath .. "/mcl_maps/"
--local last_finished_id = storage:get_int("next_id") - 1

core.mkdir(map_textures_path)

local function load_json_file(name)
	local file = assert(io.open(modpath .. "/" .. name .. ".json", "r"))
	local data = core.parse_json(file:read("*all"))
	file:close()
	return data
end

local texture_colors = load_json_file("colors")

local creating_maps = {}
local loaded_maps = {}

local c_air = core.get_content_id("air")

function mcl_maps.create_map(pos)
	local minp = vector.multiply(vector.floor(vector.divide(pos, 128)), 128)
	local maxp = vector.add(minp, vector.new(127, 127, 127))

	local itemstack = ItemStack("mcl_maps:filled_map")
	local meta = itemstack:get_meta()
	local next_id = storage:get_int("next_id")
	storage:set_int("next_id", next_id + 1)
	local id = tostring(next_id)
	meta:set_string("mcl_maps:id", id)
	meta:set_string("mcl_maps:minp", core.pos_to_string(minp))
	meta:set_string("mcl_maps:maxp", core.pos_to_string(maxp))
	meta:set_int("date", os.time())
	tt.reload_itemstack_description(itemstack)

	creating_maps[id] = true
	core.emerge_area(minp, maxp, function(_, _, calls_remaining)
		if calls_remaining > 0 then
			return
		end
		local vm = core.get_voxel_manip()
		local emin, emax = vm:read_from_map(minp, maxp)
		local data = vm:get_data()
		local param2data = vm:get_param2_data()
		local area = VoxelArea:new({ MinEdge = emin, MaxEdge = emax })
		local pixels = {}
		for x = 1, 128 do
			local map_x = minp.x - 1 + x
			local last_height
			for z = 1, 128 do
				local map_z = minp.z - 1 + z
				local cagg, alpha, height = { 0, 0, 0 }, 0
				for map_y = maxp.y, minp.y, -1 do
					local index = area:index(map_x, map_y, map_z)
					local c_id = data[index]
					if c_id ~= c_air then
						local color = texture_colors[minetest.get_name_from_content_id(c_id)]
						-- use param2 if available:
						if color and type(color[1]) == "table" then
							color = color[param2data[index] + 1] or color[1]
						end
						if color then
							-- <https://www.w3.org/TR/png-3/#13Alpha-channel-processing>
							local a = (color[4] or 255) / 255
							local f = a * (1 - alpha)
							cagg[1] = cagg[1] + f * color[1]
							cagg[2] = cagg[2] + f * color[2]
							cagg[3] = cagg[3] + f * color[3]
							alpha = alpha + f

							-- ground estimate with transparent blocks
							if alpha > 0.70 and not height then height = map_y end
							-- adjust color to give a 3d effect
							if alpha >= 0.99 and last_height and height then
								local dheight = math.min(math.max((height - last_height) * 8, -32), 32)
								cagg = {
									math.max(0, math.min(255, cagg[1] + dheight)),
									math.max(0, math.min(255, cagg[2] + dheight)),
									math.max(0, math.min(255, cagg[3] + dheight)),
								}
							end
							if alpha >= 0.99 then break end
						end
					end
				end
				last_height = height
				pixels[z] = pixels[z] or {}
				pixels[z][x] = cagg or { 0, 0, 0 }
			end
		end
		tga_encoder.image(pixels):save(map_textures_path .. "mcl_maps_map_texture_" .. id .. ".tga", { compression = "RLE", color_format = "A1R5G5B5", })
		creating_maps[id] = nil
	end)
	return itemstack
end

function mcl_maps.load_map(id, callback)
	if not id or id == "" or creating_maps[id] then
		return false
	end

	local texture = "mcl_maps_map_texture_" .. id .. ".tga"

	local result = true

	if not loaded_maps[id] then
		if not core.features.dynamic_add_media_table then
			-- core.dynamic_add_media() blocks in
			-- Minetest 5.3 and 5.4 until media loads
			loaded_maps[id] = true
			result = core.dynamic_add_media(map_textures_path .. texture, function()
			end)
			if callback then
				callback(texture)
			end
		else
			-- core.dynamic_add_media() never blocks
			-- in Minetest 5.5, callback runs after load
			result = core.dynamic_add_media(map_textures_path .. texture, function()
				loaded_maps[id] = true
				if callback then
					callback(texture)
				end
			end)
		end
	end

	if result == false then
		return false
	end

	if loaded_maps[id] then
		if callback then
			callback(texture)
		end
		return texture
	end
end

local function fill_map(itemstack, placer, pointed_thing)
	local new_stack = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
	if new_stack then
		return new_stack
	end

	if core.settings:get_bool("enable_real_maps", true) then
		local new_map = mcl_maps.create_map(placer:get_pos())
		itemstack:take_item()
		if itemstack:is_empty() then
			return new_map
		else
			local inv = placer:get_inventory()
			if inv:room_for_item("main", new_map) then
				inv:add_item("main", new_map)
			else
				core.add_item(placer:get_pos(), new_map)
			end
			return itemstack
		end
	end
end

core.register_craftitem("mcl_maps:empty_map", {
	description = S("Empty Map"),
	_doc_items_longdesc = S("Empty maps are not useful as maps, but they can be stacked and turned to maps which can be used."),
	_doc_items_usagehelp = S("Rightclick to create a filled map (which can't be stacked anymore)."),
	inventory_image = "mcl_maps_map_empty.png",
	on_place = fill_map,
	on_secondary_use = fill_map,
})

local filled_def = {
	description = S("Map"),
	_tt_help = S("Shows a map image."),
	_doc_items_longdesc = S("When created, the map saves the nearby area as an image that can be viewed any time by holding the map."),
	_doc_items_usagehelp = S("Hold the map in your hand. This will display a map on your screen."),
	inventory_image = "mcl_maps_map_filled.png^(mcl_maps_map_filled_markings.png^[colorize:#000000)",
	groups = { not_in_creative_inventory = 1, filled_map = 1, tool = 1 },
}

core.register_craftitem("mcl_maps:filled_map", filled_def)

tt.register_priority_snippet(function(itemstring, _, itemstack)
	if itemstack and core.get_item_group(itemstring, "filled_map") > 0 then
		local id = itemstack:get_meta():get_string("mcl_maps:id")
		if id ~= "" then
			return "#" .. id, mcl_colors.GRAY
		end
	end
end)

core.register_craft({
	output = "mcl_maps:empty_map",
	recipe = {
		{ "mcl_core:paper", "mcl_core:paper", "mcl_core:paper" },
		{ "mcl_core:paper", "mcl_compass:compass", "mcl_core:paper" },
		{ "mcl_core:paper", "mcl_core:paper", "mcl_core:paper" },
	}
})

core.register_craft({
	type = "shapeless",
	output = "mcl_maps:filled_map 2",
	recipe = { "group:filled_map", "mcl_maps:empty_map" },
})

local function on_craft(itemstack, _, old_craft_grid, _)
	if itemstack:get_name() == "mcl_maps:filled_map" then
		for _, stack in pairs(old_craft_grid) do
			if core.get_item_group(stack:get_name(), "filled_map") > 0 then
				itemstack:get_meta():from_table(stack:get_meta():to_table())
				return itemstack
			end
		end
	end
end

core.register_on_craft(on_craft)
core.register_craft_predict(on_craft)

------------------------------------------------------------------------
-- Dynamically updated maps.
-- TODO:
--
--   [X] Map items and grids.
--   [X] Map HUDs.
--   [X] Dimension information.
--   [X] Dynamic map updates.
--   [X] Circular map filling.
--   [ ] Cartography tables.
--   [ ] Treasure maps & biome reliefs.
--   [ ] Item frame support.
------------------------------------------------------------------------

local map_colors_by_cid = {}

local rshift = bit.rshift
local lshift = bit.lshift
local arshift = bit.arshift

local bnot = bit.bnot
local band = bit.band
local bor = bit.bor

local mathmax = math.max
local mathmin = math.min
local mathcos = math.cos
local mathsqrt = math.sqrt
local mathabs = math.abs

local pi = math.pi

local floor = math.floor
local ceil = math.ceil

local function encode_rgb (r, g, b)
	return bor (0xff000000, lshift (r, 16),
		    lshift (g, 8), b)
end

core.register_on_mods_loaded (function ()
	for i = 0, 65535 do
		map_colors_by_cid[i] = nil
	end
	for k, v in pairs (texture_colors) do
		local ok, cid = pcall (core.get_content_id, k)
		if not ok then
			core.log ("warning", string.format ("[mcl_maps]: colors.json contains unknown node `%s'.", k))
		elseif type (v[1]) == "table" then
			local by_param2 = {}
			for i = 0, 255 do
				by_param2[i] = 0
			end
			for i, color in ipairs (v) do
				local color = encode_rgb (color[1],
							  color[2],
							  color[3])
				by_param2[i - 1] = color
			end
			map_colors_by_cid[cid] = by_param2
		else
			map_colors_by_cid[cid] = encode_rgb (v[1], v[2], v[3])
		end
	end
end)

local formspec_escapes = {
	["\\"] = "\\\\",
	["^"] = "\\^",
	[":"] = "\\:",
}

local function modifier_escape (text)
	return string.gsub (text, "[\\^:]", formspec_escapes)
end

local MAP_UPDATE_AREA = 128
local MAP_UPDATE_AREA_Y = 96
local MAP_SIDE_LENGTH = 130
local MAP_DATA_LENGTH = MAP_SIDE_LENGTH - 2

local cid_ignore = core.CONTENT_IGNORE
local map_get_node_raw = core.get_node_raw

local function get_rgb (cid, param2)
	local color_or_list = map_colors_by_cid[cid]
	if type (color_or_list) == "number" then
		return color_or_list
	elseif color_or_list then
		return color_or_list[param2]
	end

	return nil
end

local function scan_heightmap (current_height, x, z, y1, y2)
	if y2 >= current_height then
		for y = y2, y1, -1 do
			local cid, _, _ = map_get_node_raw (x, y, z)
			if map_colors_by_cid[cid] then
				return y
			end

			-- If the map is unloaded here at or beneath
			-- the currently known height, and no solid
			-- node has yet been encountered, consider the
			-- column to end at the unloaded position.
			if y <= current_height and cid == cid_ignore then
				return y
			end
		end
	end
	return current_height
end

local function produce_heightmap_turn_1 (map, x1, y1, z1, base, i_start, i_end)
	local scale = map.scale - 1
	local x_start = map.x_start
	local z_start = map.z_start + lshift (z1, scale)
	local heightmap = map.heightmap

	for i = i_start, i_end do
		local current = heightmap[base + i]
		heightmap[base + i]
			= scan_heightmap (current, x_start + lshift (i - 1, scale),
					  z_start, y1, y1 + MAP_UPDATE_AREA_Y - 1)
	end
end

local LIGHT_DIR = 1.0 / mathsqrt (3.0)

local function produce_rgb_turn (map, x1, z1, base_first, base,
				 base_next, i_start, i_end)
	local scale = map.scale - 1
	local x_start = map.x_start
	local z_start = map.z_start + lshift (z1, scale)
	local heightmap = map.heightmap
	local data = map.data

	for i = i_start, i_end do
		local current = heightmap[base + i]
		local cid, _, param2
			= map_get_node_raw (x_start + lshift (i - 1, scale),
					    current, z_start)
		local rgb = get_rgb (cid, param2)
		if rgb then
			-- Central differencing.
			local t = heightmap[base_next + i]
			local b = heightmap[base_first + i]
			local r = heightmap[base + i + 1]
			local l = heightmap[base + i - 1]

			-- Slope at point.
			local x = 2 * (r - l)
			local y = 2 * (t - b)
			local z = -4

			-- Dot product with light vector.  (|a| cos (t))
			local p = mathabs (x * -LIGHT_DIR + y * LIGHT_DIR + z * LIGHT_DIR)

			-- Relief value.
			local f = p * 1 / mathsqrt (x * x + y * y + z * z)
			local r = 64 + floor (96.0 * f + 96.0)

			-- Apply relief.
			local c1 = band (rshift (band (rgb, 0x00ff00ff) * r, 8),
					 0x00ff00ff)
			local c2 = band (rshift (band (rgb, 0x0000ff00) * r, 8),
					 0x0000ff00)
			data[base + i] = bor (0xff000000, c1, c2)
		end
	end
end

local function prepare_map_heights (map, y1)
	for turn = 0, MAP_SIDE_LENGTH - 1 do
		local idx = turn * MAP_SIDE_LENGTH + 1
		produce_heightmap_turn_1 (map, -1, y1, turn - 1, idx, 0,
					  MAP_SIDE_LENGTH - 1)
	end
end

local function produce_heightmap_turn (map, x1, y1, z1, n)
	local idx = (z1 + 1) * MAP_SIDE_LENGTH + 1
	produce_heightmap_turn_1 (map, x1 - 1, y1, z1, idx, x1, x1 + n)	
end

local function produce_map_turn (map, x1, y1, z1, n)
	-- Each index addresses a row of MAP_SIDE_LENGTH elements in
	-- DATA and HEIGHTMAP representing the maximum recorded height
	-- and the current value of the map at that row.
	local turn = z1 + 1
	local idx_first = (turn - 1) * MAP_SIDE_LENGTH + 1
	local idx_turn = turn * MAP_SIDE_LENGTH + 1
	local idx_next = (turn + 1) * MAP_SIDE_LENGTH + 1
	local i_start, i_end
		= x1 + 1, mathmin (x1 + n - 1, MAP_DATA_LENGTH)
	produce_rgb_turn (map, x1, z1, idx_first, idx_turn,
			  idx_next, i_start, i_end)
end

local function alloc_map_data ()
	local tbl = {}
	for i = 1, MAP_SIDE_LENGTH * MAP_SIDE_LENGTH do
		tbl[i] = 0x0
	end
	return tbl
end

local function alloc_heightmap_data ()
	local tbl = {}
	for i = 1, MAP_SIDE_LENGTH * MAP_SIDE_LENGTH do
		tbl[i] = -32767
	end
	return tbl
end

local function convert_map_data (dst, map)
	local i = 0
	local data = map.data
	for z = MAP_DATA_LENGTH - 1, 0, -1 do
		for x = 0, MAP_DATA_LENGTH - 1 do
			i = i + 1
			dst[i] = data[(z + 1) * MAP_SIDE_LENGTH + x + 2]
		end
	end
end

local v1 = vector.new ()
local v2 = vector.new ()
local vm_y1
local vm, area, cids, param2 = nil, nil, {}, {}

local function vm_get_node_raw (x, y, z)
	-- X Y and Z are otherwise guaranteed to exist within the VM.
	if y > vm_y1 then
		local idx = area:index (x, y, z)
		return cids[idx], 0, param2[idx]
	end
	return cid_ignore, 0, 0
end

local function prepare_map_generation_vm (map, y1)
	map_get_node_raw = vm_get_node_raw
	v1.x = map.x_start - map.scale
	v1.y = y1
	vm_y1 = y1
	v1.z = map.z_start - map.scale
	v2.x = map.x_start + (MAP_UPDATE_AREA + 1) * map.scale
	v2.y = y1 + MAP_UPDATE_AREA_Y - 1
	v2.z = map.z_start + (MAP_UPDATE_AREA + 1) * map.scale
	if vm then
		vm:close ()
	end
	vm = VoxelManip (v1, v2)
	vm:get_data (cids)
	vm:get_param2_data (param2)
	area = VoxelArea (vm:get_emerged_area ())
end

local function prepare_map_generation ()
	map_get_node_raw = core.get_node_raw
	if vm then
		vm:close ()
		vm = nil
	end
end

local converted_data = {}

local function encode_map_png (map)
	convert_map_data (converted_data, map)
	return core.encode_png (MAP_DATA_LENGTH,
				MAP_DATA_LENGTH,
				converted_data, 9)
end

function mcl_maps.produce_map_test (player_name, scale)
	local player = core.get_player_by_name (player_name)
	if player then
		local pos = mcl_util.get_nodepos (player:get_pos ())
		local map = {
			x_start = pos.x - 64 * (scale or 1),
			z_start = pos.z - 64 * (scale or 1),
			scale = scale or 1,
			data = alloc_map_data (),
			heightmap = alloc_heightmap_data (),
		}
		local y1 = pos.y - floor (MAP_UPDATE_AREA_Y / 2)
		-- local clock = core.get_us_time ()
		prepare_map_generation_vm (map, y1)
		-- local tm_1 = core.get_us_time () - clock;
		prepare_map_heights (map, y1)
		-- print (tm_1, core.get_us_time () - clock - tm_1)
		for i = 0, MAP_DATA_LENGTH - 1 do
			produce_map_turn (map, 0, y1, i, MAP_DATA_LENGTH)
		end
		local png = encode_map_png (map)
		local worldpath = core.get_worldpath ()
		local file = worldpath .. "/" .. os.date ("map_%Y%m%d%H%M%S.png")
		core.safe_file_write (file, png)
		return map
	end
end

------------------------------------------------------------------------
-- Map management and serialization.
------------------------------------------------------------------------

local MAP_TTL = 20
local loaded_maps = {}
local update_all_maps

local function image_name (id)
	return map_textures_path .. id .. ".bin"
end

local function map_name (id)
	return map_textures_path .. id .. ".lua"
end

local function allocate_map_id ()
	local base = os.date ("map_%Y%m%d%H%M%S_")
	local i = 0
	while core.path_exists (map_name (base .. i)) do
		i = i + 1
	end

	local image_name = image_name (base .. i)
	local map_name = map_name (base .. i)
	return base .. i, image_name, map_name
end

local function serialize_data (dst, list, off)
	assert (#list == MAP_SIDE_LENGTH * MAP_SIDE_LENGTH)
	for i = 1, #list do
		local value = list[i]
		local b0 = band (value, 0xff)
		local b1 = rshift (band (value, 0xff00), 8)
		local b2 = rshift (band (value, 0xff0000), 16)
		local b3 = rshift (band (value, 0xff000000), 24)
		dst[off + i * 4 - 3] = string.char (b0)
		dst[off + i * 4 - 2] = string.char (b1)
		dst[off + i * 4 - 1] = string.char (b2)
		dst[off + i * 4] = string.char (b3)
	end
end

local function write_map_data (id, map)
	local tbl = {
		x_start = map.x_start,
		z_start = map.z_start,
		dimension = map.dimension or "overworld",
		scale = map.scale,
	}
	local str = core.serialize (tbl)
	local bin = {}
	serialize_data (bin, map.data, 0)
	serialize_data (bin, map.heightmap, #bin)
	local image = table.concat (bin)
	local compressed = core.compress (image, "deflate", 9)

	local rc = core.safe_file_write (map_name (id), str)
	if not rc then
		error ("Could not write map metadata for " .. id)
	end

	local rc = core.safe_file_write (image_name (id), compressed)
	if not rc then
		error ("Could not write map data for " .. id)
	end
end

local function deserialize_data (dst, str, offset)
	for i = 1, MAP_SIDE_LENGTH * MAP_SIDE_LENGTH do
		local b0 = string.byte (str, i * 4 - 3 + offset)
		local b1 = string.byte (str, i * 4 - 2 + offset)
		local b2 = string.byte (str, i * 4 - 1 + offset)
		local b3 = string.byte (str, i * 4 + offset)
		dst[i] = bor (b0, lshift (b1, 8), lshift (b2, 16),
			      lshift (b3, 24))
	end
end

local function load_map_1 (id)
	local file = assert (io.open (map_name (id), "r"))
	local data = file:read ("*all")
	file:close ()

	local map = core.deserialize (data)
	assert (type (map) == "table")
	if not map.dimension then
		map.dimension = "overworld"
	end
	assert (type (map.scale) == "number" and floor (map.scale) == map.scale)
	assert (type (map.x_start) == "number"
		and floor (map.x_start) == map.x_start)
	assert (type (map.z_start) == "number"
		and floor (map.z_start) == map.z_start)
	assert (type (map.dimension) == "string")

	local file = assert (io.open (image_name (id), "rb"))
	local data = file:read ("*all")
	file:close ()

	local str = core.decompress (data, "deflate", 9)
	map.data = {}
	map.heightmap = {}
	local offset = (MAP_SIDE_LENGTH * MAP_SIDE_LENGTH * 4)
	deserialize_data (map.data, str, 0)
	deserialize_data (map.heightmap, str, offset)
	return map
end

local warned = {}

local function load_map_data (id)
	if warned[id] then -- This map is known not to exist.
		return nil
	elseif loaded_maps[id] then
		loaded_maps[id].ttl = MAP_TTL
		return loaded_maps[id]
	end

	local ok, err = pcall (load_map_1, id)
	if not ok then
		if not warned[id] then
			core.log ("error", "[mcl_maps] Failed to load map: " .. id)
			core.log ("error", tostring (err))
			warned[id] = true
		end
		return nil
	end

	loaded_maps[id] = err
	loaded_maps[id].ttl = MAP_TTL
	return err
end

mcl_maps.load_map_data = load_map_data

local function manage_maps (dtime)
	for id, map in pairs (loaded_maps) do
		local t = map.ttl - dtime
		if t <= 0 then
			loaded_maps[id] = nil
			write_map_data (id, map)
		else
			map.ttl = t
		end
	end
	update_all_maps ()
end

local function save_all_maps (maps)
	for id, map in pairs (loaded_maps) do
		write_map_data (id, map)
	end
end

core.register_globalstep (manage_maps)
core.register_on_shutdown (save_all_maps)

------------------------------------------------------------------------
-- Map item implementation.
------------------------------------------------------------------------

local function create_new_map_1 (id, pos, dim)
	local gx = band (pos.x - 63, -128) + 64
	local gz = band (pos.z + 63, -128) - 64

	local map = {
		x_start = gx,
		z_start = gz,
		dimension = dim,
		scale = 1,
		data = alloc_map_data (),
		heightmap = alloc_heightmap_data (),
	}
	local id = allocate_map_id ()
	map.ttl = MAP_TTL
	loaded_maps[id] = map
	return id, map
end

-- Radius of circle enclosing map update area.
local CIRCLE_RADIUS = ceil (64.0 / mathcos (pi / 4))
local CIRCLE_RADIUS_SQR = CIRCLE_RADIUS * CIRCLE_RADIUS

local function create_new_map (itemstack, placer, pointed_thing)
	local new_stack = mcl_util.call_on_rightclick (itemstack, placer,
						       pointed_thing)
	if new_stack then
		return new_stack
	end

	if placer and placer:is_valid () then
		local placer_pos = placer:get_pos ()
		local pos = mcl_util.get_nodepos (placer_pos)
		local dim = mcl_worlds.pos_to_dimension (pos)
		if dim == "void" then
			local msg = S ("Maps cannot be created at this position")
			core.chat_send_player (placer:get_player_name (), msg)
			return itemstack
		end
		local id = allocate_map_id ()
		local id, map = create_new_map_1 (id, pos, dim)
		local stack = ItemStack ("mcl_maps:map")

		-- Prepare the map's heightmap and fill the map.
		local y1 = pos.y - floor (MAP_UPDATE_AREA_Y / 2)
		prepare_map_generation_vm (map, y1)
		prepare_map_heights (map, y1)
		-- for i = 0, MAP_DATA_LENGTH - 1 do
		-- 	produce_map_turn (map, 0, y1, i, 1)
		-- end

		local radius = CIRCLE_RADIUS
		local x1 = mathmax (pos.x - radius, map.x_start)
		local x2 = -1 + mathmin (pos.x + radius,
					 map.x_start + MAP_UPDATE_AREA)
		local z1 = mathmax (pos.z - radius, map.z_start)
		local z2 = -1 + mathmin (pos.z + radius,
					 map.z_start + MAP_UPDATE_AREA)

		-- Generate so much of the map as is within range of
		-- the player.
		if x1 <= x2 and z1 <= z2 then
			for z = z1, z2 do
				-- Generate a sphere.
				local dist = mathabs (z - pos.z)
				local r = mathsqrt (CIRCLE_RADIUS_SQR - dist * dist)
				local x1 = mathmax (x1, floor (pos.x - r + 0.5))
					- map.x_start
				local x2 = mathmin (x2, floor (pos.x + r + 0.5))
					- map.x_start
				if x2 >= x1 then
					local turn = z - map.z_start
					produce_map_turn (map, x1, y1, turn, x2 - x1 + 1)
				end
			end
		end

		-- Save the map and initialize the ItemStack.
		write_map_data (id, map)
		stack:get_meta ():set_string ("mcl_maps:map_id", id)

		itemstack:take_item ()
		if itemstack:is_empty () then
			return stack
		end

		local inv = placer:get_inventory()
		if inv:room_for_item ("main", stack) then
			inv:add_item ("main", stack)
		else
			core.add_item (placer_pos, new_map)
		end
		return itemstack
	end
end

core.register_craftitem ("mcl_maps:map_empty", {
	description = S ("Empty Map"),
	_doc_items_longdesc = S ("Empty maps are not useful as maps, but they can be stacked and turned to maps which can be used."),
	_doc_items_usagehelp = S ("Right click to create a filled map."),
	inventory_image = "mcl_maps_map_empty.png",
	on_place = create_new_map,
	on_secondary_use = create_new_map,
})

-- A map is maintained between players and active map textures known
-- to them.  Each key indexes only a single texture string, to wit,
-- that which corresponds to the currently wielded map, as unreleased
-- texture data on the client is preferable to accumulating unused
-- texture strings on the server.

local maps = {}
local huds = {}

local function use_filled_map (itemstack, placer, pointed_thing)
	local new_stack = mcl_util.call_on_rightclick (itemstack, placer,
						       pointed_thing)
	if new_stack then
		return new_stack
	end

	if placer and placer:is_valid () then
		local id = itemstack:get_meta ():get_string ("mcl_maps:map_id")
		if not id or id == "" then
			return
		end

		local map = load_map_data (id)
		if not map then
			return
		end

		-- Update the current map image if necessary.
		local png = core.encode_base64 (encode_map_png (map))
		huds[placer].last_texture
			= modifier_escape ("blank.png^[png:" .. png)
	end
end

core.register_craftitem ("mcl_maps:map", {
	description = S("Map"),
	_tt_help = S("Shows a map image."),
	_doc_items_longdesc = S("When created, the map saves the nearby area as an image that can be viewed any time by holding the map."),
	_doc_items_usagehelp = S("Hold the map in your hand. This will display a map on your screen."),
	inventory_image = "mcl_maps_map_filled.png^(mcl_maps_map_filled_markings.png^[colorize:#000000)",
	on_place = use_filled_map,
	on_secondary_use = use_filled_map,
})

local map_update_cnt = 0
local N = 4 -- Number of rows to update on each globalstep.
local STEPS_PER_MAP = MAP_DATA_LENGTH / N
local STEP_MASK = 0x1f

local function update_one_map_unscaled (nodepos, map, xmin, xmax, x_end, y1)
	local radius = CIRCLE_RADIUS
	local xmin = nodepos.x - radius
	local xmax = nodepos.x + radius - 1
	local x_end = map.x_start + MAP_DATA_LENGTH - 1
	if xmin <= x_end and xmax >= map.x_start then
		local y1 = nodepos.y - floor (MAP_UPDATE_AREA_Y / 2)
		local x1 = mathmax (xmin, map.x_start)
			- map.x_start
		local x2 = mathmin (xmax, x_end)
			- map.x_start
		local z_end = map.z_start + MAP_DATA_LENGTH - 1
		local z1 = mathmax (nodepos.z - radius, map.z_start)
			- map.z_start
		local z2 = mathmin (nodepos.z + radius - 1, z_end)
			- map.z_start
		local player_x = nodepos.x - map.x_start
		local player_z = nodepos.z - map.z_start
		for i = z1, z2 do
			if band (i, STEP_MASK) == map_update_cnt then
				local d = mathabs (i - player_z)
				local r = mathsqrt (CIRCLE_RADIUS_SQR - d * d)
				local x1 = mathmax (x1, floor (player_x - r + 0.5))
				local x2 = mathmin (x2, floor (player_x + r + 0.5))
				if x2 >= x1 then
					-- Unscaled maps have their entire
					-- heightmaps initialized at the time
					-- of creation, and therefore it is
					-- satisfactory if only the heightmap
					-- for the current row is updated for
					-- reasons of performance.
					produce_heightmap_turn (map, x1, y1, i, x2 - x1 + 1)
					produce_map_turn (map, x1, y1, i, x2 - x1 + 1)
				end
			end
		end
	end
end

local function update_one_map (nodepos, map, radius, xmin, xmax, x_end, y1)
	local scale = map.scale - 1
	local radius = CIRCLE_RADIUS
	local xmin = nodepos.x - radius
	local xmax = nodepos.x + radius - 1
	local data_compass = lshift (MAP_DATA_LENGTH - 1, scale)
	local x_end = map.x_start + data_compass
	if xmin <= x_end and xmax >= map.x_start then
		local y1 = nodepos.y - floor (MAP_UPDATE_AREA_Y / 2)
		local x1 = mathmax (xmin, map.x_start) - map.x_start
		local x2 = mathmin (xmax, x_end) - map.x_start
		local z_end = map.z_start + data_compass
		local z1_node = mathmax (nodepos.z - radius, map.z_start)
			- map.z_start
		local z2_node = mathmin (nodepos.z + radius - 1, z_end)
			- map.z_start
		local z1 = arshift (z1_node, scale)
		local z2 = arshift (z2_node, scale)
		local player_x = nodepos.x - map.x_start
		local player_z = nodepos.z - map.z_start
		for i = z1, z2 do
			if band (i, STEP_MASK) == map_update_cnt then
				local d = mathabs (lshift (i, scale) - player_z)
				local r = mathsqrt (CIRCLE_RADIUS_SQR - d * d)
				local x1 = mathmax (x1, floor (player_x - r + 0.5))
				local x2 = mathmin (x2, floor (player_x + r + 0.5))
				if x2 >= x1 then
					local x1 = rshift (x1, scale)
					local x2 = rshift (x2, scale)
					local cnt = x2 - x1 + 1
					produce_heightmap_turn (map, x1, y1, i - 1, cnt)
					produce_heightmap_turn (map, x1, y1, i, cnt)
					produce_heightmap_turn (map, x1, y1, i + 1, cnt)
					produce_map_turn (map, x1, y1, i, cnt)
				end
			end
		end
	end
end

function update_all_maps ()
	prepare_map_generation ()
	for player, pos in mcl_player.iterate_connected_players () do
		local wielditem = player:get_wielded_item ()
		local nodepos = mcl_util.get_nodepos (pos)
		if wielditem:get_name () == "mcl_maps:map" then
			local map_id = wielditem:get_meta ():get_string ("mcl_maps:map_id")
			local locked = wielditem:get_meta ():get_int ("mcl_maps:locked")
			local map = load_map_data (map_id)
			local dim = mcl_worlds.pos_to_dimension (nodepos)
			if map and locked ~= 1 and map.dimension == dim then
				if map.scale == 1 then
					update_one_map_unscaled (nodepos, map)
				else
					update_one_map (nodepos, map)
				end
			end
		end
	end
	map_update_cnt = (map_update_cnt + 3) % STEPS_PER_MAP
end

------------------------------------------------------------------------
-- Map item scaling.
------------------------------------------------------------------------

local MAX_MAP_SCALE = 5
mcl_maps.MAX_MAP_SCALE = MAX_MAP_SCALE

local function scale_map_data_1 (gx, gz, scale, dim)
	local map = {
		x_start = gx,
		z_start = gz,
		scale = scale,
		dimension = dim,
		data = alloc_map_data (),
		heightmap = alloc_heightmap_data (),
	}
	local id = allocate_map_id ()
	map.ttl = MAP_TTL
	loaded_maps[id] = map
	return id, map
end

local function scale_map_data (map)
	-- What should be the origin of the updated map?
	local s = map.scale + 1
	if s > MAX_MAP_SCALE then
		return nil, nil
	end
	local mask = -lshift (1, 6 + s)
	local start_x = band (map.x_start - 64, mask) + 64
	local start_z = band (map.z_start + 64, mask) - 64

	local id, dst = scale_map_data_1 (start_x, start_z,
					  s, map.dimension)

	-- Copy existing data from MAP to the scaled map.  In the
	-- interests of performance, scaling is realized only by
	-- sampling the map at appropriate intervals.

	local dx = arshift (map.x_start - start_x, s - 1)
	local dz = arshift (map.z_start - start_z, s - 1)
	local src_heightmap = map.heightmap
	local src_data = map.data
	local dst_heightmap = dst.heightmap
	local dst_data = dst.data

	for z = 1, MAP_SIDE_LENGTH - 1, 2 do
		local src_base = z * MAP_SIDE_LENGTH + 1
		local i = rshift (z, 1) + dz + 1
		local dst_base = i * MAP_SIDE_LENGTH + 1
		-- The first item is never preserved in the scaled
		-- map, as node indices are scaled by the map's scale,
		-- and `-1' would yield `-2', which is not present in
		-- the map data.
		for x = 1, MAP_SIDE_LENGTH - 1, 2 do
			local i = rshift (x, 1) + dx + 1
			dst_heightmap[dst_base + i] = src_heightmap[src_base + x]
			dst_data[dst_base + i] = src_data[src_base + x]
		end
	end

	write_map_data (id, map)
	return id, dst
end

mcl_maps.scale_map_data = scale_map_data

function mcl_maps.scale_map_item (stack)
	local map_id = stack:get_meta ():get_string ("mcl_maps:map_id")
	local map = load_map_data (map_id)
	if not map then
		return nil
	end

	local id, dst = scale_map_data (map)
	if dst then
		local stack = ItemStack ("mcl_maps:map")
		stack:get_meta ():set_string ("mcl_maps:map_id", id)
		return stack
	end
	return nil
end

core.register_chatcommand ("scale_map", {
	description = S ("Scale the map which you are wielding."),
	privs = { server = true, },
	func = function (name, param)
		local player = core.get_player_by_name (name)
		if not player then
			return
		end

		local wielditem = player:get_wielded_item ()
		if wielditem and wielditem:get_name () == "mcl_maps:map" then
			local scaled = mcl_maps.scale_map_item (wielditem)
			if scaled then
				if param == "1" then
					-- Lock the map if so
					-- specified.
					scaled:get_meta ():set_int ("mcl_maps:locked", 1)
				end
				local inv = player:get_inventory ()
				if inv:room_for_item ("main", scaled) then
					inv:add_item ("main", scaled)
				else
					core.add_item (player:get_pos (), scaled)
				end
			end
		end
		return
	end
})

------------------------------------------------------------------------
-- Server-side map item user interface.
------------------------------------------------------------------------

core.register_on_joinplayer(function(player)
	local map_def = {
		type = "image",
		text = "blank.png",
		position = { x = 0.75, y = 0.8 },
		alignment = { x = 0, y = -1 },
		offset = { x = 0, y = 0 },
		scale = { x = 2, y = 2 },
	}
	local marker_def = table.copy(map_def)
	marker_def.alignment = { x = 0, y = 0 }
	huds[player] = {
		map = player:hud_add(map_def),
		marker = player:hud_add(marker_def),
	}
end)

core.register_on_leaveplayer(function(player)
	maps[player] = nil
	huds[player] = nil
end)

mcl_player.register_globalstep (function(player)
	local wield = player:get_wielded_item ()
	local hud = huds[player]
	local texture, id

	if hud.wielditem and hud.wielditem:equals (wield) then
		texture = hud.last_texture
		id = hud.last_map_id
	else
		texture, id = mcl_maps.load_map_item (wield)
		hud.wielditem = wield
		hud.last_texture = texture
		hud.last_map_id = id

		if texture then
			mcl_title.set (player, "actionbar", {
				text = S ("Right-click to redraw map"),
				color = "white",
				stay = 60,
			})
		end
	end

	-- This may fail if the map texture is cached but the map was
	-- unloaded and subsequently removed.
	local map = id and load_map_data (id)
	if texture and map then
		local wield_def = wield:get_definition()

		if texture ~= maps[player] then
			local data = "[combine:140x140:0,0=mcl_maps_map_background.png:6,6="
				.. texture
			player:hud_change (hud.map, "text", data)
			maps[player] = texture
		end

		local pos = vector.round (player:get_pos())
		local width = lshift (MAP_DATA_LENGTH, map.scale - 1)
		local minp = vector.new (map.x_start, 0, map.z_start)
		local maxp = vector.new (map.x_start + width - 1, 0,
					 map.z_start + width - 1)

		local marker = "mcl_maps_player_arrow.png"

		if pos.x < minp.x then
			marker = "mcl_maps_player_dot.png"
			pos.x = minp.x
		elseif pos.x > maxp.x then
			marker = "mcl_maps_player_dot.png"
			pos.x = maxp.x
		end

		if pos.z < minp.z then
			marker = "mcl_maps_player_dot.png"
			pos.z = minp.z
		elseif pos.z > maxp.z then
			marker = "mcl_maps_player_dot.png"
			pos.z = maxp.z
		end

		if marker == "mcl_maps_player_arrow.png" then
			local yaw = (math.floor(player:get_look_horizontal() * 180 / math.pi / 90 + 0.5) % 4) * 90
			marker = marker .. "^[transformR" .. yaw
		end

		player:hud_change(hud.marker, "text", marker)

		local f = 2 * 128 / (maxp.x - minp.x + 1)
		player:hud_change(hud.marker, "offset", {
			x = (pos.x - minp.x) * f - 128,
			y = (maxp.z - pos.z) * f - 256,
		})
	elseif maps[player] then
		player:hud_change(hud.map, "text", "blank.png")
		player:hud_change(hud.marker, "text", "blank.png")
		maps[player] = nil
	end
end)


function mcl_maps.load_map_item (itemstack)
	if itemstack:get_name () == "mcl_maps:map" then
		local id = itemstack:get_meta ():get_string ("mcl_maps:map_id")
		local map = load_map_data (id)

		if map then
			local png = core.encode_base64 (encode_map_png (map))
			local tbl = {
				"(", modifier_escape ("blank.png^[png:" .. png), ")"
			}
			return table.concat (tbl), id
		end
	end

	return nil, nil
end
