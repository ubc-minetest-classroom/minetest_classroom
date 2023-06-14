function mc_teacher.shutdown_server(reconnect)
    minetest.request_shutdown("Server is undergoing a scheduled restart. Please try to reconnect after one minute.",reconnect,0)
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