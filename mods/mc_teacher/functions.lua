function mc_teacher.shutdown_server(reconnect)
    minetest.request_shutdown("Server is undergoing a scheduled restart. Please try to reconnect after one minute.",reconnect,0)
end

function mc_teacher.get_fs_context(player)
	local pname = (type(player) == "string" and player) or (player:is_player() and player:get_player_name()) or ""
	if not mc_teacher.fs_context[pname] then
		mc_teacher.fs_context[pname] = {
			tab = mc_teacher.TABS.OVERVIEW,
            selected_mode = "1",
			selected_privs = {interact = "true", shout = "true", fast = "true"},
		}
	end
	return mc_teacher.fs_context[pname]
end