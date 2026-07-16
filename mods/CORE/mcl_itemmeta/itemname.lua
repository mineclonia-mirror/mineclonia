mcl_itemmeta.readable_name = {}

local READABLE_NAME_KEY = "itemname"

local function get_default_readable_name(itemname)
	local def = core.registered_items[itemname]
	return def._mcl_readable_name or def.description
end
mcl_itemmeta.readable_name.get_default = get_default_readable_name

local function get_readable_name(itemstack)
	local meta = itemstack:get_meta()
	local meta_readable_name = meta:get_string(READABLE_NAME_KEY)
	return meta_readable_name == "" and get_default_readable_name(itemstack:get_name()) or meta_readable_name
end
mcl_itemmeta.readable_name.get = get_readable_name

local function set_readable_name(itemstack, readable_name)
	if readable_name == get_default_readable_name(itemstack:get_name()) then return end
	itemstack:get_meta():set_string(READABLE_NAME_KEY, readable_name)
end
mcl_itemmeta.readable_name.set = set_readable_name

-- Below "itemname" is a modifiable in itself, which is transferred to
-- the tooltip in a "tooltip" modifier
-- The only problem with this pattern is that itemname is updated twice
-- when mcl_itemmeta.reload is run

mcl_itemmeta.register_modifiable("itemname", {
	init = function(itemstack)
		return {
			name = get_default_readable_name(itemstack:get_name())
		}
	end,
	set = function(itemstack, state)
		set_readable_name(itemstack, state.name)
	end
})

mcl_itemmeta.register_meta_modifier({
	modifies = "tooltip",
	priority = mcl_itemmeta.tooltip.ITEMNAME,
	func = function(itemstack, state)
		mcl_itemmeta.invalidate(itemstack, "itemname")
		state.content = get_readable_name(itemstack)
	end,
})

mcl_itemmeta.itemname = {
	BASE = 0,
	MCL_POTIONS = 100,
}
