-- biomegen/init.lua

local make_biomelist = dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/biomelist.lua")
local make_decolist = dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/decorations.lua")

local np_filler_depth = {
    offset = 0,
    scale = 1.2,
    spread = { x = 150, y = 150, z = 150 },
    seed = 261,
    octaves = 3,
    persist = 0.7,
    lacunarity = 2.0,
}

local nobj_filler_depth, nobj_heat, nobj_heat_blend, nobj_humid, nobj_humid_blend
local nvals_filler_depth = {}
local nvals_heat = {}
local nvals_heat_blend = {}
local nvals_humid = {}
local nvals_humid_blend = {}

local elevation_chill = 0
local function set_elevation_chill(ec)
    elevation_chill = ec
end

local c_ignore
local c_air
local c_stone
local c_water
local c_rwater

local biomes, decos
local forcedBiome

local function initialize(chulens, seaLevel, seed, _forcedBiome)


    print("[biomegen] Initializing")

    local noiseparams = minetest.get_mapgen_setting_noiseparams

    local chulens2d = { x = chulens.x, y = chulens.z, z = 1 }

    local np_heat = noiseparams('mg_biome_np_heat')
    np_heat.seed = seed
    np_heat.offset = np_heat.offset + (seaLevel * elevation_chill)

    local np_humidity = noiseparams('mg_biome_np_humidity')
    np_humidity.seed = seed

    nobj_filler_depth = minetest.get_perlin_map(np_filler_depth, chulens2d)

    nobj_heat = minetest.get_perlin_map(np_heat, chulens2d)
    nobj_heat_blend = minetest.get_perlin_map(noiseparams('mg_biome_np_heat_blend'), chulens2d)

    nobj_humid = minetest.get_perlin_map(np_humidity, chulens2d)
    nobj_humid_blend = minetest.get_perlin_map(noiseparams('mg_biome_np_humidity_blend'), chulens2d)

    c_ignore = minetest.get_content_id("ignore")
    c_air = minetest.get_content_id("air")
    c_stone = minetest.get_content_id("mapgen_stone")
    c_water = minetest.get_content_id("mapgen_water_source")
    c_rwater = minetest.get_content_id("mapgen_river_water_source")

    biomes = make_biomelist()
    decos = make_decolist()

    if (biomes[_forcedBiome] ~= nil) then
        forcedBiome = _forcedBiome
    elseif (_forcedBiome ~= nil) then
        forcedBiome = nil
        Debug.log("[biomegen] Forced biome not found: " .. _forcedBiome)
    else
        forcedBiome = nil
    end
end

local biomemap = {}
local heatmap = {}
local humidmap = {}

local function calculate_noises(minp)
    local minp2d = { x = minp.x, y = minp.z }
    nobj_filler_depth:get_2d_map_flat(minp2d, nvals_filler_depth)

    nobj_heat:get_2d_map_flat(minp2d, nvals_heat)
    nobj_heat_blend:get_2d_map_flat(minp2d, nvals_heat_blend)

    nobj_humid:get_2d_map_flat(minp2d, nvals_humid)
    nobj_humid_blend:get_2d_map_flat(minp2d, nvals_humid_blend)

    for i, heat in ipairs(nvals_heat) do
        -- use nvals_heat to iterate, could have been another one
        heatmap[i] = heat + nvals_heat_blend[i]
        humidmap[i] = nvals_humid[i] + nvals_humid_blend[i]
    end
end

