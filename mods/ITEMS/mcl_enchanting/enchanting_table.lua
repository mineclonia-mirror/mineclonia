local modname = core.get_current_modname()
local F = core.formspec_escape
local S = core.get_translator(modname)

-------------------------------------------------------------------------------
-- COUNTING BOOKSHELVES
-------------------------------------------------------------------------------

mcl_enchanting.bookshelf_positions = {
	{x = -2, y = 0, z = -2}, {x = -2, y = 1, z = -2},
	{x = -1, y = 0, z = -2}, {x = -1, y = 1, z = -2},
	{x =  0, y = 0, z = -2}, {x =  0, y = 1, z = -2},
	{x =  1, y = 0, z = -2}, {x =  1, y = 1, z = -2},
	{x =  2, y = 0, z = -2}, {x =  2, y = 1, z = -2},
	{x = -2, y = 0, z =  2}, {x = -2, y = 1, z =  2},
	{x = -1, y = 0, z =  2}, {x = -1, y = 1, z =  2},
	{x =  0, y = 0, z =  2}, {x =  0, y = 1, z =  2},
	{x =  1, y = 0, z =  2}, {x =  1, y = 1, z =  2},
	{x =  2, y = 0, z =  2}, {x =  2, y = 1, z =  2},
	-- {x = -2, y = 0, z = -2}, {x = -2, y = 1, z = -2},
	{x = -2, y = 0, z = -1}, {x = -2, y = 1, z = -1},
	{x = -2, y = 0, z =  0}, {x = -2, y = 1, z =  0},
	{x = -2, y = 0, z =  1}, {x = -2, y = 1, z =  1},
	-- {x = -2, y = 0, z =  2}, {x = -2, y = 1, z =  2},
	-- {x =  2, y = 0, z = -2}, {x =  2, y = 1, z = -2},
	{x =  2, y = 0, z = -1}, {x =  2, y = 1, z = -1},
	{x =  2, y = 0, z =  0}, {x =  2, y = 1, z =  0},
	{x =  2, y = 0, z =  1}, {x =  2, y = 1, z =  1},
	-- {x =  2, y = 0, z =  2}, {x =  2, y = 1, z =  2},
}

mcl_enchanting.air_positions = {
	{x = -1, y = 0, z = -1}, {x = -1, y = 1, z = -1},
	{x = -1, y = 0, z = -1}, {x = -1, y = 1, z = -1},
	{x =  0, y = 0, z = -1}, {x =  0, y = 1, z = -1},
	{x =  1, y = 0, z = -1}, {x =  1, y = 1, z = -1},
	{x =  1, y = 0, z = -1}, {x =  1, y = 1, z = -1},
	{x = -1, y = 0, z =  1}, {x = -1, y = 1, z =  1},
	{x = -1, y = 0, z =  1}, {x = -1, y = 1, z =  1},
	{x =  0, y = 0, z =  1}, {x =  0, y = 1, z =  1},
	{x =  1, y = 0, z =  1}, {x =  1, y = 1, z =  1},
	{x =  1, y = 0, z =  1}, {x =  1, y = 1, z =  1},
	-- {x = -1, y = 0, z = -1}, {x = -1, y = 1, z = -1},
	{x = -1, y = 0, z = -1}, {x = -1, y = 1, z = -1},
	{x = -1, y = 0, z =  0}, {x = -1, y = 1, z =  0},
	{x = -1, y = 0, z =  1}, {x = -1, y = 1, z =  1},
	-- {x = -1, y = 0, z =  1}, {x = -1, y = 1, z =  1},
	-- {x =  1, y = 0, z = -1}, {x =  1, y = 1, z = -1},
	{x =  1, y = 0, z = -1}, {x =  1, y = 1, z = -1},
	{x =  1, y = 0, z =  0}, {x =  1, y = 1, z =  0},
	{x =  1, y = 0, z =  1}, {x =  1, y = 1, z =  1},
	-- {x =  1, y = 0, z =  1}, {x =  1, y = 1, z =  1},
}

function mcl_enchanting.get_bookshelves(pos)
	local absolute, relative = {}, {}
	for i, rp in ipairs(mcl_enchanting.bookshelf_positions) do
		local airp = vector.add(pos, mcl_enchanting.air_positions[i])
		local ap = vector.add(pos, rp)
		if core.get_node(ap).name == "mcl_books:bookshelf" and core.get_node(airp).name == "air" then
			table.insert(absolute, ap)
			table.insert(relative, rp)
		end
	end
	return absolute, relative
