local testBiomeTable = {
    type = "biome",
    name = "frst_bec_biomes:test_biome",
    node_top = "default:dirt_with_grass",
    depth_top = 1,
    node_filler = "default:dirt",
    depth_filler = 3,
    node_stone = "default:stone",
    node_water_top = "default:water_source",
    depth_water_top = 10,
    node_water = "default:water_source",
    node_riverbed = "default:water_source",
    depth_riverbed = 2,
    node_cave_liquid = "default:water_source",
    y_max = 31000,
    y_min = -31000,
    vertical_blend = 8,
    heat_point = 50,
    humidity_point = 50
}

local testNodeTable = {
    type = "node",
    name = "frst_bec_biomes:test_node",
    description = "Test Node",
    drawtype = "normal",
    tiles = {"default_dirt.png"},
    is_ground_content = true,
    groups = {crumbly = 3},
    drop = "default:dirt"
}

local biomeDataPath = frstBecBiomes.path .. "\\data\\biomes\\"
local nodeDataPath = frstBecBiomes.path .. "\\data\\nodes\\"

-- Write our sample json files to the mod's folder
local jsonText = minetest.write_json(testBiomeTable, true)
local f = io.open(biomeDataPath .. "testBiome.json", "wb")
local content = f:write(jsonText)
f:close()


local jsonText = minetest.write_json(testNodeTable, true)
local f = io.open(nodeDataPath .. "testNode.json", "wb")
local content = f:write(jsonText)
f:close()
