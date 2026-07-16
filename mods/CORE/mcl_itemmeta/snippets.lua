local registered_snippets = {}

local function insert_with_priority(tbl, item)
	for i, other in ipairs(tbl) do
		if other.priority > item.priority then
			table.insert(tbl, i, item)
			return
		end
	end
	table.insert(tbl, item)
end

local function register_snippet(def)
	assert(def.priority)
	insert_with_priority(registered_snippets, def)
end
mcl_itemmeta.register_snippet = register_snippet

mcl_itemmeta.register_meta_modifier({
	modifies = "tooltip",
	priority = mcl_itemmeta.tooltip.SNIPPETS,
	func = function(itemstack, state)
		local parts = {state.content}
		for _, snippet in ipairs(registered_snippets) do
			local rendered_snippet = snippet.func(itemstack)
			if rendered_snippet then
				table.insert(parts, rendered_snippet)
			end
		end
		state.content = table.concat(parts, "\n")
	end
})

-- See https://minecraft.wiki/w/Tooltip
-- Many of the below are not applicable since they rely on player-specific
-- configuration which we can't support
mcl_itemmeta.snippet = {
	BUNDLE_CONTENTS = 200,
	CREATIVE_INV_TAB = 300,
	SMITHING_TEMPLATE = 400,
	PAINTING = 500,
	TROPICAL_FISH_PATTERN = 600,
	INSTRUMENT = 700,
	MAP_INFO = 800,
	BEES = 900,
	CONTAINER_ITEMS = 1000,
	BANNER_PATTERNS = 1100,
	DECORATED_POT_FACES = 1200,
	WRITTEN_BOOK = 1300,
	FLIGHT_DURATION = 1400,
	FIREWORK_EFFECTS = 1500,
	POTION_CONTENTS = 1600,
	MUSIC_DISC_NAME = 1700,
	ARMOR_TRIM = 1800,
	STORED_ENCHANTMENTS = 1900,
	ENCHANTMENTS = 2000,
	DYED_COLOR = 2100,
	LORE = 2200,
	ATTRIBUTE_MODIFIERS = 2300,
	UNBREAKABLE = 2400,
	SUS_STEW_EFFECTS = 2500,
	HONEY_LEVEL = 2600,
	PEACEFUL_DISABLED = 2700,
	SPAWNER = 2800,
	CAN_BREAK = 2900,
	CAN_PLACE_ON = 3000,
	DURABILITY = 3100,
	ITEM_ID = 3200,
	NUM_COMPONENTS = 3300,
	USAGE_WARNING = 3400,
}
