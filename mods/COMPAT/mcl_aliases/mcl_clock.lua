-- Register aliases for old clock items
local clock_frames = 64

for a = 0, clock_frames - 1 do
	core.register_alias("mcl_clock:clock_"..tostring(a), "mcl_clock:clock")
end
