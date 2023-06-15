minetest.register_on_player_receive_fields(function(player, formname, fields)
	local pmeta = player:get_meta()
	local context = mc_student.get_fs_context(player)

	if string.sub(formname, 1, 10) ~= "mc_student" then
		return false
	end

	local wait = os.clock()
	while os.clock() - wait < 0.05 do end --popups don't work without this

	if formname == "mc_student:notebook_fs" then
		if fields.record_nav then
            mc_student.fs_context.tab = fields.record_nav
            mc_student.show_notebook_fs(player, mc_student.fs_context.tab)
		end
		if fields.default_tab then
			pmeta:set_string("default_student_tab", mc_student.fs_context.tab)
			mc_student.show_notebook_fs(player, mc_student.fs_context.tab)
		end
		if fields.realms then
			local event = minetest.explode_textlist_event(fields.realms)
			if event.type == "CHG" then
				selectedClassroom = event.index
			end
		elseif fields.join then
			local realm = classroomRealms[selectedClassroom]
			realm:TeleportPlayer(player)
		end

		if fields.classroomlist then
			local event = minetest.explode_textlist_event(fields.classroomlist)
			if event.type == "CHG" then
				-- We should not use the index here because the realm could be deleted while the formspec is active
				-- So return the actual realm.ID to avoid unexpected behaviour
				local counter = 0
				for _,thisRealm in pairs(Realm.realmDict) do
					if mc_core.checkPrivs(player,{teacher = true}) then
						counter = counter + 1
						if counter == tonumber(event.index) then
							context.selected_realm = thisRealm.ID
						end
					else
						counter = counter + 1
						-- check the category
						local realmCategory = thisRealm:getCategory()
						local joinable, reason = realmCategory.joinable(thisRealm, player)
						if joinable then
							if counter == tonumber(event.index) then
								context.selected_realm = thisRealm.ID
							end
						end
					end
				end
				mc_student.show_notebook_fs(player, mc_student.TABS.CLASSROOMS)
			end
		elseif fields.teleportrealm then
			-- Still a remote possibility that the realm is deleted in the time that the callback is executed
			-- So always check that the requested realm exists and the realm category allows the player to join
			-- Check that the player selected something from the textlist, otherwise default to spawn realm
			if not context.selected_realm then context.selected_realm = mc_worldManager.spawnRealmID end
			local realm = Realm.GetRealm(tonumber(context.selected_realm))
			if realm then
				realm:TeleportPlayer(player)
				context.selected_realm = nil
			else
				minetest.chat_send_player(player:get_player_name(),minetest.colorize(mc_core.col.log, "[Minetest Classroom] The classroom you requested is no longer available. Return to the Classroom tab on your dashboard to view the current list of available classrooms."))
			end
			mc_student.show_notebook_fs(player, mc_student.TABS.CLASSROOMS)
		elseif fields.submitreport then
			if not fields.report or fields.report == "" then
				minetest.chat_send_player(player:get_player_name(),minetest.colorize(mc_core.col.log, "[Minetest Classroom] Please add a message to your report."))
				return
			end

			local pname = player:get_player_name() or "unknown"
			local pos = player:get_pos() or {x = 0, y = 0, z = 0}
			local realm = Realm.GetRealmFromPlayer(player) or {ID = 0}
			local clean_report = minetest.formspec_escape(fields.report)
			local report_type = fields.reporttype or "Other"
			local timestamp = tostring(os.date("%Y-%m-%d %H:%M:%S"))

			for teacher,_ in pairs(mc_teacher.teachers) do
				minetest.chat_send_player(teacher, minetest.colorize(mc_core.col.log, table.concat({
					"[Minetest Classroom] NEW REPORT: ", timestamp, " by ", pname, "\n",
					"  ", string.upper(report_type), ": ", fields.report, "\n",
					"  DETAILS: Realm #", realm.ID, " at position (x=", pos.x, ", y=", pos.y, ", z=", pos.z, ")"
				})))
			end

			local reports = minetest.deserialize(mc_teacher.meta:get_string("report_log")) or {}
			table.insert(reports, {
				player = pname,
				timestamp = timestamp,
				pos = pos,
				realm = realm.ID,
				message = clean_report,
				type = report_type
			})
			mc_teacher.meta:set_string("report_log", minetest.serialize(reports))

			chatlog.write_log(pname, "[REPORT] " .. clean_report)
			minetest.chat_send_player(player:get_player_name(),minetest.colorize(mc_core.col.log, "[Minetest Classroom] Your report has been received."))
			mc_student.show_notebook_fs(player, mc_student.TABS.HELP)
		elseif fields.classrooms then
			mc_student.show_notebook_fs(player, mc_student.TABS.CLASSROOMS)
		elseif fields.map then
			mc_student.show_notebook_fs(player, mc_student.TABS.MAP)
		elseif fields.appearance then
			mc_student.show_notebook_fs(player, mc_student.TABS.APPEARANCE)
		elseif fields.help then
			mc_student.show_notebook_fs(player, mc_student.TABS.HELP)
		end
	end
end)

