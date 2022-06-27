--Copyright 2021 ShadMOrdre
--License LGPLv2.1


mg_earth = {}
mg_earth.name = "mg_earth"
mg_earth.ver_max = 0
mg_earth.ver_min = 1
mg_earth.ver_rev = 0
mg_earth.ver_str = mg_earth.ver_max .. "." .. mg_earth.ver_min .. "." .. mg_earth.ver_rev
mg_earth.authorship = "ShadMOrdre."
mg_earth.license = "LGLv2.1"
mg_earth.copyright = "2021"
mg_earth.path_mod = minetest.get_modpath(minetest.get_current_modname())
mg_earth.path_world = minetest.get_worldpath()
mg_earth.path = mg_earth.path_mod

minetest.log("[MOD] test:  Loading...")
minetest.log("[MOD] mg_earth:  Version:" .. mg_earth.ver_str)
minetest.log("[MOD] mg_earth:  Legal Info: Copyright " .. mg_earth.copyright .. " " .. mg_earth.authorship .. "")
minetest.log("[MOD] mg_earth:  License: " .. mg_earth.license .. "")

if minetest.get_mapgen_setting("mg_name") ~= "singlenode" then
    return
end

mg_earth.settings = {
    mg_world_scale = tonumber(minetest.settings:get("mg_earth.mg_world_scale")) or 1.0,
    mg_base_height = tonumber(minetest.settings:get("mg_earth.mg_base_height")) or 300,
    sea_level = tonumber(minetest.settings:get("mg_earth.sea_level")) or 1,
    flat_height = tonumber(minetest.settings:get("mg_earth.flat_height")) or 5,
    river_width = tonumber(minetest.settings:get("mg_earth.river_width")) or 5,
    enable_rivers = minetest.settings:get_bool("mg_earth.enable_rivers") or false,
    enable_caves = minetest.settings:get_bool("mg_earth.enable_caves") or false,
    enable_lakes = minetest.settings:get_bool("mg_earth.enable_lakes") or false,
    heat_scalar = minetest.settings:get_bool("mg_earth.enable_heat_scalar") or true,
    humidity_scalar = minetest.settings:get_bool("mg_earth.enable_humidity_scalar") or true,
    -- Options: 1-12.  Default = 1.  See table 'mg_heightmap_select_options' below for description.
    -- 1 = vEarth, 2 = v6, 3 = v7, 4 = v67, 5 = vFlat, 6 = vIslands, 7 = vValleys, 8 = vVoronoi, 9 = vVoronoiPlus, 10 = vSpheres, 11 = vCubes, 12 = vDiamonds, 13 = v3D,
    heightmap = tonumber(minetest.settings:get("mg_earth.heightmap")) or 1,
    -- Options: 1-4.  Default = 4.  1 = chebyshev, 2 = euclidean, 3 = manhattan, 4 = (chebyshev + manthattan) / 2
    voronoi_distance = tonumber(minetest.settings:get("mg_earth.voronoi_distance")) or 4,
    --manual seed options.		The named seeds below were used during dev, but were interesting enough to include.  The names were entered in the menu, and these resulted.
    --Default					= Terraria
    --		Terraria			= "16096304901732432682",
    --		TheIsleOfSodor		= "4866059420164947791",
    --		TheGardenOfEden		= "4093201477345457311",
    -- 		Fermat				= "14971822871466973040",
    --		Patience			= "7986080089770239873",
    --		Home				= "11071344221654115949",
    --		Gaia				= "388272015917266855",
    --		Theia				= "130097141630163915",
    --		Eufrisia			= "6535600191662084952",
    --		Coluerica			= "9359082767202495376",
    --		Pando				= "9237930693197265599",
    --		Pangaea				= "5475850681584857691",
    --		Gondwana			= "11779916298069921535",
    --		Alone				= "11763298958449250406",
    --		Agape				= "12213145824342997182",
    --		Walmart				= "5081532735129490002",
    seed = minetest.settings:get("mg_earth.seed") or "16096304901732432682",
    --voronoi_file				= minetest.settings:get("mg_earth.voronoi_file") or "points_earth",
    --voronoi_file				= "points_earth",					--		"points_dev_isle"
    voronoi_file = tonumber(minetest.settings:get("mg_earth.voronoi_file")) or 1,
    --voronoi_neighbor_file_suf	= minetest.settings:get("mg_earth.voronoi_neighbor_file_suf") or "neighbors",
    voronoi_neighbor_file_suf = "neighbors",
}

--THE FOLLOWING SETTINGS CAN BE CHANGED VIA THE MAIN MENU

minetest.set_mapgen_setting("seed", mg_earth.settings.seed, true)
minetest.set_mapgen_setting("mg_flags", "nocaves, nodungeons, light, decorations, biomes, ores", true)
mg_earth.mg_seed = minetest.get_mapgen_setting("seed")

--World Scale:  Supported values range from 0.01 to 1.0.  This scales the voronoi cells and noise values.
local mg_world_scale = mg_earth.settings.mg_world_scale
if mg_world_scale < 0.01 then
    mg_world_scale = 0.1
elseif mg_world_scale > 1 then
    mg_world_scale = 1
end
--This value is multiplied by 1.4 or added to max v7 noise height.  From this total, cell distance is then subtracted.
local mg_base_height = mg_earth.settings.mg_base_height * mg_world_scale

--Sets the water level used by the mapgen.  This should / could use map_meta value, but that is less controllable.
local mg_water_level = mg_earth.settings.sea_level * mg_world_scale

--Sets the height of the flat mapgen
local mg_flat_height = mg_earth.settings.flat_height

--Sets the max width of rivers.  Needs work.
--local mg_river_size				= 20 * mg_world_scale
--local mg_river_size = 2
local mg_river_size = mg_earth.settings.river_width * mg_world_scale

--Enables voronoi rivers.  Valleys are naturally formed at the edges of voronoi cells in this mapgen.  This turns those edges into rivers.
--local mg_rivers_enabled			= mg_earth.settings.enable_rivers
local mg_rivers_enabled = mg_earth.settings.enable_rivers

--Enables cave generation.
local mg_caves_enabled = mg_earth.settings.enable_caves

--Enables lake generation.
local mg_lakes_enabled = mg_earth.settings.enable_lakes

--Sets whether to use true earth like heat distribution.  Hot equator, cold polar regions.
local use_heat_scalar = mg_earth.settings.heat_scalar
--Sets whether to use rudimentary earthlike humidity distribution.  Some latitudes appear to carry more moisture than others.
local use_humid_scalar = mg_earth.settings.humidity_scalar

--Heightmap generation method options.
--DNU the following two lines.
--options:   bterrain, bterrainalt, flat, islands, islandsalt, v6, v7, v7alt, v7voronoi, v7altvoronoi, voronoi, v7voronoicliffs, v7altvoronoicliffs, voronoicliffs
--local mg_map = "v7altvoronoicliffs"
--END DNU
local mg_heightmap_select_options = {
    "vEarth", --1
    "v6", --2
    "v7", --3
    "v67", --4
    "vFlat", --9
    "vIslands", --5
    "vValleys", --6
    "vVoronoi", --7
    "vVoronoiPlus", --8
    "vSpheres", --10
    "vCubes", --11
    "vDiamonds", --12
    "v3D", --13
}
local mg_heightmap_select = mg_heightmap_select_options[mg_earth.settings.heightmap]

--Allowed options: c, e, m, cm.		These stand for Chebyshev, Euclidean, Manhattan, and Chebyshev Manhattan.  They determine the type of voronoi
--cell that is produces.  Chebyshev produces square cells.  Euclidean produces circular cells.  Manhattan produces diamond cells.
local dist_metrics = {
    "c",
    "e",
    "m",
    "cm",
}
local dist_metric = dist_metrics[mg_earth.settings.voronoi_distance]

--The following allows the use of custom voronoi point sets.  All point sets must be a file that returns a specially formatted lua table.  The file
--must exist in the point_sets folder within the mod.  Current sets are points_earth, (the default), and points_dev_isle
--OPTIONS:		points_earth (default), points_dev_isle, points_dev_isle_02
local voronoi_point_files = {
    "points_earth",
    "points_dev_isle",
    "points_terra",
    "points_grid",
}
p_file = voronoi_point_files[mg_earth.settings.voronoi_file]
--The following is the name of a file that is created on shutdown of all voronoi cells and their respective neighboring cells.  A unique file is created based on mg_world_scale.
--n_file = p_file .. "_" .. mg_earth.settings.voronoi_neighbor_file_suf .. ""
n_file = p_file .. "_" .. tostring(mg_world_scale) .. "_" .. mg_earth.settings.voronoi_neighbor_file_suf .. ""

local mg_points = dofile(mg_earth.path .. "/point_sets/" .. p_file .. ".lua")
local mg_neighbors = {}

mg_earth.mg_points = mg_points


--The following section are possible additional user exposed settings.

local mg_3d_terrain_enabled = false

--Noise heightmap additive options for vEarth mapgen.
local mg_noise_select_options = {
    "v6",
    "v67",
    "v7",
    "vIslands",
    "vValleys",
    "v67Valleys",
    "v3D",
}
local mg_noise_select = mg_noise_select_options[6]

--Determines percentage of base voronoi terrain, alt voronoi terrain, and noise terrain values that are then added together.
local noise_blend = 0.65
--Determines density value used by 3D terrain generation
local mg_density = 128
--Determines density value used by 3D cave generation
local mg_cave_density = 54

-- -- Cave Parameters
--local YMIN = -33000 -- Cave realm limits
--local YMIN = -1024 -- Cave realm limits
local YMIN = -31000 -- Cave realm limits
--local YMAX = -256
--local YMAX = 256
--local YMAX = mg_base_height * 0.5
--local YMAX = mg_base_height
local YMAX = -64
--local TCAVE = 0.6		-- Cave threshold: 1 = small rare caves,
local mg_cave_thresh1 = 0.6            -- Cave threshold: 1 = small rare caves,
--local mg_cave_thresh1 = 1.00			-- Cave threshold: 1 = small rare caves,
--local TCAVE1 = 8.75
--local TCAVE1 = 15
local mg_cave_thresh2 = 0.75        -- 0.5 = 1/3rd ground volume, 0 = 1/2 ground volume.
--local mg_cave_thresh2 = 2.00		-- 0.5 = 1/3rd ground volume, 0 = 1/2 ground volume.
--local TCAVE2 = 10		-- 0.5 = 1/3rd ground volume, 0 = 1/2 ground volume.
--local TCAVE2 = 20		-- 0.5 = 1/3rd ground volume, 0 = 1/2 ground volume.
local BLEND = 128        -- Cave blend distance near YMIN, YMAX
--local BLEND = mg_base_height * 0.25

-- -- Stuff
local yblmin = YMIN + BLEND * 1.5
local yblmax = YMAX - BLEND * 1.5

--####
--##
--##	END CUSTOMIZATION OPTIONS.
--##
--####



--####
--##
--##	Settings below should not be changed at risk of crashing.
--##
--####

if mg_world_scale ~= 1 then
    mg_rivers_enabled = false
    mg_caves_enabled = false
    mg_lakes_enabled = false
end

if mg_world_scale < 1.0 then
    mg_river_size = 4
    --if mg_world_scale <= 0.1 then
    --	mg_river_size = 2
    --end
end

if mg_heightmap_select == "vValleys" then
    mg_river_size = mg_earth.settings.river_width
end
--if mg_3d_terrain_enabled then
if mg_heightmap_select == "v3D" then

    mg_rivers_enabled = false
    mg_caves_enabled = false
    mg_lakes_enabled = false

end

if mg_noise_select == "v3D" then

    mg_rivers_enabled = false
    mg_caves_enabled = false
    mg_lakes_enabled = false

end

--Enables use of gal provided ecosystems.  Disables ecosystems for all other biome related mods.
local mg_ecosystems = false

--local mg_default				= true

local v_cscale = 0.05
local v_pscale = 0.1
local v_mscale = 0.125

local eco_threshold = 1
local dirt_threshold = 0.5


--Sets the max width of valley formation.  Also needs refining.
--local mg_valley_size			= 50 * mg_world_scale
--local mg_valley_size			= 10 * mg_world_scale
local mg_valley_size = mg_river_size * mg_river_size
--local mg_valley_size = 100 * mg_world_scale
--local mg_valley_size = 10
local river_size_factor = mg_river_size / 100

local biome_vertical_range = mg_base_height / 6

--Sets altitude ranges.
local ocean_depth = mg_base_height * mg_world_scale
local beach_depth = -4 * mg_world_scale
local max_beach = 4 * mg_world_scale
local max_coastal = mg_water_level + biome_vertical_range
local max_lowland = max_coastal + biome_vertical_range
local max_shelf = max_lowland + biome_vertical_range
local max_highland = max_shelf + biome_vertical_range
local max_mountain = max_highland + biome_vertical_range


--dofile(mg_earth.path .. "/voxel.lua")

mg_earth.default = minetest.global_exists("default")
mg_earth.gal = minetest.global_exists("gal")

if mg_earth.gal then
    mg_world_scale = gal.mapgen.mg_world_scale
    mg_water_level = gal.mapgen.water_level
    mg_base_height = gal.mapgen.mg_base_height
    biome_vertical_range = (gal.mapgen.mg_base_height / 6)
    max_beach = gal.mapgen.maxheight_beach
    max_coastal = gal.mapgen.sea_level + gal.mapgen.biome_vertical_range
    max_lowland = gal.mapgen.maxheight_coastal + gal.mapgen.biome_vertical_range
    max_shelf = gal.mapgen.maxheight_lowland + gal.mapgen.biome_vertical_range
    max_highland = gal.mapgen.maxheight_shelf + gal.mapgen.biome_vertical_range
    max_mountain = gal.mapgen.maxheight_highland + gal.mapgen.biome_vertical_range
    max_highland = gal.mapgen.maxheight_highland
    max_mountain = gal.mapgen.maxheight_mountain
    mg_ecosystems = true
end

mg_earth.c_air = minetest.get_content_id("air")
mg_earth.c_ignore = minetest.get_content_id("ignore")

if mg_earth.default then
    mg_earth.c_top = minetest.get_content_id("default:dirt_with_grass")
    mg_earth.c_filler = minetest.get_content_id("default:dirt")
    mg_earth.c_stone = minetest.get_content_id("default:stone")
    mg_earth.c_water = minetest.get_content_id("default:water_source")
    mg_earth.c_river = minetest.get_content_id("default:river_water_source")
    mg_earth.c_gravel = minetest.get_content_id("default:gravel")

    mg_earth.c_lava = minetest.get_content_id("default:lava_source")
    mg_earth.c_ice = minetest.get_content_id("default:ice")
    mg_earth.c_mud = minetest.get_content_id("default:clay")

    mg_earth.c_cobble = minetest.get_content_id("default:cobble")
    mg_earth.c_mossy = minetest.get_content_id("default:mossycobble")
    mg_earth.c_block = minetest.get_content_id("default:stone_block")
    mg_earth.c_brick = minetest.get_content_id("default:stonebrick")
    mg_earth.c_sand = minetest.get_content_id("default:sand")
    mg_earth.c_dirt = minetest.get_content_id("default:dirt")
    mg_earth.c_dirtdry = minetest.get_content_id("default:dry_dirt")
    mg_earth.c_dirtgrass = minetest.get_content_id("default:dirt_with_grass")
    mg_earth.c_dirtdrygrass = minetest.get_content_id("default:dirt_with_dry_grass")
    mg_earth.c_drydirtdrygrass = minetest.get_content_id("default:dry_dirt_with_dry_grass")
    mg_earth.c_dirtsnow = minetest.get_content_id("default:dirt_with_snow")
    mg_earth.c_dirtperm = minetest.get_content_id("default:permafrost")

    mg_earth.c_coniferous = minetest.get_content_id("default:dirt_with_coniferous_litter")
    mg_earth.c_rainforest = minetest.get_content_id("default:dirt_with_rainforest_litter")
    mg_earth.c_desertsandstone = minetest.get_content_id("default:desert_sandstone")
    mg_earth.c_desertsand = minetest.get_content_id("default:desert_sand")
    mg_earth.c_desertstone = minetest.get_content_id("default:desert_stone")
    mg_earth.c_sandstone = minetest.get_content_id("default:sandstone")
    mg_earth.c_silversandstone = minetest.get_content_id("default:silver_sandstone")
    mg_earth.c_silversand = minetest.get_content_id("default:silver_sand")
