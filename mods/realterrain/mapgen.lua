-- mapgen.lua
--------------------------------------------------------
-- 1. define variables & following functions:
-- 2. build_cids()
-- 3. build_biomes()
-- 4. build_shafts()
-- 5. get_shaft()
-- 6. get_tree()
-- 7. generate()

local SCHEMS_PATH       = realterrain.schems_path
local threshholds       = realterrain.threshholds

-- flags defined in settings
local alpine_level      = realterrain.settings.alpinelevel
local sub_alpine        = realterrain.settings.subalpine
local filler_depth      = realterrain.settings.fillerdepth
local water_level       = realterrain.settings.waterlevel
local kelp_min_depth    = realterrain.settings.kelpmindep
local wlily_max_depth   = realterrain.settings.wlilymaxdep
local wlily_prob        = realterrain.settings.wlilyprob
local bug_max_height    = realterrain.settings.bugmaxheight
local no_decoration     = realterrain.settings.nodecoration
local no_biomes         = realterrain.settings.nobiomes
local generate_ores     = realterrain.settings.generateores
-- local trees             = realterrain.trees

-- defaults for biome generation
local stone             = nil
local water             = nil
local air               = nil

-- tables
local surface_cache     = {} -- used to prevent reading of DEM for skyblocks
local cids_grass        = {} -- content ids for the 5 grass nodes
local cids_dry_grass    = {} -- content ids for the 5 grass nodes
local cids_fern         = {} -- content ids for the 3 grass nodes
local cids_marram_grass = {} -- content ids for the 3 grass nodes
local cids_bugs         = {} -- content ids for bugs
local cids_bugs_ct      = 0  -- table count for cids_bugs
local cids_mushrooms    = {} -- content ids for mushrooms
local cids_mushrooms_ct = 0  -- table count for cids_mushrooms
local cids_misc         = {} -- content ids for miscellaneous decorations
local cids_nodeco       = {} -- content ids for nodes that should have no decoraction above it
local biomes            = {} -- biome definitions defined in settings
local shafts            = {} -- defines all nodes for a given y coordinate
local treemap           = {} -- table of tree schems and their positions
local bugmap            = {} -- table of bug positions for adding timers
local fillmap           = {} -- table of x/z positions already occupied with some decoration

local function build_cids()
    -- default nodes
    stone = minetest.get_content_id("default:stone")
    water = minetest.get_content_id("default:water_source")
    air   = minetest.get_content_id("air")
    -- cids for grasses
    for i = 1, 5 do
        table.insert(cids_grass, minetest.get_content_id("default:grass_" .. i))
        table.insert(cids_dry_grass, minetest.get_content_id("default:dry_grass_" .. i))
    end
    for i = 1, 3 do
        table.insert(cids_fern, minetest.get_content_id("default:fern_" .. i))
        table.insert(cids_marram_grass, minetest.get_content_id("default:marram_grass_" .. i))
    end
    -- cids_bugs
    table.insert(cids_bugs, minetest.get_content_id("butterflies:butterfly_white"))
    --table.insert(cids_bugs, minetest.get_content_id("butterflies:butterfly_violet"))
    --table.insert(cids_bugs, minetest.get_content_id("butterflies:butterfly_red"))
    -- table.insert(cids_bugs, minetest.get_content_id("fireflies:firefly"))
    for _ in pairs(cids_bugs) do cids_bugs_ct = cids_bugs_ct + 1 end
    -- cids_mushrooms
    table.insert(cids_mushrooms, minetest.get_content_id("flowers:mushroom_brown"))
    table.insert(cids_mushrooms, minetest.get_content_id("flowers:mushroom_brown")) -- adding brown 2x to make it more common than red
    table.insert(cids_mushrooms, minetest.get_content_id("flowers:mushroom_red"))
    for _ in pairs(cids_mushrooms) do cids_mushrooms_ct = cids_mushrooms_ct + 1 end
    -- cids_miscellaneous
    cids_misc = {
        -- stone = minetest.get_content_id("default:stone"),
        -- water = minetest.get_content_id("default:water_source"),
        -- air = minetest.get_content_id("default:air"),
        waterlily = minetest.get_content_id("flowers:waterlily_waving"),
        sand_with_kelp = minetest.get_content_id("default:sand_with_kelp"),
        junglegrass = minetest.get_content_id("default:junglegrass"),
        dry_shrub = minetest.get_content_id("default:dry_shrub"),
        snowblock = minetest.get_content_id("default:snowblock"),
        snow = minetest.get_content_id("default:snow"),
    }
    -- cids_nodeco
    cids_nodeco[minetest.get_content_id("default:water_source")] = true
    cids_nodeco[minetest.get_content_id("default:stone")] = true
    cids_nodeco[minetest.get_content_id("default:desert_stone")] = true
    cids_nodeco[minetest.get_content_id("default:sandstone")] = true
    cids_nodeco[minetest.get_content_id("default:desert_sandstone")] = true
    cids_nodeco[minetest.get_content_id("default:silver_sandstone")] = true
