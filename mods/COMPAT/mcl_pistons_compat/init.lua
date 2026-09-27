-- convert old mesecons pistons to mcl_pistons
core.register_lbm(
{
	label = "update legacy mesecons pistons",
	name = "mcl_pistons_compat:replace_legacy_pistons",
	nodenames = {
		"mesecons_pistons:piston_normal_off",
		"mesecons_pistons:piston_up_normal_off",
		"mesecons_pistons:piston_down_normal_off",
		"mesecons_pistons:piston_normal_on",
		"mesecons_pistons:piston_up_normal_on",
		"mesecons_pistons:piston_down_normal_on",
		"mesecons_pistons:piston_pusher_normal",
		"mesecons_pistons:piston_up_pusher_normal",
		"mesecons_pistons:piston_down_pusher_normal",
		"mesecons_pistons:piston_sticky_off",
		"mesecons_pistons:piston_up_sticky_off",
		"mesecons_pistons:piston_down_sticky_off",
		"mesecons_pistons:piston_sticky_on",
		"mesecons_pistons:piston_up_sticky_on",
		"mesecons_pistons:piston_down_sticky_on",
		"mesecons_pistons:piston_pusher_sticky",
		"mesecons_pistons:piston_up_pusher_sticky",
		"mesecons_pistons:piston_down_pusher_sticky",
	},

	action = function(pos, node)
		local new_param2 = node.param2
		if string.find(node.name, "up") then
			new_param2 = core.dir_to_facedir(vector.new(0, -1, 0), true)
		elseif string.find(node.name, "down") then
			new_param2 = core.dir_to_facedir(vector.new(0, 1, 0), true)
		end

		local is_sticky = string.find(node.name, "sticky") and true or false
		local nodename = ""

		if string.find(node.name, "_on") then
			nodename = is_sticky and "mcl_pistons:piston_sticky_on" or "mcl_pistons:piston_on"
		elseif string.find(node.name, "_off") then
			nodename = is_sticky and "mcl_pistons:piston_sticky_off" or "mcl_pistons:piston_off"
		elseif string.find(node.name, "_pusher") then
			nodename = is_sticky and "mcl_pistons:piston_pusher_sticky" or "mcl_pistons:piston_pusher"
		end

		core.set_node(pos, {name = nodename, param2 = new_param2})
	end
})
