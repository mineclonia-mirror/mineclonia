-- old bed bottom halves
for color in pairs(mcl_dyes.colors) do
	core.register_alias("mcl_beds:bed_"..color, "mcl_beds:bed_"..color.."_bottom")
end

-- alias old non-uniform node names
core.register_alias("mcl_beds:bed_light_blue_top","mcl_beds:bed_lightblue_top")
core.register_alias("mcl_beds:bed_light_blue_bottom","mcl_beds:bed_lightblue_bottom")

-- antiques
core.register_alias("beds:bed_bottom", "mcl_beds:bed_red_bottom")
core.register_alias("beds:bed_top", "mcl_beds:bed_red_top")
