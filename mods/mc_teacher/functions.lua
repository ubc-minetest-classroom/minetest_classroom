function mc_teacher.shutdown_server(reconnect)
    minetest.request_shutdown("Server is undergoing a scheduled restart. Please try to reconnect after one minute.", reconnect, 0)
end

function mc_teacher.cancel_shutdown()
    if mc_teacher.restart_scheduled then
        for _,timer in pairs(mc_teacher.restart_scheduled) do
            timer:cancel()
        end
        mc_teacher.restart_scheduled = {}
        mc_teacher.clear_restart_time()
    end
end

function mc_teacher.display_restart_time(time)
    local extension = " seconds"
    if time >= 3600 then
        extension = " hours"
        time = time / 3600
    elseif time >= 60 then
        extension = " minutes"
        time = time / 60
    end

    if time == 1 then
        extension = string.sub(extension, 1, -2)
    end

    for _,player in pairs(minetest.get_connected_players()) do
        if player:is_player() then
            if not mc_core.hud:get(player, "restart_timer") then
                mc_core.hud:add(player, "restart_timer", {
                    hud_elem_type = "text",
                    text = "Server restarting in "..time..extension,
                    scale = {x = 100, y = 100},
                    position = {x = 0.5, y = 0.918},
                    alignment = {x = 0, y = -1},
                    color = 0xFFFFFF,
                    style = 0,
                })
            else
                mc_core.hud:change(player, "restart_timer", {
                    text = "Server restarting in "..time..extension
                })
            end
        end
    end
end

function mc_teacher.clear_restart_time()
    for _,player in pairs(minetest.get_connected_players()) do
        if player:is_player() and mc_core.hud:get(player, "restart_timer") then
            mc_core.hud:clear(player, "restart_timer")
        end
    end
end

function mc_teacher.get_fs_context(player)
	local pname = (type(player) == "string" and player) or (player:is_player() and player:get_player_name()) or ""
	if not mc_teacher.fs_context[pname] then
		mc_teacher.fs_context[pname] = {
			tab = mc_teacher.TABS.OVERVIEW,
            selected_mode = "1",
		}
	end
	return mc_teacher.fs_context[pname]
end

function mc_teacher.check_selected_priv_mode(context)
    if context.tab == mc_teacher.TABS.CLASSROOMS and (not context.selected_privs or context.selected_privs_mode ~= mc_teacher.TABS.CLASSROOMS) then
        context.selected_privs = {interact = true, shout = true, fast = true, fly = "nil", noclip = "nil", give = "nil"}
        context.selected_privs_mode = mc_teacher.TABS.CLASSROOMS
    elseif context.tab == mc_teacher.TABS.PLAYERS and (not context.selected_privs or context.selected_privs_mode ~= mc_teacher.TABS.PLAYERS) then
        context.selected_privs = nil
        context.selected_privs_mode = mc_teacher.TABS.PLAYERS
    end
end

local function check_for_reports(pname)
    local report_reminder = mc_teacher.meta:get_int("report_reminder")
    if report_reminder > 0 then
        minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, table.concat({
            "[Minetest Classroom] ", report_reminder, " report", report_reminder == 1 and " was" or "s were", " received while you were away. ",
            "Please check the \"Reports\" tab of the teacher controller for more information."
        })))
        mc_teacher.meta:set_int("report_reminder", 0)
    end
end

function mc_teacher.register_teacher(player)
    local pname = (type(player) == "string" and player) or (player:is_player() and player:get_player_name())
    if pname then
        mc_teacher.teachers[pname] = true
        mc_teacher.students[pname] = nil
    end
    check_for_reports(pname)
end

function mc_teacher.register_student(player)
    local pname = (type(player) == "string" and player) or (player:is_player() and player:get_player_name())
    if pname then
        mc_teacher.teachers[pname] = nil
        mc_teacher.students[pname] = true
    end
end

function mc_teacher.deregister_player(player)
    local pname = (type(player) == "string" and player) or (player:is_player() and player:get_player_name())
    if pname then
        mc_teacher.teachers[pname] = nil
        mc_teacher.students[pname] = nil
        mc_teacher.fs_context[pname] = nil
    end
end

