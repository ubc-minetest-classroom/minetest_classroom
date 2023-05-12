-- Student joins/leaves
minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()
	if not minetest.check_player_privs(player, { teacher = true }) then
		mc_student.students[pname] = true
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
	if mc_student.markers[pname] then
		mc_student.markers[pname].timer:cancel()
		mc_student.markers[pname] = nil
	end
	if not minetest.check_player_privs(player, { teacher = true }) then
		mc_student.students[pname] = nil
	end
end)

-- Log all direct messages
minetest.register_on_chatcommand(function(name, command, params)
	if command == "msg" then
		-- For some reason, the params in this callback is a string rather than a table; need to parse the player name
		local params_table = mc_core.split(params, " ")
		local to_player = params_table[1]
		if minetest.get_player_by_name(to_player) then
			local message = string.sub(params, #to_player+2, #params)
			local key = tostring(os.date("%d-%m-%Y %H:%M:%S"))
			local directmessages = minetest.deserialize(mc_student.meta:get_string("direct_messages"))
			if directmessages then
				local playermessages = directmessages[name]
				if playermessages then
					local toplayermessages = playermessages[to_player]
					if toplayermessages then
						toplayermessages[key] = message
						playermessages[to_player] = toplayermessages
						directmessages[name] = playermessages
					else
						local newtoplayer = {
							[key] = message
						}
						playermessages[to_player] = newtoplayer
						directmessages[name] = playermessages
					end
				else
					directmessages[name] = {
						[to_player] = {
							[key] = message
						}
					}
				end
			else
				directmessages = {
					[name] = {
						[to_player] = {
							[key] = message
						}
					}
				}
			end
			mc_student.meta:set_string("direct_messages", minetest.serialize(directmessages))
		else
			-- Submitted name is not a player, probably a typo, do not log
			return
		end
	end
end)

-- Log all chat messages
minetest.register_on_chat_message(function(name, message)
	local key = tostring(os.date("%d-%m-%Y %H:%M:%S"))
	local chatmessages = minetest.deserialize(mc_student.meta:get_string("chat_messages"))
	if chatmessages then
		local playermessages = chatmessages[name]
		if playermessages then
			playermessages[key] = message
			chatmessages[name] = playermessages
		else
			chatmessages[name] = {
				[key] = message
			}
		end
	else
		chatmessages = {
			[name] = {
				[key] = message
			}
		}
	end
	mc_student.meta:set_string("chat_messages", minetest.serialize(chatmessages))
end)

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
		if fields.record and fields.note ~= "" then
			mc_student.record_coordinates(player,fields.note)
			mc_student.show_notebook_fs(player, mc_student.TABS.MAP)
		elseif fields.mark then
			if not context.selected_coord then context.selected_coord = 1 end
			local pdata = minetest.deserialize(pmeta:get_string("coordinates"))
			local realm = Realm.GetRealmFromPlayer(player)
			local ids, coords, notes = {}, {}, {}
			for i in pairs(pdata.realms) do
				if tonumber(pdata.realms[i]) == tonumber(realm.ID) then
					table.insert(coords,pdata.coords[i])
					table.insert(notes,pdata.notes[i])
				end
			end
			mc_student.queue_marker(player, notes[context.selected_coord], coords[context.selected_coord])
			return
		elseif fields.coordlist then
			local event = minetest.explode_textlist_event(fields.coordlist)
			if event.type == "CHG" then
				context.selected_coord = event.index
			end
		elseif fields.classroomlist then
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
				minetest.chat_send_player(player:get_player_name(),minetest.colorize("#FF00FF","[Minetest Classroom] The classroom you requested is no longer available. Return to the Classroom tab on your dashboard to view the current list of available classrooms."))
			end
			mc_student.show_notebook_fs(player, mc_student.TABS.CLASSROOMS)
		elseif fields.go then
			if not context.selected_coord then context.selected_coord = 1 end
			local pdata = minetest.deserialize(pmeta:get_string("coordinates"))
			local realm = Realm.GetRealm(pdata.realms[context.selected_coord])
			if realm then
				if realm:getCategory().joinable(realm,player) then
					realm:TeleportPlayer(player)
					player:set_pos(pdata.coords[context.selected_coord])
				else
					minetest.chat_send_player(player:get_player_name(), minetest.colorize("#FF00FF","[Minetest Classroom] You no longer have access to this classroom."))
				end
			else
				minetest.chat_send_player(player:get_player_name(), minetest.colorize("#FF00FF","[Minetest Classroom] This classroom no longer exists."))
			end
			mc_student.show_notebook_fs(player, mc_student.TABS.MAP)
		elseif fields.delete then
			if not context.selected_coord then context.selected_coord = 1 end
			local pdata = minetest.deserialize(pmeta:get_string("coordinates"))
			if pdata then
				local newData, newCoords, newNotes, newRealms = {}, {}, {}, {}	
				if #(pdata.coords) > 1 then
					for i,coord in ipairs(pdata.coords) do
						if i ~= context.selected_coord then
							table.insert(newCoords, coord)
							table.insert(newNotes, pdata.notes[i])
							table.insert(newRealms, pdata.realms[i])
						end
					end
					newData = {coords = newCoords, notes = newNotes, realms = newRealms}
				else
					newData = nil
				end
				pmeta:set_string("coordinates", minetest.serialize(newData))
			end
			mc_student.show_notebook_fs(player, mc_student.TABS.MAP)
		elseif fields.clear then
			local pdata = minetest.deserialize(pmeta:get_string("coordinates"))
			if pdata then
				if pdata.realms then
					local newData, newCoords, newNotes, newRealms = {}, {}, {}, {}	
					for i,_ in pairs(pdata.realms) do
						local coordrealm = Realm.GetRealm(pdata.realms[i])
						local realm = Realm.GetRealmFromPlayer(player)
						if realm and coordrealm and coordrealm.ID ~= realm.ID then
							table.insert(newCoords, pdata.coords[i])
							table.insert(newNotes, pdata.notes[i])
							table.insert(newRealms, pdata.realms[i])
						end
					end
					if newCoords then
						newData = {coords = newCoords, notes = newNotes, realms = newRealms}
					else
						newdata = nil
					end
					pmeta:set_string("coordinates", minetest.serialize(newData))
				end
			end
			mc_student.show_notebook_fs(player, mc_student.TABS.MAP)
		elseif fields.share then
			local pdata = minetest.deserialize(pmeta:get_string("coordinates"))
			local realm = Realm.GetRealmFromPlayer(player)
			local ids, coords, notes = {}, {}, {}
			for i in pairs(pdata.realms) do
				if tonumber(pdata.realms[i]) == tonumber(realm.ID) then
					table.insert(coords,pdata.coords[i])
					table.insert(notes,pdata.notes[i])
				end
			end
			if not context.selected_coord or context.selected_coord > #coords then context.selected_coord = 1 end 
			for _,connplayer in pairs(minetest.get_connected_players()) do 
				local connRealm = Realm.GetRealmFromPlayer(connplayer)
				if connRealm.ID == realm.ID then
					local pos = coords[context.selected_coord]
					minetest.chat_send_player(connplayer:get_player_name(),minetest.colorize("#FF00FF","[Minetest Classroom] "..player:get_player_name().." shared location {x="..tostring(math.round(pos.x-realm.StartPos.x))..", y="..tostring(math.round(pos.y-realm.StartPos.y))..", z="..tostring(math.round(pos.z-realm.StartPos.z)).."} with the note: "..notes[context.selected_coord]))
				end
			end
			mc_student.show_notebook_fs(player, mc_student.TABS.MAP)
		elseif fields.submitreport then
			if not fields.report or fields.report == "" then
				minetest.chat_send_player(player:get_player_name(),minetest.colorize("#FF00FF","[Minetest Classroom] Please add a message to your report."))
				return
			end
			local pname = player:get_player_name()
			local pos = player:get_pos()
			local realm = Realm.GetRealmFromPlayer(player)
			local clean_report = minetest.formspec_escape(fields.report)
			local msg = pname .. " reported: " .. clean_report
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
			if count > 0 then
				local msg = "[Minetest Classroom] " .. msg .. " (teachers online: " .. teachers .. ")"
				-- Send report to any teacher currently connected
				for teacher in pairs(mc_teacher.teachers) do
					minetest.chat_send_player(teacher, minetest.colorize("#FF00FF", msg.. " [Details:" .. tostring(os.date("%d-%m-%Y %H:%M:%S")) .. " {x="..tostring(pos.x)..", y="..tostring(pos.y)..", z="..tostring(pos.z).."} realmID="..tostring(realm.ID).."]"))
				end
			end
			local key = pname .. " " .. tostring(os.date("%d-%m-%Y %H:%M:%S")) .. " {x="..tostring(pos.x)..", y="..tostring(pos.y)..", z="..tostring(pos.z).."} realmID="..tostring(realm.ID)
			local reports = minetest.deserialize(mc_student.meta:get_string("reports"))
			if reports then
				reports[key] = clean_report
			else
				reports = {
					[key] = clean_report
				}
			end
			mc_student.meta:set_string("reports", minetest.serialize(reports))
			chatlog.write_log(pname,"[REPORT] " .. clean_report)
			minetest.chat_send_player(player:get_player_name(),minetest.colorize("#FF00FF","[Minetest Classroom] Your report has been received."))
			mc_student.show_notebook_fs(player, mc_student.TABS.HELP)
		elseif fields.classrooms then
			mc_student.show_notebook_fs(player, mc_student.TABS.CLASSROOMS)
		elseif fields.map then
			mc_student.show_notebook_fs(player, mc_student.TABS.MAP)
		elseif fields.appearance then
			mc_student.show_notebook_fs(player, mc_student.TABS.APPEARANCE)
		elseif fields.help then
			mc_student.show_notebook_fs(player, mc_student.TABS.HELP)
		elseif fields.utmcoords then
            local pmeta = player:get_meta()
            pmeta:set_string("positionHudMode", "utm")
		elseif fields.latloncoords then
			local pmeta = player:get_meta()
            pmeta:set_string("positionHudMode", "latlong")
		elseif fields.classroomcoords then
			local pmeta = player:get_meta()
            pmeta:set_string("positionHudMode", "local")
		elseif fields.coordsoff then
			local pmeta = player:get_meta()
			pmeta:set_string("positionHudMode", "")
            mc_worldManager.RemoveHud(player)
		else
			-- Unhandled input
			return
		end
	end
end)