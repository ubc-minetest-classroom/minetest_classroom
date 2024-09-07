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

minetest.register_on_joinplayer(function(player)
    local pname = player:get_player_name()
    local pmeta = player:get_meta()

    local priv_format = pmeta:get_int("priv_format")
    if not priv_format or priv_format < 4 then
        pmeta:set_int("priv_format", 4)
        mc_worldManager.revokeUniversalPriv(player, {"student"})
        local realm = Realm.GetRealmFromPlayer(player)
        if realm then realm:ApplyPrivileges(player) end
    end

    if minetest.deserialize(pmeta:get_string("mc_teacher:frozen")) then
        mc_core.freeze_player(player)
        pmeta:set_string("mc_teacher:frozen", "")
    end

    if mc_core.checkPrivs(player, {teacher = true}) then
        mc_teacher.register_teacher(pname)
    else
        mc_teacher.register_student(pname)
    end

    if next(mc_teacher.teachers) ~= nil then
        local teachers = {}
        for teacher,_ in pairs(mc_teacher.teachers) do
            table.insert(teachers, teacher)
        end
        minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, table.concat({"[Minetest Classroom] ", #teachers, " teacher", #teachers == 1 and "" or "s", " currently online: ", table.concat(teachers, ", ")})))
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
            mc_teacher.log_direct_message(name, message, to_player)
        end
    end
end)

-- Log all chat messages
minetest.register_on_chat_message(mc_teacher.log_chat_message)

local function get_players_to_update(player, context, override)
    local list = {}
    local has_server_privs = mc_core.checkPrivs(player, {server = true})

    -- Additional checks added to ensure that only admins can modify roles/privs of other teachers
    if context.selected_p_mode == mc_teacher.PMODE.SELECTED then
        local selected_player = context.p_list[context.selected_p_player]
        if selected_player and (override or has_server_privs or mc_teacher.students[selected_player]) then
            table.insert(list, selected_player)
        end
    elseif context.selected_p_mode == mc_teacher.PMODE.TAB then
        for _,p in pairs(context.p_list) do
            if override or has_server_privs or mc_teacher.students[p] then
                table.insert(list, p)
            end
        end
    elseif context.selected_p_mode == mc_teacher.PMODE.ALL then
        for student,_ in pairs(mc_teacher.students) do
            table.insert(list, student)
        end
        if override or has_server_privs then
            for teacher,_ in pairs(mc_teacher.teachers) do
                table.insert(list, teacher)
            end
        end
    end
    return list
end

local function pluralize(count, role)
    local map = {
        [mc_teacher.ROLES.STUDENT] = {
            [true] = "a student",
            [false] = "students",
        },
        [mc_teacher.ROLES.TEACHER] = {
            [true] = "a teacher",
            [false] = "teachers",
        },
        [mc_teacher.ROLES.ADMIN] = {
            [true] = "an administrator",
            [false] = "administrators",
        }
    }
    return role and map[role] and map[role][count == 1] or "???"
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local pmeta = player:get_meta()
    local context = mc_teacher.get_fs_context(player)

    if string.sub(formname, 1, 10) ~= "mc_teacher" or not mc_core.checkPrivs(player, {teacher = true}) then
        return false
    end

    local wait = os.clock()
    local reload = false
    while os.clock() - wait < 0.05 do end --popups don't work without this

    local has_server_privs = mc_core.checkPrivs(player, {server = true})

    if formname == "mc_teacher:confirm_report_clear" then
        ------------------------
        -- REPORT CLEAR POPUP --
        ------------------------
        if fields.confirm then
            mc_teacher.meta:set_string("report_log", minetest.serialize({}))
            minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] The report log has been cleared."))
        end
        mc_teacher.show_controller_fs(player, context.tab)
    elseif formname == "mc_teacher:spawn_type_change" then
        ------------------------
        -- SPAWN CHANGE POPUP --
        ------------------------
        if not fields.confirm then
            fields.no_cat_override = true
        end
        mc_teacher.save_realm(player, context, fields)
        if fields.confirm and tonumber(mc_worldManager.spawnRealmID) == tonumber(context.edit_realm.id) then
            mc_worldManager.spawnRealmID = nil
            mc_worldManager.GetSpawnRealm() -- this will generate a new spawn realm
        end

        context.edit_realm = nil
        mc_teacher.show_controller_fs(player, context.tab)
    elseif formname == "mc_teacher:confirm_hide_occupied" then
        ----------------------
        -- HIDE REALM POPUP --
        ----------------------
        if fields.confirm then
            local realm = Realm.GetRealm(tonumber(context.realm_i_to_id[context.selected_realm]))
            if realm then
                local spawn = mc_worldManager.GetSpawnRealm()
                for p, v in pairs(realm:GetPlayers() or {}) do
                    if v == true then
                        local p_obj = minetest.get_player_by_name(p)
                        mc_core.temp_unfreeze_and_run(p_obj, spawn.TeleportPlayer, spawn, p_obj)
                        minetest.chat_send_player(p, minetest.colorize(mc_core.col.log, "[Minetest Classroom] The classroom you were in was hidden, so you were brought back to the server spawn."))
                    end
                end
                realm:setHidden(true)
            end
        end
        mc_teacher.show_controller_fs(player, context.tab)
    elseif formname == "mc_teacher:confirm_player_kick" then
        -----------------------
        -- PLAYER KICK POPUP --
        -----------------------
        if fields.confirm then
            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
            local reason = fields.reason and mc_core.trim(fields.reason)
            for _,p in pairs(players_to_update) do
                if p ~= pname then
                    local success = minetest.kick_player(p, reason ~= "" and reason)
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] "..(success and "Successfully kicked player " or "Could not kick player ")..p.." from the server."))
                else
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not kick yourself from the server."))
                end
            end
        end
        context.p_list = nil
        mc_teacher.show_controller_fs(player, context.tab)
    elseif formname == "mc_teacher:confirm_player_ban" then
        ----------------------
        -- PLAYER BAN POPUP --
        ----------------------
        if fields.confirm then
            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
            for _,p in pairs(players_to_update) do
                if p ~= pname then
                    local success = minetest.ban_player(p)
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] "..(success and "Successfully banned player " or "Could not ban player ")..p.." from the server."))
                else
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not ban yourself from the server."))
                end
            end
        end
        context.p_list = nil
        mc_teacher.show_controller_fs(player, context.tab)
    elseif formname == "mc_teacher:confirm_group_delete" then
        ------------------------
        -- DELETE GROUP POPUP --
        ------------------------
        if fields.confirm then
            local pname = player:get_player_name()
            local pmeta = player:get_meta()
            local groups = mc_teacher.get_player_tab_groups(player)
            local index = mc_teacher.get_group_index(context.selected_p_tab)
            if groups[index] and pmeta then
                local removed = table.remove(groups, index)
                pmeta:set_string("mc_teacher:groups", minetest.serialize(groups))
                context.selected_p_tab = nil
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Successfully deleted group "..removed.name.."."))
            else
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Selected group could not be deleted."))
            end
        end
        context.p_list = nil
        mc_teacher.show_controller_fs(player, context.tab)
    elseif formname == "mc_teacher:confirm_shutdown_schedule" and has_server_privs then
        -----------------------------
        -- SCHEDULE SHUTDOWN POPUP --
        -----------------------------
        if fields.confirm then
            mc_teacher.cancel_shutdown()
            local warn = {600, 540, 480, 420, 360, 300, 240, 180, 120, 60, 55, 50, 45, 40, 35, 30, 25, 20, 15, 10, 5, 4, 3, 2, 1}
            local time = mc_teacher.T_INDEX[context.server_shutdown_timer].t
            minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Server shutdown successfully scheduled!"))
            minetest.chat_send_all(minetest.colorize(mc_core.col.log, "[Minetest Classroom] The server will be restarting in "..context.server_shutdown_timer..". Classrooms will be saved prior to the restart."))
            mc_teacher.restart_scheduled.timer = minetest.after(time, mc_teacher.shutdown_server, true)
            for _,t in pairs(warn) do
                if time >= t then
                    mc_teacher.restart_scheduled["warn"..tostring(t)] = minetest.after(time - t, mc_teacher.display_restart_time, t)
                end
            end
            reload = true
        end
        context.server_shutdown_timer = nil
        mc_teacher.show_controller_fs(player, context.tab)
    elseif formname == "mc_teacher:confirm_shutdown_now" and has_server_privs then
        ------------------------
        -- SHUTDOWN NOW POPUP --
        ------------------------
        if fields.confirm then
            mc_teacher.cancel_shutdown()
            mc_teacher.shutdown_server(true)
        end
        mc_teacher.show_controller_fs(player, context.tab)
    elseif formname == "mc_teacher:confirm_hidden_delete" and has_server_privs then
        ------------------
        -- DELETE POPUP --
        ------------------
        if fields.confirm then
            local realm = Realm.GetRealm(tonumber(context.realm_i_to_id[context.selected_realm]))
            if not realm or realm:isDeleted() then
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] This classroom has already been deleted."))
            elseif tonumber(context.realm_i_to_id[context.selected_realm]) == mc_worldManager.spawnRealmID then
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not delete the spawn classroom."))
            else
                realm:Delete()
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] The classroom will be deleted in 15 seconds."))
            end
        end
        mc_teacher.show_controller_fs(player, context.tab)
    elseif formname == "mc_teacher:confirm_hidden_deleteall" and has_server_privs then
        ----------------------
        -- DELETE ALL POPUP --
        ----------------------
        if fields.confirm then
            local deletion_active = false
            for _,id in pairs(context.realm_i_to_id) do
                local realm = Realm.GetRealm(tonumber(id))
                if realm and not realm:isDeleted() and tonumber(id) ~= mc_worldManager.spawnRealmID then
                    realm:Delete()
                    deletion_active = true
                end
            end
            if deletion_active then
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Classrooms will begin being deleted in 15 seconds."))
            else
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] No classrooms are available to delete."))
            end
        end
        mc_teacher.show_controller_fs(player, context.tab)
    elseif has_server_privs and string.sub(formname or "", 1, 23) == "mc_teacher:role_change_" then
        -----------------------
        -- ROLE CHANGE POPUP --
        -----------------------
        if fields.confirm then
            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
            for _,p in pairs(players_to_update) do
                if p == pname then
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not change your own server role."))
                else
                    local p_obj = minetest.get_player_by_name(p)
                    if not p_obj or not p_obj:is_player() then
                        minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Could not change server role of player "..tostring(p).." (they are probably offline)."))
                    else
                        if formname == "mc_teacher:role_change_"..mc_teacher.ROLES.STUDENT then
                            mc_worldManager.revokeUniversalPriv(p_obj, {"teacher", "server"})
                            mc_teacher.register_student(p)
                        elseif formname == "mc_teacher:role_change_"..mc_teacher.ROLES.TEACHER then
                            mc_worldManager.grantUniversalPriv(p_obj, {"teacher"})
                            mc_worldManager.revokeUniversalPriv(p_obj, {"server"})
                            mc_teacher.register_teacher(p)
                        elseif formname == "mc_teacher:role_change_"..mc_teacher.ROLES.ADMIN then
                            mc_worldManager.grantUniversalPriv(p_obj, {"teacher", "server"})
                            mc_teacher.register_teacher(p)
                        end

                        local realm = Realm.GetRealmFromPlayer(p_obj)
                        if realm then
                            realm:ApplyPrivileges(p_obj)
                        end
                    end
                end
            end
            minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Server role changes applied!"))
        end
        context.p_list = nil
        mc_teacher.show_controller_fs(player, context.tab)
    elseif formname == "mc_teacher:whitelist" and has_server_privs then
        ---------------------
        -- WHITELIST POPUP --
        ---------------------
        local reload = false
        if fields.whitelist then
            local event = minetest.explode_textlist_event(fields.whitelist)
            if event.type == "CHG" then
                context.selected_ip_range = event.index
            end
        end

        if fields.ip_add or fields.ip_remove then
            if fields.ip_start and fields.ip_start ~= "" then
                local add_cond = (fields.ip_remove == nil) or nil
                if not fields.ip_end or fields.ip_end == "" then
                    networking.modify_ipv4(player, fields.ip_start, nil, add_cond)
                else
                    local ips_ordered = networking.ipv4_compare(fields.ip_start, fields.ip_end)
                    local start_ip = ips_ordered and fields.ip_start or fields.ip_end
                    local end_ip = ips_ordered and fields.ip_end or fields.ip_start
                    networking.modify_ipv4(player, start_ip, end_ip, add_cond)
                end
            end
            reload = true
        elseif fields.whitelist_show then
            context.show_whitelist = true
            reload = true
        elseif fields.remove then
            local ip_to_remove = context.ip_whitelist[tonumber(context.selected_ip_range)]
            if ip_to_remove then
                networking.modify_ipv4(player, ip_to_remove, nil, nil)
            else
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] This IP has already been removed from the whitelist."))
            end
            reload = true
        elseif fields.toggle then
            networking.toggle_whitelist(player)
            reload = true
        elseif fields.quit or fields.exit then
            context.show_whitelist = nil
            return mc_teacher.show_controller_fs(player, context.tab)
        end

        if reload then
            if fields.ip_start then context.start_ip = minetest.formspec_escape(fields.ip_start) end
            if fields.ip_end then context.end_ip = minetest.formspec_escape(fields.ip_end) end
            mc_teacher.show_whitelist_popup(player)
        end
    elseif formname == "mc_teacher:edit_realm" then
        ----------------------
        -- REALM EDIT POPUP --
        ----------------------
        if fields.allowpriv_interact or fields.denypriv_interact or fields.ignorepriv_interact then
            local change = fields.allowpriv_interact or fields.denypriv_interact or fields.ignorepriv_interact
            context.edit_realm.privs.interact = (change == "false" and "nil") or (fields.allowpriv_interact and true) or (fields.ignorepriv_interact and "nil") or false
            reload = true
        end
        if fields.allowpriv_shout or fields.denypriv_shout or fields.ignorepriv_shout then
            local change = fields.allowpriv_shout or fields.denypriv_shout or fields.ignorepriv_shout
            context.edit_realm.privs.shout = (change == "false" and "nil") or (fields.allowpriv_shout and true) or (fields.ignorepriv_shout and "nil") or false
            reload = true
        end
        if fields.allowpriv_fast or fields.denypriv_fast or fields.ignorepriv_fast then
            local change = fields.allowpriv_fast or fields.denypriv_fast or fields.ignorepriv_fast
            context.edit_realm.privs.fast = (change == "false" and "nil") or (fields.allowpriv_fast and true) or (fields.ignorepriv_fast and "nil") or false
            reload = true
        end
        if fields.allowpriv_fly or fields.denypriv_fly or fields.ignorepriv_fly then
            local change = fields.allowpriv_fly or fields.denypriv_fly or fields.ignorepriv_fly
            context.edit_realm.privs.fly = (change == "false" and "nil") or (fields.allowpriv_fly and true) or (fields.ignorepriv_fly and "nil") or false
            reload = true
        end
        if fields.allowpriv_noclip or fields.denypriv_noclip or fields.ignorepriv_noclip then
            local change = fields.allowpriv_noclip or fields.denypriv_noclip or fields.ignorepriv_noclip
            context.edit_realm.privs.noclip = (change == "false" and "nil") or (fields.allowpriv_noclip and true) or (fields.ignorepriv_noclip and "nil") or false
            reload = true
        end
        if fields.allowpriv_give or fields.denypriv_give or fields.ignorepriv_give then
            local change = fields.allowpriv_give or fields.denypriv_give or fields.ignorepriv_give
            context.edit_realm.privs.give = (change == "false" and "nil") or (fields.allowpriv_give and true) or (fields.ignorepriv_give and "nil") or false
            reload = true
        end

        if fields.erealm_cat and fields.erealm_cat ~= context.edit_realm.type then
            context.edit_realm.type = fields.erealm_cat
        elseif fields.erealm_skybox and tonumber(fields.erealm_skybox) ~= tonumber(context.edit_realm.skybox) then
            context.edit_realm.skybox = tonumber(fields.erealm_skybox)
        elseif fields.erealm_music and tonumber(fields.erealm_music) ~= tonumber(context.edit_realm.music) then
            context.edit_realm.music = tonumber(fields.erealm_music)
        elseif fields.save_realm or fields.cancel or fields.quit then
            if fields.save_realm then
                local realm = Realm.GetRealm(context.edit_realm.id)
                if realm then
                    if realm:getCategory().key == mc_teacher.R.CAT_MAP[mc_teacher.R.CAT_KEY.SPAWN] and context.edit_realm.type ~= mc_teacher.R.CAT_KEY.SPAWN and tonumber(realm.ID) == tonumber(mc_worldManager.spawnRealmID) then
                        context.edit_realm.name = fields.erealm_name
                        return mc_teacher.show_confirm_popup(player, "spawn_type_change", {
                            action = "Are you sure you want to change the current spawn classroom into a "..(context.edit_realm.type == mc_teacher.R.CAT_KEY.PRIVATE and "private" or "standard").." classroom?\nThis will generate a new spawn classroom.",
                            button = "Save new type", cancel = "Keep current type",
                        }, {x = 9.9, y = 3.8})
                    else
                        mc_teacher.save_realm(player, context, fields)
                    end
                else
                    minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] The classroom could not be found, so no changes were made to it."))
                end
            else
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] No changes were made to the classroom."))
            end

            context.edit_realm = nil
            return mc_teacher.show_controller_fs(player, context.tab)
        end

        if reload then
            if fields.erealm_name then context.edit_realm.name = minetest.formspec_escape(fields.erealm_name) end
            mc_teacher.show_edit_popup(player, context.edit_realm.id)
        end
    elseif formname == "mc_teacher:edit_group" then
        -----------------
        -- GROUP POPUP --
        -----------------
        local reload = false
        if fields.non_members then
            local event = minetest.explode_textlist_event(fields.non_members)
            if event.type == "CHG" then
                context.edit_group.sel_nm = event.index
            elseif event.type == "DCL" then
                context.edit_group.sel_nm = event.index
                fields.member_add = ""      -- trigger add button
            end
        end
        if fields.members then
            local event = minetest.explode_textlist_event(fields.members)
            if event.type == "CHG" then
                context.edit_group.sel_m = event.index
            elseif event.type == "DCL" then
                context.edit_group.sel_m = event.index
                fields.member_delete = ""   -- trigger delete button
            end
        end     
        if fields.member_add then
            local selected_player = table.remove(context.edit_group.p_list, context.edit_group.sel_nm)
            table.insert(context.edit_group.members, selected_player)
            context.edit_group.sel_nm = math.max(1, math.min(context.edit_group.sel_nm, #context.edit_group.p_list))
            reload = true
        elseif fields.member_delete then
            local selected_player = table.remove(context.edit_group.members, context.edit_group.sel_m)
            table.insert(context.edit_group.p_list, selected_player)
            context.edit_group.sel_m = math.max(1, math.min(context.edit_group.sel_m, #context.edit_group.members))
            reload = true
        elseif fields.save or fields.cancel or fields.quit then
            if fields.save then
                local pname = player:get_player_name()
                local pmeta = player:get_meta()
                local groups = mc_teacher.get_player_tab_groups(player)
                if groups and pmeta then
                    local group_to_save = {name = fields.group_name or context.edit_group.name, members = context.edit_group.members or {}}
                    if context.edit_group.id == 0 then
                        table.insert(groups, group_to_save)
                        context.selected_p_tab = (#groups + mc_teacher.PTAB.N)
                        pmeta:set_string("mc_teacher:groups", minetest.serialize(groups))
                        minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Group created!"))
                    else
                        groups[context.edit_group.id] = group_to_save
                        pmeta:set_string("mc_teacher:groups", minetest.serialize(groups))
                        minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Group updated!"))
                    end
                else
                    minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] The group could not be found, so no changes were made to it."))
                end
            else
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] No changes were made to the group."))
            end

            context.edit_group = nil
            context.p_list = nil
            return mc_teacher.show_controller_fs(player, context.tab)
        end

        if reload then
            if fields.group_name then context.edit_group.name = minetest.formspec_escape(fields.group_name) end
            mc_teacher.show_group_popup(player)
        end
    elseif formname == "mc_teacher:classify_value" then
        --------------------------
        -- CLASSIFICATION POPUP --
        --------------------------
        -- No value was clicked in the value textlist, so we assume it is the first value in the list
        if context.value_element == "node" then
            if not context.selected_node_value then context.selected_node_value = openstreetmap.temp.node_values_list[1] end
        elseif context.value_element == "way" then
            if not context.selected_way_value then context.selected_way_value = openstreetmap.temp.way_values_list[1] end
        else
            -- TODO: reserved for LiDAR
        end

        if fields.itemstring_list then
            local event = minetest.explode_textlist_event(fields.itemstring_list)
            if event.type == "CHG" then
                if tonumber(context.selected_decorator) == 2 then
                    context.selected_itemstring = openstreetmap.NODE_ITEMSTRINGS[event.index]
                    context.selected_itemstring_index = event.index
                    return mc_teacher.show_classifier_popup(player, context.selected_value or LASFile.values_list[1])
                elseif tonumber(context.selected_decorator) == 3 then
                    if context.value_element == "node" then
                        context.selected_node_itemstring = openstreetmap.NODE_ITEMSTRINGS[event.index]
                        context.selected_node_itemstring_index = event.index
                        return mc_teacher.show_classifier_popup(player, context.selected_node_value or openstreetmap.temp.node_values_list[1], context)
                    end
            
                    if context.value_element == "way" then
                        context.selected_way_itemstring = openstreetmap.NODE_ITEMSTRINGS[event.index]
                        context.selected_way_itemstring_index = event.index
                        return mc_teacher.show_classifier_popup(player, context.selected_way_value or openstreetmap.temp.way_values_list[1], context)
                    end
                end
            end
        end
        if fields.extrude then
            context.extrude = fields.extrude
        end
        if fields.save_classification then
            if context.value_element == "node" and context.selected_node_itemstring then
                openstreetmap.temp.node_value_itemstring_table[context.selected_node_value] = context.selected_node_itemstring
            elseif context.value_element == "way" and context.selected_way_itemstring then
                openstreetmap.temp.way_value_itemstring_table[context.selected_way_value] = context.selected_way_itemstring
            end
            -- fields.extrude is the index, not the value, so we need to subtract 1
            if fields.extrude then
                if context.value_element == "node" then
                    openstreetmap.temp.node_value_extrusion_table[context.selected_node_value] = fields.extrude
                elseif context.value_element == "way" then
                    openstreetmap.temp.way_value_extrusion_table[context.selected_way_value] = fields.extrude
                end
            end
            -- Reset context for the next classification popup
            context.extrude = nil
            context.selected_node_itemstring = nil
            context.selected_way_itemstring = nil
            context.selected_node_itemstring_index = nil
            context.selected_way_itemstring_index = nil
            return mc_teacher.show_controller_fs(player, context.tab)
        end
        if fields.cancel_classification then
            -- Reset context for the next classification popup
            context.extrude = nil
            context.selected_node_itemstring = nil
            context.selected_way_itemstring = nil
            context.selected_node_itemstring_index = nil
            context.selected_way_itemstring_index = nil
            return mc_teacher.show_controller_fs(player, context.tab)
        end

    elseif formname == "mc_teacher:controller_fs" then
        -------------
        -- GENERAL --
        -------------
        if fields.record_nav then
            context.tab = fields.record_nav
            context.p_list = nil
            reload = true
        end
        if fields.default_tab then
            pmeta:set_string("default_teacher_tab", context.tab)
            context.p_list = nil
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
        if fields.class_opt_scroll then
            local event = minetest.explode_scrollbar_event(fields.class_opt_scroll)
            if event.type == "CHG" then
                context.class_opt_scroll = event.value
            end
        end
        if fields.mode and fields.mode ~= context.selected_mode then
            context.selected_mode = fields.mode
            -- digital twins are currently incompatible with private classrooms
            if context.selected_mode == mc_teacher.MODES.LIDAR and context.selected_realm_type == mc_teacher.R.CAT_KEY.PRIVATE then
                context.selected_realm_type = mc_teacher.R.CAT_KEY.RESTRICTED
            end
            reload = true
        end
        if fields.realmcategory and fields.realmcategory ~= context.selected_realm_type then
            context.selected_realm_type = fields.realmcategory
            -- digital twins are currently incompatible with private classrooms
            if context.selected_mode == mc_teacher.MODES.LIDAR and context.selected_realm_type == mc_teacher.R.CAT_KEY.PRIVATE then
                context.selected_mode = mc_teacher.MODES.SCHEMATIC
            end
            reload = true
        end
        if fields.surface_itemstring_list then
            local event = minetest.explode_textlist_event(fields.surface_itemstring_list)
            if event.type == "CHG" then
                context.selected_surface_itemstring = openstreetmap.NODE_ITEMSTRINGS[event.index]
            end
            reload = true
        end
        if fields.fill_itemstring_list then
            local event = minetest.explode_textlist_event(fields.fill_itemstring_list)
            if event.type == "CHG" then
                context.selected_fill_itemstring = openstreetmap.NODE_ITEMSTRINGS[event.index]
            end
            reload = true
        end
        if fields.fill_depth then
            context.fill_depth = fields.fill_depth
            openstreetmap.fill_depth = fields.fill_depth
            reload = true
        end
        if fields.fill_enclosures then
            local change = fields.fill_enclosures
            openstreetmap.fill_enclosures = (change == "true")
            reload = true
        end
        if fields.write_metadata then
            local change = fields.write_metadata
            openstreetmap.write_metadata = (change == "true")
            reload = true
        end
        if fields.schematic and fields.schematic ~= context.selected_schematic then
            context.selected_mode = mc_teacher.MODES.SCHEMATIC
            context.selected_schematic = fields.schematic
            reload = true
        elseif fields.realterrain and context.selected_dem ~= fields.realterrain then
            context.selected_mode = mc_teacher.MODES.LIDAR
            context.selected_dem = fields.realterrain
            reload = true
        end
        if fields.realm_generator and fields.realm_generator ~= context.realm_gen and fields.realm_generator ~= mc_teacher.R.GEN.DNR then
            context.realm_gen = fields.realm_generator
            reload = true
        end
        if fields.realm_decorator and fields.realm_decorator ~= context.realm_dec then
            context.realm_dec = fields.realm_decorator
            reload = true
        end
        if fields.realm_skybox and tonumber(fields.realm_skybox) ~= tonumber(context.selected_skybox) then
            context.selected_skybox = tonumber(fields.realm_skybox)
        end
        if fields.realm_music and tonumber(fields.realm_music) ~= tonumber(context.selected_music) then
            context.selected_music = tonumber(fields.realm_music)
        end
        if fields.twin_data_source then
            context.selected_twin_data_source = fields.twin_data_source
            reload = true
        end
        if fields.decorator then
            context.selected_decorator = fields.decorator
            reload = true
        end
        if fields.node_value_list then
            local event = minetest.explode_textlist_event(fields.node_value_list)
            if event.type == "CHG" then
                context.selected_node_value_index = event.index
                if openstreetmap.temp.node_values_list then
                    context.selected_node_value = openstreetmap.temp.node_values_list[event.index]
                end
            end
        end
        if fields.way_value_list then
            local event = minetest.explode_textlist_event(fields.way_value_list)
            if event.type == "CHG" then
                context.selected_way_value_index = event.index
                if openstreetmap.temp.way_values_list then
                    context.selected_way_value = openstreetmap.temp.way_values_list[event.index]
                end
            end
        end
        if fields.las_file then
            context.selected_las_file = fields.las_file
            reload = true
        end
        if fields.fetch_osm_extent then
            -- Sanitize + check input
            if fields.osm_extent_maxlat and tonumber(fields.osm_extent_maxlat) and fields.osm_extent_minlat and tonumber(fields.osm_extent_minlat) and fields.osm_extent_maxlon and tonumber(fields.osm_extent_maxlon) and fields.osm_extent_minlon and tonumber(fields.osm_extent_minlon) and tonumber(fields.osm_extent_maxlat) <= 90 and tonumber(fields.osm_extent_minlat) >= -90 and tonumber(fields.osm_extent_maxlon) <= 180 and tonumber(fields.osm_extent_minlon) >= -180 and tonumber(fields.osm_extent_minlon) < tonumber(fields.osm_extent_maxlon) and tonumber(fields.osm_extent_minlat) < tonumber(fields.osm_extent_maxlat) then
                -- Initialize the callback to fetch nodes
                openstreetmap.fetch_all_overpass_nodes_callback(fields.osm_extent_minlat, fields.osm_extent_minlon, fields.osm_extent_maxlat, fields.osm_extent_maxlon, true, function(result)
                    if result.succeeded then

                        -- Check for errors
                        if result.status and result.status ~= "200" then
                            minetest.chat_send_player(player:get_player_name(),"[Minetest Classroom] Error: Overpass API request returned HTTP error " .. result.status)
                            return
                        end
                        
                        local data = minetest.parse_json(result.data)
                        if data and data.elements and #data.elements > 0 then
                            
                            -- Get and check the UTM zone from the bounding longitude
                            local utm_zone_min = openstreetmap.computeUTMZone(fields.osm_extent_minlon)
                            local utm_zone_max = openstreetmap.computeUTMZone(fields.osm_extent_maxlon)
                            if utm_zone_min == utm_zone_max then
                                
                                -- Get the range of eastings and northings for creating the realm size
                                local max_easting = -math.huge
                                local max_northing = -math.huge
                                local min_easting, min_northing, easting, northing, isnorth
                                local tags = {}
                                local indexedNodeData = {}
                                for _,node in pairs(data.elements) do
                                    easting, northing, isnorth = openstreetmap.latLonToUTM(node.lat, node.lon, utm_zone_min)
                                    if min_easting then min_easting = math.min(min_easting,easting) else min_easting = easting end
                                    if min_northing then min_northing = math.min(min_northing,northing) else min_northing = northing end
                                    max_easting = math.max(max_easting,easting)
                                    max_northing = math.max(max_northing,northing)

                                    -- Get unique tags while we're in here
                                    if node.tags then
                                        for k, v in pairs(node.tags) do
                                            -- Check that the tag name is whitelisted
                                            -- TODO: add support for numeric tags: "roof:levels", "width", "ele", "lanes", "maxpseed", "height", "building:levels"
                                            if openstreetmap.whitelistTags[k] then
                                                -- Parse string values here
                                                local values = mc_core.split(v, ";")
                                                if values then
                                                    for _, value in pairs(values) do 
                                                        if openstreetmap.whitelistTags[k][value] then
                                                            if openstreetmap.osm_textures[value] then
                                                                -- We have a matching texture based on the value
                                                                openstreetmap.temp.node_value_texture_table[value] = openstreetmap.osm_textures[value]
                                                                openstreetmap.temp.node_value_itemstring_table[value] = "openstreetmap:" .. value
                                                                table.insert(openstreetmap.temp.node_value_itemstring_list, "openstreetmap:" .. value)
                                                            else
                                                                -- No matching texture, so we will use the default node texture
                                                                openstreetmap.temp.node_value_texture_table[value] = "node.png"
                                                                openstreetmap.temp.node_value_itemstring_table[value] = "openstreetmap:node"
                                                                table.insert(openstreetmap.temp.node_value_itemstring_list, "openstreetmap:node")
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end 
                                    end

                                    indexedNodeData[node.id] = {
                                        lat = node.lat,
                                        lon = node.lon,
                                        type = node.type,
                                        timestamp = node.timstamp,
                                        version = node.version,
                                        changeset = node.changeset,
                                        user = node.user,
                                        uid = node.uid,
                                        tags = node.tags,
                                        MTnodeID = MTnodeID,
                                    }
                                end

                                local sizeX = max_easting - min_easting + 1
                                local sizeZ = max_northing - min_northing + 1
                                minetest.chat_send_all("    DEBUG: min_northing = "..min_northing.." max_northing = "..max_northing.." sizeZ = "..sizeZ)
                                
                                -- Store everything
                                openstreetmap.temp.sizeX = sizeX
                                openstreetmap.temp.sizeY = 160 -- TODO: calculate dynamically as a function of extrusion, fill depth, terrain, minimum of 80
                                openstreetmap.temp.sizeZ = sizeZ
                                openstreetmap.temp.min_easting = min_easting
                                openstreetmap.temp.min_northing = min_northing
                                openstreetmap.temp.utm_zone = utm_zone_min
                                openstreetmap.temp.utm_zone_is_north = isnorth
                                openstreetmap.temp.nodedata = data
                                openstreetmap.temp.indexedNodeData = indexedNodeData
                                context.fetched_nodes = true

                                -- We have nodes, now get ways
                                openstreetmap.fetch_all_overpass_ways_callback(fields.osm_extent_minlat, fields.osm_extent_minlon, fields.osm_extent_maxlat, fields.osm_extent_maxlon, false, function(result)
                                    if result.succeeded then
                
                                        -- Check for errors
                                        if result.status and result.status ~= "200" then
                                            minetest.chat_send_player(player:get_player_name(),"[Minetest Classroom] Error: Overpass API request returned HTTP error " .. result.status)
                                            return
                                        end
                                        
                                        local data = minetest.parse_json(result.data)
                                        if data and data.elements and #data.elements > 0 then
                                            -- Add any new values to the symbology table and get the MTnode
                                            for _, way in pairs(data.elements) do
                                                -- Get unique tags while we're in here
                                                if way.tags then
                                                    for k, v in pairs(way.tags) do
                                                        -- TODO: add support for numeric tags: "roof:levels", "width", "ele", "lanes", "maxpseed", "height", "building:levels"
                                                        -- Check that the tag name is whitelisted
                                                        if openstreetmap.whitelistTags[k] then
                                                            -- Parse string values here
                                                            local values = mc_core.split(v, ";")
                                                            if values then
                                                                for _, value in pairs(values) do 
                                                                    if openstreetmap.whitelistTags[k][value] then
                                                                        if openstreetmap.osm_textures[value] then
                                                                            -- We have a matching texture based on the value
                                                                            openstreetmap.temp.way_value_texture_table[value] = openstreetmap.osm_textures[value]
                                                                            openstreetmap.temp.way_value_itemstring_table[value] = "openstreetmap:" .. value
                                                                            table.insert(openstreetmap.temp.way_value_itemstring_list, "openstreetmap:" .. value)
                                                                        else
                                                                            -- No matching texture, so we will use the default way texture
                                                                            openstreetmap.temp.way_value_texture_table[value] = "way.png"
                                                                            openstreetmap.temp.way_value_itemstring_table[value] = "openstreetmap:way"
                                                                            table.insert(openstreetmap.temp.way_value_itemstring_list, "openstreetmap:way")
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end 
                                                end
                                            end

                                            -- We iterate a second time because we need to populate openstreetmap.value_texture_table first
                                            local indexedWayData = {}
                                            for _, way in pairs(data.elements) do
                                                local MTnode = "openstreetmap:way"
                                                local MTnodeID
                                                if way.tags then
                                                    -- Get the texture for the way
                                                    for k, v in pairs(way.tags) do
                                                        -- Use the first valid key-value for the way texture, otherwise use the default
                                                        if MTnode == "openstreetmap:way" and openstreetmap.temp.way_value_itemstring_table[v] then
                                                            MTnode = openstreetmap.temp.way_value_itemstring_table[v]
                                                            MTnodeID = minetest.get_content_id(MTnode)
                                                            break
                                                        end
                                                    end

                                                    -- Determine if the way is enclosed
                                                    local nodesinway = {}
                                                    for _, id in pairs(way.nodes) do table.insert(nodesinway, id) end
                                                    local enclosed
                                                    if nodesinway[1] == nodesinway[#nodesinway] then enclosed = true else enclosed = false end

                                                    indexedWayData[way.id] = {
                                                        type = way.type,
                                                        timestamp = way.timstamp,
                                                        version = way.version,
                                                        changeset = way.changeset,
                                                        user = way.user,
                                                        uid = way.uid,
                                                        nodes = way.nodes,
                                                        tags = way.tags,
                                                        MTnodeID = MTnodeID,
                                                        enclosed = enclosed
                                                    }
                                                end
                                            end
                                            openstreetmap.temp.waydata = data
                                            openstreetmap.temp.indexedWayData = indexedWayData
                                        end
                                    end
                                end)

                                context.fetched_ways = true
                                reload = true
                            else
                                minetest.chat_send_player(player:get_player_name(),"[Minetest Classroom] Error: OpenStreetMap data span more than one UTM zone, cannot map all the features on a cartesian coordinate system. Select a smaller range of longitude and try again.")
                                reload = true
                            end
                        else
                            minetest.chat_send_player(player:get_player_name(),"[Minetest Classroom] Error: Unhandled exception.")
                            reload = true
                        end
                    else
                        minetest.chat_send_player(player:get_player_name(),"[Minetest Classroom] Error: Overpass API request returned HTTP error " .. result.status)
                        reload = true
                    end
                end)
            else
                minetest.chat_send_player(player:get_player_name(), "[Minetest Classroom] Error: Invalid format or range of input latitude or longitude values.")
                reload = true
            end
        end

        -- Show the classifier popup
        if fields.node_texture_button then
            context.value_element = "node"
            return mc_teacher.show_classifier_popup(player, context.selected_node_value or openstreetmap.temp.node_values_list[1], context)
        end

        if fields.way_texture_button then
            context.value_element = "way"
            return mc_teacher.show_classifier_popup(player, context.selected_way_value or openstreetmap.temp.way_values_list[1], context)
        end

        if fields.c_newrealm then
            if mc_core.checkPrivs(player, {teacher = true}) then
                local realm_name = fields.realmname or context.realmname or ""
                local new_realm
                local errors = {}

                if realm_name == "" then
                    table.insert(errors, "Classrooms must have a non-empty name field.")
                end
                
                if context.selected_mode == mc_teacher.MODES.FLAT then

                    if tonumber(context.selected_decorator) == 3 then
                        -- Decorator is OPENSTREETMAP
                        -- TODO: Get any user-entered key-values submitted for query
                        new_realm = Realm:New(realm_name or "OSM", { x = openstreetmap.temp.sizeX, y = openstreetmap.temp.sizeY, z = openstreetmap.temp.sizeZ })
                        openstreetmap.temp.realmID = new_realm.ID
                        new_realm:CreateGround(context.selected_surface_itemstring or "default:dirt_with_grass", (context.fill_depth + 1) or 1)
                        new_realm:FillBelowGround(context.selected_fill_itemstring or "default:dirt", context.fill_depth)
                        new_realm:UpdateSpawn({x = math.ceil(openstreetmap.temp.sizeX / 2), y = math.min(context.fill_depth + 2, openstreetmap.temp.sizeY - 3), z = math.ceil(openstreetmap.temp.sizeZ / 2)})
                        new_realm:CreateBarriersFast()
                        local utmInfo = { zone = openstreetmap.temp.utm_zone, utm_is_north = openstreetmap.temp.utm_zone_is_north, easting = openstreetmap.temp.min_easting, northing = openstreetmap.temp.min_northing }
                        new_realm:set_data("UTMInfo", utmInfo)
                        new_realm:set_data("OSMIndexedNodeData",openstreetmap.temp.indexedNodeData)
                        new_realm:set_data("OSMIndexedWayData",openstreetmap.temp.indexedWayData)
                        new_realm:set_data("min_easting",openstreetmap.temp.min_easting)
                        new_realm:set_data("min_northing",openstreetmap.temp.min_northing)
                        new_realm:set_data("utm_zone",openstreetmap.temp.utm_zone)

                        local nodes = openstreetmap.temp.nodedata.elements
                        local ways = openstreetmap.temp.waydata.elements
                        openstreetmap.place_nodes_in_realm(nodes, new_realm)
                        openstreetmap.place_ways_in_realm(nodes, ways, new_realm)

                        -- Save the context and reload the controller fs for user to assign textures to the avaialable key-values
                        reload = true
                    else
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

                        if context.selected_realm_type == mc_teacher.R.CAT_KEY.PRIVATE then
                            new_realm = mc_worldManager.GetCreateInstancedRealm(realm_name, player, nil, false, realm_size)
                        else
                            -- TODO: refactor realm.lua so that it can generate realms of non-block-aligned sizes
                            new_realm = Realm:New(realm_name, realm_size)
                        end
                        
                        new_realm:CreateBarriersFast()
                        new_realm:CreateGround(context.selected_surface_itemstring or "default:dirt_with_grass", context.fill_depth + 1 or 1)
                        new_realm:FillBelowGround(context.selected_fill_itemstring or "default:dirt", context.fill_depth)
                        new_realm:UpdateSpawn({x = math.ceil(realm_size.x / 2), y = math.min(context.fill_depth + 2, realm_size.y - 3), z = math.ceil(realm_size.z / 2)})
                        
                        if tonumber(context.selected_decorator) == 2 then
                            -- If the decorator is 2, then we add the biome on top
                        else
                            -- If the decorator is 1, then we are done
                            reload = true
                        end
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

                    if context.selected_realm_type == mc_teacher.R.CAT_KEY.PRIVATE then
                        new_realm = mc_worldManager.GetCreateInstancedRealm(realm_name, player, context.selected_schematic, false)
                    else
                        new_realm = Realm:NewFromSchematic(realm_name, context.selected_schematic)
                    end
                elseif context.selected_mode == mc_teacher.MODES.RANDOM then
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

                    if context.selected_realm_type == mc_teacher.R.CAT_KEY.PRIVATE then
                        new_realm = mc_worldManager.GetCreateInstancedRealm(realm_name, player, nil, false, realm_size)
                    else
                        -- TODO: refactor realm.lua so that it can generate realms of non-block-aligned sizes
                        new_realm = Realm:New(realm_name, realm_size)
                    end
                    
                    -- Generate random terrain
                    if fields.realm_seed then context.realm_seed = fields.realm_seed end
                    if fields.realm_sealevel then context.realm_sealevel = fields.realm_sealevel end

                    local rgi = {
                        --height_func = mc_teacher.R.GEN_MAP[context.realm_gen or "1"],
                        height_func = "v2",
                        seed = context.realm_seed ~= "" and tonumber(context.realm_seed) or math.random(1, 999999999),
                        sea_level = new_realm.StartPos.y + (context.realm_sealevel ~= "" and tonumber(context.realm_sealevel) or 30),
                    }
                    if rgi.height_func ~= "nil" then
                        local param_table = {}
                        if fields.realm_chill and fields.realm_chill ~= "" and tonumber(fields.realm_chill) then
                            table.insert(param_table, fields.realm_chill)
                        end
                        if context.realm_biome and context.i_to_biome then
                            table.insert(param_table, context.i_to_biome[context.realm_biome])
                        end
                        local heightMapTable = new_realm:GenerateTerrain(rgi.seed, rgi.sea_level, rgi.height_func, param_table)

                        if tonumber(context.selected_decorator) == 3 then
                            -- Decorator is OPENSTREETMAP
                            openstreetmap.temp.realmID = new_realm.ID
                            local utmInfo = { zone = openstreetmap.temp.utm_zone, utm_is_north = openstreetmap.temp.utm_zone_is_north, easting = openstreetmap.temp.min_easting, northing = openstreetmap.temp.min_northing }
                            new_realm:set_data("UTMInfo", utmInfo)
    
                            local nodes = openstreetmap.temp.nodedata.elements
                            local ways = openstreetmap.temp.waydata.elements
                            openstreetmap.place_nodes_in_realm(nodes, new_realm, heightMapTable)
                            openstreetmap.place_ways_in_realm(nodes, ways, new_realm, heightMapTable)
    
                            -- Save the context and reload the controller fs for user to assign textures to the avaialable key-values
                            reload = true
                        elseif tonumber(context.selected_decorator) == 2 then

                        end
                    else

                    end

                    reload = true
                elseif context.selected_mode == mc_teacher.MODES.LIDAR then

                    if tonumber(context.selected_decorator) == 2 then
                        -- Ground
                        local GroundVoxelMap, xmin, ymin, zmin, xmax, ymax, zmax = LASFile.createVoxelMap(LASFile.temp.points, 2)
                        if not GroundVoxelMap or not xmin or not ymin or not zmin or not xmax or not ymax or not zmax then
                            return minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] The provided LAS file is not classified so no classroom can be created."))
                        else
                            minetest.chat_send_all("DEBUG: xmin = "..xmin)
                            minetest.chat_send_all("DEBUG: xmax = "..xmax)
                            minetest.chat_send_all("DEBUG: ymin = "..ymin)
                            minetest.chat_send_all("DEBUG: ymax = "..ymax)
                            -- Below ensures that all voxelMaps have the same dims as the ground
                            LASFile.temp.sizeX = math.ceil(xmax - xmin) + 1
                            minetest.chat_send_all("DEBUG: LASFile.temp.sizeX = "..LASFile.temp.sizeX)
                            LASFile.temp.sizeY = math.ceil(ymax - ymin) + 1
                            minetest.chat_send_all("DEBUG: LASFile.temp.sizeY = "..LASFile.temp.sizeY)
                            LASFile.temp.sizeZ = math.max(math.ceil(LASFile.temp.lasheader.MaxZ + 80), 80) -- The height will always be a minimum of 80 nodes or a buffer of 80 nodes above the max Z of the LAS
                            LASFile.temp.minX = xmin
                            LASFile.temp.minY = ymin
                            LASFile.temp.minZ = zmin
                            LASFile.temp.maxX = xmax
                            LASFile.temp.maxY = ymax
                            LASFile.temp.maxZ = zmax
    
                            -- Filter ground noise at/near sea level
                            local GroundFilteredVoxelMap = LASFile.filter_ground_noise(GroundVoxelMap, 5)
                    
                            -- Fill -inf ground values with Inverse Distance Weighted value
                            for x = 1, LASFile.temp.sizeX do
                                for y = 1, LASFile.temp.sizeY do
                                    if GroundFilteredVoxelMap[x][y] == -math.huge then
                                        local imputed_value = LASFile.Impute_IDW(x, y, GroundFilteredVoxelMap)
                                        if imputed_value ~= -math.huge then
                                            GroundFilteredVoxelMap[x][y] = imputed_value
                                        end
                                    end
                                end
                            end
                            LASFile.GroundVoxelMap = GroundFilteredVoxelMap
                    
                            -- Vegetation
                            if not LASFile.temp.lowveg and LASFile.temp.ground then
                                -- Classify vegetation if the ground exists and it is not already classified
                                local LowVegVoxelMap, MediumVegVoxelMap, HighVegVoxelMap = LASFile.classify_vegetation_voxelmaps(LASFile.temp.points, LASFile.temp.minX, LASFile.temp.minY, LASFile.temp.maxX, LASFile.temp.maxY, LASFile.temp.GroundVoxelMap)
                                LASFile.temp.LowVegVoxelMap = LowVegVoxelMap
                                LASFile.temp.MediumVegVoxelMap = MediumVegVoxelMap
                                LASFile.temp.HighVegVoxelMap = HighVegVoxelMap
                            else
                                local LowVegVoxelMap, _, _, _, _, _, _ = LASFile.createVoxelMap(LASFile.temp.points, 3)
                                local MediumVegVoxelMap, _, _, _, _, _, _ = LASFile.createVoxelMap(LASFile.temp.points, 4)
                                local HighVegVoxelMap, _, _, _, _, _, _ = LASFile.createVoxelMap(LASFile.temp.points, 5)
                                LASFile.temp.LowVegVoxelMap = LowVegVoxelMap
                                LASFile.temp.MediumVegVoxelMap = MediumVegVoxelMap
                                LASFile.temp.HighVegVoxelMap = HighVegVoxelMap
                            end
                    
                            -- Find tree stems
                            -- 1. Initialize a new voxelmap
                            local TreeStemVoxelMap = {}
                            for x = 1, LASFile.temp.sizeX do
                                TreeStemVoxelMap[x] = {}
                                for y = 1, LASFile.temp.sizeY do
                                    TreeStemVoxelMap[x][y] = -math.huge
                                end
                            end
                    
                            -- 2. Calculate focal maxima of the high vegetation voxelmap
                            local LocalMaximaVoxelMap = LASFile.peak_local_max(LASFile.temp.HighVegVoxelMap, 5)
                    
                            -- 3. Check for clustered maxima and calculate the centroid position in such cases
                            local labeledVoxelMap = LASFile.label_regions(LocalMaximaVoxelMap)
                            local centralPositions = LASFile.find_central_positions(LocalMaximaVoxelMap, labeledVoxelMap)
                    
                            -- 4. Write out the maximum elevations from the LocalMaximaVoxelMap into our final TreeStemVoxelMap
                            for _, pos in ipairs(centralPositions) do
                                TreeStemVoxelMap[pos.x][pos.y] = LocalMaximaVoxelMap[pos.x][pos.y].value
                            end
                            LASFile.temp.TreeStemVoxelMap = TreeStemVoxelMap
                    
                            -- Buildings
                            local BuildingVoxelMap, _, _, _, _, _, _ = LASFile.createVoxelMap(LASFile.temp.points, 6, LASFile.minX, LASFile.minY, LASFile.minZ, LASFile.maxX, LASFile.maxY, LASFile.maxZ)
                            LASFile.temp.BuildingVoxelMap = BuildingVoxelMap
    
                            -- Note here we switch LAS Z and Y for the minetest convention
                            minetest.chat_send_all("DEBUG: creating realm")
                            new_realm = Realm:New(realm_name or "LAS", { x = LASFile.temp.sizeX, y = LASFile.temp.sizeZ, z = LASFile.temp.sizeY }, false)
                            minetest.chat_send_all("DEBUG: created realm")
    
                            -- Remove the buffer from the EndPos x,z so that the map fits snuggly in the new realm (add 1 for the barrier)
                            new_realm.EndPos.x = new_realm.StartPos.x + LASFile.temp.sizeX + 1
                            new_realm.EndPos.y = new_realm.StartPos.y + LASFile.temp.sizeZ + 1 -- LASFile Z is minetest Y
                            new_realm.EndPos.z = new_realm.StartPos.z + LASFile.temp.sizeY + 1 -- LASFile Y is minetest Z
                            new_realm.MetaStorage.emerge = true
    
                            new_realm:CreateGround()
                            minetest.chat_send_all("DEBUG: created ground")
                            new_realm:CreateBarriersFast()
                            --[[ -- TODO: get the UTM projection information from the header
                            local utmInfo = { zone = 10, utm_is_north = true, easting = LASFile.temp.minX, northing = LASFile.temp.minY }
                            new_realm:set_data("UTMInfo", utmInfo) ]]
                            new_realm:CallOnCreateCallbacks()
    
                            reload = true
                        end
                    elseif tonumber(context.selected_decorator) == 3 then
                        -- TODO: Get any user-entered key-values submitted for query
                        new_realm = Realm:New(realm_name or "OSM", { x = openstreetmap.temp.sizeX, y = openstreetmap.temp.sizeY, z = openstreetmap.temp.sizeZ })
                        openstreetmap.temp.realmID = new_realm.ID
                        new_realm:CreateGround(context.selected_surface_itemstring or "default:dirt_with_grass", context.fill_depth + 1 or 1)
                        new_realm:FillBelowGround(context.selected_fill_itemstring or "default:dirt", context.fill_depth)
                        new_realm:UpdateSpawn({x = math.ceil(realm_size.x / 2), y = math.min(context.fill_depth + 2, realm_size.y - 3), z = math.ceil(realm_size.z / 2)})
                        new_realm:CreateBarriersFast()
                        local utmInfo = { zone = openstreetmap.temp.utm_zone, utm_is_north = openstreetmap.temp.utm_zone_is_north, easting = openstreetmap.temp.min_easting, northing = openstreetmap.temp.min_northing }
                        new_realm:set_data("UTMInfo", utmInfo)

                        local nodes = openstreetmap.temp.nodedata.elements
                        local ways = openstreetmap.temp.waydata.elements
                        openstreetmap.place_nodes_in_realm(nodes, new_realm)
                        openstreetmap.place_ways_in_realm(nodes, ways, new_realm)

                        -- Save the context and reload the controller fs for user to assign textures to the avaialable key-values
                        reload = true
                    else
                        -- No selection has been made yet, do not allow the user to submit anything
                    end
                end

                new_realm:AddOwner(player:get_player_name())
                if context.selected_realm_type == mc_teacher.R.CAT_KEY.SPAWN then
                    mc_worldManager.SetSpawnRealm(new_realm)
                    minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Server spawn classroom updated!"))
                else
                    new_realm:setCategoryKey(mc_teacher.R.CAT_MAP[context.selected_realm_type or mc_teacher.R.CAT_KEY.RESTRICTED])
                end
                new_realm:UpdateRealmPrivilege(context.selected_privs)
                new_realm:UpdateSkybox(context.skyboxes[context.selected_skybox])
                -- TODO: allow volume to be set
                new_realm:UpdateMusic(context.music[context.selected_music], 100)
                minetest.chat_send_player(player:get_player_name(),minetest.colorize(mc_core.col.log, "[Minetest Classroom] Your requested classroom was successfully created."))
                reload = true
            end
        end

        if fields.c_hidden_delete then
            local realm = Realm.GetRealm(tonumber(context.realm_i_to_id[context.selected_realm]))
            if not realm then
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] This classroom has already been deleted."))
            elseif realm:isDeleted() then
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] This classroom is currently being deleted."))
            elseif tonumber(context.realm_i_to_id[context.selected_realm]) == mc_worldManager.spawnRealmID then
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not delete the spawn classroom."))
            else
                return mc_teacher.show_confirm_popup(player, "confirm_hidden_delete", {
                    action = "Are you sure you want to delete this classroom?\nClassroom deletion is irreversible, may take a while to complete, and can cause the server to become unresponsive.",
                    button = "Delete"
                }, {x = 9.2, y = 4.3})
            end
        elseif fields.c_hidden_deleteall then
            local deletion_active = false
            for _,id in pairs(context.realm_i_to_id) do
                local realm = Realm.GetRealm(tonumber(id))
                if realm and not realm:isDeleted() and tonumber(id) ~= mc_worldManager.spawnRealmID then
                    deletion_active = true
                    break
                end
            end
            if deletion_active then
                return mc_teacher.show_confirm_popup(player, "confirm_hidden_deleteall", {
                    action = "Are you sure you want to delete all of these classrooms?\nClassroom deletion is irreversible, may take a while to complete, and can cause the server to become unresponsive.",
                    button = "Delete all"
                }, {x = 9, y = 4.3})
            else
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] No classrooms are available to delete."))
            end
            reload = true
        elseif fields.c_edit then
            if not context.selected_realm then context.selected_realm = 1 end
            if context.realm_i_to_id[context.selected_realm] and Realm.GetRealm(tonumber(context.realm_i_to_id[context.selected_realm])) then
                return mc_teacher.show_edit_popup(player, context.realm_i_to_id[context.selected_realm])
            else
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] The classroom you requested is no longer available."))
            end
        elseif fields.c_hide or fields.c_hidden_restore then
            local realm = Realm.GetRealm(tonumber(context.realm_i_to_id[context.selected_realm]))
            if realm then
                if tonumber(context.realm_i_to_id[context.selected_realm]) == mc_worldManager.spawnRealmID then
                    minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not hide the spawn classroom."))
                else
                    Realm.ScanForPlayerRealms()
                    if fields.c_hide and realm:GetPlayerCount() > 0 then
                        return mc_teacher.show_confirm_popup(player, "confirm_hide_occupied", {
                            action = "There are currently players in this classroom. Are you sure you want to hide it?\nAny players inside the classroom will be teleported to the server spawn if it gets hidden.",
                            button = "Hide classroom"
                        }, {x = 9, y = 4.3})
                    else
                        realm:setHidden(fields.c_hide and true)
                    end
                end
            else
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] The classroom you requested is no longer available."))
            end
            reload = true
        end

        if fields.music then
            context.selected_music = fields.music
            -- local background_sound = 
            -- play music as sample
            --[[minetest.sound_play(backgroundSound, {
                to_player = player:get_player_name(),
                gain = 1,
                object = player,
                loop = false
            })]]
            reload = true
        elseif fields.realm_biome and context.realm_biome ~= fields.realm_biome then
            context.realm_biome = fields.realm_biome
        end

        ---------------------------
        --  CLASSROOMS + PLAYERS --
        ---------------------------
        if fields.allowpriv_interact or fields.denypriv_interact or fields.ignorepriv_interact then
            local change = fields.allowpriv_interact or fields.denypriv_interact or fields.ignorepriv_interact
            context.selected_privs.interact = (change == "false" and "nil") or (fields.allowpriv_interact and true) or (fields.ignorepriv_interact and "nil") or false
            reload = true
        end
        if fields.allowpriv_shout or fields.denypriv_shout or fields.ignorepriv_shout then
            local change = fields.allowpriv_shout or fields.denypriv_shout or fields.ignorepriv_shout
            context.selected_privs.shout = (change == "false" and "nil") or (fields.allowpriv_shout and true) or (fields.ignorepriv_shout and "nil") or false
            reload = true
        end
        if fields.allowpriv_fast or fields.denypriv_fast or fields.ignorepriv_fast then
            local change = fields.allowpriv_fast or fields.denypriv_fast or fields.ignorepriv_fast
            context.selected_privs.fast = (change == "false" and "nil") or (fields.allowpriv_fast and true) or (fields.ignorepriv_fast and "nil") or false
            reload = true
        end
        if fields.allowpriv_fly or fields.denypriv_fly or fields.ignorepriv_fly then
            local change = fields.allowpriv_fly or fields.denypriv_fly or fields.ignorepriv_fly
            context.selected_privs.fly = (change == "false" and "nil") or (fields.allowpriv_fly and true) or (fields.ignorepriv_fly and "nil") or false
            reload = true
        end
        if fields.allowpriv_noclip or fields.denypriv_noclip or fields.ignorepriv_noclip then
            local change = fields.allowpriv_noclip or fields.denypriv_noclip or fields.ignorepriv_noclip
            context.selected_privs.noclip = (change == "false" and "nil") or (fields.allowpriv_noclip and true) or (fields.ignorepriv_noclip and "nil") or false
            reload = true
        end
        if fields.allowpriv_give or fields.denypriv_give or fields.ignorepriv_give then
            local change = fields.allowpriv_give or fields.denypriv_give or fields.ignorepriv_give
            context.selected_privs.give = (change == "false" and "nil") or (fields.allowpriv_give and true) or (fields.ignorepriv_give and "nil") or false
            reload = true
        end

        -------------
        -- PLAYERS --
        -------------
        if fields.p_list_header and context.selected_p_tab ~= fields.p_list_header then
            context.selected_p_tab = fields.p_list_header
            context.selected_p_player = 1
            context.selected_privs = nil
            context.p_list = nil
            reload = true
        end
        if fields.p_list then
            local event = minetest.explode_table_event(fields.p_list)
            if event.type == "CHG" and context.selected_p_player ~= event.row then
                context.selected_p_player = tonumber(event.row)
                context.selected_privs = nil
                reload = true
            end
        end
        if fields.p_mode_selected then
            context.selected_p_mode = mc_teacher.PMODE.SELECTED
            context.p_list = nil
            reload = true
        elseif fields.p_mode_tab then
            context.selected_p_mode = mc_teacher.PMODE.TAB
            context.p_list = nil
            reload = true
        elseif fields.p_mode_all then
            context.selected_p_mode = mc_teacher.PMODE.ALL
            context.p_list = nil
            reload = true
        end

        if fields.p_group_new then
            return mc_teacher.show_group_popup(player, nil)
        elseif fields.p_group_edit then
            if tonumber(context.selected_p_tab) > mc_teacher.PTAB.N then
                return mc_teacher.show_group_popup(player, tonumber(context.selected_p_tab))
            else
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] This group can not be edited."))
            end
            context.p_list = nil
            reload = true
        elseif fields.p_group_delete then
            if tonumber(context.selected_p_tab) > mc_teacher.PTAB.N then
                return mc_teacher.show_confirm_popup(player, "confirm_group_delete", {
                    action = "Are you sure you want to delete this group?",
                    button = "Delete group", irreversible = true,
                })
            else
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] This group can not be deleted."))
            end
            context.p_list = nil
            reload = true
        elseif fields.p_priv_update or fields.p_priv_reset then
            local players_to_update = get_players_to_update(player, context, true)
            local realm = Realm.GetRealmFromPlayer(player)
            if realm and #players_to_update > 0 then
                for _,p in pairs(players_to_update) do
                    if fields.p_priv_reset then
                        realm:ClearRealmPrivilegeOverride(p)
                    else
                        realm:UpdateRealmPrivilegeOverride(context.selected_privs or {}, p)
                    end
                    local p_obj = minetest.get_player_by_name(p)
                    if p_obj and p_obj:is_player() then
                        realm:ApplyPrivileges(p_obj)
                    end
                end
                if fields.p_priv_reset then
                    context.selected_privs = nil
                end
            end
            minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Player privileges updated!"))
            context.p_list = nil
            reload = true
        elseif fields.p_kick then
            -- TODO: add custom kick message to popup
            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
            if #players_to_update <= 0 then
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] There are no players selected."))
            elseif #players_to_update == 1 and players_to_update[1] == pname then
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not kick yourself from the server."))
            else
                return mc_teacher.show_kick_popup(player, #players_to_update)
            end
            context.p_list = nil
            reload = true
        elseif fields.p_ban then
            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
            if #players_to_update <= 0 then
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] There are no players selected."))
            elseif #players_to_update == 1 and players_to_update[1] == pname then
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not ban yourself from the server."))
            else
                local p_count_string = (#players_to_update == 1 and "this player" or "these "..tostring(#players_to_update).." players")
                return mc_teacher.show_confirm_popup(player, "confirm_player_ban", {
                    action = "Are you sure you want to ban "..p_count_string.." from the server?\nThis can only be undone by a server administrator.",
                    button = "Ban player"..(#players_to_update == 1 and "" or "s")
                }, {y = 3.8})
            end
            context.p_list = nil
            reload = true
        elseif fields.p_teleport then
            local pname = player:get_player_name()
            local sel_pname = context.p_list[context.selected_p_player]
            local sel_pobj = minetest.get_player_by_name(sel_pname or "")
            if sel_pname and sel_pobj then
                if not mc_core.is_frozen(player) then
                    local destination = sel_pobj:get_pos()
                    local realm = Realm.GetRealmFromPlayer(sel_pobj)
                    if realm and realm:Joinable(player) then
                        if mc_teacher.is_in_timeout(player) and realm.ID ~= (Realm.GetRealmFromPlayer(player) or {ID = 0}).ID then
                            minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not join other classrooms while in timeout."))
                        else
                            realm:TeleportPlayer(player)
                            player:set_pos(destination)
                            minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Teleported to player "..tostring(sel_pname).."!"))
                        end
                    else
                        minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Could not teleport to player "..tostring(sel_pname).."."))
                    end
                else
                    minetest.chat_send_player(player:get_player_name(),minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not move while frozen."))
                end
            else
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Could not find the selected player!"))
            end
            context.p_list = nil
            reload = true
        elseif fields.p_bring then
            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
            local destination = player:get_pos()
            local destRealm = Realm.GetRealmFromPlayer(player)
            if destRealm and not destRealm:isDeleted() then
                if #players_to_update <= 0 then
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] There are no players selected."))
                end
                for _, p in pairs(players_to_update) do
                    local p_obj = minetest.get_player_by_name(p)
                    if destRealm:Joinable(p_obj) then
                        mc_core.temp_unfreeze_and_run(p_obj, function()
                            destRealm:TeleportPlayer(p_obj)
                            p_obj:set_pos(destination)
                        end)
                    else
                        minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Player "..tostring(p).." does not have access to your current classroom. Please check your current classroom's category and try again."))
                    end
                end
            else
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Your current classroom could not be found! Please ask a server administrator to check that this classroom exists."))
            end
            context.p_list = nil
            reload = true
        elseif fields.p_audience then
            ---Audience action adapted from actions.lua in rubenwardy's classroom mod
            ---@see https://gitlab.com/rubenwardy/classroom/-/blob/master/actions.lua
            ---@license MIT: https://gitlab.com/rubenwardy/classroom/-/blob/1e7b11f824c03c882d74d5079d8275f3e297adea/LICENSE.txt

            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
            local realm = Realm.GetRealmFromPlayer(player)
            if #players_to_update <= 0 then
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] There are no players selected."))
            elseif #players_to_update == 1 and players_to_update[1] == pname then
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not create an audience containing only yourself."))
            elseif realm and realm:Joinable(player) then
                local eye_height = player:get_properties().eye_height
                local teacher_pos = vector.add(player:get_pos(), {x = 0, y = eye_height, z = 0})
                local res = mc_teacher.create_audience(players_to_update, realm, player:get_player_name(), teacher_pos, player:get_look_dir())
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] "..(res and "Audience created!" or "Could not fully create the requested audience, use the bring action instead.")))
            else
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] You no longer have access to this classroom."))
            end
        elseif fields.p_mute or fields.p_unmute then
            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
            if #players_to_update <= 0 then
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] There are no players selected."))
            end
            for _,p in pairs(players_to_update) do
                if p ~= pname then
                    local p_obj = minetest.get_player_by_name(p)
                    if p_obj then
                        if fields.p_mute then
                            mc_worldManager.denyUniversalPriv(p_obj, {"shout"})
                        else
                            mc_worldManager.grantUniversalPriv(p_obj, {"shout"})
                        end
                        local realm = Realm.GetRealmFromPlayer(p_obj)
                        if realm then realm:ApplyPrivileges(p_obj) end
                    else
                        minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Could not "..(fields.p_mute and "" or "un").."mute player "..tostring(p).." (they are probably offline)."))
                    end
                else
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not "..(fields.p_mute and "" or "un").."mute yourself."))
                end
            end
            context.p_list = nil
            reload = true
        elseif fields.p_freeze or fields.p_unfreeze then
            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
            if #players_to_update <= 0 then
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] There are no players selected."))
            end
            for _,p in pairs(players_to_update) do
                if p ~= pname then
                    local p_obj = minetest.get_player_by_name(p)
                    if p_obj then
                        if fields.p_freeze then
                            mc_core.freeze(p_obj)
                        else
                            mc_core.unfreeze(p_obj)
                        end
                    else
                        minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Could not "..(fields.p_freeze and "" or "un").."freeze player "..tostring(p).." (they are probably offline)."))
                    end
                else
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not "..(fields.p_freeze and "" or "un").."freeze yourself."))
                end
            end
            context.p_list = nil
            reload = true
        elseif fields.p_timeout or fields.p_endtimeout then
            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
            if #players_to_update <= 0 then
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] There are no players selected."))
            end
            for _,p in pairs(players_to_update) do
                if p ~= pname then
                    local p_obj = minetest.get_player_by_name(p)
                    if p_obj then
                        if fields.p_timeout then
                            mc_teacher.timeout(p_obj)
                        else
                            mc_teacher.end_timeout(p_obj)
                        end
                    else
                        minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Could not "..(fields.p_timeout and "timeout" or "end timeout for").." player "..tostring(p).." (they are probably offline)."))
                    end
                else
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not "..(fields.p_timeout and "put yourself in timeout" or "end your own timeout").."."))
                end
            end
            context.p_list = nil
            reload = true
        elseif fields.p_deactivate or fields.p_reactivate then
            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
            if #players_to_update <= 0 then
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] There are no players selected."))
            end
            for _,p in pairs(players_to_update) do
                if p ~= pname then
                    local p_obj = minetest.get_player_by_name(p)
                    if p_obj then
                        if fields.p_deactivate then
                            mc_worldManager.denyUniversalPriv(p_obj, {"interact"})
                        else
                            mc_worldManager.grantUniversalPriv(p_obj, {"interact"})
                        end
                        local realm = Realm.GetRealmFromPlayer(p_obj)
                        if realm then realm:ApplyPrivileges(p_obj) end
                    else
                        minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Could not "..(fields.p_deactivate and "de" or "re").."activate player "..tostring(p).." (they are probably offline)."))
                    end
                else
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not "..(fields.p_deactivate and "de" or "re").."activate yourself."))
                end
            end
            context.p_list = nil
            reload = true
        elseif has_server_privs and (fields.p_role_student or fields.p_role_teacher or fields.p_role_admin) then
            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
            if #players_to_update <= 0 then
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] There are no players selected."))
            elseif #players_to_update == 1 and players_to_update[1] == pname then
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not change your own server role."))
            else
                local p_count_string = (#players_to_update == 1 and "this player" or "these "..tostring(#players_to_update).." players")
                if fields.p_role_student then
                    return mc_teacher.show_confirm_popup(player, "role_change_"..mc_teacher.ROLES.STUDENT,
                        {action = "Are you sure you want "..p_count_string.." to be "..pluralize(#players_to_update, mc_teacher.ROLES.STUDENT).."?"}
                    )
                else
                    local role = fields.p_role_admin and mc_teacher.ROLES.ADMIN or mc_teacher.ROLES.TEACHER
                    return mc_teacher.show_confirm_popup(player, "role_change_"..role,
                        {action = "Are you sure you want "..p_count_string.." to be "..pluralize(#players_to_update, role).."?\nThis will give them access to tools which can be used to modify the server."},
                        {y = 4.3}
                    )
                end
            end
            context.p_list = nil
            reload = true
        end

        ----------------
        -- MODERATION --
        ----------------
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
            local server_msg = minetest.deserialize(mc_teacher.meta:get_string("server_log")) or {}

            local player_to_clear = context.indexed_chat_players[context.player_chat_index]
            if chat_msg and chat_msg[player_to_clear] then
                chat_msg[player_to_clear] = nil
            end
            if direct_msg and direct_msg[player_to_clear] then
                direct_msg[player_to_clear] = nil
            end
            if server_msg and server_msg[player_to_clear] then
                -- anonymous server messages should not be removed if they are listed under "Server"
                local new_server_msg = (not has_server_privs and {}) or nil
                if not has_server_privs and server_msg[player_to_clear] then
                    for _,msg_table in pairs(server_msg[player_to_clear]) do
                        if msg_table.anonymous then
                            table.insert(new_server_msg, msg_table)
                        end
                    end
                end
                server_msg[player_to_clear] = new_server_msg
            end

            mc_teacher.meta:set_string("chat_log", minetest.serialize(chat_msg))
            mc_teacher.meta:set_string("dm_log", minetest.serialize(direct_msg))
            mc_teacher.meta:set_string("server_log", minetest.serialize(server_msg))
            reload = true
        elseif fields.mod_mute or fields.mod_unmute then
            local player_to_mute = context.indexed_chat_players[context.player_chat_index]
            local pname = player:get_player_name()

            if player_to_mute ~= pname then
                local p_obj = minetest.get_player_by_name(player_to_mute)
                if p_obj then
                    if fields.mod_mute then
                        mc_worldManager.denyUniversalPriv(p_obj, {"shout"})
                    else
                        mc_worldManager.grantUniversalPriv(p_obj, {"shout"})
                    end
                    local realm = Realm.GetRealmFromPlayer(p_obj)
                    if realm then realm:ApplyPrivileges(p_obj) end
                else
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Could not "..(fields.mod_mute and "" or "un").."mute player "..tostring(player_to_mute).." (they are probably offline)."))
                end
            else
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not "..(fields.mod_mute and "" or "un").."mute yourself."))
            end
        elseif fields.mod_send_message then
            local pname = player:get_player_name()
            if fields.mod_message ~= "" then
                local recipient = context.indexed_chat_players[context.player_chat_index]
                -- TODO: save recipient name so that messages can be sent regardless of whether the log exists
                if recipient then
                    minetest.chat_send_player(recipient, "DM from "..pname..": "..fields.mod_message)
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Message sent!"))
                    mc_teacher.log_direct_message(pname, fields.mod_message, recipient)
                    reload = true
                else
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Could not send message to player."))
                end
            else
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not send an empty message to a player."))
            end
        end

        -------------
        -- REPORTS --
        -------------
        if fields.report_log then
            local event = minetest.explode_textlist_event(fields.report_log)
            if event.type == "CHG" then
                context.selected_report = event.index
                reload = true
            end
        end
        if fields.report_delete then
            local report_log = minetest.deserialize(mc_teacher.meta:get_string("report_log")) or {}
            local selected = context.report_i_to_idx[context.selected_report]
            if selected then
                report_log[selected] = nil
                mc_teacher.meta:set_string("report_log", minetest.serialize(report_log))
                reload = true
            end
        elseif fields.report_clearlog then
            return mc_teacher.show_confirm_popup(player, "confirm_report_clear", {
                action = "Are you sure you want to clear the report log?",
                button = "Clear log", irreversible = true,
            })
        elseif fields.report_send_message then
            if fields.report_message ~= "" then
                local pname = player:get_player_name()
                local report_log = minetest.deserialize(mc_teacher.meta:get_string("report_log")) or {}
                local selected = report_log[context.report_i_to_idx[context.selected_report]]
                -- TODO: save reporter name in context so that messages can be sent regardless of whether the report exists
                if selected then
                    minetest.chat_send_player(selected.player, "DM from "..pname..": "..fields.report_message)
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Message sent!"))
                    mc_teacher.log_direct_message(pname, fields.report_message, selected.player)
                else
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Could not send message to reporter."))
                end
            else
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not send an empty message to a player."))
            end
        end

        ----------------------------------------
        -- SERVER (ADDITIONAL PRIVS REQUIRED) --
        ----------------------------------------
        if has_server_privs then
            if fields.server_dyn_header and context.selected_s_tab ~= fields.server_dyn_header then
                context.selected_s_tab = fields.server_dyn_header
                reload = true
            end

            if fields.server_send_students or fields.server_send_teachers or fields.server_send_admins or fields.server_send_all then
                if fields.server_message ~= "" then
                    local message_map = {
                        [mc_teacher.M.MODE.SERVER_ANON] = function()
                            return minetest.colorize(mc_core.col.log, "[Minetest Classroom] "..fields.server_message)
                        end,
                        [mc_teacher.M.MODE.SERVER_PLAYER] = function()
                            return minetest.colorize(mc_core.col.log, "[Minetest Classroom] From "..player:get_player_name()..": "..fields.server_message)
                        end,
                        [mc_teacher.M.MODE.PLAYER] = function()
                            return "<"..player:get_player_name().."> "..fields.server_message
                        end,
                    }

                    fields.server_message_type = fields.server_message_type or mc_teacher.M.MODE.SERVER_ANON
                    local message = message_map[fields.server_message_type]()

                    if fields.server_send_students then
                        for name,_ in pairs(mc_teacher.students) do
                            minetest.chat_send_player(name, message)
                        end
                        minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Message sent!"))
                        mc_teacher.log_server_message(player:get_player_name(), fields.server_message, mc_teacher.M.RECIP.STUDENT, fields.server_message_type == mc_teacher.M.MODE.SERVER_ANON)
                    elseif fields.server_send_teachers then
                        for name,_ in pairs(mc_teacher.teachers) do
                            minetest.chat_send_player(name, message)
                        end
                        minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Message sent!"))
                        mc_teacher.log_server_message(player:get_player_name(), fields.server_message, mc_teacher.M.RECIP.TEACHER, fields.server_message_type == mc_teacher.M.MODE.SERVER_ANON)
                    elseif fields.server_send_admins then
                        for _,p_obj in pairs(minetest.get_connected_players()) do
                            if p_obj:is_player() and mc_core.checkPrivs(p_obj, {teacher = true, server = true}) then
                                minetest.chat_send_player(p_obj:get_player_name(), message)
                            end
                        end
                        minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Message sent!"))
                        mc_teacher.log_server_message(player:get_player_name(), fields.server_message, mc_teacher.M.RECIP.ADMIN, fields.server_message_type == mc_teacher.M.MODE.SERVER_ANON)
                    else
                        minetest.chat_send_all(message)
                        minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Message sent!"))
                        mc_teacher.log_server_message(player:get_player_name(), fields.server_message, mc_teacher.M.RECIP.ALL, fields.server_message_type == mc_teacher.M.MODE.SERVER_ANON)
                    end
                else
                    minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Server messages can not be empty."))
                end
            elseif fields.server_shutdown_cancel then
                mc_teacher.cancel_shutdown()
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Server restart successfully cancelled!"))
                minetest.chat_send_all(minetest.colorize(mc_core.col.log, "[Minetest Classroom] The scheduled server restart has been cancelled."))
                reload = true
            elseif fields.server_shutdown_schedule then
                context.server_shutdown_timer = fields.server_shutdown_timer
                return mc_teacher.show_confirm_popup(player, "confirm_shutdown_schedule", {
                    action = "Are you sure you want to schedule a server shutdown in "..context.server_shutdown_timer.." from now?\nClassrooms will be saved prior to the shutdown.",
                    button = "Schedule"
                }, {x = 9.2, y = 3.9})
            elseif fields.server_shutdown_now then
                return mc_teacher.show_confirm_popup(player, "confirm_shutdown_now", {
                    action = "Are you sure you want to perform a server shutdown right now?\nClassrooms will be saved prior to the shutdown."
                }, {x = 9.2, y = 3.5})
            elseif fields.server_dyn then
                local event = minetest.explode_textlist_event(fields.server_dyn)
                if event.type == "CHG" then
                    context.selected_s_dyn = event.index
                end
                reload = true
            elseif fields.server_unban then
                context.selected_s_dyn = context.selected_s_dyn or 1
                if mc_core.trim(context.server_dyn_list or "") ~= "" then
                    local bans = mc_core.split(context.server_dyn_list, ",")
                    if bans[context.selected_s_dyn] and mc_core.trim(bans[context.selected_s_dyn]) ~= "" then
                        local ban_split = mc_core.split(bans[context.selected_s_dyn], "|")
                        if ban_split and ban_split[1] then
                            minetest.unban_player_or_ip(ban_split[1])
                            minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Player unbanned!"))
                        else
                            minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Player could not be unbanned. Please unban this player by using the /unban command instead."))
                        end
                    else
                        minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Player could not be unbanned. Please unban this player by using the /unban command instead."))
                    end
                else
                    minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] There are no players to unban."))
                end
                reload = true
            elseif fields.server_whitelist then
                return mc_teacher.show_whitelist_popup(player)
            end
            
            -- SERVER + OVERVIEW
            if fields.server_edit_rules then
                return minetest.show_formspec(player:get_player_name(), "mc_rules:edit", mc_rules.show_edit_formspec(nil))
            end
        end

        -------------
        -- GENERAL --
        -------------
        if fields.exit or fields.quit then
            if context.selected_privs_mode == mc_teacher.TABS.PLAYERS then
                context.selected_privs = nil
            end
            context.skyboxes = nil
            context.tab = nil
        elseif reload then
            -- CLASSROOM --
            if fields.realmname then context.realmname = minetest.formspec_escape(fields.realmname) end
            if fields.realm_x_size then context.realm_x = fields.realm_x_size end
            if fields.realm_y_size then context.realm_y = fields.realm_y_size end
            if fields.realm_z_size then context.realm_z = fields.realm_z_size end
            if fields.realm_seed then context.realm_seed = fields.realm_seed end
            if fields.realm_sealevel then context.realm_sealevel = fields.realm_sealevel end
            if fields.realm_chill then context.realm_chill = fields.realm_chill end
            if fields.osm_extent_maxlat then context.osm_extent_maxlat = fields.osm_extent_maxlat end
            if fields.osm_extent_minlat then context.osm_extent_minlat = fields.osm_extent_minlat end
            if fields.osm_extent_maxlon then context.osm_extent_maxlon = fields.osm_extent_maxlon end
            if fields.osm_extent_minlon then context.osm_extent_minlon = fields.osm_extent_minlon end
            -- MODERATION --
            if fields.mod_message then context.mod_message = minetest.formspec_escape(fields.mod_message) end
            -- REPORTS --
            if fields.report_message then context.report_message = minetest.formspec_escape(fields.report_message) end
            -- SERVER --
            if fields.server_message then context.server_message = minetest.formspec_escape(fields.server_message) end
            if fields.server_message_type then context.server_message_type = fields.server_message_type end
            if fields.server_shutdown_timer then
                context.time_index = mc_teacher.T_INDEX[fields.server_shutdown_timer] and mc_teacher.T_INDEX[fields.server_shutdown_timer].i
            end
            mc_teacher.show_controller_fs(player, context.tab)
        end
    end
end)

----------------------------------------
-- COMMON (mc_teacher and mc_student) --
----------------------------------------
minetest.register_on_player_receive_fields(function(player, formname, fields)
    local pmeta = player:get_meta()
    local context

    if string.sub(formname, 1, 10) == "mc_student" and mc_core.checkPrivs(player, {interact = true}) then
        context = mc_student.get_fs_context(player)
    elseif string.sub(formname, 1, 10) == "mc_teacher" and mc_core.checkPrivs(player, {teacher = true}) then
        context = mc_teacher.get_fs_context(player)
    else
        return false
    end

    local wait = os.clock()
    while os.clock() - wait < 0.05 do end --popups don't work without this

    local reload = false

    if formname == "mc_student:notebook_fs" or formname == "mc_teacher:controller_fs" then
        ----------------
        -- CLASSROOMS --
        ----------------
        if fields.c_list_header and context.selected_c_tab ~= fields.c_list_header then
            context.selected_c_tab = fields.c_list_header
            context.selected_realm = 1
            reload = true
        end
        if fields.classroomlist then
            local event = minetest.explode_textlist_event(fields.classroomlist)
            if event.type == "CHG" then
                context.selected_realm = tonumber(event.index)
                if not Realm.GetRealm(context.realm_i_to_id[context.selected_realm]) then
                    context.selected_realm = 1
                end
                reload = true
            end
        elseif fields.c_teleport then
            -- Still a remote possibility that the realm is deleted in the time that the callback is executed
            -- So always check that the requested realm exists and the realm category allows the player to join
            -- Check that the player selected something from the textlist, otherwise default to spawn realm
            if not context.selected_realm then context.selected_realm = 1 end
            local realm = Realm.GetRealm(context.realm_i_to_id[context.selected_realm])
            if realm and not realm:isDeleted() and (not realm:isHidden() or mc_core.checkPrivs(player, {teacher = true})) then
                if mc_core.is_frozen(player) then
                    minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not move while frozen."))
                elseif mc_teacher.is_in_timeout(player) then
                    minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not join other classrooms while in timeout."))
                else
                    realm:TeleportPlayer(player)
                    context.selected_realm = 1
                end
            else
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] The classroom you requested is no longer available."))
            end
            reload = true
        end

        ---------
        -- MAP --
        ---------
        if fields.record and fields.note then
            local clean_note = mc_core.trim(string.gsub(fields.note, "\n+", " "))
            if clean_note ~= "" then 
                mc_core.record_coordinates(player, clean_note)
                reload = true
            else
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not record a location without a note."))
            end
        elseif fields.coordlist then
            local event = minetest.explode_textlist_event(fields.coordlist)
            if event.type == "CHG" then
                context.selected_coord = event.index
            end
        elseif fields.mark then
            if mc_core.checkPrivs(player, {shout = true}) or mc_core.checkPrivs(player, {teacher = true}) then
                local pdata = minetest.deserialize(pmeta:get_string("coordinates"))
                if pdata and pdata.note_map then
                    local realm = Realm.GetRealmFromPlayer(player)
                    if not context.selected_coord or not context.coord_i_to_note[context.selected_coord] then
                        context.selected_coord = 1
                    end
                    local note_to_mark = context.coord_i_to_note[context.selected_coord]
                    mc_core.queue_marker(player, note_to_mark, pdata.coords[pdata.note_map[note_to_mark]], formname == "mc_student:notebook_fs" and mc_student.marker_expiry or mc_teacher.marker_expiry)
                    minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Marker placed!"))
                else
                    minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Selected coordinate not found! Please report this issue to a server administrator."))
                end
            else
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] You do not have sufficient privileges to mark coordinates."))
            end
        elseif fields.go then
            if not mc_core.is_frozen(player) then
                local pdata = minetest.deserialize(pmeta:get_string("coordinates"))
                if pdata and pdata.note_map then
                    if not context.selected_coord or not context.coord_i_to_note[context.selected_coord] then
                        context.selected_coord = 1
                    end
                    local note_name = context.coord_i_to_note[context.selected_coord]
                    local note_i = pdata.note_map[note_name]
                    local realm = Realm.GetRealm(pdata.realms[note_i])
                    if realm and realm:Joinable(player)then
                        realm:TeleportPlayer(player)
                        player:set_pos(pdata.coords[note_i])
                    else
                        minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] You no longer have access to this classroom."))
                    end
                else
                    minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Selected coordinate not found! Please report this issue to a server administrator."))
                end
            else
                minetest.chat_send_player(player:get_player_name(),minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not move while frozen."))
            end
            reload = true
        elseif fields.go_all then
            local pdata = minetest.deserialize(pmeta:get_string("coordinates"))
            if pdata and pdata.note_map then
                if not context.selected_coord or not context.coord_i_to_note[context.selected_coord] then
                    context.selected_coord = 1
                end
                local note_name = context.coord_i_to_note[context.selected_coord]
                local note_i = pdata.note_map[note_name]
                local realm = Realm.GetRealm(pdata.realms[note_i])
                if realm then
                    for _,p_obj in pairs(minetest.get_connected_players()) do
                        if p_obj:get_player_name() ~= player:get_player_name() or not mc_core.is_frozen(p_obj) then
                            local p_realm = Realm.GetRealmFromPlayer(p_obj)
                            if p_realm and p_realm.ID == tonumber(pdata.realms[note_i]) and realm:Joinable(p_obj) then
                                realm:TeleportPlayer(p_obj)
                                p_obj:set_pos(pdata.coords[note_i])
                            end
                        else
                            minetest.chat_send_player(player:get_player_name(),minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not move while frozen."))
                        end
                    end
                else
                    minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] This classroom no longer exists."))
                end
            else
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Selected coordinate not found! Please report this issue to a server administrator."))
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
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Selected coordinate not found! Please report this issue to a server administrator."))
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
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Saved coordinates not found! Please report this issue to a server administrator."))
            end
            reload = true
        elseif fields.share then
            local pdata = minetest.deserialize(pmeta:get_string("coordinates"))
            if pdata and pdata.note_map then
                local realm = Realm.GetRealmFromPlayer(player)
                if not context.selected_coord or not context.coord_i_to_note[context.selected_coord] then
                    context.selected_coord = 1
                end
                local note = context.coord_i_to_note[context.selected_coord]
                local realmID = pdata.realms[pdata.note_map[note]]
                local pos = pdata.coords[pdata.note_map[note]]
                local loc = {
                    x = tostring(math.round(pos.x - realm.StartPos.x)),
                    y = tostring(math.round(pos.y - realm.StartPos.y)),
                    z = tostring(math.round(pos.z - realm.StartPos.z)),
                }

                local message = "[Minetest Classroom] "..player:get_player_name().." shared"
                if (mc_core.checkPrivs(player, {shout = true}) or mc_core.checkPrivs(player, {teacher = true})) and note ~= "" then
                    message = message.." \""..note.."\", located at"
                else
                    message = message.." the location"
                end
                message = message.." (x="..loc.x..", y="..loc.y..", z="..loc.z..")"

                for _,connplayer in pairs(minetest.get_connected_players()) do 
                    local connRealm = Realm.GetRealmFromPlayer(connplayer)
                    if connRealm.ID == realmID then
                        minetest.chat_send_player(connplayer:get_player_name(), minetest.colorize(mc_core.col.log, message))
                    end
                end
            else
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Selected coordinate not found! Please report this issue to a server administrator."))
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

        -------------
        -- REPORTS --
        -------------
        if fields.submit_report then
			if not fields.report_body or fields.report_body == "" then
				return minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Please add a message to your report."))
			end

			local pname = player:get_player_name() or "unknown"
			local pos = player:get_pos() or {x = 0, y = 0, z = 0}
			local realm = Realm.GetRealmFromPlayer(player) or {Name = "Unknown", ID = 0}
			local clean_report = minetest.formspec_escape(fields.report_body)
			local report_type = fields.report_type or "Other"
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
						"  ", string.upper(report_type), ": ", fields.report_body, "\n", details,
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
			minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Your report has been received."))
            reload = true
		end

        if reload == true then
            if formname == "mc_student:notebook_fs" then
                mc_student.show_notebook_fs(player, context.tab)
            elseif formname == "mc_teacher:controller_fs" then
                mc_teacher.show_controller_fs(player, context.tab)
            end
        end
    end
end)
