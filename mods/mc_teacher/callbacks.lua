-- Privileges
minetest.register_privilege("teacher", {
    give_to_singleplayer = true
})
minetest.register_privilege("student", {
    give_to_singleplayer = true
})

-- Frozen players
minetest.register_entity("mc_teacher:frozen_player", {
	-- This entity needs to be visible otherwise the frozen player won't be visible.
	initial_properties = {
		visual = "sprite",
		visual_size = { x = 0, y = 0 },
		textures = {"blank.png"},
		physical = false, -- Disable collision
		pointable = false, -- Disable selection box
		makes_footstep_sound = false,
	},

	on_step = function(self, dtime)
		local player = self.pname and minetest.get_player_by_name(self.pname)
		if not player or not mc_teacher.is_frozen(player) then
			self.object:remove()
			return
		end
	end,

	set_frozen_player = function(self, player)
		self.pname = player:get_player_name()
		player:set_attach(self.object, "", {x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 0 })
	end,
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

minetest.register_on_joinplayer(function(player)
    local pname = player:get_player_name()
    local pmeta = player:get_meta()

    if not pmeta:get("priv_format") then
        local privs = minetest.get_player_privs(pname)
        privs["student"] = true
        minetest.set_player_privs(pname, privs)
        pmeta:set_int("priv_format", 2)
    end

    if minetest.check_player_privs(player, {teacher = true}) then
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

    if mc_teacher.is_frozen(player) then
		mc_teacher.freeze(player)
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

local function pluralize(count, role_string)
    local map = {
        [mc_teacher.ROLES.NONE] = {
            [true] = role_string,
            [false] = role_string,
        },
        [mc_teacher.ROLES.STUDENT] = {
            [true] = "a "..role_string,
            [false] = role_string.."s",
        },
        [mc_teacher.ROLES.TEACHER] = {
            [true] = "a "..role_string,
            [false] = role_string.."s",
        },
        [mc_teacher.ROLES.ADMIN] = {
            [true] = "an "..role_string,
            [false] = role_string.."s",
        }
    }
    return role_string and map[role_string] and map[role_string][count == 1] or "???"
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
        if fields.confirm then
            mc_teacher.meta:set_string("report_log", minetest.serialize({}))
            minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] The report log has been cleared."))
        end
        mc_teacher.show_controller_fs(player, context.tab)
    elseif formname == "mc_teacher:ban_manager" and has_server_privs then
        if fields.ban_list then
            local event = minetest.explode_textlist_event(fields.ban_list)
            if event.type == "CHG" then
                context.selected_ban = event.index
            end
        end
        if fields.unban then
            context.selected_ban = context.selected_ban or 1
            local ban_string = minetest.get_ban_list() or ""
            local bans = mc_core.split(ban_string, ",")
            if bans[context.selected_ban] then
                minetest.unban_player_or_ip(bans[context.selected_ban])
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Player unbanned!"))
            end
        elseif fields.quit or fields.exit then
            mc_teacher.show_controller_fs(player, context.tab)
        end
    elseif formname == "mc_teacher:role_change_"..mc_teacher.ROLES.NONE or formname == "mc_teacher:role_change_"..mc_teacher.ROLES.STUDENT
    or (has_server_privs and (formname == "mc_teacher:role_change_"..mc_teacher.ROLES.TEACHER or formname == "mc_teacher:role_change_"..mc_teacher.ROLES.ADMIN)) then
        if fields.confirm then
            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
            for _,p in pairs(players_to_update) do
                if p == pname then
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not change your own server role."))
                end
                local p_obj = minetest.get_player_by_name(p)
                if not p_obj or not p_obj:is_player() then
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Could not change server role of player "..tostring(p).." (they are probably offline)."))
                end
                if formname == "mc_teacher:role_change_"..mc_teacher.ROLES.NONE then
                    mc_worldManager.revokeUniversalPriv(p_obj, {"student", "teacher", "server"})
                    mc_teacher.register_student(p)
                elseif formname == "mc_teacher:role_change_"..mc_teacher.ROLES.STUDENT then
                    mc_worldManager.grantUniversalPriv(p_obj, {"student"})
                    mc_worldManager.revokeUniversalPriv(p_obj, {"teacher", "server"})
                    mc_teacher.register_student(p)
                elseif has_server_privs and formname == "mc_teacher:role_change_"..mc_teacher.ROLES.TEACHER then
                    mc_worldManager.grantUniversalPriv(p_obj, {"student", "teacher"})
                    mc_worldManager.revokeUniversalPriv(p_obj, {"server"})
                    mc_teacher.register_teacher(p)
                elseif has_server_privs and formname == "mc_teacher:role_change_"..mc_teacher.ROLES.ADMIN then
                    mc_worldManager.grantUniversalPriv(p_obj, {"student", "teacher", "server"})
                    mc_teacher.register_teacher(p)
                else
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Could not change server role of player "..tostring(p).."."))
                end
            end
            minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Server role changes applied!"))
        end
        mc_teacher.show_controller_fs(player, context.tab)
    elseif formname == "mc_teacher:controller_fs" then
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
        if fields.class_opt_scroll then
            local event = minetest.explode_scrollbar_event(fields.class_opt_scroll)
            if event.type == "CHG" then
                context.class_opt_scroll = event.value
            end
        end
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
        if fields.realm_generator and fields.realm_generator ~= context.realm_gen then
            context.realm_gen = fields.realm_generator
            reload = true
        end
        if fields.realm_decorator and fields.realm_decorator ~= context.realm_dec then
            context.realm_dec = fields.realm_decorator
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

                    -- Generate realm terrain
                    local rgi = {
                        height_func =  mc_teacher.R.GEN_MAP[context.realm_gen or "1"],
                        dec_func = mc_teacher.R.DEC_MAP[context.realm_dec or "1"],
                        seed = context.realm_seed ~= "" and tonumber(context.realm_seed) or math.random(1, 999999999),
                        sea_level = new_realm.StartPos.y + (context.realm_sealevel ~= "" and tonumber(context.realm_sealevel) or 30),
                    }
                    if rgi.height_func ~= "nil" then
                        local param_table = {}
                        if fields.realm_chill and fields.realm_chill ~= "" and tonumber(fields.realm_chill) then
                            table.insert(param_table, fields.realm_chill)
                        end
                        if fields.realm_biome and fields.realm_biome ~= "" then
                            table.insert(param_table, fields.realm_biome)
                        end
                        new_realm:GenerateTerrain(rgi.seed, rgi.sea_level, rgi.height_func, rgi.dec_func, param_table)
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
            local realm = Realm.GetRealm(context.selected_realm_id)
            if realm then
                if not mc_teacher.is_frozen(player) then
                    realm:TeleportPlayer(player)
                    context.selected_realm_id = nil
                else
                    minetest.chat_send_player(player:get_player_name(),minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not move while frozen."))
                end
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

        --  CLASSROOMS + PLAYERS
        if fields.allowpriv_interact or fields.denypriv_interact or fields.ignorepriv_interact then
            context.selected_privs.interact = (fields.allowpriv_interact and true) or (fields.ignorepriv_interact and "nil") or false
            reload = true
        end
        if fields.allowpriv_shout or fields.denypriv_shout or fields.ignorepriv_shout then
            context.selected_privs.shout = (fields.allowpriv_shout and true) or (fields.ignorepriv_shout and "nil") or false
            reload = true
        end
        if fields.allowpriv_fast or fields.denypriv_fast or fields.ignorepriv_fast then
            context.selected_privs.fast = (fields.allowpriv_fast and true) or (fields.ignorepriv_fast and "nil") or false
            reload = true
        end
        if fields.allowpriv_fly or fields.denypriv_fly or fields.ignorepriv_fly then
            context.selected_privs.fly = (fields.allowpriv_fly and true) or (fields.ignorepriv_fly and "nil") or false
            reload = true
        end
        if fields.allowpriv_noclip or fields.denypriv_noclip or fields.ignorepriv_noclip then
            context.selected_privs.noclip = (fields.allowpriv_noclip and true) or (fields.ignorepriv_noclip and "nil") or false
            reload = true
        end
        if fields.allowpriv_give or fields.denypriv_give or fields.ignorepriv_give then
            context.selected_privs.give = (fields.allowpriv_give and true) or (fields.ignorepriv_give and "nil") or false
            reload = true
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
            local event = minetest.explode_table_event(fields.p_list)
            if event.type == "CHG" and context.selected_p_player ~= event.row then
                context.selected_p_player = tonumber(event.row)
                reload = true
            end
        end
        if fields.p_mode_selected then
            context.selected_p_mode = mc_teacher.PMODE.SELECTED
            reload = true
        elseif fields.p_mode_tab then
            context.selected_p_mode = mc_teacher.PMODE.TAB
            reload = true
        elseif fields.p_mode_all then
            context.selected_p_mode = mc_teacher.PMODE.ALL
            reload = true
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
                            if v ~= "nil" then
                                realm.PermissionsOverride[p][priv] = v
                            else
                                realm.PermissionsOverride[p][priv] = nil
                            end
                        end
                    else
                        realm.PermissionsOverride[p] = nil
                    end
                    local p_obj = minetest.get_player_by_name(p)
                    if p_obj and p_obj:is_player() then
                        realm:ApplyPrivileges(p_obj)
                    end
                end
            end
            minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Player privileges updated!"))
            reload = true
        elseif fields.p_kick then
            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
            for _,p in pairs(players_to_update) do
                if p ~= pname then
                    local success = minetest.kick_player(p)
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Successfully kicked player "..(success and p.." from the server." or "Could not kick "..p.." from the server.")))
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
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Successfully banned player "..(success and p.." from the server." or "Could not ban "..p.." from the server.")))
                else
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not ban yourself from the server."))
                end
            end
        elseif fields.p_teleport then
            local pname = player:get_player_name()
            local sel_pname = context.p_list[context.selected_p_player]
            local sel_pobj = minetest.get_player_by_name(sel_pname or "")
            if sel_pname and sel_pobj then
                if not mc_teacher.is_frozen(player) then
                    local destination = sel_pobj:get_pos()
                    local realm = Realm.GetRealmFromPlayer(sel_pobj)
                    if realm and realm:getCategory().joinable(realm, player) then
                        realm:TeleportPlayer(player)
                        player:set_pos(destination)
                        minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Teleported to player "..tostring(sel_pname).."!"))
                    else
                        minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Could not teleport to player "..tostring(sel_pname).."."))
                    end
                else
                    minetest.chat_send_player(player:get_player_name(),minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not move while frozen."))
                end
            else
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Could not find the selected player!"))
            end
            reload = true
        elseif fields.p_bring then
            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
            local destination = player:get_pos()
            local destRealm = Realm.GetRealmFromPlayer(player)
            if destRealm then
                for _,p in pairs(players_to_update) do
                    local p_obj = minetest.get_player_by_name(p)
                    if p_obj and destRealm:getCategory().joinable(destRealm, player) then
                        destRealm:TeleportPlayer(p_obj)
                        p_obj:set_pos(destination)
                    else
                        minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Player "..tostring(p).." does not have access to your current classroom. Please check your current classroom's category and try again."))
                    end
                end
            else
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Your current classroom could not be found! Please ask a server administrator to check that this classroom exists."))
            end
        elseif fields.p_mute or fields.p_unmute then
            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
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
            reload = true
        elseif fields.p_freeze or fields.p_unfreeze then
            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
            for _,p in pairs(players_to_update) do
                if p ~= pname then
                    local p_obj = minetest.get_player_by_name(p)
                    if p_obj then
                        if fields.p_freeze then
                            mc_teacher.freeze(p_obj)
                        else
                            mc_teacher.unfreeze(p_obj)
                        end
                    else
                        minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Could not "..(fields.p_freeze and "" or "un").."freeze player "..tostring(p).." (they are probably offline)."))
                    end
                else
                    minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not "..(fields.p_freeze and "" or "un").."freeze yourself."))
                end
            end
            reload = true
        elseif fields.p_deactivate or fields.p_reactivate then
            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
            for _,p in pairs(players_to_update) do
                if p ~= pname then
                    local p_obj = minetest.get_player_by_name(p)
                    if p_obj then
                        if fields.p_mute then
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
            reload = true
        elseif fields.p_role_none or fields.p_role_student then
            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
            if #players_to_update <= 0 then
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] There are no players selected."))
            elseif #players_to_update == 1 and players_to_update[1] == pname then
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not change your own server role."))
            else
                local p_count_string = (#players_to_update == 1 and "this player" or "these "..tostring(#players_to_update).." players")
                local role_string = fields.p_role_student and mc_teacher.ROLES.STUDENT or mc_teacher.ROLES.NONE
                return mc_teacher.show_confirm_popup(player, "role_change_"..role_string,
                    {action = "Are you sure you want "..p_count_string.." to be "..pluralize(#players_to_update, role_string).."?"}
                )
            end
        elseif has_server_privs and (fields.p_role_teacher or fields.p_role_admin) then
            local players_to_update = get_players_to_update(player, context)
            local pname = player:get_player_name()
            if #players_to_update <= 0 then
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] There are no players selected."))
            elseif #players_to_update == 1 and players_to_update[1] == pname then
                minetest.chat_send_player(pname, minetest.colorize(mc_core.col.log, "[Minetest Classroom] You can not change your own server role."))
            else
                local p_count_string = (#players_to_update == 1 and "this player" or "these "..tostring(#players_to_update).." players")
                local role_string = fields.p_role_admin and mc_teacher.ROLES.ADMIN or mc_teacher.ROLES.TEACHER
                return mc_teacher.show_confirm_popup(player, "role_change_"..role_string,
                    {action = "Are you sure you want "..p_count_string.." to be "..pluralize(#players_to_update, role_string).."?\nThis will give them access to tools which can be used to modify the server."},
                    {y = 4.2}
                )
            end
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
            if fields.server_whitelist then
                local event = minetest.explode_textlist_event(fields.server_whitelist)
                if event.type == "CHG" then
                    context.selected_ip_range = event.index
                end
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
                mc_teacher.cancel_shutdown()
                local warn = {600, 540, 480, 420, 360, 300, 240, 180, 120, 60, 55, 50, 45, 40, 35, 30, 25, 20, 15, 10, 5, 4, 3, 2, 1}
                local time = mc_teacher.T_INDEX[fields.server_shutdown_timer].t
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Server restart successfully scheduled!"))
                minetest.chat_send_all(minetest.colorize(mc_core.col.log, "[Minetest Classroom] The server will be restarting in "..fields.server_shutdown_timer..". Classrooms will be saved prior to the restart."))
                mc_teacher.restart_scheduled.timer = minetest.after(time, mc_teacher.shutdown_server, true)
                for _,t in pairs(warn) do
                    if time >= t then
                        mc_teacher.restart_scheduled["warn"..tostring(t)] = minetest.after(time - t, mc_teacher.display_restart_time, t)
                    end
                end
                reload = true
            elseif fields.server_shutdown_now then
                mc_teacher.cancel_shutdown()
                mc_teacher.shutdown_server(true)
            elseif fields.server_ip_add or fields.server_ip_remove then
                if fields.server_ip_start and fields.server_ip_start ~= "" then
                    local add_cond = (fields.server_ip_remove == nil) or nil
                    if not fields.server_ip_end or fields.server_ip_end == "" then
                        networking.modify_ipv4(player, fields.server_ip_start, nil, add_cond)
                    else
                        local ips_ordered = networking.ipv4_compare(fields.server_ip_start, fields.server_ip_end)
                        local start_ip = ips_ordered and fields.server_ip_start or fields.server_ip_end
                        local end_ip = ips_ordered and fields.server_ip_end or fields.server_ip_start
                        networking.modify_ipv4(player, start_ip, end_ip, add_cond)
                    end
                end
                reload = true
            elseif fields.server_whitelist_remove then
                local ipv4_whitelist = minetest.deserialize(networking.storage:get_string("ipv4_whitelist"))
                local ip_whitelist = {}
                for ipv4,_ in pairs(ipv4_whitelist or {}) do
                    table.insert(ip_whitelist, ipv4)
                end
                table.sort(ip_whitelist, networking.ipv4_compare)

                local ip_to_remove = ip_whitelist[tonumber(context.selected_ip_range)]
                if ip_to_remove then
                    ipv4_whitelist[ip_to_remove] = nil
                    networking.storage:set_string("ipv4_whitelist", minetest.serialize(ipv4_whitelist))
                end
                reload = true
            elseif fields.server_whitelist_toggle then
                networking.toggle_whitelist(player)
                reload = true
            elseif fields.server_ban_manager then
                return mc_teacher.show_ban_popup(player)
            end
            
            -- SERVER + OVERVIEW
            if fields.server_edit_rules then
                return minetest.show_formspec(player:get_player_name(), "mc_rules:edit", mc_rules.show_edit_formspec(nil))
            end
        end

        -- GENERAL: RELOAD
        if reload then
            -- classroom
            if fields.realmname then context.realmname = minetest.formspec_escape(fields.realmname) end
            if fields.realm_x_size then context.realm_x = fields.realm_x_size end
            if fields.realm_y_size then context.realm_y = fields.realm_y_size end
            if fields.realm_z_size then context.realm_z = fields.realm_z_size end
            if fields.realm_seed then context.realm_seed = fields.realm_seed end
            if fields.realm_sealevel then context.realm_sealevel = fields.realm_sealevel end
            if fields.realm_chill then context.realm_chill = fields.realm_chill end
            -- moderation + reports
            if fields.mod_message then context.mod_message = minetest.formspec_escape(fields.mod_message) end
            if fields.report_message then context.report_message = minetest.formspec_escape(fields.report_message) end
            -- server
            if fields.server_message then context.server_message = minetest.formspec_escape(fields.server_message) end
            if fields.server_message_type then context.server_message_type = fields.server_message_type end
            if fields.server_ip_start then context.start_ip = minetest.formspec_escape(fields.server_ip_start) end
            if fields.server_ip_end then context.end_ip = minetest.formspec_escape(fields.server_ip_end) end
            if fields.server_shutdown_timer then
                context.time_index = mc_teacher.T_INDEX[fields.server_shutdown_timer] and mc_teacher.T_INDEX[fields.server_shutdown_timer].i
            end
            -- reload
            mc_teacher.show_controller_fs(player, context.tab)
        end
    end
end)

----------------------------------------------------
-- MAP (common to both mc_teacher and mc_student) --
----------------------------------------------------
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
        if fields.record and fields.note ~= "" then
            mc_core.record_coordinates(player, fields.note)
            reload = true
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
            if not mc_teacher.is_frozen(player) then
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
                        if p_obj:get_player_name() ~= player:get_player_name() or not mc_teacher.is_frozen(p_obj) then
                            local p_realm = Realm.GetRealmFromPlayer(p_obj)
                            if p_realm and p_realm.ID == tonumber(pdata.realms[note_i]) and realm:getCategory().joinable(realm, p_obj) then
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

        if reload == true then
            if formname == "mc_student:notebook_fs" then
                mc_student.show_notebook_fs(player, mc_student.TABS.MAP)
            elseif formname == "mc_teacher:controller_fs" then
                mc_teacher.show_controller_fs(player, mc_teacher.TABS.MAP)
            end
        end
    end
end)