end
if mg_earth.gal then
    mg_earth.c_top = minetest.get_content_id("gal:dirt_with_grass")
    mg_earth.c_filler = minetest.get_content_id("gal:dirt")
    mg_earth.c_stone = minetest.get_content_id("gal:stone")
    mg_earth.c_water = minetest.get_content_id("gal:liquid_water_source")
    mg_earth.c_river = minetest.get_content_id("gal:liquid_water_river_source")
    mg_earth.c_gravel = minetest.get_content_id("gal:stone_gravel")

    mg_earth.c_lava = minetest.get_content_id("gal:liquid_lava_source")
    mg_earth.c_ice = minetest.get_content_id("gal:ice")
    mg_earth.c_mud = minetest.get_content_id("gal:dirt_mud_01")

    mg_earth.c_cobble = minetest.get_content_id("gal:stone_cobble")
    mg_earth.c_mossy = minetest.get_content_id("gal:stone_cobble_mossy")
    mg_earth.c_block = minetest.get_content_id("gal:stone_block")
    mg_earth.c_brick = minetest.get_content_id("gal:stone_brick")
    mg_earth.c_sand = minetest.get_content_id("gal:sand")
    mg_earth.c_dirt = minetest.get_content_id("gal:dirt")
    mg_earth.c_dirtdry = minetest.get_content_id("gal:dirt_dry")
    mg_earth.c_dirtgrass = minetest.get_content_id("gal:dirt_with_grass")
    mg_earth.c_dirtdrygrass = minetest.get_content_id("gal:dirt_with_grass_dry")
    mg_earth.c_drydirtdrygrass = minetest.get_content_id("gal:dirt_dry_with_grass_dry")
    mg_earth.c_dirtsnow = minetest.get_content_id("gal:dirt_with_snow")
    mg_earth.c_dirtperm = minetest.get_content_id("gal:dirt_permafrost")

    mg_earth.c_black = minetest.get_content_id("gal:dirt_black")
    mg_earth.c_black_lawn = minetest.get_content_id("gal:dirt_black_with_grass")
    mg_earth.c_brown = minetest.get_content_id("gal:dirt_brown")
    mg_earth.c_brown_lawn = minetest.get_content_id("gal:dirt_brown_with_grass")
    mg_earth.c_clayey = minetest.get_content_id("gal:dirt_clayey")
    mg_earth.c_clayey_lawn = minetest.get_content_id("gal:dirt_clayey_with_grass")
    mg_earth.c_dry = minetest.get_content_id("gal:dirt_dry")
    mg_earth.c_dry_lawn = minetest.get_content_id("gal:dirt_dry_with_grass_dry")
    mg_earth.c_sandy = minetest.get_content_id("gal:dirt_sandy")
    mg_earth.c_sandy_lawn = minetest.get_content_id("gal:dirt_sandy_with_grass")
    mg_earth.c_silty = minetest.get_content_id("gal:dirt_silty")
    mg_earth.c_silty_lawn = minetest.get_content_id("gal:dirt_silty_with_grass")
    mg_earth.c_clay = minetest.get_content_id("gal:dirt_clay_red")
    mg_earth.c_dried = minetest.get_content_id("gal:dirt_cracked")
    mg_earth.c_peat = minetest.get_content_id("gal:dirt_peat")
    mg_earth.c_silt = minetest.get_content_id("gal:dirt_silt_01")

    mg_earth.c_coniferous = minetest.get_content_id("gal:dirt_with_litter_coniferous")
    mg_earth.c_rainforest = minetest.get_content_id("gal:dirt_with_litter_rainforest")
    mg_earth.c_desertsandstone = minetest.get_content_id("gal:stone_sandstone_desert")
    mg_earth.c_desertsand = minetest.get_content_id("gal:sand_desert")
    mg_earth.c_desertstone = minetest.get_content_id("gal:stone_desert")
    mg_earth.c_sandstone = minetest.get_content_id("gal:stone_sandstone")
    mg_earth.c_silversandstone = minetest.get_content_id("gal:stone_sandstone_silver")
    mg_earth.c_silversand = minetest.get_content_id("gal:sand_silver")
end

mg_earth.heightmap = {}
mg_earth.biomemap = {}
mg_earth.biome_info = {}
mg_earth.eco_fill = {}
mg_earth.eco_top = {}
mg_earth.eco_map = {}
local mg_voronoimap = {}
mg_earth.cliffmap = {}
mg_earth.valleymap = {}
mg_earth.riverpath = {}
mg_earth.rivermap = {}
mg_earth.hh_mod = {}
mg_earth.cellmap = {}

mg_earth.center_of_chunk = nil
mg_earth.chunk_points = nil
mg_earth.chunk_terrain = nil
mg_earth.chunk_mean_altitude = nil
mg_earth.chunk_min_altitude = nil
mg_earth.chunk_max_altitude = nil

mg_earth.chunk_terrain = {
    SW = { x = nil, y = nil, z = nil },
    W = { x = nil, y = nil, z = nil },
    NW = { x = nil, y = nil, z = nil },
    S = { x = nil, y = nil, z = nil },
    C = { x = nil, y = nil, z = nil },
    N = { x = nil, y = nil, z = nil },
    SE = { x = nil, y = nil, z = nil },
    E = { x = nil, y = nil, z = nil },
    NE = { x = nil, y = nil, z = nil },
}

mg_earth.player_spawn_point = { x = -5, y = 0, z = -5 }
mg_earth.origin_y_val = { x = 0, y = 0, z = 0 }

local nobj_cave1 = nil
local nbuf_cave1 = {}
local nobj_cave2 = nil
local nbuf_cave2 = {}

local nobj_3dterrain = nil
local nbuf_3dterrain = {}

local nobj_heatmap = nil
local nbuf_heatmap = {}
local nobj_heatblend = nil
local nbuf_heatblend = {}
local nobj_humiditymap = nil
local nbuf_humiditymap = {}
local nobj_humidityblend = nil
local nbuf_humidityblend = {}

local mg_alt_scale_scale = 1
local mg_base_scale_scale = 1
local mg_noise_spread = (600 * mg_alt_scale_scale) * mg_world_scale
local mg_noise_scale = 25
local mg_alt_noise_scale = mg_noise_scale * mg_world_scale
local mg_base_noise_scale = ((mg_noise_scale * 2.8) * mg_base_scale_scale) * mg_world_scale
local mg_noise_offset = -4 * mg_world_scale
local mg_noise_octaves = 7
local mg_noise_persist = 0.6
local mg_noise_lacunarity = 2.19
-- local mg_noise_octaves = 5
-- local mg_noise_persist = 0.5
-- local mg_noise_lacunarity = 2

--TODO:  Valleys Noise config
-- mg_valleys2d.mg_noise_spread = 1024
-- mg_valleys2d.mg_noise_scale = 50
-- mg_valleys2d.mg_noise_seed = 5202
-- --mg_valleys2d.mg_noise_offset = 0
-- mg_valleys2d.mg_noise_offset = -10
-- mg_valleys2d.mg_noise_octaves = 6
-- mg_valleys2d.mg_noise_persist = 0.4
-- mg_valleys2d.mg_noise_lacunarity = 2


local mg_cliff_noise_spread = 180 * mg_world_scale
--local mg_cliff_noise_spread = 180

local mg_fill_noise_spread = 150 * mg_world_scale

--local mg_height_noise_spread = 1000 * mg_world_scale
local mg_height_noise_spread = 500 * mg_world_scale
local mg_persist_noise_spread = 2000 * mg_world_scale

local mg_noise_heathumid_spread = 1000 * mg_world_scale
local mg_noise_heat_offset = 50
local mg_noise_heat_scale = 50

if use_heat_scalar == true then
    mg_noise_heat_offset = 0
    mg_noise_heat_scale = 12.5
end

local mg_noise_humid_offset = 50
local mg_noise_humid_scale = 50

local np_eco1 = { offset = 0, scale = 1, seed = 4767, spread = { x = 256, y = 256, z = 256 }, octaves = 5, persist = 0.5, lacunarity = 4 }
local np_eco2 = { offset = 0, scale = 1, seed = 3497, spread = { x = 256, y = 256, z = 256 }, octaves = 5, persist = 0.5, lacunarity = 4 }
local np_eco3 = { offset = 0, scale = 1, seed = 2835, spread = { x = 256, y = 256, z = 256 }, octaves = 5, persist = 0.5, lacunarity = 4 }
local np_eco4 = { offset = 0, scale = 1, seed = 8321, spread = { x = 256, y = 256, z = 256 }, octaves = 5, persist = 0.5, lacunarity = 4 }
local np_eco5 = { offset = 0, scale = 1, seed = 6940, spread = { x = 256, y = 256, z = 256 }, octaves = 5, persist = 0.5, lacunarity = 4 }
local np_eco6 = { offset = 0, scale = 1, seed = 6674, spread = { x = 256, y = 256, z = 256 }, octaves = 5, persist = 0.5, lacunarity = 4 }
local np_eco7 = { offset = 0, scale = 1, seed = 5423, spread = { x = 256, y = 256, z = 256 }, octaves = 5, persist = 0.5, lacunarity = 4 }
local np_eco8 = { offset = 0, scale = 1, seed = 9264, spread = { x = 256, y = 256, z = 256 }, octaves = 5, persist = 0.5, lacunarity = 4 }

--v7 Noises
local np_2d = {
    offset = mg_noise_offset,
    scale = mg_alt_noise_scale,
    seed = 5934,
    spread = { x = mg_noise_spread, y = mg_noise_spread, z = mg_noise_spread },
    octaves = mg_noise_octaves,
    persist = mg_noise_persist,
    lacunarity = mg_noise_lacunarity,
    --flags = "defaults"
}
local np_base = {
    offset = mg_noise_offset * mg_base_scale_scale,
    scale = mg_base_noise_scale,
    --seed = 82341,
    seed = 5934,
    spread = { x = mg_noise_spread, y = mg_noise_spread, z = mg_noise_spread },
    octaves = mg_noise_octaves,
    persist = mg_noise_persist,
    lacunarity = mg_noise_lacunarity,
    flags = "defaults"
}
local np_height = {
    flags = "defaults",
    lacunarity = mg_noise_lacunarity,
    --offset = 0.25,
    offset = 0.5,
    scale = 1,
    spread = { x = mg_height_noise_spread, y = mg_height_noise_spread, z = mg_height_noise_spread },
    seed = 4213,
    octaves = mg_noise_octaves,
    persist = mg_noise_persist,
}
local np_persist = {
    flags = "defaults",
    lacunarity = mg_noise_lacunarity,
    offset = 0.6,
    scale = 0.1,
    spread = { x = mg_persist_noise_spread, y = mg_persist_noise_spread, z = mg_persist_noise_spread },
    seed = 539,
    octaves = 3,
    persist = 0.6,
}

--v6 Noises
local np_terrain_base = {
    flags = "defaults",
    lacunarity = 2,
    offset = -4 * mg_world_scale,
    scale = 20 * mg_world_scale,
    spread = { x = (250 * mg_world_scale), y = (250 * mg_world_scale), z = (250 * mg_world_scale) },
    seed = 82341,
    octaves = 5,
    persist = 0.6,
}
local np_terrain_higher = {
    flags = "defaults",
    lacunarity = 2,
    offset = 20 * mg_world_scale,
    scale = 16 * mg_world_scale,
    spread = { x = (500 * mg_world_scale), y = (500 * mg_world_scale), z = (500 * mg_world_scale) },
    seed = 85039,
    octaves = 5,
    persist = 0.6,
}
local np_steepness = {
    flags = "defaults",
    lacunarity = 2,
    offset = 0.85 * mg_world_scale,
    scale = 0.5 * mg_world_scale,
    spread = { x = (125 * mg_world_scale), y = (125 * mg_world_scale), z = (125 * mg_world_scale) },
    seed = -932,
    octaves = 5,
    persist = 0.7,
}
local np_height_select = {
    flags = "defaults",
    lacunarity = 2,
    offset = 0 * mg_world_scale,
    scale = 1 * mg_world_scale,
    spread = { x = (250 * mg_world_scale), y = (250 * mg_world_scale), z = (250 * mg_world_scale) },
    seed = 4213,
    octaves = 5,
    persist = 0.69,
}

--#	Valleys Noises
local np_val_terrain = {
    flags = "defaults",
    lacunarity = 2,
    offset = -10 * mg_world_scale,
    scale = 50 * mg_world_scale,
    spread = { x = (1024 * mg_world_scale), y = (1024 * mg_world_scale), z = (1024 * mg_world_scale) },
    seed = 5202,
    octaves = 6,
    persist = 0.4,
}
--[[
	local np_val_terrain = {
		offset = mg_valleys2d.mg_noise_offset,
		scale = mg_valleys2d.mg_noise_scale * mg_valleys2d.mg_world_scale,
		seed = mg_valleys2d.mg_noise_seed,
		spread = {x = (mg_valleys2d.mg_noise_spread * mg_valleys2d.mg_world_scale), y = (mg_valleys2d.mg_noise_spread * mg_valleys2d.mg_world_scale), z = (mg_valleys2d.mg_noise_spread * mg_valleys2d.mg_world_scale)},
		octaves = mg_valleys2d.mg_noise_octaves,
		persist = mg_valleys2d.mg_noise_persist,
		lacunarity = mg_valleys2d.mg_noise_lacunarity,
		flags = "defaults",
	}
--]]
local np_val_river = {
    flags = "defaults",
    lacunarity = 2,
    offset = 0 * mg_world_scale,
    scale = 1 * mg_world_scale,
    spread = { x = (256 * mg_world_scale), y = (256 * mg_world_scale), z = (256 * mg_world_scale) },
    seed = -6050,
    octaves = 5,
    persist = 0.6,
}
local np_val_depth = {
    flags = "defaults",
    lacunarity = 2,
    offset = 5 * mg_world_scale,
    scale = 4 * mg_world_scale,
    spread = { x = (512 * mg_world_scale), y = (512 * mg_world_scale), z = (512 * mg_world_scale) },
    seed = -1914,
    octaves = 1,
    persist = 1,
}
local np_val_profile = {
    flags = "defaults",
    lacunarity = 2,
    offset = 0.6 * mg_world_scale,
    scale = 0.5 * mg_world_scale,
    spread = { x = (512 * mg_world_scale), y = (512 * mg_world_scale), z = (512 * mg_world_scale) },
    seed = 777,
    octaves = 1,
    persist = 1,
}
local np_val_slope = {
    flags = "defaults",
    lacunarity = 2,
    offset = 0.5 * mg_world_scale,
    scale = 0.5 * mg_world_scale,
    spread = { x = (128 * mg_world_scale), y = (128 * mg_world_scale), z = (128 * mg_world_scale) },
    seed = 746,
    octaves = 1,
    persist = 1,
}
local np_val_fill = {
    flags = "defaults",
    lacunarity = 2,
    offset = 0 * mg_world_scale,
    scale = 1 * mg_world_scale,
    spread = { x = (256 * mg_world_scale), y = (512 * mg_world_scale), z = (256 * mg_world_scale) },
    seed = 1993,
    octaves = 6,
    persist = 0.8,
}

--3D Terrain Noise
local np_3dterrain = {
    offset = 0,
    scale = 1 * mg_world_scale,
    spread = { x = (384 * mg_world_scale), y = (192 * mg_world_scale), z = (384 * mg_world_scale) },
    seed = 5934,
    --octaves = 7,
    octaves = 5,
    --persist = 0.4,
    persist = 0.5,
    --lacunarity = 2.19,
    lacunarity = 2.11,
    --flags = ""
}


-- 3D noise for caves
local np_cave1 = {
    -- -- offset = 0,
    -- -- scale = 12,
    -- -- --scale = 1,
    -- -- spread = {x = 30, y = 10, z = 30}, -- squashed 3:1
    -- -- seed = 52534,
    -- -- --octaves = 3,
    -- -- octaves = 3,
    -- -- --persist = 0.5,
    -- -- persist = 0.5,
    -- -- --lacunarity = 2.0,
    -- -- lacunarity = 2.11,

    -- mgv7
    lacunarity = 2.15,
    persist = 0.6,
    scale = 25,
    offset = 0,
    --flags = "defaults",
    spread = { x = 61, y = 61, z = 61 },
    seed = 52534,
    octaves = 5,

    -- -- mgv7
    -- lacunarity = 2,
    -- persist = 0.5,
    -- scale = 12,
    -- offset = 0,
    -- flags = "defaults",
    -- spread = {x = 61, y = 61, z = 61},
    -- seed = 52534,
    -- octaves = 3,

    -- -- Subterrain
    -- offset = 0,
    -- scale = 1,
    -- spread = {x = 768, y = 256, z = 768}, -- squashed 3:1
    -- seed = 59033,
    -- octaves = 6,
    -- persist = 0.63,

    -- -- Caverealms
    -- offset = 0,
    -- scale = 1,
    -- spread = {x=512, y=256, z=512}, -- squashed 2:1
    -- seed = 59033,
    -- octaves = 6,
    -- persist = 0.63,
}
local np_cave2 = {
    -- offset = 0,
    -- scale = 12,
    -- spread = {x = 30, y = 10, z = 30}, -- squashed 3:1
    -- seed = 10325,
    -- octaves = 3,
    -- persist = 0.5,
    -- lacunarity = 2.11,
    lacunarity = 2.15,
    persist = 0.6,
    scale = 25,
    offset = 0,
    flags = "defaults",
    spread = { x = 67, y = 67, z = 67 },
    seed = 10325,
    octaves = 5,
}
local np_cliffs = {
    offset = 0,
    scale = 0.72,
    --spread = {x = mg_cliff_noise_spread, y = mg_cliff_noise_spread, z = mg_cliff_noise_spread},
    spread = { x = mg_cliff_noise_spread, y = mg_cliff_noise_spread, z = mg_cliff_noise_spread },
    --seed = 78901,
    seed = 82735,
    octaves = 5,
    persist = 0.5,
    lacunarity = 2.19,
}
local np_fill = {
    flags = "defaults",
    lacunarity = 2,
    offset = 0,
    scale = 1.2,
    spread = { x = mg_fill_noise_spread, y = mg_fill_noise_spread, z = mg_fill_noise_spread },
    seed = 261,
    octaves = 3,
    persistence = 0.7,
}

local np_heat = {
    flags = "defaults",
    lacunarity = 2,
    offset = mg_noise_heat_offset,
    scale = mg_noise_heat_scale,
    --spread = {x = 1000, y = 1000, z = 1000},
    spread = { x = mg_noise_heathumid_spread, y = mg_noise_heathumid_spread, z = mg_noise_heathumid_spread },
    seed = 5349,
    octaves = 3,
    persist = 0.5,
}
local np_heat_blend = {
    flags = "defaults",
    lacunarity = 2,
    offset = 0,
    scale = 1.5,
    spread = { x = 8, y = 8, z = 8 },
    seed = 13,
    octaves = 2,
    persist = 1,
}
local np_humid = {
    flags = "defaults",
    lacunarity = 2,
    offset = mg_noise_humid_offset,
    scale = mg_noise_humid_scale,
    --spread = {x = 1000, y = 1000, z = 1000},
    spread = { x = mg_noise_heathumid_spread, y = mg_noise_heathumid_spread, z = mg_noise_heathumid_spread },
    seed = 842,
    octaves = 3,
    persist = 0.5,
}
local np_humid_blend = {
    flags = "defaults",
    lacunarity = 2,
    offset = 0,
    scale = 1.5,
    spread = { x = 8, y = 8, z = 8 },
    seed = 90003,
    octaves = 2,
    persist = 1,
}

