local fish_names = {
	"cod",
	"salmon",
	"tropical_fish",
	"axolotl",
	"pufferfish",
}

for _, name in ipairs(fish_names) do
	core.register_alias("mcl_fishing:bucket_"..name, "mcl_buckets:bucket_"..name)
end
