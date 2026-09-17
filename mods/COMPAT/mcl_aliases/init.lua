local modpath = core.get_modpath(core.get_current_modname())

for _, name in ipairs({
	"doc_identifier",
	"mcl_armor",
	"mcl_armor_stand",
	"mcl_bamboo",
	"mcl_bells",
	"mcl_boats",
	"mcl_bows",
	"mcl_brewing",
	"mcl_copper",
	"mcl_crafting_table",
	"mcl_crimson",
	"mcl_doors",
	"mcl_dyes",
	"mcl_fences",
	"mcl_flowerpots",
	"mcl_monster_eggs",
	"mcl_panes",
	"mcl_pressureplates",
	"mcl_redstone",
	"mcl_signs",
	"mcl_stairs",
	"mcl_tools",
	"mcl_trees",
}) do
	dofile(modpath .. "/" .. name .. ".lua")
end
