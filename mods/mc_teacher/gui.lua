--- Returns a list containing the names of the given player's saved coordinates
local function get_saved_coords(player)
    local pmeta = player:get_meta()
    local realm = Realm.GetRealmFromPlayer(player)
    local pdata = minetest.deserialize(pmeta:get_string("coordinates"))
    local context = mc_teacher.get_fs_context(player)
    local coord_list = {}

    if pdata == nil or pdata == {} then
        context.coord_i_to_note = {}
        return coord_list
    elseif pdata.realms then
        local new_note_map, new_coords, new_realms = {}, {}, {}
        context.coord_i_to_note = {}

        for note,i in pairs(pdata.note_map) do
            local coordrealm = Realm.GetRealm(pdata.realms[i])
            if coordrealm then
                -- Do not include coordinates saved in other realms in output
                if realm and coordrealm.ID == realm.ID and note ~= "" then
                    table.insert(coord_list, note)
                    context.coord_i_to_note[#coord_list] = note
                end
                -- Remove coordinates saved in realms that no longer exist from database
                table.insert(new_coords, pdata.coords[i])
                table.insert(new_realms, pdata.realms[i])
                new_note_map[note] = #new_coords
            end
        end

        pmeta:set_string("coordinates", minetest.serialize({note_map = new_note_map, coords = new_coords, realms = new_realms, format = 2}))
        return coord_list
    end
end

function mc_teacher.show_controller_fs(player,tab)
    local controller_width = 16.6
    local controller_height = 10.4
    local panel_width = controller_width/2
    local spacer = 0.6
    local text_spacer = 0.55

    local pname = player:get_player_name()
    local pmeta = player:get_meta()
    local context = mc_teacher.get_fs_context(player)

    -- deprecated
    local page_width = (controller_width/8)*3.5

    if mc_core.checkPrivs(player) then
        local has_server_privs = mc_core.checkPrivs(player, {server = true})
        local tab_map = {
            [mc_teacher.TABS.OVERVIEW] = function() -- OVERVIEW
                local button_width = 1.7
                local button_height = 1.6
                local rules = mc_rules.meta:get_string("rules")
                if not rules or rules == "" then
                    rules = "Rules have not yet been set for this server."
                end

                local Y_SIZE, FACTOR = controller_height - 0.5, 0.05
                local fs = {
                    "image[0,0;", controller_width, ",0.5;mc_pixel.png^[multiply:#737373]",
                    "image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
                    "tooltip[exit;Exit;#404040;#ffffff]",
                    "hypertext[", text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Overview</b></center></style>]",
                    "hypertext[", panel_width + text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Dashboard</b></center></style>]",

                    "style_type[textarea;font=mono,bold;textcolor=#000000]",
                    "style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:#1e1e1e]",
                    "textarea[", text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Welcome to Minetest Classroom!]",
                    "textarea[", text_spacer, ",4.4;", panel_width - 2*text_spacer, ",1;;;Server Rules]",
                    "style_type[textarea;font=mono]",
                    "textarea[", text_spacer, ",1.5;", panel_width - 2*text_spacer, ",2.6;;;", minetest.formspec_escape("This is the Teacher Controller, your tool for managing classrooms, player privileges, and server settings."),
                    "\n", minetest.formspec_escape("You cannot drop this tool, so you will never lose it. However, you can move it out of your hotbar and into your inventory or the toolbox."), "]",
                    "textarea[", text_spacer, ",4.9;", panel_width - 2*text_spacer, ",", has_server_privs and 4 or 4.9, ";;;", minetest.formspec_escape(rules), "]",
                    has_server_privs and "button[0.6,9;7,0.8;server_edit_rules;Edit server rules]" or "",

                    "scrollbaroptions[min=0;max=", (11.6 + (has_server_privs and 1.7 or 0) - Y_SIZE)/FACTOR, ";smallstep=", 0.8/FACTOR, ";largestep=", 4.8/FACTOR, ";thumbsize=", 1/FACTOR, "]",
                    "scrollbar[", controller_width - 0.3, ",0.5;0.3,", Y_SIZE, ";vertical;overviewscroll;", context.overviewscroll or 0, "]",
                    "scroll_container[", panel_width, ",0.5;", panel_width, ",", Y_SIZE, ";overviewscroll;vertical;", FACTOR, "]",

                    "image_button[", spacer, ",0.5;", button_width, ",", button_height, ";mc_teacher_classrooms.png;classrooms;;false;false]",
                    "hypertext[", spacer + 1.8, ",0.8;5.35,1.6;;<style color=#000000><b>Classrooms</b>\n", minetest.formspec_escape("Create and manage classrooms"), "</style>]",
                    "image_button[", spacer, ",2.3;", button_width, ",", button_height, ";mc_teacher_map.png;map;;false;false]",
                    "hypertext[", spacer + 1.8, ",2.6;5.35,1.6;;<style color=#000000><b>Map</b>\n", minetest.formspec_escape("Record and share locations"), "</style>]",
                    "image_button[", spacer, ",4.1;", button_width, ",", button_height, ";mc_teacher_players.png;players;;false;false]",
                    "hypertext[", spacer + 1.8, ",4.4;5.35,1.6;;<style color=#000000><b>Players</b>\n", minetest.formspec_escape("Manage player privileges"), "</style>]",
                    "image_button[", spacer, ",5.9;", button_width, ",", button_height, ";mc_teacher_isometric_crop.png;moderation;;false;false]",
                    "hypertext[", spacer + 1.8, ",6.2;5.35,1.6;;<style color=#000000><b>Moderation</b>\n", minetest.formspec_escape("View player chat logs"), "</style>]",
                    "image_button[", spacer, ",7.7;", button_width, ",", button_height, ";mc_teacher_isometric_crop.png;reports;;false;false]",
                    "hypertext[", spacer + 1.8, ",8;5.35,1.6;;<style color=#000000><b>Reports</b>\n", minetest.formspec_escape("View and resolve player reports"), "</style>]",
                    "image_button[", spacer, ",9.5;", button_width, ",", button_height, ";mc_teacher_help.png;help;;false;false]",
                    "hypertext[", spacer + 1.8, ",9.8;5.35,1.6;;<style color=#000000><b>Help</b>\n", minetest.formspec_escape("View guides and resources"), "</style>]",
                }

                if has_server_privs then
                    table.insert(fs, table.concat({
                        "image_button[", spacer, ",11.3;", button_width, ",", button_height, ";mc_teacher_isometric_crop.png;server;;false;false]",
                        "hypertext[", spacer + 1.8, ",11.6;5.35,1.6;;<style color=#000000><b>Server</b>\n", minetest.formspec_escape("Manage server settings"), "</style>]",
                    }))
                end
                table.insert(fs, "scroll_container_end[]")

                return fs
            end,
            [mc_teacher.TABS.CLASSROOMS] = function() -- CLASSROOMS
                local classroom_list = {}
                local realm_count = 1
                context.realm_id_to_i = {}

                Realm.ScanForPlayerRealms()
                for id, realm in pairs(Realm.realmDict or {}) do
                    local playerCount = tonumber(realm:GetPlayerCount())
                    table.insert(classroom_list, table.concat({minetest.formspec_escape(realm.Name or ""), " (", playerCount, " player", playerCount == 1 and "" or "s", ")"}))
                    context.realm_id_to_i[tostring(id)] = realm_count
                    realm_count = realm_count + 1
                end

                local fs = {
                    "image[0,0;", controller_width, ",0.5;mc_pixel.png^[multiply:#737373]",
                    "image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
                    "tooltip[exit;Exit;#404040;#ffffff]",
                    "hypertext[", text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Classrooms</b></center></style>]",
                    "hypertext[", panel_width + text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Build a Classroom</b></center></style>]",

                    "style_type[textarea;font=mono,bold;textcolor=#000000]",
                    "style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:#1e1e1e]",
                    "textarea[", text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Available Classrooms]",
                    "textlist[", spacer, ",1.4;", panel_width - 2*spacer, ",7.5;classroomlist;", table.concat(classroom_list, ","), ";", context.realm_id_to_i and context.realm_id_to_i[context.selected_realm_id] or 1, ";false]",
                    "button[", spacer, ",9;2.3,0.8;teleportrealm;Teleport]",
                    "button[", spacer + 2.4, ",9;2.3,0.8;editrealm;Edit]",
                    "button[", spacer + 4.8, ",9;2.3,0.8;deleterealm;Delete]",

                    "style_type[field;font=mono;textcolor=#ffffff]",
                    "textarea[", panel_width + text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Name]",
                    "field[", panel_width + spacer, ",1.4;7.1,0.8;realmname;;", context.realmname or "", "]",
                    "field_close_on_enter[realmname;false]",
                    "textarea[", panel_width + text_spacer, ",2.25;3.6,1;;;Type]",
                    "dropdown[", panel_width + spacer, ",2.7;3.5,0.8;realmcategory;Default,Spawn,Classroom,Instanced" or "", ";", context.selected_realm_type or 1, ";true]",
                    "textarea[", panel_width + text_spacer + 3.6, ",2.25;3.6,1;;;Generation]",
                    "dropdown[", panel_width + spacer + 3.6, ",2.7;3.5,0.8;mode;Empty World,Schematic,Digital Twin" or "", ";", context.selected_mode or 1, ";true]",
                }

                if context.selected_mode == mc_teacher.MODES.EMPTY then
                    table.insert(fs, table.concat({
                        "textarea[", panel_width + text_spacer, ",3.6;", panel_width - 2*text_spacer, ",1;;;Classroom Size]",
                        "textarea[", panel_width + text_spacer, ",4.2;1,1;;;X =]",
                        "textarea[", panel_width + text_spacer + 2.4, ",4.2;1,1;;;Y =]",
                        "textarea[", panel_width + text_spacer + 4.8, ",4.2;1,1;;;Z =]",
                        "field[", panel_width + spacer + 0.9, ",4;1.3,0.8;realm_x_size;;", context.realm_x or 80, "]",
                        "field[", panel_width + spacer + 3.3, ",4;1.3,0.8;realm_y_size;;", context.realm_y or 80, "]",
                        "field[", panel_width + spacer + 5.7, ",4;1.3,0.8;realm_z_size;;", context.realm_z or 80, "]",
                        "field_close_on_enter[realm_x_size;false]",
                        "field_close_on_enter[realm_y_size;false]",
                        "field_close_on_enter[realm_z_size;false]",
                    }))
                elseif context.selected_mode == mc_teacher.MODES.SCHEMATIC then
                    local schematics = {}
                    local name_to_i = {}
                    local ctr = 1
                    for name, path in pairs(schematicManager.schematics) do
                        if ctr == 1 and not context.selected_schematic then
                            context.selected_schematic = name
                        end
                        table.insert(schematics, name)
                        name_to_i[name] = ctr
                    end
                    context.name_to_i = name_to_i

                    table.insert(fs, table.concat({
                        "textarea[", panel_width + text_spacer, ",3.6;", panel_width - 2*text_spacer, ",1;;;Schematic]",
                        "dropdown[", panel_width + spacer, ",4;", panel_width - 2*spacer, ",0.8;schematic;", table.concat(schematics, ","), ";", context.name_to_i[context.selected_schematic] or 1, ";false]",
                    }))
                elseif context.selected_mode == mc_teacher.MODES.TWIN then
                    local twins = {}
                    local name_to_i = {}
                    local ctr = 1
                    for name, path in pairs(realterrainManager.dems) do
                        if ctr == 1 and not context.selected_dem then
                            context.selected_dem = name
                        end
                        table.insert(twins, name)
                        name_to_i[name] = ctr
                    end
                    context.name_to_i = name_to_i

                    table.insert(fs, table.concat({
                        "textarea[", panel_width + text_spacer, ",3.6;", panel_width - 2*text_spacer, ",1;;;Digital Twin World]",
                        "dropdown[", panel_width + spacer, ",4;", panel_width - 2*spacer, ",0.8;realterrain;", table.concat(twins, ","), ";", context.name_to_i[context.selected_dem] or 1, ";false]",
                    }))
                else
                    table.insert(fs, table.concat({
                        "textarea[", panel_width + text_spacer, ",3.6;", panel_width - 2*text_spacer, ",1.2;;;Select a generation mode for more options!]",
                    }))
                end

                table.insert(fs, table.concat({
                    "textarea[", panel_width + text_spacer, ",4.9;", panel_width - 2*text_spacer, ",1;;;Default Privileges]",
                    "style_type[textarea;font=mono]",
                    "textarea[", panel_width + text_spacer + 0.5, ",5.3;1.9,1;;;interact]",
                    "textarea[", panel_width + text_spacer + 0.5, ",5.7;1.9,1;;;shout]",
                    "textarea[", panel_width + text_spacer + 2.9, ",5.3;1.9,1;;;fast]",
                    "textarea[", panel_width + text_spacer + 2.9, ",5.7;1.9,1;;;fly]",
                    "textarea[", panel_width + text_spacer + 5.3, ",5.3;1.9,1;;;noclip]",
                    "textarea[", panel_width + text_spacer + 5.3, ",5.7;1.9,1;;;give]",
                    "checkbox[", panel_width + spacer, ",5.5;priv_interact;;", context.selected_privs.interact or "false", "]",
                    "checkbox[", panel_width + spacer, ",5.9;priv_shout;;", context.selected_privs.shout or "false", "]",
                    "checkbox[", panel_width + spacer + 2.4, ",5.5;priv_fast;;", context.selected_privs.fast or "false", "]",
                    "checkbox[", panel_width + spacer + 2.4, ",5.9;priv_fly;;", context.selected_privs.fly or "false", "]",
                    "checkbox[", panel_width + spacer + 4.8, ",5.5;priv_noclip;;", context.selected_privs.noclip or "false", "]",
                    "checkbox[", panel_width + spacer + 4.8, ",5.9;priv_give;;", context.selected_privs.give or "false", "]",

                    "style_type[textarea;font=mono,bold]",
                    "textarea[", panel_width + text_spacer, ",6.2;", panel_width - 2*text_spacer, ",1;;;Background Music]",
                    "dropdown[", panel_width + spacer, ",6.6;", panel_width - 2*spacer, ",0.8;bgmusic;None;1;false]",
                    "textarea[", panel_width + text_spacer, ",7.5;", panel_width - 2*text_spacer, ",1;;;Skybox]",
                    "dropdown[", panel_width + spacer, ",7.9;", panel_width - 2*spacer, ",0.8;skybox;Default;1;false]",
                    "button[", panel_width + spacer, ",9;", panel_width - 2*spacer, ",0.8;requestrealm;Generate Classroom]",
                }))

                return fs
                -- TODO: Background Music and skyboxes
                -- method: local backgroundSound = realm:get_data("background_sound")]]
            end,
            [mc_teacher.TABS.MAP] = function() -- MAP
                local map_x = spacer + 0.025
                local map_y = 1.425
                local fs = {
                    "image[0,0;", controller_width, ",0.5;mc_pixel.png^[multiply:#737373]",
                    "image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
                    "tooltip[exit;Exit;#404040;#ffffff]",
                    "hypertext[", text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Map</b></center></style>]",
                    "hypertext[", panel_width + text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Coordinates</b></center></style>]",
                    "style_type[textarea;font=mono,bold;textcolor=#000000]",
                    "textarea[", text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Surrounding Area]",
                    "image[", map_x - 0.025, ",", map_y - 0.025, ";7.1,7.1;mc_pixel.png^[multiply:#000000]",
                    "image[", map_x, ",", map_y, ";7.05,7.05;mc_pixel.png^[multiply:#808080]",
                }
                
                local bounds = {xmin = -24, xmax = 24, zmin = -24, zmax = 24}
                local mapar = mc_mapper.map_handler(player, bounds)
                for i = 1, bounds.xmax - bounds.xmin - 1, 1 do
                    for j = 1, bounds.zmax - bounds.zmin - 1, 1 do
                        if mapar[i][j].im ~= nil then
                            -- The following for colorbrewer integration
                            if mapar[i][j].pa then
                                local y_im = math.ceil(mapar[i][j].p2/16)
                                local x_im = mapar[i][j].p2-((y_im-1)*16)
                                mapar[i][j].im = mapar[i][j].pa.."_palette.png\\^[sheet\\:16x16:"..tostring(x_im).."\\,"..tostring(y_im) -- double backslash required to first escape lua and then escape the API
                            end
                            if mapar[i][j].y ~= mapar[i][j+1].y then mapar[i][j].im = mapar[i][j].im .. "^(mc_mapper_blockb.png^[transformR180)" end
                            if mapar[i][j].y ~= mapar[i][j-1].y then mapar[i][j].im = mapar[i][j].im .. "^(mc_mapper_blockb.png)" end
                            if mapar[i][j].y ~= mapar[i-1][j].y then mapar[i][j].im = mapar[i][j].im .. "^(mc_mapper_blockb.png^[transformR270)" end
                            if mapar[i][j].y ~= mapar[i+1][j].y then mapar[i][j].im = mapar[i][j].im .. "^(mc_mapper_blockb.png^[transformR90)" end
                            table.insert(fs, table.concat({
                                "image[", map_x + 0.15*(i - 1), ",", map_y + 0.15*(bounds.zmax - bounds.zmin - j - 1),
                                ";0.15,0.15;", mapar[i][j].im, "]";
                            }))
                        end
                    end
                end

                local yaw = player:get_look_yaw()
                local rotate = 0
                if yaw ~= nil then
                    -- Find rotation and texture based on yaw.
                    yaw = math.fmod(mc_mapper.round_to_texture_multiple(math.deg(yaw)), 360)
                    if yaw < 90 then
                        rotate = 90
                    elseif yaw < 180 then
                        rotate = 180
                    elseif yaw < 270 then
                        rotate = 270
                    else
                        rotate = 0
                    end
                    yaw = math.fmod(yaw, 90)
                end
                local pos = player:get_pos()
                local round_px, round_pz = math.round(pos.x), math.round(pos.z)

                table.insert(fs, table.concat({
                    "image[", 3.95 + (pos.x - round_px)*0.15, ",", 4.75 - (pos.z - round_pz)*0.15,
                    ";0.4,0.4;mc_mapper_d", yaw, ".png^[transformFY", rotate ~= 0 and ("R"..rotate) or "", "]",
                    "textarea[", text_spacer, ",8.6;", panel_width - 2*text_spacer, ",1;;;Coordinate and Elevation Display]",
                    "style_type[button,image_button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:#1e1e1e]",
                    "button[", spacer, ",9;1.7,0.8;utmcoords;UTM]",
                    "button[", spacer + 1.8, ",9;1.7,0.8;latloncoords;Lat/Lon]",
                    "button[", spacer + 3.6, ",9;1.7,0.8;classroomcoords;Local]",
                    "button[", spacer + 5.4, ",9;1.7,0.8;coordsoff;Off]",
                    "textarea[", panel_width + text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Saved Coordinates]",
                }))

                local coord_list = get_saved_coords(player)
                table.insert(fs, table.concat({
                    "textlist[", panel_width + spacer, ",1.4;", panel_width - 2*spacer, ",4.8;coordlist;", coord_list and #coord_list > 0 and table.concat(coord_list, ",") or "No coordinates saved!", ";", context.selected_coord or 1, ";false]",
                    coord_list and #coord_list > 0 and "" or "style_type[image_button;bgimg=mc_pixel.png^[multiply:#acacac]",
                    "image_button[", panel_width + spacer, ",6.3;1.1,1.1;mc_teacher_teleport.png;", coord_list and #coord_list > 0 and "go" or "blocked", ";;false;false]",
                    "image_button[", panel_width + spacer + 1.2, ",6.3;1.1,1.1;mc_teacher_teleport_all.png;", coord_list and #coord_list > 0 and "go_all" or "blocked", ";;false;false]",
                    "image_button[", panel_width + spacer + 2.4, ",6.3;1.1,1.1;mc_teacher_share.png;", coord_list and #coord_list > 0 and "share" or "blocked", ";;false;false]",
                    "image_button[", panel_width + spacer + 3.6, ",6.3;1.1,1.1;mc_teacher_mark.png;", coord_list and #coord_list > 0 and "mark" or "blocked", ";;false;false]",
                    "image_button[", panel_width + spacer + 4.8, ",6.3;1.1,1.1;mc_teacher_delete.png;", coord_list and #coord_list > 0 and "delete" or "blocked", ";;false;false]",
                    "image_button[", panel_width + spacer + 6.0, ",6.3;1.1,1.1;mc_teacher_clear.png;", coord_list and #coord_list > 0 and "clear" or "blocked", ";;false;false]",
                    
                    coord_list and #coord_list > 0 and "" or "style_type[button;bgimg=mc_pixel.png^[multiply:#1e1e1e]",
                    "textarea[", panel_width + text_spacer, ",8.5;", panel_width - 2*text_spacer, ",1;;;Save current coordinates]",
                    "style_type[textarea;font=mono]",
                    "textarea[", panel_width + text_spacer, ",7.6;", panel_width - 2*text_spacer, ",1;;;SELECTED\nLocal: (X, Y, Z)]",
                    "textarea[", panel_width + spacer, ",8.9;6.2,0.9;note;;]",
                    "style_type[image_button;bgimg=mc_pixel.png^[multiply:#1e1e1e]",
                    "image_button[15.1,8.9;0.9,0.9;mc_teacher_save.png;record;Save;false;false]",
                    
                    "tooltip[utmcoords;Displays real-world UTM coordinates;#404040;#ffffff]",
                    "tooltip[latloncoords;Displays real-world latitude and longitude;#404040;#ffffff]",
                    "tooltip[classroomcoords;Displays in-game coordinates, relative to the classroom;#404040;#ffffff]",
                    "tooltip[coordsoff;Disables coordinate display;#404040;#ffffff]",
                    "tooltip[go;Teleport to location;#404040;#ffffff]",
                    "tooltip[go_all;Teleport all players to location;#404040;#ffffff]",
                    "tooltip[share;Share location in chat;#404040;#ffffff]",
                    "tooltip[mark;Place marker in world;#404040;#ffffff]",
                    "tooltip[delete;Delete location;#404040;#ffffff]",
                    "tooltip[clear;Clear all saved locations;#404040;#ffffff]",
                    "tooltip[note;Add a note here!;#404040;#ffffff]",
                    "style_type[image_button;bgimg=blank.png]",
                }))

                return fs
            end,
            [mc_teacher.TABS.PLAYERS] = function() -- PLAYERS
                context.selected_p_tab = context.selected_p_tab or "1"
                context.selected_p_player = context.selected_p_player or 1
                context.selected_p_mode = context.selected_p_mode or mc_teacher.PMODE.SELECTED

                if not context.p_list then
                    context.p_list = {}
                    if context.selected_p_tab == "1" then
                        for student,_ in pairs(mc_teacher.students) do
                            table.insert(context.p_list, student)
                        end
                    elseif context.selected_p_tab == "2" then
                        for teacher,_ in pairs(mc_teacher.teachers) do
                            table.insert(context.p_list, teacher)
                        end
                    elseif context.selected_p_tab == "3" then
                        local this_realm = Realm.GetRealmFromPlayer(player)
                        for _,p in pairs(minetest.get_connected_players() or {}) do
                            if p:is_player() then
                                local p_realm = Realm.GetRealmFromPlayer(p)
                                if this_realm and p_realm and this_realm.ID == p_realm.ID then
                                    table.insert(context.p_list, p:get_player_name())
                                end
                            end
                        end
                    end
                end

                local selected_player = context.p_list[context.selected_p_player]
                local player_privs = {interact = true, shout = true, fast = true, fly = true, noclip = true, give = true}
                if selected_player then
                    local _,missing = minetest.check_player_privs(selected_player, player_privs)
                    if type(missing) == "string" then missing = {missing} end

                    for _,priv in pairs(missing or {}) do
                        player_privs[priv] = false
                    end
                    for priv, v in pairs(player_privs) do
                        context.selected_privs[priv] = v and "true" or "false"
                    end
                else
                    player_privs = {}
                end

                local fs = {
                    "image[0,0;", controller_width, ",0.5;mc_pixel.png^[multiply:#737373]",
                    "image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
                    "tooltip[exit;Exit;#404040;#ffffff]",
                    "hypertext[", text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Players</b></center></style>]",
                    "hypertext[", panel_width + text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Manage Players</b></center></style>]",
                    "style_type[textarea;font=mono,bold;textcolor=#000000]",
                    "style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:#1e1e1e]",
                    -- TODO: re-implement groups
                    "style[p_group_new,p_group_edit,p_group_delete,p_group_add_player,p_group_remove_player;bgimg=mc_pixel.png^[multiply:#acacac]",
                    -- TODO: re-impelment remaining actions
                    "style[p_teleport,p_bring,p_audience,p_freeze;bgimg=mc_pixel.png^[multiply:#acacac]",
                    
                    "tabheader[", spacer, ",1.4;", panel_width - 2*spacer - 0.35, ",0.5;p_list_header;Students,Teachers,Classroom;", context.selected_p_tab, ";false;true]",
                    "textlist[", spacer, ",1.4;", panel_width - 2*spacer, ",7.5;p_list;", table.concat(context.p_list, ","), ";", context.selected_p_player, ";false]",
                    "button[", panel_width - spacer - 0.45, ",0.95;0.45,0.45;p_group_new;+]",
                    "button[", spacer, ",9;3.5,0.8;p_group_edit;Edit Group]",
                    "button[", spacer + 3.6, ",9;3.5,0.8;p_group_delete;Delete Group]",

                    "textarea[", panel_width + text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Action Mode]",
                    "button[", panel_width + spacer, ",1.4;2.3,0.8;p_mode_selected;Selected]",
                    "button[", panel_width + spacer + 2.4, ",1.4;2.3,0.8;p_mode_tab;Tab]",
                    "button[", panel_width + spacer + 4.8, ",1.4;2.3,0.8;p_mode_all;All]",
                    "textarea[", panel_width + text_spacer, ",2.45;", panel_width - 2*text_spacer, ",1;;;Classroom Privileges]",
                    "style_type[textarea;font=mono]",
                    "textarea[", panel_width + text_spacer + 0.5, ",2.85;1.8,1;;;interact]",
                    "textarea[", panel_width + text_spacer + 0.5, ",3.25;1.8,1;;;shout]",
                    "textarea[", panel_width + text_spacer + 2.9, ",2.85;1.8,1;;;fast]",
                    "textarea[", panel_width + text_spacer + 2.9, ",3.25;1.8,1;;;fly]",
                    "textarea[", panel_width + text_spacer + 5.3, ",2.85;1.8,1;;;noclip]",
                    "textarea[", panel_width + text_spacer + 5.3, ",3.25;1.8,1;;;give]",
                    "style_type[textarea;font=mono,bold]",
                }

                if player_privs.interact then
                    table.insert(fs, table.concat({"image[", panel_width + spacer - 0.05, ",2.85;0.4,0.4;mc_pixel.png^[multiply:#59a63a]"}))
                end
                if player_privs.shout then
                    table.insert(fs, table.concat({"image[", panel_width + spacer - 0.05, ",3.25;0.4,0.4;mc_pixel.png^[multiply:#59a63a]"}))
                end
                if player_privs.fast then
                    table.insert(fs, table.concat({"image[", panel_width + spacer + 2.35, ",2.85;0.4,0.4;mc_pixel.png^[multiply:#59a63a]"}))
                end
                if player_privs.fly then
                    table.insert(fs, table.concat({"image[", panel_width + spacer + 2.35, ",3.25;0.4,0.4;mc_pixel.png^[multiply:#59a63a]"}))
                end
                if player_privs.noclip then
                    table.insert(fs, table.concat({"image[", panel_width + spacer + 4.75, ",2.85;0.4,0.4;mc_pixel.png^[multiply:#59a63a]"}))
                end
                if player_privs.give then
                    table.insert(fs, table.concat({"image[", panel_width + spacer + 4.75, ",3.25;0.4,0.4;mc_pixel.png^[multiply:#59a63a]"}))
                end

                table.insert(fs, table.concat({
                    "checkbox[", panel_width + spacer, ",3.05;priv_interact;;", context.selected_privs.interact or "false", "]",
                    "checkbox[", panel_width + spacer, ",3.45;priv_shout;;", context.selected_privs.shout or "false", "]",
                    "checkbox[", panel_width + spacer + 2.4, ",3.05;priv_fast;;", context.selected_privs.fast or "false", "]",
                    "checkbox[", panel_width + spacer + 2.4, ",3.45;priv_fly;;", context.selected_privs.fly or "false", "]",
                    "checkbox[", panel_width + spacer + 4.8, ",3.05;priv_noclip;;", context.selected_privs.noclip or "false", "]",
                    "checkbox[", panel_width + spacer + 4.8, ",3.45;priv_give;;", context.selected_privs.give or "false", "]",
                    "button[", panel_width + spacer, ",3.75;3.5,0.8;p_priv_update;Update privs]",
                    "button[", panel_width + spacer + 3.6, ",3.75;3.5,0.8;p_priv_reset;Reset privs]",

                    "textarea[", panel_width + text_spacer, ",4.8;", panel_width - 2*text_spacer, ",1;;;Actions]",
                    "button[", panel_width + spacer, ",5.2;2.3,0.8;p_teleport;Teleport]",
                    "button[", panel_width + spacer + 2.4, ",5.2;2.3,0.8;p_bring;Bring]",
                    "button[", panel_width + spacer + 4.8, ",5.2;2.3,0.8;p_audience;Audience]",
                    "button[", panel_width + spacer, ",6.1;2.3,0.8;p_kick;Kick]",
                    "button[", panel_width + spacer + 2.4, ",6.1;2.3,0.8;p_ban;Ban]",
                    "button[", panel_width + spacer + 4.8, ",6.1;2.3,0.8;p_freeze;Freeze]",
                    "textarea[", panel_width + text_spacer, ",7.15;", panel_width - 2*text_spacer, ",1;;;Groups]",
                    "dropdown[", panel_width + spacer, ",7.55;3.5,0.8;p_group_select;(WIP);1;false]",
                    "button[", panel_width + spacer + 3.6, ",7.55;1.7,0.8;p_group_add_player;Add]",
                    "button[", panel_width + spacer + 5.4, ",7.55;1.7,0.8;p_group_remove_player;Remove]",
                    "textarea[", panel_width + text_spacer, ",8.6;", panel_width - 2*text_spacer, ",1;;;Server Role]",
                }))

                if not has_server_privs then
                    table.insert(fs, "style_type[button;bgimg=mc_pixel.png^[multiply:#acacac]")
                end
                table.insert(fs, table.concat({
                    "button[", panel_width + spacer, ",9;2.3,0.8;p_role_student;Student]",
                    "button[", panel_width + spacer + 2.4, ",9;2.3,0.8;p_role_teacher;Teacher]",
                    "button[", panel_width + spacer + 4.8, ",9;2.3,0.8;p_role_admin;Admin]",
                    "tooltip[p_mode_selected;The selected player;#404040;#ffffff]",
                    "tooltip[p_mode_tab;All players in the selected tab;#404040;#ffffff]",
                    "tooltip[p_mode_all;All online players;#404040;#ffffff]",
                }))

                return fs
            end,
            [mc_teacher.TABS.MODERATION] = function() -- MODERATION
                local fs = {
                    "image[0,0;", controller_width, ",0.5;mc_pixel.png^[multiply:#737373]",
                    "image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
                    "tooltip[exit;Exit;#404040;#ffffff]",
                    "hypertext[", text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Moderation</b></center></style>]",
                    "hypertext[", panel_width + text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Message Log</b></center></style>]",
                    "style_type[textarea;font=mono,bold;textcolor=#000000]",
                    "style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:#1e1e1e]",
                }

                local chat_msg = minetest.deserialize(mc_teacher.meta:get_string("chat_log"))
                local direct_msg = minetest.deserialize(mc_teacher.meta:get_string("dm_log"))
                local indexed_chat_players = {}

                if chat_msg then
                    for cm_name,_ in pairs(chat_msg) do
                        if not mc_core.tableHas(indexed_chat_players, cm_name) then
                            table.insert(indexed_chat_players, cm_name)
                        end
                    end
                end
                if direct_msg then
                    for dm_name,_ in pairs(direct_msg) do
                        if not mc_core.tableHas(indexed_chat_players, dm_name) then
                            table.insert(indexed_chat_players, dm_name)
                        end
                    end
                end
                context.indexed_chat_players = indexed_chat_players

                if #indexed_chat_players > 0 then
                    if not context.player_chat_index or not indexed_chat_players[context.player_chat_index] then
                        context.player_chat_index = 1
                    end
                    local selected = indexed_chat_players[context.player_chat_index]
                    local stamps = {}
                    local stamp_to_key = {}

                    if chat_msg and chat_msg[selected] then
                        for i, msg_table in ipairs(chat_msg[selected]) do
                            table.insert(stamps, msg_table.timestamp)
                            stamp_to_key[msg_table.timestamp] = "chat:"..i
                        end
                    end
                    if direct_msg and direct_msg[selected] then
                        for i, msg_table in ipairs(direct_msg[selected]) do
                            table.insert(stamps, msg_table.timestamp)
                            stamp_to_key[msg_table.timestamp] = "dm:"..i
                        end
                    end
                    table.sort(stamps)

                    local player_log = {}
                    context.log_i_to_key = {}
                    local chat_col = "#CCFFFF"
                    local dm_col = "#FFFFCC"

                    -- build main message list
                    for i, stamp in ipairs(stamps) do
                        local key = stamp_to_key[stamp] or "null:0"
                        local split_key = mc_core.split(key, ":")
                        local index = tonumber(split_key[2] or "0")
                        if split_key[1] == "chat" and index ~= 0 then
                            local msg_table = chat_msg[selected][index]
                            table.insert(player_log, chat_col..minetest.formspec_escape(table.concat({"[", stamp, "] ", msg_table.message})))
                            table.insert(context.log_i_to_key, key)
                        elseif split_key[1] == "dm" and index ~= 0 then
                            local msg_table = direct_msg[selected][index]
                            table.insert(player_log, dm_col..minetest.formspec_escape(table.concat({"[", stamp, "] DM to ", msg_table.recipient, ": ", msg_table.message})))
                            table.insert(context.log_i_to_key, key)
                        end
                    end

                    if not context.message_chat_index or not context.log_i_to_key[context.message_chat_index] then
                        context.message_chat_index = 1
                    end
                    local selected_key = context.log_i_to_key[context.message_chat_index]
                    local sel_split_key = mc_core.split(selected_key, ":")
                    local sel_index = tonumber(sel_split_key[2] or "0")
                    local display_message = {}

                    if sel_split_key[1] == "chat" and chat_msg[selected][sel_index] then
                        display_message.header = "Global chat message"
                        display_message.message = chat_msg[selected][sel_index].message
                    elseif sel_split_key[1] == "dm" and direct_msg[selected][sel_index] then
                        display_message.header = "Direct message to "..direct_msg[selected][sel_index].recipient
                        display_message.message = direct_msg[selected][sel_index].message
                    end

                    table.insert(fs, table.concat({
                        "textarea[", text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Message Logs]",
                        "textlist[", spacer, ",1.4;", panel_width - 2*spacer, ",5.5;mod_log_players;", table.concat(indexed_chat_players, ","), ";", context.player_chat_index, ";false]",
                        "button[", spacer, ",7;3.5,0.8;mod_mute;Mute player]", -- TODO: sync w/ mute button on Players tab
                        "button[", spacer + 3.6, ",7;3.5,0.8;mod_clearlog;Delete log]",
                        "textarea[", text_spacer, ",8;", panel_width - 2*text_spacer, ",1;;;Message ", selected or "player", "]",
                        "style_type[textarea;font=mono]",
                        "textarea[", spacer, ",8.4;", panel_width - 2*spacer - 0.8, ",1.4;mod_message;;]",
                        "style_type[textarea;font=mono,bold]",
                        "button[", panel_width - spacer - 0.8, ",8.4;0.8,1.4;mod_send_message;Send]",
                        "textarea[", panel_width + text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Sent Messages]",
                        "textlist[", panel_width + spacer, ",1.4;", panel_width - 2*spacer, ",6.4;mod_log_messages;", table.concat(player_log, ","), ";", context.message_chat_index, ";false]",
                        "textarea[", panel_width + text_spacer, ",8;", panel_width - 2*text_spacer, ",1;;;", display_message and display_message.header or "Unknown", "]",
                        "style_type[textarea;font=mono]",
                        "textarea[", panel_width + text_spacer, ",8.4;", panel_width - 2*text_spacer, ",1.4;;;", display_message and display_message.message or "", "]",
                        "tooltip[mod_clearlog;Removes all messages sent by the selected player from the log;#404040;#ffffff]",
                    }))
                else
                    -- fallback formspec
                    table.insert(fs, table.concat({
                        "textarea[", text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;No messages logged!]",
                        "style_type[textarea;font=mono]",
                        "textarea[", text_spacer, ",1.5;", panel_width - 2*text_spacer, ",8.3;;;When players send chat messages or direct messages to other players, they will be logged here!]",
                    }))
                end

                return fs
            end,
            [mc_teacher.TABS.REPORTS] = function() -- REPORTS
                return {}
            end,
            [mc_teacher.TABS.HELP] = function() -- HELP
                local set = minetest.settings
                local fs = {
                    "image[0,0;", controller_width, ",0.5;mc_pixel.png^[multiply:#737373]",
                    "image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
                    "tooltip[exit;Exit;#404040;#ffffff]",
                    "hypertext[", text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Help</b></center></style>]",
                    "hypertext[", panel_width + text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Getting Started</b></center></style>]",
                    "style_type[textarea;font=mono,bold;textcolor=#000000]",
                    "textarea[", text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Game controls]",
                    "style_type[textarea;font=mono]",
                    "style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:#1e1e1e]",

                    -- Controls + keybinds
                    "textarea[", text_spacer, ",1.5;", panel_width - 2*text_spacer, ",8.3;;;",
                    "Move forwards: ", mc_core.clean_key(set:get("keymap_forward") or "KEY_KEY_W"), "\n",
                    "Move backwards: ", mc_core.clean_key(set:get("keymap_backward") or "KEY_KEY_S"), "\n",
                    "Move left: ", mc_core.clean_key(set:get("keymap_left") or "KEY_KEY_A"), "\n",
                    "Move right: ", mc_core.clean_key(set:get("keymap_right") or "KEY_KEY_D"), "\n",
                    "Jump/climb up: ", mc_core.clean_key(set:get("keymap_jump") or "KEY_SPACE"), "\n",
                    "Sneak", set:get("aux1_descends") == "true" and "" or "/climb down", ": ", mc_core.clean_key(set:get("keymap_sneak") or "KEY_LSHIFT"), "\n",
                    "Sprint", set:get("aux1_descends") == "true" and "/climb down" or "", ": ", mc_core.clean_key(set:get("keymap_aux1") or "KEY_KEY_E"), "\n",
                    "Zoom: ", mc_core.clean_key(set:get("keymap_zoom") or "KEY_KEY_Z"), "\n",
                    "\n",
                    "Dig block/use tool: ", set:get("keymap_dig") and mc_core.clean_key(set:get("keymap_dig") or "KEY_LBUTTON"), "\n",
                    "Place block: ", set:get("keymap_place") and mc_core.clean_key(set:get("keymap_place") or "KEY_RBUTTON"), "\n",
                    "Select hotbar item: SCROLL WHEEL or SLOT NUMBER (1-8)\n",
                    "Select next hotbar item: ", mc_core.clean_key(set:get("keymap_hotbar_next") or "KEY_KEY_N"), "\n",
                    "Select previous hotbar item: ", mc_core.clean_key(set:get("keymap_hotbar_previous") or "KEY_KEY_B"), "\n",
                    "Drop item: ", mc_core.clean_key(set:get("keymap_drop") or "KEY_KEY_Q"), "\n",
                    "\n",
                    "Open inventory: ", mc_core.clean_key(set:get("keymap_inventory") or "KEY_KEY_I"), "\n",
                    "Open chat: ", mc_core.clean_key(set:get("keymap_chat") or "KEY_KEY_T"), "\n",
                    "View minimap: ", mc_core.clean_key(set:get("keymap_minimap") or "KEY_KEY_V"), "\n",
                    "Take a screenshot: ", mc_core.clean_key(set:get("keymap_screenshot") or "KEY_F12"), "\n",
                    "Change camera perspective: ", mc_core.clean_key(set:get("keymap_camera_mode") or "KEY_KEY_C"), "\n",
                    "Mute/unmute game sound: ", mc_core.clean_key(set:get("keymap_mute") or "KEY_KEY_M"), "\n",
                    "\n",
                    "Enable/disable sprint: ", mc_core.clean_key(set:get("keymap_fastmove") or "KEY_KEY_J"), "\n",
                    "Enable/disable fly mode: ", mc_core.clean_key(set:get("keymap_freemove") or "KEY_KEY_K"), "\n",
                    "Enable/disable noclip mode: ", mc_core.clean_key(set:get("keymap_noclip") or "KEY_KEY_H"), "\n",
                    "Show/hide HUD (display): ", mc_core.clean_key(set:get("keymap_toggle_hud") or "KEY_F1"), "\n",
                    "Show/hide chat: ", mc_core.clean_key(set:get("keymap_toggle_chat") or "KEY_F2"), "\n",
                    "Show/hide world fog: ", mc_core.clean_key(set:get("keymap_toggle_force_fog_off") or "KEY_F3"), "\n",
                    "Expand/shrink chat window: ", mc_core.clean_key(set:get("keymap_console") or "KEY_F10"), "\n",
                    "\n",
                    minetest.formspec_escape("[MINETEST TECHNICAL INFO]"), "\n",
                    "Show/hide debug log: ", mc_core.clean_key(set:get("keymap_toggle_debug") or "KEY_F5"), "\n",
                    "Show/hide profiler: ", mc_core.clean_key(set:get("keymap_toggle_profiler") or "KEY_F6"),
                    "]",
                }

                return fs
            end,
            [mc_teacher.TABS.SERVER] = function() -- SERVER
                -- TODO: Implement ban manager
                local whitelist_state = minetest.deserialize(networking.storage:get_string("enabled"))

                local fs = {
                    "image[0,0;", controller_width, ",0.5;mc_pixel.png^[multiply:#737373]",
                    "image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
                    "tooltip[exit;Exit;#404040;#ffffff]",
                    "hypertext[", text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Server Management</b></center></style>]",
                    "hypertext[", panel_width + text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Server Whitelist</b></center></style>]",
                    "style_type[textarea;font=mono,bold;textcolor=#000000]",
                    "style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:#1e1e1e]",

                    "textarea[", text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Global Messenger]",
                    "style_type[textarea,field;font=mono]",
                    "textarea[", spacer, ",1.4;", panel_width - 2*spacer, ",2.1;server_message;;", context.server_message or "", "]",
                    "style_type[textarea;font=mono,bold]",
                    "textarea[", text_spacer, ",3.6;", panel_width - 2*text_spacer, ",1;;;Send as:]",
                    "dropdown[", spacer, ",4.0;", panel_width - 2*spacer, ",0.8;server_message_type;Anonymous server message,Server message from yourself,Chat message from yourself;1;true]",
                    "textarea[", text_spacer, ",4.9;", panel_width - 2*text_spacer, ",1;;;Send to:]",
                    "button[", spacer, ",5.3;1.7,0.8;server_send_teachers;Teachers]",
                    "button[", spacer + 1.8, ",5.3;1.7,0.8;server_send_students;Students]",
                    "button[", spacer + 3.6, ",5.3;1.7,0.8;server_send_admins;Admins]",
                    "button[", spacer + 5.4, ",5.3;1.7,0.8;server_send_all;Everyone]",
                    "textarea[", text_spacer, ",6.3;", panel_width - 2*text_spacer, ",1;;;Schedule Server Shutdown]",
                    "dropdown[", spacer, ",6.7;", panel_width - 2*spacer, ",0.8;server_shutdown_timer;30 seconds,1 minute,5 minutes,10 minutes,15 minutes,30 minutes,45 minutes,1 hour,2 hours,3 hours,6 hours,12 hours,24 hours;1;false]",
                    "button[", spacer, ",7.6;3.5,0.8;server_shutdown_schedule;Schedule]",
                    "button[", spacer + 3.6, ",7.6;3.5,0.8;server_shutdown_now;Shutdown now]",
                    "textarea[", text_spacer, ",8.6;", panel_width - 2*text_spacer, ",1;;;Misc. actions]",
                    "button[", spacer, ",9;3.5,0.8;server_ban_manager;Banned players]",
                    "button[", spacer + 3.6, ",9;3.5,0.8;server_edit_rules;Server rules]",
                    
                    "textarea[", panel_width + text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Whitelisted IPv4 Addresses]",
                    "textlist[", panel_width + spacer, ",1.4;", panel_width - 2*spacer, ",4.9;server_whitelist;;1;false]",
                    "button[", panel_width + spacer, ",6.4;3.5,0.8;server_whitelist_toggle;", whitelist_state and "DISABLE" or "ENABLE", " whitelist]",
                    "button[", panel_width + spacer + 3.6, ",6.4;3.5,0.8;server_whitelist_remove;Delete range]",
                    "textarea[", panel_width + text_spacer, ",7.4;", panel_width - 2*text_spacer, ",1;;;Modify Whitelist]",
                    "style_type[textarea;font_size=*0.85]",
                    "textarea[", panel_width + text_spacer, ",8.6;3.6,1;;;Start IPv4]",
                    "textarea[", panel_width + text_spacer + 3.6, ",8.6;3.6,1;;;End IPv4]",
                    "field[", panel_width + spacer, ",7.8;3.5,0.8;server_ip_start;;", context.start_ip or "0.0.0.0", "]",
                    "field[", panel_width + spacer + 3.6, ",7.8;3.5,0.8;server_ip_end;;", context.end_ip or "", "]",
                    "field_close_on_enter[server_ip_start;false]",
                    "field_close_on_enter[server_ip_end;false]",
                    "button[", panel_width + spacer, ",9;3.5,0.8;server_ip_add;Add range]",
                    "button[", panel_width + spacer + 3.6, ",9;3.5,0.8;sever_ip_remove;Remove range]",

                    "tooltip[server_message;Type your message here!;#404040;#ffffff]",
                    "tooltip[server_ban_manager;View and manage banned players;#404040;#ffffff]",
                    "tooltip[server_edit_rules;Edit server rules;#404040;#ffffff]",
                    "tooltip[server_ip_start;First IPv4 address in the desired range;#404040;#ffffff]",
                    "tooltip[server_ip_end;Last IPv4 address in the desired range (optional);#404040;#ffffff]",
                    "tooltip[server_whitelist_remove;Removes the selected IP range from the whitelist;#404040;#ffffff]",
                    "tooltip[server_ip_add;Adds the typed range of IPs to the whitelist;#404040;#ffffff]",
                    "tooltip[server_ip_remove;Removes the typed range of IPs from the whitelist;#404040;#ffffff]",
                    "tooltip[server_whitelist_toggle;Whitelist is currently ", whitelist_state and "ENABLED" or "DISABLED", ";#404040;#ffffff]",
                }

                return fs

                --[[
                local fsx, fsy
                local fs = {}
                fs[#fs + 1] = "field[1,0.85;"
                fs[#fs + 1] = tostring((page_width)-1.6)
                fs[#fs + 1] = ",0.8;servermessage;"
                fs[#fs + 1] = minetest.colorize("#000","Send Message to All Connected Players")
                fs[#fs + 1] = ";]button["
                fs[#fs + 1] = tostring((controller_width/2)-1.4)
                fs[#fs + 1] = ",0.85;1.4,0.8;submitmessage;Send]style_type[label;font_size=*1;textcolor=#000]label[1,2;"
                fs[#fs + 1] = minetest.colorize("#000","Schedule Server Restart")
                fs[#fs + 1] = "]dropdown[1,2.2;3,0.8;time;1 minute,5 minutes,10 minutes,15 minutes,30 minutes,1 hour,6 hours,12 hours,24 hours;1;false]"
                fs[#fs + 1] = "button[4.2,2.2;3,0.8;submitsched;Schedule Restart]"
                fs[#fs + 1] = "button_exit[1,3.2;3,0.8;submitshutdown;Shutdown Now]"
                fsx = ((controller_width/2)-(((controller_width/8)*3)))/2
                fsy = 1
                fs[#fs + 1] = "style_type[label;font_size=*1.2]label["
                fs[#fs + 1] = tostring(controller_width/2+1.6)
                fs[#fs + 1] = ",0.4;"
                fs[#fs + 1] = minetest.colorize("#000","White-Listed IPv4 Addresses")
                fs[#fs + 1] = "]textlist["
                fs[#fs + 1] = tostring(fsx+(controller_width/2))
                fs[#fs + 1] = ",1.1;"
                fs[#fs + 1] = tostring(page_width)
                fs[#fs + 1] = ","
                fs[#fs + 1] = tostring(controller_height/3)
                fs[#fs + 1] = ";iplist;"
                local ipv4_whitelist = minetest.deserialize(networking.storage:get_string("ipv4_whitelist"))
                local count = 0
                local counter = 0
                for _ in pairs(ipv4_whitelist) do count = count + 1 end
                for ipv4,_ in pairs(ipv4_whitelist) do
                    counter = counter + 1
                    fs[#fs + 1] = ipv4
                    if counter ~= count then fs[#fs + 1] = "," end
                end
                fs[#fs + 1] = ";1;false]style_type[label;font_size=*1]label["
                fs[#fs + 1] = tostring(fsx+(controller_width/2))
                fs[#fs + 1] = ","
                fs[#fs + 1] = tostring(fsy+(controller_height/4)+1.3)
                fs[#fs + 1] = ";"
                fs[#fs + 1] = minetest.colorize("#000","Start IPv4 Range")
                fs[#fs + 1] = "]field["
                fs[#fs + 1] = tostring(fsx+(controller_width/2))
                fs[#fs + 1] = ","
                fs[#fs + 1] = tostring(fsy+(controller_height/4)+1.5)
                fs[#fs + 1] = ";3,0.8;ipstart;;0.0.0.0]style_type[label;font_size=*1]label["
                fs[#fs + 1] = tostring(fsx+(controller_width/2))
                fs[#fs + 1] = ","
                fs[#fs + 1] = tostring(fsy+(controller_height/4)+2.5)
                fs[#fs + 1] = ";"
                fs[#fs + 1] = minetest.colorize("#000","End IPv4 Range")
                fs[#fs + 1] = "]field["
                fs[#fs + 1] = tostring(fsx+(controller_width/2))
                fs[#fs + 1] = ","
                fs[#fs + 1] = tostring(fsy+(controller_height/4)+2.7)
                fs[#fs + 1] = ";3,0.8;ipend;;Optional]"
                fs[#fs + 1] = "button["
                fs[#fs + 1] = tostring(fsx+(controller_width/2)+3.2)
                fs[#fs + 1] = ","
                fs[#fs + 1] = tostring(fsy+(controller_height/4)+2.7)
                fs[#fs + 1] = ";1.1,0.8;addip;Add]"
                fs[#fs + 1] = "button["
                fs[#fs + 1] = tostring(fsx+(controller_width/2)+3.2+1.3)
                fs[#fs + 1] = ","
                fs[#fs + 1] = tostring(fsy+(controller_height/4)+2.7)
                fs[#fs + 1] = ";1.7,0.8;removeip;Remove]"
                local state = minetest.deserialize(networking.storage:get_string("enabled"))
                if state then
                    fs[#fs + 1] = "button["
                    fs[#fs + 1] = tostring(fsx+(controller_width/2)+3.2)
                    fs[#fs + 1] =  ","
                    fs[#fs + 1] = tostring(fsy+(controller_height/4)+1.5)
                    fs[#fs + 1] = ";3,0.8;toggleoff;Turn OFF Whitelist]"
                else
                    fs[#fs + 1] = "button["
                    fs[#fs + 1] = tostring(fsx+(controller_width/2)+3.2)
                    fs[#fs + 1] =  ","
                    fs[#fs + 1] = tostring(fsy+(controller_height/4)+1.5)
                    fs[#fs + 1] = ";3,0.8;toggleon;Turn ON Whitelist]"
                end
                fs[#fs + 1] = "button_exit["
                fs[#fs + 1] = tostring(fsx+(controller_width/2))
                fs[#fs + 1] = ","
                fs[#fs + 1] = tostring(fsy+(controller_height/4)+2.7+1.2)
                fs[#fs + 1] = ";3.9,0.8;modifyrules;Modify Server Rules]"]]
            end,
        }

        local bookmarked_tab = pmeta:get_string("default_teacher_tab")
        if not tab_map[bookmarked_tab] then
            bookmarked_tab = nil
            pmeta:set_string("default_teacher_tab", nil)
        end
        local selected_tab = (tab_map[tab] and tab) or (tab_map[context.tab] and context.tab) or bookmarked_tab or "1"
        context.tab = selected_tab
        mc_teacher.check_selected_priv_mode(context)

        local teacher_formtable = {
            "formspec_version[6]",
            "size[", controller_width, ",", controller_height, "]",
            mc_core.draw_book_fs(controller_width, controller_height, {bg = "#404040", shadow = "#303030", binding = "#333333", divider = "#969696"}),
            "style[tabheader;noclip=true]",
            "tabheader[0,-0.25;", controller_width, ",0.55;record_nav;Overview,Classrooms,Map,Players,Moderation,Reports,Help",
            has_server_privs and ",Server" or "", ";", selected_tab, ";true;false]",
            table.concat(tab_map[selected_tab](), "")
        }

        if bookmarked_tab == selected_tab then
            table.insert(teacher_formtable, table.concat({
                "style_type[image;noclip=true]",
                "image[", controller_width - 0.6, ",-0.25;0.5,0.7;mc_teacher_bookmark_filled.png]",
                "tooltip[", controller_width - 0.6, ",-0.25;0.5,0.8;This tab is currently bookmarked;#404040;#ffffff]",
            }))
        else
            table.insert(teacher_formtable, table.concat({
                "image_button[", controller_width - 0.6, ",-0.25;0.5,0.5;mc_teacher_bookmark_hollow.png^[colorize:#FFFFFF:127;default_tab;;true;false]",
                "tooltip[default_tab;Bookmark this tab?;#404040;#ffffff]",
            }))
        end

        minetest.show_formspec(pname, "mc_teacher:controller_fs", table.concat(teacher_formtable, ""))
        return true
    end
end

--[[
NEW FORMSPEC CLEAN COPIES

TAB GROUPING:
[1] OVERVIEW + RULES
[2] CLASSROOM MANAGEMENT
[3] MAP + COORDINATES
[4] PLAYER MANAGEMENT
[5] MODERATION
[6] HELP
[7] REPORT LOG
[8] SERVER MANAGEMENT (extra)

OVERVIEW + RULES:
formspec_version[6]
size[16.6,10.4]
box[0,0;16.6,0.5;#737373]
box[8.275,0;0.05,10.4;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.2,1;;;Overview]
textarea[8.85,0.1;7.2,1;;;Dashboard]
textarea[0.55,1;7.2,1;;;Welcome to Minetest Classroom!]
textarea[0.55,1.5;7.2,2.8;;;This is the Teacher Controller\, your tool for managing classrooms\, player privileges\, and server settings. You cannot drop or delete this tool\, so you will never lose it\, but you can move it out of your hotbar and into your inventory or the toolbox.]
textarea[0.55,4.4;7.2,1;;;Server Rules]
textarea[0.55,4.9;7.2,4;;;These are the server rules!]
button[0.6,9;7.1,0.8;modifyrules;Edit Server Rules]
image_button[8.9,1;1.7,1.6;mc_teacher_classrooms.png;classrooms;;false;false]
image_button[8.9,2.8;1.7,1.6;mc_teacher_map.png;map;;false;false]
image_button[8.9,4.6;1.7,1.6;mc_teacher_players.png;players;;false;false]
image_button[8.9,6.4;1.7,1.6;mc_teacher_isometric.png;help;;false;false]
image_button[8.9,8.2;1.7,1.6;mc_teacher_isometric.png;help;;false;false]
textarea[10.7,1.3;5.35,1.6;;;ClassroomsnFind classrooms or players]
textarea[10.7,3.1;5.35,1.6;;;MapnRecord and share locations]
textarea[10.7,4.9;5.35,1.6;;;PlayersnManage player privileges]
textarea[10.7,6.7;5.35,1.6;;;ModerationnView player chat logs]
textarea[10.7,8.5;5.35,1.6;;;ReportsnView player reports]
image[16,-0.25;0.5,0.8;mc_teacher_bookmark.png]

CLASSROOMS:
formspec_version[6]
size[16.6,10.4]
box[0,0;16.6,0.5;#737373]
box[8.275,0;0.05,10.4;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.2,1;;;Classrooms]
textarea[8.85,0.1;7.2,1;;;Build a Classroom]
textarea[0.55,1;7.2,1;;;Available Classrooms]
textlist[0.6,1.4;7.1,7.5;classroomlist;;1;false]
button[0.6,9;2.3,0.8;teleportrealm;Teleport]
button[3,9;2.3,0.8;editrealm;Edit]
button[5.4,9;2.3,0.8;deleterealm;Delete]
textarea[8.85,1;7.2,1;;;Name]
field[8.9,1.4;7.1,0.8;realmname;;]
textarea[8.85,2.3;3.6,1;;;Type]
dropdown[8.9,2.7;3.5,0.8;realmcategory;Default,Spawn,Classroom,Instanced;1;true]
textarea[12.45,2.3;3.6,1;;;Generation]
dropdown[12.5,2.7;3.5,0.8;mode;Empty World,Schematic,Digital Twin;1;true]
textarea[8.85,3.6;7.2,1;;;OPTIONS]
box[8.9,4;7.1,0.8;#808080]
textarea[8.85,4.9;7.2,1;;;Default Privileges]
textarea[9.35,5.3;1.8,1;;;interact]
textarea[9.35,5.7;1.8,1;;;shout]
textarea[11.75,5.3;1.8,1;;;fast]
textarea[11.75,5.7;1.8,1;;;fly]
textarea[14.15,5.3;1.8,1;;;noclip]
textarea[14.15,5.7;1.8,1;;;give]
checkbox[8.9,5.5;priv_interact;;true]
checkbox[8.9,5.9;priv_shout;;true]
checkbox[11.3,5.5;priv_fast;;true]
checkbox[11.3,5.9;priv_fly;;false]
checkbox[13.7,5.5;priv_noclip;;false]
checkbox[13.7,5.9;priv_give;;false]
textarea[8.85,6.2;7.2,1;;;Background Music]
dropdown[8.9,6.6;7.1,0.8;bgmusic;;1;true]
textarea[8.85,7.5;7.2,1;;;Skybox]
dropdown[8.9,7.9;7.1,0.8;;;1;true]
button[8.9,9;7.1,0.8;requestrealm;Generate Classroom]

MAP + COORDINATES:
formspec_version[6]
size[16.6,10.4]
box[0,0;16.6,0.5;#737373]
box[8.275,0;0.05,10.4;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.1,1;;;Map]
textarea[8.85,0.1;7.1,1;;;Coordinates]
textarea[0.55,1;7.1,1;;;Surrounding Area]
box[0.6,1.4;7.1,7.1;#000000]
box[0.625,1.425;7.05,7.05;#808080]
image[4,4.8;0.3,0.3;]
textarea[0.55,8.6;7.1,1;;;Coordinate and Elevation Display]
button[0.6,9;1.7,0.8;utmcoords;UTM]
button[2.4,9;1.7,0.8;latloncoords;Lat/Long]
button[4.2,9;1.7,0.8;classroomcoords;Local]
button[6,9;1.7,0.8;coordsoff;Off]
textarea[8.85,1;7.1,1;;;Saved Coordinates]
textlist[8.9,1.4;7.1,4.4;coordlist;;8;false]
textarea[8.85,8.5;7.1,1;;;Save current coordinates]
image_button[15.1,8.9;0.9,0.9;blank.png;;Save;false;true]
textarea[8.9,8.9;6.2,0.9;note;;]
textarea[8.85,7.2;7.2,1.1;;;(coordinate name) (coords) (realm)]
image_button[8.9,5.9;1.1,1.1;blank.png;go;TP;false;true]
image_button[10.1,5.9;1.1,1.1;blank.png;go_all;TP_A;false;true]
image_button[12.5,5.9;1.1,1.1;blank.png;mark;MK;false;true]
image_button[11.3,5.9;1.1,1.1;blank.png;share;SH;false;true]
image_button[13.7,5.9;1.1,1.1;blank.png;delete;DL;false;true]
image_button[14.9,5.9;1.1,1.1;blank.png;clear;DL_A;false;true]

PLAYERS:
formspec_version[6]
size[16.6,10.4]
box[0,0;16.6,0.5;#737373]
box[8.275,0;0.05,10.4;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.2,1;;;Online Players]
textarea[8.85,0.1;7.2,1;;;Manage Players]
textarea[0.55,1;6.7,1;;;Students]
textlist[0.6,1.4;7.1,7.5;student_list;;1;false]
button[7.25,0.95;0.45,0.45;p_group_new;+]
button[0.6,9;3.5,0.8;p_group_edit;Edit Group]
button[4.2,9;3.5,0.8;p_group_delete;Delete Group]
image[4.25,1.45;0.4,0.4;]
image[4.75,1.45;0.4,0.4;]
image[5.25,1.45;0.4,0.4;]
image[5.75,1.45;0.4,0.4;]
image[6.25,1.45;0.4,0.4;]
image[6.75,1.45;0.4,0.4;]
image[7.25,1.45;0.4,0.4;]
textarea[8.85,1;7.2,1;;;Action Mode]
button[8.9,1.4;2.3,0.8;;Selected]
button[11.3,1.4;2.3,0.8;;Group]
button[13.7,1.4;2.3,0.8;;All]
textarea[8.85,2.45;7.2,1;;;Classroom Privileges]
textarea[9.35,2.85;1.8,1;;;interact]
textarea[9.35,3.25;1.8,1;;;shout]
textarea[11.75,2.85;1.8,1;;;fast]
textarea[11.75,3.25;1.8,1;;;fly]
textarea[14.15,2.85;1.8,1;;;noclip]
textarea[14.15,3.25;1.8,1;;;give]
checkbox[8.9,3.05;priv_interact;;true]
checkbox[8.9,3.45;priv_shout;;true]
checkbox[11.3,3.05;priv_fast;;true]
checkbox[11.3,3.45;priv_fly;;false]
checkbox[13.7,3.05;priv_noclip;;false]
checkbox[13.7,3.45;priv_give;;false]
button[8.9,3.75;3.5,0.8;;Update privileges]
button[12.5,3.75;3.5,0.8;;Reset to default]
textarea[8.85,4.8;7.2,1;;;Actions]
button[8.9,5.2;2.3,0.8;;Teleport]
button[11.3,5.2;2.3,0.8;;Bring]
button[13.7,5.2;2.3,0.8;;Audience]
button[8.9,6.1;2.3,0.8;;Kick]
button[11.3,6.1;2.3,0.8;;Ban]
button[13.7,6.1;2.3,0.8;;Freeze]
textarea[8.85,7.15;7.2,1;;;Groups]
dropdown[8.9,7.55;3.5,0.8;;;1;false]
button[12.5,7.55;1.7,0.8;;Add]
button[14.3,7.55;1.7,0.8;;Remove]
textarea[8.85,8.6;7.2,1;;;Server Role]
button[11.3,9;2.3,0.8;;Teacher]
button[8.9,9;2.3,0.8;;Student]
button[13.7,9;2.3,0.8;;Admin]

MODERATION:
formspec_version[6]
size[16.6,10.4]
box[0,0;16.6,0.5;#737373]
box[8.275,0;0.05,10.4;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.1,1;;;Moderation]
textarea[8.85,0.1;7.1,1;;;Message Log]
textarea[0.55,1;7.2,1;;;Message Logs]
textlist[0.6,1.4;7.1,5.5;mod_log_players;;1;false]
button[0.6,7;3.5,0.8;mod_mute;Mute player]
button[4.2,7;3.5,0.8;mod_clearlog;Clear player's log]
textarea[0.55,8;7.2,1;;;Message player]
textarea[0.6,8.4;6.2,1.4;mod_message;;]
button[6.8,8.4;0.9,1.4;mod_send_message;Send]
textarea[8.85,1;7.2,1;;;Sent Messages]
textlist[8.9,1.4;7.1,6.4;mod_log_messages;;1;false]
textarea[8.85,8;7.2,1;;;(message type)]
textarea[8.85,8.4;7.2,1.4;;;add message text here!]

REPORTS:
formspec_version[6]
size[16.6,10.4]
box[0,0;16.6,0.5;#737373]
box[8.275,0;0.05,10.4;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.1,1;;;Reports]
textarea[8.85,0.1;7.1,1;;;Reports]
textarea[0.55,1;7.2,1;;;Coming soon!]

HELP:
formspec_version[6]
size[16.6,10.4]
box[0,0;16.6,0.5;#737373]
box[8.275,0;0.05,10.4;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.1,1;;;Help]
textarea[8.85,0.1;7.1,1;;;Getting Started]
textarea[0.55,1;7.2,1;;;Controls]
textarea[0.55,1.5;7.2,8.3;;;Add controls here!]

SERVER:
formspec_version[6]
size[16.6,10.4]
box[0,0;16.6,0.5;#737373]
box[8.275,0;0.05,10.4;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.1,1;;;Server Management]
textarea[8.85,0.1;7.1,1;;;Server Whitelist]
textarea[0.55,1;7.2,1;;;Global Messenger]
textarea[0.6,1.4;7.1,2.1;server_message;;]
textarea[0.55,3.6;7.2,1;;;Send as:]
dropdown[0.6,4;7.1,0.8;server_message_type;Anonymous server message,Server message from yourself,Chat message from yourself;1;true]
textarea[0.55,4.9;7.2,1;;;Send to:]
button[0.6,5.3;1.7,0.8;server_send_teachers;Teachers]
button[2.4,5.3;1.7,0.8;server_send_students;Students]
button[4.2,5.3;1.7,0.8;server_send_admins;Admins]
button[6,5.3;1.7,0.8;server_send_all;Everyone]
textarea[0.55,6.3;7.2,1;;;Schedule Server Shutdown]
dropdown[0.6,6.7;7.1,0.8;server_shutdown_timer;;1;false]
button[0.6,7.6;3.5,0.8;server_shutdown_schedule;Schedule]
button[4.2,7.6;3.5,0.8;server_shutdown_now;Shutdown now]
textarea[0.55,8.6;7.2,1;;;Misc. actions]
button[0.6,9;3.5,0.8;server_ban_manager;Banned players]
button[4.2,9;3.5,0.8;server_edit_rules;Server rules]
textarea[8.85,1;7.2,1;;;Whitelisted IPv4 Addresses]
textlist[8.9,1.4;7.1,4.9;server_whitelist;;1;false]
button[8.9,6.4;3.5,0.8;server_whitelist_toggle;ENABLE whitelist]
button[12.5,6.4;3.5,0.8;server_whitelist_remove;Delete range]
textarea[8.85,7.4;7.2,1;;;Modify Whitelist]
textarea[8.85,8.6;3.6,1;;;Start IPv4]
textarea[12.45,8.6;3.6,1;;;End IPv4 (optional)]
field[8.9,7.8;3.5,0.8;server_ip_start;;0.0.0.0]
field[12.5,7.8;3.5,0.8;server_ip_end;;]
button[8.9,9;3.5,0.8;server_ip_add;Add range]
button[12.5,9;3.5,0.8;sever_ip_remove;Remove range]
]]
