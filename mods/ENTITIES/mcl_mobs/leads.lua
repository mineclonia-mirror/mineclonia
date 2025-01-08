--[[
	mcl_mobs,
	lead entity code reused from
	Minetest Leads mod by Silver Sandstone <@SilverSandstone@craftodon.social>

	A lead is a non persistent entity that ties a "follower" entity to a
	"leader" entity and restricts the followers movement. A leader may hold
	many leads, but a follower can be tied to only one lead. Currently
	players, mobs, and fences (actually a "knot" entity at the fence
	position) can act as leaders, while mobs, boats and fences (actually the
	knot) can be followers. Lead is persisted on the follower side by
	storing the type and identity of the leader entity - if any - using the
	properties

	* `leader`: the name of the leading player
	* `leadermob`: the `leaderid` of the leading mob
	* `tied_to_node`: the position vector of the fence the entity is tied to

	Mobs get assigned a `leaderid` when they start leading a mob, ids are
	increasing numbers. The largest id used is persisted in mod storage.

	Players and knots on fences have a list of leads they are holding so
	they can be transfered on interaction. Knots are automatically created
	and destroyed when leads get attached resp. removed.
--]]

local modname = core.get_current_modname()
--local modpath = core.get_modpath(modname)
local S = core.get_translator(modname)
local storage = core.get_mod_storage()

local MIN_BREAK_AGE = 1.0
local STRETCH_SOUND_INTERVAL = 2.0
local LEAD_MAX_LENGTH = 10
local PULL_FORCE = 35

local player_leads = {}
local leader_mobs = {}
local next_leader_id = tonumber(storage:get("max_leader_id")) or 0

local function get_next_leader_id(obj)
	next_leader_id = next_leader_id + 1
	storage:set_int("max_leader_id", next_leader_id)
	leader_mobs[next_leader_id] = obj
	return next_leader_id
end

local function is_lead_attachable(pos)
	local node = core.get_node(pos)
	return core.get_item_group(node.name, "can_attach_lead") > 0
end

local function create_knot(pos)
	return core.add_entity(pos, "mcl_mobs:knot")
end

local function get_knot(pos, create)
	pos = vector.round(pos)
	for __, object in pairs(core.get_objects_in_area(pos, pos)) do
		local entity = object:get_luaentity()
		if entity and entity.is_knot then
			return object
		end
	end
	return (create == nil or create) and create_knot(pos)
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
			-- existing lead
			if new_lead then
				leadent.follower = self.object
				if self.is_leadable then
					self.lead = lead
					local cb = self.object:get_properties().collisionbox or { 0,0,0,0,0,0 }
					leadent.follower_attach_offset = vector.new(0,cb[5] - 0.2 or 0.5,0)
				else
					self.leads[lead] = leadent
					leadent.follower_attach_offset = vector.zero()
				end
			end
			leadent.leader = obj
			if obj:is_player() then
				if not player_leads[obj] then player_leads[obj] = {} end
				player_leads[obj][lead] = leadent
				leadent.leader_attach_offset = vector.new(0,1,0)
				if self.is_leadable then
					self.leader = obj:get_player_name()
					self.leadermob = nil
					self.tied_to_node = nil
				end
			else
				local leaderent = obj:get_luaentity()
				if leaderent.is_knot then
					leaderent.leads[lead] = leadent
					leadent.leader_attach_offset = vector.zero()
					self.leader = nil
					self.leadermob = nil
					self.tied_to_node = leader_pos
				else
					if not leaderent.leaderid then
						leaderent.leaderid = get_next_leader_id(obj)
					end
					local cb = obj:get_properties().collisionbox or { 0,0,0,0,0,0 }
					leadent.leader_attach_offset = vector.new(0,cb[5] - 0.2 or 0.5,0)
					self.leadermob = leaderent.leaderid
					self.leader = nil
					self.tied_to_node = nil
				end
			end
			leadent:update_visuals()
			core.sound_play("leads_attach", {pos = led_pos}, true)
			return leadent
		else
			core.log("no lead ent")
		end
	end
end

-- helper to transfer a lead between a player and a knot
local function transfer_one_lead(leads, new_leader, knot)
	local lead, leadent = next(leads)
	if lead then
		local follower = leadent.follower
		if follower == knot then
			-- knot clicked is in the follower role of the lead to
			-- transfer, try to invert lead direction
			follower = leadent.leader
			if follower:is_player() then
				-- lead might be held by another player, but
				-- probably the player is just trying to connect
				-- a fence to itself; anyway, a player can't be
				-- led, even by itself, abort transfer
				core.log("warning", "[mcl_mobs] attempt to lead player")
				return
			elseif not new_leader:is_player() then
				-- should not happen, but better safe than sorry
				core.log("warning", "[mcl_mobs] unexpected lead transfer attempt")
				return
			end
			-- new_leader is a player, just destroy lead (without
			-- dropping the item) and let it be recreated in the
			-- correct direction by attach_lead
			--
			-- this will also remove the lead from the leads table
			leadent:remove(new_leader, nil, true)
			lead = nil
		else
			-- remove lead from leads table
			leads[lead] = nil
		end
		return attach_lead(follower:get_luaentity(), new_leader, lead)
	end
end

