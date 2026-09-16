local modpath = core.get_modpath(core.get_current_modname())

for _, name in ipairs({
	"mcl_armor",
	"mcl_bamboo",
	"mcl_copper",
	"mcl_crimson",
	"mcl_doors",
	"mcl_dyes",
	"mcl_panes",
	"mcl_stairs",
	"mcl_tools",
	"mcl_trees",
	"mesecons",
}) do
	dofile(modpath .. "/" .. name .. ".lua")
end
