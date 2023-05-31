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
        if count > 0 then minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Teachers currently online: "..teachers)) end
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
    local context = mc_teacher.get_fs_context(player)

	if string.sub(formname, 1, 10) ~= "mc_teacher" or not mc_core.checkPrivs(player,{teacher = true}) then
		return false
	end

	local wait = os.clock()
    local reload = false
	while os.clock() - wait < 0.05 do end --popups don't work without this

	if formname == "mc_teacher:controller_fs" then
        local has_server_privs = mc_core.checkPrivs(player, {server = true})

        -------------
        -- GENERAL --
        -------------
		if fields.record_nav then
            context.tab = fields.record_nav
            reload = true
		end
        if fields.default_tab then
			pmeta:set_string("default_teacher_tab", context.tab)
            reload = true
		end
        if fields.playerlist then
			local event = minetest.explode_textlist_event(fields.playerlist)
			if event.type == "CHG" then
				context.player_chat_index = event.index
                reload = true
			end
        end
        if fields.playerchatlist then
			local event = minetest.explode_textlist_event(fields.playerchatlist)
			if event.type == "CHG" then
				context.mod_chat_index = event.index
                reload = true
			end
        end

        --------------
        -- OVERVIEW --
        --------------
        if fields.classrooms then
            context.tab = mc_teacher.TABS.CLASSROOMS
            reload = true
        elseif fields.map then
            context.tab = mc_teacher.TABS.MAP
            reload = true
        elseif fields.players then
            context.tab = mc_teacher.TABS.PLAYERS
            reload = true
        elseif fields.moderation then
            context.tab = mc_teacher.TABS.MODERATION
            reload = true
        elseif fields.reports then
            context.tab = mc_teacher.TABS.REPORTS
            reload = true
        elseif fields.help then
            context.tab = mc_teacher.TABS.HELP
            reload = true
        elseif fields.server and mc_core.checkPrivs(player, {server = true}) then
            context.tab = mc_teacher.TABS.SERVER
            reload = true
        end
        if fields.overviewscroll then
            local scroll = minetest.explode_scrollbar_event(fields.overviewscroll)
            if scroll.type == "CHG" then
                context.overviewscroll = scroll.value
            end 
        end

        ---------------------------------
        -- MANAGE CLASSROOMS
        ---------------------------------
        if fields.mode and fields.mode ~= context.selected_mode then
            context.selected_mode = fields.mode
            reload = true
        end
        if fields.schematic and fields.schematic ~= context.selected_schematic then
            context.selected_mode = mc_teacher.MODES.SCHEMATIC
            context.selected_schematic = fields.schematic
            reload = true
        elseif fields.realterrain and context.selected_dem ~= fields.realterrain then
            context.selected_mode = mc_teacher.MODES.TWIN
            context.selected_dem = fields.realterrain
            reload = true
        end

        if fields.requestrealm then
            if mc_core.checkPrivs(player,{teacher = true}) then
                local new_realm_name = fields.realmname or ""
                local errors = {}

                if new_realm_name == "" then
                    table.insert(errors, "Classrooms must have a non-empty name field.")
                end
                reload = true

                --local realmName, realmSizeX, realmSizeZ, realmSizeY
                --if fields.realmname == "" or fields.realmname == nil then realmName = "Unnamed Classroom" else realmName = fields.realmname end
                if context.selected_mode == mc_teacher.MODES.EMPTY then
                    -- Sanitize + check input
                    local new_realm_info = {
                        x_size = tonumber(fields.realm_x_size),
                        y_size = tonumber(fields.realm_y_size),
                        z_size = tonumber(fields.realm_z_size)
                    }

                    if new_realm_info.x_size < 80 or (new_realm_info.x_size > 240 and not has_server_privs) then
                        table.insert(errors, "Classrooms must have a width "..(has_server_privs and "of at least 80 nodes." or "between 80 and 240 nodes."))
                    end
                    if new_realm_info.y_size < 80 or (new_realm_info.y_size > 240 and not has_server_privs) then
                        table.insert(errors, "Classrooms must have a height "..(has_server_privs and "of at least 80 nodes." or "between 80 and 240 nodes."))
                    end
                    if new_realm_info.z_size < 80 or (new_realm_info.z_size > 240 and not has_server_privs) then
                        table.insert(errors, "Classrooms must have a length "..(has_server_privs and "of at least 80 nodes." or "between 80 and 240 nodes."))
                    end

                    if #errors ~= 0 then
                        for _,err in pairs(errors) do
                            minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] "..err))
                        end
                        return minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Please check your inputs and try again."))
                    end

                    local new_realm = Realm:New(new_realm_name, new_realm_info)
                    new_realm:CreateGround()
                    new_realm:CreateBarriersFast()
                    new_realm:set_data("owner", player:get_player_name())
                    minetest.chat_send_player(player:get_player_name(),minetest.colorize(mc_core.col.log, "[Minetest Classroom] Your requested classroom was successfully created."))
                elseif context.selected_mode == mc_teacher.MODES.SCHEMATIC then
                    if not context.selected_schematic then
                        table.insert(errors, "No schematic selected.")
                    elseif not schematicManager.schematics[context.selected_schematic] then
                        table.insert(errors, "Selected schematic not found.")
                    end

                    if #errors ~= 0 then
                        for _,err in pairs(errors) do
                            minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] "..err))
                        end
                        return minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Please check your inputs and try again."))
                    end

                    local new_realm = Realm:NewFromSchematic(new_realm_name, context.selected_schematic)
                    new_realm:set_data("owner", player:get_player_name())
                    minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Your requested classroom was successfully created."))
                    reload = true
                elseif context.selected_mode == mc_teacher.MODES.TWIN then
                    if not context.selected_dem then
                        table.insert(errors, "No digital twin world selected.")
                    elseif not realterrainManager.dems[context.selected_dem] then
                        table.insert(errors, "Selected digital twin world not found.")
                    end
                    
                    if #errors ~= 0 then
                        for _,err in pairs(errors) do
                            minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] "..err))
                        end
                        return minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Please check your inputs and try again."))
                    end
                    
                    local new_realm = Realm:NewFromDEM(new_realm_name, context.selected_dem)
                    new_realm:set_data("owner", player:get_player_name())
                    minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Your requested classroom was successfully created."))
                    reload = true
                end
            end
        end

        if fields.classroomlist then
            local event = minetest.explode_textlist_event(fields.classroomlist)
            if event.type == "CHG" and mc_core.checkPrivs(player,{teacher = true}) then
                -- We should not use the index here because the realm could be deleted while the formspec is active
                -- So return the actual realm.ID to avoid unexpected behaviour
                local counter = 0
                for _,thisRealm in pairs(Realm.realmDict) do
                    counter = counter + 1
                    if counter == tonumber(event.index) then
                        context.selected_realm_id = thisRealm.ID
                    end
                end
                reload = true
            end
        elseif fields.teleportrealm then
			-- Still a remote possibility that the realm is deleted in the time that the callback is executed
			-- So always check that the requested realm exists and the realm category allows the player to join
			-- Check that the player selected something from the textlist, otherwise default to spawn realm
			if not context.selected_realm_id then context.selected_realm_id = mc_worldManager.spawnRealmID end
			local realm = Realm.GetRealm(tonumber(context.selected_realm_id))
			if realm then
				realm:TeleportPlayer(player)
				context.selected_realm_id = nil
			else
				minetest.chat_send_player(player:get_player_name(),minetest.colorize(mc_core.col.log, "[Minetest Classroom] The classroom you requested is no longer available. Return to the Classroom tab on your dashboard to view the current list of available classrooms."))
			end
			reload = true
        elseif fields.deleterealm then
            local realm = Realm.GetRealm(tonumber(context.selected_realm_id))
            if realm and tonumber(context.selected_realm_id) ~= mc_worldManager.spawnRealmID then realm:Delete() end
            reload = true
        end

        if fields.music then
            context.selected_music = fields.music
            -- local background_sound = 
            -- play music as sample
            minetest.sound_play(backgroundSound, {
                to_player = player:get_player_name(),
                gain = 1,
                object = player,
                loop = false
            })
            reload = true
        end

        ---------------------------------
        -- MODERATOR
        ---------------------------------
		if fields.clearlog then
            local chatmessages = minetest.deserialize(mc_student.meta:get_string("chat_messages"))
            local directmessages = minetest.deserialize(mc_student.meta:get_string("direct_messages"))
            local pname = context.indexed_chat_players[tonumber(context.player_chat_index)]
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
            reload = true
        elseif fields.deletemessage then
            -- TODO: delete a specific message
            reload = true
        end

        -- MANAGE SERVER
        if fields.submitmessage then
            minetest.chat_send_all(minetest.colorize(mc_core.col.log, "[Minetest Classroom] "..fields.servermessage))
			reload = true
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
            reload = true
        elseif fields.removeip then
            if fields.ipstart then
                if not fields.ipend or fields.ipend == "Optional" or fields.ipend == "" then
                    networking.modify_ipv4(player,fields.ipstart,nil,nil)
                else
                    networking.modify_ipv4(player,fields.ipstart,fields.ipend,nil)
                end
            end
            reload = true
        elseif fields.toggleon or fields.toggleoff then
            networking.toggle_whitelist(player)
            reload = true
        end
        
        -- SERVER + OVERVIEW
        if fields.modifyrules then
            return minetest.show_formspec(player:get_player_name(), "mc_rules:edit", mc_rules.show_edit_formspec(nil))
        end

        if reload then
            -- save
            if fields.realmname then context.realmname = minetest.formspec_escape(fields.realmname) end
            if fields.realm_x_size then context.realm_x = fields.realm_x_size end
            if fields.realm_y_size then context.realm_y = fields.realm_y_size end
            if fields.realm_z_size then context.realm_z = fields.realm_z_size end
            -- reload
            mc_teacher.show_controller_fs(player, context.tab)
        end
    end
end) 