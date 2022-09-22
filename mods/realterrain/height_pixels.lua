-- global variables
realterrain.raster_pos1 = nil
realterrain.raster_pos2 = nil
local xcenter = 0
local zcenter = 0

-- gets the closest number in threshholds table based on given num
local threshholds = realterrain.threshholds
function realterrain.closest(threshholds, num)
    local result = 0
    if num and tonumber(num) > 0 then
        local diff = nil
        local min_diff = 255
        local arr_cnt = 0
        for _ in pairs(threshholds) do arr_cnt = arr_cnt + 1 end
        for i = 1, arr_cnt do
            diff = math.abs(num - threshholds[i])
            if (diff < min_diff) then
              min_diff = diff;
              result = threshholds[i]
            end
        end
    end
    return result
end

--the raw get pixel method that uses the selected method and accounts for bit depth
function realterrain.get_raw_pixel(x,z,rastername) -- "rastername" is a string

    local raster
    if rastername == "dem" then
        raster = realterrain.dem
    elseif rastername == "chm" then
        raster = realterrain.chm
    elseif rastername == "urban" then
        raster = realterrain.urban
    elseif rastername == "cover" then
        raster = realterrain.cover
    end

    local colstart, rowstart = 0,0
    if raster.format == "bmp" then
        x=x+1
        z=z-1
        colstart = 1
        rowstart = -1
    end
    
    z = -z
    local r,g,b
    local width, length
    width = raster.width
    length = raster.length
    --check to see if the image is even on the raster, otherwise skip
    if width and length and ( x >= rowstart and x <= width ) and ( z >= colstart and z <= length ) then
        local bitmap = raster.image
        local c
        if bitmap.pixels[z] and bitmap.pixels[z][x] then
            c = bitmap.pixels[z][x]
            r = c.r
            g = c.g
            b = c.b
        end
            
        return r,g,b
    end
end

--main function that builds a heightmap
function realterrain.build_heightmap(x0, x1, z0, z1)
    local raster = realterrain.raster
    local heightmap = {}
    local xscale = realterrain.settings.xscale
    local zscale = realterrain.settings.zscale
    local xoffset = realterrain.settings.xoffset 
    local zoffset = realterrain.settings.zoffset 
    local yscale = realterrain.settings.yscale
    local yoffset = realterrain.settings.yoffset
    local center_map = realterrain.settings.centermap
    
    local function adjust(value, scale, offset, center)
        return math.floor((value/scale)+offset+center+0.5)
    end
    
    local xcenter = 0
    local zcenter = 0

    -- local rasternames = {}
    -- if realterrain.settings.fileelev ~= "" then table.insert(rasternames, "elev") end
    -- if realterrain.settings.filecover ~= "" then table.insert(rasternames, "cover")    end

    -- -- loop through rasters to check that they all have the same dimensions
    -- local x_raster_hsh = {}
    -- local x_raster_hsh_cnt = 0
    -- local z_raster_hsh = {}
    -- local z_raster_hsh_cnt = 0
    -- for _, rastername in ipairs(rasternames) do
    --     local raster = realterrain[rastername]
    --     if raster.width and raster.length then
    --         x_raster_hsh[raster.width] = true
    --         z_raster_hsh[raster.length] = true
            
    --         -- get centers if center_map is set to true
    --         if center_map then
    --             xcenter = (raster.width / 2)
    --             zcenter = -(raster.length / 2)
    --         end
    --     end
    -- end

    -- -- there should only be one width and one length in raster_hsh, if more than some raster dimensions are off
    -- for _ in pairs(x_raster_hsh) do x_raster_hsh_cnt = x_raster_hsh_cnt + 1 end
    -- if x_raster_hsh_cnt > 1 then
    --     error("the width (x axis) of some rasters do not match.")
    --     return heightmap
    -- end
    -- for _ in pairs(z_raster_hsh) do z_raster_hsh_cnt = z_raster_hsh_cnt + 1 end
    -- if z_raster_hsh_cnt > 1 then
    --     error("the height (z axis) of some rasters do not match.")
    --     return heightmap
    -- end
    
    -- set global raster x and z positions
    realterrain.raster_pos1 = { x=0-xcenter, y=0, z=0-zcenter}
    realterrain.raster_pos2 = { x=0+xcenter, y=255,z=0+zcenter}

    -- -- get adjusted x and z positions
    -- local adjusted_x0 = adjust(x0, xscale, xoffset, xcenter)
    -- local adjusted_x1 = adjust(x1, xscale, xoffset, xcenter)
    -- local adjusted_z0 = adjust(z0, zscale, zoffset, zcenter)
    -- local adjusted_z1 = adjust(z1, zscale, zoffset, zcenter)
    
    -- -- loop through rasters again to build heightmap
    -- for _, rastername in ipairs(rasternames) do
    --     local raster = realterrain[rastername]
        if raster.width and raster.length then
            --local colstart, colend, rowstart, rowend = adjusted_x0,adjusted_x1,adjusted_z0,adjusted_z1
            for x=x0,x1 do
                -- Check that the x coordinate is within local space
                if (x >= 0) then
                    if not heightmap[x] then heightmap[x] = {} end
                    for z=z0,z1 do
                        -- Check that the z coordinate is within local space
                        if (z >= 0) then
                            if not heightmap[x][z] then heightmap[x][z] = {} end
                            local value = realterrain.get_raw_pixel(x, z, realterrain.raster)
                            if value then
                                Debug.log("[height_pixels] bitmap value ["..tostring(z)..","..tostring(x).."] = "..tostring(value))
                                heightmap[x][z] = math.floor(value*yscale+yoffset+0.5)
                            end
                        end
                    end
                end
            end
        end
    -- end    --end for rasternames
    return heightmap
end