end
local function build_biomes()

    local threshhold_cnt    = 0
    local ground_default    = "default:stone"
    local shrub_default     = nil
    local tree_default      = nil
    local function isempty(s)
        return s == nil or s == ''
    end
    for _ in pairs(threshholds) do threshhold_cnt = threshhold_cnt + 1 end
    for i = 1, threshhold_cnt do
        
        local threshhold      = threshholds[i]
        local prefixnum = i <= 10 and "0" .. i-1 or i-1
        local prefix = "b" .. prefixnum
        local ground1_setting = realterrain.settings[prefix.."ground1"]
        local ground2_setting = realterrain.settings[prefix.."ground2"]
        local gprob_setting   = realterrain.settings[prefix.."gprob"]
        local shrub1_setting  = realterrain.settings[prefix.."shrub1"]
        local sprob1_setting  = realterrain.settings[prefix.."sprob1"]
        local shrub2_setting  = realterrain.settings[prefix.."shrub2"]
        local sprob2_setting  = realterrain.settings[prefix.."sprob2"]
        local tree1_setting   = realterrain.settings[prefix.."tree1"]
        local tprob1_setting  = realterrain.settings[prefix.."tprob1"]
        local tree2_setting   = realterrain.settings[prefix.."tree2"]
        local tprob2_setting  = realterrain.settings[prefix.."tprob2"]
        
        local ground1 = (ground1_setting) and ground1_setting or ground_default
        local ground2 = (ground2_setting and gprob_setting > 0) and ground2_setting or ground1
        local shrub1  = (shrub1_setting and sprob1_setting > 0) and shrub1_setting or shrub_default
        local shrub2  = (shrub2_setting and sprob2_setting > 0) and shrub2_setting or shrub1
        local tree1  = (tree1_setting and tprob1_setting > 0) and tree1_setting or tree_default
        local tree2  = (tree2_setting and tprob2_setting > 0) and tree2_setting or tree1
        
        biomes[threshhold] = {
            
            ground1 = minetest.get_content_id(ground1),
            ground2 = minetest.get_content_id(ground2),
            gprob   = gprob_setting,
            shrub1  = shrub1 and minetest.get_content_id(shrub1) or nil,
            sprob1  = sprob1_setting,
            shrub2  = shrub2 and minetest.get_content_id(shrub2) or nil,
            sprob2  = sprob2_setting,
            tree1   = tree1,
            tprob1  = tprob1_setting,
            tree2   = tree2,
            tprob2  = tprob2_setting,
        }
    end
end
local function build_shafts()
    for _, shaft in ipairs(realterrain.shafts) do
        table.insert(shafts, {
            surface     = minetest.get_content_id(shaft[1]),
            filler      = minetest.get_content_id(shaft[2]),
            bedrock     = minetest.get_content_id(shaft[3]),
            shrub       = shaft[4],
            sprob       = tonumber(shaft[5]),
            bprob       = tonumber(shaft[6]),
            mprob       = tonumber(shaft[7]),
        })
    end