local abs = math.abs
local max = math.max
local min = math.min
local floor = math.floor
local sin = math.sin
local cos = math.cos
local tan = math.tan
local atan = math.atan
local atan2 = math.atan2
local pi = math.pi
local rad = math.rad

local cliffs_thresh = floor((np_2d.scale) * 0.5)

local function rangelim(v, min, max)
    if v < min then
        return min
    end
    if v > max then
        return max
    end
    return v
end

local function max_height(noiseprm)
    local height = 0
    local scale = noiseprm.scale
    for i = 1, noiseprm.octaves do
        height = height + scale
        scale = scale * noiseprm.persist
    end
    return height + noiseprm.offset
end

local function min_height(noiseprm)
    local height = 0
    local scale = noiseprm.scale
    for i = 1, noiseprm.octaves do
        height = height - scale
        scale = scale * noiseprm.persist
    end
    return height + noiseprm.offset
end

local v7_min_height = min_height(np_base)
local v7_max_height = max_height(np_base)
local v7_alt_max_height = max_height(np_2d)


--##Metrics functions.  Distance, direction, slope.
local function get_direction_to_pos(a, b)
    local t_compass
    local t_dir = { x = 0, z = 0 }

    if a.z < b.z then
        t_dir.z = 1
        t_compass = "N"
    elseif a.z > b.z then
        t_dir.z = -1
        t_compass = "S"
    else
        t_dir.z = 0
        t_compass = ""
    end
    if a.x < b.x then
        t_dir.x = 1
        t_compass = t_compass .. "E"
    elseif a.x > b.x then
        t_dir.x = -1
        t_compass = t_compass .. "W"
    else
        t_dir.x = 0
        t_compass = t_compass .. ""
    end
    return t_dir, t_compass
end

local function get_dist(a, b, d_type)
    local dist
    if d_type then
        if d_type == "c" then
            dist = (max(abs(a), abs(b)))
        elseif d_type == "e" then
            dist = ((abs(a) * abs(a)) + (abs(b) * abs(b))) ^ 0.5
        elseif d_type == "m" then
            dist = (abs(a) + abs(b))
        elseif d_type == "cm" then
            dist = (max(abs(a), abs(b)) + (abs(a) + abs(b))) * 0.5
        end
    end
    return dist
end

local function get_dist2line(a, b, p)

    local run = a.x - b.x
    local rise = a.z - b.z
    local ln_length = (((run * run) + (rise * rise)) ^ 0.5)

    return max(1, (abs((run * (a.z - p.z)) - ((a.x - p.x) * rise)) / ln_length))

end

local function get_dist2endline_inverse(a, b, p)

    local run = a.x - b.x
    local rise = a.z - b.z
    local c = {
        x = b.x - rise,
        z = b.z + run
    }
    local d = {
        x = b.x + rise,
        z = b.z - run
    }
    local lx = c.x - d.x
    local lz = c.z - d.z

    return max(1, (abs((lx * (c.z - p.z)) - ((c.x - p.x) * lz))) / (((lx * lx) + (lz * lz)) ^ 0.5))

end

local function get_midpoint(a, b)
    --get_midpoint(a,b)
    return ((a.x + b.x) * 0.5), ((a.z + b.z) * 0.5)            --returns the midpoint between two points
end

local function get_slope(a, b)
    local run = a.x - b.x
    local rise = a.z - b.z
    return (rise / run), rise, run
end

local function get_slope_inverse(a, b)
    local run = a.x - b.x
    local rise = a.z - b.z
    return (run / rise), run, rise
end


--##Voronoi functions.  Nearest cell, Nearest Neighbor Midpoint, Cell Neighbors, load / save.
local function get_nearest_cell(pos, tier)

    local thisidx
    local thiscellx
    local thiscellz
    local thisdist
    local lastidx
    local lastcellx
    local lastcellz
    local lastdist
    local last
    local this
    for i, point in ipairs(mg_points) do
        --euclidean
        --local platform = get_distance_3d_euclid({x=x,y=y,z=z},{x=center_of_chunk.x,y=center_of_chunk.y,z=center_of_chunk.z})
        --local cell = get_distance_3d_euclid({x=x,y=y,z=z},{x=point.x,y=point.y,z=point.z})
        --((abs(a) * abs(a)) + (abs(b) * abs(b)))^0.5
        --manhattan
        --local platform = (abs(x-center_of_chunk.x) + abs(y-center_of_chunk.y) + abs(z-center_of_chunk.z))
        --local chnk = (abs(x-point.x) + abs(y-point.y) + abs(z-point.z))
        --chebyshev
        --local platform = (max(abs(x-center_of_chunk.x), max(abs(y-center_of_chunk.y), abs(z-center_of_chunk.z))))
        --local cell = (max(abs(x-point.x), max(abs(y-point.y), abs(z-point.z))))

        local pointidx, pointz, pointx, pointtier = unpack(point)
        local dist_x = abs(pos.x - (tonumber(pointx) * mg_world_scale))
        local dist_z = abs(pos.z - (tonumber(pointz) * mg_world_scale))

        --this = (max(dist_x, dist_z) + (dist_x + dist_z)) * 0.5
        this = get_dist(dist_x, dist_z, dist_metric)
        --this = ((dist_x * dist_x) + (dist_z * dist_z))^0.5

        if tonumber(pointtier) == tier then

            if last then
                if last > this then
                    last = this
                    thisidx = tonumber(pointidx)
                    thiscellz = (tonumber(pointz) * mg_world_scale)
                    thiscellx = (tonumber(pointx) * mg_world_scale)
                    thisdist = this
                    lastidx = tonumber(pointidx)
                    lastcellz = (tonumber(pointz) * mg_world_scale)
                    lastcellx = (tonumber(pointx) * mg_world_scale)
                    lastdist = this
                elseif last == this then
                    thisidx = tonumber(pointidx)
                    thiscellz = (tonumber(pointz) * mg_world_scale)
                    thiscellx = (tonumber(pointx) * mg_world_scale)
                    thisdist = this
                    if not mg_neighbors[thisidx] then
                        mg_neighbors[thisidx] = {}
                    end
                    if not mg_neighbors[lastidx] then
                        mg_neighbors[lastidx] = {}
                    end
                    if not mg_neighbors[thisidx][lastidx] then
                        mg_neighbors[thisidx][lastidx] = {}
                    end
                    if not mg_neighbors[lastidx][thisidx] then
                        mg_neighbors[lastidx][thisidx] = {}
                    end
                    local t_mid_x, t_mid_z = get_midpoint({ x = thiscellx, z = thiscellz }, { x = lastcellx, z = lastcellz })
                    mg_neighbors[thisidx][lastidx].m_x = t_mid_x
                    mg_neighbors[thisidx][lastidx].m_z = t_mid_z
                    mg_neighbors[thisidx][lastidx].n_x = lastcellx
                    mg_neighbors[thisidx][lastidx].n_z = lastcellz
                    mg_neighbors[lastidx][thisidx].m_x = t_mid_x
                    mg_neighbors[lastidx][thisidx].m_z = t_mid_z
                    mg_neighbors[lastidx][thisidx].n_x = thiscellx
                    mg_neighbors[lastidx][thisidx].n_z = thiscellz
                end
            else
                last = this
                thisidx = tonumber(pointidx)
                thiscellz = (tonumber(pointz) * mg_world_scale)
                thiscellx = (tonumber(pointx) * mg_world_scale)
                thisdist = this
                lastidx = tonumber(pointidx)
                lastcellz = (tonumber(pointz) * mg_world_scale)
                lastcellx = (tonumber(pointx) * mg_world_scale)
                lastdist = this
            end
        end
    end

    --return idx, closest, cell
    return thisidx, thisdist, thiscellz, thiscellx

end

local function get_nearest_midpoint(pos, ppoints)

    if not pos then
        return
    end

    local c_midpoint
    local this_dist
    --local c_z
    --local c_x
    --local c_dx
    --local c_dz
    --local c_si
    local last_dist

    for i, i_neighbor in pairs(ppoints) do

        local t_x = pos.x - i_neighbor.m_x
        local t_z = pos.z - i_neighbor.m_z

        this_dist = get_dist(t_x, t_z, dist_metric)

        if last_dist then
            if last_dist >= this_dist then
                last_dist = this_dist
                c_midpoint = i
                --c_z = i_neighbor.m_z
                --c_x = i_neighbor.m_x
                --c_dz = i_neighbor.cm_zd
                --c_dx = i_neighbor.cm_xd
                --c_si = i_neighbor.m_si
            end
        else
            last_dist = this_dist
            c_midpoint = i
            --c_z = i_neighbor.m_z
            --c_x = i_neighbor.m_x
            --c_dz = i_neighbor.cm_zd
            --c_dx = i_neighbor.cm_xd
            --c_si = i_neighbor.m_si
        end
    end

    --return c_midpoint, c_z, c_x, c_dz, c_dx, c_si
    return c_midpoint

end

local function get_cell_neighbors(cell_idx, cell_z, cell_x, cell_tier)

    local t_points = mg_points

    --local curr_cell = t_points[cell_idx]
    local t_neighbors = {}

    if mg_neighbors[cell_idx] then

        t_neighbors = mg_neighbors[cell_idx]

    else

        mg_neighbors[cell_idx] = {}

        for i, i_point in ipairs(t_points) do

            local pointidx, pointz, pointx, pointtier = unpack(i_point)

            if cell_tier == pointtier then

                local t_mid_x, t_mid_z
                local t_cell
                local neighbor_add = false

                if i ~= cell_idx then

                    t_mid_x, t_mid_z = get_midpoint({ x = (tonumber(pointx) * mg_world_scale), z = (tonumber(pointz) * mg_world_scale) }, { x = cell_x, z = cell_z })

                    t_cell = get_nearest_cell({ x = t_mid_x, z = t_mid_z }, cell_tier)

                    if (t_cell == i) or (t_cell == cell_idx) then
                        neighbor_add = true
                    end

                end

                if neighbor_add == true then

                    -- t_neighbors[i] = {}
                    -- t_neighbors[i].m_z = t_mid_z
                    -- t_neighbors[i].m_x = t_mid_x
                    mg_neighbors[cell_idx][pointidx] = {}
                    mg_neighbors[cell_idx][pointidx].m_z = t_mid_z
                    mg_neighbors[cell_idx][pointidx].m_x = t_mid_x
                    mg_neighbors[cell_idx][pointidx].n_z = (tonumber(pointz) * mg_world_scale)
                    mg_neighbors[cell_idx][pointidx].n_x = (tonumber(pointx) * mg_world_scale)

                    t_neighbors = mg_neighbors[cell_idx]

                end
            end
        end
    end

    return t_neighbors

end

local function load_worldpath(separator, path)
    local file = io.open(mg_earth.path_world .. "/" .. path .. ".csv", "r")
    if file then
        local t = {}
        for line in file:lines() do
            if line:sub(1, 1) ~= "#" and line:find("[^%" .. separator .. "% ]") then
                table.insert(t, line:split(separator, true))
            end
        end
        if type(t) == "table" then
            return t
        end
    end

    return nil
end

local function save_worldpath(pobj, pfilename)
    local file = io.open(mg_earth.path_world .. "/" .. pfilename .. ".csv", "w")
    if file then
        file:write(pobj)
        file:close()
    end
end

local function load_neighbors(pfile)

    if not pfile or pfile == "" then
        return
    end

    local t_neighbors

    if (t_neighbors == nil) then
        t_neighbors = load_worldpath("|", pfile)
    end

    if not (t_neighbors == nil) then

        for i_p, p_neighbors in ipairs(t_neighbors) do

            local c_i, n_i, m_z, m_x, n_z, n_x = unpack(p_neighbors)

            if not (mg_neighbors[tonumber(c_i)]) then
                mg_neighbors[tonumber(c_i)] = {}
            end

            mg_neighbors[tonumber(c_i)][tonumber(n_i)] = {}
            mg_neighbors[tonumber(c_i)][tonumber(n_i)].m_z = tonumber(m_z)
            mg_neighbors[tonumber(c_i)][tonumber(n_i)].m_x = tonumber(m_x)
            mg_neighbors[tonumber(c_i)][tonumber(n_i)].n_z = tonumber(n_z)
            mg_neighbors[tonumber(c_i)][tonumber(n_i)].n_x = tonumber(n_x)

        end

        minetest.log("[MOD] test: Voronoi Cell Neighbors loaded from file.")

    end
end
load_neighbors(n_file)

local function save_neighbors(pfile)

    if not pfile or pfile == "" then
        return
    end

    local temp_neighbors = "#Cell_Index|Neighbor_Index|Midpoint_Zpos|Midpoint_Xpos|Neighbor_Zpos|Neighbor_Xpos\n"

    for i_c, i_cell in pairs(mg_neighbors) do

        temp_neighbors = temp_neighbors .. "#C_I|N_I|M_Z|M_X|N_Z|N_X\n"

        for i_n, i_neighbor in pairs(i_cell) do

            temp_neighbors = temp_neighbors .. i_c .. "|" .. i_n .. "|" .. i_neighbor.m_z .. "|" .. i_neighbor.m_x .. "|" .. i_neighbor.n_z .. "|" .. i_neighbor.n_x .. "\n"

        end

        temp_neighbors = temp_neighbors .. "#" .. "\n"

    end

    --gal.lib.csv.save_worldpath(temp_neighbors, pfile)
    save_worldpath(temp_neighbors, pfile)

end


--##Biome functions.  Create table of content ids, determine biome, get name / altitude / ecosystem, get heat / humid scalars
local function update_biomes()

    for name, desc in pairs(minetest.registered_biomes) do

        if desc then

            mg_earth.biome_info[desc.name] = {}

            mg_earth.biome_info[desc.name].b_name = desc.name
            mg_earth.biome_info[desc.name].b_cid = minetest.get_biome_id(name)

            mg_earth.biome_info[desc.name].b_top = mg_earth.c_top
            mg_earth.biome_info[desc.name].b_top_depth = 1
            mg_earth.biome_info[desc.name].b_filler = mg_earth.c_filler
            mg_earth.biome_info[desc.name].b_filler_depth = 4
            mg_earth.biome_info[desc.name].b_stone = mg_earth.c_stone
            mg_earth.biome_info[desc.name].b_water_top = mg_earth.c_water
            mg_earth.biome_info[desc.name].b_water_top_depth = 1
            mg_earth.biome_info[desc.name].b_water = mg_earth.c_water
            mg_earth.biome_info[desc.name].b_river = mg_earth.c_river
            mg_earth.biome_info[desc.name].b_riverbed = mg_earth.c_gravel
            mg_earth.biome_info[desc.name].b_riverbed_depth = 2
            mg_earth.biome_info[desc.name].b_cave_liquid = mg_earth.c_lava
            mg_earth.biome_info[desc.name].b_dungeon = mg_earth.c_brick
            mg_earth.biome_info[desc.name].b_dungeon_alt = mg_earth.c_mossy
            mg_earth.biome_info[desc.name].b_dungeon_stair = mg_earth.c_block
            mg_earth.biome_info[desc.name].b_node_dust = mg_earth.c_air
            mg_earth.biome_info[desc.name].vertical_blend = 0
            mg_earth.biome_info[desc.name].min_pos = { x = -31000, y = -31000, z = -31000 }
            mg_earth.biome_info[desc.name].max_pos = { x = 31000, y = 31000, z = 31000 }
            mg_earth.biome_info[desc.name].b_miny = -31000
            mg_earth.biome_info[desc.name].b_maxy = 31000
            mg_earth.biome_info[desc.name].b_heat = 50
            mg_earth.biome_info[desc.name].b_humid = 50

            if desc.node_top and desc.node_top ~= "" then
                mg_earth.biome_info[desc.name].b_top = minetest.get_content_id(desc.node_top) or c_dirtgrass
            end

            if desc.depth_top and desc.depth_top ~= "" then
                mg_earth.biome_info[desc.name].b_top_depth = desc.depth_top or 1
            end

            if desc.node_filler and desc.node_filler ~= "" then
                mg_earth.biome_info[desc.name].b_filler = minetest.get_content_id(desc.node_filler) or c_dirt
            end

            if desc.depth_filler and desc.depth_filler ~= "" then
                mg_earth.biome_info[desc.name].b_filler_depth = desc.depth_filler or 4
            end

            if desc.node_stone and desc.node_stone ~= "" then
                mg_earth.biome_info[desc.name].b_stone = minetest.get_content_id(desc.node_stone) or c_stone
            end

            if desc.node_water_top and desc.node_water_top ~= "" then
                mg_earth.biome_info[desc.name].b_water_top = minetest.get_content_id(desc.node_water_top) or c_water
            end

            if desc.depth_water_top and desc.depth_water_top ~= "" then
                mg_earth.biome_info[desc.name].b_water_top_depth = desc.depth_water_top or 1
            end

            if desc.node_water and desc.node_water ~= "" then
                mg_earth.biome_info[desc.name].b_water = minetest.get_content_id(desc.node_water) or c_water
            end
            if desc.node_river_water and desc.node_river_water ~= "" then
                mg_earth.biome_info[desc.name].b_river = minetest.get_content_id(desc.node_river_water) or c_river
            end

            if desc.node_riverbed and desc.node_riverbed ~= "" then
                mg_earth.biome_info[desc.name].b_riverbed = minetest.get_content_id(desc.node_riverbed)
            end

            if desc.depth_riverbed and desc.depth_riverbed ~= "" then
                mg_earth.biome_info[desc.name].b_riverbed_depth = desc.depth_riverbed or 2
            end
            --[[
			if desc.node_cave_liquid and desc.node_cave_liquid ~= "" then
				mg_earth.biome_info[desc.name].b_cave_liquid = minetest.get_content_id(desc.node_cave_liquid)
			end

			if desc.node_dungeon and desc.node_dungeon ~= "" then
				mg_earth.biome_info[desc.name].b_dungeon = minetest.get_content_id(desc.node_dungeon)
			end

			if desc.node_dungeon_alt and desc.node_dungeon_alt ~= "" then
				mg_earth.biome_info[desc.name].b_dungeon_alt = minetest.get_content_id(desc.node_dungeon_alt)
			end

			if desc.node_dungeon_stair and desc.node_dungeon_stair ~= "" then
				mg_earth.biome_info[desc.name].b_dungeon_stair = minetest.get_content_id(desc.node_dungeon_stair)
			end

			if desc.node_dust and desc.node_dust ~= "" then
				mg_earth.biome_info[desc.name].b_node_dust = minetest.get_content_id(desc.node_dust)
			end
--]]
            if desc.vertical_blend and desc.vertical_blend ~= "" then
                mg_earth.biome_info[desc.name].vertical_blend = desc.vertical_blend or 0
            end

            if desc.y_min and desc.y_min ~= "" then
                mg_earth.biome_info[desc.name].b_miny = desc.y_min or -31000
            end

            if desc.y_max and desc.y_max ~= "" then
                mg_earth.biome_info[desc.name].b_maxy = desc.y_max or 31000
            end

            mg_earth.biome_info[desc.name].min_pos = desc.min_pos or { x = -31000, y = -31000, z = -31000 }
            if desc.y_min and desc.y_min ~= "" then
                mg_earth.biome_info[desc.name].min_pos.y = math.max(mg_earth.biome_info[desc.name].min_pos.y, desc.y_min)
            end

            mg_earth.biome_info[desc.name].max_pos = desc.max_pos or { x = 31000, y = 31000, z = 31000 }
            if desc.y_max and desc.y_max ~= "" then
                mg_earth.biome_info[desc.name].max_pos.y = math.min(mg_earth.biome_info[desc.name].max_pos.y, desc.y_max)
            end

            if desc.heat_point and desc.heat_point ~= "" then
                mg_earth.biome_info[desc.name].b_heat = desc.heat_point or 50
            end

            if desc.humidity_point and desc.humidity_point ~= "" then
                mg_earth.biome_info[desc.name].b_humid = desc.humidity_point or 50
            end


        end
    end
