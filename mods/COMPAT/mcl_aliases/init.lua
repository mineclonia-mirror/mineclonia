local modpath = core.get_modpath(core.get_current_modname())

for _, name in ipairs({
	"doc_identifier",
	"mcl_armor",
	"mcl_armor_stand",
	"mcl_bamboo",
	"mcl_bells",
	"mcl_bows",
	"mcl_copper",
	"mcl_crimson",
	"mcl_doors",
	"mcl_dyes",
	"mcl_panes",
	"mcl_redstone",
	"mcl_stairs",
	"mcl_tools",
	"mcl_trees",
}) do
	dofile(modpath .. "/" .. name .. ".lua")
end
