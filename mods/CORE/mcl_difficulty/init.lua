local S = core.get_translator("mcl_difficulty")

mcl_difficulty = {
	difficulties = {
		"peaceful",
		"easy",
		"normal",
		"hard",
	},
	registered_on_difficulty_change = {}
}

local difficulty_aliases = {
	["0"] = "peaceful",
	["1"] = "easy",
	["2"] = "normal",
	["3"] = "hard",
	["p"] = "peaceful",
	["e"] = "easy",
	["n"] = "normal",
	["h"] = "hard",
}

function mcl_difficulty.register_on_difficulty_change(func)
	table.insert(mcl_difficulty.registered_on_difficulty_change, func)
end

local world_settings = Settings(core.get_worldpath() .. "/world.mt")

function mcl_difficulty.get_difficulty()
	return world_settings:get("mcl_difficulty") or core.settings:get("mcl_difficulty")
end

function mcl_difficulty.set_difficulty(d)
	if table.indexof(mcl_difficulty.difficulties, d) == -1 then return false end
	local old_d = mcl_difficulty.get_difficulty()
	world_settings:set("mcl_difficulty", d)
	world_settings:write()
	for _, func in ipairs(mcl_difficulty.registered_on_difficulty_change) do
		func(old_d, d)
	end
	return true
end

core.register_chatcommand("difficulty", {
	params = S("[<difficulty>]"),
	description = S("Change difficulty (peaceful/easy/normal/hard/0/1/2/3/p/e/n/h)"),
	privs = { server = true },
	func = function(_, param)
		local args = param:split(" ")

		local d = difficulty_aliases[args[1]] or args[1]
		if d and mcl_difficulty.set_difficulty(d) == false then
			return false, S("Failed to set difficulty @1", d)
		end

		--Result message - show effective difficulty
		return true, S("Difficulty: @1", mcl_difficulty.get_difficulty())
	end
})

local function set_mcl_vars_difficulty(_, difficulty)
	-- Difficulty.  Peaceful is 0, normal is 1,
	if difficulty == "peaceful" then
		mcl_vars.difficulty = 0
	elseif difficulty == "easy" then
		mcl_vars.difficulty = 1
	elseif difficulty == "normal"
		or not difficulty
		or difficulty == "" then
		mcl_vars.difficulty = 2
	elseif difficulty == "hard" then
		mcl_vars.difficulty = 3
	else
		mcl_vars.difficulty = 2
		core.log ("warning", "mcl_difficulty is configured to an unknown value " .. difficulty)
	end
end

mcl_difficulty.register_on_difficulty_change(set_mcl_vars_difficulty)

set_mcl_vars_difficulty(nil, mcl_difficulty.get_difficulty())
