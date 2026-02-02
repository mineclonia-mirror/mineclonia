local deepslate_max = mcl_worlds.layer_to_y(16)
local deepslate_min = mcl_vars.mg_overworld_min

local mountains = {
	"ExtremeHills", "ExtremeHills_beach", "ExtremeHills_ocean", "ExtremeHills_deep_ocean", "ExtremeHills_underground",
	"ExtremeHills+", "ExtremeHills+_ocean", "ExtremeHills+_deep_ocean", "ExtremeHills+_underground",
	"ExtremeHillsM", "ExtremeHillsM_ocean", "ExtremeHillsM_deep_ocean", "ExtremeHillsM_underground",
}

local mesa = {
	"Mesa", "Mesa_sandlevel", "Mesa_ocean", "MesaBryce", "MesaBryce_sandlevel",
	"MesaBryce_ocean", "MesaPlateauF", "MesaPlateauF_sandlevel", "MesaPlateauF_ocean",
	"MesaPlateauFM", "MesaPlateauFM_sandlevel", "MesaPlateauFM_ocean",
}

--Clay
core.register_ore({
	ore_type       = "blob",
	ore            = "mcl_core:clay",
	wherein        = {"mcl_core:sand","mcl_core:stone","mcl_core:gravel"},
	clust_scarcity = 15*15*15,
	clust_num_ores = 33,
	clust_size     = 5,
	y_min          = -5,
	y_max          = 0,
	noise_params = {
		offset  = 0,
		scale   = 1,
		spread  = {x=250, y=250, z=250},
		seed    = 34843,
		octaves = 3,
		persist = 0.6,
		lacunarity = 2,
		flags = "defaults",
	}
})

-- Diorite, andesite and granite
local specialstones = { "mcl_core:diorite", "mcl_core:andesite", "mcl_core:granite" }
for s=1, #specialstones do
	local node = specialstones[s]
	core.register_ore({
		ore_type       = "blob",
		ore            = node,
		wherein        = {"mcl_core:stone"},
		clust_scarcity = 15*15*15,
		clust_num_ores = 33,
		clust_size     = 5,
		y_min          = mcl_vars.mg_overworld_min_old,
		y_max          = mcl_vars.mg_overworld_max,
		noise_params = {
			offset  = 0,
			scale   = 1,
			spread  = {x=250, y=250, z=250},
			seed    = 12345,
			octaves = 3,
			persist = 0.6,
			lacunarity = 2,
			flags = "defaults",
		}
	})
	core.register_ore({
		ore_type       = "blob",
		ore            = node,
		wherein        = {"mcl_core:stone"},
		clust_scarcity = 10*10*10,
		clust_num_ores = 58,
		clust_size     = 7,
		y_min          = mcl_vars.mg_overworld_min_old,
		y_max          = mcl_vars.mg_overworld_max,
		noise_params = {
			offset  = 0,
			scale   = 1,
			spread  = {x=250, y=250, z=250},
			seed    = 12345,
			octaves = 3,
			persist = 0.6,
			lacunarity = 2,
			flags = "defaults",
		}
	})
end

local stonelike = {"mcl_core:stone", "mcl_core:diorite", "mcl_core:andesite", "mcl_core:granite"}

-- Dirt
core.register_ore({
	ore_type       = "blob",
	ore            = "mcl_core:dirt",
	wherein        = stonelike,
	clust_scarcity = 15*15*15,
	clust_num_ores = 33,
	clust_size     = 4,
	y_min          = mcl_vars.mg_overworld_min_old,
	y_max          = mcl_vars.mg_overworld_max,
	noise_params = {
		offset  = 0,
		scale   = 1,
		spread  = {x=250, y=250, z=250},
		seed    = 12345,
		octaves = 3,
		persist = 0.6,
		lacunarity = 2,
		flags = "defaults",
	}
})

-- Gravel
core.register_ore({
	ore_type       = "blob",
	ore            = "mcl_core:gravel",
	wherein        = stonelike,
	clust_scarcity = 14*14*14,
	clust_num_ores = 33,
	clust_size     = 5,
	y_min          = mcl_vars.mg_overworld_min_old,
	y_max          = mcl_worlds.layer_to_y(111),
	noise_params = {
		offset  = 0,
		scale   = 1,
		spread  = {x=250, y=250, z=250},
		seed    = 12345,
		octaves = 3,
		persist = 0.6,
		lacunarity = 2,
		flags = "defaults",
	}
})

