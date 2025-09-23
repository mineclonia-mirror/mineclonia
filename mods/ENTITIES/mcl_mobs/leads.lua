--[[
	mcl_mobs,
	lead entity code reused from
	Minetest Leads mod by Silver Sandstone <@SilverSandstone@craftodon.social>


Overview

	A lead is a non persistent entity that "ties" a "follower" entity to a
	"leader" entity and may exert some force on the follower. A lead is
	*not* attached to the leader and follower objects in the Luanti sense of
	the word, but just displays as connecting the two. A leader may hold
	many leads, but a follower can be tied to only one lead. Currently
	players, mobs, and fences (actually a "knot" entity at the fence
	position) can act as leaders, while registered entities with the
	`is_leadable` property (currently mobs and boats) and fences (actually
	the knot) can be followers. A lead is persisted on the follower side by
	storing the type and identity of the leader entity as a leader data
	table with exactly one non nil entry in the `_lead_leader`field:

```lua
{
	player, -- the name of the leading player
	mob,    -- the `_lead_leaderid` of the leading mob
	node,   -- the stringified position vector of the node the lead is tied to
}
```

	Leads are automatically respawned when the follower and leader object
	are both available (as long as the follower with the persistent
	`_lead_leader` field regularly calls `mcl_mobs.check_lead()` which is
	automatically done by default for mobs and boats). When a lead's
	follower or leader object disappear from the game the lead object is
	removed, but the leader data remains. Thus when one from a pair of mobs
	connected by a lead gets unloaded by the engine (e.g. because of the
	server's active range), the lead disappears, too, but reappears when the
	object becomes active again. To make this work smoothly the follower
	object is teleported near the leader object when respawning the lead, if
	necessary to not break the lead. Game logic needs to explicitly remove
	the lead lua entity if it wants to have the follower-leader-link broken
	and to drop the lead back as an item. This automatically happens if a
	lead breaks.

	A lead starts to pull `is_leadable` followers towards the leader when
	its length exceeds its 'max_length` property (initially 10) and breaks
	if its length exceeds twice that length.

	Mobs get assigned a `_lead_leaderid` when they start leading a mob, ids are
	increasing numbers. The largest id used is persisted in mod storage.

	Players and knots on fences have a list of leads they are holding so
	they can be transfered on interaction. Knots are automatically created
	and destroyed when leads get attached or removed. Knots persist their
	lead information in fence node metadata.



Global API

* function mcl_mobs.attach_lead(followerent, leader_spec)
-- Create a lead to `followerent` lua entity.  Returns the created lead lua
-- entity or nil. `leader_spec` may be a player object, a mob or knot object or
-- lua entity, or a leader data table. Note that, if successful, this will
-- effectively add a lead item to the world.

* function mcl_mobs.check_lead(self)
-- Check for and respawn persistent leads if necessary. Automatically triggered
-- on every step for leadable mcla entities (mobs and boats), but must be called
-- explicitly for 3rd party mod provided `is_leadable` entities providing a
-- persistent `_lead_leader` field. Also fills the `_lead_leaderid` cache
-- required to respawn leads attached to mob leaders.

* function mcl_mobs.get_player_leads(player)
-- Returns the list of all lead lua entities currently being held by `player`.

* function mcl_mobs.get_knot(pos)
-- Get the knot lua entity at position given by vector `pos`.
}
```



mob_class API

```lua
{
	is_leadable = true,
	-- Makes it possible to attach a lead to this mob and make it a lead
	-- follower. Note that every mob can become a lead leader independent of
	-- this property. Typically set in the mob def, but may change during
	-- the lifetime of a mob. Making a mob unleadable while a lead is
	-- attached will *not* automatically drop the lead.

	lead,
	-- The last lead object attached to this mob. If the lead object gets
	-- removed directly without calling the `remove` method on the lead lua
	-- entity this may become stale, otherwise this is automatically updated
	-- by the lead code.

	_lead_leaderid,
	-- The persistent id used by follower objects to find their leader
	-- object when respawning leads after object reactivation. Should not be
	-- changed by mob code.

	_lead_leader,
	-- A leader data table describing the object leading this mob. Should
	-- not be changed by mob code.

	allow_lead_attach = function(self, leader_data),
	-- Check whether the leader object described by the given `leader_data`
	-- may attach a new lead to this mob. Default is to always return
	-- `true`. This is not called on transferring a lead from one leader to
	-- another.

	get_lead_attach_offset = function(self),
	-- Returns the offset where the lead entity appears on the mob. By
	-- default returns `vector.new(0, <collisionbox height> - 0.2, 0)`.

	after_lead_attached = function(self, leadent),
	-- Called whenever a lead is attached to this mob after lead
	-- initialization is finalized. Default is noop.

	attach_lead = function(self, followerent),
	-- Try to attach a lead to the given `followerent` lua entity. Returns
	-- the created lead lua entity or nil.

	check_lead = function(self),
	-- Call `mcl_mobs.check_lead(self)`. By default this is automatically
	-- called on every step.
}
```

Note: other entities just need to set `self.is_leadable = true` to allow leading
them in the follower role. Persisting the `_lead_leader` field and regularly
calling `mcl_mobs.check_lead(self)` is enough to make the leads code
automatically respawn such a lead on object reload. Using other objects besides
mobs, players, and knots in the leader role is currently not supported (at least
the internal functions `get_leader_data`, `get_leader object` and `attach_lead`
would need to be adapted).



lead_entity API

```lua
{
	follower,
	-- Server object in follower role.
	follower_attach_offset,
	-- The position relative to the `follower`'s position the lead should
	-- end. See `leader_attach_offset` for details.

	leader,
	-- Server object in leader role.
	leader_attach_offset,
	-- The position relative to the `leader`'s position the lead should
	-- end. Initialized during lead attach:
	-- * to (0, 1, 0) for players
	-- * using leader:get_lead_attach_offset() if it exists
	-- * to (0, 0, 0) otherwise
	-- The attachment offset is not changed automatically during the lead's
	-- lifetime.

	max_length = 10,
	current_length,
	-- The lead starts to pull `is_leadable` followers towards the leader
	-- when the distance between leader and follower exceeds its max length.
	-- The lead breaks when the distance exceeds twice this length.
	-- Initialized to 10 on lead creation. Not automatically changed during
	-- the lead's lifetime.

	pull_force = 35,
	-- Factor to apply to the force when pulling the follower object.
	-- Initialized to 35 on lead creation. Not automatically changed during
	-- the lead's lifetime.

	get_leader_data = function(),
	-- Returns the leader data table specifying the leader object of this
	-- lead.

	remove = function(self, breaker)
	-- Removes the lead and drops it as an item unless player object
	-- `breaker` is in creative mode.

	transfer = function(self, new_leader)
	-- Tries to change the leader of the lead to `new_leader`.  Returns the
	-- lead lua entity (i.e. itself) on success. `new_leader` may be a
	-- player object, a mob or knot object or lua entity, or a leader data
	-- table.

	teleport = function(self)
	-- Notifies the lead to teleport follower mob near leader if necessary
	-- on next lead step only. This is useful to prevent the lead breaking
	-- if some environmental change may have increased the lead length
	-- beyond its break length (== twice the `max_length`). Doesn't
	-- currently do anything when the follower object is not a mob.
}
```



knot_entity API

```lua
{
	get_leads = function()
	-- returns the list of all lead lua entities currently being attached to
	-- this knot.

	remove = function(self, breaker)
	-- Removes all leads - including unspawned ones - attached to this knot
	-- (dropping them as items, see `lead_entity:remove()`).

}
```
]]


local modname = core.get_current_modname()
local S = core.get_translator(modname)
local storage = core.get_mod_storage()


local MIN_BREAK_AGE = 1.0
local STRETCH_SOUND_INTERVAL = 2.0
local LEAD_MAX_LENGTH = 4
local LEAD_PULL_FORCE = 1.3
local PERSISTENT_LEAD_KEY = "mcl_mobs:lead_data"

local player_leads = {}
local leader_mobs = {}
local next_leader_id = tonumber(storage:get("max_leader_id")) or 0

local function get_leads(hashtable)
	local leads = {}
	for _, leadent in pairs(hashtable or {}) do
		leads[#leads + 1] = leadent
	end
	return leads
end

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

local function get_leader_data(leader)
	local is_player = leader:is_player()
	local leaderent = leader:get_luaentity()
	if not is_player and not leaderent then return nil end
	return {
		player = is_player and leader:get_player_name() or nil,
		mob = leaderent and leaderent.is_mob and leaderent._lead_leaderid or nil,
		node = leaderent and leaderent.is_knot and core.pos_to_string(leader:get_pos(), 0) or nil,
	}
end

local function get_leader_object(leader_spec)
	local leader

	if type(leader_spec) == "userdata" then
		-- server entity
		leader = leader_spec
	elseif type(leader_spec) == "table" then
		if leader_spec.object then
			-- lua entity
			leader = leader_spec.object
		-- leader data table
		elseif leader_spec.player then
			local player = core.get_player_by_name(leader_spec.player)
			leader = player and player:get_pos() and player
		elseif leader_spec.mob then
			local mob = leader_mobs[leader_spec.mob]
			leader = mob and mob:get_pos() and mob
		elseif leader_spec.node then
			leader = get_knot(core.string_to_pos(leader_spec.node))
		end
	-- TODO: error out if unexpected leader spec?
	end

	return leader
end

local function drop_lead(pos)
	if pos then
		core.add_item(pos, "mcl_mobs:lead")
	end
end

local function attach_lead(followerent, leader, lead, respawn)
	local led_pos = followerent.object:get_pos()
	-- check wether the mob already has a lead (unless transfering or respawning the lead)
	if followerent.is_leadable and followerent._lead_leader and not (lead or respawn) then
		-- check wether the lead is actually active, then abort,
		-- otherwise drop the old lead and allow attaching a new lead
		if followerent.lead and followerent.lead:get_pos() then
			return nil
		elseif led_pos then
			drop_lead(led_pos)
		end
	end
	if led_pos and followerent.is_leadable or followerent.is_knot then
		local leader_pos = leader:get_pos()
		local leaderent = leader:get_luaentity()
		if leaderent and leaderent.is_mob and not leaderent._lead_leaderid then
			leaderent._lead_leaderid = get_next_leader_id(leader)
		end
		local leader_data = get_leader_data(leader)
		if not (lead or respawn) and followerent.allow_lead_attach and not followerent:allow_lead_attach(leader_data) then
			core.log("[mcl_mobs] Follower doesn't allow lead")
			return nil
		end
		lead = lead or core.add_entity(leader_pos, "mcl_mobs:lead_entity")
		if lead and lead:get_pos() then
			local leadent = lead:get_luaentity()
			leadent.leader = leader
			leadent.follower = followerent.object
			if leader:is_player() then
				if not player_leads[leader] then player_leads[leader] = {} end
				player_leads[leader][lead] = leadent
				leadent.leader_attach_offset = vector.new(0,1,0)
			else
				if leaderent.is_knot then
					leaderent.leads[lead] = leadent
					leadent.leader_attach_offset = vector.zero()
				else
					local offset = leaderent.get_lead_attach_offset and leaderent:get_lead_attach_offset() or vector.zero()
					leadent.leader_attach_offset = offset
				end
			end
			if followerent.is_leadable then
				followerent.lead = lead
				followerent._lead_leader = leader_data
				local offset = followerent.get_lead_attach_offset and followerent:get_lead_attach_offset() or vector.zero()
				leadent.follower_attach_offset = offset
				if followerent.after_lead_attached then
					followerent:after_lead_attached(leadent)
				end
			else
				-- knot in follower role, persist lead data
				followerent:add_persistent_lead(lead, leadent)
				leadent.follower_attach_offset = vector.zero()
			end
			leadent:update_visuals()
			core.sound_play("leads_attach", {pos = led_pos}, true)
			return leadent
		else
			core.log("[mcl_mobs] Failed to create lead entity")
		end
	end

	return nil
end

-- helper to transfer a lead between a player and a knot
local function transfer_one_lead(leads, new_leader, knot)
	local lead, leadent, follower, followerent, invalid

	-- skip and clean defunct leads (this typically happens because some
	-- entity got removed directly); mostly harmless:-)
	repeat
		lead, leadent = next(leads)
		follower = lead and leadent.follower
		followerent = follower and follower:get_luaentity()
		invalid = lead and not (lead:get_pos() and followerent)
		if invalid then
			core.log("action", "[mcl_mobs] cleaning defunct lead")
			leads[lead] = nil
			-- no need to further clean up the defunct follower
		end
	until not invalid

	if lead then
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
			-- new_leader is a player, remove persistent lead data from knot
			followerent:remove_persistent_lead(lead, leadent)
			followerent = follower:get_luaentity()
		end
		-- remove lead from leads table
		leads[lead] = nil
		return attach_lead(followerent, new_leader, lead)
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
		return itemstack
	end

	-- then try to transfer a lead from the player to the fence
	local player_leads = clicker and player_leads[clicker] or {}
	if next(player_leads) then
		for objref, _ in pairs(player_leads) do
			local leads = {}
			leads[objref] = player_leads[objref]
			transfer_one_lead(leads, knot or create_knot(pos), knot)
			leads = {}
		end
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

-- lead entitiess are not persistent and get respawned when the leadable object
-- gets reloaded
local function respawn_lead(self, leader_data)
	local leader = get_leader_object(leader_data)

	if leader then
		return attach_lead(self, leader, nil, true)
	end
end

function mcl_mobs.get_player_leads(player)
	return get_leads(player and player_leads[player])
end

function mcl_mobs.get_knot(pos)
	local knot = pos and get_knot(pos, false)
	return knot and knot:get_luaentity()
end

function mcl_mobs.attach_lead(followerent, leader)
	return attach_lead(followerent, leader)
end

function mcl_mobs.check_lead(self)
	-- repopulate leader_mobs table
	if self._lead_leaderid and not leader_mobs[self._lead_leaderid] then
		leader_mobs[self._lead_leaderid] = self.object
	end

	-- check whether self is led
	if not self.is_leadable then return false end
	if not self._lead_leader then return false end

	if self.lead and self.lead:get_pos() then
		return true
	end

	-- respawn lead if necessary
	return respawn_lead(self, self._lead_leader)

	-- if respawning didnt work just try again next time
	--
	-- TODO: is there a point where we want to clean the possibly outdated
	-- lead data from the entity?
end


local mob_class = mcl_mobs.mob_class

function mob_class:allow_lead_attach(leader_data)
	return true
end

function mob_class:get_lead_attach_offset()
	local cb = self.object:get_properties().collisionbox or { 0, 0, 0, 0, 0.7, 0 }
	return vector.new(0, cb[5] - 0.2, 0)
end

function mob_class:after_lead_attached(leadent)
end

function mob_class:attach_lead(followerent)
	return mcl_mobs.attach_lead(followerent, self.object)
end

function mob_class:attach_lead(followerent)
	return mcl_mobs.attach_lead(followerent, self.object)
end

function mob_class:check_lead()
	return mcl_mobs.check_lead(self)
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
	self.max_length = LEAD_MAX_LENGTH
	self.current_length = self.max_length
	self.pull_force = LEAD_PULL_FORCE
	self.follower_attach_offset = vector.zero()
	self.leader_attach_offset = vector.zero()
end

function lead_entity:on_step(dtime)
	self.age = ( self.age or 0 ) + dtime
	local success, pos, offset = self:step_physics(dtime, self.age < MIN_BREAK_AGE or self._prevent_break)
	self._prevent_break = nil
	if success then
		self.current_length = math.max(offset:length(), 0.25)
		self.rotation = offset:dir_to_rotation()
		self.object:move_to(pos, true)
		self:update_visuals()
	end
end

function lead_entity:step_physics(dtime, prevent_break)
	local l_pos = self.leader and self.leader:get_pos() or self.tied_to_node
	local f_pos = self.follower and self.follower:get_pos()

	if not (l_pos and f_pos) then
		self.object:remove()
		return false, nil, nil
	end

	l_pos = l_pos + self.leader_attach_offset
	f_pos = f_pos + self.follower_attach_offset

	local pull_distance = self.max_length
	local break_distance = pull_distance * 2
	local distance = l_pos:distance(f_pos)

	local followerent = self.follower:get_luaentity()

	-- check whether lead breaks
	if distance > break_distance then
		if prevent_break then
			if followerent.is_mob then
				-- teleport follower near leader
				f_pos = l_pos:add((f_pos - l_pos):normalize() * pull_distance)
				self.follower:set_pos(f_pos)
			end
			-- TODO: actively prevent breaking the lead for other constellations, too?
		else
			self:remove(nil, true)
			return false, nil, nil
		end
	end

	local lead_pos = (f_pos + l_pos) / 2

	-- affect non knot followers
	if distance > pull_distance and not followerent.is_knot then
		-- detach follower before pulling
		mcl_util.detach_object(self.follower)

		local pull_speed_factor = self.pull_force
		followerent:gopath(lead_pos, pull_speed_factor, "run")

		self.sound_timer = ( self.sound_timer or 0 ) + dtime
		if self.sound_timer >= STRETCH_SOUND_INTERVAL then
			self.sound_timer = self.sound_timer - STRETCH_SOUND_INTERVAL
			if math.random(8) == 1 then
				core.sound_play("leads_stretch", {pos = lead_pos}, true)
			end
		end
	end

	return true, lead_pos, f_pos - l_pos
end

function lead_entity:on_rightclick(puncher, time_from_last_punch, tool_capabilities, dir, damage)
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

function lead_entity:teleport()
	self._prevent_break = true -- modify step_physics for next step
end

local function unattach_leader(lead, leader)
	local leads = player_leads[leader]
	if leads then
		leads[lead] = nil
	else
		-- knot's leads table needs to be updated
		local leaderent = leader:get_luaentity()
		if leaderent and leaderent.is_knot then
			leaderent.leads[lead] = nil
		end
	end
end

function lead_entity:remove(breaker, snap, nodrop)
	if not (nodrop or (breaker and breaker:is_player() and core.is_creative_enabled(breaker:get_player_name()))) then
		drop_lead(self.follower and self.follower:get_pos() or self.object:get_pos())
	end

	if self.follower and self.follower:get_pos() then
		local l = self.follower:get_luaentity()
		if l.is_leadable then
			l._lead_leader = nil
		elseif l.is_knot then
			-- knot in follower role, unpersist lead data
			l:remove_persistent_lead(self.object, self)
		else
			l.lead = nil
		end
	end

	if self.leader then
		unattach_leader(self.object, self.leader)
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

function lead_entity:get_leader_data()
	return get_leader_data(self.leader)
end

function lead_entity:transfer(new_leader)
	local leader = get_leader_object(new_leader)

	if leader and leader ~= self.follower then
		local old_leader = self.leader
		if attach_lead(self.follower:get_luaentity(), leader, self.object) then
			unattach_leader(self.object, old_leader)
			return self
		end
	end
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
	self.pos = self.object:get_pos():round()
	local meta = core.get_meta(self.pos)
	self.persistent_leads = core.deserialize(meta:get(PERSISTENT_LEAD_KEY)) or {}
end

function knot_entity:save_persistent_leads()
	local meta = core.get_meta(self.pos)
	local data = next(self.persistent_leads) and self.persistent_leads
	meta:set_string(PERSISTENT_LEAD_KEY, data and core.serialize(data) or "")
end

local function get_leader_data_key(leadent)
	local leader_data = leadent and leadent:get_leader_data()
	return leader_data and core.serialize(leader_data) or "<defunct>"
end

function knot_entity:add_persistent_lead(lead, leadent)
	if self.leads[lead] then
		-- remove old leader data
		self.persistent_leads[get_leader_data_key(self.leads[lead])] = nil
	end
	-- make copy to detect leader changes on lead transfer
	self.leads[lead] = setmetatable(table.copy(leadent), getmetatable(leadent))
	local leader_data_key = get_leader_data_key(leadent)
	if not self.persistent_leads[leader_data_key] then
		self.persistent_leads[leader_data_key] = 1
	end
	self:save_persistent_leads()
end

function knot_entity:remove_persistent_lead(lead, leadent)
	self.leads[lead] = nil
	local leader_data_key = get_leader_data_key(leadent)
	if self.persistent_leads[leader_data_key] then
		self.persistent_leads[leader_data_key] = nil
		self:save_persistent_leads()
	end
end

function knot_entity:remove(killer)
	for _, leadent in pairs(self.leads) do
		-- note that removing the lead will remove leadent from the
		-- leads table just being iterated, but that modification does
		-- not interfere with the iteration
		leadent:remove(killer)
	end
	-- drop unspawned persistent leads, too
	for leader_data, _ in pairs(self.persistent_leads) do
		-- we don't need to inspect the lead any further
		drop_lead(self.pos)
		self.persistent_leads[leader_data] = nil
	end
	self:save_persistent_leads()
	self.object:remove()
end

function knot_entity:on_step(dtime)
	-- verify leads once a second, if no (potentially unspawned) lead or no
	-- lead attachable node is present, remove the knot
	self.timer = (self.timer or 0) - dtime
	if self.timer > 0 then return end
	self.timer = 0.1

	if not ((next(self.leads) or next(self.persistent_leads)) and is_lead_attachable(self.object:get_pos())) then
		self:remove()
	end

	-- check whether to respawn some leads
	local active = {}
	for _, leadent in pairs(self.leads) do
		if leadent.follower == self.object then
			active[get_leader_data_key(leadent)] = true
		end
	end
	local incomplete = false
	for leader_data_key, _ in pairs(self.persistent_leads) do
		if not active[leader_data_key] then
			-- try to respawn
			if not respawn_lead(self, core.deserialize(leader_data_key)) then
				incomplete = true
			end
		end
	end

	-- make knot look different when not all leads active
	local texture, alpha = "mcl_mobs_lead_knot.png", false
	if incomplete then
		if not next(self.leads) then
			texture, alpha = "[fill:16x16:#80808080^[overlay:" .. texture, true
		else
			texture = "[fill:16x16:#908088FF^[overlay:" .. texture
		end
	end
	self.object:set_properties({
		textures = { texture },
		use_texture_alpha = alpha,
	})
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

function knot_entity:get_leads()
	return get_leads(self.leads)
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
		{"mcl_mobitems:string", "mcl_mobitems:string", ""},
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

-- spawn knots on fences with persistent leads on every load
core.register_lbm({
    label = "Spawn knots on fences",
    name = "mcl_mobs:spawn_knots_on_fences",
    nodenames = {"group:fence"},
    run_at_every_load = true,
    action = function(pos)
	    local meta = core.get_meta(pos)
	    if meta:contains(PERSISTENT_LEAD_KEY) then
		    create_knot(pos)
	    end
    end,
})
