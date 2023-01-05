-- Privileges
minetest.register_privilege("teacher", {
    give_to_singleplayer = false
})

minetest.register_on_priv_grant(function(name, granter, priv)
    if priv == "teacher" then
        mc_teacher.teachers[name] = true
    end
end)

minetest.register_on_priv_revoke(function(name, revoker, priv)
    if priv == "teacher" then
        mc_teacher.teachers[name] = nil
    end
end)

-- Teacher joins/leaves
minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()
	if minetest.check_player_privs(player, { teacher = true }) then
		mc_teacher.teachers[pname] = true
        local teachers = ""
        local count = 0
        for teacher,_ in pairs(mc_teacher.teachers) do
            if count == #mc_teacher.teachers then
                teachers = teachers .. teacher
            else
                teachers = teachers .. teacher .. ", "
            end
            count = count + 1
        end
        if count > 0 then minetest.chat_send_player(pname, minetest.colorize("#FF00FF", "[Minetest Classroom] Teachers currently online: "..teachers)) end
    end
end)

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()
	if minetest.check_player_privs(player, { teacher = true }) then
		mc_teacher.teachers[pname] = nil
	else
		mc_teacher.students[pname] = nil
	end
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local pmeta = player:get_meta()

	if string.sub(formname, 1, 10) ~= "mc_teacher" then
		return false
	end

	local wait = os.clock()
	while os.clock() - wait < 0.05 do end --popups don't work without this

	if formname == "mc_teacher:controller_fs" then
		if fields.record_nav then
            mc_teacher.fs_context.tab = fields.record_nav
            mc_teacher.show_controller_fs(player,mc_teacher.fs_context.tab)
		end
        if fields.playerlist then
			local event = minetest.explode_textlist_event(fields.playerlist)
			if event.type == "CHG" then
				mc_teacher.fs_context.chat_player_index = event.index
                mc_teacher.show_controller_fs(player,"4")
			end
        end
        if fields.playerchatlist then
			local event = minetest.explode_textlist_event(fields.playerchatlist)
			if event.type == "CHG" then
				mc_teacher.fs_context.chat_index = event.index
                mc_teacher.show_controller_fs(player,"4")
			end
        end
		if fields.default_tab then
			pmeta:set_string("default_teacher_tab",mc_teacher.fs_context.tab)
			mc_teacher.show_controller_fs(player,mc_teacher.fs_context.tab)
		end
		if fields.clearlog then
            local chatmessages = minetest.deserialize(mc_student.meta:get_string("chat_messages"))
            local directmessages = minetest.deserialize(mc_student.meta:get_string("direct_messages"))
            local pname = mc_teacher.fs_context.indexed_chat_players[tonumber(mc_teacher.fs_context.chat_player_index)]
            if directmessages then
                local player_dm_log = directmessages[pname]
                if player_dm_log then
                    for to_player,_ in pairs(player_dm_log) do
                        local to_player_dms = player_dm_log[to_player]
                        for key,_ in pairs(to_player_dms) do
                            to_player_dms[key] = nil
                        end
                        player_dm_log[to_player] = to_player_dms
                    end
                    directmessages[pname] = player_dm_log
                end
                directmessages[pname] = {}
                if directmessages[pname] then directmessages[pname] = nil end
            end
            if chatmessages then
                local player_chat_log = chatmessages[pname]
                if player_chat_log then
                    for key,_ in pairs(player_chat_log) do
                        player_chat_log[key] = nil
                    end
                    chatmessages[pname] = player_chat_log
                end
                chatmessages[pname] = {}
                if chatmessages[pname] then chatmessages[pname] = nil end
            end
            mc_student.meta:set_string("chat_messages", minetest.serialize(chatmessages))
            mc_student.meta:set_string("direct_messages", minetest.serialize(directmessages))
            mc_teacher.show_controller_fs(player,"4")
        elseif fields.deletemessage then
            -- TODO: delete a specific message
            mc_teacher.show_controller_fs(player,"4")
        elseif fields.submitmessage then
            minetest.chat_send_all(minetest.colorize("#FF00FF","[Minetest Classroom] "..fields.servermessage))
			mc_teacher.show_controller_fs(player,"5")
        elseif fields.submitsched then
            if mc_teacher.restart_scheduled.timer then mc_teacher.restart_scheduled.timer:cancel() end
            local sched = {
                ["1 minute"] = 60,
                ["5 minutes"] = 300,
                ["10 minutes"] = 600,
                ["15 minutes"] = 900,
                ["30 minutes"] = 1800,
                ["1 hour"] = 3600,
                ["6 hours"] = 21600,
                ["12 hours"] = 43200,
                ["24 hours"] = 86400}
            local time = sched[fields.time]
            mc_teacher.restart_scheduled.timer = minetest.after(time,mc_teacher.shutdown_server,true)
        elseif fields.submitshutdown then
            if mc_teacher.restart_scheduled.timer then mc_teacher.restart_scheduled.timer:cancel() end
            mc_teacher.shutdown_server(true)
        elseif fields.addip then
            if fields.ipstart then
                if not fields.ipend or fields.ipend == "Optional" or fields.ipend == "" then
                    networking.modify_ipv4(player,fields.ipstart,nil,true)
                else
                    networking.modify_ipv4(player,fields.ipstart,fields.ipend,true)
                end
            end
            mc_teacher.show_controller_fs(player,"5")
        elseif fields.removeip then
            if fields.ipstart then
                if not fields.ipend or fields.ipend == "Optional" or fields.ipend == "" then
                    networking.modify_ipv4(player,fields.ipstart,nil,nil)
                else
                    networking.modify_ipv4(player,fields.ipstart,fields.ipend,nil)
                end
            end
            mc_teacher.show_controller_fs(player,"5")
        elseif fields.toggleon or fields.toggleoff then
            networking.toggle_whitelist(player)
            mc_teacher.show_controller_fs(player,"5")
        elseif fields.modifyrules then
            minetest.show_formspec(player:get_player_name(), "mc_rules:edit", mc_rules.show_edit_formspec(nil))
        else
			-- Unhandled input
			return
		end
	end
end) 