end

-------------------------------------------------------------------------------
-- ENCHANTING TABLE FORMSPEC
-------------------------------------------------------------------------------

function mcl_enchanting.get_random_glyph_row()
	local glyphs = ""
	local x = 1.3
	for _ = 1, 9 do
		glyphs = glyphs ..
			"image[" .. x .. ",0.1;0.5,0.5;mcl_enchanting_glyph_" .. math.random(18) .. ".png^[colorize:#675D49:255]"
		x = x + 0.6
	end
	return glyphs
end

function mcl_enchanting.generate_random_table_slots(itemstack, num_bookshelves)
	local base = math.random(8) + math.floor(num_bookshelves / 2) + math.random(0, num_bookshelves)
	local required_levels = {
		math.max(base / 3, 1),
		(base * 2) / 3 + 1,
		math.max(base, num_bookshelves * 2)
	}
	local slots = {}
	for i, enchantment_level in ipairs(required_levels) do
		local slot = false
		local enchantments, description = mcl_enchanting.generate_random_enchantments(itemstack, enchantment_level)
		if enchantments then
			slot = { ---@diagnostic disable-line: cast-local-type
				enchantments = enchantments,
				description = description,
				glyphs = mcl_enchanting.get_random_glyph_row(),
				level_requirement = math.max(i, math.floor(enchantment_level)),
			}
		end
		slots[i] = slot
	end
	return slots
end

function mcl_enchanting.get_table_slots(player, itemstack, num_bookshelves)
	local itemname = itemstack:get_name()
	if (not mcl_enchanting.can_enchant_freshly(itemname)) or mcl_enchanting.not_enchantable_on_enchanting_table(itemname) then
		return { false, false, false }
	end
	local meta = player:get_meta()
	local player_slots = core.deserialize(meta:get_string("mcl_enchanting:slots")) or {}
	local player_bookshelves_slots = player_slots[num_bookshelves] or {}
	local player_bookshelves_item_slots = player_bookshelves_slots[itemname]
	if player_bookshelves_item_slots then
		return player_bookshelves_item_slots
	else
		player_bookshelves_item_slots = mcl_enchanting.generate_random_table_slots(itemstack, num_bookshelves)
		if player_bookshelves_item_slots then
			player_bookshelves_slots[itemname] = player_bookshelves_item_slots
			player_slots[num_bookshelves] = player_bookshelves_slots
			meta:set_string("mcl_enchanting:slots", core.serialize(player_slots))
			return player_bookshelves_item_slots
		else
			return { false, false, false }
		end
	end
end

function mcl_enchanting.reset_table_slots(player)
	player:get_meta():set_string("mcl_enchanting:slots", "")
end

