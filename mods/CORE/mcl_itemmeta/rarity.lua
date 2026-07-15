mcl_itemmeta.rarity = {}

local rarity_by_groupvalue = {}
local color_by_rarity = {}
local enchanted_upgrade = {}

-- Table of group value by capitalized rarity name
mcl_itemmeta.rarities = {}

local RARITY_KEY = "rarity"

local function register_rarity(name, def)
	assert(def.group_value)
	if rarity_by_groupvalue[def.group_value] then
		error("Rarity group value already registered: " .. def.group_value)
	end
	if color_by_rarity[name] then
		error("Rarity already registered: " .. name)
	end

	color_by_rarity[name] = def.color
	rarity_by_groupvalue[def.group_value] = name
	mcl_itemmeta.rarities[string.upper(name)] = def.group_value
	enchanted_upgrade[name] = def.enchanted_upgrade or name
end
mcl_itemmeta.rarity.register_rarity = register_rarity

local function get_rarity_from_group_value(group_value)
	return rarity_by_groupvalue[group_value]
end
mcl_itemmeta.rarity.from_group_value = get_rarity_from_group_value

local function get_default_rarity(itemname)
	return get_rarity_from_group_value(core.get_item_group(itemname, RARITY_KEY))
end
mcl_itemmeta.rarity.get_default = get_default_rarity

local function get_rarity(itemstack)
	local meta = itemstack:get_meta()
	local meta_rarity = meta:get_string(RARITY_KEY)
	if meta_rarity ~= "" then
		return meta_rarity
	else
		return get_default_rarity(itemstack:get_name())
	end
end
mcl_itemmeta.rarity.get = get_rarity

local function set_rarity(itemstack, rarity)
	if rarity == get_default_rarity(itemstack:get_name()) then return end
	itemstack:get_meta():set_string(RARITY_KEY, rarity)
end
mcl_itemmeta.rarity.set = set_rarity

local function upgrade_enchanted_rarity(rarity)
	return enchanted_upgrade[rarity]
end

register_rarity("common", {
	group_value = 0,
	color = nil,
	enchanted_upgrade = "rare"
})
register_rarity("uncommon", {
	group_value = 1,
	color = mcl_colors.YELLOW,
	enchanted_upgrade = "rare"
})
register_rarity("rare", {
	group_value = 2,
	color = mcl_colors.AQUA,
	enchanted_upgrade = "epic"
})
register_rarity("epic", {
	group_value = 3,
	color = mcl_colors.DARK_PURPLE
})

local function apply_rarity_color(str, rarity, is_enchanted)
	local effective_rarity = is_enchanted and upgrade_enchanted_rarity(rarity) or rarity
	local color = color_by_rarity[effective_rarity]
	return color and core.colorize(color_by_rarity[effective_rarity], str) or str
end
mcl_itemmeta.rarity.apply_rarity_color = apply_rarity_color

mcl_itemmeta.register_meta_modifier({
	modifies = "tooltip",
	priority = mcl_itemmeta.tooltip.RARITY_COLOR,
	func = function(itemstack, state)
		local readable_name = state.content
		local rarity = get_rarity(itemstack)
		local is_enchanted = mcl_enchanting and mcl_enchanting.is_enchanted(itemstack:get_name())
		state.content = apply_rarity_color(readable_name, rarity, is_enchanted)
	end
})
