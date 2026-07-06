mcl_itemframes = {}
mcl_itemframes.registered_nodes = {}
mcl_itemframes.registered_itemframes = {}

local fbox = {
	type = "fixed",
	fixed = {-6/16, -1/2, -6/16, 6/16, -7/16, 6/16}
}

local base_props = {
	visual = "wielditem",
	visual_size = {x = 0.3, y = 0.3},
	physical = false,
	pointable = false,
	textures = {"blank.png"},
	-- This was effectively true already.
	static_save = false,
}

local map_props = {
	visual = "upright_sprite",
	visual_size = {x = 1, y = 1},
	collide_with_objects = false,
	textures = {"blank.png"},
	_mcl_pistons_unmovable = true
}

mcl_itemframes.tpl_node = {
	drawtype = "mesh",
	is_ground_content = false,
	mesh = "mcl_itemframes_frame.obj",
	selection_box = fbox,
	collision_box = fbox,
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	sounds = mcl_sounds.node_sound_defaults(),
	node_placement_prediction = "",
	_mcl_hardness = 0.5,
	allow_metadata_inventory_move = function() return 0 end,
	allow_metadata_inventory_put = function() return 0 end,
	allow_metadata_inventory_take = function() return 0 end,
}

local tpl_groups = {
	dig_immediate = 3, deco_block = 1, dig_by_piston = 1,
	handy = 1, axey = 1, itemframe = 1, unsticky = 1,
	supported_node_wallmounted = 1, jigsaw_preserve_meta = 1,
	jigsaw_construct = 1,
}

mcl_itemframes.tpl_entity = {
	initial_properties = base_props,
	_mcl_fishing_hookable = true,
	_mcl_fishing_reelable = false,
	_mcl_pistons_unmovable = true,
}

-- Utility functions
local function find_entity(pos)
	for o in core.objects_inside_radius(pos, 0.45) do
		local l = o:get_luaentity()
		if l and l.name == "mcl_itemframes:item" then
			return l
		end
	end
end

local function find_or_create_entity(pos)
	local l = find_entity(pos)
	if not l then
		l = core.add_entity(pos, "mcl_itemframes:item"):get_luaentity()
	end
	return l
end

local function remove_entity(pos)
	local l = find_entity(pos)
	if l then
		l.object:remove()
	end
end
mcl_itemframes.remove_entity = remove_entity

local function drop_item(pos)
	local inv = core.get_meta(pos):get_inventory()
	core.add_item(pos, inv:get_stack("main", 1))
	inv:set_stack("main", 1, ItemStack(""))
	remove_entity(pos)
end

local load_map_id = mcl_maps.load_map_id

local function get_map_id (itemstack)
	return load_map_id (itemstack)
end

local function rotate_entity(pos, rot)
	local l = find_entity(pos)
	local meta = core.get_meta(pos)
	local itemstack = meta:get_inventory():get_stack("main", 1)
	local is_map = (get_map_id(itemstack) and 1 or 0)
	if l then
		l.object:set_rotation(vector.add(l.object:get_rotation(), vector.new(0, 0, 0.25 * math.pi * (rot or 1) * (is_map + 1))))
		meta:set_int("mcl_item_rotation", (meta:get_int("mcl_item_rotation") + (rot == nil and 1 or 0)) % 8)
		mcl_redstone.update_comparators(pos)
	end
end

local function update_entity(pos)
	if not pos then return end
	local meta = core.get_meta(pos)
	local inv = meta:get_inventory()
	local itemstack = inv:get_stack("main", 1)
	if not itemstack then
		remove_entity(pos)
		return
	end
	local itemstring = itemstack:get_name()
	local l = find_or_create_entity(pos)
	if not itemstring or itemstring == "" then
		remove_entity(pos)
		return
	end
	l:set_item(itemstack, pos)
	rotate_entity(pos, meta:get_int("mcl_item_rotation"))
	return l
end
mcl_itemframes.update_entity = update_entity

-- Node functions
function mcl_itemframes.tpl_node.on_rightclick(pos, _, clicker, ostack, _)
	local inv = core.get_meta(pos):get_inventory()
	if not inv:get_stack("main", 1):is_empty() then
		rotate_entity(pos)
		return ostack
	end
	local name = clicker:get_player_name()
	if core.is_protected(pos, name) then
		core.record_protection_violation(pos, name)
		return ostack
	end
	local pstack = ItemStack(ostack)
	local imeta = ostack:get_meta()
	local nmeta = core.get_meta(pos)
	nmeta:set_string("infotext", imeta:get_string("name"))
	nmeta:set_string ("mcl_itemframes:dynamic_map_id", "")
	nmeta:set_string ("mcl_itemframes:dynamic_map_texture", "")
	local itemstack = pstack:take_item()
	drop_item(pos)
	inv:set_stack("main", 1, itemstack)
	update_entity(pos)
	if not core.is_creative_enabled(clicker:get_player_name()) then
		return pstack
	end
	return ostack
end

mcl_itemframes.tpl_node.on_destruct = drop_item

