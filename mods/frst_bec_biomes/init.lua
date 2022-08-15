frstBecBiomes = { storage = minetest.get_mod_storage(), path = minetest.get_modpath(minetest.get_current_modname()) }

dofile(frstBecBiomes.path .. "\\sampleGen.lua")

local conf = Settings(frstBecBiomes.path .. "/settings.conf")
local removeOtherBiomes = conf:get_bool("remove_other_biomes", false)

Debug.log("removeOtherBiomes: " .. tostring(removeOtherBiomes))

if (removeOtherBiomes) then
    Debug.log("Removing other biomes")
    minetest.clear_registered_biomes()
    minetest.clear_registered_decorations()
    minetest.clear_registered_ores()
end

local rootDataDirectory = frstBecBiomes.path .. "\\data\\"

local dataDirs = minetest.get_dir_list(rootDataDirectory, true)

for k, dataDirectory in pairs(dataDirs) do
    local dataDir = rootDataDirectory .. dataDirectory .. "\\"

    -- Load our data in each folder
    local files = minetest.get_dir_list(dataDir, false)
    for k, fileName in pairs(files) do
        local ext = string.sub(fileName, -5)
        if (ext == ".json") then
            Debug.log("Loading data " .. fileName)
            local f = io.open(dataDir .. fileName, "r")
            local content = f:read("*all")
            f:close()

            local dataTable = minetest.parse_json(content, {})

            if (dataTable.type == "biome") then
                Debug.log("Registering biome " .. dataTable.name)
                minetest.register_biome(dataTable)
            elseif (dataTable.type == "node") then
                minetest.register_node(dataTable.name, dataTable)
            else
                Debug.log("Unknown data type " .. tostring(dataTable.type) " for " .. tostring(dataDir .. fileName))
            end
        end
    end
end