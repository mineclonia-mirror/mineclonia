--[[
	mcl_leads,
	lead entity code reused from
	Minetest Leads mod by Silver Sandstone <@SilverSandstone@craftodon.social>
--]]

local modname = core.get_current_modname()
--local modpath = core.get_modpath(modname)
local S = core.get_translator(modname)
local MIN_BREAK_AGE = 1.0
local STRETCH_SOUND_INTERVAL = 2.0
local LEAD_MAX_LENGTH = 15
local PULL_FORCE = 25

local active_leads = {}

local function add_knot(pos)
	pos = pos:round();
	for __, object in ipairs(core.get_objects_in_area(pos, pos)) do
		local entity = object:get_luaentity()
		if entity and entity.name == "mcl_leads:knot" then
			return object
		end
	end

	return core.add_entity(pos, "mcl_leads:knot")
end

core.register_craftitem("mcl_leads:lead", {
	description = S("Lead"),
	_doc_items_longdesc = S("Leads can be used for moving and tethering animals. They can also be attached between two fences for decoration."),
	_doc_items_usagehelp = S("Right-click on an animal or fence to attach a lead. Punch the lead to release it, or right-click on a fence to tether it."),
	inventory_image = "leads_lead_inv.png",
	groups = { lead = 1 },
	on_place = function(itemstack, user, pointed_thing)
		if pointed_thing.type == "node" then
			local p = core.get_pointed_thing_position(pointed_thing)
			local n = core.get_node(p)
			if active_leads[user] and #active_leads[user] > 0 and core.get_item_group(n.name, "can_attach_lead") > 0 then
				local leadent = table.remove(active_leads[user])
				leadent.leader = add_knot(p)
				leadent.tied_to_node = true
				core.sound_play("leads_attach", {pos = p}, true)
			end
		end
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type == "object" then
			local mob = pointed_thing.ref:get_luaentity()
			if mob and mob.is_mob and mob.is_leadable then
				if not active_leads[user] then active_leads[user] = {} end
				local lead = core.add_entity(mob.object:get_pos(),"mcl_leads:lead_entity")
				local leadent = lead:get_luaentity()
				leadent.tied_to_node = false
				leadent.leader = user
				leadent.follower = pointed_thing.ref
				leadent.item = itemstack:get_name()
				leadent.max_length = LEAD_MAX_LENGTH
				leadent:update_visuals()
				table.insert(active_leads[user], leadent)
				core.sound_play("leads_attach", {pos = mob.object:get_pos()}, true)
			end
		end
	end,
})

core.register_craft({
	output = 'leads:lead';
	recipe =
	{
		{"mcl_mobitems:string", "mcl_mobitems:string", ""},
		{"mcl_mobitems:string", "mcl_mobitems:slimeball", ""},
		{"",   "",   "mcl_mobitems:string"},
	}
})

local lead_entity = {}
lead_entity.description = S'Lead'
lead_entity._leads_immobile = true
lead_entity.initial_properties = {
	visual	   = 'mesh',
	visual_size  = vector.new(0.5, 0.5, 0.5),
	mesh		 = 'leads_lead.obj',
	textures	 = {'leads_lead.png'},
	physical	 = false,
	selectionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
}

function lead_entity:on_activate(staticdata, dtime_s)
	self.current_length = 1
	self.max_length = LEAD_MAX_LENGTH
	self.rotation = vector.zero()
	self.leader_attach_offset = vector.zero()
	self.follower_attach_offset = vector.zero()
	self.age = 0.0
	self.sound_timer = 0.0

	local data = core.deserialize(staticdata)
	if data then
		self:load_from_data(data)
	end

	self.object:set_armor_groups{fleshy = 0}
end

function lead_entity:load_from_data(data)
	self.item = data.item or self.item
	self.max_length = data.max_length or self.max_length
	self.leader_id = data.leader_id or {}
	self.follower_id = data.follower_id or {}
	self.leader_id.pos   = vector.new(self.leader_id.pos)
	self.follower_id.pos = vector.new(self.follower_id.pos)
	self:update_visuals()
end

function lead_entity:on_step(dtime)
	self.age = self.age + dtime
	local success, pos, offset = self:step_physics(dtime)
	if success then
		self.current_length = math.max(offset:length(), 0.25)
		self.rotation = offset:dir_to_rotation()
		self.object:move_to(pos, true)
		self:update_visuals()
	end
end