function mcl_itemframes.tpl_node.on_construct(pos)
	if not mcl_structures.is_structure_constructor () then
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("main", 1)
	else
		local meta = core.get_meta (pos)
		local inv = meta:get_inventory ()
		if inv:get_size ("main") == 0 then
			inv:set_size ("main", 1)
		end
		update_entity (pos)
	end
end

function mcl_itemframes.tpl_node.on_rotate()
	return false
end

local function find_cached_map_texture (pos, dynamic_id)
	local meta = core.get_meta (pos)
	if meta:get_string ("mcl_itemframes:dynamic_map_id") == dynamic_id then
		return meta:get_string ("mcl_itemframes:dynamic_map_texture")
	else
		local texture = mcl_maps.load_map_texture (dynamic_id)
		meta:set_string ("mcl_itemframes:dynamic_map_id", dynamic_id)
		meta:set_string ("mcl_itemframes:dynamic_map_texture", texture)
		return texture
	end
end

-- Entity functions
function mcl_itemframes.tpl_entity:set_item(itemstack, pos)
	if not itemstack or not itemstack.get_name then
		self.object:remove()
		update_entity(pos)
		return
	end
	if pos then
		self._itemframe_pos = pos
	else
		pos = self._itemframe_pos
	end
	local ndef = core.registered_nodes[core.get_node(pos).name]
	if not ndef._mcl_itemframe then
		self.object:remove()
		update_entity()
		return
	end
	local prop_overrides
	local stackdef = itemstack:get_definition ()
	if stackdef and stackdef._on_set_item_entity then
		local s
		s, prop_overrides = stackdef._on_set_item_entity (itemstack, self)
		if s then
			itemstack = s
		end
	end
	local def = mcl_itemframes.registered_itemframes[ndef._mcl_itemframe]
	self._item = itemstack:get_name()
	self._stack = itemstack
	local id = get_map_id (itemstack)
	self._dynamic_map_id = id

	local dir = core.wallmounted_to_dir(core.get_node(pos).param2)
	self.object:set_pos(vector.add(pos, dir * 0.42))
	self.object:set_rotation(vector.dir_to_rotation(dir))

	local texture
	if self._dynamic_map_id then
		texture	= find_cached_map_texture (pos, self._dynamic_map_id)
	end
	if "mcl_maps:filled_map" == self._item then
		-- FIXME: this is the stupidest possible thing and not cached
		-- this case should really be handled in find_cached_map_texture()
		-- Should it be done using mcl_maps.load_map_item ?
		local worldpath = core.get_worldpath()
		local map_textures_path = worldpath .. "/mcl_maps/"
		local meta = itemstack:get_meta ()
		id = meta:get_string ("mcl_maps:id")
		local image_file = map_textures_path .. "mcl_maps_map_texture_"
				.. id .. ".tga"
		local file, _ = io.open (image_file, "rb")
		if not file then
			local msg = S ("Failed to open image file: " .. image_file)
			core.log ("error", msg)
			return nil, nil
		end
		image_payload = file:read ("*all")
		texture = "[png:" .. core.encode_base64 (image_payload)
	end
	print(texture)
	if texture then
		local props = table.merge (map_props, {
			textures = {
				"blank.png^" .. texture,
			},
		}, def.object_properties or {})
		self.object:set_properties (props)
		return
	end

	local idef = itemstack:get_definition()
	local ws = idef.wield_scale
	self.object:set_properties(table.merge(base_props, {
		wield_item = self._item,
		visual_size = {x = base_props.visual_size.x / ws.x, y = base_props.visual_size.y / ws.y},
	}, prop_overrides or {}, def.object_properties or {}))
end

function mcl_itemframes.tpl_entity:on_step(dtime)
	local def = core.registered_items[self._item]
	if def and def._on_entity_step then
		local r = def._on_entity_step(self, dtime, self._item)
		if type(r) == "string" then
			self._item = r
		end
	end
	self._timer = (self._timer and self._timer - dtime) or 1
	if self._timer > 0 then return end
	self._timer = 1
	if core.get_item_group(core.get_node(self._itemframe_pos).name, "itemframe") <= 0 then
		self.object:remove()
		return
	end
end

function mcl_itemframes.register_itemframe(name, def)
	if not def.node then return end
	local nodename = "mcl_itemframes:"..name
	table.insert(mcl_itemframes.registered_nodes, nodename)
	mcl_itemframes.registered_itemframes[name] = def
	core.register_node(":"..nodename, table.merge(mcl_itemframes.tpl_node, def.node, {
		_mcl_itemframe = name,
		groups = table.merge(tpl_groups, def.node.groups),
	}))
end

core.register_entity("mcl_itemframes:item", mcl_itemframes.tpl_entity)

core.register_lbm({
	label = "Respawn item frame item entities",
	name = "mcl_itemframes:respawn_entities",
	nodenames = {"group:itemframe"},
	run_at_every_load = true,
	action = update_entity,
})

local modpath = core.get_modpath(core.get_current_modname())
dofile(modpath .. "/register.lua")
