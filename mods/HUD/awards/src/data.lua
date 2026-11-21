--local storage = core.get_mod_storage()
local __player_data = {}

-- Table Save Load Functions
function awards.save_player(pl)
	local name = pl:get_player_name()
	local m = pl:get_meta()
	m:set_string("awards:data", core.write_json(__player_data[name]))
end

function awards.save()
	for pl in mcl_util.connected_players() do
		awards.save_player(pl)
	end
end

--[[
local function convert_data()
	core.log("warning", "Importing awards data from previous version")

	local old_players = __player_data
	__player_data = {}
	for name, data in pairs(old_players) do
		while name.name do
			name = name.name
		end
		if type(name) == "string" then
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

			__player_data[name] = data
		end
	end
end
--]]

function awards.load_player(pl)
	local m = pl:get_meta()
	local name = pl:get_player_name()
	local s =core.parse_json(m:get_string("awards:data"))
	if not __player_data then
		__player_data = {}
	end
	__player_data[name] = (s ~= "" and s) or {}
end

function awards.unload_player(pl)
	local name = pl:get_player_name()
	awards.save_player(pl)
	__player_data[name] = nil
end

function awards.load()
	for pl in mcl_util.connected_players() do
		awards.load_player(pl)
	end
end

function awards.player(name)
	assert(type(name) == "string")
	local data = __player_data[name] or {}
	__player_data[name] = data

	data.name     = data.name or name
	data.unlocked = data.unlocked or {}
	return data
end

function awards.player_or_nil(name)
	return __player_data[name]
end

function awards.enable(name)
	awards.player(name).disabled = nil
end

function awards.disable(name)
	awards.player(name).disabled = true
end

function awards.clear_player(name)
	__player_data[name] = {}
	awards.save_player(core.get_player_by_name(name))
end

core.register_on_joinplayer(function(pl)
	awards.load_player(pl)
end)

core.register_on_leaveplayer(function(pl)
	awards.unload_player(pl)
end)
