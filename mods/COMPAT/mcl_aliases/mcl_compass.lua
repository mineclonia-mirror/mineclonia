-- Aliases for obsolete compass items

local compass_frames = 32

for cmp, fmt in pairs({
	[""] = "",
	["lodestone_"] = "_lodestone",
	["recovery_"] = "_recovery",
}) do
	for i = 0, compass_frames - 1 do
		core.register_alias(string.format("mcl_compass:%d"..fmt, i), "mcl_compass:"..cmp.."compass")
	end
end
