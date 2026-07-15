tt = {}
tt.COLOR_DEFAULT = mcl_colors.GREEN
tt.COLOR_DANGER = mcl_colors.YELLOW
tt.COLOR_GOOD = mcl_colors.GREEN
tt.NAME_COLOR = mcl_colors.YELLOW

-- API
tt.registered_snippets = {}

function tt.register_snippet(func)

	mcl_itemmeta.register_snippet({
		priority = 150,
		func = function(itemstack)
			local tool_capabilities = itemstack:get_tool_capabilities()
			local itemname = itemstack:get_name()
			local snippet, color = func(itemname, tool_capabilities, itemstack)
			if color == nil then
				color = tt.COLOR_DEFAULT
			end
			return (snippet and color) and core.colorize(color, snippet) or snippet
		end
	})
end

function tt.register_priority_snippet(func)
	tt.register_snippet(func)
end

dofile(core.get_modpath(core.get_current_modname()).."/snippets.lua")

function tt.reload_itemstack_description(itemstack)
	mcl_itemmeta.invalidate(itemstack, "tooltip")
end

-- FIXME: Remove, should rewrite any mods that use this to use the new system
mcl_itemmeta.register_meta_modifier({
	modifies = "tooltip",
	priority = mcl_itemmeta.tooltip.FINISH,
	func = function(itemstack, state)
		local generate = itemstack:get_definition()._mcl_generate_description
		if generate then
			generate(itemstack)
			state.content = itemstack:get_meta():get_string("description")
		end
	end
})
