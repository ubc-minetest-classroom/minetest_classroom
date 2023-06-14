function mc_core.record_coordinates(player, message)
    if mc_core.checkPrivs(player, {interact = true}) then
        local pmeta = player:get_meta()
        local pos = player:get_pos()
        local realmID = pmeta:get_int("realm")
        local temp, clean_message
        clean_message = minetest.formspec_escape(message)
        temp = minetest.deserialize(pmeta:get_string("coordinates")) or {realms = {}, coords = {}, note_map = {}}

        if temp.realms and temp.coords then
            table.insert(temp.realms, realmID)
            table.insert(temp.coords, pos)
        else
            temp.realms = {realmID}
            temp.coords = {pos}
        end
        temp.note_map[clean_message] = #temp.realms

        pmeta:set_string("coordinates", minetest.serialize(temp))
        minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Your position was recorded in your notebook."))
    end
end

function mc_core.queue_marker(player, message, pos, expiry)
    if player and pos then
        local pname = player:get_player_name()
        local realm = Realm.GetRealmFromPlayer(player)
        local DEFAULT_MARKER_EXPIRY = 30

        if not message then 
            message = "m" 
        else
            message = "m: "..message
        end

        if mc_core.markers[pname] then
            mc_core.markers[pname].timer:cancel()
        end
        mc_core.markers[pname] = {
            timer = minetest.after(expiry or DEFAULT_MARKER_EXPIRY, mc_core.remove_marker, pname),
            message = message,
            pos = pos,
            realm = realm.ID
        }
        mc_core.show_marker(pname, message, pos)
    end
end

local function show_marker(from_pname, to_pname, message, pos)
    if not mc_core.hud:get(to_pname, from_pname.."_marker") then 
        mc_core.hud:add(to_pname, from_pname.."_marker", {
            hud_elem_type = "waypoint",
            world_pos = pos,
            precision = 1,
            number = mc_core.hex_string_to_num(mc_core.col.marker),
            text = (message or "m"), --.."\n(marked by "..from_pname..")",
            alignment = {x = 0, y = 0},
            z_order = -300,
        })
    else
        mc_core.hud:change(to_pname, from_pname.."_marker", {
            world_pos = pos,
            text = message,
        })
    end
end

function mc_core.show_marker(pname, message, pos)
    for _,player in pairs(minetest.get_connected_players()) do
        if player:is_player() then
            local realm = Realm.GetRealmFromPlayer(player)
            if realm and realm.ID == mc_core.markers[pname].realm then
                show_marker(pname, player:get_player_name(), message, pos)
            end
        end
    end
end

function mc_core.remove_marker(pname)
    if mc_core.markers[pname] then
        mc_core.markers[pname].timer:cancel()
        mc_core.markers[pname] = nil
    end
    for _,player in pairs(minetest.get_connected_players()) do
        if player:is_player() then
            local player_name = player:get_player_name()
            if mc_core.hud:get(player_name, pname.."_marker") then
                mc_core.hud:remove(player_name, pname.."_marker")
            end
        end
    end
end

function mc_core.update_marker_visibility(pname, realmID)
    if mc_core.markers then
        for name, marker in pairs(mc_core.markers) do
            if realmID == marker.realm then
                show_marker(name, pname, marker.message, marker.pos)
            elseif mc_core.hud:get(pname, name.."_marker") then
                mc_core.hud:remove(pname, name.."_marker")
            end
        end
    end
end

minetest.register_on_joinplayer(function(player)
    local pname = player:get_player_name()
    local pmeta = player:get_meta()
    local temp = minetest.deserialize(pmeta:get_string("coordinates"))
    -- old format: convert to newer format
    if temp and temp.notes then
        temp.note_map = {}
        temp.format = 2
        for i,note in pairs(temp.notes) do
            temp.note_map[note] = i
        end
        temp.notes = nil
        pmeta:set_string("coordinates", minetest.serialize(temp))
    end
end)

minetest.register_on_leaveplayer(function(player)
    local pname = player:get_player_name()
    if mc_core.markers[pname] then
		mc_core.remove_marker(pname)
    end
end)