core.register_ore({
	ore_type       = "blob",
	ore            = "mcl_deepslate:deepslate",
	wherein        = { "mcl_core:stone" },
	clust_scarcity = 200,
	clust_num_ores = 100,
	clust_size     = 10,
	y_min          = deepslate_min,
	y_max          = deepslate_max,
	noise_params = {
		offset  = 0,
		scale   = 1,
		spread  = { x = 250, y = 250, z = 250 },
		seed    = 12345,
		octaves = 3,
		persist = 0.6,
		lacunarity = 2,
		flags = "defaults",
	}
})

core.register_ore({
	ore_type       = "blob",
	ore            = "mcl_deepslate:tuff",
	wherein        = { "mcl_core:stone", "mcl_core:diorite", "mcl_core:andesite", "mcl_core:granite", "mcl_deepslate:deepslate" },
	clust_scarcity = 10*10*10,
	clust_num_ores = 58,
	clust_size     = 7,
	y_min          = deepslate_min,
	y_max          = deepslate_max,
	noise_params = {
		offset  = 0,
		scale   = 1,
		spread  = {x=250, y=250, z=250},
		seed    = 12345,
		octaves = 3,
		persist = 0.6,
		lacunarity = 2,
		flags = "defaults",
	}
})

core.register_ore({
	ore_type       = "scatter",
	ore            = "mcl_deepslate:infested_deepslate",
	wherein        = "mcl_deepslate:deepslate",
	clust_scarcity = 26 * 26 * 26,
	clust_num_ores = 3,
	clust_size     = 2,
	y_min          = deepslate_min,
	y_max          = deepslate_max,
	biomes         = mountains,
})

core.register_ore({
	ore_type       = "scatter",
	ore            = "mcl_core:water_source",
	wherein        = "mcl_deepslate:deepslate",
	clust_scarcity = 9000,
	clust_num_ores = 1,
	clust_size     = 1,
	y_min          = mcl_worlds.layer_to_y(5),
	y_max          = deepslate_max,
})

core.register_ore({
	ore_type       = "scatter",
	ore            = "mcl_core:lava_source",
	wherein        = "mcl_deepslate:deepslate",
	clust_scarcity = 2000,
	clust_num_ores = 1,
	clust_size     = 1,
	y_min          = mcl_worlds.layer_to_y(1),
	y_max          = mcl_worlds.layer_to_y(10),
})

core.register_ore({
	ore_type       = "scatter",
	ore            = "mcl_core:lava_source",
	wherein        = "mcl_deepslate:deepslate",
	clust_scarcity = 9000,
	clust_num_ores = 1,
	clust_size     = 1,
	y_min          = mcl_worlds.layer_to_y(11),
	y_max          = deepslate_max,
})