function mc_teacher.log_chat_message(name, message)
	local timestamp = tostring(os.date("%Y-%m-%d %H:%M:%S"))
    local log = minetest.deserialize(mc_teacher.meta:get_string("chat_log")) or {}
    log[name] = log[name] or {}
    table.insert(log[name], {
        timestamp = timestamp,
        message = message,
    })
	mc_teacher.meta:set_string("chat_log", minetest.serialize(log))
end

function mc_teacher.log_server_message(name, message, recipient, is_anon)
	local timestamp = tostring(os.date("%Y-%m-%d %H:%M:%S"))
    local log = minetest.deserialize(mc_teacher.meta:get_string("server_log")) or {}
    log[name] = log[name] or {}
    table.insert(log[name], {
        timestamp = timestamp,
        message = message,
        recipient = recipient,
        anonymous = is_anon,
    })
	mc_teacher.meta:set_string("server_log", minetest.serialize(log))
end

function mc_teacher.log_direct_message(name, message, recipient)
    local timestamp = tostring(os.date("%Y-%m-%d %H:%M:%S"))
    local log = minetest.deserialize(mc_teacher.meta:get_string("dm_log")) or {}
    log[name] = log[name] or {}
    table.insert(log[name], {
        timestamp = timestamp,
        recipient = recipient,
        message = message
    })
    mc_teacher.meta:set_string("dm_log", minetest.serialize(log))
end

function mc_teacher.get_server_role(player)
    local pname = (type(player) == "string" and player) or (player:is_player() and player:get_player_name()) or ""
    local privs = minetest.get_player_privs(pname)
    if not privs["teacher"] then
        return mc_teacher.ROLES.STUDENT
    elseif not privs["server"] then
        return mc_teacher.ROLES.TEACHER
    else
        return mc_teacher.ROLES.ADMIN
    end
end

function mc_teacher.save_realm(player, context, fields)
    local realm = Realm.GetRealm(context.edit_realm.id)
    if realm then
        if not fields.no_cat_override then
            if context.edit_realm.type == mc_teacher.R.CAT_KEY.SPAWN and realm.ID ~= mc_worldManager.GetSpawnRealm().ID then
                if realm:isHidden() or realm:isDeleted() then
                    minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] This classroom is currently "..(realm:isHidden() and "hidden" or "being deleted"..", so it could not be set as the server's spawn classroom.")))
                else
                    mc_worldManager.SetSpawnRealm(realm)
                    minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Server spawn classroom updated!"))
                end
            else
                realm:setCategoryKey(mc_teacher.R.CAT_MAP[context.edit_realm.type or mc_teacher.R.CAT_KEY.CLASSROOM])
            end
        end
        realm.Name = (mc_core.trim(fields.erealm_name or "") ~= "" and fields.erealm_name) or (mc_core.trim(context.edit_realm.name or "") ~= "" and context.edit_realm.name) or "Unnamed classroom"
        realm:UpdateRealmPrivilege(context.edit_realm.privs or {})
        realm:UpdateSkybox(context.skyboxes[context.edit_realm.skybox])
        realm:UpdateMusic(context.music[context.edit_realm.music], 100)

        -- update players in realm
        local players_in_realm = realm:GetPlayersAsArray()
        for _,p in pairs(players_in_realm) do
            local p_obj = minetest.get_player_by_name(p)
            if p_obj then
                realm:ApplyPrivileges(p_obj)
                realm:ApplySkybox(p_obj)
                realm:ApplyMusic(p_obj)
            end
        end
        minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Classroom updated!"))
    end
end

function mc_teacher.timeout(player)
    local pmeta = player and player:is_player() and player:get_meta()
    if pmeta then
        local realm = Realm.GetRealmFromPlayer(player) or {ID = 0}
        local spawn = mc_worldManager.GetSpawnRealm()
        if realm.ID ~= spawn.ID then
            mc_core.temp_unfreeze_and_run(player, spawn.TeleportPlayer, spawn, player)
        end
	    pmeta:set_string("mc_teacher:timeout", minetest.serialize(true))
    end
end

function mc_teacher.end_timeout(player)
    local pmeta = player and player:is_player() and player:get_meta()
    if pmeta then
	    pmeta:set_string("mc_teacher:timeout", "")
    end
