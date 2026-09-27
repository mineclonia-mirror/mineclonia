-- mcl_redstone rename aliases
for _, s in ipairs({
	"acacia",
	"bamboo",
	"birch",
	"cherry_blossom",
	"crimson",
	"dark_oak",
	"jungle",
	"mangrove",
	"oak",
	"spruce",
	"warped",
	"polished_blackstone",
	"stone"
}) do
	core.register_alias("mesecons_button:button_"..s.."_off", "mcl_buttons:button_"..s.."_off")
	core.register_alias("mesecons_button:button_"..s.."_on", "mcl_buttons:button_"..s.."_on")
end

--mcl_trees rename aliases
for o, n in pairs({
	["wood"] =		"oak",
	["sprucewood"] =	"spruce",
	["acaciawood"] =	"acacia",
	["junglewood"] =	"jungle",
	["birchwood"] =		"birch",
	["darkwood"] =		"dark_oak",
	["warped_hyphae"] =	"warped",
	["crimson_hyphae"] =	"crimson",
	["mangrove_wood"] =	"mangrove",
	["cherrywood"] =	"cherry_blossom",
}) do
	core.register_alias("mesecons_button:button_"..o.."_on","mcl_buttons:button_"..n.."_on")
	core.register_alias("mesecons_button:button_"..o.."_off","mcl_buttons:button_"..n.."_off")
end

core.register_alias("mesecons:button", "mesecons_button:button_off")
