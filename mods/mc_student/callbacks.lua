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
            context.tab = fields.record_nav
            mc_student.show_notebook_fs(player, context.tab)
		end
		if fields.default_tab then
			pmeta:set_string("default_student_tab", context.tab)
			mc_student.show_notebook_fs(player, context.tab)
		end

		if fields.submitreport then
			if not fields.report or fields.report == "" then
				minetest.chat_send_player(player:get_player_name(),minetest.colorize(mc_core.col.log, "[Minetest Classroom] Please add a message to your report."))
				return
			end

			local pname = player:get_player_name() or "unknown"
			local pos = player:get_pos() or {x = 0, y = 0, z = 0}
			local realm = Realm.GetRealmFromPlayer(player) or {Name = "Unknown", ID = 0}
			local clean_report = minetest.formspec_escape(fields.report)
			local report_type = fields.reporttype or "Other"
			local timestamp = tostring(os.date("%Y-%m-%d %H:%M:%S"))

			if next(mc_teacher.teachers) ~= nil then
				local details = "  DETAILS: "
				if realm.ID ~= 0 then
					local loc = {
						x = tostring(math.round(pos.x - realm.StartPos.x)),
						y = tostring(math.round(pos.y - realm.StartPos.y)),
						z = tostring(math.round(pos.z - realm.StartPos.z)),
					}
					details = details.."Realm #"..realm.ID.." ("..realm.Name..") at position (x="..loc.x..", y="..loc.y..", z="..loc.z..")"
				else
					details = details.."Unknown realm at position (x="..pos.x..", y="..pos.y..", z="..pos.z..")"
				end
				for teacher,_ in pairs(mc_teacher.teachers) do
					minetest.chat_send_player(teacher, minetest.colorize(mc_core.col.log, table.concat({
						"[Minetest Classroom] NEW REPORT: ", timestamp, " by ", pname, "\n",
						"  ", string.upper(report_type), ": ", fields.report, "\n", details,
					})))
				end
			else
				local report_reminder = mc_teacher.meta:get_int("report_reminder")
				report_reminder = report_reminder + 1
				mc_teacher.meta:set_int("report_reminder", report_reminder)
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

-- report log converter
local function reformat_report_key(key)
	local day, month, year, hour, min, sec = string.match(key, "(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)")
    return day and table.concat({year, "-", month, "-", day, " ", hour, ":", min, ":", sec}) or key
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
				timestamp = reformat_report_key(key),
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

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()
	if pname then
		mc_student.fs_context[pname] = nil
	end
end)