end
local function get_shaft(cover, elev)

    -- defines y shaft of bedrock, filler, surface, and decoration based on biome
    local bedrock       = stone
    local filler        = stone
    local surface       = stone
    local tree          = nil   -- 1 block above surface
    local shrub         = nil   -- 1 block above surface
    local waterlily     = nil   -- 1 block above lake water_level
    local bug           = nil   -- 2 or more blocks above the surface
    local bug_ht        = 2     -- minimum 2 blocks above the surface
    local param2        = 0
    
    -- internal variables
    local randnum       = math.random(1,5)
    local shaft         = nil
    local bprob         = 0 -- bug probability
    local mprob         = 0 -- mushroom probability
    local wdepth        = elev < water_level and water_level-elev or 0 -- water depth

    if not no_biomes and cover then
    
        -- get biome based on cover (0:lake, 16:beach, 256:ocean, 257:alpine, 258:subalpine)
        if elev > (alpine_level + randnum) then
            cover = (sub_alpine > 0 and elev < (alpine_level + sub_alpine + randnum)) and 258 or 257
        elseif cover > 0 and elev < water_level - kelp_min_depth then
            cover = 256 -- use ocean biome if no lake biome present and elev is less than kelp_min_depth
        elseif cover == 0 and elev >= water_level and elev <= water_level+1 then
            cover = 16 -- if lake biome falls at or over water_level use beach biome instead
        elseif cover == 16 and elev > water_level+1 then
            cover = 32 -- if beach has elevation 2 or more nodes higher than water_level then use grassland
        end
        
        local biome = biomes[cover]
        surface = (not no_decoration and biome.gprob >= math.random(1,100)) and biome.ground2 or biome.ground1

        if not no_decoration and not cids_nodeco[surface] then -- define decorations based on biome first
        
            -- check settings for tree schems first
            if biome.tree1 and (biome.tprob1 * 100) >= math.random(1,10000) then -- tprob1 can be x.x%
                if biome.tree2 and biome.tprob2 >= math.random(1,100) then -- tprob2 can be x%
                    tree = biome.tree2
                else
                    tree = biome.tree1
                end
            end
            -- check settings for shrubs if no tree and surface allows
            if not tree then
                if biome.shrub1 and (biome.sprob1 * 100) >= math.random(1,10000) then -- sprob1 can be x.x%
                    if biome.shrub2 and biome.sprob2 >= math.random(1,100) then -- sprob2 can be x%
                        shrub = biome.shrub2
                    else
                        shrub = biome.shrub1
                    end
                end
            end
            
            -- if no tree or shrub from biome, get from shaft
            if not tree and not shrub then
                for _, p in pairs(shafts) do
                    if p.surface == surface then
                        shaft = p
                        break
                    end
                end
                if shaft then
                    bedrock = shaft.bedrock
                    filler  = shaft.filler
                    -- if no decoration and surface allows, then use shrub/bug/mushroom defined in shaft
                    if not shrub then
                        if shaft.shrub and shaft.sprob >= math.random(1,100) then -- sprob can be x%
                            -- try for shrub defined in shaft first
                            if shaft.shrub == "grass" then
                                shrub = cids_grass[math.random(1, 5)]
                            elseif shaft.shrub == "dry_grass" then
                                shrub = cids_dry_grass[math.random(1, 5)]
                            elseif shaft.shrub == "fern" then
                                shrub = cids_fern[math.random(1, 3)]
                            elseif shaft.shrub == "marram_grass" then
                                shrub = cids_marram_grass[math.random(1, 3)]
                            else
                                shrub = cids_misc[shaft.shrub]
                            end
                        elseif shaft.mprob * 100 >= math.random(1,10000) then
                            -- try for mushroom second
                            shrub = cids_mushrooms[math.random(1, cids_mushrooms_ct)]
                        end
                        if shaft.bprob * 100 >= math.random(1,10000) then
                            -- if a bug shows up, determine how high it's flying
                            bug = cids_bugs[math.random(1, cids_bugs_ct)]
                            bug_ht = math.random(2, bug_max_height)
                        end
                    end
                end
            end
            
            if wdepth > 0 then
                -- get waterlily and param2 for kelp and waterlily
                if cover == 256 and surface == cids_misc["sand_with_kelp"] then
                    local kelp_max_length = wdepth - 2 -- two nodes below the water's surface
                    local kelp_min_length = kelp_max_length / 2 -- half of kelp_max_length
                    param2 = math.random(kelp_min_length, kelp_max_length) * 16 -- param2 for kelp length
                elseif cover == 0 and wdepth <= wlily_max_depth then
                    local calc_wlily_prob = wdepth < wlily_max_depth and ((wlily_max_depth - wdepth) / wlily_max_depth) * wlily_prob or 1 -- reduce probability the deeper you go
                    if calc_wlily_prob >= math.random(1,100) then
                        waterlily = cids_misc["waterlily"]
                        param2 = math.floor(math.random(0,3))
                    end
                end
            end
        
        end -- end not nodecoration
    end -- end not nobiomes
    
    return {
        bedrock     = bedrock,
        filler      = filler,
        surface     = surface,
        tree        = tree,
        shrub       = shrub,
        bug         = bug,
        bug_ht      = bug_ht,
        waterlily   = waterlily,
        param2      = param2
    }
