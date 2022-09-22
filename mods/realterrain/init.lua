-- init.lua
--------------------------------------------------------
-- 1. define variables and init function
-- 2. load files and run
-- 3. set mapgen parameters and register generate function defined in mapgen.lua
-- 4. set player privilages and status
-- 5. register chat command to emerge blocks
-- 6. call init function

-- local variables
local worldpath = minetest.get_worldpath()
local modname = minetest.get_current_modname()
local MOD_PATH = minetest.get_modpath(modname)
local LIB_PATH = MOD_PATH .. "/lib/"
local RASTER_PATH = MOD_PATH .. "/rasters/"
local SCHEMS_PATH = MOD_PATH .. "/schems/" -- used in mapgen.lua
local IE = minetest.request_insecure_environment()
package.path = (MOD_PATH.."/lib/lua-imagesize-1.2/?.lua;"..package.path)
imagesize = IE.require "imagesize"
local raster_pos1, raster_pos2 = nil -- defines the size of the map to emerge
local context = {} -- persist emerge data between callback calls
local mapdone = false

-- global variables
realterrain = {}
realterrain.mod_path = MOD_PATH
realterrain.lib_path = LIB_PATH
realterrain.raster_path = RASTER_PATH
realterrain.schems_path = SCHEMS_PATH
realterrain.raster_pos1 = nil
realterrain.raster_pos2 = nil
realterrain.loadRealm = nil
realterrain.realmEmergeContinue = nil
realterrain.dem = {}
realterrain.chm = {}
realterrain.trees = {}
realterrain.urban = {}
realterrain.buildings = {}
realterrain.cover = {}

-- load files and run
dofile(MOD_PATH .. "/settings.lua")
dofile(LIB_PATH .. "/iohelpers.lua")
dofile(LIB_PATH .. "/imageloader.lua")
dofile(MOD_PATH .. "/height_pixels.lua")
dofile(MOD_PATH .. "/mapgen.lua")

function realterrain.init(DEM_PATH)

    if not DEM_PATH then
        minetest.chat_send_all("[realterrain] DEM_PATH is invalid or not registered. Cannot initialize realterrain.")
        return
    end

    -- Check for the digital elevation model (DEM), this is required
    local width, length, format = imagesize.imgsize(DEM_PATH..".bmp")
    if width and length and format then
        Debug.log("[realterrain] DEM file path is "..DEM_PATH..".bmp")
        Debug.log("[realterrain] DEM has image dimensions "..width.." by "..length)
        if string.sub(format, -3) == "bmp" or string.sub(format, -6) == "bitmap" then
            dofile(minetest.get_modpath("realterrain").."/lib/loader_bmp.lua")
            local bitmap, e = imageloader.load(DEM_PATH..".bmp")
            if e then Debug.log(e) end
            realterrain.dem.image = bitmap
            realterrain.dem.width = width
            realterrain.dem.length = length
            realterrain.dem.format = "bmp"
        else
            minetest.chat_send_all("[realterrain] Your file should be an uncompressed bmp. Cannot initialize realterrain.")
            return
        end
    end

    -- Check for additional files (these are optional and not registered)
    if realterrain.dem.image then
        local dem_ras = realterrain.build_image(DEM_PATH..".bmp")
        -- Check for canopy height model (CHM) image
        local chm_file = minetest.get_modpath("realterrain").."\\rasters\\chm\\"..realterrain.queued_key..".bmp"
        if realterrain.file_exists(chm_file) then
            Debug.log("[realterrain] CHM file path is "..chm_file)
            local width, length, format = imagesize.imgsize(chm_file)
            Debug.log("[realterrain] CHM has image dimensions "..width.." by "..length)
            if width and length and format then
                if string.sub(format, -3) == "bmp" or string.sub(format, -6) == "bitmap" then
                    local bitmap, e = imageloader.load(chm_file)
                    if e then Debug.log(e) end
                    realterrain.chm.image = bitmap
                    realterrain.chm.width = width
                    realterrain.chm.length = length
                    realterrain.chm.format = "bmp"

                    -- Derive max tree height locations from CHM
                    local chm_ras = realterrain.build_image(chm_file)
                    local max_ras = realterrain.maximum_image_filter(chm_file,7)
                    for x=1,width do
                        if not realterrain.trees[x] then realterrain.trees[x] = {} end
                        for z=1,length do
                            if not realterrain.trees[x][z] then realterrain.trees[x][z] = {} end
                            -- Looking for the locations in the CHM that match the maximum filter
                            -- Note that we only return locations where the maximum height is more than 4 nodes
                            if chm_ras[x][z] > 0 and chm_ras[x][z] == max_ras[x][z] and (chm_ras[x][z]-dem_ras[x][z] > 4) then
                                realterrain.trees[x][z] = max_ras[x][z]
                            else
                                realterrain.trees[x][z] = 0
                            end
                        end
                    end
                else
                    minetest.chat_send_all("[realterrain] Your CHM file should be an uncompressed bmp. Cannot initialize realterrain.")
                    return
                end
            end
        end

        -- Check for urban image representing building elevations
        local urban_file = minetest.get_modpath("realterrain").."\\rasters\\urban\\"..realterrain.queued_key..".bmp"
        if realterrain.file_exists(urban_file) then
            Debug.log("[realterrain] Urban file path is "..urban_file)
            local width, length, format = imagesize.imgsize(urban_file)
            Debug.log("[realterrain] Urban has image dimensions "..width.." by "..length)
            if width and length and format then
                if string.sub(format, -3) == "bmp" or string.sub(format, -6) == "bitmap" then
                    local bitmap, e = imageloader.load(urban_file)
                    if e then Debug.log(e) end
                    realterrain.urban.image = bitmap
                    realterrain.urban.width = width
                    realterrain.urban.length = length
                    realterrain.urban.format = "bmp"
                    
                    -- Derive buildings
                    local urban_ras = realterrain.build_image(urban_file)
                    for x=1,width do
                        if not realterrain.buildings[x] then realterrain.buildings[x] = {} end
                        for z=1,length do
                            if not realterrain.buildings[x][z] then realterrain.buildings[x][z] = {} end
                            realterrain.buildings[x][z] = urban_ras[x][z]
                        end
                    end
                else
                    minetest.chat_send_all("[realterrain] Your urban file should be an uncompressed bmp. Cannot initialize realterrain.")
                    return
                end
            end
        end

        -- Check for cover image representing cover types
        local cover_file = minetest.get_modpath("realterrain").."\\rasters\\cover\\"..realterrain.queued_key..".bmp"
        if realterrain.file_exists(cover_file) then
            Debug.log("[realterrain] Cover file path is "..cover_file)
            local width, length, format = imagesize.imgsize(cover_file)
            Debug.log("[realterrain] Cover has image dimensions "..width.." by "..length)
            if width and length and format then
                if string.sub(format, -3) == "bmp" or string.sub(format, -6) == "bitmap" then
                    local bitmap, e = imageloader.load(cover_file)
                    if e then Debug.log(e) end
                    realterrain.cover.image = bitmap
                    realterrain.cover.width = width
                    realterrain.cover.length = length
                    realterrain.cover.format = "bmp"
                else
                    minetest.chat_send_all("[realterrain] Your cover file should be an uncompressed bmp. Cannot initialize realterrain.")
                    return
                end
            end
        end
    end

