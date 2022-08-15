frstBecBiomes = { storage = minetest.get_mod_storage(), path = minetest.get_modpath(minetest.get_current_modname()) }

local conf = Settings(frstBecBiomes.path .. "/settings.conf")
local removeOtherBiomes = conf:get_bool("remove_other_biomes", false)

Debug.log("removeOtherBiomes: " .. tostring(removeOtherBiomes))

if (removeOtherBiomes) then
    Debug.log("Removing other biomes")
    minetest.clear_registered_biomes()
    minetest.clear_registered_decorations()
    minetest.clear_registered_ores()
end

local testBiomeTable = {
    name = "frst_bec_biomes:forest",
    node_dust = "default:snow",
    node_top = "default:dirt_with_snow",
    depth_top = 1,
    node_filler = "default:dirt",
    depth_filler = 3,
    node_stone = "default:stone",
    node_water_top = "default:dirt",
    depth_water_top = 10,
    node_water = "default:dirt",
    node_riverbed = "default:dirt",
    depth_riverbed = 2,
    node_cave_liquid = "default:dirt",
    y_max = 31000,
    y_min = -31000,
    vertical_blend = 8,
    heat_point = 50,
    humidity_point = 50
}

local jsonText = minetest.write_json(testBiomeTable, true)

--local f = io.open(frstBecBiomes.path .. "\\data\\" .. "test.json", "wb")
--local content = f:write(jsonText)
--f:close()

local files = minetest.get_dir_list(frstBecBiomes.path .. "\\data\\", false)
for k, fileName in pairs(files) do
    local f = io.open(fileName, "r")
    local content = f:read("*all")
    f:close()

    local biomeTable = minetest.parse_json(content, {})
    minetest.register_biome(biomeTable)
end


