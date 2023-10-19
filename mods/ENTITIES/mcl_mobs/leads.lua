--[[
	mcl_mobs,
	lead entity code reused from
	Minetest Leads mod by Silver Sandstone <@SilverSandstone@craftodon.social>
--]]

local mob_class = mcl_mobs.mob_class
local modname = core.get_current_modname()
--local modpath = core.get_modpath(modname)
local S = core.get_translator(modname)

local MIN_BREAK_AGE = 1.0
local STRETCH_SOUND_INTERVAL = 2.0
local LEAD_MAX_LENGTH = 10
local PULL_FORCE = 35

local player_leads = {}

local function add_knot(pos)
	pos = vector.round(pos)
	for __, object in pairs(core.get_objects_in_area(pos, pos)) do
		local entity = object:get_luaentity()
		if entity and entity.name == "mcl_mobs:knot" then
			return object
		end
	end
	return core.add_entity(pos, "mcl_mobs:knot")
end

local function drop_lead(pos)
	if pos then
		core.add_item(pos, "mcl_mobs:lead")
	end
end

function mob_class:attach_lead(obj)
	if self.is_leadable then
		local lead = core.add_entity(obj:get_pos(), "mcl_mobs:lead_entity")
		if lead and lead:get_pos() then
			local cb = self.object:get_properties().collisionbox or { 0,0,0,0,0,0 }
			local leadent = lead:get_luaentity()
			leadent.tied_to_node = true
			self.lead = lead
			leadent.leader = obj
			leadent.follower = self.object
			leadent.max_length = LEAD_MAX_LENGTH
			leadent.leader_attach_offset = vector.zero()
			leadent.follower_attach_offset = vector.new(0,cb[5] - 0.2 or 0.5,0)
			leadent:update_visuals()
			if obj:is_player() then
				if not player_leads[obj] then player_leads[obj] = {} end
				self.leader = obj:get_player_name()
				table.insert(player_leads[obj], leadent)
				leadent.tied_to_node = false
				leadent.leader_attach_offset = vector.new(0,1,0)
			else
				local knot = obj:get_luaentity()
				self.leader = nil
				self.tied_to_node = obj:get_pos()
				if knot then
					table.insert(knot.leads, leadent)
					leadent.leader_attach_offset = vector.new(0,0,0)
				else
					lead:remove()
				end
			end
			core.sound_play("leads_attach", {pos = self.object:get_pos()}, true)
			return leadent
		else
			core.log("no lead ent")
		end
	end
end

function mcl_mobs.transfer_lead_to_node(pos, player)
	local n = core.get_node(pos)
	if player_leads[player] and #player_leads[player] > 0 and core.get_item_group(n.name, "can_attach_lead") > 0 then
		local leadent = table.remove(player_leads[player])
		local knot = add_knot(pos)
		local l = leadent.follower:get_luaentity()
		if l then
			l:attach_lead(knot)
			leadent.object:remove()
			return true
		end
	end
end

function mob_class:check_lead(dtime)
	if not self.is_leadable then return end
	if not self.leader and not self.tied_to_node then return false end
	if self.lead and self.lead:get_pos() then
		if self.leader then
			local pl = core.get_player_by_name(self.leader)
			self:look_at(pl:get_pos())
		end
		return true
	end

	if self.tied_to_node then
		self:attach_lead(add_knot(self.tied_to_node))
	elseif self.leader then
		local pl = core.get_player_by_name(self.leader)
		if pl and pl:get_pos() then
			self:attach_lead(pl)
		end
	end
end

local lead_entity = {}
lead_entity.description = S("Lead")
lead_entity._leads_immobile = true
lead_entity.initial_properties = {
	visual	   = 'mesh',
	visual_size  = vector.new(0.5, 0.5, 0.5),
	mesh		 = 'mcl_mobs_lead.obj',
	textures	 = {'mcl_mobs_lead_entity.png'},
	physical	 = false,
	selectionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
}

function lead_entity:on_activate(staticdata, dtime_s)
	if staticdata == "remove" then
		self.object:remove() --mobs respawn their own lead
	end
	self.current_length = LEAD_MAX_LENGTH
	self.follower_attach_offset = vector.zero()
	self.leader_attach_offset = vector.zero()
end

function lead_entity:on_step(dtime)
	self.age = ( self.age or 0 ) + dtime
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
		self:remove()
		return false, nil, nil
	end

	l_pos = l_pos + self.leader_attach_offset
	f_pos = f_pos + self.follower_attach_offset

	local pull_distance = self.max_length
	local break_distance = pull_distance * 2
	local distance = l_pos:distance(f_pos)
	if distance > break_distance and self.age > MIN_BREAK_AGE then
		self:remove(nil, true)
		return false, nil, nil
	end

	local pos = (f_pos + l_pos) / 2
	if self.follower and distance > pull_distance then
		local pull_force = PULL_FORCE
		if not self.follower:get_luaentity().is_mob then
			pull_force = PULL_FORCE * 4
		end
		local force = (distance - pull_distance) * pull_force/ pull_distance
		self.follower:add_velocity((l_pos - f_pos):normalize() * dtime * force)

		self.sound_timer = ( self.sound_timer or 0 ) + dtime
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
	local name = puncher and puncher:get_player_name() or ''
	local pos = vector.round(self.leader:get_pos())
	if core.is_protected(pos, name) then
		core.record_protection_violation(pos, name)
		return
	end
	if not core.is_creative_enabled(name) then
		drop_lead(pos)
	end
	self:remove(puncher)
	return true