end

---@public
---build_image
---@param raster_path path to 8-bit raster image bitmap (.bmp) on disk
---@return table of values of bitmap raster image indexed by [x][z]
function realterrain.build_image(raster_path)
    local width, length, format = imagesize.imgsize(raster_path)
    local bitmap, e = imageloader.load(raster_path)
    if e then Debug.log(e) end
    local c
    local r = {}       
    for x=1,width do
        if not r[x] then r[x] = {} end
        for z=-1,length do
            if bitmap.pixels[z] and bitmap.pixels[z][x] then
                if not r[x][z] then r[x][z] = {} end
                c = bitmap.pixels[z][x]
                r[x][z] = c.r, c.b, c.g
            end
        end
    end
    return r
end

---@public
---maximum_image_filter
---@param raster_path path to 8-bit raster image bitmap (.bmp) on disk
---@param filter_size odd-numbered integer representing the width of the kernel in both x and z directions
---@return table of [x,z] values representing the maximum height within the neighborhood specified by the filter_size
function realterrain.maximum_image_filter(raster_path,filter_size)
    if (filter_size % 2) == 0 then
        Debug.log("Error: Specified filter size must be odd-numbered.")
        return
    end

    -- Force filter size to integer
    local filter_size = math.floor(filter_size)

    -- Check what we are dealing with
    local width, length, format = imagesize.imgsize(raster_path)
    if width and length and format then
        if filter_size > width or filter_size > length then
            Debug.log("Error: Specified filter size must be smaller than the input raster.")
            return
        end
        if not string.sub(format, -3) == "bmp" or not string.sub(format, -6) == "bitmap" then
            Debug.log("Error: Raster file must be an 8-bit bitmap (.bmp).")
            return
        end

        local d = math.floor(filter_size/2)
        local w = filter_size-1
        local r = {}
        local r = realterrain.build_image(raster_path)

        -- Apply the maximum filter
        local max_ras = {}
        for x=1-d,width do -- Dilate the x coordinate space by the diameter of the kernel
            if not max_ras[x+d] then max_ras[x+d] = {} end
            for z=-1-d,length-2 do -- Dilate the z coordinate space by the diameter of the kernel
                if not max_ras[x+d][z+d] then max_ras[x+d][z+d] = {} end
                max_ras[x+d][z+d] = realterrain.kernel_max(x,z,w,r)
            end
        end
        return max_ras
    end    

