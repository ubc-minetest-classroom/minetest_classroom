function openstreetmap.latLonToUTM(lat, lon, zone)
    local equatorialRadius = 6378137.0
    local flatteningCoeff = 0.00335281066474748 -- 1/298.257223563
    local centralMeridian = -183 + 6 * zone

    local eccSquared = 2 * flatteningCoeff - flatteningCoeff^2
    local eccPrimeSquared = eccSquared / (1 - eccSquared)
    
    local N = equatorialRadius / math.sqrt(1 - eccSquared * math.sin(math.rad(lat))^2)
    local T = math.tan(math.rad(lat))^2
    local C = eccPrimeSquared * math.cos(math.rad(lat))^2
    local A = math.cos(math.rad(lat)) * (math.rad(lon) - math.rad(centralMeridian))
    
    local M = equatorialRadius * ((1 - eccSquared / 4 - 3 * eccSquared^2 / 64 - 5 * eccSquared^3 / 256) * math.rad(lat) - (3 * eccSquared / 8 + 3 * eccSquared^2 / 32 + 45 * eccSquared^3 / 1024) * math.sin(2 * math.rad(lat)) + (15 * eccSquared^2 / 256 + 45 * eccSquared^3 / 1024) * math.sin(4 * math.rad(lat)) - (35 * eccSquared^3 / 3072) * math.sin(6 * math.rad(lat)))

    local easting = 0.9996 * N * (A + (1 - T + C) * A^3 / 6 + (5 - 18 * T + T^2 + 72 * C - 58 * eccPrimeSquared) * A^5 / 120) + 500000.0
    local northing = 0.9996 * (M + N * math.tan(math.rad(lat)) * (A^2 / 2 + (5 - T + 9 * C + 4 * C^2) * A^4 / 24 + (61 - 58 * T + T^2 + 600 * C - 330 * eccPrimeSquared) * A^6 / 720))

    local easting = math.floor(easting)
    local northing = math.floor(northing)
    local isnorth
    if lat >= 0 then isnorth = true else isnorth = false end

    return easting, northing, isnorth
end

function openstreetmap.computeUTMZone(longitude)
    return math.floor((longitude + 180) / 6) + 1
end

