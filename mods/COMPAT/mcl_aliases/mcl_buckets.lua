for _, name in ipairs({
	"axolotl",
	"cod",
	"pufferfish",
	"salmon",
	"tropical_fish",
}) do
	core.register_alias("mcl_fishing:bucket_"..name, "mcl_buckets:bucket_"..name)
end