end

---@public
---kernel_max
---@param x the smallest x coordinate representing the upper left position of the kernel
---@param z the smallest z coordinate representing the upper left position of the kernel
---@param w integer width of the kernel
---@param r table holding values of raster indexed by coordinates [x][z]
---@return table indexed by [x][z] with maximum kernel values
function realterrain.kernel_max(x,z,w,r)
    local m = nil
    for xx=x,x+w do
        for zz=z,z+w do
            local v = nil
            if r[xx] and r[xx][zz] then
                v = r[xx][zz]
                if not m then 
                    m = v 
                elseif v > m then 
                    m = v 
                end
            end
        end 
    end
    return m
end         

function realterrain.file_exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
 end


-- Set mapgen parameters
minetest.register_on_mapgen_init(function()
    minetest.set_mapgen_setting("water_level", realterrain.settings.waterlevel, true)
    minetest.set_mapgen_setting("mg_flags", realterrain.settings.mgflags, true)
    minetest.set_mapgen_setting("mg_name", realterrain.settings.mgname, true)
    minetest.set_mapgen_setting("mgflat_ground_level", realterrain.settings.yoffset, true)
    minetest.set_mapgen_setting("mgflat_spflags", realterrain.settings.mgflat_spflags, true)
    minetest.set_mapgen_setting("mgflat_large_cave_depth", realterrain.settings.mgflat_lcavedep, true)
    minetest.set_mapgen_setting("mgflat_cave_width", realterrain.settings.mgflat_cwidth, true)
    minetest.set_mapgen_setting_noiseparams("mg_biome_np_heat", realterrain.settings.mgbiome_heat, true)
end)

-- On generated function
minetest.register_on_generated(function(minp, maxp, seed)
    if realterrain.realmEmergeContinue then -- TODO: This is a temporary flag to stop realterrain generation
        realterrain.generate(minp, maxp)
    end
end)

-- registers a chat command to allow generation of the map without having to tediously walk every inch of it
-- modified from https://rubenwardy.com/minetest_modding_book/en/map/environment.html#loading-blocks
minetest.register_chatcommand("generate", {
    params = "",
    description = "generate the map",
    func = function ()

        local loadRealm = realterrain.loadRealm
        local pos1 = loadRealm.StartPos
        local pos2 = loadRealm.EndPos
        local function sec2clock(seconds)
            local seconds = tonumber(seconds)
            if seconds <= 0 then
                return "00:00:00";
            else
                hours = string.format("%02.f", math.floor(seconds/3600));
                mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
                secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
                return hours..":"..mins..":"..secs
            end
        end
        if pos1 and pos2 then
        
            local map_dimensions = 0
            local x_axis = math.abs(pos1.x) + math.abs(pos2.x)
            local z_axis = math.abs(pos1.z) + math.abs(pos2.z)
            map_dimensions1 = "Map dimensions:(" .. pos1.x .. ", " .. pos1.y .. ", " .. pos1.z .. ") to (" .. pos2.x .. ", " .. pos2.y .. ", " .. pos2.z .. ")"
            map_dimensions2 = "Map has a volume of " .. x_axis * pos2.y * z_axis .. " nodes (" .. x_axis .. "*" .. pos2.y .. "*" .. z_axis .. ")"

            minetest.emerge_area (pos1, pos2, function (pos, action, num_calls_remaining, context)
                -- On first call, record number of blocks
                if not context.total_blocks then
                    context.total_blocks  = num_calls_remaining + 1
                    context.loaded_blocks = 0
                    context.start_time = os.clock()
                end

                -- Increment number of blocks loaded
                context.loaded_blocks = context.loaded_blocks + 1

                -- Send progress message
                if context.total_blocks == context.loaded_blocks then
                    local elapsed_time = os.clock()-context.start_time
                    minetest.chat_send_all("Finished loading blocks! Time elapsed:" .. sec2clock(elapsed_time))
                    minetest.chat_send_all(map_dimensions1)
                    minetest.chat_send_all(map_dimensions2)
                    context = {}
                    mapdone = true
                else
                    local perc = 100 * context.loaded_blocks / context.total_blocks
                    local msg  = string.format("Loading blocks %d/%d (%.2f%%)", context.loaded_blocks, context.total_blocks, perc)
                    minetest.chat_send_all(msg)
                end
            end, context)
        end
    end
})

-- realterrain.init()