end
local function get_tree(pos, name)
    -- checks the trees table for tree name and returns a tree object
    local properties = nil
    local order = 1 -- default order 1 is to be overwritten be all subsequent schems (use for wide trees with lots of foliage)
    local radius = 3 -- default to 7x?x7 for tree schems not in trees table (i.e. a specific tree shape like pine2)
    local tradius = 0
    local rotation = math.floor(math.random(0,3)) * 90
    for tname, tproperties in pairs(trees) do
        if name == tname then
            properties = tproperties
            break
        end
    end
    if properties then
        local schems = properties.schems
        if schems and schems > 1 then
            local rnumber = math.random(1, schems)
            if name == "bush" or name == "bbush" or name == "pbush" or name == "spbush" then
                order = 1
            else
                order = rnumber
            end
            name  = name .. rnumber
        end
        radius  = properties.radius
        tradius = properties.tradius
    end
    
    -- if trunk radius is greater than 0, add positions to fillmap to avoid having trunk overwritten by decoration
    if tradius > 0 then
        local pos1 = {x=pos.x-tradius, y=pos.y, z=pos.z-tradius}
        local pos2 = {x=pos.x+tradius, y=pos.y+bug_max_height, z=pos.z+tradius}
        table.insert(fillmap, {pos1=pos1,pos2=pos2} )
    end
    
    return {order = order, pos = pos, name = name, radius = radius, rotation = rotation}
end

