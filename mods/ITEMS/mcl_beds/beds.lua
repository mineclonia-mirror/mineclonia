local S = core.get_translator(core.get_current_modname())
local D = mcl_util.get_dynamic_translator()

local messy_textures = { --translator table for the bed texture filenames names not adhering to the common color names of mcl_dyes
	["lightblue"] = "light_blue",
}

local canonical_color = "red"

for color, colordef in pairs(mcl_dyes.colors) do
	local is_canonical =

	core.register_craft({
		type = "shapeless",
		output = "mcl_beds:bed_"..color.."_bottom",
		recipe = { "group:bed", "mcl_dyes:"..color }
	})

	local entry_name, create_entry
	if is_canonical then
		entry_name = S("Bed")
	else
		create_entry = false
	end
	local texcol = color
	if messy_textures[color] then
		texcol = messy_textures[color]
	end
	-- Register bed
	mcl_beds.register_bed("mcl_beds:bed_"..color, {
		description = D(colordef.readable_name .. " Bed"),
		_doc_items_entry_name = entry_name,
		_doc_items_create_entry = create_entry,
		inventory_image = "mcl_beds_bed_"..texcol.."_inv.png",
		wield_image = "mcl_beds_bed_"..texcol.."_inv.png",

		tiles = {
			"mcl_beds_bed_"..texcol..".png"
		},
		recipe = {
			{"mcl_wool:"..color, "mcl_wool:"..color, "mcl_wool:"..color},
			{"group:wood", "group:wood", "group:wood"}
		},
	})

	if not is_canonical then
		doc.add_entry_alias("nodes", "mcl_beds:bed_"..canonical_color.."_bottom", "nodes", "mcl_beds:bed_"..color.."_bottom")
		doc.add_entry_alias("nodes", "mcl_beds:bed_"..canonical_color.."_bottom", "nodes", "mcl_beds:bed_"..color.."_top")
	end
end

core.register_node("mcl_beds:straw_bed", {
	description = S("Straw Bed"),
	_tt_help = S("Allows you to sleep without setting your respawn point"),

	_doc_items_longdesc = beddesc,
	_doc_items_usagehelp = beduse,
	_doc_items_create_entry = true,
	_doc_items_entry_name = "Straw Bed",

	inventory_image = "mcl_beds_straw_bed_inv.png",
	wield_image = "mcl_beds_straw_bed_inv.png",
	drawtype = "mesh",
	mesh = "mcl_beds_straw_bed.obj",
	tiles = {"mcl_beds_straw_bed.png"},
	use_texture_alpha = "clip",
	paramtype = "light",
	paramtype2 = "4dir",
	is_ground_content = false,
	stack_max = 16,
	groups = {handy = 1, flammable = -1, hoey = 1, bed = 2, dig_by_piston=1, unsticky = 1},
	_mcl_hardness = 0.2,
	_mcl_blast_resistance = 0.2,
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	drop = "mcl_beds:straw_bed",
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.3, 1.5}
	},
	collision_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.3, 1.5}
	},
	on_place = function(itemstack, placer, pointed_thing)
		local player_name = placer and placer:get_player_name() or ""

		local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
		if rc then return rc end

		local dir = placer and placer:is_player() and placer:get_look_dir() and core.dir_to_facedir(placer:get_look_dir()) or 0

		local front_pos = vector.add(pointed_thing.above, core.facedir_to_dir(dir))
		local front_node = core.get_node(front_pos)
		local front_def = core.registered_nodes[front_node.name]

		if not front_def or not front_def.buildable_to then
			return itemstack
		end

		if core.is_protected(front_pos, player_name) and
			not core.check_player_privs(player_name, "protection_bypass") then
			core.record_protection_violation(front_pos, player_name)
			return itemstack
		end

		local bed_node = {name = "mcl_beds:straw_bed", param2 = dir}

		core.set_node(pointed_thing.above, bed_node)

		if not core.is_creative_enabled(player_name) then
			itemstack:take_item()
			end

		return itemstack
	end,

	on_rightclick = function(pos, _, clicker)
		return mcl_beds.on_rightclick(pos, clicker, false, true)
	end,

	on_rotate = rotate,
	after_destruct = destruct_bed,
})

core.register_craft({
	output = "mcl_beds:straw_bed 4",
	recipe = {
		{"mcl_farming:hay_block", "mcl_farming:hay_block", "mcl_farming:hay_block"},
	}
})