if core.settings:get_bool("mcl_generate_ores", true) then
	--
	-- Ancient debris
	--
	local ancient_debris_wherein = {"mcl_nether:netherrack","mcl_blackstone:blackstone","mcl_blackstone:basalt"}
	-- Common spawn
	core.register_ore({
		ore_type       = "scatter",
		ore            = "mcl_nether:ancient_debris",
		wherein         = ancient_debris_wherein,
		clust_scarcity = 15000,
		-- in MC it's 0.004% chance (~= scarcity 25000) but reports and experiments show that ancient debris is unreasonably hard to find in survival with that value
		clust_num_ores = 3,
		clust_size     = 3,
		y_min = mcl_vars.mg_nether_min + 8,
		y_max = mcl_vars.mg_nether_min + 22,
	})

	-- Rare spawn (below)
	core.register_ore({
		ore_type       = "scatter",
		ore            = "mcl_nether:ancient_debris",
		wherein         = ancient_debris_wherein,
		clust_scarcity = 32000,
		clust_num_ores = 2,
		clust_size     = 3,
		y_min = mcl_vars.mg_nether_min,
		y_max = mcl_vars.mg_nether_min + 8,
	})

	-- Rare spawn (above)
	core.register_ore({
		ore_type       = "scatter",
		ore            = "mcl_nether:ancient_debris",
		wherein         = ancient_debris_wherein,
		clust_scarcity = 32000,
		clust_num_ores = 2,
		clust_size     = 3,
		y_min = mcl_vars.mg_nether_min + 22,
		y_max = mcl_vars.mg_nether_min + 119,
	})

	local stonelike = { "mcl_core:stone", "mcl_core:diorite", "mcl_core:andesite", "mcl_core:granite" }

	local function register_ore_mg(ore, wherein, defs)
		core.register_ore({
			ore_type       = "scatter",
			ore            = ore,
			wherein        = wherein,
			clust_scarcity = defs[1],
			clust_num_ores = defs[2],
			clust_size     = defs[3],
			y_min          = defs[4],
			y_max          = defs[5],
			biomes		   = defs[6],
		})
	end

	-- Methodology for transforming MC wiki values:
	--
	-- MC tries per chunk are multiplied by 25 (default chunksize^2). For
	-- non uniform distribution tries are distributed to height layers
	-- usually 16 or 32 blocks high. This large height is on the coarse
	-- side, but unfortunately thinner layers would easily exceed the
	-- supported scarcity range for rare ores.
	--
	-- Distribution of tries is mostly chosen to give 'nice' scarcity
	-- values, i.e. number of tries evenly divide 80x80, to prevent
	-- unexpected ore node loss due to rounding in the engine with default
	-- chunksize 5. 8, 16, 25, 32, 40, 50, 64, 80, 100 are 'good' values for
	-- number of tries in a height range.
	--
	-- Luanti clust_scarcity = (volume / (MC tries * 25))
	--
	-- Volume usually is (80^2 * (y_max-y_min)), but chunk borders may need
	-- to be taken into account for rarer ores; the most relevant chunk
	-- borders for default chunksize 5 are at y = -48 and y = 32.
	--
	-- Tries per height range may be aggregated to prevent scarcity from
	-- coming close to the engine supported scarcity limit - beyond which no
	-- ore will be generated at all - or to get better values.
	--
	-- Split of tries between stone and deepslate:
	-- - all tries for range [-128, -65] go to deepslate
	-- - all tries for range [-48, +inf] go to stone
	-- - tries for range [-64, -49] are doubled for deepslate and stone (the
	--   assumption being that around half the nodes will hit the wrong
	--   stone type and get discarded by the engine; as always numbers may
	--   be jiggled a bit to get 'nice' scarcity values)
	--
	-- MC spawn size values are converted to clust_size/clust_num_ores with
	-- hopefully similar average number of ore nodes in a cluster (there
	-- seems to be little data on actual MC ore cluster size distribution,
	-- Luanti scatter ores have a binomial distribution). Values get tweaked
	-- to account for air exposure reduction using the following
	-- assumptions:
	-- - ~50% of clusters will be intersected by a cave
	-- - ~33% of nodes exposed to air
	-- -> (100 * <air exposure reduction factor> / 6)% nodes lost
	-- -> adapt tries to account for too large/small reduction, because of
	--    coarse value range for clust_num_ores (cluster size may need to
	--    be adjusted similarly to get better scarcity values)
	--
	-- Challenges:
	-- - partial tries per chunk are not (well) supported by Luanti ores
	--   (see https://github.com/luanti-org/luanti/issues/16065)
	-- - Luanti ores can't place different ore nodes depending on
	--   replaced node (making it necessary to separate stone and deepslate
	--   ores)
	-- - Luanti's calculation of number of ore nodes in a cluster and
	--   cluster shape seems very different from MC
	local ore_mapgen = {
		["deepslate"] = {
			["coal"] = {
				{ 1575, 5, 3, deepslate_min, deepslate_max },
				{ 1530, 8, 3, deepslate_min, deepslate_max },
				{ 1500, 12, 3, deepslate_min, deepslate_max },
			},
			["iron"] = {
				{ 830, 5, 3, deepslate_min, deepslate_max },
			},
			["gold"] = {
				{ 4775, 5, 3, deepslate_min, deepslate_max },
				{ 6560, 7, 3, deepslate_min, deepslate_max },
			},
			["diamond"] = {
				{ 10000, 4, 3, deepslate_min, mcl_worlds.layer_to_y(12) },
				{ 5000, 2, 3, deepslate_min, mcl_worlds.layer_to_y(12) },
				{ 10000, 8, 3, deepslate_min, mcl_worlds.layer_to_y(12) },
				{ 20000, 1, 1, mcl_worlds.layer_to_y(13), mcl_worlds.layer_to_y(15) },
				{ 20000, 2, 2, mcl_worlds.layer_to_y(13), mcl_worlds.layer_to_y(15) },
			},
			["redstone"] = {
				{ 500, 4, 3, deepslate_min, mcl_worlds.layer_to_y(13) },
				{ 800, 7, 4, deepslate_min, mcl_worlds.layer_to_y(13) },
				{ 1000, 4, 3, mcl_worlds.layer_to_y(13), mcl_worlds.layer_to_y(15) },
				{ 1600, 7, 4, mcl_worlds.layer_to_y(13), mcl_worlds.layer_to_y(15) },
			},
			["lapis"] = {
				-- spawnsize 7, max 10 nodes
				-- -> num = 5, size = 3 (~99% 1-10 nodes)
				-- 4 tries per chunk, uniform, [-64, 64]
				-- -> 62.5 tries in deepslate (+ 50 tries in stone)
				-- 62.5 tries [ -64,  15]
				{ 8192, 5, 3,  -128, -49 },
				-- 2 tries per chunk, triangular, 0+-32
				-- air exposure reduction factor 1.0
				-- -> num -= 1 (-20%), size -= 1, -> upgrade to ~2.5 tries per chunk
				-- -> 58 tries in deepslate (+ 33 tries in stone)
				-- 8 tries    [-32, -17]
				{  6400, 4, 2, -96, -81 },
				-- 50 tries   [-16,  15]
				{  4096, 4, 2, -80, -49 },
			},
			["emerald"] = {
				{ 16384, 1, 1, mcl_worlds.layer_to_y(4), deepslate_max, mountains },
			},
			["copper"] = {
				{ 830, 5, 3, deepslate_min, deepslate_max },
			}
		},
		["stone"] = {
			["coal"] = {
				{ 525*3, 5, 3, mcl_vars.mg_overworld_min, mcl_worlds.layer_to_y(50) },
				{ 510*3, 8, 3, mcl_vars.mg_overworld_min, mcl_worlds.layer_to_y(50) },
				{ 500*3, 12, 3, mcl_vars.mg_overworld_min, mcl_worlds.layer_to_y(50) },
				{ 550*3, 4, 2, mcl_worlds.layer_to_y(51), mcl_worlds.layer_to_y(80) },
				{ 525*3, 6, 3, mcl_worlds.layer_to_y(51), mcl_worlds.layer_to_y(80) },
				{ 500*3, 8, 3, mcl_worlds.layer_to_y(51), mcl_worlds.layer_to_y(80) },
				{ 600*3, 3, 2, mcl_worlds.layer_to_y(81), mcl_worlds.layer_to_y(128) },
				{ 550*3, 4, 3, mcl_worlds.layer_to_y(81), mcl_worlds.layer_to_y(128) },
				{ 500*3, 5, 3, mcl_worlds.layer_to_y(81), mcl_worlds.layer_to_y(128) },
			},
			["iron"] = {
				{ 830, 5, 3, mcl_vars.mg_overworld_min, mcl_worlds.layer_to_y(39) },
				{ 1660, 4, 2, mcl_worlds.layer_to_y(40), mcl_worlds.layer_to_y(63) },
			},
			["gold"] = {
				{ 4775, 5, 3, mcl_vars.mg_overworld_min, mcl_worlds.layer_to_y(30) },
				{ 6560, 7, 3, mcl_vars.mg_overworld_min, mcl_worlds.layer_to_y(30) },
				{ 13000, 4, 2, mcl_worlds.layer_to_y(31), mcl_worlds.layer_to_y(33) },
				{ 3333, 5, 3, mcl_worlds.layer_to_y(32), mcl_worlds.layer_to_y(79), mesa }
			},
			["diamond"] = {
				{ 10000, 4, 3, mcl_vars.mg_overworld_min, mcl_worlds.layer_to_y(12) },
				{ 5000, 2, 2, mcl_vars.mg_overworld_min, mcl_worlds.layer_to_y(12) },
				{ 10000, 8, 3, mcl_vars.mg_overworld_min, mcl_worlds.layer_to_y(12) },
				{ 20000, 1, 1, mcl_worlds.layer_to_y(13), mcl_worlds.layer_to_y(15) },
				{ 20000, 2, 2, mcl_worlds.layer_to_y(13), mcl_worlds.layer_to_y(15) },
			},
			["redstone"] = {
				{ 500, 4, 3, mcl_vars.mg_overworld_min, mcl_worlds.layer_to_y(13) },
				{ 800, 7, 4, mcl_vars.mg_overworld_min, mcl_worlds.layer_to_y(13) },
				{ 1000, 4, 3, mcl_worlds.layer_to_y(13), mcl_worlds.layer_to_y(15) },
				{ 1600, 7, 4, mcl_worlds.layer_to_y(13), mcl_worlds.layer_to_y(15) },
			},
			["lapis"] = {
				-- spawnsize 7, max 10 nodes
				-- -> num = 5, size = 3 (~99% 1-10 nodes)
				-- 4 tries per chunk, uniform, [-64, 64]
				-- -> 50 tries in stone (+ 62.5 tries in deepslate)
				-- 50 tries  [  0, 63]
				{ 8192, 5, 3, -64, -1 },
				-- 2 tries per chunk, triangular, 0+-32
				-- air exposure reduction factor 1.0
				-- -> num -= 1 (-20%), size -= 1, -> upgrade to ~2.5 tries per chunk
				-- -> 33 tries in stone (+ 58 tries in deepslate)
				-- 25 tries   [  0,  15]
				{  4096, 4, 2, -64, -49 },
				-- 8 tries    [ 16,  31]
				{  6400, 4, 2, -48, -33 },
			},
			["copper"] = {
				{ 830, 5, 3, mcl_vars.mg_overworld_min, mcl_worlds.layer_to_y(39) },
				{ 1660, 4, 2, mcl_worlds.layer_to_y(40), mcl_worlds.layer_to_y(63) },
			},
			["emerald"] = {
				{ 16384, 1, 1, mcl_worlds.layer_to_y(4), mcl_worlds.layer_to_y(32), mountains }
			},
		}
	}

	for stone, ore in pairs(ore_mapgen) do
		local modname = ""
		local wherein

		for name, defs in pairs(ore) do
			if stone == "deepslate" then
				modname = "mcl_deepslate"
				wherein = { "mcl_deepslate:deepslate", "mcl_deepslate:tuff" }
			elseif stone == "stone" then
				modname = "mcl_core"
				wherein = stonelike
				if name == "copper" then
					modname = "mcl_copper"
				end
			end
			for _, def in pairs(defs) do
				register_ore_mg(modname..":"..stone.."_with_"..name, wherein, def)
			end
		end
	end
end

if not mcl_vars.superflat then
-- Water and lava springs (single blocks of lava/water source)
-- Water appears at nearly every height, but not near the bottom
core.register_ore({
	ore_type       = "scatter",
	ore            = "mcl_core:water_source",
	wherein         = {"mcl_core:stone", "mcl_core:andesite", "mcl_core:diorite", "mcl_core:granite", "mcl_core:dirt"},
	clust_scarcity = 9000,
	clust_num_ores = 1,
	clust_size     = 1,
	y_min          = mcl_worlds.layer_to_y(5),
	y_max          = mcl_worlds.layer_to_y(128),
})

-- Lava springs are rather common at -31 and below
core.register_ore({
	ore_type       = "scatter",
	ore            = "mcl_core:lava_source",
	wherein         = stonelike,
	clust_scarcity = 2000,
	clust_num_ores = 1,
	clust_size     = 1,
	y_min          = mcl_worlds.layer_to_y(1),
	y_max          = mcl_worlds.layer_to_y(10),
})

core.register_ore({
	ore_type       = "scatter",
	ore            = "mcl_core:lava_source",
	wherein         = stonelike,
	clust_scarcity = 9000,
	clust_num_ores = 1,
	clust_size     = 1,
	y_min          = mcl_worlds.layer_to_y(11),
	y_max          = mcl_worlds.layer_to_y(31),
})

-- Lava springs will become gradually rarer with increasing height
core.register_ore({
	ore_type       = "scatter",
	ore            = "mcl_core:lava_source",
	wherein         = stonelike,
	clust_scarcity = 32000,
	clust_num_ores = 1,
	clust_size     = 1,
	y_min          = mcl_worlds.layer_to_y(32),
	y_max          = mcl_worlds.layer_to_y(47),
})

core.register_ore({
	ore_type       = "scatter",
	ore            = "mcl_core:lava_source",
	wherein         = stonelike,
	clust_scarcity = 72000,
	clust_num_ores = 1,
	clust_size     = 1,
	y_min          = mcl_worlds.layer_to_y(48),
	y_max          = mcl_worlds.layer_to_y(61),
})

-- Lava may even appear above surface, but this is very rare
core.register_ore({
	ore_type       = "scatter",
	ore            = "mcl_core:lava_source",
	wherein         = stonelike,
	clust_scarcity = 96000,
	clust_num_ores = 1,
	clust_size     = 1,
	y_min          = mcl_worlds.layer_to_y(62),
	y_max          = mcl_worlds.layer_to_y(127),
})
end
