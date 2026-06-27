mcl_maps = {}

local pairs = pairs
local ipairs = ipairs

local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
local S = core.get_translator(modname)

local worldpath = core.get_worldpath()
local map_textures_path = worldpath .. "/mcl_maps/"

local detected_old_maps = false
if core.path_exists (map_textures_path) then
	for _, name in ipairs (core.get_dir_list (map_textures_path)) do
		if name:find ("^mcl_maps_map_texture_") then
			detected_old_maps = true
			break
		end
	end
else
	core.mkdir (map_textures_path)
end

local use_old_map_grid
	= core.get_mapgen_setting ("mcl_use_old_map_grid")

if not use_old_map_grid then
	use_old_map_grid = detected_old_maps
	core.set_mapgen_setting ("mcl_use_old_map_grid",
				 tostring (detected_old_maps), true)
else
	use_old_map_grid = core.is_yes (use_old_map_grid)
end

local function load_json_file(name)
	local file = assert(io.open(modpath .. "/" .. name .. ".json", "r"))
	local data = core.parse_json(file:read("*all"))
	file:close()
	return data
end

local texture_colors = load_json_file ("colors")

local enable_real_maps
	= core.settings:get_bool ("enable_real_maps", true)
local enable_minimap_shading
	= core.settings:get_bool ("mcl_enable_minimap_map_shading", false)

------------------------------------------------------------------------
-- Dynamically updated maps.
------------------------------------------------------------------------

local map_colors_by_cid = {}

local rshift = bit.rshift
local lshift = bit.lshift
local arshift = bit.arshift

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
local MAP_SIDE_LENGTH = 128
mcl_maps.MAP_SIDE_LENGTH = MAP_SIDE_LENGTH

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
			= scan_heightmap (current, x_start + lshift (i, scale),
					  z_start, y1, y1 + MAP_UPDATE_AREA_Y - 1)
	end
end

local function produce_rgb_turn (map, z1, base_first, base, base_next,
                                i_start, i_end)
	local scale = map.scale - 1
	local x_start = map.x_start
	local z_start = map.z_start + lshift (z1, scale)
	local heightmap = map.heightmap
	local data = map.data
	local map_r = 4.0 / (lshift (1, scale) + 4.0)
	local cz = z1 - MAP_SIDE_LENGTH - 1
	local last = MAP_SIDE_LENGTH - 1

	for i = i_start, i_end do
		local current = heightmap[base + i]
		local x_pos = x_start + lshift (i, scale)
		local cid, _, param2
			= map_get_node_raw (x_pos, current, z_start)
		local rgb = get_rgb (cid, param2)
		if rgb then
			local height = heightmap[base + i]
			local height_north = heightmap[base_next + i] or height
			if height_north ~= height then
				local b = band (rgb, 0xff)
				local g = rshift (band (rgb, 0xff00), 8)
				local r = rshift (band (rgb, 0xff0000), 16)
				if height_north < height then
					r = math.min(255, r + 16)
					g = math.min(255, g + 16)
					b = math.min(255, b + 16)
				elseif height_north > height then
					r = math.max(0, r - 16)
					g = math.max(0, g - 16)
					b = math.max(0, b - 16)
				end
				rgb = bor (b, lshift (g, 8), lshift (r, 16))
			end
			data[base + i] = bor (0xff000000, rgb)
		end
	end
end

local function prepare_map_heights (map, y1)
	for turn = 0, MAP_SIDE_LENGTH - 1 do
		local idx = turn * MAP_SIDE_LENGTH + 1
		produce_heightmap_turn_1 (map, -1, y1, turn, idx, 0,
					  MAP_SIDE_LENGTH - 1)
	end
end

local function produce_heightmap_turn (map, x1, y1, z1, n)
	local idx = z1 * MAP_SIDE_LENGTH + 1
	produce_heightmap_turn_1 (map, x1, y1, z1, idx, x1,
				  x1 + n - 1)
end

