for _, s in ipairs({"1", "2", "3", "4", "locked"}) do
	core.register_alias("mesecons_delayer:delayer_off_"..s, "mcl_repeaters:repeater_off_"..s)
	core.register_alias("mesecons_delayer:delayer_on_"..s, "mcl_repeaters:repeater_on_"..s)
end
