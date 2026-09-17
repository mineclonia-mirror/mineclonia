-- Backwards compatibility definitions

mcl_compass.stereotype = "mcl_compass:compass"

function mcl_compass.get_compass_itemname()
	mcl_util.log_deprecated_call("error")
	return mcl_compass.stereotype
end

function mcl_compass.get_compass_angle()
	mcl_util.log_deprecated_call("error")
	return 0
end
