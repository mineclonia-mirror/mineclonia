mcl_itemmeta = {}
local modpath = core.get_modpath(core.get_current_modname())
dofile(modpath .. "/computed.lua")
dofile(modpath .. "/default_modifiables.lua")

dofile(modpath .. "/tooltip.lua")
dofile(modpath .. "/snippets.lua")
dofile(modpath .. "/rarity.lua")
dofile(modpath .. "/itemname.lua")

dofile(modpath .. "/appearance.lua")

--[[
local registered_components = {}

local function make_component_accessor(def)
	local meta_key = def.meta_key
	local meta_deserialize = def.meta_deserialize
	local default_accessor = def.default_accessor
	return function(itemstack)
		local meta = itemstack:get_meta()
		local meta_value = meta:get_string(meta_key)
		return meta_value == "" and default_accessor(itemstack:get_name()) or meta_deserialize(meta_value)
	end
end

local function make_component_setter(def)
	local meta_key = def.meta_key
	local meta_deserialize = def.meta_deserialize
	local meta_serialize = def.meta_serialize
	local default_accessor = def.default_accessor
	return function(itemstack, value)
	end
end

local function register_component(name, def)
	registered_components[name] = {
	}
end
]]