function mcl_enchanting.show_enchanting_formspec(player)
	local C = core.get_color_escape_sequence
	local name = player:get_player_name()
	local meta = player:get_meta()
	local inv = player:get_inventory()
	local num_bookshelves = meta:get_int("mcl_enchanting:num_bookshelves")
	local table_name = meta:get_string("mcl_enchanting:table_name")

	local formspec = table.concat({
		"formspec_version[4]",
		"size[11.75,10.425]",

		"label[0.375,0.375;" .. F(C(mcl_formspec.label_color) .. table_name) .. "]",
		mcl_formspec.get_itemslot_bg_v4(1, 3.25, 1, 1),
		"list[current_player;enchanting_item;1,3.25;1,1]",
		mcl_formspec.get_itemslot_bg_v4(2.25, 3.25, 1, 1),
		"image[2.25,3.25;1,1;mcl_enchanting_lapis_background.png]",
		"list[current_player;enchanting_lapis;2.25,3.25;1,1]",
		"image[4.125,0.56;7.25,4.1;mcl_enchanting_button_background.png]",
		"label[0.375,4.7;" .. F(C(mcl_formspec.label_color) .. S("Inventory")) .. "]",
		mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3),
		"list[current_player;main;0.375,5.1;9,3;9]",

		mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1),
		"list[current_player;main;0.375,9.05;9,1;]",

		"listring[current_player;enchanting_item]",
		"listring[current_player;main]",
		"listring[current_player;enchanting]",
		"listring[current_player;main]",
		"listring[current_player;enchanting_lapis]",
		"listring[current_player;main]",
	})

	local itemstack = inv:get_stack("enchanting_item", 1)
	local player_levels = mcl_experience.get_level(player)
	local is_creative = core.is_creative_enabled(name)
	local y = 0.65
	local any_enchantment = false
	local table_slots = mcl_enchanting.get_table_slots(player, itemstack, num_bookshelves)
	for i, slot in ipairs(table_slots) do
		any_enchantment = any_enchantment or slot
		local enough_lapis = inv:contains_item("enchanting_lapis", ItemStack({ name = "mcl_core:lapis", count = i }))
		local enough_levels = slot and slot.level_requirement <= player_levels or is_creative
		local can_enchant = (slot and enough_lapis and enough_levels)
		local level_tooltip = ""
		if slot and not is_creative then
			if enough_levels then
				level_tooltip = "\n" .. C("#818181") .. F(S("@1 Enchantment Levels", i))
			else
				level_tooltip = "\n" .. C("#FC5454") .. F(S("Level requirement: @1", slot.level_requirement))
			end
		end
		local ending = (can_enchant and "" or "_off")
		local hover_ending = (can_enchant and "_hovered" or "_off")
		formspec = formspec
			.. "container[4.125," .. y .. "]"
			..
			(
				slot and
				"tooltip[button_" ..
				i ..
				";" ..
				C("#818181") ..
				((slot.description and F(slot.description)) or "") ..
				" " ..
				C("#FFFFFF") ..
				" . . . ?\n\n" ..
				C(enough_lapis and "#818181" or "#FC5454") ..
					F(S("@1 Lapis Lazuli", i)) ..
				level_tooltip ..
				"]" or "")
			..
			"style[button_" ..
			i ..
			";bgimg=mcl_enchanting_button" ..
			ending ..
			".png;bgimg_hovered=mcl_enchanting_button" ..
			hover_ending .. ".png;bgimg_pressed=mcl_enchanting_button" .. hover_ending .. ".png]"
			.. "button[0,0;7.25,1.3;button_" .. i .. ";]"
			.. (slot and "image[0,0;1.3,1.3;mcl_enchanting_number_" .. i .. ending .. ".png]" or "")
			.. (slot and "label[6.8,1;" .. C(can_enchant and "#80FF20" or "#407F10") .. slot.level_requirement .. "]" or "")
			.. (slot and slot.glyphs or "")
			.. "container_end[]"
		y = y + 1.3
	end
	formspec = formspec
		..
		"image[" ..
		(any_enchantment and 1.1 or 1.67) ..
		",1.2;" ..
		(any_enchantment and 2 or 0.87) ..
		",1.43;mcl_enchanting_book_" .. (any_enchantment and "open" or "closed") .. ".png]"
	core.show_formspec(name, "mcl_enchanting:table", formspec)
end

function mcl_enchanting.handle_formspec_fields(player, formname, fields)
	if formname == "mcl_enchanting:table" then
		local button_pressed
		for i = 1, 3 do
			if fields["button_" .. i] then
				button_pressed = i
			end
		end
		if not button_pressed then return end
		local name = player:get_player_name()
		local inv = player:get_inventory()
		local meta = player:get_meta()
		local num_bookshelfes = meta:get_int("mcl_enchanting:num_bookshelves")
		local itemstack = inv:get_stack("enchanting_item", 1)
		local cost = ItemStack({ name = "mcl_core:lapis", count = button_pressed })
		if not inv:contains_item("enchanting_lapis", cost) then
			return
		end
		local slots = mcl_enchanting.get_table_slots(player, itemstack, num_bookshelfes)
		local slot = slots[button_pressed]
		if not slot then
			return
		end
		if not core.is_creative_enabled(name) then
			local player_level = mcl_experience.get_level(player)
			if player_level < slot.level_requirement then
				return
			end
			mcl_experience.set_level(player, player_level - button_pressed)
		end
		inv:remove_item("enchanting_lapis", cost)
		mcl_enchanting.set_enchanted_itemstring(itemstack)
		mcl_enchanting.set_enchantments(itemstack, slot.enchantments)
		inv:set_stack("enchanting_item", 1, itemstack)
		core.sound_play("mcl_enchanting_enchant", { to_player = name, gain = 5.0 })
		mcl_enchanting.reset_table_slots(player)
		mcl_enchanting.show_enchanting_formspec(player)
		awards.unlock(player:get_player_name(), "mcl:enchanter")
	end