end

function lead_entity:on_death(killer)
	self:remove(killer)
end

function lead_entity:get_staticdata()
	return "remove"
end

function lead_entity:remove(breaker, snap)
	if not (breaker and breaker:is_player() and core.is_creative_enabled(breaker:get_player_name())) then
		drop_lead(self.object:get_pos())
	end

	if self.follower and self.follower:get_pos() then
		local l = self.follower:get_luaentity()
		l.lead = nil
		l.leader = nil
		l.tied_to_node = nil
	end

	if snap then
		core.sound_play("leads_break", {pos = self.object:get_pos()}, true)
	else
		core.sound_play("leads_remove", {pos = self.object:get_pos()}, true)
	end

	self.object:remove()
end

function lead_entity:update_visuals()
	local properties = {visual_size = vector.new(10, 10, 10 * self.current_length)}
	properties.selectionbox = {-0.4, -0.4, -0.4, 0.4, 0.4, 0.4, rotate = false}
	self.object:set_properties(properties)
	self.object:set_rotation(self.rotation or vector.zero())
end

local knot_entity = {
	initial_properties = {
		visual		  = 'mesh',
		visual_size	 = vector.new(10, 10, 10),
		mesh			= "mcl_mobs_lead_knot.obj",
		textures		= { "mcl_mobs_lead_knot.png" },
		physical		= false,
		selectionbox	= {-3/16, -4/16, -3/16, 3/16, 4/16, 3/16},
	},
}

knot_entity.description = S("Lead Knot")

knot_entity.leads = {}

function knot_entity:on_activate(staticdata, dtime_s)
	if staticdata == "remove" then self.object:remove() end
end

function knot_entity:remove(killer)
	for _,v in pairs(self.leads) do
		v:remove(killer)
	end
	self.object:remove()
end

function knot_entity:on_step(dtime)
	self.timer = (self.timer or 1) - dtime
	if self.timer > 0 then return end
	self.timer = 1
	local n = core.get_node(self.object:get_pos())
	if core.get_item_group(n.name, "can_attach_lead") == 0 or not self.leads or #self.leads == 0 then
		self:remove()
	end
end

function knot_entity:get_staticdata() return "remove" end

function knot_entity:on_punch(puncher, time_from_last_punch, tool_capabilities, dir, damage)
	local pos = self.object:get_pos():round()
	local name = puncher and puncher:get_player_name() or ''
	if core.is_protected(pos, name) then
		core.record_protection_violation(pos, name)
		return true
	end
	core.sound_play("leads_remove", {pos = self.object:get_pos()}, true)

	self:remove()
	return true
end

function knot_entity:on_rightclick(clicker)
	local pos = self.object:get_pos():round()
	local name = clicker and clicker:get_player_name() or ''
	if core.is_protected(pos, name) then
		core.record_protection_violation(pos, name)
		return true
	end
	if clicker and clicker:is_player() then
		if player_leads[clicker] and #player_leads[clicker] > 0 then
			return mcl_mobs.transfer_lead_to_node(pos, clicker)
		else
			local lead = table.remove(self.leads)
			if lead then
				local mob = lead.follower:get_luaentity()
				mob:attach_lead(clicker)
				lead.object:remove()
				if #self.leads < 1 then
					self:remove()
					return
				end
			end
		end
	end
end

core.register_craftitem("mcl_mobs:lead", {
	description = S("Lead"),
	_doc_items_longdesc = S("Leads can be used for moving and tethering animals. They can also be attached between two fences for decoration."),
	_doc_items_usagehelp = S("Right-click on an animal or fence to attach a lead. Punch the lead to release it, or right-click on a fence to tether it."),
	inventory_image = "mcl_mobs_lead_inv.png",
	groups = { lead = 1 },
	on_place = function(itemstack, user, pointed_thing)
		local rc = mcl_util.call_on_rightclick(itemstack, user, pointed_thing)
		if rc then return rc end
		if pointed_thing.type == "node" then
			mcl_mobs.transfer_lead_to_node(pointed_thing.under, user)
		end
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type == "object" then
			local l = pointed_thing.ref:get_luaentity()
			if l and l.is_mob then
				l:attach_lead(user)
			end
		end
	end,
})

core.register_craft({
	output = "mcl_mobs:lead";
	recipe =
	{
		{"mcl_mobitems:string", "mcl_mobitems:string", ""},
		{"mcl_mobitems:string", "mcl_mobitems:slimeball", ""},
		{"",   "",   "mcl_mobitems:string"},
	}
})

core.register_entity("mcl_mobs:lead_entity", lead_entity)
core.register_entity("mcl_mobs:knot", knot_entity)
