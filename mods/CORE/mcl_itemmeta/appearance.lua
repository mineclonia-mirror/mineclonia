
mcl_itemmeta.register_modifiable("appearance", {
	init = function(itemstack)
		local def = itemstack:get_definition()
		local inventory_image = def.inventory_image
		local inventory_overlay = def.inventory_overlay
		local wield_image = def.wield_image
		local wield_overlay = def.wield_overlay
		if not wield_image and inventory_image then
			wield_image = inventory_image
			wield_overlay = inventory_overlay
		end

		return {
			inventory_image = inventory_image,
			inventory_overlay = inventory_overlay,
			wield_image = wield_image,
			wield_overlay = wield_overlay,
		}
	end,
	set = function(itemstack, values)
		local meta = itemstack:get_meta()
		local def = itemstack:get_definition()
		meta:set_string("inventory_image", values.inventory_image ~= def.inventory_image
			and values.inventory_image
			or ""
		)
		meta:set_string("inventory_overlay", values.inventory_overlay ~= def.inventory_overlay
			and values.inventory_overlay
			or ""
		)

		local override_wield_image = values.wield_image ~= (def.wield_image or values.inventory_image)
		local wield_image_defined = override_wield_image or def.wield_image
		local default_wield_overlay = wield_image_defined and def.wield_overlay or def.inventory_overlay
		meta:set_string("wield_image", override_wield_image
			and values.wield_image
			or ""
		)

		meta:set_string("wield_overlay", values.wield_overlay ~= default_wield_overlay
			and values.wield_overlay
			or ""
		)
	end
})

mcl_itemmeta.appearance = {
	IMAGE_BASE = 10100,
	BANNER_LAYERS = 10200,
	DECORATED_POT_FACES = 10300,
	ENCHANTMENT_GLINT = 10400,
}