-- Bresenham's 3D line algorithm
function openstreetmap.draw_line_between_nodes(start_pos, end_pos, MTnodeID, id, ftype, OSMnodes, enclosed, tags, extrusion_value, chunks)

    -- Minimum data needed to place a way
    if not start_pos or not end_pos or not MTnodeID or not id or not ftype or not OSMnodes then
        return false
    end

    local dx = math.abs(end_pos.x - start_pos.x)
    local dy = math.abs(end_pos.y - start_pos.y)
    local dz = math.abs(end_pos.z - start_pos.z)
    
    local sx = start_pos.x < end_pos.x and 1 or -1
    local sy = start_pos.y < end_pos.y and 1 or -1
    local sz = start_pos.z < end_pos.z and 1 or -1
    
    local err1, err2

    local positions_on_line_segment = {}

    if dx > dy and dx > dz then  -- x dominant
        err1 = dy - dx
        err2 = dz - dx
        while start_pos.x ~= end_pos.x do

            if extrusion_value and tonumber(extrusion_value) > 0 then 
                -- With extrusion, we need to consider that the extruded feature might span several chunks
                for dd = 1, extrusion_value, 1 do
                    -- Determine the chunk that the OSM node position is in
                    local chunk = openstreetmap.findChunkForPosition({x = start_pos.x, y = start_pos.y + dd, z = start_pos.z}, chunks)
                    if chunk then
                        -- We are going to use chunk.pos1 as a key to quickly access the associated OSM node data
                        local chunk_pos1_str = minetest.pos_to_string(chunk.pos1)

                        -- Get the unique positions along the line segment, if enclosed, to allow filling
                        if enclosed then 
                            if not openstreetmap.way_positions[id] then openstreetmap.way_positions[id] = {} end
                            table.insert(openstreetmap.way_positions[id],{x = start_pos.x, y = start_pos.y + dd, z = start_pos.z}) 
                        end

                        posKey = {x = start_pos.x, y = start_pos.y + dd, z = start_pos.z}
                        posStr = minetest.pos_to_string(posKey)
                        -- Avoid replacing any existing node content on the way
                        if not openstreetmap.staged_osm_nodes[chunk_pos1_str][posStr] then
                            if not openstreetmap.staged_osm_ways[chunk_pos1_str] then
                                openstreetmap.staged_osm_ways[chunk_pos1_str] = {}
                            end
                            openstreetmap.staged_osm_ways[chunk_pos1_str][posStr] = {
                                MTnodeID = MTnodeID,
                                WayID = id,
                                WayType = ftype,
                                WayNodes = OSMnodes,
                                WayEnclosed = enclosed,
                                WayTags = tags
                            }
                        end
                    end
                end
            else
                -- These ways are at ground level
                -- Determine the chunk that the OSM node position is in
                local chunk = openstreetmap.findChunkForPosition({x = start_pos.x, y = start_pos.y, z = start_pos.z}, chunks)
                if chunk then
                    -- We are going to use chunk.pos1 as a key to quickly access the associated OSM node data
                    local chunk_pos1_str = minetest.pos_to_string(chunk.pos1)

                    -- Get the unique positions along the line segment, if enclosed, to allow filling
                    if enclosed then 
                        if not openstreetmap.way_positions[id] then openstreetmap.way_positions[id] = {} end
                        table.insert(openstreetmap.way_positions[id],{x = start_pos.x, y = start_pos.y, z = start_pos.z}) 
                    end

                    posKey = {x = start_pos.x, y = start_pos.y, z = start_pos.z}
                    posStr = minetest.pos_to_string(posKey)
                    -- Avoid replacing any existing node content on the way
                    if not openstreetmap.staged_osm_nodes[chunk_pos1_str][posStr] then
                        if not openstreetmap.staged_osm_ways[chunk_pos1_str] then
                            openstreetmap.staged_osm_ways[chunk_pos1_str] = {}
                        end
                        openstreetmap.staged_osm_ways[chunk_pos1_str][posStr] = {
                            MTnodeID = MTnodeID,
                            WayID = id,
                            WayType = ftype,
                            WayNodes = OSMnodes,
                            WayEnclosed = enclosed,
                            WayTags = tags
                        }
                    end
                end
            end

            if err1 > 0 then
                start_pos.y = start_pos.y + sy
                err1 = err1 - dx
            end
            if err2 > 0 then
                start_pos.z = start_pos.z + sz
                err2 = err2 - dx
            end
            start_pos.x = start_pos.x + sx
            err1 = err1 + dy
            err2 = err2 + dz
        end
    elseif dy > dx and dy > dz then  -- y dominant
        err1 = dx - dy
        err2 = dz - dy
        while start_pos.y ~= end_pos.y do
            if extrusion_value and tonumber(extrusion_value) > 0 then 
                -- With extrusion, we need to consider that the extruded feature might span several chunks
                for dd = 1, extrusion_value, 1 do
                    -- Determine the chunk that the OSM node position is in
                    local chunk = openstreetmap.findChunkForPosition({x = start_pos.x, y = start_pos.y + dd, z = start_pos.z}, chunks)
                    if chunk then
                        -- We are going to use chunk.pos1 as a key to quickly access the associated OSM node data
                        local chunk_pos1_str = minetest.pos_to_string(chunk.pos1)

                        -- Get the unique positions along the line segment, if enclosed, to allow filling
                        if enclosed then 
                            if not openstreetmap.way_positions[id] then openstreetmap.way_positions[id] = {} end
                            table.insert(openstreetmap.way_positions[id],{x = start_pos.x, y = start_pos.y + dd, z = start_pos.z}) 
                        end

                        posKey = {x = start_pos.x, y = start_pos.y + dd, z = start_pos.z}
                        posStr = minetest.pos_to_string(posKey)
                        -- Avoid replacing any existing node content on the way
                        if not openstreetmap.staged_osm_nodes[chunk_pos1_str][posStr] then
                            if not openstreetmap.staged_osm_ways[chunk_pos1_str] then
                                openstreetmap.staged_osm_ways[chunk_pos1_str] = {}
                            end
                            openstreetmap.staged_osm_ways[chunk_pos1_str][posStr] = {
                                MTnodeID = MTnodeID,
                                WayID = id,
                                WayType = ftype,
                                WayNodes = OSMnodes,
                                WayEnclosed = enclosed,
                                WayTags = tags
                            }
                        end
                    end
                end
            else
                -- These ways are at ground level
                -- Determine the chunk that the OSM node position is in
                local chunk = openstreetmap.findChunkForPosition({x = start_pos.x, y = start_pos.y, z = start_pos.z}, chunks)
                if chunk then
                    -- We are going to use chunk.pos1 as a key to quickly access the associated OSM node data
                    local chunk_pos1_str = minetest.pos_to_string(chunk.pos1)

                    -- Get the unique positions along the line segment, if enclosed, to allow filling
                    if enclosed then 
                        if not openstreetmap.way_positions[id] then openstreetmap.way_positions[id] = {} end
                        table.insert(openstreetmap.way_positions[id],{x = start_pos.x, y = start_pos.y, z = start_pos.z}) 
                    end

                    posKey = {x = start_pos.x, y = start_pos.y, z = start_pos.z}
                    posStr = minetest.pos_to_string(posKey)
                    -- Avoid replacing any existing node content on the way
                    if not openstreetmap.staged_osm_nodes[chunk_pos1_str][posStr] then
                        if not openstreetmap.staged_osm_ways[chunk_pos1_str] then
                            openstreetmap.staged_osm_ways[chunk_pos1_str] = {}
                        end
                        openstreetmap.staged_osm_ways[chunk_pos1_str][posStr] = {
                            MTnodeID = MTnodeID,
                            WayID = id,
                            WayType = ftype,
                            WayNodes = OSMnodes,
                            WayEnclosed = enclosed,
                            WayTags = tags
                        }
                    end
                end
            end
            
            if err1 > 0 then
                start_pos.x = start_pos.x + sx
                err1 = err1 - dy
            end
            if err2 > 0 then
                start_pos.z = start_pos.z + sz
                err2 = err2 - dy
            end
            start_pos.y = start_pos.y + sy
            err1 = err1 + dx
            err2 = err2 + dz
        end
    else  -- z dominant
        err1 = dy - dz
        err2 = dx - dz
        while start_pos.z ~= end_pos.z do
            if extrusion_value and tonumber(extrusion_value) > 0 then 
                -- With extrusion, we need to consider that the extruded feature might span several chunks
                for dd = 1, extrusion_value, 1 do
                    -- Determine the chunk that the OSM node position is in
                    local chunk = openstreetmap.findChunkForPosition({x = start_pos.x, y = start_pos.y + dd, z = start_pos.z}, chunks)
                    if chunk then
                        -- We are going to use chunk.pos1 as a key to quickly access the associated OSM node data
                        local chunk_pos1_str = minetest.pos_to_string(chunk.pos1)

                        -- Get the unique positions along the line segment, if enclosed, to allow filling
                        if enclosed then 
                            if not openstreetmap.way_positions[id] then openstreetmap.way_positions[id] = {} end
                            table.insert(openstreetmap.way_positions[id],{x = start_pos.x, y = start_pos.y + dd, z = start_pos.z}) 
                        end

                        posKey = {x = start_pos.x, y = start_pos.y + dd, z = start_pos.z}
                        posStr = minetest.pos_to_string(posKey)
                       -- Avoid replacing any existing node content on the way
                       if not openstreetmap.staged_osm_nodes[chunk_pos1_str][posStr] then
                            if not openstreetmap.staged_osm_ways[chunk_pos1_str] then
                                openstreetmap.staged_osm_ways[chunk_pos1_str] = {}
                            end
                            openstreetmap.staged_osm_ways[chunk_pos1_str][posStr] = {
                                MTnodeID = MTnodeID,
                                WayID = id,
                                WayType = ftype,
                                WayNodes = OSMnodes,
                                WayEnclosed = enclosed,
                                WayTags = tags
                            }
                        end
                    end
                end
            else
                -- These ways are at ground level
                -- Determine the chunk that the OSM node position is in
                local chunk = openstreetmap.findChunkForPosition({x = start_pos.x, y = start_pos.y, z = start_pos.z}, chunks)
                if chunk then
                    -- We are going to use chunk.pos1 as a key to quickly access the associated OSM node data
                    local chunk_pos1_str = minetest.pos_to_string(chunk.pos1)

                    -- Get the unique positions along the line segment, if enclosed, to allow filling
                    if enclosed then 
                        if not openstreetmap.way_positions[id] then openstreetmap.way_positions[id] = {} end
                        table.insert(openstreetmap.way_positions[id],{x = start_pos.x, y = start_pos.y, z = start_pos.z}) 
                    end

                    posKey = {x = start_pos.x, y = start_pos.y, z = start_pos.z}
                    posStr = minetest.pos_to_string(posKey)
                    -- Avoid replacing any existing node content on the way
                    if not openstreetmap.staged_osm_nodes[chunk_pos1_str][posStr] then
                        if not openstreetmap.staged_osm_ways[chunk_pos1_str] then
                            openstreetmap.staged_osm_ways[chunk_pos1_str] = {}
                        end
                        openstreetmap.staged_osm_ways[chunk_pos1_str][posStr] = {
                            MTnodeID = MTnodeID,
                            WayID = id,
                            WayType = ftype,
                            WayNodes = OSMnodes,
                            WayEnclosed = enclosed,
                            WayTags = tags
                        }
                    end
                end
            end

            if err1 > 0 then
                start_pos.y = start_pos.y + sy
                err1 = err1 - dz
            end
            if err2 > 0 then
                start_pos.x = start_pos.x + sx
                err2 = err2 - dz
            end
            start_pos.z = start_pos.z + sz
            err1 = err1 + dy
            err2 = err2 + dx
        end
    end

    if extrusion_value and tonumber(extrusion_value) > 0 then 
        -- With extrusion, we need to consider that the extruded feature might span several chunks
        for dd = 1, extrusion_value, 1 do
            -- Determine the chunk that the OSM node position is in
            local chunk = openstreetmap.findChunkForPosition({x = end_pos.x, y = end_pos.y + dd, z = end_pos.z}, chunks)
            if chunk then
                -- We are going to use chunk.pos1 as a key to quickly access the associated OSM node data
                local chunk_pos1_str = minetest.pos_to_string(chunk.pos1)

                -- Get the unique positions along the line segment, if enclosed, to allow filling
                if enclosed then 
                    if not openstreetmap.way_positions[id] then openstreetmap.way_positions[id] = {} end
                    table.insert(openstreetmap.way_positions[id],{x = end_pos.x, y = end_pos.y + dd, z = end_pos.z}) 
                end

                posKey = {x = end_pos.x, y = end_pos.y + dd, z = end_pos.z}
                posStr = minetest.pos_to_string(posKey)
                -- Avoid replacing any existing node content on the way
                if not openstreetmap.staged_osm_nodes[chunk_pos1_str][posStr] then
                    if not openstreetmap.staged_osm_ways[chunk_pos1_str] then
                        openstreetmap.staged_osm_ways[chunk_pos1_str] = {}
                    end
                    openstreetmap.staged_osm_ways[chunk_pos1_str][posStr] = {
                        MTnodeID = MTnodeID,
                        WayID = id,
                        WayType = ftype,
                        WayNodes = OSMnodes,
                        WayEnclosed = enclosed,
                        WayTags = tags
                    }
                end
            end
        end
    else
        -- These ways are at ground level
        -- Determine the chunk that the OSM node position is in
        local chunk = openstreetmap.findChunkForPosition({x = end_pos.x, y = end_pos.y, z = end_pos.z}, chunks)
        if chunk then
            -- We are going to use chunk.pos1 as a key to quickly access the associated OSM node data
            local chunk_pos1_str = minetest.pos_to_string(chunk.pos1)

            -- Get the unique positions along the line segment, if enclosed, to allow filling
            if enclosed then 
                if not openstreetmap.way_positions[id] then openstreetmap.way_positions[id] = {} end
                table.insert(openstreetmap.way_positions[id],{x = end_pos.x, y = end_pos.y, z = end_pos.z}) 
            end

            posKey = {x = end_pos.x, y = end_pos.y, z = end_pos.z}
            posStr = minetest.pos_to_string(posKey)
            -- Avoid replacing any existing node content on the way
            if not openstreetmap.staged_osm_nodes[chunk_pos1_str][posStr] then
                if not openstreetmap.staged_osm_ways[chunk_pos1_str] then
                    openstreetmap.staged_osm_ways[chunk_pos1_str] = {}
                end
                openstreetmap.staged_osm_ways[chunk_pos1_str][posStr] = {
                    MTnodeID = MTnodeID,
                    WayID = id,
                    WayType = ftype,
                    WayNodes = OSMnodes,
                    WayEnclosed = enclosed,
                    WayTags = tags
                }
            end
        end
    end