local function calc_biome_from_noise(heat, humid, pos, seaLevel)
    local biome_closest = nil
    local biome_closest_blend = nil
    local dist_min = 31000
    local dist_min_blend = 31000

    for i, biome in pairs(biomes) do
        local min_pos = { x = biome.min_pos.x, y = biome.min_pos.y + seaLevel, z = biome.min_pos.z }
        local max_pos = { x = biome.max_pos.x, y = biome.max_pos.y + seaLevel, z = biome.max_pos.z }
        if pos.y >= min_pos.y and pos.y <= max_pos.y + biome.vertical_blend
                and pos.x >= min_pos.x and pos.x <= max_pos.x
                and pos.z >= min_pos.z and pos.z <= max_pos.z then
            local d_heat = heat - biome.heat_point
            local d_humid = humid - biome.humidity_point
            local dist = d_heat * d_heat + d_humid * d_humid -- Pythagorean distance

            if pos.y <= max_pos.y then
                -- Within y limits of biome
                if dist < dist_min then
                    dist_min = dist
                    biome_closest = biome
                end
            elseif dist < dist_min_blend then
                -- Blend area above biome
                dist_min_blend = dist
                biome_closest_blend = biome
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
        return biome_closest_blend
    end

    return biome_closest
end

local function get_default_biome()
    local core_cid = minetest.get_content_id
    local function cid(name)
        if not name then
            return
        end
        local result
        pcall(function() --< try
            result = core_cid(name)
        end)
        if not result then
            print("[biomegen] Node " .. name .. " not found!")
        end
        return result
    end

    return {
        node_top = cid("mapgen_stone"),
        depth_top = 0,
        node_filler =  cid("mapgen_stone"),
        depth_filler = 0,
        node_stone = cid("mapgen_stone"),
        node_water_top = cid("mapgen_water_source"),
        depth_water_top = 0,
        node_water = cid("mapgen_water_source"),
        node_river_water = cid("mapgen_river_water_source"),
        node_riverbed = cid("mapgen_stone"),
        depth_riverbed = 0,
        min_pos = {x=-31000, y=-31000, z=-31000},
		max_pos = {x=31000, y=31000, z=31000},
		vertical_blend = 0,
		heat_point = 50,
		humidity_point = 50,
    }
end

local function get_biome_at_index(i, pos, seaLevel)

    if (forcedBiome and pos.y and seaLevel) then
        return biomes[forcedBiome]
    end

    local heat = heatmap[i] - (math.max(pos.y, seaLevel) * elevation_chill)
    local humid = humidmap[i] + (seaLevel - pos.y) * elevation_chill -- -30
    if (pos.y >= seaLevel + 30) then
        humid = humid + (pos.y - seaLevel - 15) * elevation_chill * 0.5
    end


    --(math.max(pos.y - seaLevel, seaLevel + 20 - pos.y) * elevation_chill * 0.5)

    return calc_biome_from_noise(heat, humid, pos, seaLevel) or get_default_biome()
end

