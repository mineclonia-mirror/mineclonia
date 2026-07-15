-- Allow items or nodes to be marked as WIP (Work In Progress) or Experimental

local S = core.get_translator(core.get_current_modname())

mcl_wip = {}
mcl_wip.registered_wip_items = {}
mcl_wip.registered_experimental_items = {}

function mcl_wip.register_wip_item(itemname)
	mcl_wip.registered_wip_items[itemname] = true --Only check for valid node name after mods loaded
end

function mcl_wip.register_experimental_item(itemname)
	mcl_wip.registered_experimental_items[itemname] = true
end

tt.register_snippet(function(itemname)
	local parts = {}
	if mcl_wip.registered_wip_items[itemname] then
		table.insert(parts, core.colorize(mcl_colors.RED, S("(WIP)")))
	end

	if mcl_wip.registered_experimental_items[itemname] then
		table.insert(parts, core.colorize(mcl_colors.YELLOW, S("(Temporary)")))
	end

	if #parts > 0 then
		return table.concat(parts, "\n"), false
	end
end)
