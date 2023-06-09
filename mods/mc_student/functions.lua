function mc_student.get_fs_context(player)
	local pname = (type(player) == "string" and player) or (player:is_player() and player:get_player_name()) or ""
	if not mc_student.fs_context[pname] then
		mc_student.fs_context[pname] = {
			tab = mc_student.TABS.OVERVIEW,
			playerscroll = 0,
			selected_realm = nil,
			selected_coord = nil
		}
	end
	return mc_student.fs_context[pname]
end
