local S = core.get_translator(core.get_current_modname())

local version_str = "(unknown)"
do
	local readme_path = core.get_game_info().path .. DIR_DELIM .. "README.md"
	local file = io.open(readme_path, "r")
	if file then
		local content = file:read("*a")
		file:close()

		local version = content:match("Version:%s*([%d%.]+)")
		if version then
			version_str = version
		end
	end
end

core.register_chatcommand("ver", {
	description = S("Displays the Mineclonia version"),
	params = "",
	privs = {},
	func = function(name)
		core.chat_send_player(name, "Mineclonia version: " .. version_str)
	end
})
