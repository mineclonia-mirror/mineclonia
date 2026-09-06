local pairs = pairs

local rshift = bit.rshift
local band = bit.band

local concat = table.concat
local insert = table.insert
local char = string.char

local encode_base255 = mcl_serverplayer.encode_base255

------------------------------------------------------------------------
-- Client-side cartography data management.
------------------------------------------------------------------------

local send_map_metadata = mcl_serverplayer.send_map_metadata
local send_map_data_packet = mcl_serverplayer.send_map_data_packet
local send_map_data_finish = mcl_serverplayer.send_map_data_finish
local send_map_data_update = mcl_serverplayer.send_map_data_update

local MAP_DATA_LENGTH = mcl_maps.MAP_DATA_LENGTH
local MAP_SIZE = MAP_DATA_LENGTH * MAP_DATA_LENGTH
local N = mcl_maps.N
local UPDATE_SIZE = N * MAP_DATA_LENGTH

local function serialize_argb_data (dst, list, size)
	for i = 1, size do
		local value = list[i]
		local b0 = band (value, 0xff)
		local b1 = rshift (band (value, 0xff00), 8)
		local b2 = rshift (band (value, 0xff0000), 16)
		local b3 = rshift (band (value, 0xff000000), 24)
		dst[i * 4 - 3] = char (b0)
		dst[i * 4 - 2] = char (b1)
		dst[i * 4 - 1] = char (b2)
		dst[i * 4] = char (b3)
	end
end

local function serialize_map_data (dst, list)
	return serialize_argb_data (dst, list, MAP_SIZE)
end

local dst = {}
local MAX_MAP_DATA_LENGTH = mcl_serverplayer.MAX_MAP_DATA_LENGTH

local function send_map_to_player (player, id, map, encoded_map)
	serialize_map_data (dst, encoded_map)
	local compressed_string
		= core.compress (concat (dst), "zstd")
	local encoded_string = encode_base255 (compressed_string)
	local meta = {
		id = id,
		x_start = map.x_start,
		z_start = map.z_start,
		scale = map.scale,
		dimension = map.dimension,
	}

	if map.structure_pos then
		-- The Y position of the structure is not to be
		-- declared to clients.
		meta.structure_x = map.structure_pos.x
		meta.structure_z = map.structure_pos.z
	end

	send_map_metadata (player, meta)

	-- Send the encoded map data.
	local len = #encoded_string
	for i = 1, len, MAX_MAP_DATA_LENGTH do
		local rem = len - i + 1

		if rem > MAX_MAP_DATA_LENGTH then
			local str_end = i + MAX_MAP_DATA_LENGTH - 1
			local substr = encoded_string:sub (i, str_end)
			send_map_data_packet (player, id, substr)
		else
			local substr = encoded_string:sub (i, len)
			send_map_data_finish (player, id, substr)
		end
	end
end

------------------------------------------------------------------------
-- Server-side cartography data management.
------------------------------------------------------------------------

function mcl_serverplayer.request_cartographic_map_data (player, state, payload)
	if payload == "" then
		state.requested_map_id = nil
		state.requested_explorer_map_id = nil
		state.outstanding_map_request = false
	else
		state.requested_map_id = payload
		state.requested_explorer_map_id = nil
		state.outstanding_map_request = true
	end
end

function mcl_serverplayer.request_explorer_map_data (player, state, payload)
	local id = tonumber (payload)
	if not id then
		error ("Invalid payload for ServerboundRequestExplorerMapData: " .. payload)
	end
	state.requested_map_id = nil
	state.requested_explorer_map_id = id
	state.outstanding_map_request = true
end

function mcl_serverplayer.step_maps (state, player, dtime)
	local wielditem = player:get_wielded_item ()
	local meta = wielditem:get_meta ()
	local name = wielditem:get_name ()

	-- Load the IDs to be compared against the outstanding map
	-- request.
	local id, explorer_map_id
	if core.get_item_group (name, "explorer_map") > 0 then
		explorer_map_id = meta:get_int ("mcl_maps:explorer_map_id")
		if explorer_map_id == 0 then
			explorer_map_id = nil
		end
	elseif core.get_item_group (name, "filled_map") > 0 then
		id = meta:get_string ("mcl_maps:map_id")
		if id == "" then
			id = nil
		end
	end

	local any_match = (state.requested_map_id == id
			   and state.requested_explorer_map_id == explorer_map_id)
	if state.outstanding_map_request and any_match then
		local map_id = mcl_maps.load_map_id (wielditem)
		if not map_id then
			return
		end
		local map = mcl_maps.load_map_data (map_id)
		if not map then
			return
		end

		-- Send the map to the player and clear this request.
		local encoded = mcl_maps.convert_map_data (map)
		local id = tostring (id or explorer_map_id)
		send_map_to_player (player, id, map, encoded)
		state.outstanding_map_request = false
	elseif not state.outstanding_map_request
		and not any_match
		and (state.requested_map_id or state.requested_explorer_map_id) then
		-- Cancel this request till the client is entitled to
		-- access the map again.
		state.outstanding_map_request = true
	end
end

------------------------------------------------------------------------
-- Map update delivery.
------------------------------------------------------------------------

local client_states = mcl_serverplayer.client_states
local dst = {}

local function maybe_send_map_update (player, state, map, key, rows,
				      encoded_updates)
	if not state.proto -- The connection may have yet to be
			   -- initialized.
		or state.proto < 14
		or state.outstanding_map_request then
		-- Maps aren't supported or the client has not yet
		-- received the desired map.
		return false
	end

	local requested_map_id = state.requested_map_id
	local requested_explorer_map_id
		= state.requested_explorer_map_id
	if not requested_explorer_map_id and not requested_map_id then
		return false
	end
	local requested_key = tostring (requested_explorer_map_id
					or requested_map_id)
	if requested_key ~= key then
		-- A different map is being observed by this client.
		return false
	end

	-- Encode and send this update.
	if encoded_updates[key] then
		send_map_data_update (player, key, rows, encoded_updates[key])
		return true
	end
	local update = mcl_maps.encode_map_update (map, rows)
	serialize_argb_data (dst, update, UPDATE_SIZE)
	local encoded = encode_base255 (concat (dst))
	encoded_updates[key] = encoded
	send_map_data_update (player, key, rows, encoded)
	return true
end

function mcl_serverplayer.send_cartography_updates (updates, rows)
	local encoded_updates = {}
	for player, state in pairs (client_states) do
		for map, key in pairs (updates) do
			if maybe_send_map_update (player, state,
						  map, key, rows,
						  encoded_updates) then
				break
			end
		end
	end
end

------------------------------------------------------------------------
-- Protocol initialization.
------------------------------------------------------------------------

local explorer_map_items = {}
local cartographic_map_items = {}

core.register_on_mods_loaded (function ()
	for k, def in pairs (core.registered_items) do
		if def.groups.explorer_map
			and def.groups.explorer_map > 0 then
			insert (explorer_map_items, {
				k, def._treasure_symbol,
			})
		elseif def.groups.filled_map
			and def.groups.filled_map > 0 then
			insert (cartographic_map_items, k)
		end
	end
end)

mcl_serverplayer.explorer_map_items = explorer_map_items
mcl_serverplayer.cartographic_map_items = cartographic_map_items