end
core.register_on_player_receive_fields(mcl_enchanting.handle_formspec_fields)

-------------------------------------------------------------------------------
-- ENCHANTING TABLE INVENTORY
-------------------------------------------------------------------------------

mcl_enchanting.enchanting_lists = {"enchanting", "enchanting_item", "enchanting_lapis"}

function mcl_enchanting.initialize_player(player)
	local inv = player:get_inventory()
	inv:set_size("enchanting", 1)
	inv:set_size("enchanting_item", 1)
	inv:set_size("enchanting_lapis", 1)
end
core.register_on_joinplayer(mcl_enchanting.initialize_player)

function mcl_enchanting.is_enchanting_inventory_action(action, inventory, inventory_info)
	if inventory:get_location().type == "player" then
		local enchanting_lists = mcl_enchanting.enchanting_lists
		if action == "move" then
			local is_from = table.indexof(enchanting_lists, inventory_info.from_list) ~= -1
			local is_to = table.indexof(enchanting_lists, inventory_info.to_list) ~= -1
			return is_from or is_to, is_to
		elseif (action == "put" or action == "take") and table.indexof(enchanting_lists, inventory_info.listname) ~= -1 then
			return true
		end
	else
		return false
	end
end

function mcl_enchanting.allow_inventory_action(_, action, inventory, inventory_info)
	local is_enchanting_action, do_limit = mcl_enchanting.is_enchanting_inventory_action(action, inventory,
		inventory_info)
	if is_enchanting_action and do_limit then
		if action == "move" then
			local listname = inventory_info.to_list
			local stack = inventory:get_stack(inventory_info.from_list, inventory_info.from_index)
			if stack:get_name() == "mcl_core:lapis" and listname ~= "enchanting_item" then
				local count = stack:get_count()
				local old_stack = inventory:get_stack("enchanting_lapis", 1)
				if old_stack:get_name() ~= "" then
					count = math.min(count, old_stack:get_free_space())
				end
				return count
			elseif inventory:get_stack("enchanting_item", 1):get_count() == 0 and listname ~= "enchanting_lapis" then
				return 1
			else
				return 0
			end
		else
			return 0
		end
	end
end
core.register_allow_player_inventory_action(mcl_enchanting.allow_inventory_action)

function mcl_enchanting.on_inventory_action(player, action, inventory, inventory_info)
	if mcl_enchanting.is_enchanting_inventory_action(action, inventory, inventory_info) then
		if action == "move" and inventory_info.to_list == "enchanting" then
			local stack = inventory:get_stack("enchanting", 1)
			local result_list
			if stack:get_name() == "mcl_core:lapis" then
				result_list = "enchanting_lapis"
				stack:add_item(inventory:get_stack("enchanting_lapis", 1))
			else
				result_list = "enchanting_item"
			end
			inventory:set_stack(result_list, 1, stack)
			inventory:set_stack("enchanting", 1, nil)
		end
		mcl_enchanting.show_enchanting_formspec(player)
	end
end
core.register_on_player_inventory_action(mcl_enchanting.on_inventory_action)

-------------------------------------------------------------------------------
-- BOOK ENTITY
-------------------------------------------------------------------------------

mcl_enchanting.book_offset = vector.new(0, 0.75, 0)
mcl_enchanting.book_animations = {["close"] = 1, ["opening"] = 2, ["open"] = 3, ["closing"] = 4}
mcl_enchanting.book_animation_steps = {0, 640, 680, 700, 740}
mcl_enchanting.book_animation_loop = {["open"] = true, ["close"] = true}
mcl_enchanting.book_animation_speed = 40

local function spawn_book_entity(pos, respawn)
	if respawn then
		-- Check if we already have a book
		for obj in core.objects_inside_radius(pos, 1) do
			local lua = obj:get_luaentity()
			if lua and lua.name == "mcl_enchanting:book" then
				if lua._table_pos and vector.equals(pos, lua._table_pos) then
					return
				end
			end
		end
	end
	local obj = core.add_entity(vector.add(pos, mcl_enchanting.book_offset), "mcl_enchanting:book")
	if obj then
		local lua = obj:get_luaentity()
		if lua then
			lua._table_pos = table.copy(pos)
		end
	end
end

function mcl_enchanting.schedule_book_animation(self, anim)
	self.scheduled_anim = { timer = self.anim_length, anim = anim }
end

