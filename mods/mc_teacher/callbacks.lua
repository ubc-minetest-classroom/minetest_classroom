-- Privileges
minetest.register_privilege("teacher", {
    give_to_singleplayer = false
})

minetest.register_on_priv_grant(function(name, granter, priv)
    if priv == "teacher" then
        mc_teacher.register_teacher(name)
    end
    return true -- continue to next callback
end)

minetest.register_on_priv_revoke(function(name, revoker, priv)
    if priv == "teacher" then
        mc_teacher.register_student(name)
    end
    return true -- continue to next callback
end)

-- Teacher joins/leaves
minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()
	if minetest.check_player_privs(player, { teacher = true }) then
		mc_teacher.register_teacher(pname)
    else
        mc_teacher.register_student(pname)
    end

    local teachers = {}
    local count = 0
    for teacher,_ in pairs(mc_teacher.teachers) do
        table.insert(teachers, teacher)
        count = count + 1
    end
    if count > 0 then 
        minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, table.concat({"[Minetest Classroom] ", count, " teacher", count == 1 and "" or "s", " currently online: ", table.concat(teachers, ", ")})))
    end
end)

minetest.register_on_leaveplayer(function(player)
    mc_teacher.deregister_player(player)
end)

-- Log all direct messages
minetest.register_on_chatcommand(function(name, command, params)
	if command == "msg" then
		-- For some reason, the params in this callback is a string rather than a table; need to parse the player name
		local params_table = mc_core.split(params, " ")
		local to_player = params_table[1]
		if minetest.get_player_by_name(to_player) then
			local message = string.sub(params, #to_player+2, #params)
			local timestamp = tostring(os.date("%Y-%m-%d %H:%M:%S"))
			local direct_msg = minetest.deserialize(mc_teacher.meta:get_string("dm_log")) or {}
            direct_msg[name] = direct_msg[name] or {}
            table.insert(direct_msg[name], {
                timestamp = timestamp,
                recipient = to_player,
                message = message
            })
            mc_teacher.meta:set_string("dm_log", minetest.serialize(direct_msg))
		end
	end
end)

-- Log all chat messages
minetest.register_on_chat_message(function(name, message)
	local timestamp = tostring(os.date("%Y-%m-%d %H:%M:%S"))
	local chat_msg = minetest.deserialize(mc_teacher.meta:get_string("chat_log")) or {}
    chat_msg[name] = chat_msg[name] or {}
    table.insert(chat_msg[name], {
        timestamp = timestamp,
        message = message
    })
	mc_teacher.meta:set_string("chat_log", minetest.serialize(chat_msg))
end)

local function get_players_to_update(player, context)
    local list = {}
    if context.selected_p_mode == mc_teacher.PMODE.SELECTED then
        local selected_player = context.p_list[context.selected_p_player]
        if selected_player then table.insert(list, selected_player) end
    elseif context.selected_p_mode == mc_teacher.PMODE.TAB then
        -- TODO: separate students and teachers
        for _,p in pairs(context.p_list) do
            table.insert(list, p)
        end
    elseif context.selected_p_mode == mc_teacher.PMODE.ALL then
        for student,_ in pairs(mc_teacher.students) do
            table.insert(list, student)
        end
        -- TODO: add check for server perms
        --[[for teacher,_ in pairs(mc_teacher.teachers) do
            table.insert(list, teacher)
        end]]
    end
    return list
end

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

        ----------------
        -- CLASSROOMS --
        ----------------
        if fields.mode and fields.mode ~= context.selected_mode then
            context.selected_mode = fields.mode
            -- digital twins are currently incompatible with instanced realms
            if context.selected_mode == mc_teacher.MODES.TWIN and context.selected_realm_type == Realm.CAT_KEY.INSTANCED then
                context.selected_realm_type = Realm.CAT_KEY.DEFAULT
            end
            reload = true
        end
        if fields.realmcategory and fields.realmcategory ~= context.selected_realm_type then
            context.selected_realm_type = fields.realmcategory
            -- digital twins are currently incompatible with instanced realms
            if context.selected_mode == mc_teacher.MODES.TWIN and context.selected_realm_type == Realm.CAT_KEY.INSTANCED then
                context.selected_mode = mc_teacher.MODES.SCHEMATIC
            end
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
                local realm_name = fields.realmname or context.realmname or ""
                local new_realm
                local errors = {}

                if realm_name == "" then
                    table.insert(errors, "Classrooms must have a non-empty name field.")
                end
                
                if context.selected_mode == mc_teacher.MODES.EMPTY then
                    -- Sanitize + check input
                    local realm_size = {
                        x = tonumber(fields.realm_x_size or context.realm_x),
                        y = tonumber(fields.realm_y_size or context.realm_y),
                        z = tonumber(fields.realm_z_size or context.realm_z)
                    }

                    if realm_size.x < 80 or (realm_size.x > 240 and not has_server_privs) then
                        table.insert(errors, "Classrooms must have a width "..(has_server_privs and "of at least 80 nodes." or "between 80 and 240 nodes."))
                    end
                    if realm_size.y < 80 or (realm_size.y > 240 and not has_server_privs) then
                        table.insert(errors, "Classrooms must have a height "..(has_server_privs and "of at least 80 nodes." or "between 80 and 240 nodes."))
                    end
                    if realm_size.z < 80 or (realm_size.z > 240 and not has_server_privs) then
                        table.insert(errors, "Classrooms must have a length "..(has_server_privs and "of at least 80 nodes." or "between 80 and 240 nodes."))
                    end

                    if #errors ~= 0 then
                        for _,err in pairs(errors) do
                            minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] "..err))
                        end
                        return minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Please check your inputs and try again."))
                    end

                    if context.selected_realm_type == Realm.CAT_KEY.INSTANCED then
                        new_realm = mc_worldManager.GetCreateInstancedRealm(realm_name, player, nil, true, realm_size)
                    else
                        -- TODO: refactor realm.lua so that it can generate realms of non-block-aligned sizes
                        new_realm = Realm:New(realm_name, realm_size)
                        new_realm:CreateGround()
                        new_realm:CreateBarriersFast()
                    end
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

                    if context.selected_realm_type == Realm.CAT_KEY.INSTANCED then
                        new_realm = mc_worldManager.GetCreateInstancedRealm(realm_name, player, context.selected_schematic, true)
                    else
                        new_realm = Realm:NewFromSchematic(realm_name, context.selected_schematic)
                    end
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
                    
                    new_realm = Realm:NewFromDEM(realm_name, context.selected_dem)
                end

                new_realm:set_data("owner", player:get_player_name())
                new_realm:setCategoryKey(Realm.CAT_MAP[context.selected_realm_type or "1"])
                new_realm:UpdateRealmPrivilege(context.selected_privs)
                minetest.chat_send_player(player:get_player_name(),minetest.colorize(mc_core.col.log, "[Minetest Classroom] Your requested classroom was successfully created."))
                reload = true
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
            --minetest.log(minetest.serialize(Realm.realmDict))
			local realm = Realm.GetRealm(context.selected_realm_id)
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

        --  CLASSROOMS + PLAYERS
        if fields.priv_interact then
            context.selected_privs.interact = fields.priv_interact
        end
        if fields.priv_shout then
            context.selected_privs.shout = fields.priv_shout
        end
        if fields.priv_fast then
            context.selected_privs.fast = fields.priv_fast
        end
        if fields.priv_fly then
            context.selected_privs.fly = fields.priv_fly
        end
        if fields.priv_noclip then
            context.selected_privs.noclip = fields.priv_noclip
        end
        if fields.priv_give then
            context.selected_privs.give = fields.priv_give
        end

        -------------
        -- PLAYERS --
        -------------
        if fields.p_list_header and context.selected_p_tab ~= fields.p_list_header then
            context.selected_p_tab = fields.p_list_header
            context.selected_p_player = 1
            context.p_list = nil
            reload = true
        end
        if fields.p_list then
            local event = minetest.explode_textlist_event(fields.p_list)
            if event.type == "CHG" then
                context.selected_p_player = event.index
                reload = true
            end
        end
        if fields.p_mode_selected then
            context.selected_p_mode = mc_teacher.PMODE.SELECTED
        elseif fields.p_mode_tab then
            context.selected_p_mode = mc_teacher.PMODE.TAB
        elseif fields.p_mode_all then
            context.selected_p_mode = mc_teacher.PMODE.ALL
        end

        if fields.p_priv_update or fields.p_priv_reset then
            local players_to_update = get_players_to_update(player, context)
            local realm = Realm.GetRealmFromPlayer(player)
            if realm and #players_to_update > 0 then
                realm.PermissionsOverride = realm.PermissionsOverride or {}
                for _,p in pairs(players_to_update) do
                    if fields.p_priv_update then
                        realm.PermissionsOverride[p] = realm.PermissionsOverride[p] or {}
                        for priv, v in pairs(context.selected_privs) do
                            realm.PermissionsOverride[p][priv] = (v == "true" and true or false)
                        end
                        minetest.log(minetest.serialize(realm.PermissionsOverride[p]))
                    else
                        realm.PermissionsOverride[p] = nil
                    end
                    local p_obj = minetest.get_player_by_name(p)
                    if p_obj and p_obj:is_player() then
                        realm:ApplyPrivileges(p_obj)
                    end
                end
            end
            reload = true
        elseif fields.p_kick then
            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
            for _,p in pairs(players_to_update) do
                if p ~= pname then
                    local success = minetest.kick_player(p)
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] "..(success and p.." successfully kicked from the server." or "Could not kick "..p.." from the server.")))
                else
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not kick yourself from the server."))
                end
            end
        elseif fields.p_ban then
            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
            for _,p in pairs(players_to_update) do
                if p ~= pname then
                    local success = minetest.ban_player(p)
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] "..(success and p.." successfully banned from the server." or "Could not ban "..p.." from the server.")))
                else
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not ban yourself from the server."))
                end
            end
        end

        ---------------
        -- MODERATOR --
        ---------------
        if fields.mod_log_players then
			local event = minetest.explode_textlist_event(fields.mod_log_players)
			if event.type == "CHG" then
				context.player_chat_index = event.index
                context.message_chat_index = 1
                reload = true
			end
        end
        if fields.mod_log_messages then
			local event = minetest.explode_textlist_event(fields.mod_log_messages)
			if event.type == "CHG" then
				context.message_chat_index = event.index
                reload = true
			end
        end
		if fields.mod_clearlog then
            local chat_msg = minetest.deserialize(mc_teacher.meta:get_string("chat_log")) or {}
            local direct_msg = minetest.deserialize(mc_teacher.meta:get_string("dm_log")) or {}
            local player_to_clear = context.indexed_chat_players[context.player_chat_index]
            if direct_msg and direct_msg[player_to_clear] then
                direct_msg[player_to_clear] = nil
            end
            if chat_msg and chat_msg[player_to_clear] then
                chat_msg[player_to_clear] = nil
            end
            mc_teacher.meta:set_string("chat_log", minetest.serialize(chat_msg))
            mc_teacher.meta:set_string("dm_log", minetest.serialize(direct_msg))
            reload = true
        end

        ------------
        -- SERVER --
        ------------
        if fields.server_send_students or fields.server_send_teachers or fields.server_send_admins or fields.server_send_all then

            minetest.chat_send_all(minetest.colorize(mc_core.col.log, "[Minetest Classroom] "..fields.server_message))
			reload = true
        elseif fields.server_shutdown_schedule then
            mc_teacher.cancel_shutdown()
            local sched = {
                ["30 seconds"] = 30,
                ["1 minute"] = 60,
                ["5 minutes"] = 300,
                ["10 minutes"] = 600,
                ["15 minutes"] = 900,
                ["30 minutes"] = 1800,
                ["45 minutes"] = 2700,
                ["1 hour"] = 3600,
                ["2 hours"] = 7200,
                ["3 hours"] = 10800,
                ["6 hours"] = 21600,
                ["12 hours"] = 43200,
                ["24 hours"] = 86400
            }
            local warn = {600, 540, 480, 420, 360, 300, 240, 180, 120, 60, 55, 50, 45, 40, 35, 30, 25, 20, 15, 10, 5, 4, 3, 2, 1}
            local time = sched[fields.server_restart_timer]
            minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Server restart successfully scheduled!"))
            minetest.chat_send_all(minetest.colorize(mc_core.col.log, "[Minetest Classroom] The server will be restarting in "..fields.time..". Worlds will be saved prior to the restart, so world data should not be lost."))
            mc_teacher.restart_scheduled.timer = minetest.after(time, mc_teacher.shutdown_server, true)
            for _,t in pairs(warn) do
                if time >= t then
                    mc_teacher.restart_scheduled["warn"..tostring(t)] = minetest.after(time - t, mc_teacher.display_restart_time, t)
                end
            end
        elseif fields.server_shutdown_now then
            mc_teacher.cancel_shutdown()
            mc_teacher.shutdown_server(true)
        elseif fields.addip then
            if fields.ipstart then
                if not fields.ipend or fields.ipend == "Optional" or fields.ipend == "" then
                    networking.modify_ipv4(player, fields.ipstart, nil, true)
                else
                    networking.modify_ipv4(player, fields.ipstart, fields.ipend, true)
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
        elseif fields.server_whitelist_toggle then
            networking.toggle_whitelist(player)
            reload = true
        end
        
        -- SERVER + OVERVIEW
        if fields.server_edit_rules then
            return minetest.show_formspec(player:get_player_name(), "mc_rules:edit", mc_rules.show_edit_formspec(nil))
        end

        -- GENERAL: RELOAD
        if reload then
            if fields.realmname then context.realmname = minetest.formspec_escape(fields.realmname) end
            if fields.realm_x_size then context.realm_x = fields.realm_x_size end
            if fields.realm_y_size then context.realm_y = fields.realm_y_size end
            if fields.realm_z_size then context.realm_z = fields.realm_z_size end
            if fields.server_message then context.server_message = minetest.formspec_escape(fields.server_message) end
            if fields.server_ip_start then context.start_ip = minetest.formspec_escape(fields.server_ip_start) end
            if fields.server_ip_end then context.end_ip = minetest.formspec_escape(fields.server_ip_end) end
            mc_teacher.show_controller_fs(player, context.tab)
        end
    end
