minetest.register_chatcommand("fetch_kv_overpass_nodes", {
    params = "<key>=<value> <minlat> <minlon> <maxlat> <maxlon>",
    description = "Search Overpass API for nodes with a specific key=value within a bounding box and create a realm with their extent",
    func = function(name, params)
        local key, value, minlat, minlon, maxlat, maxlon = params:match("^(%w+)=(%w+)%s+([%d.-]+)%s+([%d.-]+)%s+([%d.-]+)%s+([%d.-]+)$")
        
        if not key or not value or not minlat or not minlon or not maxlat or not maxlon then
            return false, "Invalid parameters. Expected <key>=<value> <minlat> <minlon> <maxlat> <maxlon>"
        end

        openstreetmap.fetch_kv_overpass_nodes(key, value, minlat, minlon, maxlat, maxlon)

        return true, "Fetching data from Overpass API..."
    end
})

minetest.register_chatcommand("fetch_all_overpass_nodes", {
    params = "<minlat> <minlon> <maxlat> <maxlon> <notags>",
    description = "Search Overpass API for all nodes within a bounding box and create a realm from their extent, specify if you want to return nodes with no tags",
    func = function(name, params)
        local minlat, minlon, maxlat, maxlon, notags = params:match("^([%d.-]+)%s+([%d.-]+)%s+([%d.-]+)%s+([%d.-]+)%s+(%w+)$")
        
        if not minlat or not minlon or not maxlat or not maxlon then
            return false, "Invalid parameters. Expected <minlat> <minlon> <maxlat> <maxlon> <notags>"
        end
        
        if notags == "true" then notags = true else notags = false end
        openstreetmap.fetch_all_overpass_nodes(minlat, minlon, maxlat, maxlon, notags)

        return true, "Fetching data from Overpass API..."
    end
})

minetest.register_chatcommand("fetch_all_overpass_ways", {
    params = "<minlat> <minlon> <maxlat> <maxlon> <notags> <notags>",
    description = "Search Overpass API for all ways within a bounding box, specify if you want to return ways with no tags",
    func = function(name, params)
        local minlat, minlon, maxlat, maxlon, notags = params:match("^([%d.-]+)%s+([%d.-]+)%s+([%d.-]+)%s+([%d.-]+)%s+(%w+)$")
        
        if not minlat or not minlon or not maxlat or not maxlon then
            return false, "Invalid parameters. Expected <minlat> <minlon> <maxlat> <maxlon> <notags>"
        end
        
        if notags == "true" then notags = true else notags = false end
        openstreetmap.fetch_all_overpass_ways(minlat, minlon, maxlat, maxlon, notags)

        return true, "Fetching data from Overpass API..."
    end
})

minetest.register_chatcommand("place_nodes", {
    params = "",
    description = "Iterates all the nodes in data and places them in the empty realm.",
    func = function(name, params)
        
        local newRealm = Realm.GetRealm(openstreetmap.temp.realmID)

        -- Place the nodes in the realm
        for _,node in pairs(openstreetmap.temp.nodedata.elements) do

            -- Calculate node position in world space
            local easting, northing, isnorth = openstreetmap.latLonToUTM(node.lat, node.lon, openstreetmap.temp.utm_zone)
            local posX = easting - openstreetmap.temp.min_easting + newRealm.StartPos.x
            local posY = newRealm.StartPos.y + 2
            local posZ = northing - openstreetmap.temp.min_northing + newRealm.StartPos.z
            local pos = {x = posX, y = posY, z = posZ}

            -- Process the tags
            local MTnode = "openstreetmap:node"
            local tags = {}
            if node.tags then
                for k, v in pairs(node.tags) do
                    tags[k] = v
                    -- Use the first valid key-value for the node texture
                    if MTnode == "openstreetmap:node" then
                        if openstreetmap.osm_textures[v] then 
                            -- We found a valid texture and registered name
                            MTnode = "openstreetmap:" .. v
                        end
                    end
                end
            end

            -- Create copy of current node metadata before place_node
            local nmeta = minetest.get_meta(pos)
            local old_meta = minetest.deserialize(nmeta:get_string("osm_data")) or {}

            -- Place the node (this clears the node metadata)
            minetest.place_node(pos, {name = MTnode})

            -- Populate OSM data
            openstreetmap.update_osm_data_for_MT_node(old_meta, pos, node.id, node.type, node.lat, node.lon, _, _, _, tags)
        end

        return true, "Placing data from Overpass API..."
    end
})

