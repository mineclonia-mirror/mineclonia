for _,v in pairs({"","_exposed","_weathered"}) do
	core.register_alias("mcl_copper:waxed_block"..v,"mcl_copper:block"..v.."_preserved")
	core.register_alias("mcl_copper:waxed_block"..v.."_cut","mcl_copper:block"..v.."_cut_preserved")
end

core.register_alias("mcl_copper:waxed_block_oxidized","mcl_copper:block_oxidized")
core.register_alias("mcl_copper:waxed_block_oxidized_cut","mcl_copper:block_oxidized_cut")
