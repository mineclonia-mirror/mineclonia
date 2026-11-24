local __player_data = {}

-- Table Save Load Functions
function awards.save_player(pl)
	local name = pl:get_player_name()
	local m = pl:get_meta()
	m:set_string("awards:data", core.write_json(__player_data[name]))
end

function awards.load_player(pl)
	if awards.compat_load(pl) then return end
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

function awards.save()
	for pl in mcl_util.connected_players() do
		awards.save_player(pl)
	end
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