end

local function get_dirt(pos)

    local n1 = minetest.get_perlin(np_eco1):get_2d({ x = pos.x, y = pos.z })
    local n2 = minetest.get_perlin(np_eco2):get_2d({ x = pos.x, y = pos.z })
    local n3 = minetest.get_perlin(np_eco3):get_2d({ x = pos.x, y = pos.z })
    local n4 = minetest.get_perlin(np_eco4):get_2d({ x = pos.x, y = pos.z })
    local n5 = minetest.get_perlin(np_eco5):get_2d({ x = pos.x, y = pos.z })
    local n6 = minetest.get_perlin(np_eco6):get_2d({ x = pos.x, y = pos.z })
    local n7 = minetest.get_perlin(np_eco7):get_2d({ x = pos.x, y = pos.z })
    local n8 = minetest.get_perlin(np_eco8):get_2d({ x = pos.x, y = pos.z })

    local eco = "n0"

    local bmax = max(n1, n2, n3, n4, n5, n6, n7, n8)

    if bmax > dirt_threshold then
        if n1 == bmax then
            if n1 > eco_threshold then
                eco = "n9"
            else
                eco = "n1"
            end
        elseif n2 == bmax then
            if n2 > eco_threshold then
                eco = "n10"
            else
                eco = "n2"
            end
        elseif n3 == bmax then
            if n3 > eco_threshold then
                eco = "n11"
            else
                eco = "n3"
            end
        elseif n4 == bmax then
            if n4 > eco_threshold then
                eco = "n12"
            else
                eco = "n4"
            end
        elseif n5 == bmax then
            if n5 > eco_threshold then
                eco = "n13"
            else
                eco = "n5"
            end
        elseif n6 == bmax then
            if n6 > eco_threshold then
                eco = "n14"
            else
                eco = "n6"
            end
        elseif n7 == bmax then
            if n7 > eco_threshold then
                eco = "n15"
            else
                eco = "n7"
            end
        elseif n8 == bmax then
            if n8 > eco_threshold then
                eco = "n16"
            else
                eco = "n8"
            end
        end
    end
    --
    if not eco or eco == "" then
        eco = "n0"
    end

    --return dirt, lawn
    return eco

end

local function get_biome_altitude(y)

    local alt = ""

    if (y >= max_beach) and (y < max_coastal) then
        alt = "coastal"
    elseif (y >= max_coastal) and (y < max_lowland) then
        alt = "lowland"
    elseif (y >= max_lowland) and (y < max_shelf) then
        alt = "shelf"
    elseif (y >= max_shelf) and (y < max_highland) then
        alt = "highland"
    end

    return alt

end

local function calc_biome_from_noise(heat, humid, pos)
    local biome_closest = nil
    local biome_closest_blend = nil
    local dist_min = 31000
    local dist_min_blend = 31000

    for i, biome in pairs(mg_earth.biome_info) do
        local min_pos, max_pos = biome.min_pos, biome.max_pos
        if pos.y >= min_pos.y and pos.y <= max_pos.y + biome.vertical_blend
                and pos.x >= min_pos.x and pos.x <= max_pos.x
                and pos.z >= min_pos.z and pos.z <= max_pos.z then
            local d_heat = heat - biome.b_heat
            local d_humid = humid - biome.b_humid
            local dist = d_heat * d_heat + d_humid * d_humid -- Pythagorean distance

            if pos.y <= max_pos.y then
                -- Within y limits of biome
                if dist < dist_min then
                    dist_min = dist
                    biome_closest = biome
                elseif dist < dist_min_blend and dist > dist_min then
                    -- Blend area above biome
                    dist_min_blend = dist
                    biome_closest_blend = biome
                end
            end
        end
    end

    -- Carefully tune pseudorandom seed variation to avoid single node dither
    -- and create larger scale blending patterns similar to horizontal biome
    -- blend.
    local seed = math.floor(pos.y + (heat + humid) * 0.9)
    local rng = PseudoRandom(seed)

    if biome_closest_blend and dist_min_blend <= dist_min
            and rng:next(0, biome_closest_blend.vertical_blend) >= pos.y - biome_closest_blend.max_pos.y then
        return biome_closest_blend.b_name
    end

    return biome_closest.b_name

end

local function get_gal_biome_name(pheat, phumid, ppos)

    local t_heat, t_humid, t_altitude, t_name

    local m_top1 = 12.5
    local m_top2 = 37.5
    local m_top3 = 62.5
    local m_top4 = 87.5

    local m_biome1 = 25
    local m_biome2 = 50
    local m_biome3 = 75

    --[[	if phumid <= 25 then
		if pheat <= 25 then
			t_name = "cold_arid"
		elseif pheat <= 50 and pheat > 25 then
			t_name = "temperate_arid"
		elseif pheat <= 75 and pheat > 50 then
			t_name = "warm_arid"
		else
			t_name = "hot_arid"
		end
	elseif phumid <= 50 and phumid > 25 then
		if pheat <= 25 then
			t_name = "cold_temperate"
		elseif pheat <= 50 and pheat > 25 then
			t_name = "temperate_temperate"
		elseif pheat <= 75 and pheat > 50 then
			t_name = "warm_temperate"
		else
			t_name = "hot_temperate"
		end
	elseif phumid <= 75 and phumid > 50 then
		if pheat <= 25 then
			t_name = "cold_semihumid"
		elseif pheat <= 50 and pheat > 25 then
			t_name = "temperate_semihumid"
		elseif pheat <= 75 and pheat > 50 then
			t_name = "warm_semihumid"
		else
			t_name = "hot_semihumid"
		end
	elseif phumid > 75 then
		if pheat <= 50 then
			t_name = "temperate_humid"
		else
			t_name = "hot_humid"
		end
	else
		t_name = "default"
	end
--]]


    if pheat < m_top1 then
        t_heat = "cold"
    elseif pheat >= m_top1 and pheat < m_top2 then
        t_heat = "cool"
    elseif pheat >= m_top2 and pheat < m_top3 then
        t_heat = "temperate"
    elseif pheat >= m_top3 and pheat < m_top4 then
        t_heat = "warm"
    elseif pheat >= m_top4 then
        t_heat = "hot"
    else

    end

    if phumid < m_top1 then
        t_humid = "_arid"
    elseif phumid >= m_top1 and phumid < m_top2 then
        t_humid = "_semiarid"
    elseif phumid >= m_top2 and phumid < m_top3 then
        t_humid = "_temperate"
    elseif phumid >= m_top3 and phumid < m_top4 then
        t_humid = "_semihumid"
    elseif phumid >= m_top4 then
        t_humid = "_humid"
    else

    end

    if ppos.y < gal.mapgen.beach_depth then
        t_altitude = "_ocean"
    elseif ppos.y >= gal.mapgen.beach_depth and ppos.y < gal.mapgen.maxheight_beach then
        t_altitude = "_beach"
    elseif ppos.y >= gal.mapgen.maxheight_beach and ppos.y < gal.mapgen.maxheight_highland then
        t_altitude = ""
    elseif ppos.y >= gal.mapgen.maxheight_highland and ppos.y < gal.mapgen.maxheight_mountain then
        t_altitude = "_mountain"
    elseif ppos.y >= gal.mapgen.maxheight_mountain then
        t_altitude = "_strato"
    else
        t_altitude = ""
    end

    if t_heat and t_heat ~= "" and t_humid and t_humid ~= "" then
        t_name = t_heat .. t_humid .. t_altitude
    else
        if (t_heat == "hot") and (t_humid == "_humid") and (pheat > 90) and (phumid > 90) and (t_altitude == "_beach") then
            t_name = "hot_humid_swamp"
        elseif (t_heat == "hot") and (t_humid == "_semihumid") and (pheat > 90) and (phumid > 80) and (t_altitude == "_beach") then
            t_name = "hot_semihumid_swamp"
        elseif (t_heat == "warm") and (t_humid == "_humid") and (pheat > 80) and (phumid > 90) and (t_altitude == "_beach") then
            t_name = "warm_humid_swamp"
        elseif (t_heat == "temperate") and (t_humid == "_humid") and (pheat > 57) and (phumid > 90) and (t_altitude == "_beach") then
            t_name = "temperate_humid_swamp"
        else
            t_name = "temperate_temperate"
        end
    end

    if ppos.y >= -31000 and ppos.y < -20000 then
        t_name = "generic_mantle"
    elseif ppos.y >= -20000 and ppos.y < -15000 then
        t_name = "stone_basalt_01_layer"
    elseif ppos.y >= -15000 and ppos.y < -10000 then
        t_name = "stone_brown_layer"
    elseif ppos.y >= -10000 and ppos.y < -6000 then
        t_name = "stone_sand_layer"
    elseif ppos.y >= -6000 and ppos.y < -5000 then
        t_name = "desert_stone_layer"
    elseif ppos.y >= -5000 and ppos.y < -4000 then
        t_name = "desert_sandstone_layer"
    elseif ppos.y >= -4000 and ppos.y < -3000 then
        t_name = "generic_stone_limestone_01_layer"
    elseif ppos.y >= -3000 and ppos.y < -2000 then
        t_name = "generic_granite_layer"
    elseif ppos.y >= -2000 and ppos.y < gal.mapgen.ocean_depth then
        t_name = "generic_stone_layer"
    else

    end

    return t_name

end

local function get_heat_scalar(z)

    if use_heat_scalar == true then

        local t_z = abs(z)
        local t_heat = 50
        local t_heat_scale = 0.0071875
        local t_heat_mid = ((60000 * mg_world_scale) * 0.25)
        local t_diff = t_heat_mid - t_z
        local t_map_scale = t_heat_scale / mg_world_scale

        return t_heat + (t_diff * t_map_scale)

    else
        return 0
    end

end

local function get_humid_scalar(z)

    if use_humid_scalar == true then

        local t_z = abs(z)
        local t_humid_mid = ((60000 * mg_world_scale) * 0.062)
        local t_world = 0.0125 / mg_world_scale
        local t_diff = 0

        if t_z <= (t_humid_mid * 2) then
            local t_mid = t_humid_mid
            if t_z > t_mid then
                t_diff = abs((t_z - t_mid) * t_world) * -1
            else
                t_diff = abs((t_mid - t_z) * t_world)
            end
        elseif (t_z > (t_humid_mid * 2)) and (t_z <= (t_humid_mid * 4)) then
            local t_mid = t_humid_mid * 3
            if t_z > t_mid then
                t_diff = abs((t_z - t_mid) * t_world)
            else
                t_diff = abs((t_mid - t_z) * t_world) * -1
            end
        elseif (t_z > (t_humid_mid * 4)) then
            local t_mid = t_humid_mid * 5
            if t_z > t_mid then
                t_diff = abs((t_z - t_mid) * t_world) * -1
            else
                t_diff = abs((t_mid - t_z) * t_world)
            end
        end

        return t_diff

    else
        return 0
    end

end


--##Heightmap functions.  v6, v7, v67, vIslands, vVoronoi, vEarth and master get_mg_heightmap.
local function get_terrain_height_cliffs(theight, z, x)

    local cheight = minetest.get_perlin(np_cliffs):get_2d({ x = x, y = z })

    -- cliffs
    local t_cliff = 0
    if theight > 1 and theight < cliffs_thresh then
        local clifh = max(min(cheight, 1), 0)
        if clifh > 0 then
            clifh = -1 * (clifh - 1) * (clifh - 1) + 1
            t_cliff = clifh
            theight = theight + (cliffs_thresh - theight) * clifh * ((theight < 2) and theight - 1 or 1)
        end
    end
    return theight, t_cliff
end

local function get_3d_height(z, y, x)

    --local n_y = minetest.get_perlin(np_2d):get_2d({x=x,y=z})
    --local n_y = minetest.get_perlin(np_3dterrain):get_2d({x=x,y=z})

    --local n_f = minetest.get_perlin(np_3dterrain):get_3d({x = x, y = (n_y + y), z = z})
    local n_f = minetest.get_perlin(np_3dterrain):get_3d({ x = x, y = y, z = z })

    --local s_d = (1 - n_y) / (mg_density * mg_world_scale)
    local s_d = n_f - (n_y + y)
    --local n_t = n_f + s_d
    local n_t = n_f - s_d

    return n_t
    --return n_f * mg_density
    --return n_y

end

local function get_3d_density(z, y, x)

    local n_f = minetest.get_perlin(np_3dterrain):get_3d({ x = x, y = y, z = z })
    local s_d = (1 - y) / (mg_density * mg_world_scale)

    local n_t = n_f + s_d

    return n_t

end

local function get_v6_base(terrain_base, terrain_higher,
                           steepness, height_select)

    local base = 1 + terrain_base
    local higher = 1 + terrain_higher

    -- Limit higher ground level to at least base
    if higher < base then
        higher = base
    end

    -- Steepness factor of cliffs
    local b = steepness
    b = rangelim(b, 0.0, 1000.0)
    b = 5 * b * b * b * b * b * b * b
    b = rangelim(b, 0.5, 1000.0)

    -- Values 1.5...100 give quite horrible looking slopes
    if b > 1.5 and b < 100.0 then
        if b < 10 then
            b = 1.5
        else
            b = 100
        end
    end

    local a_off = -0.20 -- Offset to more low
    local a = 0.5 + b * (a_off + height_select);
    a = rangelim(a, 0.0, 1.0) -- Limit

    return math.floor(base * (1.0 - a) + higher * a)
end

local function get_v6_height(z, x)

    local terrain_base = minetest.get_perlin(np_terrain_base):get_2d({
        x = x + 0.5 * np_terrain_base.spread.x,
        y = z + 0.5 * np_terrain_base.spread.y })

    local terrain_higher = minetest.get_perlin(np_terrain_higher):get_2d({
        x = x + 0.5 * np_terrain_higher.spread.x,
        y = z + 0.5 * np_terrain_higher.spread.y })

    local steepness = minetest.get_perlin(np_steepness):get_2d({
        x = x + 0.5 * np_steepness.spread.x,
        y = z + 0.5 * np_steepness.spread.y })

    local height_select = minetest.get_perlin(np_height_select):get_2d({
        x = x + 0.5 * np_height_select.spread.x,
        y = z + 0.5 * np_height_select.spread.y })

    return get_v6_base(terrain_base, terrain_higher, steepness, height_select) + 2 -- (Dust)
end

local function get_v7_height(z, x)

    local aterrain = 0

    local hselect = minetest.get_perlin(np_height):get_2d({ x = x, y = z })
    local hselect = rangelim(hselect, 0, 1)

    local persist = minetest.get_perlin(np_persist):get_2d({ x = x, y = z })
    --local lacun = 2 + (persist * persist)

    np_base.persistence = persist;
    --np_v7_base.lacunarity = lacun
    local height_base = minetest.get_perlin(np_base):get_2d({ x = x, y = z })

    np_2d.persistence = persist;
    --np_v7_alt.lacunarity = lacun
    local height_alt = minetest.get_perlin(np_2d):get_2d({ x = x, y = z })

    if (height_alt > height_base) then
        aterrain = floor(height_alt)
    else
        aterrain = floor((height_base * hselect) + (height_alt * (1 - hselect)))
    end

    return aterrain