local function generate_biomes(data, a, minp, maxp, seed, seaLevel, forcedBiomeName)

    local chulens = { x = maxp.x - minp.x + 1, y = maxp.y - minp.y + 1, z = maxp.z - minp.z + 1 }

    local index = 1

    initialize(chulens, seaLevel, seed, forcedBiomeName)

    calculate_noises(minp)

    for z = minp.z, maxp.z do
        for x = minp.x, maxp.x do
            local biome = nil
            local water_biome = nil
            local biome_stone = c_stone

            local depth_top = 0
            local base_filler = 0
            local depth_water_top = 0
            local depth_riverbed = 0

            local biome_y_min = minp.y
            local y_start = maxp.y
            local vi = a:index(x, maxp.y, z)
            local ystride = a.ystride

            local c_above = data[vi + ystride]
            if c_above == c_ignore then
                y_start = y_start - 1
                c_above = data[vi]
                vi = vi - ystride
            end
            local air_above = c_above == c_air
            local river_water_above = c_above == c_rwater
            local water_above = c_above == c_water or river_water_above

            biomemap[index] = nil

            local nplaced = (air_above or water_above) and 0 or 31000

            for y = y_start, minp.y - 1, -1 do
                local c = data[vi]
                local is_stone_surface = (c == c_stone) and
                        (air_above or water_above or not biome or y < biome_y_min)
                local is_water_surface = (c == c_water or c == c_rwater) and
                        (air_above or not biome or y < biome_y_min)

                if is_stone_surface or is_water_surface then


                    biome = get_biome_at_index(index, { x = x, y = y, z = z }, seaLevel)

                    biome_stone = biome.node_stone

                    if not biomemap[index] and is_stone_surface then
                        biomemap[index] = biome
                    end

                    if not water_biome and is_water_surface then
                        water_biome = biome
                    end

                    depth_top = biome.depth_top
                    base_filler = math.max(depth_top + biome.depth_filler + nvals_filler_depth[index], 0)
                    depth_water_top = biome.depth_water_top
                    depth_riverbed = biome.depth_riverbed
                    biome_y_min = biome.min_pos.y
                end

                if c == c_stone or c == biome_stone then
                    local c_below = data[vi - ystride]
                    if c_below == c_air or c_below == c_rwater or c_below == c_water then
                        nplaced = 31000
                    end
                    if river_water_above then
                        if nplaced < depth_riverbed then
                            data[vi] = biome.node_riverbed
                            nplaced = nplaced + 1
                        else
                            nplaced = 31000
                            river_water_above = false
                        end
                    elseif nplaced < depth_top then
                        data[vi] = biome.node_top
                        nplaced = nplaced + 1
                    elseif nplaced < base_filler then
                        data[vi] = biome.node_filler
                        nplaced = nplaced + 1
                    else
                        data[vi] = biome_stone
                        nplaced = 31000
                    end

                    air_above = false
                    water_above = false
                elseif c == c_water then
                    if y > seaLevel - depth_water_top then
                        data[vi] = biome.node_water_top
                    else
                        data[vi] = biome.node_water
                    end
                    nplaced = 0
                    air_above = false
                    water_above = true
                elseif c == c_rwater then
                    data[vi] = biome.node_river_water
                    nplaced = 0
                    air_above = false
                    water_above = true
                    river_water_above = true
                elseif c == c_air then
                    nplaced = 0
                    air_above = true
                    water_above = false
                else
                    nplaced = 31000
                    air_above = false
                    water_above = false
                end

                vi = vi - ystride
            end

            if not biomemap[index] then
                biomemap[index] = water_biome
            end

            index = index + 1
        end
    end
end

-- Walkable, liquid, and dustable: memoization tables for better performance
local walkable = setmetatable({}, {
    __index = function(t, c)
        local is_walkable = false
        local ndef = minetest.registered_nodes[minetest.get_name_from_content_id(c)]
        if ndef and ndef.walkable then
            is_walkable = true
        end

        t[c] = is_walkable
        return is_walkable
    end,
})

local liquid = setmetatable({}, {
    __index = function(t, c)
        local is_liquid = false
        local ndef = minetest.registered_nodes[minetest.get_name_from_content_id(c)]
        if ndef and ndef.liquidtype then
            is_liquid = ndef.liquidtype ~= "none"
        end

        t[c] = is_liquid
        return is_liquid
    end,
})

local function can_place_deco(deco, data, vi, pattern)
    if not deco.place_on[data[vi]] then
        return false
    elseif deco.num_spawn_by <= 0 then
        return true
    end

    local spawn_by = deco.spawn_by
    local nneighs = deco.num_spawn_by
    for i, incr in ipairs(pattern) do
        vi = vi + incr
        if spawn_by[data[vi]] then
            nneighs = nneighs - 1
            if nneighs < 1 then
                return true
            end
        end
    end

    return false
end