-- message log converter
local function reformat_chat_key(key)
	local month, day, year, hour, min, sec = string.match(key, "(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)")
    return month and table.concat({year, "-", month, "-", day, " ", hour, ":", min, ":", sec}) or key
end

minetest.register_on_mods_loaded(function()
	local chatmessages = minetest.deserialize(mc_student.meta:get_string("chat_messages"))
	local directmessages = minetest.deserialize(mc_student.meta:get_string("direct_messages"))
	local reports = minetest.deserialize(mc_student.meta:get_string("reports"))

	if chatmessages then
		local new_chatlog = minetest.deserialize(mc_teacher.meta:get_string("chat_log")) or {}
		for pname, log in pairs(chatmessages) do 
			new_chatlog[pname] = new_chatlog[pname] or {}
			for key, message in pairs(log) do
				table.insert(new_chatlog[pname], {
					timestamp = reformat_chat_key(key),
					message = message,
				})
			end
		end

		mc_teacher.meta:set_string("chat_log", minetest.serialize(new_chatlog))
		mc_teacher.meta:set_int("chat_log_format", 2)
		mc_student.meta:set_string("chat_messages", nil)
	end

	if directmessages then
		local new_dmlog = minetest.deserialize(mc_teacher.meta:get_string("dm_log")) or {}
		for pname, log in pairs(directmessages) do 
			new_dmlog[pname] = new_dmlog[pname] or {}
			for recipient, msg_table in pairs(log) do
				for key, message in pairs(msg_table) do
					table.insert(new_dmlog[pname], {
						timestamp = reformat_chat_key(key),
						recipient = recipient,
						message = message,
					})
				end
			end
		end

		mc_teacher.meta:set_string("dm_log", minetest.serialize(new_dmlog))
		mc_teacher.meta:set_int("dm_log_format", 2)
		mc_student.meta:set_string("direct_messages", nil)
	end

	if reports then
		local new_reportlog = {} --minetest.deserialize(mc_teacher.meta:get_string("report_log")) or {}
		for key, message in pairs(reports) do
			table.insert(new_reportlog, {
				player = string.match(key, "(.+) %d+%-%d+%-%d+ %d+:%d+:%d+") or "unknown",
				timestamp = reformat_chat_key(key),
				pos = {
					x = tonumber(string.match(key, "{x=(%-?%d+%.%d*), y=%-?%d+%.%d*, z=%-?%d+%.%d*}") or "0"),
					y = tonumber(string.match(key, "{x=%-?%d+%.%d*, y=(%-?%d+%.%d*), z=%-?%d+%.%d*}") or "0"),
					z = tonumber(string.match(key, "{x=%-?%d+%.%d*, y=%-?%d+%.%d*, z=(%-?%d+%.%d*)}") or "0"),
				},
				realm = string.match(key, "realmID=(%d+)"),
				message = message,
				type = "Other",
			})
		end
		mc_teacher.meta:set_string("report_log", minetest.serialize(new_reportlog))
		mc_teacher.meta:set_int("report_log_format", 2)
		mc_student.meta:set_string("reports", nil)
	end
end)