end

local function get_terrain_height(z, x)

    local tterrain = 0

    local hselect = minetest.get_perlin(np_height):get_2d({ x = x, y = z })
    local hselect = rangelim(hselect, 0, 1)

    local persist = minetest.get_perlin(np_persist):get_2d({ x = x, y = z })

    np_base.persistence = persist;
    local height_base = minetest.get_perlin(np_base):get_2d({ x = x, y = z })

    np_2d.persistence = persist;
    local height_alt = minetest.get_perlin(np_2d):get_2d({ x = x, y = z })

    if (height_alt > height_base) then
        tterrain = floor(height_alt)
    else
        tterrain = floor((height_base * hselect) + (height_alt * (1 - hselect)))
    end

    local cliffs_thresh = floor((np_2d.scale) * 0.5)
    local cheight = minetest.get_perlin(np_cliffs):get_2d({ x = x, y = z })

    local t_cliff = 0

    if tterrain > 1 and tterrain < cliffs_thresh then
        local clifh = max(min(cheight, 1), 0)
        if clifh > 0 then
            clifh = -1 * (clifh - 1) * (clifh - 1) + 1
            t_cliff = clifh
            tterrain = tterrain + (cliffs_thresh - tterrain) * clifh * ((tterrain < 2) and tterrain - 1 or 1)
        end
    end

    return tterrain, t_cliff

end

local function get_valleys_height(z, x)

    -- Check if in a river channel
    local v_rivers = minetest.get_perlin(np_val_river):get_2d({ x = x, y = z })
    local abs_rivers = abs(v_rivers)
    --if abs(v_rivers) <= river_size_factor then
    --	-- TODO: Add riverbed calculation
    --	return nil
    --end

    local valley = minetest.get_perlin(np_val_depth):get_2d({ x = x, y = z })
    local valley_d = valley * valley
    local base = valley_d + minetest.get_perlin(np_val_terrain):get_2d({ x = x, y = z })
    local river = abs_rivers - river_size_factor
    local tv = max(river / minetest.get_perlin(np_val_profile):get_2d({ x = x, y = z }), 0)
    local valley_h = valley_d * (1 - math.exp(-tv * tv))
    local surface_y = base + valley_h
    local slope = valley_h * minetest.get_perlin(np_val_slope):get_2d({ x = x, y = z })

    --# 2D Generation
    local n_fill = minetest.get_perlin(np_val_fill):get_3d({ x = x, y = surface_y, z = z })

    local surface_delta = n_fill - surface_y;
    local density = slope * n_fill - surface_delta;

    local river_course = 31000
    if abs_rivers <= river_size_factor then
        -- TODO: Add riverbed calculation
        river_course = abs_rivers
    end

    return density, river_course
    --return density

end

local function get_mg_heightmap(ppos, nheat, nhumid, i2d)

    local r_y = mg_flat_height
    local r_c = 0

    local vheight = 0
    local nheight = 0
    local n_c = 0

    mg_earth.valleymap[i2d] = -31000
    mg_earth.rivermap[i2d] = -31000
    mg_earth.riverpath[i2d] = 0

    if mg_heightmap_select == "vEarth" or mg_heightmap_select == "vVoronoi" or mg_heightmap_select == "vVoronoiPlus" then

        local m_idx, m_dist, m_z, m_x = get_nearest_cell({ x = ppos.x, z = ppos.z }, 1)
        get_cell_neighbors(m_idx, m_z, m_x, 1)
        --local m_slope = (m_z - ppos.z) / (m_x - ppos.x)
        --local m_slope_inv = (m_x - ppos.x) / (m_z - ppos.z)
        local p_idx, p_dist, p_z, p_x = get_nearest_cell({ x = ppos.x, z = ppos.z }, 2)
        get_cell_neighbors(p_idx, p_z, p_x, 2)
        --local p_slope = (p_z - ppos.z) / (p_x - ppos.x)
        --local p_slope_inv = (p_x - ppos.x) / (p_z - ppos.z)
        --local p_ridge = sin(abs((tan((p_z - ppos.z) / (p_x - ppos.x))) + (tan((p_x - ppos.x) / (p_z - ppos.z)))))

        mg_earth.cellmap[i2d] = { m = m_idx, p = p_idx }

        local p_n = mg_neighbors[p_idx]
        local p_ni = get_nearest_midpoint({ x = ppos.x, z = ppos.z }, p_n)
        local pe_dist = get_dist2endline_inverse({ x = p_x, z = p_z }, { x = p_n[p_ni].m_x, z = p_n[p_ni].m_z }, { x = ppos.x, z = ppos.z })
        local p2e_dist = get_dist((p_x - p_n[p_ni].m_x), (p_z - p_n[p_ni].m_z), dist_metric)
        local n2pe_dist = get_dist2line({ x = p_x, z = p_z }, { x = p_n[p_ni].n_x, z = p_n[p_ni].n_z }, { x = ppos.x, z = ppos.z })
        --local pe_dir, pe_comp = get_direction_to_pos({x = ppos.x, z = ppos.z},{x = p_n[p_ni].m_x, z = p_n[p_ni].m_z})
        --local e_slope = get_slope_inverse({x = p_x, z = p_z},{x = p_n[p_ni].m_x, z = p_n[p_ni].m_z})

        local vcontinental = ((m_dist * v_cscale) + (p_dist * v_pscale))
        --local vcontinental = ((m_dist + p_dist) * v_pscale)
        --local vterrain = ((mg_base_height + v7_max_height) - (m_dist * v_cscale)) - (p_dist * v_pscale)
        local vterrain = (mg_base_height * 1.4) - ((m_dist * v_cscale) + (p_dist * v_pscale))
        --local vterrain = (mg_base_height * 1.4) - ((m_dist + p_dist) * v_pscale)
        --local vterrain = ((mg_base_height + v7_max_height) - (m_dist * v_cscale)) - sin(abs((tan((p_z - z) / (p_x - x))) + (tan((p_x - x) / (p_z - z)))))

        local valt = (vterrain * 0.25) + (((vterrain / vcontinental) * (mg_world_scale / 0.01)) * 0.30)
        --local vheight = vterrain * 0.25

        if mg_heightmap_select == "vEarth" or mg_heightmap_select == "vVoronoiPlus" then
            vheight = valt
            --vheight = vterrain
        else
            vheight = vterrain
        end

        r_y = vheight
        mg_voronoimap[i2d] = vterrain

        if mg_heightmap_select == "vEarth" then

            --local v6_height = 0
            --local v6_height = get_v6_height(z,x)
            local v7_height = get_v7_height(ppos.z, ppos.x)
            --local v7_height = (get_v7_height(z,x) / v7_max_height) * (mg_world_scale / 0.01)

            --local nfill = minetest.get_perlin(np_fill):get_2d({x=x,y=z})

            --if vterrain > 0 then
            --local d_height = (v6_noise * (vterrain / mg_base_height))
            local d_humid = 0
            if nhumid < 50 then
                d_humid = (get_v6_height(ppos.z, ppos.x) * ((50 - nhumid) / 50))
            end
            --v6_height = (d_height * 0.1) + (d_humid * 0.5)
            local v6_height = d_humid * 0.5
            --v6_height = d_humid
            --end

            if mg_noise_select == "v6" then
                nheight = v6_height
            elseif mg_noise_select == "v67" then
                --nheight = ((((v7_height + v6_height) / bcontinental) * (mg_world_scale / 0.01)) * 0.5)
                nheight = v7_height + v6_height
                --nheight = (v7_height + v6_height) * noise_blend
                --nheight = ((v7_height + v6_height) * noise_blend) * (max(0,(p2e_dist - p_dist)) / p2e_dist)
                --local nheight = ((v7_height + v6_height) * 0.65) * (max(0,(p2e_dist - (pe_dist + mg_valley_size))) / p2e_dist)
                --local nheight = (v7_height + v6_height) * (max(0,(p2e_dist - (pe_dist + mg_valley_size))) / p2e_dist)
                --local nheight = (v7_height + v6_height) * ((p2e_dist - (pe_dist + mg_valley_size)) / p2e_dist)
            elseif mg_noise_select == "v7" then
                nheight = v7_height
            elseif mg_noise_select == "vIslands" then
                nheight, n_c = get_terrain_height(z, x)
            elseif mg_noise_select == "v67Valleys" then
                mg_rivers_enabled = true
                nheight = v7_height + v6_height + (get_valleys_height(ppos.z, ppos.x) * -1)
            elseif mg_noise_select == "vValleys" then
                --mg_rivers_enabled = true
                nheight = (get_valleys_height(ppos.z, ppos.x) * -1)
            elseif mg_noise_select == "v3D" then
                -- local t_y = r_y + minetest.get_perlin(np_2d):get_2d({x=ppos.x,y=ppos.z})
                -- local h_y = mg_earth.heightmap[i2d]
                -- -- local h_y = get_3d_height(z,r_y,x)
                -- -- -- if h_y and h_y > -31000 then
                -- -- -- nheight = h_y + t_y
                -- -- -- else
                -- -- -- nheight = t_y
                -- -- -- end
                -- mg_voronoimap[i2d] = t_y
                --if h_y then
                -- if h_y > ocean_depth and h_y <then
                --nheight = h_y + t_y
                --nheight = h_y
                -- end
                -- -- if h_y < mg_water_level and h_y > ocean_depth then
                -- -- nheight = h_y + t_y
                -- -- else
                -- -- end
                -- -- else
                -- -- nheight = t_y
                --end

                --local t_y = vheight + minetest.get_perlin(np_2d):get_2d({x=ppos.x,y=ppos.z})
                local t_y = vheight + mg_earth.heightmap[i2d]
                mg_voronoimap[i2d] = t_y
                local n_f = 0

                --if mg_world_scale == 1 then
                --n_f = nbuf_3dterrain[z-minp.z+1][(n_y + y)-minp.y+1][x-minp.x+1]
                --n_f = nbuf_3dterrain[z-minp.z+1][(n_y + y)-minp.y+1][x-minp.x+1]
                --	n_f = nbuf_3dterrain[z-minp.z+1][t_y-minp.y+1][x-minp.x+1]
                --else
                --n_f = minetest.get_perlin(np_3dterrain):get_3d({x = x, y = (n_y + y), z = z})
                n_f = minetest.get_perlin(np_3dterrain):get_3d({ x = ppos.x, y = t_y, z = ppos.z })
                --end

                --local s_d = (1 - (n_y + y)) / (mg_density * mg_world_scale)
                local s_d = (1 - t_y) / (mg_density * mg_world_scale)
                local n_t = n_f + s_d

                -- if get_3d_density(z,y,x) > 0 then
                if n_t > 0 then
                    --mg_earth.heightmap[index2d] = (n_y + y)
                    --mg_earth.heightmap[index2d] = y

                    nheight = n_t + t_y

                end

                --nheight = get_3d_height(ppos.z,vheight,ppos.x)
            end

            local bterrain = 0

            if mg_rivers_enabled then

                -- local tterrain = vheight + nheight
                -- local v_floor = mg_valley_size * 0.5
                -- local v_lift = mg_valley_size * 0.8
                -- local v_rise = mg_valley_size
                -- --max(0,(t_terrain - bheight))

                -- if (pe_dist <= v_rise) and (pe_dist > v_lift) then
                -- --bterrain = min((vheight + max(1,(tterrain - vheight))), tterrain)
                -- bterrain = vheight + ((nheight * (max(0,((p2e_dist - v_rise) - p_dist)) / (p2e_dist - v_rise))) * 0.5)
                -- --bterrain = vheight + (nheight * 0.35)
                -- elseif (pe_dist <= v_lift) and (pe_dist > v_floor) then
                -- --bterrain = min((vheight + max(0,(tterrain - vheight))), tterrain)
                -- bterrain = vheight + ((nheight * (max(0,((p2e_dist - v_rise) - p_dist)) / (p2e_dist - v_rise))) * 0.2)
                -- --bterrain = vheight + (nheight * 0.1)
                -- elseif (pe_dist <= v_floor) then
                -- --bterrain = min(vheight, tterrain)
                -- bterrain = vheight
                -- --bterrain = vheight
                -- else
                -- --vterrain = t_terrain + (v7_height / max(1,((p_dist * v_pscale) - v_rise)))
                -- --bterrain = tterrain + (v7_height / bcontinental)
                -- --bterrain = vheight + (nheight * (max(0,((p2e_dist - v_rise) - p_dist)) / (p2e_dist - v_rise)))
                -- --bterrain = vheight + (nheight * noise_blend)
                -- bterrain = vheight + (nheight * noise_blend)
                -- end

                -- bterrain = vheight + (nheight * noise_blend)
                bterrain = vheight + (nheight * min(1, ((1 / p_dist) * 100)))
                --bterrain = vheight + (nheight * min(1,((1 / min(p_dist,p2e_dist)) * 100)))
                --bterrain = vheight + (nheight * (1 - (p_dist * 0.001)))
                --bterrain = vheight + (nheight * (1 - (min(p_dist,p2e_dist) * 0.001)))

            else
                --bterrain = vheight + (((nheight * (p_dist * v_pscale)) * (mg_world_scale / 0.01)) * noise_blend)
                --bterrain = vheight + (nheight * noise_blend)
                bterrain = vheight + (nheight * min(1, ((1 / p_dist) * 100)))
                --bterrain = vheight + (nheight * min(1,((1 / min(p_dist,p2e_dist)) * 100)))
                --bterrain = vheight + (nheight * (1 - (p_dist * 0.001)))
                --bterrain = vheight + (nheight * (1 - (min(p_dist,p2e_dist) * 0.001)))
            end


            --local bterrain = vheight + (nheight * min(1,(max(0,(pe_dist - mg_valley_size)) / (mg_valley_size + sin(nheight - vheight)))))
            --local bterrain = vheight + (nheight * min(1,(max(0,(pe_dist - (mg_valley_size + sin(nheight - vheight)))) / mg_valley_size)))
            --local bterrain = (nheight * min(1,(max(0,(pe_dist - ((n2pe_dist / mg_valley_size) + sin(nheight - vheight)))) / (n2pe_dist / mg_valley_size))))
            --local bterrain = vheight + (nheight * (pe_dist / p2e_dist))
            --local bterrain = vheight + (nheight - (tonumber("0.0" .. tostring(p_dist))))
            --local bterrain = vheight + (nheight * (1 / (max(1,(bcontinental * 0.1)))))
            --local bterrain = vheight + (nheight * (1 / (max(1,bcontinental))))
            --local bterrain = vheight + nheight
            --local bterrain = nheight
            --local bterrain = vheight + nheight

            if mg_noise_select == "v3D" then
                r_y = nheight
                r_c = 0
            else
                r_y, r_c = get_terrain_height_cliffs(bterrain, ppos.z, ppos.x)
            end

        end

        if mg_rivers_enabled then
            if r_y >= 0 then

                local terrain_scalar_inv = (min(0, ((250 * mg_world_scale) - r_y)) / (250 * mg_world_scale))
                local r_size = mg_valley_size * terrain_scalar_inv
                local t_sin = sin(r_y - vheight)

                if n2pe_dist >= (r_y - r_size) then

                    --mg_earth.valleymap[i2d] = n2pe_dist / mg_valley_size
                    mg_earth.rivermap[i2d] = pe_dist
                    mg_earth.riverpath[i2d] = t_sin

                end
            end
        end

    end

    if mg_heightmap_select == "v6" or mg_heightmap_select == "v7" or mg_heightmap_select == "v67" or mg_heightmap_select == "vIslands" then

        local v6_height = 0
        local v7_height = 0
        --local nfill = minetest.get_perlin(np_fill):get_2d({x=x,y=z})


        if mg_heightmap_select == "v6" or mg_heightmap_select == "v67" then
            v6_height = get_v6_height(ppos.z, ppos.x)
        end

        if mg_heightmap_select == "v7" or mg_heightmap_select == "v67" or mg_heightmap_select == "vIslands" then
            v7_height = get_v7_height(ppos.z, ppos.x)
            --v7_height = get_v7_height(z,x) * 0.5
            --v7_height = (get_v7_height(z,x) / v7_max_height) * (mg_world_scale / 0.01)
            --v7_height = (v7_noise * v7_noise) / (mg_base_height * 1.4)
        end

        if mg_heightmap_select == "v67" then
            --if vterrain > 0 then
            --local d_height = (v6_noise * (vterrain / mg_base_height))
            local d_humid = 0
            if nhumid < 50 then
                d_humid = (get_v6_height(ppos.z, ppos.x) * ((50 - nhumid) / 50))
            end
            --v6_height = (d_height * 0.1) + (d_humid * 0.5)
            v6_height = d_humid * 0.5
            --v6_height = d_humid
            --end
        end

        if mg_heightmap_select == "v6" then
            nheight = v6_height
        elseif mg_heightmap_select == "v7" or mg_heightmap_select == "vIslands" then
            nheight = v7_height
        elseif mg_heightmap_select == "v67" then
            nheight = (v7_height + v6_height) * noise_blend
        else
            --nheight = ((((v7_height + v6_height) / bcontinental) * (mg_world_scale / 0.01)) * 0.5)
            nheight = v7_height + v6_height
            --nheight = (v7_height + v6_height) * noise_blend
        end
    end

    if mg_heightmap_select == "v6" or mg_heightmap_select == "v7" or mg_heightmap_select == "v67" or mg_heightmap_select == "vIslands" then

        mg_rivers_enabled = false

    end

    if mg_heightmap_select == "vIslands" then
        --local bterrain = vheight + (nheight * noise_blend)
        local bterrain = vheight + nheight
        r_y, r_c = get_terrain_height_cliffs(bterrain, ppos.z, ppos.x)
    end

    if mg_heightmap_select == "v6" or mg_heightmap_select == "v7" or mg_heightmap_select == "v67" then
        local bterrain = vheight + nheight
        r_y = bterrain
    end

    if mg_heightmap_select == "vValleys" then
        r_y, r_c = get_valleys_height(ppos.z, ppos.x)
        mg_earth.rivermap[i2d] = r_c
        mg_rivers_enabled = true
        --mg_lakes_enabled = false
        r_c = 0
    end

    if mg_heightmap_select == "v3D" then
        local t_y = r_y
        local h_y = mg_earth.heightmap[i2d]
        if h_y and h_y > -31000 then
            r_y = h_y
        else
            r_y = t_y
        end
        -- r_y = t_y
    end

    return r_y, (r_c + n_c)

