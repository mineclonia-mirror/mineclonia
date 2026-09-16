core.register_entity(":3d_armor_stand:armor_entity", {
	on_activate = function(self)
		core.log("action", "[mcl_armor_stand] Removing legacy entity: 3d_armor_stand:armor_entity")
		self.object:remove()
	end,
	static_save = false,
})
