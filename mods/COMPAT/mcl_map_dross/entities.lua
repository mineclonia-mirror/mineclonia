-- entities to be automatically removed from the map:
--
local bad_entities = {
	"mcl_potions:poison_2_splash_flying",
	"mcl_potions:slowness_2_arrow_entity",
	"mobs_mc:potion_arrow",
	"mcl_throwing:flying_bobber_entity",
}

local rm_entity = {
	on_activate = function(self)
		self.object:remove()
	end,
}

for _, ent in ipairs(bad_entities) do
	core.register_entity(":"..ent, rm_entity)
end
