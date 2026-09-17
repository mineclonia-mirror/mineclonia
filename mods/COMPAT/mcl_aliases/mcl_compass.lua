-- Aliases for obsolete compass items

local compass_frames = 32

for _, cmp in ipairs({
	"",
	"_lodestone",
	"_recovery"
}) do
	for i = 0, compass_frames - 1 do
		core.register_alias("mcl_compass:"..i..cmp, "mcl_compass:compass"..cmp)
	end
end