end

function openstreetmap.fillEnclosedWays(chunks)
    for wayID, positions in pairs(openstreetmap.way_positions) do
        local minX, minY, minZ, maxX, maxY, maxZ = math.huge, math.huge, math.huge, -math.huge, -math.huge, -math.huge

        -- Find the bounding box of the enclosed area
        for _, pos in pairs(positions) do
            minX = math.min(minX, pos.x)
            minZ = math.min(minZ, pos.z)
            minY = math.min(minY, pos.y)
            maxX = math.max(maxX, pos.x)
            maxY = math.max(maxY, pos.y)
            maxZ = math.max(maxZ, pos.z)
        end

        -- Iterate through integer coordinates within the bounding box
        for x = math.floor(minX), math.ceil(maxX) do
            for z = math.floor(minZ), math.ceil(maxZ) do
                local posKey = {x = x, y = maxY, z = z}

                -- Check if the position is inside the enclosed area
                if openstreetmap.isPositionInsideEnclosure(posKey, positions) then
                    local posStr = minetest.pos_to_string(posKey)
                    local chunk = openstreetmap.findChunkForPosition(posKey, chunks)
                    if chunk then
                        local chunk_pos1_str = minetest.pos_to_string(chunk.pos1)
                        -- Avoid replacing any existing node or way content within the enclosure
                        if not openstreetmap.staged_osm_nodes[chunk_pos1_str][posStr] and not openstreetmap.staged_osm_ways[chunk_pos1_str][posStr] then
                            -- Get the way_info
                            local way_info = openstreetmap.temp.indexedWayData[wayID]
                            
                            if not openstreetmap.staged_osm_ways[chunk_pos1_str] then
                                openstreetmap.staged_osm_ways[chunk_pos1_str] = {}
                            end

                            openstreetmap.staged_osm_ways[chunk_pos1_str][posStr] = {
                                MTnodeID = way_info.MTnodeID,
                                WayID = wayID,
                                WayType = way_info.type,
                                WayNodes = way_info.nodes,
                                WayEnclosed = way_info.enclosed,
                                WayTags = way_info.tags
                            }
                        end
                    end
                end
            end
        end
    end
end


-- Function to check if a point is inside the given way positions
function openstreetmap.isPositionInsideEnclosure(point, positions)
    local oddNodes = false
    local j = #positions

    for i = 1, #positions do
        if ((positions[i].z < point.z and positions[j].z >= point.z or positions[j].z < point.z and positions[i].z >= point.z) and
            (positions[i].x <= point.x or positions[j].x <= point.x)) then
            oddNodes = oddNodes ~= (positions[i].x + (point.z - positions[i].z) / (positions[j].z - positions[i].z) * (positions[j].x - positions[i].x) < point.x)
        end
        j = i
    end

    return oddNodes
end