local function place_deco(deco, data, a, vm, minp, maxp, blockseed, realmOriginY, placementTable)
    local ps = PcgRandom(blockseed + 53)
    local carea_size = maxp.x - minp.x + 1

    local sidelen = deco.sidelen
    if carea_size % sidelen > 0 then
        sidelen = carea_size
    end
    local divlen = carea_size / sidelen - 1
    local area = sidelen * sidelen
    local ystride, zstride = a.ystride, a.zstride
    local pattern = { 1, zstride, -1, -1, -zstride, -zstride, 1, 1, ystride, zstride, zstride, -1, -1, -zstride, -zstride, 1 } -- Successive increments to iterate over 16 neighbouring nodes

    for z0 = 0, divlen do
        for x0 = 0, divlen do
            local p2d_center = { x = minp.x + sidelen * (x0 + 0.5), y = minp.z + sidelen * (z0 + 0.5) }
            local p2d_min = { x = minp.x + sidelen * x0, y = minp.z + sidelen * z0 }
            local p2d_max = { x = minp.x + sidelen * (x0 + 1) - 1, y = minp.z + sidelen * (z0 + 1) - 1 }

            local cover = false
            local nval = deco.use_noise and deco.noise:get_2d(p2d_center) or deco.fill_ratio
            local deco_count = 0

            if nval >= 10 then
                cover = true
                deco_count = area
            else
                local deco_count_f = area * nval
                if deco_count_f >= 1 then
                    deco_count = deco_count_f
                elseif deco_count_f > 0 and ps:next(1, 1000) <= deco_count_f * 1000 then
                    deco_count = 1
                end
            end

            local x = p2d_min.x - 1
            local z = p2d_min.y

            for i = 1, deco_count do
                if not cover then
                    x = ps:next(p2d_min.x, p2d_max.x)
                    z = ps:next(p2d_min.y, p2d_max.y)
                else
                    x = x + 1
                    if x == p2d_max.x + 1 then
                        z = z + 1
                        x = p2d_min.x
                    end
                end
                local mapindex = carea_size * (z - minp.z) + (x - minp.x)

                if deco.flags["all_floors"] == true and deco.flags["all_ceilings"] == true then
                    local biome_ok = true
                    if deco.use_biomes and #biomemap > 0 then
                        local biome_here = biomemap[mapindex]
                        if biome_here and not deco.biomes[biome_here.name] then
                            biome_ok = false
                        end
                    end

                    if biome_ok then
                        local size = (maxp.x - minp.x + 1) / 2
                        local floors = {}
                        local ceilings = {}

                        local is_walkable = false
                        local vi = a:index(x, maxp.y, z)
                        local walkable_above = walkable[data[vi]]
                        for y = maxp.y - 1, minp.y, -1 do
                            vi = vi - ystride
                            is_walkable = walkable[data[vi]]
                            if is_walkable and not walkable_above then
                                table.insert(floors, y)
                            elseif walkable_above and not walkable then
                                table.insert(ceilings, y)
                            end

                            walkable_above = is_walkable
                        end

                        if deco.flags["all_floors"] then
                            for _, y in ipairs(floors) do
                                if y >= biome.y_min and y <= biome.y_max then
                                    local pos = { x = x, y = y, z = z }
                                    if can_place_deco(deco, data, vi, pattern) then
                                        deco:generate(vm, ps, pos, false)
                                    end
                                end
                            end
                        end

                        if deco.flags["all_ceilings"] then
                            for _, y in ipairs(ceilings) do
                                if y >= biome.y_min and y <= biome.y_max then
                                    local pos = { x = x, y = y, z = z }
                                    if can_place_deco(deco, data, vi, pattern) then
                                        deco:generate(vm, ps, pos, true)
                                    end
                                end
                            end
                        end
                    end
                else
                    local y = -31000
                    if deco.flags["liquid_surface"] == true then
                        local vi = a:index(x, maxp.y, z)
                        for yi = maxp.y, minp.y, -1 do
                            local c = data[vi]
                            if walkable[c] then
                                break
                            elseif liquid[c] then
                                y = yi
                                break
                            end
                            vi = vi - ystride
                        end
                    else
                        local vi = a:index(x, maxp.y, z)
                        for yi = maxp.y, minp.y, -1 do
                            if walkable[data[vi]] then
                                y = yi
                                break
                            end
                            vi = vi - ystride
                        end
                    end

                    if y >= (deco.y_min + realmOriginY) and y <= (deco.y_max + realmOriginY) and y >= minp.y and y <= maxp.y then
                        local biome_ok = true
                        if deco.use_biomes and #biomemap > 0 then
                            local biome_here = biomemap[mapindex]
                            if biome_here and not deco.biomes[biome_here.name] then
                                biome_ok = false
                            end
                        end

                        local pos = { x = x, y = y, z = z }
                        if biome_ok and (ptable.get(placementTable, pos) == nil) then

                            if can_place_deco(deco, data, a:index(x, y, z), pattern) then
                                deco:generate(vm, ps, pos, false)
                                ptable.store(placementTable, pos, true)
                            end
                        end
                    end
                end
            end
        end
    end

    return 0