end


--##Lakes mod by Sokomine
-- helper function for mark_min_max_height_in_mapchunk(..)
-- math_extrema: math.min for maxheight; math.max for minheight
-- populates the tables minheight and maxheight with data;
local mark_min_max_height_local = function(minp, maxp, heightmap, ax, az, i, chunksize, minheight, maxheight, direction)
    i = i + 1;
    if (ax == minp.x or az == minp.z or ax == maxp.x or az == maxp.z) then
        minheight[i] = heightmap[i];
        maxheight[i] = heightmap[i];
    else
        if (not (minheight[i])) then
            minheight[i] = -100000;
        end
        if (not (maxheight[i])) then
            maxheight[i] = 100000;
        end

        local i_side = i - chunksize;
        local i_prev = i - 1;
        local i_add = -1;
        local swap_args = false;
        if (direction == -1) then
            i_side = i + chunksize;
            i_prev = i + 1;
            i_add = 1;
            swap_args = true;
        else
            direction = 1;
        end

        -- do for minheight (=search for hills)
        local hr = minheight[i_side];
        -- handle minheight
        -- compare minheight with the neighbour to the right or left
        if (hr and heightmap[i] and hr > minheight[i]) then
            minheight[i] = math.min(hr, heightmap[i]);
        end

        if (((direction == 1 and ax > minp.x) or (direction == -1 and ax < maxp.x))
                -- has the neighbour before a higher minheight?
                and minheight[i_prev]
                and minheight[i_prev] > minheight[i]) then
            minheight[i] = math.min(minheight[i_prev], heightmap[i]);
        end
        hr = minheight[i];
        -- walk backward in that row and set all with a lower minheight but
        -- a sufficiently high height to the new minheight
        local n = 1;
        local i_run = i - n;
        while (hr
                and ((direction == 1 and (ax - n) >= minp.x) or (direction == -1 and (ax + n) <= maxp.x))
                -- has the neighbour before a lower minheight?
                and minheight[i_run]
                and minheight[i_run] < hr
                -- is the neighbour before heigh enough?
                and (heightmap[i_run] >= hr or heightmap[i_run] > minheight[i_run])) do
            hr = math.min(hr, heightmap[i_run]);
            minheight[i_run] = hr;

            n = n + 1;
            i_run = i_run + i_add;
        end

        -- same for maxheight (= search for holes)
        hr = maxheight[i_side];
        -- compare maxheight with the neighbour to the right or left
        if (hr and heightmap[i] and hr < maxheight[i]) then
            maxheight[i] = math.max(hr, heightmap[i]);
        end

        if (((direction == 1 and ax > minp.x) or (direction == -1 and ax < maxp.x))
                -- has the neighbour before a higher maxheight?
                and maxheight[i_prev]
                and maxheight[i_prev] < maxheight[i]) then
            maxheight[i] = math.max(maxheight[i_prev], heightmap[i]);
        end
        hr = maxheight[i];
        -- walk backward in that row and set all with a lower maxheight but
        -- a sufficiently high height to the new maxheight
        local n = 1;
        local i_run = i - n;
        while (hr
                and ((direction == 1 and (ax - n) >= minp.x) or (direction == -1 and (ax + n) <= maxp.x))
                -- has the neighbour before a lower maxheight?
                and maxheight[i_run]
                and maxheight[i_run] > hr
                -- is the neighbour before heigh enough?
                and (heightmap[i_run] <= hr or heightmap[i_run] < maxheight[i_run])) do
            hr = math.max(hr, heightmap[i_run]);
            maxheight[i_run] = hr;

            n = n + 1;
            i_run = i_run + i_add;
        end
    end
end

-- detect places where nodes might be removed or added without changing the borders
-- of the mapchunk; afterwards, the landscape may be levelled, but one hill or hole
-- cannot yet be distinguished from the other;
-- more complex shapes may require multiple runs
-- Note: There is no general merging here (apart fromm the two runs) because MT maps are
--       usually very small-scale and there would be too many areas that may need merging.
local mark_min_max_height_in_mapchunk = function(minp, maxp, heightmap)
    local chunksize = maxp.x - minp.x + 1;
    local minheight = {}
    local maxheight = {}
    for j = 1, 2 do
        local i = 0
        for az = minp.z, maxp.z do
            for ax = minp.x, maxp.x do
                -- fill minheight and maxheight with data whereever hills or holes are
                mark_min_max_height_local(minp, maxp, heightmap, ax, az, i, chunksize, minheight, maxheight, 1);
                i = i + 1
            end
        end

        -- we keep i the way it is;
        i = i + 1;
        -- the previous run could not cover all situations; check from the other side now
        for az = maxp.z, minp.z, -1 do
            for ax = maxp.x, minp.x, -1 do
                -- update minheight and maxheight for hills and holes; but this time, start from the
                -- opposite corner of the mapchunk in order to preserve what is needed there
                mark_min_max_height_local(minp, maxp, heightmap, ax, az, i, chunksize, minheight, maxheight, -1);
                i = i - 1;
            end
        end
    end
    return { minheight = minheight, maxheight = maxheight };
end

-- helper function for mark_holes_and_hills_in_mapchunk(..)
local identify_individual_holes_or_hills = function(minp, maxp, ax, az, i, chunksize, markmap, merge_into, hole_counter, hole_data, h_real, h_max, condition)
    markmap[i] = 0;
    -- no hole or hill
    if (not (condition)) then
        return hole_counter;
    end
    local h_prev_z = markmap[i - chunksize];
    local h_prev_x = markmap[i - 1];
    local match_z = 0;
    local match_x = 0;
    -- if the node to the right (at z=z-1) is also part of a hole, then
    -- both nodes are part of the same hole
    if (az > minp.z and h_prev_z and h_prev_z > 0) then
        match_z = h_prev_z;
    end
    -- if the node before (at x=x-1) is also part of a hole, then both
    -- nodes are also part of the same hole
    if (ax > minp.x and h_prev_x and h_prev_x > 0) then
        match_x = h_prev_x;
    end

    -- continue the hole from z direction
    if (match_z > 0 and match_x == 0) then
        markmap[i] = merge_into[match_z];
        -- continue the hole from x direction
    elseif (match_z == 0 and match_x > 0) then
        markmap[i] = merge_into[match_x];
        -- new hole at this place
    elseif (match_z == 0 and match_x == 0) then
        hole_counter = hole_counter + 1;
        merge_into[hole_counter] = hole_counter;
        markmap[i] = hole_counter;
        -- both are larger than 0 and diffrent - we need to merge
    else
        markmap[i] = merge_into[match_z];
        -- actually do the merge
        for k, v in ipairs(merge_into) do
            if (merge_into[k] == match_x) then
                merge_into[k] = merge_into[match_z];
            end
        end
    end

    -- gather some statistical data in hole_data
    if (markmap[i] > 0) then
        local id = markmap[i];
        -- height difference
        local ay = math.abs(h_max - h_real);
        if (not (hole_data[id])) then
            hole_data[id] = {
                minp = { x = ax, z = az, y = math.min(h_max, h_real) },
                maxp = { x = ax, z = az, y = math.max(h_max, h_real) },
                size = 1,
                volume = ay,
            };
        else
            -- the surface area is one larger now
            hole_data[id].size = hole_data[id].size + 1;
            -- the volume has also grown
            hole_data[id].volume = hole_data[id].volume + ay;
            if (ax < hole_data[id].minp.x) then
                hole_data[id].minp.x = ax;
            end
            -- minimal and maximal dimensions may have changed
            hole_data[id].minp.x = math.min(ax, hole_data[id].minp.x);
            hole_data[id].maxp.x = math.max(ax, hole_data[id].maxp.x);
            hole_data[id].minp.z = math.min(az, hole_data[id].minp.z);
            hole_data[id].maxp.z = math.max(az, hole_data[id].maxp.z);
            hole_data[id].minp.y = math.min(ay, hole_data[id].minp.y);
            hole_data[id].maxp.y = math.max(ay, hole_data[id].maxp.y);
        end
    end
    return hole_counter;
end

-- helper function for mark_holes_and_hills_in_mapchunk(..)
-- works the same for hills and holes
local merge_if_same_hole_or_hill = function(hole_data, merge_into)
    local id2merged = {}
    local merged = {}
    local hole_counter = 1;
    -- we already know from merge_into that k needs to be merged into v
    for k, v in ipairs(merge_into) do
        -- we have not covered the merge target
        if (not (id2merged[v])) then
            id2merged[v] = hole_counter;
            hole_counter = hole_counter + 1;
            merged[v] = hole_data[v];
            -- another hole or hill has already been treated -> merge with new data needed
        else
            -- merge hole_data_merged
            merged[v].size = merged[v].size + hole_data[k].size;
            merged[v].volume = merged[v].volume + hole_data[k].volume;
            -- minimal and maximal dimensions may have changed
            merged[v].minp.x = math.min(merged[v].minp.x, hole_data[k].minp.x);
            merged[v].maxp.x = math.max(merged[v].maxp.x, hole_data[k].maxp.x);
            merged[v].minp.z = math.min(merged[v].minp.z, hole_data[k].minp.z);
            merged[v].maxp.z = math.max(merged[v].maxp.z, hole_data[k].maxp.z);
            merged[v].minp.y = math.min(merged[v].minp.y, hole_data[k].minp.y);
            merged[v].maxp.y = math.max(merged[v].maxp.y, hole_data[k].maxp.y);
        end
        id2merged[k] = id2merged[v];
    end
    return { id2merged = id2merged, merged = merged };
end

local mark_holes_and_hills_in_mapchunk = function(minp, maxp, heightmap, minheight, maxheight)
    local chunksize = maxp.x - minp.x + 1;
    -- distinguish the individual hills and holes from each other so that we may treat
    -- each one diffrently if so desired
    local holes_markmap = {}
    local hills_markmap = {}
    -- used to mark the individual holes on the markmap
    local hole_counter = 0;
    local hill_counter = 0;
    -- some holes will first be seen from diffrent directions and get diffrent IDs (=
    -- hole_counter) assigned; these need to be merged because they're the same
    local holes_merge_into = {};
    local hills_merge_into = {};
    -- store size, minp/maxp, max/min depth/height
    local hole_data = {};
    local hill_data = {};

    local i = 0
    for az = minp.z, maxp.z do
        for ax = minp.x, maxp.x do
            i = i + 1;

            local h_real = heightmap[i];
            local h_min = minheight[i];
            local h_max = maxheight[i];
            -- do this for holes
            hole_counter = identify_individual_holes_or_hills(minp, maxp, ax, az, i, chunksize,
                    holes_markmap, holes_merge_into, hole_counter, hole_data, h_real, h_min,
            -- h_max>0 because we do not want to create pools/fill land below sea level
                    (h_max and h_real and h_max > h_real and h_max < maxp.y and h_max > minp.y and h_max > 0));
            -- ..and for hills
            hill_counter = identify_individual_holes_or_hills(minp, maxp, ax, az, i, chunksize,
                    hills_markmap, hills_merge_into, hill_counter, hill_data, h_real, h_max,
            -- the socket of individual hills may well lie below water level
                    (h_min and h_real and h_min < h_real and h_min < maxp.y and h_min > minp.y and h_min > minp.y));
        end
    end

    -- a hole or hill might have been found from diffrent directions and thus
    -- might have gotten diffrent ids; merge them if they represent the same
    -- hole or hill
    local holes = merge_if_same_hole_or_hill(hole_data, holes_merge_into);
    local hills = merge_if_same_hole_or_hill(hill_data, hills_merge_into);

    return { holes = holes, holes_merge_into = holes_merge_into, holes_markmap = holes_markmap,
             hills = hills, hills_merge_into = hills_merge_into, hills_markmap = hills_markmap };
end

-- create a (potential) new heightmap where all the hills we discovered are flattened and all
-- holes filled with something so that we get more flat terrain;
-- this function also adjusts
-- 	detected.hills.merged[id].target_height (set to the flattened value)
-- 	and detected.hills_markmap[i]  for easier access without having to go throuh
-- 	                               detected.hills_merge_into in the future
-- (same for holes)
local heightmap_with_hills_lowered_and_holes_filled = function(minp, maxp, heightmap, extrema, detected)
    local adjusted_heightmap = {}
    local chunksize = maxp.x - minp.x + 1;
    local i = 0
    for az = minp.z, maxp.z do
        for ax = minp.x, maxp.x do
            i = i + 1;

            -- no changes at the borders of the mapchunk
            if (ax == minp.x or ax == maxp.x or az == minp.z or az == maxp.z) then
                adjusted_heightmap[i] = heightmap[i];
            else
                -- make sure it gets one value set
                adjusted_heightmap[i] = heightmap[i];

                -- is there a hill?
                local hill_id = detected.hills_markmap[i];
                if (hill_id and hill_id > 0) then
                    -- which hill are we dealing with?
                    local id = detected.hills_merge_into[hill_id];
                    local new_height = detected.hills.merged[id].target_height;
                    if (not (new_height)) then
                        -- target height: height if this hill would be removed completely
                        new_height = minp.y - 1;
                    end
                    new_height = math.max(new_height, extrema.minheight[i]);
                    local id_hole_right = detected.holes_markmap[i - chunksize];
                    if (id_hole_right and id_hole_right > 0) then
                        new_height = math.max(new_height, detected.holes.merged[id_hole_right].target_height);
                    end
                    local id_hole_prev = detected.holes_markmap[i - 1];
                    if (id_hole_prev and id_hole_prev > 0) then
                        new_height = math.min(new_height, detected.holes.merged[id_hole_prev].target_height);
                    end
                    detected.hills.merged[id].target_height = new_height;
                    adjusted_heightmap[i] = new_height;
                    -- store for later use
                    detected.hills_markmap[i] = id;
                end

                -- is there a hole?
                local hole_id = detected.holes_markmap[i];
                if (hole_id and hole_id > 0) then
                    -- which hole are we dealing with?
                    local id = detected.holes_merge_into[hole_id];
                    local new_height = detected.holes.merged[id].target_height;
                    if (not (new_height)) then
                        -- target height: height if this hole would be filled completely
                        new_height = maxp.y + 1;
                    end
                    new_height = math.min(new_height, extrema.maxheight[i]);
                    -- is either the neighbour to the right or in the south a hill?
                    -- we have processed that place already; thus we can be sure
                    -- that this is an id that can be fed to detected.hills.merged
                    -- directly
                    local id_hill_right = detected.hills_markmap[i - chunksize];
                    if (id_hill_right and id_hill_right > 0) then
                        new_height = math.min(new_height, detected.hills.merged[id_hill_right].target_height);
                    end
                    local id_hill_prev = detected.hills_markmap[i - 1];
                    if (id_hill_prev and id_hill_prev > 0) then
                        new_height = math.min(new_height, detected.hills.merged[id_hill_prev].target_height);
                    end
                    detected.holes.merged[id].target_height = new_height;
                    adjusted_heightmap[i] = new_height;
                    -- store for later use
                    detected.holes_markmap[i] = id;
                end
            end
        end
    end
    return adjusted_heightmap;
end