function mcl_enchanting.set_book_animation(self, anim)
	local anim_index = mcl_enchanting.book_animations[anim]
	local start, stop = mcl_enchanting.book_animation_steps[anim_index],
		mcl_enchanting.book_animation_steps[anim_index + 1]
	self.object:set_animation({ x = start, y = stop }, mcl_enchanting.book_animation_speed, 0,
		mcl_enchanting.book_animation_loop[anim] or false)
	self.scheduled_anim = nil
	self.anim_length = (stop - start) / 40
end

function mcl_enchanting.check_animation_schedule(self, dtime)
	local schedanim = self.scheduled_anim
	if schedanim then
		schedanim.timer = schedanim.timer - dtime
		if schedanim.timer <= 0 then
			mcl_enchanting.set_book_animation(self, schedanim.anim)
		end
	end
end

function mcl_enchanting.look_at(self, pos2)
	local pos1 = self.object:get_pos()
	local vec = vector.subtract(pos1, pos2)
	local yaw = math.atan(vec.z / vec.x) - math.pi / 2
	yaw = yaw + (pos1.x >= pos2.x and math.pi or 0)
	self.object:set_yaw(yaw + math.pi)
end

core.register_entity("mcl_enchanting:book", {
	initial_properties = {
		visual = "mesh",
		mesh = "mcl_enchanting_book.b3d",
		visual_size = {x = 12.5, y = 12.5},
		collisionbox = {0, 0, 0},
		pointable = false,
		physical = false,
		textures = {"mcl_enchanting_book_entity.png", "mcl_enchanting_book_entity.png", "mcl_enchanting_book_entity.png", "mcl_enchanting_book_entity.png", "mcl_enchanting_book_entity.png"},
		static_save = false,
	},
	_player_near = false,
	_table_pos = nil,
	on_activate = function(self, _)
		self.object:set_armor_groups({immortal = 1})
		mcl_enchanting.set_book_animation(self, "close")
	end,
	on_step = function(self, dtime)
		local old_player_near = self._player_near
		local player_near = false
		local player
		for obj in core.objects_inside_radius(vector.subtract(self.object:get_pos(), mcl_enchanting.book_offset), 2.5) do
			if obj:is_player() then
				player_near = true
				player = obj
			end
		end
		if player_near and not old_player_near then
			mcl_enchanting.set_book_animation(self, "opening")
			mcl_enchanting.schedule_book_animation(self, "open")
		elseif old_player_near and not player_near then
			mcl_enchanting.set_book_animation(self, "closing")
			mcl_enchanting.schedule_book_animation(self, "close")
		end
		if player then
			mcl_enchanting.look_at(self, player:get_pos())
		end
		self._player_near = player_near
		mcl_enchanting.check_animation_schedule(self, dtime)
	end,
	_mcl_pistons_unmovable = true
})

core.register_lbm({
	label = "(Re-)spawn book entity above enchanting table",
	name = "mcl_enchanting:spawn_book_entity",
	nodenames = {"mcl_enchanting:table"},
	run_at_every_load = true,
	action = function(pos)
		spawn_book_entity(pos, true)
	end,
})

-------------------------------------------------------------------------------
-- ENCHANTING TABLE
-------------------------------------------------------------------------------