local function produce_map_turn (map, x1, y1, z1, n)
	-- Each index addresses a row of MAP_SIDE_LENGTH elements in
	-- DATA and HEIGHTMAP representing the maximum recorded height
	-- and the current value of the map at that row.
	local turn = z1
	local idx_first = (turn - 1) * MAP_SIDE_LENGTH + 1
	local idx_turn = turn * MAP_SIDE_LENGTH + 1
	local idx_next = (turn + 1) * MAP_SIDE_LENGTH + 1
	local i_start, i_end
		= x1, mathmin (x1 + n - 1, MAP_SIDE_LENGTH - 1)
	produce_rgb_turn (map, z1, idx_first, idx_turn,
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
	for z = MAP_SIDE_LENGTH - 1, 0, -1 do
		for x = 0, MAP_SIDE_LENGTH - 1 do
			i = i + 1
			dst[i] = data[z * MAP_SIDE_LENGTH + x + 1]
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
	v1.x = map.x_start
	v1.y = y1
	vm_y1 = y1
	v1.z = map.z_start
	v2.x = map.x_start + (MAP_UPDATE_AREA - 1) * map.scale
	v2.y = y1 + MAP_UPDATE_AREA_Y - 1
	v2.z = map.z_start + (MAP_UPDATE_AREA - 1) * map.scale
	if vm then
		mcl_util.vm_close (vm)
	end
	vm = VoxelManip (v1, v2)
	vm:get_data (cids)
	vm:get_param2_data (param2)
	area = VoxelArea (vm:get_emerged_area ())
end

local function prepare_map_generation ()
	map_get_node_raw = core.get_node_raw
	if vm then
		mcl_util.vm_close (vm)
		vm = nil
	end
end

local converted_data = {}

local function encode_map_png (map, compression)
	convert_map_data (converted_data, map)
	local png = core.encode_png (MAP_SIDE_LENGTH,
				     MAP_SIDE_LENGTH,
				     converted_data,
				     compression)
	return png
end

local function irr_convert_map_data (dst, map)
	local i = 0
	local data = map.data
	for z = 0, MAP_SIDE_LENGTH - 1 do
		for x = 0, MAP_SIDE_LENGTH - 1 do
			i = i + 1
			dst[i] = data[z * MAP_SIDE_LENGTH + x + 1]
		end
	end
end

function mcl_maps.convert_map_data (map)
	irr_convert_map_data (converted_data, map)
	return converted_data
end

------------------------------------------------------------------------
-- Map management and serialization.
------------------------------------------------------------------------

local MAP_TTL = 20
local ERROR_MAP_ID = "error"

local loaded_maps = {}
local update_all_maps

local function map_name (id)
	return map_textures_path .. id .. ".lua"
end

local function texture_name (id)
	return map_textures_path .. id .. '_texture.tga'
end

local function heightmap_name (id)
	return map_textures_path .. id .. "_heightmap.tga"
end

local function allocate_map_id ()
	local base = os.date ("map_%Y%m%d%H%M%S_")
	local i = 0
	while core.path_exists (map_name (base .. i)) do
		i = i + 1
	end

	local texture_name = texture_name (base .. i)
	local heightmap_name = heightmap_name (base .. i)
	local map_name = map_name (base .. i)
	return base .. i, texture_name, heightmap_name, map_name
end

local char = string.char
local byte = string.byte

local function serialize_data (dst, list, off)
	assert (#list == MAP_SIDE_LENGTH * MAP_SIDE_LENGTH)
	for i = 1, #list do
		local value = list[i]
		local b0 = band (value, 0xff)
		local b1 = rshift (band (value, 0xff00), 8)
		local b2 = rshift (band (value, 0xff0000), 16)
		local b3 = rshift (band (value, 0xff000000), 24)
		dst[off + i * 4 - 3] = char (b0)
		dst[off + i * 4 - 2] = char (b1)
		dst[off + i * 4 - 1] = char (b2)
		dst[off + i * 4] = char (b3)
	end
end

local function write_map_data (id, map)
	local tbl = {
		x_start = map.x_start,
		z_start = map.z_start,
		structure_pos = map.structure_pos,
		dimension = map.dimension or "overworld",
		scale = map.scale,
	}
	local str = core.serialize (tbl)
	local rc = core.safe_file_write (map_name (id), str)
	if not rc then
		error ("Could not write map metadata for " .. id)
	end

	local bytes = string.char
	local tga_header = bytes(0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, MAP_SIDE_LENGTH, 0, MAP_SIDE_LENGTH, 0, 32, 8)
	local tga_footer = bytes(0, 0, 0, 0, 0, 0, 0, 0) .. "TRUEVISION-XFILE." .. bytes(0)

	local texture = {}
	serialize_data (texture, map.data, #texture)
	local texture_bytes = tga_header .. table.concat (texture) .. tga_footer
	local rc = core.safe_file_write (texture_name (id), texture_bytes)
	if not rc then
		error ("Could not write map texture for " .. id)
	end

	local heightmap = {}
	serialize_data (heightmap, map.heightmap, #heightmap)
	local heightmap_bytes = tga_header .. table.concat (heightmap) .. tga_footer
	local rc = core.safe_file_write (heightmap_name (id), heightmap_bytes)
	if not rc then
		error ("Could not write map heightmap for " .. id)
	end
end

local function deserialize_data (dst, str, offset)
	for i = 1, MAP_SIDE_LENGTH * MAP_SIDE_LENGTH do
		local b0 = byte (str, i * 4 - 3 + offset)
		local b1 = byte (str, i * 4 - 2 + offset)
		local b2 = byte (str, i * 4 - 1 + offset)
		local b3 = byte (str, i * 4 + offset)
		dst[i] = bor (b0, lshift (b1, 8), lshift (b2, 16),
			      lshift (b3, 24))
	end
end

local function load_map_error ()
	local map = {
		dimension = "none",
		x_start = 0,
		z_start = 0,
		scale = 1,
		data = alloc_map_data (),
		heightmap = alloc_heightmap_data (),
	}
	return map
end

local function load_map_1 (id)
	if id == ERROR_MAP_ID then
		return load_map_error ()
	end

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
	if map.structure_pos then
		assert (type (map.structure_pos) == "table")
		assert (type (map.structure_pos.x) == "number")
		assert (type (map.structure_pos.y) == "number")
		assert (type (map.structure_pos.z) == "number")
		map.structure_pos = vector.copy (map.structure_pos)
	end

	local texture_file = assert (io.open (texture_name (id), "rb"))
	local texture_data = texture_file:read ("*all")
	texture_file:close()
	map.data = {}
	deserialize_data (map.data, texture_data, 18)

	local heightmap_file = assert (io.open (heightmap_name (id), "rb"))
	local heightmap_data = heightmap_file:read ("*all")
	heightmap_file:close()
	map.heightmap = {}
	deserialize_data (map.heightmap, heightmap_data, 18)

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

local function save_all_maps ()
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
	local gx, gz

	if not use_old_map_grid then
		gx = band (pos.x - 63, -128) + 64
		gz = band (pos.z + 63, -128) - 64
	else
		gx = band (pos.x, -128)
		gz = band (pos.z, -128)
	end

	local map = {
		x_start = gx,
		z_start = gz,
		dimension = dim,
		scale = 1,
		data = alloc_map_data (),
		heightmap = alloc_heightmap_data (),
	}
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
		if not enable_real_maps then
			local msg = S ("Maps are not enabled on this server")
			core.chat_send_player (placer:get_player_name (), msg)
			return itemstack
		end
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
		tt.reload_itemstack_description (stack)

		itemstack:take_item ()
		if itemstack:is_empty () then
			return stack
		end

		local inv = placer:get_inventory()
		if inv:room_for_item ("main", stack) then
			inv:add_item ("main", stack)
		else
			core.add_item (placer_pos, stack)
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
		if mcl_serverplayer.is_csm_at_least (placer, 14) then
			return
		end

		local id = mcl_maps.load_map_id (itemstack)
		if not id then
			return
		end

		local map = load_map_data (id)
		if not map then
			return
		end

		-- Update the current map image if necessary.
		local png = core.encode_base64 (encode_map_png (map, 9))
		huds[placer].last_texture
			= modifier_escape ("blank.png^[png:" .. png)
	end
end

core.register_craftitem ("mcl_maps:map", {
	description = S("Map"),
	_tt_help = S("Shows a map image."),
	_doc_items_longdesc = S("When wielded, the area within a radius of 64 nodes from your position is recorded for display as you explore the world."),
	_doc_items_usagehelp = S("Hold the map in your hand. This will display a map on your screen and record the world in the same."),
	inventory_image = "mcl_maps_map_filled.png^(mcl_maps_map_filled_markings.png^[colorize:#000000)",
	on_place = use_filled_map,
	on_secondary_use = use_filled_map,
	groups = {
		not_in_creative_inventory = 1,
		filled_map = 1,
		tool = 1,
	},
})

core.register_craftitem ("mcl_maps:map_locked", {
	description = S("Locked Map"),
	_tt_help = S("Shows a static map image."),
	_doc_items_longdesc = S ("This item contains a map which is no longer updated as you move."),
	_doc_items_usagehelp = S ("Hold the map in your hand. This will display a map on your screen."),
	inventory_image = "mcl_maps_map_filled.png^(mcl_maps_map_filled_markings.png^[colorize:#000000)",
	groups = {
		not_in_creative_inventory = 1,
		filled_map = 1,
		tool = 1,
	},
})

local map_update_cnt = 0
local N = 4 -- Number of rows to update on each globalstep.
mcl_maps.N = N
local STEPS_PER_MAP = MAP_SIDE_LENGTH / N
local STEP_MASK = 0x1f

local function update_one_map_unscaled (nodepos, map)
	local radius = CIRCLE_RADIUS
	local xmin = nodepos.x - radius
	local xmax = nodepos.x + radius - 1
	local x_end = map.x_start + MAP_SIDE_LENGTH - 1
	local map_updated = false
	if xmin <= x_end and xmax >= map.x_start then
		local y1 = nodepos.y - floor (MAP_UPDATE_AREA_Y / 2)
		local x1 = mathmax (xmin, map.x_start)
			- map.x_start
		local x2 = mathmin (xmax, x_end)
			- map.x_start
		local z_end = map.z_start + MAP_SIDE_LENGTH - 1
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
					map_updated = true
				end
			end
		end
	end
	return map_updated
end

local function update_one_map (nodepos, map)
	local scale = map.scale - 1
	local radius = CIRCLE_RADIUS
	local xmin = nodepos.x - radius
	local xmax = nodepos.x + radius - 1
	local data_compass = lshift (MAP_SIDE_LENGTH - 1, scale)
	local x_end = map.x_start + data_compass
	local map_updated = false
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
					if i > 0 then
						produce_heightmap_turn (map, x1, y1, i - 1, cnt)
					end
					produce_heightmap_turn (map, x1, y1, i, cnt)
					if i < MAP_SIDE_LENGTH - 1 then
						produce_heightmap_turn (map, x1, y1, i + 1, cnt)
					end
					produce_map_turn (map, x1, y1, i, cnt)
					map_updated = true
				end
			end
		end
	end
	return map_updated
end

local realize_explorer_map

function update_all_maps ()
	local updates = {}
	prepare_map_generation ()
	for player, pos in mcl_player.iterate_connected_players () do
		local wielditem = player:get_wielded_item ()
		local nodepos = mcl_util.get_nodepos (pos)
		local item_name = wielditem:get_name ()
		local map_id, explorer_map_id
		if item_name == "mcl_maps:map" then
			local meta = wielditem:get_meta ()
			map_id = meta:get_string ("mcl_maps:map_id")
		elseif core.get_item_group (item_name, "explorer_map") > 0 then
			map_id, explorer_map_id = realize_explorer_map (wielditem)
		end
		if map_id and map_id ~= "" then
			local map = load_map_data (map_id)
			local dim = mcl_worlds.pos_to_dimension (nodepos)
			if map and map.dimension == dim then
				local updated
				if map.scale == 1 then
					updated = update_one_map_unscaled (nodepos, map)
				else
					updated = update_one_map (nodepos, map)
				end

				if updated then
					-- If an explorer map has been
					-- updated, this update must
					-- be identified by the
					-- explorer map ID.  Explorer
					-- maps and cartographic maps
					-- are expected not to alias.
					updates[map]
						= tostring (explorer_map_id or map_id)
				end
			end
		end
	end
	mcl_serverplayer.send_cartography_updates (updates, map_update_cnt)
	map_update_cnt = (map_update_cnt + 3) % STEPS_PER_MAP
end

local dst = {}

function mcl_maps.encode_map_update (map, update_cnt)
	local data = map.data
	local idx = 1
	for i = 0, MAP_SIDE_LENGTH - 1 do
		if band (i, STEP_MASK) == update_cnt then
			local base = i * MAP_SIDE_LENGTH + 1
			for src_idx = base, base + MAP_SIDE_LENGTH - 1 do
				dst[idx] = data[src_idx]
				idx = idx + 1
			end
		end
	end
	return dst
end

------------------------------------------------------------------------
-- Explorer maps.
------------------------------------------------------------------------

local BIOME_STIPPLES = {}

local EXPLORER_MAP_BKG = 0xffc3ae89

local RIVER = {
	0xff955824,
	0xff955824,
	0xff955824,
	0xff955824,
	0xff955824,
	0xff955824,
	0xff955824,
	0xff955824,
}

local DEEP_OCEAN = {
	0xff5c3311,
	EXPLORER_MAP_BKG,
	0xff5c3311,
	EXPLORER_MAP_BKG,
	0xff5c3311,
	EXPLORER_MAP_BKG,
	0xff5c3311,
	EXPLORER_MAP_BKG,
}

local OCEAN = {
	0xff955824,
	EXPLORER_MAP_BKG,
	0xff955824,
	EXPLORER_MAP_BKG,
	0xff955824,
	EXPLORER_MAP_BKG,
	0xff955824,
	EXPLORER_MAP_BKG,
}

for _, biome in ipairs (mcl_levelgen.build_biome_list ({"#is_river"})) do
	BIOME_STIPPLES[biome] = RIVER
end

for _, biome in ipairs (mcl_levelgen.build_biome_list ({"#is_ocean"})) do
	BIOME_STIPPLES[biome] = OCEAN
end


for _, biome in ipairs (mcl_levelgen.build_biome_list ({"#is_deep_ocean"})) do
	BIOME_STIPPLES[biome] = DEEP_OCEAN
end

local prepare_cartography_biomes
	= mcl_biome_dispatch.prepare_cartography_biomes
local get_cartography_biome
	= mcl_biome_dispatch.get_cartography_biome

local function fill_explorer_map (map, y)
	local s = map.scale - 1
	local compass = lshift (MAP_SIDE_LENGTH - 1, s)
	local x1 = map.x_start
	local z1 = map.z_start
	local dim = prepare_cartography_biomes (y, x1, z1, compass,
						compass)
	if not dim then
		return false
	end

	local data = map.data
	for dz = 0, MAP_SIDE_LENGTH - 1 do
		local base = dz * MAP_SIDE_LENGTH + 1
		for dx = 0, MAP_SIDE_LENGTH - 1 do
			local i = dx
			local biome
				= get_cartography_biome (dim, x1 + lshift (dx, s),
							 z1 + lshift (dz, s))
			local stipples = BIOME_STIPPLES[biome]
			if stipples then
				data[base + i] = stipples[band (dx, 0x7) + 1]
			else
				data[base + i] = EXPLORER_MAP_BKG
			end
		end
	end
	return true
end

local function create_explorer_map_1 (pos)
	local dim = mcl_worlds.pos_to_dimension (pos)
	if dim == "void" then
		return nil, nil
	end
	local id = allocate_map_id ()
	local id, map = create_new_map_1 (id, pos, dim)
	map.structure_pos = vector.copy (pos)
	fill_explorer_map (map, pos.y)
	write_map_data (id, map)
	return id, map
end

function mcl_maps.create_explorer_map_now (pos, item)
	local id, map = create_explorer_map_1 (pos)

	if id and map then
		-- Initialize the ItemStack.
		local stack = ItemStack (item)
		stack:get_meta ():set_string ("mcl_maps:map_id", id)
		tt.reload_itemstack_description (stack)
		return stack
	end
	return nil
end

core.register_chatcommand ("explorer_map", {
	description = S ("Create an explorer map."),
	privs = { server = true, },
	func = function (name, param)
		local player = core.get_player_by_name (name)
		if not player then
			return
		end

		local map_pos = vector.from_string (param)
			or player:get_pos ()
		local pos = mcl_util.get_nodepos (map_pos)
		local stack = mcl_maps.create_explorer_map_now (pos, "mcl_maps:map")
		if stack then
			local inv = player:get_inventory ()
			if inv:room_for_item ("main", stack) then
				inv:add_item ("main", stack)
			else
				core.add_item (player:get_pos (), stack)
			end
		end
	end
})

core.register_chatcommand ("explorer_map_item", {
	description = S ("Create an explorer map item."),
	privs = { server = true, },
	func = function (name, param)
		local player = core.get_player_by_name (name)
		if not player then
			return
		end

		local id, pos = unpack (param:split (" "))
		local def = core.registered_items[id]
		if not def or not def._explorer_map_structures then
			return
		end
		local map_pos = vector.from_string (pos or "")
			or player:get_pos ()
		local pos = mcl_util.get_nodepos (map_pos)
		local stack = mcl_maps.initialize_explorer_map (pos, ItemStack (id))
		if stack then
			local inv = player:get_inventory ()
			if inv:room_for_item ("main", stack) then
				inv:add_item ("main", stack)
			else
				core.add_item (player:get_pos (), stack)
			end
		end
	end
})

local function explorer_map_on_entity_step (self, dtime, _)
	if self.name == "mcl_itemframes:item"
		and not self._dynamic_map_id then
		-- The explorer map is still be loaded.  Wait till it
		-- is realized, and record the map ID.
		local itemstack = self._stack
		if itemstack
			and core.get_item_group (itemstack:get_name (),
						 "explorer_map") > 0 then
			-- Load the map once it has been generated.
			self._dynamic_map_id = realize_explorer_map (itemstack)
			if self._dynamic_map_id then
				self:set_item (itemstack)
			end
		end
	end
end

local explorer_map_toplevel = {
	description = S ("Explorer Map"),
	_tt_help = S ("Guides you to a structure."),
	_doc_items_longdesc = S ("When wielded, a map is displayed with an indicator marking the position of a structure."),
	_doc_items_usagehelp = S("Hold the map in your hand.  This will display a map on your screen and record the world in the same."),
	on_place = use_filled_map,
	on_secondary_use = use_filled_map,
	groups = {
		not_in_creative_inventory = 1,
		filled_map = 1,
		explorer_map = 1,
		tool = 1,
	},
	_on_entity_step = explorer_map_on_entity_step,
}

function mcl_maps.register_explorer_map (name, color, itemdef)
	local merge = table.merge
	core.register_craftitem (":" .. name, merge (explorer_map_toplevel, merge (itemdef, {
		inventory_image = table.concat ({
			"mcl_maps_map_filled.png",
			"^(mcl_maps_map_filled_markings.png",
			"^[colorize:", color, ")",
		}),
		_explorer_map_structures
			= itemdef._explorer_map_structures or {},
	})))

	local recipe = { name, }
	for i = 2, 9 do
		for j = 2, i do
			recipe[j] = "mcl_maps:map_empty"
		end
		core.register_craft ({
			type = "shapeless",
			output = name .. " " .. i,
			recipe = recipe,
		})
	end
end

local function build_map_icon_texture (x, y)
	return table.concat ({
		"blank.png^[resize:8x8^[combine:8x8:",
		tostring (-(x * 8)), ",",
		tostring (-(y * 8)), "=",
		"mcl_maps_map_icons.png",
	})
end

mcl_maps.register_explorer_map ("mcl_maps:ocean_explorer_map", "#3a7265", {
	description = S ("Ocean Explorer Map"),
	_explorer_map_structures = {
		"mcl_levelgen:ocean_monument",
	},
	_treasure_symbol = build_map_icon_texture (9, 0),
	_skip_existing_chunks = true,
})

mcl_maps.register_explorer_map ("mcl_maps:woodland_explorer_map", "#524c44", {
	description = S ("Woodland Explorer Map"),
	_explorer_map_structures = {
		"mcl_levelgen:woodland_mansion",
	},
	_treasure_symbol = build_map_icon_texture (8, 0),
	_skip_existing_chunks = true,
})

mcl_maps.register_explorer_map ("mcl_maps:trial_explorer_map", "#c26b4c", {
	description = S ("Trial Explorer Map"),
	_explorer_map_structures = {
		"mcl_levelgen:trial_chambers",
	},
	_treasure_symbol = build_map_icon_texture (2, 2),
	_skip_existing_chunks = true,
})

mcl_maps.register_explorer_map ("mcl_maps:buried_treasure_map", "#675aad", {
	description = S ("Buried Treasure Map"),
	_explorer_map_structures = {
		"mcl_levelgen:buried_treasure",
	},
	_treasure_symbol = build_map_icon_texture (10, 1),
	_skip_existing_chunks = false,
})

mcl_maps.register_explorer_map ("mcl_maps:plains_village_map", "#848484", {
	description = S ("Plains Village Map"),
	_explorer_map_structures = {
		"mcl_villages:village_plains",
	},
	_treasure_symbol = build_map_icon_texture (12, 1),
	_skip_existing_chunks = true,
})


mcl_maps.register_explorer_map ("mcl_maps:desert_village_map", "#848484", {
	description = S ("Desert Village Map"),
	_explorer_map_structures = {
		"mcl_villages:village_desert",
	},
	_treasure_symbol = build_map_icon_texture (11, 1),
	_skip_existing_chunks = true,
})

mcl_maps.register_explorer_map ("mcl_maps:savannah_village_map", "#848484", {
	description = S ("Savanna Village Map"),
	_explorer_map_structures = {
		"mcl_villages:village_savannah",
	},
	_treasure_symbol = build_map_icon_texture (13, 1),
	_skip_existing_chunks = true,
})

mcl_maps.register_explorer_map ("mcl_maps:snowy_village_map", "#848484", {
	description = S ("Snowy Village Map"),
	_explorer_map_structures = {
		"mcl_villages:village_snowy",
	},
	_treasure_symbol = build_map_icon_texture (14, 1),
	_skip_existing_chunks = true,
})

mcl_maps.register_explorer_map ("mcl_maps:taiga_village_map", "#848484", {
	description = S ("Taiga Village Map"),
	_explorer_map_structures = {
		"mcl_villages:village_taiga",
	},
	_treasure_symbol = build_map_icon_texture (15, 1),
	_skip_existing_chunks = true,
})

mcl_maps.register_explorer_map ("mcl_maps:swamp_explorer_map", "#848484", {
	description = S ("Swamp Explorer Map"),
	_explorer_map_structures = {
		"mcl_levelgen:swamp_hut",
	},
	_treasure_symbol = build_map_icon_texture (1, 2),
	_skip_existing_chunks = true,
})

mcl_maps.register_explorer_map ("mcl_maps:jungle_explorer_map", "#848484", {
	description = S ("Jungle Explorer Map"),
	_explorer_map_structures = {
		"mcl_levelgen:jungle_temple",
	},
	_treasure_symbol = build_map_icon_texture (0, 2),
	_skip_existing_chunks = true,
})

local storage = core.get_mod_storage ()

function mcl_maps.initialize_explorer_map (pos, stack)
	local def = core.registered_items[stack:get_name ()]
	assert (def and def._explorer_map_structures)

	-- Indices commence at 30000 to prevent
	-- `realizing_explorer_maps' from being initialized as an
	-- array.
	local id = storage:get_int ("last_explorer_map_id") + 1 + 30000
	storage:set_int ("last_explorer_map_id", id)
	local meta = stack:get_meta ()
	meta:set_int ("mcl_maps:explorer_map_id", id)
	meta:set_int ("mcl_maps:explorer_map_x", floor (pos.x + 0.5))
	meta:set_int ("mcl_maps:explorer_map_y", floor (pos.y + 0.5))
	meta:set_int ("mcl_maps:explorer_map_z", floor (pos.z + 0.5))
	return stack
end

local realizing_explorer_maps = {}

local v = vector.new ()

local function filter_generated_structures (bx, by, bz, _)
	v.x = bx * 16
	v.y = by * 16
	v.z = bz * 16
	core.load_area (v)
	local cid, _, _, _
		= core.get_node_raw (bx * 16, by * 16, bz * 16)
	return cid ~= cid_ignore
end

local function realize_explorer_map_1 (pos, cb_data)
	local err = true
	if pos then
		local clock = core.get_us_time ()
		local id, _ = create_explorer_map_1 (pos)
		if id then
			local time = core.get_us_time () - clock
			local msg = "[mcl_maps]: Generated explorer map in "
				.. time / 1000 .. " ms"
			core.log ("action", msg)
			storage:set_string ("e_" .. cb_data, id)
			realizing_explorer_maps[cb_data] = nil
			err = false
		end
	end
	if err then
		storage:set_string ("e_" .. cb_data, ERROR_MAP_ID)
		realizing_explorer_maps[cb_data] = nil
	end

	-- If a map with this ID appears in any HUD slot, guarantee
	-- that it is reloaded.
	for _, hud in pairs (huds) do
		local stack = hud.wielditem
		if stack then
			local meta = stack:get_meta ()
			local id = meta:get_int ("mcl_maps:explorer_map_id")
			if id == cb_data then
				hud.wielditem = nil
				hud.last_texture = nil
				hud.last_map_id = nil
			end
		end
	end
end

local function maybe_realize_explorer_map (id)
	local map_id = storage:get_string ("e_" .. id)
	if map_id and map_id ~= "" then
		return map_id
	end
	return nil
end

function realize_explorer_map (stack)
	local meta = stack:get_meta ()
	local id = meta:get_int ("mcl_maps:explorer_map_id")
	local map_id = maybe_realize_explorer_map (id)
	if map_id then
		return map_id, id
	end
	local def = stack:get_definition ()
	assert (def and def._explorer_map_structures)
	if id > 0 and enable_real_maps then
		if realizing_explorer_maps[id] then
			return nil
		end

		local x = meta:get_int ("mcl_maps:explorer_map_x")
		local y = meta:get_int ("mcl_maps:explorer_map_y")
		local z = meta:get_int ("mcl_maps:explorer_map_z")
		local pos = vector.new (x, y, z)
		local structures = def._explorer_map_structures
		realizing_explorer_maps[id] = true
		local msg = {
			"[mcl_maps]: Generating explorer map of type ",
			stack:get_name (),
			" at ",
			vector.to_string (pos),
		}
		core.log ("action", table.concat (msg))
		local dist = 32
		local filter = filter_generated_structures

		-- Some explorer maps, such as Buried Treasure maps,
		-- always point to the nearest structure of the
		-- appropriate type in Minecraft, even after they have
		-- been generated.
		if not def._skip_existing_chunks then
			dist = 96
			filter = nil
		end

		mcl_biome_dispatch.locate_structure_near (pos, structures, dist,
							  realize_explorer_map_1,
							  id, nil, filter)
		return maybe_realize_explorer_map (stack, id), id
	end
	return nil
end

mcl_maps.realize_explorer_map = realize_explorer_map

local function initialize_explorer_maps (stack, x, y, z)
	local name = stack:get_name ()
	if core.get_item_group (name, "explorer_map") > 0 then
		v.x = x
		v.y = y
		v.z = z

		mcl_maps.initialize_explorer_map (v, stack)
	end
end

mcl_levelgen.register_loot_postprocessor ("mcl_maps:initialize_explorer_maps",
					  initialize_explorer_maps)

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

local function scale_map_origins (x_start, z_start, s)
	local mask = -lshift (1, 6 + s)
	if not use_old_map_grid then
		local start_x = band (x_start - 64, mask) + 64
		local start_z = band (z_start + 64, mask) - 64
		return start_x, start_z
	else
		local start_x = band (x_start, mask)
		local start_z = band (z_start, mask)
		return start_x, start_z
	end
end

local function scale_map_data (map)
	-- What should be the origin of the updated map?
	local s = map.scale + 1
	if s > MAX_MAP_SCALE then
		return nil, nil
	end
	local start_x, start_z
		= scale_map_origins (map.x_start,
				     map.z_start, s)
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

	for z = 0, MAP_SIDE_LENGTH - 1, 2 do
		local src_base = z * MAP_SIDE_LENGTH + 1
		local i = rshift (z, 1) + dz
		local dst_base = i * MAP_SIDE_LENGTH + 1
		for x = 0, MAP_SIDE_LENGTH - 1, 2 do
			local i = rshift (x, 1) + dx
			dst_heightmap[dst_base + i] = src_heightmap[src_base + x]
			dst_data[dst_base + i] = src_data[src_base + x]
		end
	end

	write_map_data (id, dst)
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

local function copy_map_data (src)
	local map = {
		x_start = src.x_start,
		z_start = src.z_start,
		dimension = src.dimension,
		scale = src.scale,
		data = alloc_map_data (),
		heightmap = alloc_heightmap_data (),
	}

	local src_data = src.data
	local src_heightmap = src.heightmap
	local dst_data = map.data
	local dst_heightmap = map.heightmap

	for i = 1, MAP_SIDE_LENGTH * MAP_SIDE_LENGTH do
		dst_data[i] = src_data[i]
		dst_heightmap[i] = src_heightmap[i]
	end

	local id = allocate_map_id ()
	map.ttl = MAP_TTL
	loaded_maps[id] = map
	write_map_data (id, map)
	return id, map
end

mcl_maps.copy_map_data = copy_map_data

function mcl_maps.lock_map_item (stack)
	local map_id = stack:get_meta ():get_string ("mcl_maps:map_id")
	local map = load_map_data (map_id)
	if not map then
		return nil
	end

	local id, dst = copy_map_data (map)
	if dst then
		local stack = ItemStack ("mcl_maps:map_locked")
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
					scaled:set_name ("mcl_maps:map_locked")
				end
				local inv = player:get_inventory ()
				if inv:room_for_item ("main", scaled) then
					inv:add_item ("main", scaled)
				else
					core.add_item (player:get_pos (), scaled)
				end
			end
		end
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
	local marker_def = table.copy (map_def)
	marker_def.alignment = { x = 0, y = 0 }
	local treasure_def = table.copy (marker_def)
	huds[player] = {
		map = player:hud_add (map_def),
		treasure = player:hud_add (treasure_def),
		marker = player:hud_add (marker_def),
		light = core.LIGHT_MAX,
	}
end)

core.register_on_leaveplayer(function(player)
	maps[player] = nil
	huds[player] = nil
end)

local function adjust_marker (player, id, img_arrow, img_dot, pos, minp, maxp)
	local marker = img_arrow

	if pos.x < minp.x then
		marker = img_dot
		pos.x = minp.x
	elseif pos.x > maxp.x then
		marker = img_dot
		pos.x = maxp.x
	end
	if pos.z < minp.z then
		marker = img_dot
		pos.z = minp.z
	elseif pos.z > maxp.z then
		marker = img_dot
		pos.z = maxp.z
	end

	if marker == "mcl_maps_player_arrow.png" then
		local dir = player:get_look_horizontal ()
		local yaw = (floor (dir * 180 / pi / 45 + 0.5) % 8) * 45

		if yaw == 0 or yaw == 90 or yaw == 180 or yaw == 270 then
			marker = "mcl_maps_player_arrow.png^[transformR"
				.. yaw
		else
			marker = "mcl_maps_player_arrow_diagonal.png^[transformR"
				.. (yaw - 45)
		end
	end
	if not marker then
		player:hud_change (id, "text", "blank.png")
		return
	end

	local light_overlay = "^[colorize:black:" .. 255 - (huds[player].light * 17)
	player:hud_change (id, "text", marker .. light_overlay)
	local f = 2 * 128 / (maxp.x - minp.x + 1)
	player:hud_change (id, "offset", {
		x = (pos.x - minp.x) * f - 128,
		y = (maxp.z - pos.z) * f - 264,
	})
end

function mcl_maps.clear_player_hud (player)
	local hud = huds[player]
	if hud then
		player:hud_change (hud.map, "text", "blank.png")
		player:hud_change (hud.marker, "text", "blank.png")
		player:hud_change (hud.treasure, "text", "blank.png")
		hud.wielditem = nil
		hud.last_texture = nil
		hud.last_map_id = nil
	end
end

mcl_player.register_globalstep (function (player)
	local wield = player:get_wielded_item ()
	local hud = huds[player]
	local texture, id

	if mcl_serverplayer.is_csm_at_least (player, 14) then
		return
	end

	if hud.wielditem and hud.wielditem:equals (wield) then
		texture = hud.last_texture
		id = hud.last_map_id
	else
		texture, id = mcl_maps.load_map_item (wield)
		hud.wielditem = wield
		hud.last_texture = texture
		hud.last_map_id = id

		local map_name = wield:get_name ()
		if texture and map_name ~= "mcl_maps:map_locked" then
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
		local eye_pos = mcl_util.target_eye_pos (player)
		local light = core.get_node_light (eye_pos) or 0
		if texture ~= maps[player] or light ~= hud.light then
			local light_overlay = "^[colorize:black:" .. 255 - (light * 17)
			local data = "[combine:140x140:0,0=mcl_maps_map_background.png\\^[resize\\:140x140:6,6="
				.. texture .. light_overlay
			player:hud_change (hud.map, "text", data)
			maps[player] = texture
			hud.light = light
		end

		local pos = mcl_util.get_nodepos (player:get_pos ())
		local width = lshift (MAP_SIDE_LENGTH, map.scale - 1)
		local minp = vector.new (map.x_start, 0, map.z_start)
		local maxp = vector.new (map.x_start + width - 1, 0,
					 map.z_start + width - 1)

		adjust_marker (player, hud.marker, "mcl_maps_player_arrow.png",
			       "mcl_maps_player_dot.png", pos, minp, maxp)
		if map.structure_pos then
			local def = wield:get_definition ()
			if def and def._treasure_symbol then
				adjust_marker (player, hud.treasure,
					       def._treasure_symbol,
					       nil, map.structure_pos,
					       minp, maxp)
			else
				player:hud_change (hud.treasure, "text", "blank.png")
			end
		else
			player:hud_change (hud.treasure, "text", "blank.png")
		end
	elseif maps[player] then
		player:hud_change(hud.map, "text", "blank.png")
		player:hud_change(hud.marker, "text", "blank.png")
		player:hud_change(hud.treasure, "text", "blank.png")
		maps[player] = nil
	end
end)

local function load_map_id (itemstack)
	local name = itemstack:get_name ()
	if core.get_item_group (name, "filled_map") > 0 then
		local id
		if core.get_item_group (name, "explorer_map") > 0 then
			local _
			id, _ = realize_explorer_map (itemstack)
			if not id then
				return nil
			end
		else
			local meta = itemstack:get_meta ()
			id = meta:get_string ("mcl_maps:map_id")
			if not id or id == "" then
				return nil
			end
		end
		return id
	end
end

mcl_maps.load_map_id = load_map_id

function mcl_maps.load_map_item (itemstack)
	local id = load_map_id (itemstack)
	if id then
		local map = load_map_data (id)

		if map then
			local png = core.encode_base64 (encode_map_png (map, 9))
			local tbl = {
				"(", modifier_escape ("blank.png^[png:" .. png), ")"
			}
			return table.concat (tbl), id
		end
	end
	return nil, nil
end

function mcl_maps.load_map_texture (id_or_map)
	local map

	if type (id_or_map) == "string" then
		map = load_map_data (id_or_map)
	else
		map = id_or_map
	end

	if map then
		-- This function may be invoked frequently during item
		-- frame initialization, during which high compression
		-- levels prove to be unduly expensive.
		local png = core.encode_base64 (encode_map_png (map, 3))
		return "blank.png^[png:" .. png
	end
	return nil
end

------------------------------------------------------------------------
-- Crafting and other sundries.
------------------------------------------------------------------------

core.register_craft ({
	output = "mcl_maps:map_empty",
	recipe = {
		{ "mcl_core:paper", "mcl_core:paper", "mcl_core:paper" },
		{ "mcl_core:paper", "mcl_compass:compass", "mcl_core:paper" },
		{ "mcl_core:paper", "mcl_core:paper", "mcl_core:paper" },
	}
})

-- Register recipes for cloning ordinary and locked maps.

for i = 2, 9 do
	local recipe = { "mcl_maps:map", }
	for j = 2, i do
		recipe[j] = "mcl_maps:map_empty"
	end
	core.register_craft ({
		type = "shapeless",
		output = "mcl_maps:map " .. i,
		recipe = recipe,
	})
	recipe[1] = "mcl_maps:map_locked"
	core.register_craft ({
		type = "shapeless",
		output = "mcl_maps:map_locked " .. i,
		recipe = recipe,
	})
end

-- Register recipe for scaling ordinary maps.

core.register_craft ({
	output = "mcl_maps:map",
	recipe = {
		{ "mcl_core:paper", "mcl_core:paper", "mcl_core:paper" },
		{ "mcl_core:paper", "mcl_maps:map", "mcl_core:paper" },
		{ "mcl_core:paper", "mcl_core:paper", "mcl_core:paper" },
	}
})

local function is_scaling_recipe (craft_grid)
	for i = 1, 9 do
		local desired = "mcl_core:paper"
		if i == 5 then
			desired = "mcl_maps:map"
		end
		if craft_grid[i]:get_name () ~= desired then
			return false
		end
	end

	return true
end

local function describe_map (start_x, start_z, scale)
	local compass = lshift (MAP_SIDE_LENGTH, scale - 1)
	local tbl = {
		S ("Displays area: (@1, @2) - (@3, @4)", start_x, start_z,
		   start_x + compass - 1, start_z + compass - 1), "\n",
		S ("Scale: @1x", lshift (1, scale - 1)),
	}
	return table.concat (tbl)
end

mcl_maps.describe_map = describe_map

local function on_craft (itemstack, _, old_craft_grid, _)
	local stack_name = itemstack:get_name ()
	if stack_name == "mcl_maps:map" then
		-- Does the old craft grid contain the recipe for
		-- scaling maps?
		if is_scaling_recipe (old_craft_grid) then
			local old_stack = old_craft_grid[5]
			local stack = mcl_maps.scale_map_item (old_stack)
			if stack then
				tt.reload_itemstack_description (stack)
			end
			return stack or itemstack
		end
	end

	if core.get_item_group (stack_name, "filled_map") > 0 then
		for _, stack in ipairs (old_craft_grid) do
			if stack:get_name () == stack_name then
				local meta = itemstack:get_meta()
				meta:from_table (stack:get_meta ():to_table ())
				tt.reload_itemstack_description (itemstack)
				return itemstack
			end
		end
	end
end

local function on_craft_predict (itemstack, _, old_craft_grid, _)
	local stack_name = itemstack:get_name ()
	if stack_name == "mcl_maps:map" then
		-- Does the old craft grid contain the recipe for
		-- scaling maps?
		if is_scaling_recipe (old_craft_grid) then
			local old_stack = old_craft_grid[5]
			local meta = old_stack:get_meta ()
			local id = meta:get_string ("mcl_maps:map_id")
			if not id or id == "" then
				return ItemStack ()
			end
			local map = load_map_data (id)
			if not map or map.scale >= MAX_MAP_SCALE then
				return ItemStack ()
			end
			local x_start, z_start
				= scale_map_origins (map.x_start,
						     map.z_start,
						     map.scale + 1)
			local description
				= core.colorize (mcl_colors.GRAY,
						 describe_map (x_start,
							       z_start,
							       map.scale + 1))
			local new_meta = itemstack:get_meta ()
			new_meta:set_string ("description", table.concat ({
				S ("Map"),
				"\n",
				description,
			}))
			return itemstack
		end
	end

	if core.get_item_group (stack_name, "filled_map") > 0 then
		for _, stack in ipairs (old_craft_grid) do
			if stack:get_name () == stack_name then
				local meta = itemstack:get_meta()
				meta:from_table (stack:get_meta ():to_table ())
				tt.reload_itemstack_description (itemstack)
				return itemstack
			end
		end
		tt.reload_itemstack_description (itemstack)
	end
end

core.register_on_craft (on_craft)
core.register_craft_predict (on_craft_predict)

tt.register_priority_snippet(function(itemstring, _, itemstack)
	if itemstack
		and core.get_item_group (itemstring, "filled_map") > 0
		and core.get_item_group (itemstring, "explorer_map") == 0 then
		local meta = itemstack:get_meta ()
		local id = meta:get_string ("mcl_maps:map_id")
		if id ~= "" then
			local map = load_map_data (id)
			if map then
				return describe_map (map.x_start, map.z_start,
						     map.scale), mcl_colors.GRAY
			end
		end
		return S ("Invalid map"), mcl_colors.RED
	end
end)

------------------------------------------------------------------------
-- Conversion of obsolete maps.
------------------------------------------------------------------------

dofile (modpath .. "/tgadec.lua")

local function convert_old_map (itemstack, placer, pointed_thing)
	local new_stack = mcl_util.call_on_rightclick (itemstack, placer,
						       pointed_thing)
	if new_stack then
		return new_stack
	end

	if placer and placer:is_valid () then
		local meta = itemstack:get_meta ()
		local old_map_id = meta:get_string ("mcl_maps:id")
		local old_minp = meta:get_string ("mcl_maps:minp")
		local pos = core.string_to_pos (old_minp)

		if old_map_id == "" or not pos then
			local msg = S ("This old map is invalid and cannot be converted.")
			core.chat_send_player (placer:get_player_name (), msg)
			return nil
		end
		local id = storage:get_string ("converted_map_" .. old_map_id)

		if not id or id == "" then
			local data_file = map_textures_path .. "mcl_maps_map_texture_"
				.. old_map_id .. ".tga"
			if not core.path_exists (data_file) then
				local msg = S ("The map data previously generated for this map does not exist.")
				core.chat_send_player (placer:get_player_name (), msg)
				return nil
			end

			local map = {
				x_start = pos.x,
				z_start = pos.z,
				dimension = mcl_worlds.pos_to_dimension (pos)
					or "none",
				scale = 1,
			}

			local file, _ = io.open (data_file, "rb")
			if not file then
				local msg = S ("Failed to open map file for conversion.")
				core.chat_send_player (placer:get_player_name (), msg)
				return nil
			end
			local data = file:read ("*all")
			file:close ()
			local ok, width, height, pixels
				= pcall (mcl_maps.get_targa_pixels, data)
			if not ok or width ~= MAP_SIDE_LENGTH or height ~= MAP_SIDE_LENGTH then
				local msg = S ("Format of existing map data is invalid: @1",
					       tostring (width))
				core.chat_send_player (placer:get_player_name (), msg)
				return nil
			end

			id = allocate_map_id ()
			map.ttl = MAP_TTL
			map.data = alloc_map_data ()
			map.heightmap = alloc_heightmap_data ()

			-- Write pixels into the updated map.
			local dst = map.data
			for z = 0, MAP_SIDE_LENGTH - 1 do
				local src_base = z * width + 1
				local dst_base = z * MAP_SIDE_LENGTH + 1
				for x = 0, MAP_SIDE_LENGTH - 1 do
					dst[dst_base + x] = pixels[src_base + x]
				end
			end
			loaded_maps[id] = map
			write_map_data (id, map)
			storage:set_string ("converted_map_" .. old_map_id, id)
		end

		itemstack:set_name ("mcl_maps:map_locked")
		meta:set_string ("mcl_maps:map_id", id)
		tt.reload_itemstack_description (itemstack)
		return itemstack
	end
end

core.register_alias ("mcl_maps:empty_map", "mcl_maps:map_empty")

core.register_craftitem ("mcl_maps:filled_map", {
	description = S ("Map (old)"),
	_tt_help = S ("This map is no longer supported.  Right click to convert it."),
	inventory_image = "mcl_maps_map_filled.png^mcl_maps_map_update_required.png",
	groups = {
		not_in_creative_inventory = 1,
		tool = 1,
	},
	on_place = convert_old_map,
	on_secondary_use = convert_old_map,
})

for _, skin_item in ipairs ({
	"mcl_maps:filled_map_character_male_surv",
	"mcl_maps:filled_map_character_female_surv",
	"mcl_maps:filled_map_character_male_crea",
	"mcl_maps:filled_map_character_female_crea",
	"mcl_maps:filled_map_hand",
}) do
	core.register_alias (skin_item, "mcl_maps:filled_map")
end

local list = mcl_skins.get_skin_list ()
for _, skin in pairs (list) do
	local name = "mcl_maps:filled_map_" .. skin.id
	if not core.registered_items[name] then
		core.register_alias (name, "mcl_maps:filled_map")
	end
end

core.register_chatcommand ("create_old_map", {
	description = S ("Obtain an old map with the provided ID."),
	privs = { server = true, },
	func = function (name, param)
		local player = core.get_player_by_name (name)
		if not player then
			return
		end

		if #param > 0 then
			local stack = ItemStack ("mcl_maps:filled_map")
			local meta = stack:get_meta ()
			meta:set_string ("mcl_maps:id", param)
			local pos = mcl_util.get_nodepos (player:get_pos ())
			pos.x = band (pos.x, -128)
			pos.y = band (pos.y, -128)
			pos.z = band (pos.z, -128)
			meta:set_string ("mcl_maps:minp",
					 core.pos_to_string (pos))
			local inv = player:get_inventory ()
			if inv:room_for_item ("main", stack) then
				inv:add_item ("main", stack)
			else
				core.add_item (player:get_pos (), stack)
			end
		end
	end
})