--##Chatcommands functions.  Emerge functions.
minetest.register_chatcommand("emerge_area", {
    params = "x1 y1 z1 x2 y2 z2",
    description = "Generate map in a square box from pos1(x1,y1,z1) to pos2(x2,y2,z2)./nUsage:  /emerge_area x1 y1 z1 x2 y2 z2",
    func = function(name, params)
        --		local found, _, s_x1, s_y1, s_z1, s_x2, s_y2, s_z2 = params:find("^%s*(%d+)%s*(-?%d*)%s*$")
        local found, _, s_x1, s_y1, s_z1, s_x2, s_y2, s_z2 = params:find("^([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)[ ] *([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
        if found == nil then
            minetest.chat_send_player(name, "Usage: /mapgen x1 y1 z1 x2 y2 z2")
            return
        end

        local pos1 = { x = tonumber(s_x1), y = tonumber(s_y1), z = tonumber(s_z1) }
        local pos2 = { x = tonumber(s_x2), y = tonumber(s_y2), z = tonumber(s_z2) }

        local start_time = minetest.get_us_time()

        minetest.emerge_area(pos1, pos2, function(blockpos, action, remaining)
            local dt = math.floor((minetest.get_us_time() - start_time) / 1000)
            local block = (blockpos.x * 16) .. "," .. (blockpos.y * 16) .. "," .. (blockpos.z * 16)
            local info = "(mapgen-" .. remaining .. "-" .. dt .. "ms) "
            if action == core.EMERGE_GENERATED then
                minetest.chat_send_player(name, info .. "Generated new block at " .. block)
                --minetest.get_player_by_name(name):send_mapblock({x=(blockpos.x * 16),y=(blockpos.y * 16),z=(blockpos.z * 16)})
            elseif (action == core.EMERGE_CANCELLED) or (action == core.EMERGE_ERRORED) then
                minetest.chat_send_player(name, info .. "Block at " .. block .. " did not emerge")
            else
                --minetest.chat_send_player(name, "(mapgen-"..remaining.."-"..dt.."s) Visited block at "..(blockpos.x)..","..(blockpos.y)..","..(blockpos.z))
            end

            if remaining <= 0 then
                minetest.chat_send_player(name, "(mapgen-" .. dt .. "ms) Generation done.")
            end
        end
        )
    end
})

minetest.register_chatcommand("emerge_radius", {
    params = "radius [max_height]",
    description = "Generate map in a square box of size 2*radius centered at your current position.",
    func = function(name, params)
        local found, _, s_radius, s_height = params:find("^%s*(%d+)%s*(-?%d*)%s*$")
        if found == nil then
            minetest.chat_send_player(name, "Usage: /mapgen radius max_height")
            return
        end

        local player = minetest.get_player_by_name(name)
        local pos = player:getpos()

        local radius = tonumber(s_radius)
        local max_height = tonumber(s_height)

        if max_height == nil then
            max_height = pos.y + 1
        end

        if radius == 0 then
            radius = 1
        end

        local start_pos = {
            x = pos.x - radius,
            y = pos.y,
            z = pos.z - radius
        }

        local end_pos = {
            x = pos.x + radius,
            y = max_height,
            z = pos.z + radius
        }

        local start_time = minetest.get_us_time()

        minetest.emerge_area(start_pos, end_pos, function(blockpos, action, remaining)
            local dt = math.floor((minetest.get_us_time() - start_time) / 1000)
            local block = (blockpos.x * 16) .. "," .. (blockpos.y * 16) .. "," .. (blockpos.z * 16)
            local info = "(mapgen-" .. remaining .. "-" .. dt .. "ms) "
            if action == core.EMERGE_GENERATED then
                minetest.chat_send_player(name, info .. "Generated new block at " .. block)
            elseif (action == core.EMERGE_CANCELLED) or (action == core.EMERGE_ERRORED) then
                minetest.chat_send_player(name, info .. "Block at " .. block .. " did not emerge")
            else
                --minetest.chat_send_player(name, "(mapgen-"..remaining.."-"..dt.."s) Visited block at "..(blockpos.x)..","..(blockpos.y)..","..(blockpos.z))
            end

            if remaining <= 0 then
                minetest.chat_send_player(name, "(mapgen-" .. dt .. "ms) Generation done.")
            end
        end
        )
    end
})

local mapgen_times = {
    noisemaps = {},
    preparation = {},
    loop2d = {},
    loop3d = {},
    biomes = {},
    mainloop = {},
    setdata = {},
    liquid_lighting = {},
    writing = {},
    make_chunk = {},
}

local data = {}

minetest.register_on_generated(function(minp, maxp, seed)

    -- Start time of mapchunk generation.
    local t0 = os.clock()

    nobj_cave1 = nobj_cave1 or minetest.get_perlin_map(np_cave1, { x = maxp.x - minp.x + 1, y = maxp.x - minp.x + 1, z = maxp.x - minp.x + 1 })
    --nbuf_cave1 = nobj_cave1:get_3d_map_flat({x = minp.x, y = minp.y, z = minp.z})
    nbuf_cave1 = nobj_cave1:get_3d_map({ x = minp.x, y = minp.y, z = minp.z })
    nobj_cave2 = nobj_cave2 or minetest.get_perlin_map(np_cave2, { x = maxp.x - minp.x + 1, y = maxp.x - minp.x + 1, z = maxp.x - minp.x + 1 })
    --nbuf_cave2 = nobj_cave2:get_3d_map_flat({x = minp.x, y = minp.y, z = minp.z})
    nbuf_cave2 = nobj_cave2:get_3d_map({ x = minp.x, y = minp.y, z = minp.z })

    if mg_world_scale == 1 then
        nobj_3dterrain = nobj_3dterrain or minetest.get_perlin_map(np_3dterrain, { x = maxp.x - minp.x + 1, y = maxp.x - minp.x + 1, z = maxp.x - minp.x + 1 })
        nbuf_3dterrain = nobj_3dterrain:get_3d_map({ x = minp.x, y = minp.y, z = minp.z })
    end

    nobj_heatmap = nobj_heatmap or minetest.get_perlin_map(np_heat, { x = maxp.x - minp.x + 1, y = maxp.x - minp.x + 1, z = 0 })
    nbuf_heatmap = nobj_heatmap:get_2d_map({ x = minp.x, y = minp.z })

    nobj_heatblend = nobj_heatblend or minetest.get_perlin_map(np_heat_blend, { x = maxp.x - minp.x + 1, y = maxp.x - minp.x + 1, z = 0 })
    nbuf_heatblend = nobj_heatblend:get_2d_map({ x = minp.x, y = minp.z })

    nobj_humiditymap = nobj_humiditymap or minetest.get_perlin_map(np_humid, { x = maxp.x - minp.x + 1, y = maxp.x - minp.x + 1, z = 0 })
    nbuf_humiditymap = nobj_humiditymap:get_2d_map({ x = minp.x, y = minp.z })

    nobj_humidityblend = nobj_humidityblend or minetest.get_perlin_map(np_humid_blend, { x = maxp.x - minp.x + 1, y = maxp.x - minp.x + 1, z = 0 })
    nbuf_humidityblend = nobj_humidityblend:get_2d_map({ x = minp.x, y = minp.z })

    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    vm:get_data(data)
    local a = VoxelArea:new({ MinEdge = emin, MaxEdge = emax })
    local csize = vector.add(vector.subtract(maxp, minp), 1)

    local write = false

    --2D HEIGHTMAP GENERATION
    local mean_alt = 0
    local min_alt = -31000
    local max_alt = 31000

    local chunk_rand = math.random(5, 20)

    mg_earth.center_of_chunk = {
        x = (maxp.x - ((maxp.x - minp.x + 1) / 2)) + (10 - math.random(20)),
        y = (maxp.y - ((maxp.x - minp.x + 1) / 2)) + (10 - math.random(20)),
        z = (maxp.z - ((maxp.x - minp.x + 1) / 2)) + (10 - math.random(20)),
    }

    mg_earth.chunk_points = {
        { x = minp.x, y = minp.y, z = minp.z },
        { x = mg_earth.center_of_chunk.x, y = minp.y, z = minp.z },
        { x = maxp.x, y = minp.y, z = minp.z },
        { x = minp.x, y = minp.y, z = mg_earth.center_of_chunk.z },
        { x = mg_earth.center_of_chunk.x, y = minp.y, z = mg_earth.center_of_chunk.z },
        { x = maxp.x, y = minp.y, z = mg_earth.center_of_chunk.z },
        { x = minp.x, y = minp.y, z = maxp.z },
        { x = mg_earth.center_of_chunk.x, y = minp.y, z = maxp.z },
        { x = maxp.x, y = minp.y, z = maxp.z },
        { x = minp.x, y = mg_earth.center_of_chunk.y, z = minp.z },
        { x = mg_earth.center_of_chunk.x, y = mg_earth.center_of_chunk.y, z = minp.z },
        { x = maxp.x, y = mg_earth.center_of_chunk.y, z = minp.z },
        { x = minp.x, y = mg_earth.center_of_chunk.y, z = mg_earth.center_of_chunk.z },
        { x = mg_earth.center_of_chunk.x, y = mg_earth.center_of_chunk.y, z = mg_earth.center_of_chunk.z },
        { x = maxp.x, y = mg_earth.center_of_chunk.y, z = mg_earth.center_of_chunk.z },
        { x = minp.x, y = mg_earth.center_of_chunk.y, z = maxp.z },
        { x = mg_earth.center_of_chunk.x, y = mg_earth.center_of_chunk.y, z = maxp.z },
        { x = maxp.x, y = mg_earth.center_of_chunk.y, z = maxp.z },
        { x = minp.x, y = maxp.y, z = minp.z },
        { x = mg_earth.center_of_chunk.x, y = maxp.y, z = minp.z },
        { x = maxp.x, y = maxp.y, z = minp.z },
        { x = minp.x, y = maxp.y, z = mg_earth.center_of_chunk.z },
        { x = mg_earth.center_of_chunk.x, y = maxp.y, z = mg_earth.center_of_chunk.z },
        { x = maxp.x, y = maxp.y, z = mg_earth.center_of_chunk.z },
        { x = minp.x, y = maxp.y, z = maxp.z },
        { x = mg_earth.center_of_chunk.x, y = maxp.y, z = maxp.z },
        { x = maxp.x, y = maxp.y, z = maxp.z },
    }


    -- Mapgen preparation is now finished. Check the timer to know the elapsed time.
    local t1 = os.clock()

    if mg_heightmap_select == "v3D" or mg_noise_select == "v3D" then
        --if mg_heightmap_select == "v3D" then
        --local nixyz = 1
        --local index2d = 0
        local index2d = 1
        for z = minp.z, maxp.z do
            for y = minp.y, maxp.y do
                for x = minp.x, maxp.x do

                    --index2d = (z - minp.z) * csize.x + (x - minp.x) + 1

                    --local n_y = minetest.get_perlin(np_2d):get_2d({x=x,y=z})

                    local n_f = 0

                    if mg_world_scale == 1 then
                        --n_f = nbuf_3dterrain[z-minp.z+1][(n_y + y)-minp.y+1][x-minp.x+1]
                        --n_f = nbuf_3dterrain[z-minp.z+1][(n_y + y)-minp.y+1][x-minp.x+1]
                        n_f = nbuf_3dterrain[z - minp.z + 1][y - minp.y + 1][x - minp.x + 1]
                    else
                        --n_f = minetest.get_perlin(np_3dterrain):get_3d({x = x, y = (n_y + y), z = z})
                        n_f = minetest.get_perlin(np_3dterrain):get_3d({ x = x, y = y, z = z })
                    end

                    --local s_d = (1 - (n_y + y)) / (mg_density * mg_world_scale)
                    local s_d = (1 - y) / (mg_density * mg_world_scale)
                    local n_t = n_f + s_d

                    -- if get_3d_density(z,y,x) > 0 then
                    if n_t > 0 then
                        --mg_earth.heightmap[index2d] = (n_y + y)
                        mg_earth.heightmap[index2d] = y
                    end

                    --nixyz = nixyz + 1
                    index2d = index2d + 1

                end
                index2d = index2d - (maxp.x - minp.x + 1) --shift the 2D index back
            end
            index2d = index2d + (maxp.x - minp.x + 1) --shift the 2D index up a layer
        end
    end

    --local index2d = 0
    local index2d = 1

    for z = minp.z, maxp.z do
        --for y = minp.y, maxp.y do
        for x = minp.x, maxp.x do

            --index2d = (z - minp.z) * csize.x + (x - minp.x) + 1

            local nheat = get_heat_scalar(z) + nbuf_heatmap[z - minp.z + 1][x - minp.x + 1] + nbuf_heatblend[z - minp.z + 1][x - minp.x + 1]
            local nhumid = get_humid_scalar(z) + nbuf_humiditymap[z - minp.z + 1][x - minp.x + 1] + nbuf_humidityblend[z - minp.z + 1][x - minp.x + 1]

            local t_y, t_c = get_mg_heightmap({ x = x, y = 0, z = z }, nheat, nhumid, index2d)

            if mg_heightmap_select == "v3D" or mg_noise_select == "v3D" then
                --if mg_heightmap_select == "v3D" then
                t_y = mg_earth.heightmap[index2d]
                mg_earth.cliffmap[index2d] = t_c
            else
                --mg_earth.heightmap[index2d] = t_y or minetest.get_mapgen_object("heightmap")
                mg_earth.heightmap[index2d] = t_y
                mg_earth.cliffmap[index2d] = t_c
            end

            -- print("[mg_earth] Biome Name:  " .. nbiome_name .. "    Heat:" .. nbiome_data.heat .. "    Humidity:" .. nbiome_data.humidity .. "")
            if mg_earth.gal then
                --if mg_world_scale < 0.1 then
                mg_earth.biomemap[index2d] = get_gal_biome_name(nheat, nhumid, { x = x, y = t_y, z = z })
                --else
                --	mg_earth.biomemap[index2d] = calc_biome_from_noise(nheat,nhumid,{x=x,y=t_y,z=z})
                --end
            else
                local nbiome_data = minetest.get_biome_data({ x = x, y = t_y, z = z })
                -- local nbiome_id = nbiome_data.biome
                local nbiome_name = minetest.get_biome_name(nbiome_data.biome)
                mg_earth.biomemap[index2d] = nbiome_name
            end

            --mg_earth.cellmap[index2d] = p_idx

            mg_earth.eco_map[index2d] = get_dirt({ x = x, y = t_y, z = z })

            mg_earth.hh_mod[index2d] = min(0, (nheat - nhumid)) * mg_world_scale

            if z == minp.z then
                if x == minp.x then
                    mg_earth.chunk_terrain["SW"] = { x = minp.x, y = t_y, z = minp.z }
                elseif x == mg_earth.center_of_chunk.x then
                    mg_earth.chunk_terrain["W"] = { x = mg_earth.center_of_chunk.x, y = t_y, z = minp.z }
                elseif x == maxp.x then
                    mg_earth.chunk_terrain["NW"] = { x = maxp.x, y = t_y, z = minp.z }
                end
            elseif z == mg_earth.center_of_chunk.z then
                if x == minp.x then
                    mg_earth.chunk_terrain["S"] = { x = minp.x, y = t_y, z = mg_earth.center_of_chunk.z }
                elseif x == mg_earth.center_of_chunk.x then
                    mg_earth.chunk_terrain["C"] = { x = mg_earth.center_of_chunk.x, y = t_y, z = mg_earth.center_of_chunk.z }
                elseif x == maxp.x then
                    mg_earth.chunk_terrain["N"] = { x = maxp.x, y = t_y, z = mg_earth.center_of_chunk.z }
                end
            elseif z == maxp.z then
                if x == minp.x then
                    mg_earth.chunk_terrain["SE"] = { x = minp.x, y = t_y, z = maxp.z }
                elseif x == mg_earth.center_of_chunk.x then
                    mg_earth.chunk_terrain["E"] = { x = mg_earth.center_of_chunk.x, y = t_y, z = maxp.z }
                elseif x == maxp.x then
                    mg_earth.chunk_terrain["NE"] = { x = maxp.x, y = t_y, z = maxp.z }
                end
            end

            --## MEAN, MIN, MAX ALTITUDES
            mean_alt = mean_alt + t_y
            if min_alt == -31000 then
                min_alt = t_y
            else
                min_alt = min(t_y, min_alt)
            end
            if max_alt == 31000 then
                max_alt = t_y
            else
                max_alt = max(t_y, max_alt)
            end

            --## SPAWN SELECTION
            if z == mg_earth.player_spawn_point.z then
                if x == mg_earth.player_spawn_point.x then
                    mg_earth.player_spawn_point.y = t_y
                end
            end
            if z == mg_earth.origin_y_val.z then
                if x == mg_earth.origin_y_val.x then
                    mg_earth.origin_y_val.y = t_y
                end
            end

            index2d = index2d + 1

        end
        --end
    end

    mg_earth.chunk_mean_altitude = mean_alt / ((maxp.x - minp.x) * (maxp.z - minp.z))
    mg_earth.chunk_min_altitude = min_alt
    mg_earth.chunk_max_altitude = max_alt

    local t2 = os.clock()

    local detected
    if mg_lakes_enabled then
        -- do the actual work of hill and hole detection
        local tl1 = minetest.get_us_time();
        -- find places where the land could be lowered or raised
        local extrema = mark_min_max_height_in_mapchunk(minp, maxp, mg_earth.heightmap);
        -- distinguish between individual holes and hills
        detected = mark_holes_and_hills_in_mapchunk(minp, maxp, mg_earth.heightmap, extrema.minheight, extrema.maxheight);
        -- flatten hills, fill holes (just virutal in adjusted_heightmap)
        local adjusted_heightmap = heightmap_with_hills_lowered_and_holes_filled(minp, maxp, mg_earth.heightmap, extrema, detected);
        local tl2 = minetest.get_us_time();
        print("Time elapsed: " .. tostring(tl2 - tl1));

        -- for now: fill each hole (no matter how big or tiny) with river water
        for id, data in pairs(detected.holes.merged) do
            --detected.holes.merged[id].material = minetest.get_name_from_content_id(mg_earth.c_river);
            detected.holes.merged[id].material = mg_earth.c_river;
        end
    end

    local t3 = os.clock()
    print("Time elapsed: " .. tostring(t3 - t2));


    --local nixyz = 1
    --local index2d = 0
    local index2d = 1

    for z = minp.z, maxp.z do
        for y = minp.y, maxp.y do

            local tcave1
            local tcave2

            if y < yblmin then
                tcave1 = mg_cave_thresh1 + ((yblmin - y) / BLEND) ^ 2
                tcave2 = mg_cave_thresh2 + ((yblmin - y) / BLEND) ^ 2
            elseif y > yblmax then
                tcave1 = mg_cave_thresh1 + ((y - yblmax) / BLEND) ^ 2
                tcave2 = mg_cave_thresh2 + ((y - yblmax) / BLEND) ^ 2
            else
                tcave1 = mg_cave_thresh1
                tcave2 = mg_cave_thresh2
            end

            for x = minp.x, maxp.x do

                --index2d = (z - minp.z) * csize.x + (x - minp.x) + 1
                local ivm = a:index(x, y, z)

                local t_biome = mg_earth.biomemap[index2d]
                local t_eco = mg_earth.eco_map[index2d]

                local t_filldepth = 4
                local t_top_depth = 1
                local t_riverbed_depth = mg_river_size
                local t_stone_height = (mg_earth.heightmap[index2d] - (t_filldepth + t_top_depth))
                local t_fill_height = (mg_earth.heightmap[index2d] - t_top_depth)

                local t_ignore = mg_earth.c_ignore
                local t_air = mg_earth.c_air

                local t_node = t_ignore
                if data[ivm] == t_air then
                    t_node = t_air
                end

                local t_stone = mg_earth.c_stone
                local t_filler = mg_earth.c_dirt
                local t_top = mg_earth.c_dirtgrass
                local t_snow = mg_earth.c_dirtsnow
                local t_sand = mg_earth.c_sand
                local t_ice = mg_earth.c_ice
                local t_water = mg_earth.c_water
                local t_river = mg_earth.c_river
                local t_riverbed = mg_earth.c_dirt
                local t_mud = mg_earth.c_dirt

                t_stone = mg_earth.biome_info[t_biome].b_stone
                t_filler = mg_earth.biome_info[t_biome].b_filler
                t_top = mg_earth.biome_info[t_biome].b_top
                t_water = mg_earth.biome_info[t_biome].b_water
                t_river = mg_earth.biome_info[t_biome].b_river
                t_riverbed_depth = mg_earth.biome_info[t_biome].b_riverbed_depth

                if mg_ecosystems then
                    if (mg_earth.heightmap[index2d] > max_beach) and (mg_earth.heightmap[index2d] < max_highland) then
                        if (not string.find(t_biome, "ocean")) or (not string.find(t_biome, "beach")) or (not string.find(t_biome, "swamp"))
                                or (not string.find(t_biome, "mountain")) or (not string.find(t_biome, "strato")) then
                            if mg_earth.eco_map[index2d] ~= "n0" then
                                if (t_biome and (t_biome ~= "")) and (t_eco and (t_eco ~= "")) then
                                    if gal.ecosystems[t_biome] then
                                        local t_alt = get_biome_altitude(y)
                                        if gal.ecosystems[t_biome][t_alt .. "_" .. t_eco] then
                                            t_stone = gal.ecosystems[t_biome][t_alt .. "_" .. t_eco].stone
                                            t_filler = gal.ecosystems[t_biome][t_alt .. "_" .. t_eco].fill
                                            t_top = gal.ecosystems[t_biome][t_alt .. "_" .. t_eco].top
                                            t_water = mg_earth.biome_info[t_biome].b_water
                                            t_river = gal.ecosystems[t_biome][t_alt .. "_" .. t_eco].river
                                            t_riverbed_depth = mg_earth.biome_info[t_biome].b_riverbed_depth
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                if mg_earth.cliffmap[index2d] > 0 then
                    t_filler = t_stone
                end

                if mg_earth.heightmap[index2d] > (max_highland + mg_earth.hh_mod[index2d]) then
                    t_top = t_stone
                    t_filler = t_stone
                    t_water = t_water
                    t_river = t_ice
                end
                -- --if theight > ((max_mountain + h_mod) - (z / 100)) then
                if mg_earth.heightmap[index2d] > (max_mountain + mg_earth.hh_mod[index2d]) then
                    --if mg_earth.heightmap[index2d] > max_mountain then
                    t_top = t_stone
                    t_filler = t_stone
                    t_water = t_ice
                    t_river = t_ice
                end

                if mg_rivers_enabled then
                    if mg_heightmap_select == "vEarth" or mg_heightmap_select == "vVoronoi" or mg_heightmap_select == "vVoronoiPlus" then
                        local r_path = mg_earth.rivermap[index2d] + mg_earth.riverpath[index2d]
                        --local r_size = t_riverbed_depth * mg_river_size
                        local r_size = mg_river_size
                        if (r_path >= 0) and (r_path <= r_size) then
                            if y >= (mg_water_level - r_path) then
                                if y >= (t_stone_height + r_path) and y < t_fill_height then
                                    t_filler = t_river
                                else
                                    t_filler = t_riverbed
                                end
                                if y > mg_water_level then
                                    t_top = t_air
                                else
                                    t_top = t_river
                                end
                            end
                        end
                    elseif mg_heightmap_select == "vValleys" then
                        river_size_factor = (mg_river_size - (mg_earth.heightmap[index2d] / (40 * mg_world_scale))) / 100
                        if mg_earth.rivermap[index2d] <= river_size_factor then
                            if mg_earth.heightmap[index2d] >= (mg_water_level - 1) then
                                t_filldepth = t_riverbed_depth - (mg_earth.heightmap[index2d] / (75 * mg_world_scale))
                            end
                        end
                        if y >= t_stone_height and y < t_fill_height then
                            if mg_earth.rivermap[index2d] <= river_size_factor then
                                if y > (mg_water_level - 1) then
                                    if y >= (mg_earth.heightmap[index2d] - ((t_filldepth - (t_riverbed_depth * 0.5)) + t_top_depth)) and y < (mg_earth.heightmap[index2d] - t_top_depth) then
                                        t_filler = t_river
                                    else
                                        t_filler = t_riverbed
                                    end
                                    if mg_earth.rivermap[index2d] >= (river_size_factor * 0.7) then
                                        t_filler = t_mud
                                    end
                                end
                            end
                        elseif y >= t_fill_height and y <= mg_earth.heightmap[index2d] then
                            if mg_earth.rivermap[index2d] <= river_size_factor then
                                if y > mg_water_level then
                                    t_top = t_air
                                else
                                    t_top = t_water
                                end
                            end
                        end
                    end
                end

                if mg_lakes_enabled then
                    -- is there a hole?
                    if (detected.holes_markmap[index2d] and detected.holes_markmap[index2d] > 0) then
                        local id = detected.holes_merge_into[detected.holes_markmap[index2d]];
                        local hole = detected.holes.merged[id];
                        -- local biome_river_cid = mg_earth.biome_info[biomemap[index2d]].b_river or minetest.CONTENT_AIR
                        -- local hole_mat = minetest.get_name_from_content_id(biome_river_cid) or "air"
                        -- --minetest.set_node( {x=ax, z=az, y=hole.target_height}, {name=hole.material});
                        -- minetest.set_node( {x=ax, z=az, y=hole.target_height}, {name=hole_mat});
                        --local hole_mat = minetest.get_name_from_content_id(t_river)
                        --minetest.set_node( {x=x, z=z, y=hole.target_height}, {name = hole_mat});
                        -- if y >= mg_earth.heightmap[index2d] and y < hole.target_height then
                        -- t_node = t_river
                        -- end
                        --if y <= hole.target_height then
                        if mg_earth.heightmap[index2d] <= hole.target_height then
                            t_filler = t_riverbed
                            t_top = t_river
                        end
                    end
                end

                if y < t_stone_height then
                    t_node = t_stone
                elseif y >= t_stone_height and y < t_fill_height then
                    t_node = t_filler
                elseif y >= t_fill_height and y <= mg_earth.heightmap[index2d] then
                    t_node = t_top
                elseif y > mg_earth.heightmap[index2d] and y <= mg_water_level then
                    --Water Level (Sea Level)
                    t_node = t_water
                end

                if mg_caves_enabled then
                    if (mg_rivers_enabled and (mg_earth.valleymap[index2d] > 10)) or (mg_rivers_enabled == false) then
                        --if (y <= mg_earth.heightmap[index2d]) and (y >= (mg_water_level - 10)) then
                        if (y <= mg_earth.heightmap[index2d]) then

                            --local n_f1 = minetest.get_perlin(np_cave1):get_3d({x = x, y = y, z = z})
                            --local n_f1 = nbuf_cave1[nixyz]
                            local n_f1 = nbuf_cave1[z - minp.z + 1][y - minp.y + 1][x - minp.x + 1]
                            --local n_f2 = minetest.get_perlin(np_cave2):get_3d({x = x, y = y, z = z})
                            --local n_f2 = nbuf_cave2[nixyz]
                            local n_f2 = nbuf_cave2[z - minp.z + 1][y - minp.y + 1][x - minp.x + 1]
                            local s_d1 = (1 - y) / (mg_density * mg_world_scale)
                            local s_d2 = (1 - y) / (mg_density * mg_world_scale)

                            local n_t1 = n_f1 + s_d1
                            local n_t2 = n_f2 + s_d2

                            if (n_t1 > 0) and (n_t2 > 0) then
                                --if abs(n_t1 - n_t2) < 1 then
                                if y <= mg_water_level then
                                    t_node = t_water
                                else
                                    t_node = t_ignore
                                end
                                --end
                            end


                            --[[									-- local ncave1 = nbuf_cave1[nixyz]
										-- local ncave2 = nbuf_cave2[nixyz]

										-- if (ncave1 > tcave1) then
											-- if string.find(mg_earth.biomemap[index2d], "_humid") or string.find(mg_earth.biomemap[index2d], "_semihumid") then
												-- t_node = t_ignore
												-- -- if y <= mg_water_level then
													-- -- t_node = t_water
												-- -- else
													-- -- t_node = t_ignore
												-- -- end
											-- end
										-- end
										-- -- if (ncave2 < tcave2) then
											-- -- if string.find(mg_earth.biomemap[index2d], "_humid") or string.find(mg_earth.biomemap[index2d], "_semihumid") then
												-- -- t_node = t_ignore
											-- -- end
										-- -- end
										-- -- if (ncave1 < tcave1) and (ncave2 < tcave2) then
											-- -- if string.find(mg_earth.biomemap[index2d], "_temperate") then
												-- -- t_node = t_ignore
											-- -- end
										-- -- end
										-- -- if (ncave1 < tcave1) or (ncave2 < tcave2) then
											-- -- if string.find(mg_earth.biomemap[index2d], "_arid") or string.find(mg_earth.biomemap[index2d], "_semiarid") then
												-- -- t_node = t_ignore
											-- -- end
											-- -- -- if string.find(mg_earth.biomemap[index2d], "_coastal") or string.find(mg_earth.biomemap[index2d], "_beach") or string.find(mg_earth.biomemap[index2d], "_ocean") then
												-- -- -- if y <= mg_water_level then
													-- -- -- t_node = t_water
												-- -- -- end
											-- -- -- end
										-- -- end
--]]
                        end
                    end

                    --mg_cave_thresh1 = 1.00 - max(0,((mg_earth.heightmap[index2d] - y) * 0.01))
                    --mg_cave_thresh2 = 0.00 + min(2,((mg_earth.heightmap[index2d] - y) * 0.01))

                end

                if mg_heightmap_select == "vSpheres" or mg_heightmap_select == "vCubes" or mg_heightmap_select == "vDiamonds" then
                    -- if platform <= 25 then
                    -- -- if y <= 50 then
                    -- -- t_node = t_stone
                    -- -- end
                    -- if y == 50 then
                    -- t_node = t_top
                    -- elseif y < 50 and y >= 45 then
                    -- t_node = t_filler
                    -- elseif y < 45 and y >= 25 then
                    -- t_node = t_stone
                    -- end
                    -- -- elseif platform > 25 and platform <= 29 then
                    -- -- if y <= 50 then
                    -- -- t_node = t_filler
                    -- -- end
                    -- -- elseif platform == 30 then
                    -- -- if y <= 50 then
                    -- -- t_node = t_top
                    -- -- end
                    -- end

                    local platform = 0
                    if mg_heightmap_select == "vSpheres" then
                        --euclidean
                        --local platform = get_distance_3d_euclid({x=x,y=y,z=z},{x=center_of_chunk.x,y=center_of_chunk.y,z=center_of_chunk.z})
                        platform = (((x - mg_earth.center_of_chunk.x) * (x - mg_earth.center_of_chunk.x)) + ((y - mg_earth.center_of_chunk.y) * (y - mg_earth.center_of_chunk.y)) + ((z - mg_earth.center_of_chunk.z) * (z - mg_earth.center_of_chunk.z))) ^ 0.5
                    end

                    if mg_heightmap_select == "vDiamonds" then
                        --manhattan
                        platform = (abs(x - mg_earth.center_of_chunk.x) + abs(y - mg_earth.center_of_chunk.y) + abs(z - mg_earth.center_of_chunk.z))
                    end

                    if mg_heightmap_select == "vCubes" then
                        --chebyshev
                        local platform = (max(abs(x - mg_earth.center_of_chunk.x), max(abs(y - mg_earth.center_of_chunk.y), abs(z - mg_earth.center_of_chunk.z))))
                    end

                    if platform <= chunk_rand then
                        if y == (10 + chunk_rand) then
                            t_node = t_top
                        elseif y < (10 + chunk_rand) and y >= (5 + chunk_rand) then
                            t_node = t_filler
                        elseif y < (5 + chunk_rand) and y >= (-15 + chunk_rand) then
                            t_node = t_stone
                        end
                    else
                        t_node = t_air
                    end
                end

                --if mg_heightmap_select == "v3D" or mg_noise_select == "v3D" or mg_3d_terrain_enabled == true then
                if mg_heightmap_select == "v3D" or mg_noise_select == "v3D" then

                    local n_f = 0

                    if mg_world_scale == 1 then
                        if mg_noise_select == "v3D" then
                            n_f = minetest.get_perlin(np_3dterrain):get_3d({ x = x, y = mg_voronoimap[index2d], z = z })
                        else
                            n_f = nbuf_3dterrain[z - minp.z + 1][y - minp.y + 1][x - minp.x + 1]
                        end
                    else
                        if mg_noise_select == "v3D" then
                            n_f = minetest.get_perlin(np_3dterrain):get_3d({ x = x, y = mg_voronoimap[index2d], z = z })
                        else
                            n_f = minetest.get_perlin(np_3dterrain):get_3d({ x = x, y = y, z = z })
                        end
                    end

                    local s_d = 0

                    if mg_noise_select == "v3D" then
                        --s_d = (1 - (y + mg_voronoimap[index2d])) / (mg_density * mg_world_scale)
                        --  TRY BELOW
                        s_d = (1 - mg_voronoimap[index2d]) / (mg_density + mg_voronoimap[index2d] * mg_world_scale)
                    else
                        s_d = (1 - y) / (mg_density * mg_world_scale)
                    end

                    local n_t = n_f + s_d

                    if n_t <= 0 then
                        --if get_3d_density(z,y,x) <= 0 then
                        --if (mg_voronoimap[index2d] + y) <= mg_water_level then
                        if y <= mg_water_level then
                            t_node = t_water
                        else
                            t_node = t_ignore
                        end
                    end
                end

                data[ivm] = t_node

                --nixyz = nixyz + 1
                index2d = index2d + 1

                write = true

            end
            index2d = index2d - (maxp.x - minp.x + 1) --shift the 2D index back
        end
        index2d = index2d + (maxp.x - minp.x + 1) --shift the 2D index up a layer
    end

    local t4 = os.clock()

    if write then
        vm:set_data(data)
    end

    local t5 = os.clock()

    if write then

        --minetest.generate_ores(vm,minp,maxp)
        minetest.generate_decorations(vm, minp, maxp)

        vm:set_lighting({ day = 0, night = 0 })
        vm:calc_lighting()
        vm:update_liquids()
    end

    local t6 = os.clock()

    if write then
        vm:write_to_map()
    end

    local t7 = os.clock()

    -- Print generation time of this mapchunk.
    local chugent = math.ceil((os.clock() - t0) * 1000)
    --print(("[mg_earth] Generating from %s to %s"):format(minetest.pos_to_string(minp), minetest.pos_to_string(maxp)) .. "  :  " .. chugent .. " ms")
    print("[mg_earth] Mapchunk generation time " .. chugent .. " ms")

    table.insert(mapgen_times.noisemaps, 0)
    table.insert(mapgen_times.preparation, t1 - t0)
    table.insert(mapgen_times.loop3d, t2 - t1)
    table.insert(mapgen_times.loop2d, t3 - t2)
    table.insert(mapgen_times.mainloop, t4 - t3)
    table.insert(mapgen_times.setdata, t5 - t4)
    table.insert(mapgen_times.liquid_lighting, t6 - t5)
    table.insert(mapgen_times.writing, t7 - t6)
    table.insert(mapgen_times.make_chunk, t7 - t0)

    -- Deal with memory issues. This, of course, is supposed to be automatic.
    local mem = math.floor(collectgarbage("count") / 1024)
    if mem > 1000 then
        print("mg_earth is manually collecting garbage as memory use has exceeded 500K.")
        collectgarbage("collect")
    end
end)

local function mean(t)
    local sum = 0
    local count = 0

    for k, v in pairs(t) do
        if type(v) == 'number' then
            sum = sum + v
            count = count + 1
        end
    end

    return (sum / count)
end

minetest.register_on_shutdown(function()


    save_neighbors(n_file)

    if #mapgen_times.make_chunk == 0 then
        return
    end

    local average, standard_dev
    minetest.log("mg_earth lua Mapgen Times:")

    average = mean(mapgen_times.noisemaps)
    minetest.log("  noisemaps: - - - - - - - - - - - - - - -  " .. average)

    average = mean(mapgen_times.preparation)
    minetest.log("  preparation: - - - - - - - - - - - - - -  " .. average)

    average = mean(mapgen_times.loop2d)
    minetest.log(" 2D Noise loops: - - - - - - - - - - - - - - - - -  " .. average)

    average = mean(mapgen_times.loop3d)
    minetest.log(" 3D Noise loops: - - - - - - - - - - - - - - - - -  " .. average)

    average = mean(mapgen_times.mainloop)
    minetest.log(" Main Render loops: - - - - - - - - - - - - - - - - -  " .. average)

    average = mean(mapgen_times.setdata)
    minetest.log("  writing: - - - - - - - - - - - - - - - -  " .. average)

    average = mean(mapgen_times.liquid_lighting)
    minetest.log("  liquid_lighting: - - - - - - - - - - - -  " .. average)

    average = mean(mapgen_times.writing)
    minetest.log("  writing: - - - - - - - - - - - - - - - -  " .. average)

    average = mean(mapgen_times.make_chunk)
    minetest.log("  makeChunk: - - - - - - - - - - - - - - -  " .. average)

end)

minetest.register_on_mods_loaded(function()

    update_biomes()

end)

minetest.log("[MOD] mg_earth:  Successfully loaded.")




