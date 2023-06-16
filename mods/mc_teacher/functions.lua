function mc_teacher.shutdown_server(reconnect)
    minetest.request_shutdown("Server is undergoing a scheduled restart. Please try to reconnect after one minute.", reconnect, 0)
end

function mc_teacher.cancel_shutdown()
    if mc_teacher.restart_scheduled then
        for _,timer in pairs(mc_teacher.restart_scheduled) do
            timer:cancel()
        end
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
        context.selected_privs = {interact = "true", shout = "true", fast = "true"}
        context.selected_privs_mode = mc_teacher.TABS.CLASSROOMS
    elseif context.tab == mc_teacher.TABS.PLAYERS and context.selected_privs_mode ~= mc_teacher.TABS.PLAYERS then
        context.selected_privs = {}
        context.selected_privs_mode = mc_teacher.TABS.PLAYERS
    end
end

function mc_teacher.register_teacher(player)
    local pname = (type(player) == "string" and player) or (player:is_player() and player:get_player_name())
    if pname then
        mc_teacher.teachers[pname] = true
        mc_teacher.students[pname] = nil
    end
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
    end
end