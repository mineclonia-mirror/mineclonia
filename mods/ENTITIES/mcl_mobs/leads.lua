--[[
	mcl_mobs,
	lead entity code reused from
	Minetest Leads mod by Silver Sandstone <@SilverSandstone@craftodon.social>
--]]

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

local function attach_lead(self, obj, lead)
	-- can't attach more than one lead to a mob
	if self.is_leadable and self.lead and not lead then return end
	if self.is_leadable or self.is_knot then
		local new_lead = not lead
		local led_pos = self.object:get_pos()
		local leader_pos = obj:get_pos()
		lead = lead or core.add_entity(leader_pos, "mcl_mobs:lead_entity")
		if lead and lead:get_pos() then
			local leadent = lead:get_luaentity()
			leadent.max_length = LEAD_MAX_LENGTH
			-- lead properties of follower side already set up for
			-- existing lead, especially the lead is already added
			-- to knot's table and adding it twice would be bad
			if new_lead then
				leadent.follower = self.object
				if self.is_leadable then
					self.lead = lead
					local cb = self.object:get_properties().collisionbox or { 0,0,0,0,0,0 }
					leadent.follower_attach_offset = vector.new(0,cb[5] - 0.2 or 0.5,0)
				else
					table.insert(self.leads, leadent)
					leadent.follower_attach_offset = vector.zero()
				end
			end
			leadent.leader = obj
			if obj:is_player() then
				if not player_leads[obj] then player_leads[obj] = {} end
				table.insert(player_leads[obj], leadent)
				leadent.leader_attach_offset = vector.new(0,1,0)
				if self.is_leadable then
					self.leader = obj:get_player_name()
				end
			else
				local knot = obj:get_luaentity()
				table.insert(knot.leads, leadent)
				leadent.leader_attach_offset = vector.zero()
				self.leader = nil
				self.tied_to_node = leader_pos
			end
			leadent:update_visuals()
			core.sound_play("leads_attach", {pos = led_pos}, true)
			return leadent
		else
			core.log("no lead ent")
		end
	end
end

function mcl_mobs.transfer_lead_to_node(pos, player, stack)
	local n = core.get_node(pos)
	if core.get_item_group(n.name, "can_attach_lead") > 0 then
		if player_leads[player] and #player_leads[player] > 0 then
			local leadent = table.remove(player_leads[player])
			local l = leadent.follower:get_luaentity()
			if l then
				attach_lead(l, add_knot(pos), leadent.object)
			end
		elseif stack:get_name() == "mcl_mobs:lead" then
			attach_lead(add_knot(pos):get_luaentity(), player)
			if not core.is_creative_enabled(player:get_player_name()) then
				stack:take_item()
			end
		end
	end

	return stack
end

-- leads are not persistent and get respawned when the leadable object gets reloaded
function mcl_mobs.check_lead(self)
	if not self.is_leadable then return end
	if not self.leader and not self.tied_to_node then return false end
	if self.lead and self.lead:get_pos() then
		if self.leader and self.is_mob then
			local pl = core.get_player_by_name(self.leader)
			self:look_at(pl:get_pos())
		end
		return true
	end

	if self.tied_to_node then
		attach_lead(self, add_knot(self.tied_to_node))
	elseif self.leader then
		local pl = core.get_player_by_name(self.leader)
		if pl and pl:get_pos() then
			attach_lead(self, pl)
		end
	end
end

local lead_entity = {}
lead_entity.description = S("Lead")
lead_entity.initial_properties = {
	static_save = false,
	visual	   = 'mesh',
	visual_size  = vector.new(0.5, 0.5, 0.5),
	mesh		 = 'mcl_mobs_lead.obj',
	textures	 = {'mcl_mobs_lead_entity.png'},
	physical	 = false,
	selectionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
}

function lead_entity:on_activate(staticdata, dtime_s)
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
	local l_pos = self.leader and self.leader:get_pos() or self.tied_to_node
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
			pull_force = PULL_FORCE * 20
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

function lead_entity:remove(breaker, snap)
	if not (breaker and breaker:is_player()) then
		-- non player action caused the lead to break, so drop it
		drop_lead(self.follower:get_pos())
	end

	if self.follower and self.follower:get_pos() then
		local l = self.follower:get_luaentity()
		l.leader = nil
		l.tied_to_node = nil
		if l.is_knot then
			table.remove(l.leads, table.indexof(l.leads, self))
		else
			l.lead = nil
		end
	end

	if self.leader then
		local leads = player_leads[self.leader]
		if leads then
			table.remove(leads, table.indexof(leads, self))
		else
			local knot = self.leader:get_luaentity()
			if knot then
				table.remove(knot.leads, table.indexof(knot.leads, self))
			end
		end
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
		static_save = false,
		visual		  = 'mesh',
		visual_size	 = vector.new(10, 10, 10),
		mesh			= "mcl_mobs_lead_knot.obj",
		textures		= { "mcl_mobs_lead_knot.png" },
		physical		= false,
		selectionbox	= {-3/16, -4/16, -3/16, 3/16, 4/16, 3/16},
	},
}

knot_entity.description = S("Lead Knot")

function knot_entity:on_activate(staticdata, dtime_s)
	self.is_knot = true
	self.leads = {}
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
	-- verify lead attachable node is still present and there is at least
	-- one lead attached
	local n = core.get_node(self.object:get_pos())
	if core.get_item_group(n.name, "can_attach_lead") == 0 or #self.leads <= 0 then
		self:remove()
	end
end

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
		local stack = clicker:get_wielded_item()
		if #self.leads > 0 then
			local lead = table.remove(self.leads)
			if lead then
				local l = lead.follower:get_luaentity()
				attach_lead(l, clicker, lead.object)
				if #self.leads < 1 then
					self:remove()
				end
			end
		else
			clicker:set_wielded_item(mcl_mobs.transfer_lead_to_node(pos, clicker, stack))
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
			return mcl_mobs.transfer_lead_to_node(pointed_thing.under, user, itemstack)
		end
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type == "object" then
			local l = pointed_thing.ref:get_luaentity()
			if l then
				if attach_lead(l, user) and not core.is_creative_enabled(user and user:get_player_name()) then
					itemstack:take_item()
				end
			end
		end
		return itemstack
	end,
})

core.register_craft({
	output = "mcl_mobs:lead 2";
	recipe =
	{
		{"mcl_mobitems:string", "mcl_mobitems:string", ""},
		{"mcl_mobitems:string", "mcl_mobitems:slimeball", ""},
		{"",   "",   "mcl_mobitems:string"},
	}
})

core.register_entity("mcl_mobs:lead_entity", lead_entity)
core.register_entity("mcl_mobs:knot", knot_entity)
