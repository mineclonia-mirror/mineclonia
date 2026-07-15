mcl_itemmeta.register_modifiable("tooltip", {
	depends = {"itemname"},
	init = function(itemstack)
		return {content = itemstack:get_definition()._mcl_readable_name}
	end,
	set = function(itemstack, state)
		local def = itemstack:get_definition()
		itemstack:get_meta():set_string("description",
			state.content == def.description
			and ""
			or state.content
		)
	end
})

-- Override all of the definitions with readable name
mcl_autogroup.register_definition_override(function(name, def)
	core.override_item(name, {
		_mcl_readable_name = def.description
	})
end)

-- Set the description field of the definition to the "default" generated description
-- obtained when meta is empty. This is to save space because most items will have the same
-- description, therefore they won't need the description to be overridden in meta
mcl_autogroup.register_definition_override(function(name, _)
	local itemstack = ItemStack(name)
	local calculated_description = mcl_itemmeta.calculate_no_set(itemstack, "tooltip")
	core.override_item(name, {
		description = calculated_description.content,
	})
end)

mcl_itemmeta.tooltip = {
	ITEMNAME = 20050,
	CUSTOM_NAME = 20100,
	RARITY_COLOR = 20200,
	MCL_WIP = 20250,
	SNIPPETS = 20300,
	FINISH = 20900,
}

-- Show custom names
mcl_itemmeta.register_meta_modifier({
	modifies = "tooltip",
	priority = mcl_itemmeta.tooltip.CUSTOM_NAME,
	func = function(itemstack, state)
		local custom_name = itemstack:get_meta():get_string("name")
		if custom_name ~= "" then
			-- FIXME: This should be italicized, instead we are coloring it
			-- however this hides the rarity
			state.content = core.colorize(mcl_colors.AQUA, custom_name)
		end
	end
})

