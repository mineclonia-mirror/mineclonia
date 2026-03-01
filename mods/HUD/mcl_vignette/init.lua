local S = core.get_translator("mcl_vignette")

local GAMMA = 2.00 -- <https://www.desmos.com/calculator/rwy1wriv5v>
local SMOOTHING = 0.14

-- temporary data tables, all indexed by player ObjectRef
local vignette_huds = {}  -- HUD IDs
local player_opacity = {} -- calculated virtual alpha for interpolation [0.0f..255.0f]
local player_alpha = {}   -- last applied alpha [0..255]

local math_abs = math.abs
local math_floor = math.floor

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function update_vignette_alpha(player)
	local light = core.get_node_light(vector.offset(player:get_pos(), 0, 0.5, 0)) or 0
	local target = 255 * (1 - ((light / core.LIGHT_MAX) ^ GAMMA))
	local cur = player_opacity[player] or target
	cur = 	lerp(cur, target, SMOOTHING)

	if math_abs(cur - target) < 0.5 then -- snap
		cur = target
	end
	player_opacity[player] = cur

	local cur_int = math_floor(cur + 0.5)
	if cur_int ~= player_alpha[player] then
		player_alpha[player] = cur_int
		return cur_int
	end
end

local vignette_def = {
	type = "image",
	position = {x = 0.5, y = 0.5},
	scale = {x = -100, y = -100},
	text = "mcl_vignette_vignette.png^[opacity:0",
	alignment = 0,
	z_index = -400, -- <https://api.luanti.org/hud/#hud-element-types>
}

local function add_vignette(player)
	if not vignette_huds[player] then
		-- initialize with alpha to avoid an awkward ~0.5s delay
		vignette_huds[player] = player:hud_add(table.merge(vignette_def, {
			text = "mcl_vignette_vignette.png^[opacity:" .. update_vignette_alpha(player)
		}))
	end
end

local function remove_vignette(player)
	if vignette_huds[player] then
		player:hud_remove(vignette_huds[player])
		vignette_huds[player] = nil
		player_opacity[player] = nil
		player_alpha[player] = nil
	end
end

mcl_player.register_player_setting("mcl_vignette:vignette_enabled", {
	type = "boolean",
	short_desc = S("Show darkness vignette"),
	section = "Graphics",
	ui_default = "true",
	on_change = function(player, _, value)
		if value == nil or value == true then
			add_vignette(player)
		else
			remove_vignette(player)
		end
	end,
})

mcl_player.register_globalstep(function(player)
	if not mcl_player.get_player_setting(player, "mcl_vignette:vignette_enabled", true) then
		remove_vignette(player)
		player_opacity[player] = nil
		return
	end

	add_vignette(player)
	local new_alpha = update_vignette_alpha(player)
	if new_alpha then
		player:hud_change(vignette_huds[player], "text", "mcl_vignette_vignette.png^[opacity:" .. new_alpha)
	end
end)
