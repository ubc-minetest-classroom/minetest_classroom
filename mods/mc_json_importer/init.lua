json_importer = { path = minetest.get_modpath(minetest.get_current_modname()) }

local conf = Settings(json_importer.path .. "/settings.conf")

if (conf:get_bool("remove_other_biomes", false)) then
    minetest.debug("Removing other biomes")
    minetest.clear_registered_biomes()
    minetest.clear_registered_decorations()
    minetest.clear_registered_ores()
end

if (conf:get_bool("generate_sample_files", false)) then
    minetest.debug("Generating sample files")
    dofile(json_importer.path .. "\\sampleGen.lua")
end

-- A table to act as an enum/switch for registering different types of data.
local dataTypes = {}
dataTypes["biome"] = function(dataTable)
    dataTable._jsonType = nil
    minetest.register_biome(dataTable)
end

dataTypes["node"] = function(dataTable)
    dataTable._jsonType = nil
    minetest.register_node(dataTable.name, dataTable)
end

dataTypes["craft_item"] = function(dataTable)
    minetest.register_craftitem(dataTable.name, dataTable)
end

dataTypes["tool"] = function(dataTable)
    minetest.register_tool(dataTable.name, dataTable)
end

dataTypes["craft_recipe"] = function(dataTable)
    minetest.register_craft(dataTable)
end

local function buildFilePath(rootDirectory, extension)
    if (extension == nil) then
        extension = ".json"
    end
    local directories = {}
    table.insert(directories, rootDirectory)

    local files = {}

    while (#directories > 0) do
        local currentDir = table.remove(directories, #directories)
        for _, directory in pairs(minetest.get_dir_list(currentDir, true)) do
            table.insert(directories, currentDir .. "\\" .. directory)
        end

        for _, fileName in pairs(minetest.get_dir_list(currentDir, false)) do
            local ext = string.sub(fileName, -#extension)
            if (ext == extension) then
                table.insert(files, currentDir .. "\\" .. fileName)
            end
        end

        return files
    end
end

local function loadFile(filePath)
    local f = io.open(filePath, "r")
    local content = f:read("*all")
    f:close()

    local dataTable = minetest.parse_json(content, {})

    if (dataTypes[string.lower(tostring(dataTable._jsonType))] ~= nil) then
        dataTypes[string.lower(tostring(dataTable._jsonType))](dataTable)
    else
        minetest.debug("Unknown data type " .. tostring(dataTable._jsonType) " for " .. tostring(filePath))
    end
end

local function loadDirectory(rootPath)
    local files = buildFilePath(rootPath, ".json")
    for k, file in ipairs(files) do
        loadFile(file, ".json")
    end
end

json_importer.loadDirectory = loadDirectory