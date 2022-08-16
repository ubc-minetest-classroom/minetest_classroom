json_importer = { path = minetest.get_modpath(minetest.get_current_modname()) }

dofile(json_importer.path .. "\\sampleGen.lua")

local conf = Settings(json_importer.path .. "/settings.conf")
local removeOtherBiomes = conf:get_bool("remove_other_biomes", false)

Debug.log("removeOtherBiomes: " .. tostring(removeOtherBiomes))

if (removeOtherBiomes) then
    Debug.log("Removing other biomes")
    minetest.clear_registered_biomes()
    minetest.clear_registered_decorations()
    minetest.clear_registered_ores()
end

local function buildFilePath(rootDirectory)

    local directories = {}
    table.insert(directories, rootDirectory)

    local files = {}

    while (#directories > 0) do
        local currentDir = table.remove(directories, #directories)
        for _, directory in pairs(minetest.get_dir_list(currentDir, true)) do
            table.insert(directories, currentDir .. "\\" .. directory)
        end

        for _, file in pairs(minetest.get_dir_list(currentDir, false)) do
            table.insert(files, currentDir .. "\\" .. file)
        end
    end

    return files
end

local rootDataDirectory = json_importer.path .. "\\data\\"

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