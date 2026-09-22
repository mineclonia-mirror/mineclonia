local bits = {
	["side"] =   {[0] = "100001", "100100", "100010", "101000", "101111"},
	["corner"] = {[0] = "101001", "100101", "100110", "101010", "101111"}
}

core.register_lbm({
	label = "Replace legacy mushroom cap blocks",
	name = "mcl_mushrooms_compat:replace_legacy_mushroom_caps",
	nodenames = {
		"mcl_mushrooms:brown_mushroom_block_cap_corner",
		"mcl_mushrooms:brown_mushroom_block_cap_side",
		"mcl_mushrooms:red_mushroom_block_cap_corner",
		"mcl_mushrooms:red_mushroom_block_cap_side"
	},
	action = function(pos, node)
		local prefix, affix = string.match(node.name, "^(.*_)(%w*)$")
		core.set_node(pos, {name = prefix..bits[affix][node.param2 <= 3 and node.param2 or 4]})
	end,
})