minetest.register_chatcommand("place_ways", {
    params = "",
    description = "Iterates all the ways in data and places them in the empty realm.",
    func = function(name, params)
        
        local newRealm = Realm.GetRealm(openstreetmap.temp.realmID)
        local nodes = openstreetmap.temp.nodedata.elements
        local ways = openstreetmap.temp.waydata.elements

        -- Place the ways in the realm
        for _,way in pairs(ways) do
            local MTnode = "openstreetmap:way"

            -- Get the nodes for the current way
            for i = 1, #way.nodes - 1 do
                local start_node, end_node
                for _,node in pairs(nodes) do
                    if node.id == way.nodes[i] then
                        start_node = node
                        break
                    end
                end
                for _,node in pairs(nodes) do
                    if node.id == way.nodes[i + 1] then
                        end_node = node
                        break
                    end
                end
                if start_node and end_node then
                    -- Calculate the node positions
                    local start_easting, start_northing, _ = openstreetmap.latLonToUTM(start_node.lat, start_node.lon, openstreetmap.temp.utm_zone)
                    local start_pos = {x = start_easting - openstreetmap.temp.min_easting + newRealm.StartPos.x, y = newRealm.StartPos.y + 2, z = start_northing - openstreetmap.temp.min_northing + newRealm.StartPos.z}
                    local end_easting, end_northing, _ = openstreetmap.latLonToUTM(end_node.lat, end_node.lon, openstreetmap.temp.utm_zone)
                    local end_pos = {x = end_easting - openstreetmap.temp.min_easting + newRealm.StartPos.x, y = newRealm.StartPos.y + 2, z = end_northing - openstreetmap.temp.min_northing + newRealm.StartPos.z}

                    -- Process the tags
                    local nodePlaced = false
                    local tags = {}
                    if way.tags then
                        for k, v in pairs(way.tags) do
                            tags[k] = v
                            -- Search for the correct MT node
                            if MTnode == "openstreetmap:way" then
                                -- Use the first valid key-value for the way texture
                                if openstreetmap.osm_textures[v] then 
                                    -- We found a valid texture and registered name
                                    MTnode = "openstreetmap:" .. v
                                end
                            end
                        end
                    end

                    -- Gather the node ids associated with the way
                    local nodes = {}
                    for _,id in pairs(way.nodes) do table.insert(nodes,id) end

                    -- Determine if the way is enclosed
                    local enclosed
                    if nodes[1] == nodes[#nodes] then enclosed = true else enclosed = false end

                    -- Place the way and update the OSM data
                    openstreetmap.draw_line_between_nodes(start_pos, end_pos, MTnode, way.id, way.type, nodes, enclosed, tags)
                end
            end
        end

        return true, "Placing data from Overpass API..."
    end
})

minetest.register_chatcommand("search_overpass", {
    params = "<key>=<value> <minlat> <minlon> <maxlat> <maxlon>",
    description = "Search Overpass API for nodes with a specific key=value within a bounding box",
    func = function(name, params)
        local key, value, minlat, minlon, maxlat, maxlon = params:match("^(%w+)=(%w+)%s+([%d.-]+)%s+([%d.-]+)%s+([%d.-]+)%s+([%d.-]+)$")
        
        if not key or not value or not minlat or not minlon or not maxlat or not maxlon then
            return false, "Invalid parameters. Expected <key>=<value> <minlat> <minlon> <maxlat> <maxlon>"
        end
        
        openstreetmap.fetch_kv_overpass_nodes(key, value, minlat, minlon, maxlat, maxlon, function(result)
            if result.succeeded then
                -- Process the data and do something with it, for this example, just print number of nodes found
                local data = minetest.parse_json(result.data)
                minetest.chat_send_player(name, "Found " .. #data.elements .. " nodes with " .. key .. "=" .. value)
            else
                minetest.chat_send_player(name, "Failed to fetch data from Overpass API")
            end
        end)

        return true, "Fetching data from Overpass API..."
    end
})

minetest.register_chatcommand("query_osm_db", {
    params = "<expression>",
    description = "Simple query language supporting operators: AND, OR, =, >=, <=, <, >, and !=",
    func = function(name, params)

        local osmdb = minetest.deserialize(openstreetmap.meta:get_string("osm_db")) or {}
        local results = openstreetmap.query_osm_db(osmdb, params)
        if results then
            minetest.chat_send_player(name, "Your query returned the following key-value pairs:")
            for id, res in ipairs(results) do
                for k,v in pairs(res) do 
                    minetest.chat_send_player(name, "    ID="..id.." "..k.."="..v)
                end
            end
        else
            minetest.chat_send_player(name, "Your query did not return any matching key-value pairs.")
        end
    end
})