end

local function get_blockseed(p, seed)
    return seed + p.z * 38134234 + p.y * 42123 + p.x * 23
end

local function place_all_decos(data, a, vm, minp, maxp, seed, realmOriginY)
    local emin = vm:get_emerged_area()
    local blockseed = get_blockseed(emin, seed)

    local placementTable = {}

    local nplaced = 0

    for i, deco in pairs(decos) do
        nplaced = nplaced + place_deco(deco, data, a, vm, minp, maxp, blockseed, realmOriginY, placementTable)
    end

    return nplaced
end

local dustable = setmetatable({}, {
    __index = function(t, c)
        local is_dustable = false
        local ndef = minetest.registered_nodes[minetest.get_name_from_content_id(c)]
        if ndef and ndef.walkable then
            local dtype = ndef.drawtype
            if dtype and dtype == "normal" or dtype == "allfaces" or dtype == "allfaces_optional" or dtype == "glasslike" or dtype == "glasslike_framed" or dtype == "glasslike_framed_optional" then
                is_dustable = true
            end
        end

        t[c] = is_dustable
        return is_dustable
    end,
})

local function dust_top_nodes(data, a, vm, minp, maxp, seaLevel)
    if maxp.y < seaLevel then
        return
    end

    local full_maxp = a.MaxEdge

    local index = 1
    local ystride = a.ystride

    for z = minp.z, maxp.z do
        for x = minp.x, maxp.x do
            local biome = biomemap[index]

            if biome and biome.node_dust then
                local vi = a:index(x, full_maxp.y, z)
                local c_full_max = data[vi]
                local y_start

                if c_full_max == c_air then
                    y_start = full_maxp.y - 1
                elseif c_full_max == c_ignore then
                    vi = a:index(x, maxp.y, z)
                    local c_max = data[vi]

                    if c_max == c_air then
                        y_start = maxp.y
                    end
                end

                if y_start then
                    -- workaround for the 'continue' statement
                    vi = a:index(x, y_start, z)
                    local y = y_start
                    for y0 = y_start, minp.y - 1, -1 do
                        if data[vi] ~= c_air then
                            y = y0
                            break
                        end
                        vi = vi - ystride
                    end
                    local c = data[vi]
                    if dustable[c] and c ~= biome.node_dust then
                        local pos = { x = x, y = y + 1, z = z }
                        vm:set_node_at(pos, { name = biome.node_dust_name })
                    end
                end
            end
            index = index + 1
        end
    end
end

biomegen = {
    set_elevation_chill = set_elevation_chill,
    calculate_noises = calculate_noises,
    get_biome_at_index = get_biome_at_index,
    calc_biome_from_noise = calc_biome_from_noise,
    generate_biomes = generate_biomes,
    place_all_decos = place_all_decos,
    dust_top_nodes = dust_top_nodes,
}


function biomegen.generate_all(data, a, vm, minp, maxp, seed, seaLevel, forcedBiomeName)
    generate_biomes(data, a, minp, maxp, seed, seaLevel, forcedBiomeName)

    vm:set_data(data)
    place_all_decos(data, a, vm, minp, maxp, seed, minp.y)
    minetest.generate_ores(vm, minp, maxp)
    vm:get_data(data)
    dust_top_nodes(data, a, vm, minp, maxp, seaLevel)
end

function biomegen.get_biomes()
    return make_biomelist()
end
