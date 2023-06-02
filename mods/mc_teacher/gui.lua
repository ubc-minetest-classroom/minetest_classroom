--- Returns a list of classrooms that the given player can join
local function get_fs_classroom_list(player)
	local list = {}
	Realm.ScanForPlayerRealms()

	for _,realm in pairs(Realm.realmDict) do
        local playerCount = tonumber(realm:GetPlayerCount())
        table.insert(list, table.concat({
            minetest.formspec_escape(realm.Name or ""), " (", playerCount, " player", playerCount == 1 and "" or "s", ")"
        }))
	end
	return table.concat(list, ",")
end

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
			["1"] = function() -- OVERVIEW
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
                    has_server_privs and "button[0.6,8.8;7,0.8;modifyrules;Edit Server Rules]" or "",

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
			["2"] = function() -- CLASSROOMS
                local fs = {
                    "image[0,0;", controller_width, ",0.5;mc_pixel.png^[multiply:#737373]",
					"image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
					"tooltip[exit;Exit;#404040;#ffffff]",
					"hypertext[", text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Classrooms</b></center></style>]",
					"hypertext[", panel_width + text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Build a Classroom</b></center></style>]",

                    "style_type[textarea;font=mono,bold;textcolor=#000000]",
                    "style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:#1e1e1e]",
                    "textarea[", text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Available Classrooms]",
                    "textlist[", spacer, ",1.4;", panel_width - 2*spacer, ",7.5;classroomlist;", get_fs_classroom_list(player), ";", context.selected_realm_id or 1, ";false]",
                    "button[", spacer, ",9;2.3,0.8;teleportrealm;Teleport]",
                    "button[", spacer + 2.4, ",9;2.3,0.8;editrealm;Edit]",
                    "button[", spacer + 4.8, ",9;2.3,0.8;deleterealm;Delete]",

                    "style_type[field;font=mono;textcolor=#ffffff]",
                    "textarea[", panel_width + text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Name]",
                    "field[", panel_width + spacer, ",1.4;7.1,0.8;realmname;;", context.realmname or "", "]",
                    "field_close_on_enter[realmname;false]",
                    "textarea[", panel_width + text_spacer, ",2.25;3.6,1;;;Type]",
                    "dropdown[", panel_width + spacer, ",2.7;3.5,0.8;realmcategory;Default,Spawn,Classroom,Instanced;", context.selected_realm_type or 1, ";true]",
                    "textarea[", panel_width + text_spacer + 3.6, ",2.25;3.6,1;;;Generation]",
                    "dropdown[", panel_width + spacer + 3.6, ",2.7;3.5,0.8;mode;Empty World,Schematic,Digital Twin;", context.selected_mode or 1, ";true]",
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
                    "checkbox[", panel_width + spacer, ",5.5;priv_interact;;true]",
                    "checkbox[", panel_width + spacer, ",5.9;priv_shout;;true]",
                    "checkbox[", panel_width + spacer + 2.4, ",5.5;priv_fast;;true]",
                    "checkbox[", panel_width + spacer + 2.4, ",5.9;priv_fly;;false]",
                    "checkbox[", panel_width + spacer + 4.8, ",5.5;priv_noclip;;false]",
                    "checkbox[", panel_width + spacer + 4.8, ",5.9;priv_give;;false]",

                    "style_type[textarea;font=mono,bold]",
                    "textarea[", panel_width + text_spacer, ",6.2;", panel_width - 2*text_spacer, ",1;;;Background Music]",
                    "dropdown[", panel_width + spacer, ",6.6;", panel_width - 2*spacer, ",0.8;bgmusic;None;1;false]",
                    "textarea[", panel_width + text_spacer, ",7.5;", panel_width - 2*text_spacer, ",1;;;Skybox]",
                    "dropdown[", panel_width + spacer, ",7.9;", panel_width - 2*spacer, ",0.8;skybox;Default;1;false]",
                    "button[", panel_width + spacer, ",9;", panel_width - 2*spacer, ",0.8;requestrealm;Generate Classroom]",
                }))

                return fs
                --[[ -- Background Music
                -- method: local backgroundSound = realm:get_data("background_sound")
                fs[#fs + 1] = "dropdown["
                fs[#fs + 1] = tostring(fsx)
                fs[#fs + 1] = ","
                fs[#fs + 1] = tostring(fsy)
                fs[#fs + 1] = ";"
                last_width = (page_width/2)-0.1
                fs[#fs + 1] = tostring(last_width)
                fs[#fs + 1] = ","
                last_height = 0.6
                fs[#fs + 1] = tostring(last_height)
                -- iterate registered music
                mc_worldManager.path
                fs[#fs + 1] = ";music;None,this song,another song,third song;"
                fs[#fs + 1] = ";true]"]]
			end,
			["3"] = function() -- MAP
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
            ["4"] = function() -- PLAYERS
                return {}
            end,
			["5"] = function() -- MODERATION
                local fs = {}
                local fsx, fsy
                fsx = ((controller_width/2)-(((controller_width/8)*3)))/2
                fs[#fs + 1] = "label["
                fs[#fs + 1] = tostring(fsx+(controller_width/2))
                fs[#fs + 1] = ",0.55;"
                fs[#fs + 1] = minetest.colorize("#000","Select a Player to View Messages")
                fs[#fs + 1] = "]textlist["
                fs[#fs + 1] = tostring(fsx+(controller_width/2))
                fs[#fs + 1] = ",0.85;"
                fs[#fs + 1] = tostring(page_width)
                fs[#fs + 1] = ","
                fs[#fs + 1] = tostring(controller_height/4)
                fs[#fs + 1] = ";playerlist;"
                local chatmessages, directmessages
                chatmessages = minetest.deserialize(mc_student.meta:get_string("chat_messages"))
                directmessages = minetest.deserialize(mc_student.meta:get_string("direct_messages"))
                local countchat = 0
                local countdm = 0
                local counter = 0
                if chatmessages then for _ in pairs(chatmessages) do countchat = countchat + 1 end end
                local indexed_chat_players = {}
                if directmessages then 
                    for pname,_ in pairs(directmessages) do
                        table.insert(indexed_chat_players,pname)
                        local player_messages = directmessages[pname]
                        for to_player,_ in pairs(player_messages) do
                            local to_player_messages = player_messages[to_player]
                            for _ in pairs(to_player_messages) do
                                countdm = countdm + 1 
                            end
                        end
                    end 
                end
                local unique_chat_players = {}
                if directmessages then
                    for pnamed,_ in pairs(directmessages) do
                        table.insert(unique_chat_players,pnamed)
                        table.insert(indexed_chat_players,pnamed)
                    end
                end

                if chatmessages then
                    for pnamec,_ in pairs(chatmessages) do
                        for pnamec,_ in pairs(unique_chat_players) do
                            if pnamed ~= pnamec then
                                table.insert(unique_chat_players,pnamed)
                                table.insert(indexed_chat_players,pnamed)
                            end
                        end
                    end
                end
                -- Send indexed_chat_players to mod storage so that we can use it later for delete/clear callbacks
                context.indexed_chat_players = indexed_chat_players
                if unique_chat_players then
                    for _,pname in pairs(unique_chat_players) do
                        counter = counter + 1
                        fs[#fs + 1] = pname
                        if counter ~= #unique_chat_players then fs[#fs + 1] = "," end
                    end
                else
                    fs[#fs + 1] = "No chat messages logged"
                end
                fs[#fs + 1] = ";1;false]"
                if #unique_chat_players > 0 then
                    -- Add another textlist below with the messages from the selected player
                    if not tonumber(context.player_chat_index) then context.player_chat_index = 1 end
                    fs[#fs + 1] = "label["
                    fs[#fs + 1] = tostring(fsx+(controller_width/2))
                    fs[#fs + 1] = ","
                    fs[#fs + 1] = tostring(controller_height/4+0.85+0.4)
                    fs[#fs + 1] = ";"
                    fs[#fs + 1] = minetest.colorize("#000","Select a Message")
                    fs[#fs + 1] = "]textlist["
                    fs[#fs + 1] = tostring(fsx+(controller_width/2))
                    fs[#fs + 1] = ","
                    fs[#fs + 1] = tostring(controller_height/4+0.85+0.7)
                    fs[#fs + 1] = ";"
                    fs[#fs + 1] = tostring(page_width)
                    fs[#fs + 1] = ","
                    fs[#fs + 1] = tostring(controller_height/4)
                    fs[#fs + 1] = ";playerchatlist;"
                    local pname = indexed_chat_players[tonumber(context.player_chat_index)]
                    local player_chat_log, player_dm_log
                    if chatmessages then player_chat_log = chatmessages[pname] end
                    local to_player_names = {}
                    if directmessages then 
                        player_dm_log = directmessages[pname]
                        -- Parse the textlist index to the to_player_names
                        if player_dm_log then
                            for to_pname,_ in pairs(player_dm_log) do
                                local to_player_messages = player_dm_log[to_pname]
                                -- Repeat the to_player_name for as many DMs logged to create the indexed array
                                for _ in pairs(to_player_messages) do
                                    table.insert(to_player_names,to_pname) 
                                end
                            end
                        end
                    end
                    -- Direct messages first
                    if player_dm_log then
                        for to_player,_ in pairs(player_dm_log) do
                            counter = 0
                            for key,message in pairs(player_dm_log[to_player]) do
                                counter = counter + 1
                                fs[#fs + 1] = key
                                fs[#fs + 1] = " DM to "
                                fs[#fs + 1] = to_player
                                fs[#fs + 1] = ": "
                                fs[#fs + 1] = message
                                if (counter ~= #player_dm_log[to_player]) or (counter == #player_dm_log[to_player] and player_chat_log and #player_chat_log > 0) then 
                                    fs[#fs + 1] = "," 
                                end
                            end
                        end
                    end
                    -- General chat messages second
                    if player_chat_log then
                        counter = 0
                        for key,message in pairs(player_chat_log) do
                            counter = counter + 1
                            fs[#fs + 1] = key
                            fs[#fs + 1] = ": "
                            fs[#fs + 1] = message
                            if counter ~= #player_chat_log then fs[#fs + 1] = "," end
                        end
                    end
                    fs[#fs + 1] = ";"
                    local chat_index = tonumber(context.mod_chat_index) or 1
                    fs[#fs + 1] = tostring(chat_index)
                    fs[#fs + 1] = ";false]"
                    if countchat > 0 or countdm > 0 then
                        if countdm > 0 and chat_index <= countdm then
                            local selected_to_player = to_player_names[chat_index]
                            local selected_to_player_log = player_dm_log[selected_to_player]
                            -- Get the message
                            counter = 0
                            for key,message in pairs(selected_to_player_log) do
                                counter = counter + 1
                                -- There may be many DMs with the selected_to_player_log, so get the correct message based on the chat_index
                                if counter == chat_index then
                                    fs[#fs + 1] = "label["
                                    fs[#fs + 1] = tostring(fsx+(controller_width/2))
                                    fs[#fs + 1] = ","
                                    fs[#fs + 1] = tostring(controller_height/4+0.85+0.7+controller_height/4+0.2+0.2)
                                    fs[#fs + 1] = ";"
                                    fs[#fs + 1] = minetest.colorize("#000","Direct message to "..selected_to_player)
                                    fs[#fs + 1] = "]style[message;textcolor=#000]textarea["
                                    fs[#fs + 1] = tostring(fsx+(controller_width/2))
                                    fs[#fs + 1] = ","
                                    fs[#fs + 1] = tostring(controller_height/4+0.85+0.7+controller_height/4+0.2+0.5)
                                    fs[#fs + 1] = ";"
                                    fs[#fs + 1] = tostring(page_width)
                                    fs[#fs + 1] = ","
                                    fs[#fs + 1] = "1"
                                    fs[#fs + 1] = ";message;;"
                                    fs[#fs + 1] = message
                                    fs[#fs + 1] = "]"
                                end
                            end
                        else
                            counter = countdm
                            for key,message in pairs(player_chat_log) do
                                counter = counter + 1
                                if counter == chat_index then
                                    fs[#fs + 1] = "label["
                                    fs[#fs + 1] = tostring(fsx+(controller_width/2))
                                    fs[#fs + 1] = ","
                                    fs[#fs + 1] = tostring(controller_height/4+0.85+0.7+controller_height/4+0.2+0.2)
                                    fs[#fs + 1] = ";"
                                    fs[#fs + 1] = minetest.colorize("#000","Message to all players")
                                    fs[#fs + 1] = "]style[message;textcolor=#000]textarea["
                                    fs[#fs + 1] = tostring(fsx+(controller_width/2))
                                    fs[#fs + 1] = ","
                                    fs[#fs + 1] = tostring(controller_height/4+0.85+0.7+controller_height/4+0.2+0.5)
                                    fs[#fs + 1] = ";"
                                    fs[#fs + 1] = tostring(page_width)
                                    fs[#fs + 1] = ","
                                    fs[#fs + 1] = "1"
                                    fs[#fs + 1] = ";message;;"
                                    fs[#fs + 1] = message
                                    fs[#fs + 1] = "]"
                                end
                            end
                        end
                        -- There are chat messages, so add buttons
                        fs[#fs + 1] = "button["
                        fs[#fs + 1] = tostring(fsx+(controller_width/2))
                        fs[#fs + 1] = ","
                        fs[#fs + 1] = tostring(controller_height/4+0.85+0.7+controller_height/4+0.2+0.5+1+0.2)
                        fs[#fs + 1] = ";2.8,0.6;deletemessage;Delete Selected]button["
                        fs[#fs + 1] = tostring(fsx+(controller_width/2))
                        fs[#fs + 1] = ","
                        fs[#fs + 1] = tostring(controller_height/4+0.85+0.7+controller_height/4+0.2+0.5+1+0.2+0.6+0.2)
                        fs[#fs + 1] = ";3,0.6;clearlog;Clear Player's Log]"
                    end
                end
				return fs
			end,
            ["6"] = function() -- REPORTS
                return {}
            end,
            ["7"] = function() -- HELP
                return {}
            end,
            ["8"] = function() -- SERVER
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
                fs[#fs + 1] = ";3.9,0.8;modifyrules;Modify Server Rules]"
                -- TODO: Manage Bans
				return fs
			end,
		}

        local bookmarked_tab = pmeta:get_string("default_teacher_tab")
		if not tab_map[bookmarked_tab] then
			bookmarked_tab = nil
			pmeta:set_string("default_teacher_tab", nil)
        end
		local selected_tab = (tab_map[tab] and tab) or (tab_map[context.tab] and context.tab) or bookmarked_tab or "1"
        context.tab = selected_tab

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
box[8.295,0;0.05,10.4;#000000]
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
box[8.295,0;0.05,10.4;#000000]
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
box[8.295,0;0.05,10.4;#000000]
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
]]
