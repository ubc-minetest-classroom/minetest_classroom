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
    if not privs["student"] then
        return mc_teacher.ROLES.NONE
    elseif not privs["teacher"] then
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
            if context.edit_realm.type == mc_teacher.R.CAT_KEY.SPAWN then
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

        -- update players in realm
        local players_in_realm = realm:GetPlayersAsArray()
        for _,p in pairs(players_in_realm) do
            local p_obj = minetest.get_player_by_name(p)
            if p_obj then
                realm:ApplyPrivileges(p_obj)
            end
        end
        minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Classroom updated!"))
    end
end