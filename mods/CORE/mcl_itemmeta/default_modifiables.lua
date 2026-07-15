
--[[
local function default_accessor(field)
	local function init(itemstack)
		return itemstack:get_definition()[field]
	end
	local function set(itemstack, value)
		local meta = itemstack:get_meta()
		if value == init(itemstack) then
			meta:set_string(field, "")
		else
			meta:set_string(field, value)
		end
	end

	return {
		init = init,
		set = set
	}
end
]]

--register_modifiable_field("description", default_accessor("description"))

