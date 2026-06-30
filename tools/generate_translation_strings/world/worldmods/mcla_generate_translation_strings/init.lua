--luacheck: globals mcla_generated_translations
core.after(1, function()
	if core.global_exists("mcla_generated_translations") then
		local wp = core.get_worldpath().."/mcla_translate"
		core.mkdir(wp)
		local filename_dirs = wp.."/mod_dirs.txt"
		local file_dirs, _ = io.open(filename_dirs, "w")

		for modname, stringset in pairs(mcla_generated_translations) do
			local filename_mod = wp.."/"..modname.."_translations_tmp.lua"
			local file, _ = io.open(filename_mod, "w")
			file_dirs:write(core.get_modpath(modname).." "..modname.."_translations_tmp.lua\n")
			local strings = {}
			for string, _ in pairs(stringset) do
				table.insert(strings, string)
			end
			table.sort(strings)
			for _, str in ipairs(strings) do
				file:write("NS(" .. dump(str) .. ")\n")
			end
			file:close()
		end
		file_dirs:close()
	end
	core.request_shutdown()
end)
