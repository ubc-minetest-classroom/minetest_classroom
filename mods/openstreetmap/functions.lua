function openstreetmap.fetch_kv_overpass_nodes(key, value, minlat, minlon, maxlat, maxlon)
    openstreetmap.fetch_kv_overpass_nodes_callback(key, value, minlat, minlon, maxlat, maxlon, function(result)
        if result.succeeded then
            local data = minetest.parse_json(result.data)
            minetest.chat_send_all("Found " .. #data.elements .. " nodes with " .. key .. "=" .. value)

            -- Get and check the UTM zone from the bounding longitude
            local utm_zone_min = openstreetmap.computeUTMZone(minlon)
            local utm_zone_max = openstreetmap.computeUTMZone(maxlon)
            if utm_zone_min == utm_zone_max then
                -- Get the range of eastings and northings for creating the realm size
                local max_easting = 0
                local max_northing = 0
                local min_easting, min_northing
                for _,node in pairs(data.elements) do
                    local easting, northing = openstreetmap.latLonToUTM(node.lat, node.lon, utm_zone_min)
                    if min_easting then min_easting = math.min(min_easting,easting) else min_easting = easting end
                    if min_northing then min_northing = math.min(min_northing,northing) else min_northing = northing end
                    max_easting = math.max(max_easting,easting)
                    max_northing = math.max(max_northing,northing)
                end
                local sizeX = max_easting - min_easting + 1
                local sizeZ = max_northing - min_northing + 1

                -- Create the realm
                local newRealm = Realm:New("OSM", { x = sizeX, y = 80, z = sizeZ })
                newRealm:CreateGround()
                newRealm:CreateBarriersFast()

                -- Store everything
                openstreetmap.temp.sizeX = sizeX
                openstreetmap.temp.sizeY = 80
                openstreetmap.temp.sizeZ = sizeZ
                openstreetmap.temp.min_easting = min_easting
                openstreetmap.temp.min_northing = min_northing
                openstreetmap.temp.utm_zone = utm_zone_min
                openstreetmap.temp.realmID = newRealm.ID
                openstreetmap.temp.nodedata = data

            else
                minetest.chat_send_all("OSM data span more than one UTM zone, cannot map all the features in a cartesian coordinate system.")
            end
        else
            minetest.chat_send_all("Failed to fetch data from Overpass API")
        end
    end)
end

function openstreetmap.fetch_all_overpass_nodes(minlat, minlon, maxlat, maxlon, notags)
    openstreetmap.fetch_all_overpass_nodes_callback(minlat, minlon, maxlat, maxlon, notags, function(result)
        if result.succeeded then
            local data = minetest.parse_json(result.data)
            minetest.chat_send_all("Found " .. #data.elements .. " nodes")

            -- Get and check the UTM zone from the bounding longitude
            local utm_zone_min = openstreetmap.computeUTMZone(minlon)
            local utm_zone_max = openstreetmap.computeUTMZone(maxlon)
            if utm_zone_min == utm_zone_max then
                
                -- Get the range of eastings and northings for creating the realm size
                local max_easting = 0
                local max_northing = 0
                local min_easting, min_northing, easting, northing, isnorth
                for _,node in pairs(data.elements) do
                    easting, northing, isnorth = openstreetmap.latLonToUTM(node.lat, node.lon, utm_zone_min)
                    if min_easting then min_easting = math.min(min_easting,easting) else min_easting = easting end
                    if min_northing then min_northing = math.min(min_northing,northing) else min_northing = northing end
                    max_easting = math.max(max_easting,easting)
                    max_northing = math.max(max_northing,northing)
                end
                local sizeX = max_easting - min_easting + 1
                local sizeZ = max_northing - min_northing + 1

                -- Reformat nodedata so that the node id is a key
                local outNodeData = {}
                for _, node in pairs(data) do
                    outNodeData[node.id] = {
                        type = node.type,
                        lat = node.lat,
                        lon = node.lon,
                        timestamp = node.timstamp,
                        version = node.version,
                        changeset = node.changeset,
                        user = node.user,
                        uid = node.uid,
                        tags = node.tags,
                    }
                end

                -- Store everything
                openstreetmap.temp.sizeX = sizeX
                openstreetmap.temp.sizeY = 160
                openstreetmap.temp.sizeZ = sizeZ
                openstreetmap.temp.min_easting = min_easting
                openstreetmap.temp.min_northing = min_northing
                openstreetmap.temp.utm_zone = utm_zone_min
                openstreetmap.temp.nodedata = outNodeData

            else
                minetest.chat_send_all("OSM data span more than one UTM zone, cannot map all the features in a cartesian coordinate system.")
            end
        else
            minetest.chat_send_all("Failed to fetch data from Overpass API")
        end
    end)
end

function openstreetmap.fetch_all_overpass_ways(minlat, minlon, maxlat, maxlon, notags)
    openstreetmap.fetch_all_overpass_ways_callback(minlat, minlon, maxlat, maxlon, notags, function(result)
        if result.succeeded then
            local data = minetest.parse_json(result.data)
            minetest.chat_send_all("Found " .. #data.elements .. " ways")
            -- Reformat nodedata so that the node id is a key
            local indexedWayData = {}
            for _, way in pairs(data) do
                -- Process the tags to get the MTnode
                local MTnode = "openstreetmap:way"
                if way.tags then
                    for k, v in pairs(way.tags) do
                        -- Use the first valid key-value for the node texture, otherwise use the default
                        if MTnode == "openstreetmap:way" and openstreetmap.temp.way_value_itemstring_table[v] then
                            MTnode = openstreetmap.temp.way_value_itemstring_table[v]
                        end
                    end
                end
                local MTnodeID = minetest.get_content_id(MTnode)
                
                -- Determine if the way is enclosed
                local nodesinway = {}
                for _, id in pairs(way.nodes) do table.insert(nodesinway, id) end
                local enclosed
                if nodesinway[1] == nodesinway[#nodesinway] then enclosed = true else enclosed = false end

                indexedWayData[way.id] = {
                    type = way.type,
                    timestamp = way.timstamp,
                    version = way.version,
                    changeset = way.changeset,
                    user = way.user,
                    uid = way.uid,
                    nodes = way.nodes,
                    tags = way.tags,
                    MTnodeID = MTnodeID,
                    enclosed = enclosed
                }
            end
            -- Store everything
            openstreetmap.temp.waydata = data
            openstreetmap.temp.indexedWayData = indexedWayData
        else
            minetest.chat_send_all("Failed to fetch data from Overpass API")
        end
    end)
end

-- Function to fetch node data from Overpass API based on key=value and bounding box
function openstreetmap.fetch_kv_overpass_nodes_callback(key, value, minlat, minlon, maxlat, maxlon, callback)
    local query = string.format([[
        [out:json];
        node["%s"="%s"](%s,%s,%s,%s);
        out;
    ]], key, value, minlat, minlon, maxlat, maxlon)

    openstreetmap.http.fetch({
        url = "https://overpass-api.de/api/interpreter",
        post_data = query,
        timeout = 10
    }, callback)
end

-- Function to fetch all node data from Overpass API with valid tags and bounding box
function openstreetmap.fetch_all_overpass_nodes_callback(minlat, minlon, maxlat, maxlon, notags, callback)
    local query
    if notags then
        -- Return all nodes, regardles whether they have tags
        query = string.format([[
            [out:json];
            node(%s,%s,%s,%s);
            out;
        ]], minlat, minlon, maxlat, maxlon)
    else
        -- Only return nodes that have tags
        query = string.format([[
            [out:json];
            node[~"."~"."](%s,%s,%s,%s);
            out;
        ]], minlat, minlon, maxlat, maxlon)
    end

    openstreetmap.http.fetch({
        url = "https://overpass-api.de/api/interpreter",
        post_data = query,
        timeout = 10
    }, callback)
end

-- Function to fetch all node data from Overpass API with valid tags and bounding box
function openstreetmap.fetch_all_overpass_ways_callback(minlat, minlon, maxlat, maxlon, notags, callback)
    local query
    if notags then
        -- Return all nodes, regardles whether they have tags
        query = string.format([[
            [out:json];
            way(%s,%s,%s,%s);
            out;
        ]], minlat, minlon, maxlat, maxlon)
    else
        -- Only return nodes that have tags
        query = string.format([[
            [out:json];
            way[~"."~"."](%s,%s,%s,%s);
            out;
        ]], minlat, minlon, maxlat, maxlon)
    end

    openstreetmap.http.fetch({
        url = "https://overpass-api.de/api/interpreter",
        post_data = query,
        timeout = 10
    }, callback)
end

function openstreetmap.update_osm_data_for_MT_node(old_meta, pos, id, ftype, lat, lon, OSMnodes, enclosed, members, tags)
    local nmeta = minetest.get_meta(pos)
    local osmdb = minetest.deserialize(openstreetmap.meta:get_string("osm_db")) or {}

    if ftype == "node" then
        local node_table = {
            type = ftype,
            lat = lat,
            lon = lon,
            tags = tags or {} -- not all nodes have tags
        }
        old_meta[id] = node_table
        osmdb[id] = node_table
    elseif ftype == "way" then
        local way_table = {
            type = ftype,
            OSMnodes = OSMnodes,
            enclosed = enclosed,
            tags = tags or {} -- not all ways have tags
        }
        old_meta[id] = way_table
        osmdb[id] = way_table
    elseif ftype == "relation" then
        local relation_table = {
            type = ftype,
            enclosed = enclosed,
            members = members,
            tags = tags or {} -- not all relations have tags
        }
        old_meta[id] = relation_table
        osmdb[id] = relation_table
    else
        return false
    end

    nmeta:set_string("osm_data", minetest.serialize(old_meta))
    openstreetmap.meta:set_string("osm_db", minetest.serialize(osmdb))
    
end

function openstreetmap.flash_entity(pos, count)
    if count <= 0 then
        return
    end
    
    local obj = minetest.add_entity(pos, "openstreetmap:highlight")
    
    minetest.after(1, function()
        obj:remove()
        minetest.after(1, function()
            openstreetmap.flash_entity(pos, count - 1)
        end)
    end)
end

function openstreetmap.parse_expression(expr, entry)
    local key, operator, value = expr:match("([^<>=!]+)([<>=!]+)([^<>=!]+)")
    
    if not key or not operator or not value then
        return false
    end
    
    if operator == "=" then
        return tostring(entry[key]) == value
    elseif operator == ">" then
        return tonumber(entry[key]) > tonumber(value)
    elseif operator == "<" then
        return tonumber(entry[key]) < tonumber(value)
    elseif operator == ">=" then
        return tonumber(entry[key]) >= tonumber(value)
    elseif operator == "<=" then
        return tonumber(entry[key]) <= tonumber(value)
    elseif operator == "!=" then
        return tostring(entry[key]) ~= value
    end
    
    return false
end

function openstreetmap.query_osm_db(data, q)
    local parts = {}
    for part in q:gmatch("[^%s]+") do
        table.insert(parts, part)
    end

    local results = {}
    for _, entry in pairs(data) do
        local result = false
        local and_next = false
        local or_next = false
        
        for _, part in ipairs(parts) do
            if part == "AND" then
                and_next = true
                or_next = false
            elseif part == "OR" then
                or_next = true
                and_next = false
            else
                local current_result = openstreetmap.parse_expression(part, entry)
                
                if and_next then
                    result = result and current_result
                    and_next = false
                elseif or_next then
                    result = result or current_result
                    or_next = false
                else
                    result = current_result
                end
            end
        end
        
        if result then
            table.insert(results, entry)
        end
    end
    
    return results
end

function openstreetmap.value_exists_for_key(table, key, value)
    for _, v in ipairs(table[key] or {}) do
        if v == value then
            return true
        end
    end
    return false
end

function openstreetmap.value_exists_in_table(table, value)
    for _, v in ipairs(table or {}) do
        if v == value then
            return true
        end
    end
    return false
end

function openstreetmap.findChunkForPosition(position, chunks)
    for _, chunk in pairs(chunks) do
        local chunkPos1 = chunk.pos1
        local chunkPos2 = chunk.pos2

        if position.x >= chunkPos1.x and position.x <= chunkPos2.x
           and position.y >= chunkPos1.y and position.y <= chunkPos2.y
           and position.z >= chunkPos1.z and position.z <= chunkPos2.z then
            return chunk
        end
    end

    return nil  -- Position is not in any chunk
end

function openstreetmap.place_nodes_in_realm(nodes, realm, heightMapTable)
    if not nodes or not realm then
        return false
    end

    -- Create voxel manipulator chunks based on the realm dimensions
    local chunks = Realm:Create_VM_Chunks(realm.StartPos, realm.EndPos, mc_core.VM_CHUNK_SIZE)

    -- Global table to stage OSM node data
    openstreetmap.staged_osm_nodes = {}

    for _, node in pairs(nodes) do
        -- Calculate node position in world space
        local easting, northing, isnorth = openstreetmap.latLonToUTM(node.lat, node.lon, openstreetmap.temp.utm_zone)
        local posX = easting - openstreetmap.temp.min_easting + realm.StartPos.x
        local posY = realm.StartPos.y
        local posZ = northing - openstreetmap.temp.min_northing + realm.StartPos.z
        if heightMapTable then 
            -- We have a height map table, so add the height to the y position
            if heightMapTable[posX] and heightMapTable[posX][posZ] then
                posY = posY + math.ceil(heightMapTable[posX][posZ])
            end
        end

        -- Process the tags and get the MTnode
        local MTnode = "openstreetmap:node"
        local extrusion_value
        if node.tags then
            for k, v in pairs(node.tags) do
                -- Use the first valid key-value for the node texture, otherwise use the default
                if MTnode == "openstreetmap:node" and openstreetmap.temp.node_value_itemstring_table[v] then
                    MTnode = openstreetmap.temp.node_value_itemstring_table[v]
                    -- Check for user-defined extrusion
                    if openstreetmap.temp.node_value_extrusion_table[v] then
                        extrusion_value = openstreetmap.temp.node_value_extrusion_table[v]
                    end
                end
            end
        end
        local MTnodeID = minetest.get_content_id(MTnode)

        if extrusion_value and tonumber(extrusion_value) > 0 then 
            -- With extrusion, we need to consider that the extruded feature might span several chunks
            for dd = 1, extrusion_value, 1 do
                -- Determine the chunk that the OSM node position is in
                local chunk = openstreetmap.findChunkForPosition({x = posX, y = posY + dd, z = posZ}, chunks)
                if chunk then
                    local posKey = {x = posX, y = posY + dd, z = posZ}
                    local posStr = minetest.pos_to_string(posKey)

                    -- We are going to use chunk.pos1 as a key to quickly access the associated OSM node data
                    local chunk_pos1_str = minetest.pos_to_string(chunk.pos1)
                    if not openstreetmap.staged_osm_nodes[chunk_pos1_str] then
                        openstreetmap.staged_osm_nodes[chunk_pos1_str] = {}
                    end
                    
                    openstreetmap.staged_osm_nodes[chunk_pos1_str][posStr] = {
                        MTnodeID = MTnodeID,
                        NodeID = node.id,
                        NodeType = node.type,
                        NodeLat = node.lat,
                        NodeLon = node.lon,
                        NodeTags = node.tags
                    }
                end
            end
        else
            -- Determine the chunk that the OSM node position is in
            local chunk = openstreetmap.findChunkForPosition({x = posX, y = posY, z = posZ}, chunks)
            if chunk then
                local posKey = {x = posX, y = posY, z = posZ}
                local posStr = minetest.pos_to_string(posKey)

                -- We are going to use chunk.pos1 as a key to quickly access the associated OSM node data
                local chunk_pos1_str = minetest.pos_to_string(chunk.pos1)
                if not openstreetmap.staged_osm_nodes[chunk_pos1_str] then
                    openstreetmap.staged_osm_nodes[chunk_pos1_str] = {}
                end
                
                openstreetmap.staged_osm_nodes[chunk_pos1_str][posStr] = {
                    MTnodeID = MTnodeID,
                    NodeID = node.id,
                    NodeType = node.type,
                    NodeLat = node.lat,
                    NodeLon = node.lon,
                    NodeTags = node.tags
                }
            end
        end
    end

    -- Process the chunks that have OSM nodes
    local chunk_number = 1
    local vm = minetest.get_voxel_manip()
    for chunk_pos1_str, nodesInChunk in pairs(openstreetmap.staged_osm_nodes) do
        minetest.chat_send_all("[OpenStreetMap] Placing node content in chunk "..tostring(chunk_number).." of "..tostring(#chunks).." total chunks...")
        local chunk_pos1 = minetest.string_to_pos(chunk_pos1_str)
        local chunk_pos2 = {
            x = chunk_pos1.x + mc_core.VM_CHUNK_SIZE - 1, 
            y = chunk_pos1.y + mc_core.VM_CHUNK_SIZE - 1, 
            z = chunk_pos1.z + mc_core.VM_CHUNK_SIZE - 1
        }
        local emin, emax = vm:read_from_map(chunk_pos1, chunk_pos2)
        local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
        local data = vm:get_data()

        -- Iterate over OSM nodes within the chunk
        for posStr, NodeTable in pairs(nodesInChunk) do
            local pos = minetest.string_to_pos(posStr)

            -- Create copy of current node metadata before place_node
            local nmeta = minetest.get_meta(pos)
            local old_meta = minetest.deserialize(nmeta:get_string("osm_data")) or {}

            -- Update y placement in realm
            if openstreetmap.fill_depth then
                pos.y = pos.y + openstreetmap.fill_depth + 1
            else
                -- TODO: implement heightmap from LiDAR
                pos.y = pos.y + 1
            end

            local index = area:index(pos.x, pos.y, pos.z)
            data[index] = NodeTable.MTnodeID

            -- Update OSM metadata
            if openstreetmap.write_metadata then
                openstreetmap.update_osm_data_for_MT_node(old_meta, pos, NodeTable.NodeID, NodeTable.NodeType, NodeTable.NodeLat, NodeTable.NodeLon, _, _, _, NodeTable.NodeTags)
            end
        end

        -- Write data back to the map with lighting updates
        vm:set_data(data)
        vm:calc_lighting()
        vm:write_to_map(true)
        vm:update_liquids()
        data = nil
        
        chunk_number = chunk_number + 1
    end
end

function openstreetmap.place_ways_in_realm(nodes, ways, realm)
    if not nodes or not ways or not realm then
        return false
    end

    -- Global table to stage OSM way data
    openstreetmap.staged_osm_ways = {}

    -- Global table to hold all unique way positions
    openstreetmap.way_positions = {}

    -- Create a lookup dictionary for nodes
    local nodeLookup = {}
    for _,node in pairs(nodes) do
        nodeLookup[node.id] = node
    end

    -- Create voxel manipulator chunks based on the realm dimensions
    local chunks = Realm:Create_VM_Chunks(realm.StartPos, realm.EndPos, mc_core.VM_CHUNK_SIZE)

    for _,way in pairs(ways) do
        local MTnode = "openstreetmap:way"

        -- Get the nodes for the current way
        for i = 1, #way.nodes - 1 do
            local start_node = nodeLookup[way.nodes[i]]
            local end_node = nodeLookup[way.nodes[i + 1]]
            if start_node and end_node then
                -- Calculate the node positions
                local start_easting, start_northing, _ = openstreetmap.latLonToUTM(start_node.lat, start_node.lon, openstreetmap.temp.utm_zone)
                local start_pos = {x = start_easting - openstreetmap.temp.min_easting + realm.StartPos.x, y = realm.StartPos.y, z = start_northing - openstreetmap.temp.min_northing + realm.StartPos.z}
                local end_easting, end_northing, _ = openstreetmap.latLonToUTM(end_node.lat, end_node.lon, openstreetmap.temp.utm_zone)
                local end_pos = {x = end_easting - openstreetmap.temp.min_easting + realm.StartPos.x, y = realm.StartPos.y, z = end_northing - openstreetmap.temp.min_northing + realm.StartPos.z}

                -- Process the tags
                local extrusion_value
                MTnode = "openstreetmap:way"
                if way.tags then
                    for k, v in pairs(way.tags) do
                        -- Use the first valid key-value for the node texture, otherwise use the default
                        if MTnode == "openstreetmap:way" and openstreetmap.temp.way_value_itemstring_table[v] then
                            MTnode = openstreetmap.temp.way_value_itemstring_table[v]
                            -- Check for user-defined extrusion
                            if openstreetmap.temp.way_value_extrusion_table[v] then
                                extrusion_value = openstreetmap.temp.way_value_extrusion_table[v]
                            end
                        end
                    end
                end
                local MTnodeID = minetest.get_content_id(MTnode)

                -- Update the texture in the indexed way data for fill to work
                openstreetmap.temp.indexedWayData[way.id].MTnodeID = MTnodeID

                -- Gather the node ids associated with the way
                local nodesinway = {}
                for _, id in pairs(way.nodes) do table.insert(nodesinway, id) end

                -- Determine if the way is enclosed
                local enclosed
                if nodesinway[1] == nodesinway[#nodesinway] then enclosed = true else enclosed = false end
                -- Check that we actually have all the nodes for the way so that we avoid filling polygons that fold back onto themselves
                for _, nodeid in ipairs(nodesinway) do if not openstreetmap.temp.indexedNodeData[nodeid] then enclosed = false break end end

                -- Calculate the MT node positions between the start/end and stage the info and metadata for writing
                openstreetmap.draw_line_between_nodes(start_pos, end_pos, MTnodeID, way.id, way.type, nodesinway, enclosed, way.tags, extrusion_value, chunks)
            end
        end
    end

    -- Fill enclosed ways
    if openstreetmap.fill_enclosures and openstreetmap.way_positions then 
        openstreetmap.fillEnclosedWays(chunks) 
    end

    -- Process the chunks that have OSM nodes
    local chunk_number = 1
    local vm = minetest.get_voxel_manip()
    for chunk_pos1_str, nodesInChunk in pairs(openstreetmap.staged_osm_ways) do
        minetest.chat_send_all("[OpenStreetMap] Placing way content in chunk "..tostring(chunk_number).." of "..tostring(#chunks).." total chunks...")
        local chunk_pos1 = minetest.string_to_pos(chunk_pos1_str)
        local chunk_pos2 = {
            x = chunk_pos1.x + mc_core.VM_CHUNK_SIZE - 1, 
            y = chunk_pos1.y + mc_core.VM_CHUNK_SIZE - 1, 
            z = chunk_pos1.z + mc_core.VM_CHUNK_SIZE - 1
        }
        local emin, emax = vm:read_from_map(chunk_pos1, chunk_pos2)
        local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
        local data = vm:get_data()

        -- Iterate over OSM nodes within the chunk
        for posStr, WayTable in pairs(nodesInChunk) do
            local pos = minetest.string_to_pos(posStr)

            -- Create copy of current node metadata before we change it
            local nmeta = minetest.get_meta(pos)
            local old_meta = minetest.deserialize(nmeta:get_string("osm_data")) or {}

            -- Update y placement in realm
            if openstreetmap.fill_depth then
                pos.y = pos.y + openstreetmap.fill_depth + 1
            else
                -- TODO: implement heightmap from LiDAR
                pos.y = pos.y + 1
            end
            local index = area:index(pos.x, pos.y, pos.z)
            data[index] = WayTable.MTnodeID

            -- Update OSM metadata
            if openstreetmap.write_metadata then
                openstreetmap.update_osm_data_for_MT_node(old_meta, pos, WayTable.WayID, WayTable.WayType, _, _, WayTable.WayNodes, WayTable.WayEnclosed, _, WayTable.WayTags)
            end
        end

        -- Write data back to the map with lighting updates
        vm:set_data(data)
        vm:calc_lighting()
        vm:write_to_map(true)
        vm:update_liquids()
        
        chunk_number = chunk_number + 1
    end
end