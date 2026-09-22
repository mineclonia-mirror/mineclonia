local modpath = core.get_modpath(core.get_current_modname())

dofile(modpath.."/small.lua")
dofile(modpath.."/huge.lua")

mcl_levelgen.register_levelgen_script (modpath .. "/lg_register.lua")
