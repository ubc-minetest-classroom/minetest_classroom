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
        if fields.default_tab then
			pmeta:set_string("default_teacher_tab",mc_teacher.fs_context.tab)
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

        ---------------------------------
        -- MANAGE CLASSROOMS
        ---------------------------------
        if fields.mode then
            if fields.realmname then mc_teacher.fs_context.realmname = minetest.formspec_escape(fields.realmname) end
            if fields.mode ~= "1" then
                mc_teacher.fs_context.selectedMode = fields.mode
                mc_teacher.show_controller_fs(player,"2")
            else
                mc_teacher.fs_context.selectedMode = "1"
                mc_teacher.show_controller_fs(player,"2")
            end
        elseif fields.schematic then
            if fields.realmname then mc_teacher.fs_context.realmname = minetest.formspec_escape(fields.realmname) end
            mc_teacher.fs_context.selectedMode = "3"
            mc_teacher.fs_context.selectedSchematicIndex = fields.schematic
            mc_teacher.show_controller_fs(player,"2")
        elseif fields.realterrain then
            if fields.realmname then mc_teacher.fs_context.realmname = minetest.formspec_escape(fields.realmname) end
            mc_teacher.fs_context.selectedMode = "4"
            mc_teacher.fs_context.selectedDEMIndex = fields.realterrain
            mc_teacher.show_controller_fs(player,"2")
        end

        if fields.requestrealm then
            if mc_helpers.checkPrivs(player,{teacher = true}) then
                local realmName, realmSizeX, realmSizeZ, realmSizeY
                if fields.realmname == "" or fields.realmname == nil then realmName = "Unnamed Classroom" else realmName = fields.realmname end
                if mc_teacher.fs_context.selectedMode == "2" then
                    -- Sanitize input
                    if mc_helpers.checkPrivs(player,{server = true}) then
                        if tonumber(fields.realmxsize) and tonumber(fields.realmxsize) >= 80 then
                            realmSizeX = tonumber(fields.realmxsize)
                        else
                            minetest.chat_send_player(player:get_player_name(),minetest.colorize("#FF00FF","[Minetest Classroom] You may only request classrooms with a width of at least 80 nodes. Check your input and try again."))
                        end
                        if tonumber(fields.realmzsize) and tonumber(fields.realmzsize) >= 80 then
                            realmSizeZ = tonumber(fields.realmzsize)
                        else
                            minetest.chat_send_player(player:get_player_name(),minetest.colorize("#FF00FF","[Minetest Classroom] You may only request classrooms with a height of at least 80 nodes. Check your input and try again."))
                        end
                        if tonumber(fields.realmysize) and tonumber(fields.realmysize) >= 80 then
                            realmSizeY = tonumber(fields.realmysize)
                        else
                            minetest.chat_send_player(player:get_player_name(),minetest.colorize("#FF00FF","[Minetest Classroom] You may only request classrooms with a length of at least 80 nodes. Check your input and try again."))
                        end
                    else
                        if tonumber(fields.realmxsize) and tonumber(fields.realmxsize) >= 80 and tonumber(fields.realmxsize) <= 240 then
                            realmSizeX = tonumber(fields.realmxsize)
                        else
                            minetest.chat_send_player(player:get_player_name(),minetest.colorize("#FF00FF","[Minetest Classroom] You may only request classrooms with a width between 80 and 240 nodes. Check your input and try again."))
                        end
                        if tonumber(fields.realmzsize) and tonumber(fields.realmzsize) >= 80 and tonumber(fields.realmzsize) <= 240 then
                            realmSizeZ = tonumber(fields.realmzsize)
                        else
                            minetest.chat_send_player(player:get_player_name(),minetest.colorize("#FF00FF","[Minetest Classroom] You may only request classrooms with a height between 80 and 240 nodes. Check your input and try again."))
                        end
                        if tonumber(fields.realmysize) and tonumber(fields.realmysize) >= 80 and tonumber(fields.realmysize) <= 240 then
                            realmSizeY = tonumber(fields.realmysize)
                        else
                            minetest.chat_send_player(player:get_player_name(),minetest.colorize("#FF00FF","[Minetest Classroom] You may only request classrooms with a length between 80 and 240 nodes. Check your input and try again."))
                        end
                    end
                    if realmName and realmSizeX and realmSizeZ and realmSizeY then
                        local newRealm = Realm:New(realmName, { x = realmSizeX, y = realmSizeY, z = realmSizeZ })
                        newRealm:CreateGround()
                        newRealm:CreateBarriersFast()
                        newRealm:set_data("owner", player:get_player_name())
                        minetest.chat_send_player(player:get_player_name(),minetest.colorize("#FF00FF","[Minetest Classroom] Your requested classroom was successfully created."))
                    end
                    mc_teacher.show_controller_fs(player,"2")
                elseif mc_teacher.fs_context.selectedMode == "3" and mc_teacher.fs_context.selectedSchematicIndex then
                    local counter = 1
                    for schematicKey,_ in pairs(schematicManager.schematics) do
                        counter = counter + 1
                        if tonumber(mc_teacher.fs_context.selectedSchematicIndex) == counter then 
                            local newRealm = Realm:NewFromSchematic(realmName, schematicKey)
                        end 
                    end
                    minetest.chat_send_player(player:get_player_name(),minetest.colorize("#FF00FF","[Minetest Classroom] Your requested classroom was successfully created."))
                    mc_teacher.show_controller_fs(player,"2")
                elseif mc_teacher.fs_context.selectedMode == "4" and mc_teacher.fs_context.selectedDEMIndex then
                    local counter = 1
                    for DEMKey,_ in pairs(realterrainManager.dems) do 
                        counter = counter + 1
                        if tonumber(mc_teacher.fs_context.selectedDEMIndex) == counter then 
                            local newRealm = Realm:NewFromDEM(realmName, DEMKey)
                        end 
                    end
                    minetest.chat_send_player(player:get_player_name(),minetest.colorize("#FF00FF","[Minetest Classroom] Your requested classroom was successfully created."))
                    mc_teacher.show_controller_fs(player,"2")
                else
                    -- missing information to process the request
                end
            end
        end

        if fields.classroomlist then
            local event = minetest.explode_textlist_event(fields.classroomlist)
            if event.type == "CHG" then
                -- We should not use the index here because the realm could be deleted while the formspec is active
                -- So return the actual realm.ID to avoid unexpected behaviour
                local counter = 0
                for _,thisRealm in pairs(Realm.realmDict) do
                    if mc_helpers.checkPrivs(player,{teacher = true}) then
                        counter = counter + 1
                        if counter == tonumber(event.index) then
                            selectedRealmID = thisRealm.ID
                        end
                    end
                end
                mc_teacher.show_controller_fs(player,"2")
            end
        elseif fields.teleportrealm then
			-- Still a remote possibility that the realm is deleted in the time that the callback is executed
			-- So always check that the requested realm exists and the realm category allows the player to join
			-- Check that the player selected something from the textlist, otherwise default to spawn realm
			if not selectedRealmID then selectedRealmID = mc_worldManager.spawnRealmID end
			local realm = Realm.GetRealm(tonumber(selectedRealmID))
			if realm then
				realm:TeleportPlayer(player)
				selectedRealmID = nil
			else
				minetest.chat_send_player(player:get_player_name(),minetest.colorize("#FF00FF","[Minetest Classroom] The classroom you requested is no longer available. Return to the Classroom tab on your dashboard to view the current list of available classrooms."))
			end
			mc_teacher.show_controller_fs(player,"2")
        elseif fields.deleterealm then
            local realm = Realm.GetRealm(tonumber(selectedRealmID))
            if realm and tonumber(selectedRealmID) ~= mc_worldManager.spawnRealmID then realm:Delete() end
            mc_teacher.show_controller_fs(player,"2")
        end

        if fields.music then
            mc_teacher.fs_context.selectedMusic = fields.music
            -- local background_sound = 
            -- play music as sample
            minetest.sound_play(backgroundSound, {
                to_player = player:get_player_name(),
                gain = 1,
                object = player,
                loop = false })
            mc_teacher.show_controller_fs(player,"2")
        end

        ---------------------------------
        -- MODERATOR
        ---------------------------------
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
        end

        -- MANAGE SERVER
        if fields.submitmessage then
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