function realterrain.generate(minp, maxp)
    -- Get the realm
    local loadRealm = realterrain.loadRealm

    -------------------------------------
    -- this section creates the heightmap
    -------------------------------------
    local t0 = os.clock()

    local c_stone = minetest.get_content_id("default:stone")
    local c_dirt = minetest.get_content_id("default:dirt")
    local c_dirt_with_grass = minetest.get_content_id("default:dirt_with_grass")
    local c_dirt_with_coniferous_litter = minetest.get_content_id("default:dirt_with_coniferous_litter")
    local c_pine_tree_needles = minetest.get_content_id("default:pine_needles")
    local c_pine_tree = minetest.get_content_id("default:pine_tree")
    local c_water_source = minetest.get_content_id("default:water_source")
    local c_sand = minetest.get_content_id("default:sand")
    local c_stonebrick = minetest.get_content_id("default:stonebrick")
    local c_gravel = minetest.get_content_id("default:gravel")
    local c_surface = c_dirt_with_grass -- Surface content
    local filler_depth = 5 -- Nodes below the surface to fill with the filler, after which becomes bedrock
    local sea_level = 0 -- Nodes above realm.StartPos.y to fill with water
    local sand_level = 0 -- Nodes above sea_level to use sand as surface
    local leaf_litter_below_canopy = true -- Boolean to replace c_surface_content with leaf litter under CHM (requires CHM)

    -- Check if the chunk is within the realm
    if (maxp.x < loadRealm.StartPos.x) and (maxp.z < loadRealm.StartPos.z) and (minp.x > loadRealm.EndPos.x) and (minp.z > loadRealm.EndPos.z) then
        -- Chunk is not in the realm, skip
        return 
    end

    -- Chunk is in the realm, continue processing
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new { MinEdge = emin, MaxEdge = emax }
    local data = vm:get_data()

    for z = minp.z, maxp.z do
        for y = minp.y, maxp.y do
            for x = minp.x, maxp.x do
                local vi = area:index(x, y, z)
                local xx = math.floor(x-loadRealm.StartPos.x+0.5)
                local nrow = loadRealm.EndPos.z-loadRealm.StartPos.z
                local zz = math.floor(z-loadRealm.StartPos.z+0.5)
                zz = nrow - zz -- We need to make this correction so that the map is oriented correctly
                local dem_elev = realterrain.get_raw_pixel(xx, -zz, "dem")
                local chm_elev = realterrain.get_raw_pixel(xx, -zz, "chm")
                local urban_elev = realterrain.get_raw_pixel(xx, -zz, "urban")
                local cover = realterrain.get_raw_pixel(xx, -zz, "cover")
                -- Confirm we are on the [x,z] plane of the DEM
                if dem_elev then
                    -- Add the elevation to the realm coordinate space
                    dem_elev = dem_elev + loadRealm.StartPos.y
                    -- Check that the y of the chunk is within the realm
                    if (y > loadRealm.StartPos.y) and (y < loadRealm.EndPos.y) then
                        -- At or below sea_level
                        if y <= loadRealm.StartPos.y+sea_level then
                            -- Submerged land (sand)
                            if y <= dem_elev then
                                data[vi] = c_sand
                            -- Just water
                            else
                                data[vi] = c_water_source
                            end
                        -- Sandy areas near sea_level
                        elseif (y <= loadRealm.StartPos.y+sea_level+sand_level) and (y <= dem_elev) then
                            data[vi] = c_sand
                        -- Filler below surface
                        elseif (y < dem_elev) and (y >= dem_elev-filler_depth) then
                            data[vi] = c_dirt
                        -- Bedrock below filler
                        elseif (y < dem_elev-filler_depth) then
                            data[vi] = c_stone
                        -- Surface
                        elseif y == dem_elev then
                            if leaf_litter_below_canopy and (chm_elev > 0) then
                                data[vi] = c_dirt_with_coniferous_litter
                            elseif cover > 0 then
                                -- TODO: create a lookup table for the cover codes
                                data[vi] = c_gravel
                            else
                                data[vi] = c_surface
                            end
                        -- Buildings
                        elseif urban_elev then
                            if (y > dem_elev) and (y <= urban_elev) and (urban_elev > 0) then
                                data[vi] = c_stonebrick
                            end
                        end
                    end

                    -- Check if the height value is valid (i.e., vegetation is present)
                    if chm_elev then
                        -- Add the height to the realm coordinate space
                        chm_elev = chm_elev + loadRealm.StartPos.y
                        -- Here we dilate the CHM vertically (chm_elev-2) to fill some gaps and make the visualization more realistic
                        if (y > loadRealm.StartPos.y) and (y >= chm_elev-2) and (y <= chm_elev) then
                            data[vi] = c_pine_tree_needles
                        end
                    end

                    -- Get any tree locations
                    if realterrain.trees[xx+1] and realterrain.trees[xx+1][zz+1] then
                        local tree_elev = realterrain.trees[xx+1][zz+1]
                        -- Debug.log("tree_elev = "..tostring(tree_elev))
                        if tree_elev > 0 then
                            tree_elev = tree_elev + loadRealm.StartPos.y
                            if (y < tree_elev-1) and (y > dem_elev) then
                                data[vi] = c_pine_tree
                            end
                        end
                    end
                    dem_elev = nil
                    chm_elev = nil
                    tree_elev = nil
                    urban_elev = nil
                end
            end
        end
    end

    vm:set_data(data)    
    vm:write_to_map(true)
end