local storage = core.get_mod_storage()

-- Awards has historically used a format that stored all player
-- statistics (of all player who ever logged in) in one huge
-- json string.
-- This file is mainly concerned with converting this first
-- into per-player fields in modstorage one time.
-- Then as players log in the data is finally stored in player meta.

--converts from ancient awards.txt data storage directly to per-player modstorage
local function convert_from_txt(old_players)
	core.log("warning", "Importing awards data from previous version")

	for name, data in pairs(old_players) do
		while name.name do
			name = name.name
		end
		data.name = name
		print("Converting data for " .. name)

		-- Just rename counted
		local counted = {
			chats  = "chat",
			deaths = "death",
			joins  = "join",
		}
		for from, to in pairs(counted) do
			data[to]   = data[from]
			data[from] = nil
		end

		data.death = {
			unknown = data.death,
			__total = data.death,
		}

		-- Convert item db to new format
		local counted_items = {
			count = "dig",
			place = "place",
			craft = "craft",
		}
		for from, to in pairs(counted_items) do
			local ret = {}

			local count = 0
			if data[from] then
				for modname, items in pairs(data[from]) do
					for itemname, value in pairs(items) do
						itemname = modname .. ":" .. itemname
						local key = core.registered_aliases[itemname] or itemname
						ret[key] = value
						count = count + value
					end
				end
			end

			ret.__total = count
			data[from] = nil
			data[to] = ret
		end

		storage:set_string("player_data_"..name, core.write_json(data))
	end
end

-- universal conversion: either calls the above conversion from awards.txti
-- or alternatively if present converts the huge "unistring" json from modstorage
-- to per-player fields in modstorage.
local function migrate_old_data()
	local ms = storage:get("player_data")
	local old_save_path = core.get_worldpath().."/awards.txt"
	local file = io.open(old_save_path, "r")
	if ms and ms ~= "" then
		local all_data = core.parse_json(ms) or {}
		local i = 0
		for k, v in pairs(all_data) do
			i = i + 1
			storage:set_string("player_data_"..k, core.write_json(v))
		end
		storage:set_string("player_data_bk", ms)
		storage:set_string("player_data", "")
		core.log("warning", "[awards] "..tostring(i).." sets of player data were converted to per-player modstorage fields. A backup of the full string was saved in the player_data_bk modstorage field.")
	elseif file then
		local table = core.deserialize(file:read("*all"))
		if type(table) == "table" then
			convert_from_txt(table)
		end
		file:close()
		os.rename(old_save_path, core.get_worldpath().."/awards.bk.txt")
	end
end

-- this is called from on_joinplayer(data.lua) to do the final conversion step
-- for each player saving the data in player meta instead of modstorage.
function awards.compat_load(pl)
	local name = pl:get_player_name()
	local m = pl:get_meta()
	local ms = storage:get("player_data_"..name)
	if ms and ms ~= "" then
		m:set_string("awards:data", ms)
		storage:set_string("player_data_"..name, "") --delete the temporary per-player field - data is in playermeta now
		awards.load_player(pl)
		return true
	end
end

migrate_old_data()
