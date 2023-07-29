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
    if context.tab == mc_teacher.TABS.CLASSROOMS and context.selected_privs_mode ~= mc_teacher.TABS.CLASSROOMS then
        context.selected_privs = {interact = true, shout = true, fast = true, fly = "nil", noclip = "nil", give = "nil"}
        context.selected_privs_mode = mc_teacher.TABS.CLASSROOMS
    elseif context.tab == mc_teacher.TABS.PLAYERS and context.selected_privs_mode ~= mc_teacher.TABS.PLAYERS then
        context.selected_privs = {interact = "nil", shout = "nil", fast = "nil", fly = "nil", noclip = "nil", give = "nil"}
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

function mc_teacher.freeze(player)
    local pmeta = player and player:is_player() and player:get_meta()
    if pmeta then
	    pmeta:set_string("mc_teacher:frozen", minetest.serialize(true))
        local parent = player:get_attach()
        if parent and parent:get_luaentity() and parent:get_luaentity().set_frozen_player then
            return
        end
        local obj = minetest.add_entity(player:get_pos(), "mc_teacher:frozen_player")
        obj:get_luaentity():set_frozen_player(player)
    end
end

function mc_teacher.unfreeze(player)
    local pmeta = player and player:is_player() and player:get_meta()
    if pmeta then
	    pmeta:set_string("mc_teacher:frozen", "")

        local pname = player:get_player_name()
        local objects = minetest.get_objects_inside_radius(player:get_pos(), 2)
        for _,obj in pairs(objects) do
            local entity = obj:get_luaentity()
            if entity and entity.set_frozen_player and entity.pname == pname then
                obj:remove()
            end
        end
    end
end

function mc_teacher.is_frozen(player)
    local pmeta = player and player:is_player() and player:get_meta()
	return pmeta and minetest.deserialize(pmeta:get("mc_teacher:frozen")) or false
end