end

function mc_teacher.is_in_timeout(player)
    if not player or not player:is_player() then
        return false
    end

    local pmeta = player:get_meta()
    local timeout_str = pmeta:get("mc_teacher:timeout")

    if not timeout_str or timeout_str == "" then
        return false
    end

    return minetest.deserialize(timeout_str) or false
end

function mc_teacher.get_player_tab_groups(player)
    local pmeta = player and player:is_player() and player:get_meta()
    return pmeta and minetest.deserialize(pmeta:get("mc_teacher:groups")) or {}
end

function mc_teacher.get_group_index(group_id)
    return tonumber(group_id or mc_teacher.PTAB.N) - mc_teacher.PTAB.N
end

function mc_teacher.get_realm_prefix(realm, category)
    if not realm or not category then
        return ""
    elseif category == mc_teacher.R.CAT_MAP[mc_teacher.R.CAT_KEY.INSTANCED] then
        local raw_owners = realm:GetOwners() or {}
        local owners = {}
        for p,_ in pairs(raw_owners) do
            table.insert(owners, p)
        end
        if next(owners) then
            return "["..table.concat(owners, ", ").."] "
        else
            return ""
        end
    elseif category == mc_teacher.R.CAT_MAP[mc_teacher.R.CAT_KEY.SPAWN] then
        return "[SPAWN] "
    else
        return ""
    end
end

---Audience utilities (mc_teacher.create_audience, find_audience_center, place_player_if_pos_clear) adapted from actions.lua in rubenwardy's classroom mod
---@see https://gitlab.com/rubenwardy/classroom/-/blob/master/actions.lua
---@license MIT: https://gitlab.com/rubenwardy/classroom/-/blob/1e7b11f824c03c882d74d5079d8275f3e297adea/LICENSE.txt

local function find_audience_center(start, direction)
    local endp = vector.add(start, vector.multiply(direction, 10))
    local rc = minetest.raycast(start, endp, false, true)
    local first = rc:next()
    if first then
        return vector.subtract(first.under, direction)
    else
        return endp
    end
end

local function place_player_if_pos_clear(player, pos, realm, face_pos)
    -- Move down to ground
    local rc = minetest.raycast(pos, vector.add(pos, { x = 0, y = -20, z = 0 }), false, true)
    local first = rc:next()
    if first then
        pos = vector.add(first.under, { x = 0, y = 1, z = 0 })
    end

    -- Check teacher is visible and audience position is within realm
    if not minetest.line_of_sight(pos, face_pos) or not realm:ContainsCoordinate(pos) then
        return false
    end

    mc_core.temp_unfreeze_and_run(player, function()
        realm:TeleportPlayer(player)
        player:set_pos(pos)
        local delta = vector.subtract(face_pos, pos)
        player:set_look_horizontal(math.atan2(delta.z, delta.x) - math.pi / 2)
    end)
    return true
end

function mc_teacher.create_audience(players, realm, focus_pname, focus_pos, direction)
    local center = find_audience_center(focus_pos, direction)
    local dir_perp = vector.normalize(vector.new(direction.z, direction.y, -direction.x))
    local row = 0
    local raw_column = 0
    local is_single_row = #players <= 5

    while #players > 0 do
        local p = table.remove(players, #players)
        local p_obj = minetest.get_player_by_name(p)
        if p ~= focus_pname and realm:Joinable(p_obj) then
            -- calculate player position
            local column = math.floor(raw_column / 2) * ((raw_column % 2) * 2 - 1) + raw_column % 2
            local delta = vector.add(vector.multiply(direction, row), vector.multiply(dir_perp, column))
            local pos = vector.add(center, delta)
            if not place_player_if_pos_clear(p_obj, pos, realm, focus_pos) then
                table.insert(players, p)
            end
            -- adjust position variables
            row = is_single_row and row or ((row + 1) % 2)
            if row ~= 1 then
                raw_column = raw_column + 1
            end
            if raw_column >= 200 and raw_column % 100 == 1 then
                is_single_row = true
                row = math.floor(raw_column / 100)
            end
            if row > 10 then
                return false
            end
        end
    end
    return true
end
