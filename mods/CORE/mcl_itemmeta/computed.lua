---@class ModifiableDef<State>
---@field init fun(itemstack: ItemStack): State
---@field set fun(itemstack: ItemStack, value: State)

---@class MetaModifierDef
---@field modifies string
---@field priority number
---@field func fun(itemstack: ItemStack, values: table<string, any>)

local modifiables = {}
local modifiers_by_modifiable = {}

local function register_modifiable(name, def)
	-- TODO: checking
	modifiables[name] = def

	-- Modifiers may be registered before the corresponding modifiables
	modifiers_by_modifiable[name] = modifiers_by_modifiable[name] or {}
end
mcl_itemmeta.register_modifiable = register_modifiable

local function insert_with_priority(tbl, item)
	for i, other in ipairs(tbl) do
		if other.priority > item.priority then
			table.insert(tbl, i, item)
			return
		end
	end
	table.insert(tbl, item)
end

---@param def MetaModifierDef
local function register_meta_modifier(def)
	local modifiers_table = modifiers_by_modifiable[def.modifies]
	if not modifiers_table then
		-- Modifiers may be registered before the corresponding modifiables
		modifiers_table = {}
		modifiers_by_modifiable[def.modifies] = modifiers_table
	end
	-- TODO: checking
	assert(def.priority)
	insert_with_priority(modifiers_table, def)
end
mcl_itemmeta.register_meta_modifier = register_meta_modifier

local function invalidate(itemstack, modifiable)
	local modifiable_def = modifiables[modifiable]
	local state = modifiable_def.init(itemstack)
	for _, modifier in ipairs(modifiers_by_modifiable[modifiable]) do
		modifier.func(itemstack, state)
	end
	modifiable_def.set(itemstack, state)
end
mcl_itemmeta.invalidate = invalidate

local function invalidator(modifiable)
	return function(itemstack)
		invalidate(itemstack, modifiable)
	end
end
mcl_itemmeta.invalidator = invalidator

local function reload(itemstack)
	for modifiable, _ in pairs(modifiables) do
		invalidate(itemstack, modifiable)
	end
end
mcl_itemmeta.reload = reload

local function calculate_no_set(itemstack, modifiable)
	local modifiable_def = modifiables[modifiable]
	local state = modifiable_def.init(itemstack)
	for _, modifier in ipairs(modifiers_by_modifiable[modifiable]) do
		modifier.func(itemstack, state)
	end
	return state
end
mcl_itemmeta.calculate_no_set = calculate_no_set