local function tie_lead_to_knot(pos, clicker, itemstack, knot)
	-- need a player to take or tie leads
	if not clicker or not clicker:is_player() then return end

	local knot = knot or get_knot(pos, false)

	-- first try to take a lead from the fence, unless sneak is pressed
	local knotent = knot and knot:get_luaentity()
	local knot_leads =  knotent and knotent.leads
	if knot_leads and not clicker:get_player_control().sneak and transfer_one_lead(knot_leads, clicker, knot) then
		if not next(knot_leads) then
			knotent:remove()
		end
		return itemstack
	end

	-- then try to transfer a lead from the player to the fence
	local player_leads = clicker and player_leads[clicker] or {}
	if next(player_leads) and transfer_one_lead(player_leads, knot or create_knot(pos), knot) then
		return itemstack
	end

	-- last try to tie a new lead to the fence
	if itemstack:get_name() == "mcl_mobs:lead" then
		local knotent = (knot or create_knot(pos)):get_luaentity()
		if attach_lead(knotent, clicker) then
			if not core.is_creative_enabled(clicker:get_player_name()) then
				itemstack:take_item()
			end
			return itemstack
		end
	end
end

-- leads are not persistent and get respawned when the leadable object gets reloaded
function mcl_mobs.check_lead(self)
	-- repopulate leader_mobs table
	if self.leaderid and not leader_mobs[self.leaderid] then
		leader_mobs[self.leaderid] = self.object
	end

	-- check whether self is led
	if not self.is_leadable then return end
	if not self.leader and not self.leadermob and not self.tied_to_node then return false end

	-- make mob look at leading player
	if self.lead and self.lead:get_pos() then
		if self.leader and self.is_mob then
			local pl = core.get_player_by_name(self.leader)
			self:look_at(pl:get_pos())
		end
		return true
	end

	-- respawn lead if necessary
	if self.tied_to_node then
		attach_lead(self, get_knot(self.tied_to_node))
	elseif self.leader then
		local pl = core.get_player_by_name(self.leader)
		if pl and pl:get_pos() then
			attach_lead(self, pl)
		end
	elseif self.leadermob and leader_mobs[self.leadermob] and leader_mobs[self.leadermob]:get_pos() then
		attach_lead(self, leader_mobs[self.leadermob])
	end

	-- if respawning didnt work just try again next time
	--
	-- TODO: is there a point where we want to clean the possibly outdated
	-- lead data from the entity?
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
	local followerent = self.follower:get_luaentity()
	-- can't pull knots
	if distance > pull_distance and not followerent.is_knot then
		-- detach follower
		mcl_util.detach_object(self.follower)
		local pull_force = PULL_FORCE
		if not followerent.is_mob then
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
	self:remove(puncher)
	return true
end

function lead_entity:on_death(killer)
	self:remove(killer)
end

function lead_entity:remove(breaker, snap, nodrop)
	if not (nodrop or (breaker and breaker:is_player() and core.is_creative_enabled(breaker:get_player_name()))) then
		drop_lead(self.follower:get_pos())
	end

	if self.follower and self.follower:get_pos() then
		local l = self.follower:get_luaentity()
		l.leader = nil
		l.leadermob = nil
		l.tied_to_node = nil
		if l.is_knot then
			l.leads[self.object] = nil
		else
			l.lead = nil
		end
	end

	if self.leader then
		local leads = player_leads[self.leader]
		if leads then
			leads[self.object] = nil
		else
			-- knot's leads table needs to be updated
			local leaderent = self.leader:get_luaentity()
			if leaderent and leaderent.is_knot then
				leaderent.leads[self.object] = nil
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
	for _, leadent in pairs(self.leads) do
		-- note that removing the lead will remove leadent from the
		-- leads table just being iterated, but that modification does
		-- not interfere with the iteration
		leadent:remove(killer)
	end
	self.object:remove()
end

function knot_entity:on_step(dtime)
	self.timer = (self.timer or 1) - dtime
	if self.timer > 0 then return end
	self.timer = 1
	-- verify there is at least one lead attached and lead attachable node
	-- is still present
	if not (next(self.leads) and is_lead_attachable(self.object:get_pos())) then
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

	self:remove(puncher)
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
		local itemstack = clicker:get_wielded_item()
		local resultstack = tie_lead_to_knot(pos, clicker, itemstack, self.object)
		if resultstack then
			clicker:set_wielded_item(resultstack)
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
			local pos = pointed_thing.under
			if is_lead_attachable(pos) then
				return tie_lead_to_knot(pos, user, itemstack)
			end
		end
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type == "object" then
			local l = pointed_thing.ref:get_luaentity()
			-- attaching a lead to a knot is handled by the knot entity
			if l and l.is_leadable then
				if attach_lead(l, user) and not core.is_creative_enabled(user and user:get_player_name() or "") then
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

-- add lead interaction to all registered fences
local function fence_on_rightclick(pos, _, clicker, itemstack)
	return tie_lead_to_knot(pos, clicker, itemstack)
end

core.register_on_mods_loaded(function()
	for name, def in pairs(core.registered_nodes) do
		if core.get_item_group(name, "fence") == 1 then
			local groups = table.copy(def.groups)
			groups.can_attach_lead = 1
			core.override_item(name, {
				groups = groups,
				_mcl_on_rightclick_optional = fence_on_rightclick,
			})
		end
	end
end)
