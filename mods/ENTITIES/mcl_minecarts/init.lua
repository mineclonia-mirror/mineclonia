mcl_minecarts = {}

local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)

dofile(modpath .. DIR_DELIM .. "functions.lua")
dofile(modpath .. DIR_DELIM .. "api.lua")
dofile(modpath .. DIR_DELIM .. "rails.lua")
dofile(modpath .. DIR_DELIM .. "carts.lua")