end)

----------------------------------------------------
-- MAP (common to both mc_teacher and mc_student) --
----------------------------------------------------
minetest.register_on_player_receive_fields(function(player, formname, fields)
	local pmeta = player:get_meta()

	if string.sub(formname, 1, 10) == "mc_student" then
		context = mc_student.get_fs_context(player)
	elseif string.sub(formname, 1, 10) == "mc_teacher" then
		context = mc_teacher.get_fs_context(player)
	else
		return false
	end

	local wait = os.clock()
	while os.clock() - wait < 0.05 do end --popups don't work without this

	local reload = false

	if formname == "mc_student:notebook_fs" or formname == "mc_teacher:controller_fs" then
		if fields.record and fields.note ~= "" then
			mc_core.record_coordinates(player, fields.note)
			reload = true
		elseif fields.coordlist then
			local event = minetest.explode_textlist_event(fields.coordlist)
			if event.type == "CHG" then
				context.selected_coord = event.index
			end
		elseif fields.mark then
			local pdata = minetest.deserialize(pmeta:get_string("coordinates"))
			if pdata and pdata.note_map then
				local realm = Realm.GetRealmFromPlayer(player)
				if not context.selected_coord or not context.coord_i_to_note[context.selected_coord] then
					context.selected_coord = 1
				end
				local note_to_mark = context.coord_i_to_note[context.selected_coord]
				mc_core.queue_marker(player, note_to_mark, pdata.coords[pdata.note_map[note_to_mark]], formname == "mc_student:notebook_fs" and mc_student.marker_expiry or mc_teacher.marker_expiry)
			else
				minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Selected coordinate could not be marked."))
			end
		elseif fields.go then
			local pdata = minetest.deserialize(pmeta:get_string("coordinates"))
			if pdata and pdata.note_map then
				if not context.selected_coord or not context.coord_i_to_note[context.selected_coord] then
					context.selected_coord = 1
				end
				local note_name = context.coord_i_to_note[context.selected_coord]
				local note_i = pdata.note_map[note_name]
				local realm = Realm.GetRealm(pdata.realms[note_i])
				if realm then
					if realm:getCategory().joinable(realm, player) then
						realm:TeleportPlayer(player)
						player:set_pos(pdata.coords[note_i])
					else
						minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] You no longer have access to this classroom."))
					end
				else
					minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] This classroom no longer exists."))
				end
			else
				minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Could not teleport to location."))
			end
			reload = true
		elseif fields.delete then
			local pdata = minetest.deserialize(pmeta:get_string("coordinates"))
			if pdata and pdata.note_map then
				local new_note_map, new_coords, new_realms = {}, {}, {}
				if not context.selected_coord or not context.coord_i_to_note[context.selected_coord] then
					context.selected_coord = 1
				end
				local note_to_delete = context.coord_i_to_note[context.selected_coord]
				if note_to_delete then
					for note,i in pairs(pdata.note_map) do
						if note ~= note_to_delete then
							table.insert(new_coords, pdata.coords[i])
							table.insert(new_realms, pdata.realms[i])
							new_note_map[note] = #new_coords
						end
					end
					minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Selected coordinate successfully deleted."))
				else
					minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Selected coordinate could not be deleted."))
				end
				pmeta:set_string("coordinates", minetest.serialize({note_map = new_note_map, coords = new_coords, realms = new_realms, format = 2}))
			else
				minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Selected coordinate could not be deleted."))
			end
			reload = true
		elseif fields.clear then
			local pdata = minetest.deserialize(pmeta:get_string("coordinates"))
			if pdata and pdata.note_map then
				local new_note_map, new_coords, new_realms = {}, {}, {}
				local realm = Realm.GetRealmFromPlayer(player)
				for note,i in pairs(pdata.note_map) do 
					local coordrealm = Realm.GetRealm(pdata.realms[i])
					if realm and coordrealm and coordrealm.ID ~= realm.ID then
						table.insert(new_coords, pdata.coords[i])
						table.insert(new_realms, pdata.realms[i])
						new_note_map[note] = #new_coords
					end
				end
				pmeta:set_string("coordinates", minetest.serialize({note_map = new_note_map, coords = new_coords, realms = new_realms, format = 2}))
				minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] All coordinates saved in this classroom have been cleared."))
			else
				minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Saved coordinates could not be cleared."))
			end
			reload = true
		elseif fields.share then
			local pdata = minetest.deserialize(pmeta:get_string("coordinates"))
			if pdata and pdata.note_map then
				local realm = Realm.GetRealmFromPlayer(player)
				if not context.selected_coord or not context.coord_i_to_note[context.selected_coord] then
					context.selected_coord = 1
				end
				local note_to_share = context.coord_i_to_note[context.selected_coord]
				local realmID = pdata.realms[pdata.note_map[note_to_share]]
				local pos = pdata.coords[pdata.note_map[note_to_share]]
				for _,connplayer in pairs(minetest.get_connected_players()) do 
					local connRealm = Realm.GetRealmFromPlayer(connplayer)
					if connRealm.ID == realmID then
						minetest.chat_send_player(connplayer:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] "..player:get_player_name().." shared location {x="..tostring(math.round(pos.x-realm.StartPos.x))..", y="..tostring(math.round(pos.y-realm.StartPos.y))..", z="..tostring(math.round(pos.z-realm.StartPos.z)).."} with the note: "..note_to_share))
					end
				end
			else
				minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Location could not be shared."))
			end
			reload = true
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
		end

		if reload == true then
			if formname == "mc_student:notebook_fs" then
				mc_student.show_notebook_fs(player, mc_student.TABS.MAP)
			elseif formname == "mc_teacher:controller_fs" then
				mc_teacher.show_controller_fs(player, mc_teacher.TABS.MAP)
			end
		end
	end
end)