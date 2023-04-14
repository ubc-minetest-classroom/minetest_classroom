-- This global table keeps track of realterrain files exposed to the realm system

realterrainManager = {}
realterrainManager.dems = {}
realterrainManager.biomes = {}

---@public
---Registers a Digital Elevation Model (DEM) (and optional, but highly recommended, config file).
---Both should share the same file name (minus extension) under the same directory.
---DEMs should have extension "*.bmp"; Config file should have extension "*.conf"
---@param key string the key to associate with the DEM path.
---@param rootPath string the path to a DEM and config file.
function realterrainManager.registerDEM(key, rootPath)
    key = string.lower(key)

    -- Sanity checking our DEM registration to ensure we don't enter an invalid state.
    if (key == nil) then
        minetest.log("warning", "tried registering a DEM with nil key:" .. key " for path " .. rootPath .. " in the realms  realterrain manager.")
        return false
    end

    if (rootPath == nil) then
        minetest.log("warning", "tried registering a DEM with nil path for key: " .. key)
        return false
    end

    if (mc_core.fileExists(rootPath .. ".conf") == false) then
        minetest.log("warning", "trying to register DEM " .. rootPath .. "without a config file. Default config values will be used.")
    end

    realterrainManager.dems[key] = rootPath
end

---@public
---Function used to retrieve a DEM and its config file from a key previously registered.
---@return string path to the DEM; or nil if the key is invalid.
---@return table DEM configuration containing Author, Name, spawnPoint, and size; or nil if the key is invalid.
function realterrainManager.getDEM(key)
    key = string.lower(key)

    local DEM_PATH = realterrainManager.dems[key]

    if (DEM_PATH == nil) then
        return nil, nil
    end

    local settings = Settings(DEM_PATH .. ".conf")

    local _author = tostring(settings:get("author"))
    local _name = tostring(settings:get("name"))
    local _format = tostring(settings:get("format"))

    if (_author == nil or _author == "") then
        _author = "unknown"
    end

    if (_name == nil or _name == "") then
        _name = "unknown"
    end

    if (_format == nil or _format == "") then
        _format = "old"
    end

    -- Get information about the DEM
    local DEM_size_x, DEM_size_z, _ = imagesize.imgsize(DEM_PATH..".bmp")
    local DEM_size_x = tonumber(DEM_size_x)
    local DEM_size_z = tonumber(DEM_size_z)
    -- TODO: find the max height value in the DEM for properly sizing the realm
    -- local vals = {"max" = 0}
    -- for x = 0, DEM_size_x do
    --     for z = 0, DEM_size_z do
    --         local value = realterrain.get_raw_pixel(adjusted_x, adjusted_z, "elev")
    --         local value = math.floor(value+0.5)
    --         local temp = vals["max"]
    --         local vals["max"] = math.max(temp,value)
    --     end
    -- end
    --local DEM_size_y = vals[1] + 80 -- Add a vertical buffer for flying and decorations
    local DEM_size_y = 300
    
    local spawn_pos_x = tonumber(settings:get("spawn_pos_x")) or 0
    local spawn_pos_y = tonumber(settings:get("spawn_pos_y")) or 2
    local spawn_pos_z = tonumber(settings:get("spawn_pos_z")) or 0

    local DEM_table_name = settings:get("DEM_table_name") or nil
    local teleport_function_in_name = settings:get("teleport_in_function_name") or nil
    local teleport_function_out_name = settings:get("teleport_out_function_name") or nil
    local realm_create_function_name = settings:get("realm_create_function_name") or nil
    local realm_delete_function_name = settings:get("realm_delete_function_name") or nil

    local offset_x = tonumber(settings:get("offset_x")) or 0
    local offset_y = tonumber(settings:get("offset_y")) or 0
    local offset_z = tonumber(settings:get("offset_z")) or 0

    -- TODO: eventually read this information directly from geoTiff
    local utm_zone = tonumber(settings:get("utm_zone") or 1)
    local utm_hemisphere = settings:get("utm_hemisphere") or "N"
    local utm_origin_easting = tonumber(settings:get("utm_origin_easting")) or 0
    local utm_origin_northing = tonumber(settings:get("utm_origin_northing")) or 0
    local elevation_offset = tonumber(settings:get("elevation_offset")) or 0

    local _miscData = {}

    local settingNames = settings:get_names()
    for k, v in pairs(settingNames) do
        if (mc_core.starts(string.lower(tostring(v)), "d_")) then
            _miscData[string.gsub(v, "d_", "", 1)] = settings:get(v)
        end
    end

    local _spawnPoint = { x = spawn_pos_x, y = spawn_pos_y, z = spawn_pos_z }
    local _DEMSize = { x = DEM_size_x, y = DEM_size_y, z = DEM_size_z }
    local _startOffset = { x = offset_x, y = offset_y, z = offset_z }
    local _utmInfo = { zone = utm_zone, utm_is_north = (utm_hemisphere == "n" or utm_hemisphere == "N"), easting = utm_origin_easting, northing = utm_origin_northing }

    local config = { author = _author, name = _name, format = _format, spawnPoint = _spawnPoint, DEMSize = _DEMSize,
                     tableName = DEM_table_name, onTeleportInFunction = teleport_function_in_name, onTeleportOutFunction = teleport_function_out_name,
                     onDEMPlaceFunction = realm_create_function_name, onRealmDeleteFunction = realm_delete_function_name, utmInfo = _utmInfo, miscData = _miscData, startOffset = _startOffset }

    config.elevationOffset = elevation_offset

    return DEM_PATH, config
end

local files = minetest.get_dir_list(minetest.get_modpath("realterrain") .. "\\rasters\\dem\\", false)
for _, fileName in pairs(files) do
    local filePath = minetest.get_modpath("realterrain") .. "\\rasters\\dem\\" .. fileName
    local ext = string.sub(filePath, -5)
    if (ext == ".conf") then
        local path = string.sub(filePath, 1, -6)
        local key = string.sub(fileName, 1, -6)
        realterrainManager.registerDEM(key, path)
    end
end