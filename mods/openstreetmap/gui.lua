local context = {}

function openstreetmap.show_osm_tags_fs(player, pos)
    context.pos = pos or openstreetmap.pointed_thing_pos
    local fs = {
        "formspec_version[6]",
        "size[10.5,11]"
    }

    local nmeta = minetest.get_meta(context.pos)
    local ndata = minetest.deserialize(nmeta:get_string("osm_data"))

    if ndata then
        local data
        fs[#fs + 1] = "label[3.3,1;OpenStreetMap Information]"
        fs[#fs + 1] = "label[0.6,1.8;Features:]"
        fs[#fs + 1] = "textlist[0.6,2;9.3,3;featurelist;"
        context.idlist = {}
        for id,_ in pairs(ndata) do
            table.insert(context.idlist,id)
            data = ndata[id]
            fs[#fs + 1] = data.type
            fs[#fs + 1] = " (id "
            fs[#fs + 1] = id
            fs[#fs + 1] = ")"
            fs[#fs + 1] = ","
        end
        fs[#fs] = ""
        fs[#fs + 1] = ";"
        fs[#fs + 1] = context.selected_feature or context.idlist[1]
        fs[#fs + 1] = ";false]"
        local fid = context.idlist[context.selected_feature] or context.idlist[1]
        data = ndata[fid]
        if data.type == "node" then
            fs[#fs + 1] = "label[0.6,5.5;Latitude: "
            fs[#fs + 1] = data.lat
            fs[#fs + 1] = "]"
            fs[#fs + 1] = "label[0.6,6;Longitude: "
            fs[#fs + 1] = data.lon
            fs[#fs + 1] = "]"
            if next(data.tags) then
                fs[#fs + 1] = "label[0.6,6.5;Tags:]"
                fs[#fs + 1] = "textlist[0.6,6.7;9.3,3;taglist;"
                for k,v in pairs(data.tags) do
                    fs[#fs + 1] = k
                    fs[#fs + 1] = " = "
                    fs[#fs + 1] = v
                    fs[#fs + 1] = ","
                end
                fs[#fs] = ""
                fs[#fs + 1] = ";"
                fs[#fs + 1] = context.selected_tag or 1
                fs[#fs + 1] = ";false]"
            else
                fs[#fs + 1] = "label[0.6,6.5;No tags to display]"
            end
        elseif data.type == "way" then
            if next(data.tags) then
                -- Ways and relations do not have latitude/longitude
                fs[#fs + 1] = "label[0.6,5.5;Tags:]"
                fs[#fs + 1] = "textlist[0.6,5.7;9.3,3;taglist;"
                for k,v in pairs(data.tags) do
                    fs[#fs + 1] = k
                    fs[#fs + 1] = " = "
                    fs[#fs + 1] = v
                    fs[#fs + 1] = ","
                end
                fs[#fs] = ""
                fs[#fs + 1] = ";"
                fs[#fs + 1] = context.selected_tag or 1
                fs[#fs + 1] = ";false]"
            else
                fs[#fs + 1] = "label[0.6,5.5;No tags to display]"
            end
        end
        fs[#fs + 1] = "button[0.6,9.9;2,1;highlight;Highlight]"
    else
        -- empty list, nothing to see here
        fs[#fs + 1] = "label[0.6,1;No OSM data to display for this Minetest node]"
    end
    minetest.show_formspec(player:get_player_name(), "openstreetmap:inspect", table.concat(fs,""))
end

-- Processing the form
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if string.sub(formname, 1, 13) ~= "openstreetmap" then
        return false
    end

    local wait = os.clock()
    while os.clock() - wait < 0.05 do end --popups don't work without this

    if formname == "openstreetmap:inspect" then
        if fields.featurelist then
            local event = minetest.explode_textlist_event(fields.featurelist)
            if event.type == "CHG" then context.selected_feature = event.index end
            openstreetmap.show_osm_tags_fs(player, context.pos)
        elseif fields.taglist then
            local event = minetest.explode_textlist_event(fields.taglist)
            if event.type == "CHG" then context.selected_tag = event.index end
        elseif fields.highlight then
            -- TODO: refactor so that node data and way data are stored as attributes the realm
            local nmeta = minetest.get_meta(context.pos)
            local ndata = minetest.deserialize(nmeta:get_string("osm_data"))
            local fid = context.idlist[context.selected_feature] or context.idlist[1]
            local data = ndata[fid]
            if data.type == "node" then
                openstreetmap.flash_entity(context.pos, 10)
            elseif data.type == "way" then
                -- Calculate node position in world space
                local realm = Realm.GetRealmFromPlayer(player)
                for _,id in pairs(data.OSMnodes) do
                    -- Get the node table
                    local indexedNodeData = realm:get_data("OSMIndexedNodeData")
                    local min_easting = realm:get_data("min_easting")
                    local min_northing = realm:get_data("min_northing")
                    local utm_zone = realm:get_data("utm_zone")
                    --local nodes = openstreetmap.temp.nodedata.elements
                    for idx,node in pairs(indexedNodeData) do
                        if idx == id then
                            local easting, northing, _ = openstreetmap.latLonToUTM(node.lat, node.lon, utm_zone)
                            local pos = {x = easting - min_easting + realm.StartPos.x, y = realm.StartPos.y + 2, z = northing - min_northing + realm.StartPos.z}
                            openstreetmap.flash_entity(pos, 10)
                            break
                        end
                    end
                end
            end
        else
            return false
        end
    end
end)