function lead_entity:step_physics(dtime)
	local l_pos = self.leader:get_pos()
	local f_pos = self.follower:get_pos()
	if not (l_pos and f_pos) then
		self:break_lead()
		return false, nil, nil
	end

	l_pos = l_pos + self.leader_attach_offset
	f_pos = f_pos + self.follower_attach_offset

	local pull_distance = self.max_length
	local break_distance = pull_distance * 2
	local distance = l_pos:distance(f_pos)
	if distance > break_distance and self.age > MIN_BREAK_AGE then
		self:break_lead(nil, true)
		return false, nil, nil
	end

	local pos = (f_pos + l_pos) / 2
	if self.follower and distance > pull_distance then
		local force = (distance - pull_distance) * PULL_FORCE / pull_distance
		self.follower:add_velocity((l_pos - f_pos):normalize() * dtime * force)

		self.sound_timer = self.sound_timer + dtime
		if self.sound_timer >= STRETCH_SOUND_INTERVAL then
			self.sound_timer = self.sound_timer - STRETCH_SOUND_INTERVAL
			if math.random(8) == 1 then
				core.sound_play("leads_stretch", {pos = pos}, true)
			end
		end
	end
	return true, pos, f_pos - l_pos
end

function lead_entity:on_punch(puncher, time_from_last_punch, tool_capabilities, dir, damage)
	-- Check protection:
	--if leads.settings.respect_protection then
		local name = puncher and puncher:get_player_name() or ''
		for __, connector_id in ipairs{self.leader_id, self.follower_id} do
			if connector_id and connector_id.pos then
				local pos = vector.round(connector_id.pos)
				if core.is_protected(pos, name) then
					core.record_protection_violation(connector_id.pos, name)
					return true
				end
			end
		end
	--end


	self:break_lead(puncher)
	return true
end

--- Handles the lead being ‘killed’.
function lead_entity:on_death(killer)
	self:break_lead(killer)
end

--- Returns the lead's state as a table.
function lead_entity:get_staticdata()
	local data = {}
	data.item = self.item
	data.max_length = self.max_length
	data.leader_id = self.leader_id
	data.follower_id = self.follower_id
	return core.serialize(data)
end

function lead_entity:break_lead(breaker, snap)
	if self.item then
		--if not core.is_creative_enabled(owner:get_player_name()) then
		core.add_item(self.object:get_pos(),"mcl_leads:lead")
		--end
	end

	-- Play sound:
	if snap then
		core.sound_play("leads_break", {pos = self.object:get_pos()}, true)
	else
		core.sound_play("leads_remove", {pos = self.object:get_pos()}, true)
	end

	-- Remove lead:
	self.object:remove()
	self.item = nil
end

function lead_entity:update_visuals()
	local properties = {visual_size = vector.new(10, 10, 10 * self.current_length)}
	properties.selectionbox = {-0.0625, -0.0625, -self.current_length / 2,
									0.0625,  0.0625,  self.current_length / 2, rotate = true}
	self.object:set_properties(properties)
	self.object:set_rotation(self.rotation)
end

core.register_entity("mcl_leads:lead_entity", lead_entity)

knot_entity = {}

knot_entity.description = S("Lead Knot")

knot_entity._leads_immobile  = true
knot_entity._leads_leashable = true

knot_entity.initial_properties = {
	visual		  = 'mesh',
	visual_size	 = vector.new(10, 10, 10),
	mesh			= 'leads_lead_knot.obj',
	textures		= {'leads_lead_knot.png'},
	physical		= false,
	selectionbox	= {-3/16, -4/16, -3/16, 3/16, 4/16, 3/16},
}

function knot_entity:on_activate(staticdata, dtime_s)
	self.num_connections = 0

	local data = core.deserialize(staticdata)
	if data then
		self.num_connections = data.num_connections or 0
	end

	self.object:set_armor_groups{immortal = 1}
end

function knot_entity:on_step(dtime, moveresult)
	--if self.num_connections <= 0 then
	--	self.object:remove()
	--end
end

function knot_entity:get_staticdata()
	local data = {num_connections = self.num_connections}
	return core.serialize(data)
end

function knot_entity:on_punch(puncher, time_from_last_punch, tool_capabilities, dir, damage)

	local pos = self.object:get_pos():round()
	local name = puncher and puncher:get_player_name() or ''
	if core.is_protected(pos, name) then
		core.record_protection_violation(pos, name)
		return true
	end

	local break_leads = puncher and puncher:get_player_control().sneak
	local connected_leads
	if break_leads then
		connected_leads = {}
	else
		core.sound_play("leads_remove", {pos = self.object:get_pos()}, true)
	end


	if puncher then
		self:transfer_leads(puncher)
	end

	if break_leads then
		for __, lead in ipairs(connected_leads) do
			lead:get_luaentity():break_lead(puncher)
		end
	end

	self.object:remove()
	return true
end

function knot_entity:on_rightclick(clicker)
	--local pos = self.object:get_pos()
	--leads.knot(clicker, pos)
end

core.register_entity("mcl_leads:knot", knot_entity)