core.register_node("mcl_enchanting:table", {
	description = S("Enchanting Table"),
	_tt_help = S("Spend experience, and lapis to enchant various items."),
	_doc_items_longdesc = S("Enchanting Tables will let you enchant armors, tools, weapons, and books with various abilities. But, at the cost of some experience, and lapis lazuli."),
	_doc_items_usagehelp =
			S("Rightclick the Enchanting Table to open the enchanting menu.").."\n"..
			S("Place a tool, armor, weapon or book into the top left slot, and then place 1-3 Lapis Lazuli in the slot to the right.").."\n".."\n"..
			S("After placing your items in the slots, the enchanting options will be shown. Hover over the options to read what is available to you.").."\n"..
			S("These options are randomized, and dependent on experience level; but the enchantment strength can be increased.").."\n".."\n"..
			S("To increase the enchantment strength, place bookshelves around the enchanting table. However, you will need to keep 1 air node between the table, & the bookshelves to empower the enchanting table.").."\n".."\n"..
			S("After finally selecting your enchantment; left-click on the selection, and you will see both the lapis lazuli and your experience levels consumed. And, an enchanted item left in its place."),
	_doc_items_hidden = false,
	drawtype = "nodebox",
	tiles = {"mcl_enchanting_table_top.png",  "mcl_enchanting_table_bottom.png", "mcl_enchanting_table_side.png", "mcl_enchanting_table_side.png", "mcl_enchanting_table_side.png", "mcl_enchanting_table_side.png"},
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 0.25, 0.5},
	},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	groups = {pickaxey = 2, deco_block = 1, unmovable_by_piston = 1, pathfinder_partial = 2},
	on_rotate = screwdriver.rotate_simple,
	on_rightclick = function(pos, _, clicker)
		local player_meta = clicker:get_meta()
		--local table_meta = core.get_meta(pos)
		--local num_bookshelves = table_meta:get_int("mcl_enchanting:num_bookshelves")
		local table_name = core.get_meta(pos):get_string("name")
		if table_name == "" then
			table_name = S("Enchant")
		end
		local bookshelves = mcl_enchanting.get_bookshelves(pos)
		player_meta:set_int("mcl_enchanting:num_bookshelves", math.min(15, #bookshelves))
		player_meta:set_string("mcl_enchanting:table_name", table_name)
		mcl_enchanting.show_enchanting_formspec(clicker)
		-- Respawn book entity just in case it got lost
		spawn_book_entity(pos, true)
	end,
	on_construct = function(pos)
		spawn_book_entity(pos)
	end,
	after_dig_node = function(pos, _, _ , digger)
		local dname = (digger and digger:get_player_name()) or ""
		if core.is_creative_enabled(dname) then
			return
		end
		local itemstack = ItemStack("mcl_enchanting:table")
		local meta = core.get_meta(pos)
		local itemmeta = itemstack:get_meta()
		itemmeta:set_string("name", meta:get_string("name"))
		itemmeta:set_string("description", meta:get_string("description"))
		core.add_item(pos, itemstack)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing) ---@diagnostic disable-line: unused-local
		local meta = core.get_meta(pos)
		local itemmeta = itemstack:get_meta()
		meta:set_string("name", itemmeta:get_string("name"))
		meta:set_string("description", itemmeta:get_string("description"))
	end,
	after_destruct = function(pos)
		for obj in core.objects_inside_radius(pos, 1) do
			local lua = obj:get_luaentity()
			if lua and lua.name == "mcl_enchanting:book" then
				if lua._table_pos and vector.equals(pos, lua._table_pos) then
					obj:remove()
				end
			end
		end
	end,
	drop = "",
	_mcl_blast_resistance = 1200,
	_mcl_hardness = 5,
	paramtype = "light",
	light_source = 7,
})

core.register_craft({
	output = "mcl_enchanting:table",
	recipe = {
		{"", "mcl_books:book", ""},
		{"mcl_core:diamond", "mcl_core:obsidian", "mcl_core:diamond"},
		{"mcl_core:obsidian", "mcl_core:obsidian", "mcl_core:obsidian"}
	}
})

core.register_abm({
	label = "Enchanting table bookshelf particles",
	interval = 1,
	chance = 1,
	nodenames = "mcl_enchanting:table",
	action = function(pos)
		local playernames = {}
		for obj in core.objects_inside_radius(pos, 15) do
			if obj:is_player() then
				table.insert(playernames, obj:get_player_name())
			end
		end
		if #playernames < 1 then
			return
		end
		local absolute, relative = mcl_enchanting.get_bookshelves(pos)
		for i, ap in ipairs(absolute) do
			if math.random(5) == 1 then
				local rp = relative[i]
				local t = math.random()+1 --time
				local d = {x = rp.x, y=rp.y-0.7, z=rp.z} --distance
				local v = {x = -math.random()*d.x, y = math.random(), z = -math.random()*d.z} --velocity
				local a = {x = 2*(-v.x*t - d.x)/t/t, y = 2*(-v.y*t - d.y)/t/t, z = 2*(-v.z*t - d.z)/t/t} --acceleration
				local s = math.random()+0.9 --size
				t = t - 0.1 --slightly decrease time to avoid texture overlappings
				local tx = "mcl_enchanting_glyph_" .. math.random(18) .. ".png"
				for _, name in pairs(playernames) do
					core.add_particle({
						pos = ap,
						velocity = v,
						acceleration = a,
						expirationtime = t,
						size = s,
						texture = tx,
						collisiondetection = false,
						playername = name
					})
				end
			end
		end
	end
})
