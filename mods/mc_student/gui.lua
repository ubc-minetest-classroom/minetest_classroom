--- Returns true if the given player can join the given realm, false otherwise
local function player_can_join_realm(player, realm)
	local realmCategory = realm:getCategory()
	local joinable, reason = realmCategory.joinable(realm, player)
	return joinable
end

--- Returns a ping indicator texture for the given player
local function get_ping_texture(pinfo)
	local tile = 5
	if pinfo then
		local ping = math.floor(pinfo.avg_rtt * 1000/2)
		if ping >= 750 then
			tile = 4
		elseif ping >= 350 then
			tile = 3
		elseif ping >= 150 then
			tile = 2
		elseif ping >= 50 then
			tile = 1
		elseif ping >= 0 then
			tile = 0
		end	
	end
	return "mc_teacher_ping.png^[sheet:1x6:0,"..tile
end

--- Returns a list containing the names of the given player's saved coordinates
local function get_saved_coords(player)
	local pmeta = player:get_meta()
	local realm = Realm.GetRealmFromPlayer(player)
	local pdata = minetest.deserialize(pmeta:get_string("coordinates"))
	local context = mc_student.get_fs_context(player)
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

-- Removes KEY_ from the front of key names
local function clean_key(key)
    return string.match(tostring(key), "K?E?Y?_?KEY_(.-)$") or key
end

function mc_student.show_notebook_fs(player, tab)
	local notebook_width = 16.6
	local notebook_height = 10.4
	local panel_width = notebook_width/2
    local spacer = 0.6
    local text_spacer = 0.55

    local pname = player:get_player_name()
	local pmeta = player:get_meta()
	local context = mc_student.get_fs_context(player)

	if mc_core.checkPrivs(player, {interact = true}) then
		local tab_map = {
			[mc_student.TABS.OVERVIEW] = function() -- OVERVIEW + RULES
				local button_width = 1.7
				local button_height = 1.6
				local rules = mc_rules.meta:get_string("rules")
				if not rules or rules == "" then
					rules = "Rules have not yet been set for this server. Please contact a teacher for more information."
				end

				local fs = {
					"image[0,0;", notebook_width, ",0.5;mc_pixel.png^[multiply:#737373]",
					"image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
					"tooltip[exit;Exit;#325140;#ffffff]",
					"hypertext[", text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Overview</b></center></style>]",
					"hypertext[", panel_width + text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Dashboard</b></center></style>]",

					"style_type[textarea;font=mono,bold;textcolor=#000000]",
					"textarea[", text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Welcome to Minetest Classroom!]",
					"textarea[", text_spacer, ",4.4;", panel_width - 2*text_spacer, ",1;;;Server Rules]",
					"style_type[textarea;font=mono]",
					"textarea[", text_spacer, ",1.5;", panel_width - 2*text_spacer, ",2.6;;;", minetest.formspec_escape("This is the Student Notebook, your tool for accessing classrooms and other features."),
					"\n", minetest.formspec_escape("You cannot drop or delete the Student Notebook, so you will never lose it. However, you can move it out of your hotbar and into your inventory or the toolbox."), "]",
					"textarea[", text_spacer, ",4.9;", panel_width - 2*text_spacer, ",4.9;;;", minetest.formspec_escape(rules), "]",

					"image_button[", panel_width + spacer, ",1.0;", button_width, ",", button_height, ";mc_teacher_classrooms.png;classrooms;;false;false]",
					"image_button[", panel_width + spacer, ",2.8;", button_width, ",", button_height, ";mc_teacher_map.png;map;;false;false]",
					"image_button[", panel_width + spacer, ",4.6;", button_width, ",", button_height, ";mc_teacher_appearance.png;appearance;;false;false]",
					"image_button[", panel_width + spacer, ",6.4;", button_width, ",", button_height, ";mc_teacher_help.png;help;;false;false]",
					"hypertext[", panel_width + spacer + 1.8, ",1.3;5.35,1.6;;<style color=#000000><b>Classrooms</b>\n", minetest.formspec_escape("Find classrooms or players"), "</style>]",
					"hypertext[", panel_width + spacer + 1.8, ",3.1;5.35,1.6;;<style color=#000000><b>Map</b>\n", minetest.formspec_escape("Record and share locations"), "</style>]",
					"hypertext[", panel_width + spacer + 1.8, ",4.9;5.35,1.6;;<style color=#000000><b>Appearance</b>\n", minetest.formspec_escape("Personalize your avatar"), "</style>]",
					"hypertext[", panel_width + spacer + 1.8, ",6.7;5.35,1.6;;<style color=#000000><b>Help</b>\n", minetest.formspec_escape("Report a player or server issue"), "</style>]",
				}
				return fs
			end,
			[mc_student.TABS.CLASSROOMS] = function() -- CLASSROOMS + ONLINE PLAYERS
				local classroom_list = {}
				local realm_count = 1
                context.realm_id_to_i = {}
                Realm.ScanForPlayerRealms()
				
                for id, realm in pairs(Realm.realmDict) do
					if mc_core.checkPrivs(player, {teacher = true}) or player_can_join_realm(player, realm) then
						local playerCount = tonumber(realm:GetPlayerCount())
						table.insert(classroom_list, table.concat({minetest.formspec_escape(realm.Name or ""), " (", playerCount, " player", playerCount == 1 and "" or "s", ")"}))
						context.realm_id_to_i[id] = realm_count
						realm_count = realm_count + 1
					end
                end

				-- TODO: add area/realm owner information
				local fs = {
					"image[0,0;", notebook_width, ",0.5;mc_pixel.png^[multiply:#737373]",
					"image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
					"tooltip[exit;Exit;#325140;#ffffff]",
					"hypertext[", text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Classrooms</b></center></style>]",
					"hypertext[", panel_width + text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Online Players</b></center></style>]",

					"style_type[textarea;font=mono,bold;textcolor=#000000]",
					"textarea[", text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Available Classrooms]",
					"textlist[", spacer, ",1.4;", panel_width - 2*spacer, ",7.5;classroomlist;", table.concat(classroom_list, ","), ";", context.realm_id_to_i and context.realm_id_to_i[context.selected_realm] or "1", ";false]",
					"style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:#1e1e1e]",
					"button[", spacer, ",9;", panel_width - 2*spacer, ",0.8;teleportrealm;Teleport]",
				}

				local fsy = 1
				local Y_SHIFT = 0.5
				local player_lists = {
					teacher = {},
					student = {}
				}
				local label_height = {
					teacher = 0.5,
					student = 0.5
				}

				-- test teachers: {profpickell = true, anotherTeacher = true, a_lovely_ta = false, moderator1 = 1, teacher2 = 2, foobar = 3}
				-- test ping: {avg_rtt = math.random() - 0.2}
				for teacher,_ in pairs(mc_teacher.teachers) do
					if teacher then
						local pinfo = minetest.get_player_information(teacher)
						local ping_texture = get_ping_texture(pinfo)
						table.insert(player_lists.teacher, table.concat({
							"image[", spacer, ",", fsy - 0.05, ";0.5,0.4;", ping_texture, "]",
							"textarea[", spacer + 0.6, ",", fsy, ";", panel_width - 2*spacer - 0.6, ",1;;;", teacher, "]"
						}))
						fsy = fsy + Y_SHIFT
					end
				end
				if #player_lists.teacher > 0 then
					fsy = fsy + 0.2
					label_height.student = fsy
					fsy = fsy + Y_SHIFT
				end

				--test students: {fofo = true, jiji = false, baba = 3, keke = "yes", me = 1, nan = 2, west = 3, lala = 4, foo = 6, bar = 7, baz = 8, bat = 9}
				--test ping: {avg_rtt = math.random() * 2}
				for student,_ in pairs(mc_teacher.students) do
					if student then
						local pinfo = minetest.get_player_information(student)
						local ping_texture = get_ping_texture(pinfo)
						table.insert(player_lists.student, table.concat({
							"image[", spacer, ",", fsy - 0.05, ";0.5,0.4;", ping_texture, "]",
							"textarea[", spacer + 0.6, ",", fsy, ";", panel_width - 2*spacer - 0.6, ",1;;;", student, "]"
						}))
						fsy = fsy + Y_SHIFT
					end
				end
				if #player_lists.student > 0 then
					fsy = fsy + Y_SHIFT
				end

				fsy = fsy - 0.05 -- image positioning adjustment

				local Y_SIZE, FACTOR = 9.7, 0.05
				table.insert(fs, table.concat({
					fsy > Y_SIZE and table.concat({
						"scrollbaroptions[min=0;max=", (fsy - Y_SIZE)/FACTOR, ";smallstep=", 0.8/FACTOR, ";largestep=", 4.8/FACTOR, ";thumbsize=", 1/FACTOR, "]",
						"scrollbar[", notebook_width - 0.3, ",0.5;0.3,", Y_SIZE, ";vertical;playerscroll;", context.playerscroll or 0, "]"
					}) or "",
					"scroll_container[", panel_width, ",0.5;7.9,", Y_SIZE, ";playerscroll;vertical;", FACTOR, "]",

					#player_lists.teacher > 0 and table.concat({"textarea[", text_spacer, ",", label_height.teacher, ";", panel_width - 2*text_spacer, ",1;;;Teachers]"}) or "",
					#player_lists.student > 0 and table.concat({"textarea[", text_spacer, ",", label_height.student, ";", panel_width - 2*text_spacer, ",1;;;Students]"}) or "",
					"style_type[textarea;font=mono]",
				}))
				for _,fs_teacher in pairs(player_lists.teacher) do
					table.insert(fs, fs_teacher)
				end
				for _,fs_student in pairs(player_lists.student) do
					table.insert(fs, fs_student)
				end
				table.insert(fs, "scroll_container_end[]")

				return fs
			end,
			[mc_student.TABS.MAP] = function() -- MAP
				local map_x = spacer + 0.025
				local map_y = 1.425
				local fs = {
					"image[0,0;", notebook_width, ",0.5;mc_pixel.png^[multiply:#737373]",
					"image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
					"tooltip[exit;Exit;#325140;#ffffff]",
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
				local texture_base = "[combine:536x440:0,0=blank.png:48,0="
				local has_share_privs = mc_core.checkPrivs(player, {shout = true}) or mc_core.checkPrivs(player, {teacher = true})
				table.insert(fs, table.concat({
					"textlist[", panel_width + spacer, ",1.4;", panel_width - 2*spacer, ",4.8;coordlist;", coord_list and #coord_list > 0 and table.concat(coord_list, ",") or "No coordinates saved!", ";", context.selected_coord or 1, ";false]",
					coord_list and #coord_list > 0 and "" or "style_type[image_button;bgimg=mc_pixel.png^[multiply:#acacac]",
					has_share_privs and "" or "style[mark;bgimg=mc_pixel.png^[multiply:#acacac]",
					"image_button[", panel_width + spacer, ",6.3;1.34,1.1;", texture_base, "mc_teacher_teleport.png;", coord_list and #coord_list > 0 and "go" or "blocked", ";;false;false]",
					"image_button[", panel_width + spacer + 1.44, ",6.3;1.34,1.1;", texture_base, "mc_teacher_share.png;", coord_list and #coord_list > 0 and "share" or "blocked", ";;false;false]",
					"image_button[", panel_width + spacer + 2.88, ",6.3;1.34,1.1;", texture_base, "mc_teacher_mark.png;", coord_list and #coord_list > 0 and "mark" or "blocked", ";;false;false]",
					"image_button[", panel_width + spacer + 4.32, ",6.3;1.34,1.1;", texture_base, "mc_teacher_delete.png;", coord_list and #coord_list > 0 and "delete" or "blocked", ";;false;false]",
					"image_button[", panel_width + spacer + 5.76, ",6.3;1.34,1.1;", texture_base, "mc_teacher_clear.png;", coord_list and #coord_list > 0 and "clear" or "blocked", ";;false;false]",

					coord_list and #coord_list > 0 and "" or "style_type[button;bgimg=mc_pixel.png^[multiply:#1e1e1e]",
					"textarea[", panel_width + text_spacer, ",8.5;", panel_width - 2*text_spacer, ",1;;;Save current coordinates]",
					"style_type[textarea;font=mono]",
					"textarea[", panel_width + text_spacer, ",7.6;", panel_width - 2*text_spacer, ",1;;;SELECTED\nLocal: (X, Y, Z)]",
					"textarea[", panel_width + spacer, ",8.9;6.2,0.9;note;;]",
					"style_type[image_button;bgimg=mc_pixel.png^[multiply:#1e1e1e]",
					"image_button[15.1,8.9;0.9,0.9;mc_teacher_save.png;record;Save;false;false]",
					
					"tooltip[utmcoords;Displays real-world UTM coordinates;#325140;#ffffff]",
					"tooltip[latloncoords;Displays real-world latitude and longitude;#325140;#ffffff]",
					"tooltip[classroomcoords;Displays in-game coordinates, relative to the classroom;#325140;#ffffff]",
					"tooltip[coordsoff;Disables coordinate display;#325140;#ffffff]",
					"tooltip[go;Teleport to location;#325140;#ffffff]",
					"tooltip[share;Share location in chat;#325140;#ffffff]",
					"tooltip[mark;Place marker in world;#325140;#ffffff]",
					"tooltip[delete;Delete location;#325140;#ffffff]",
                    "tooltip[clear;Clear all saved locations;#325140;#ffffff]",
					"tooltip[note;Add a note here!;#325140;#ffffff]",
					"style_type[image_button;bgimg=blank.png]",
				}))

				return fs
			end,
			[mc_student.TABS.APPEARANCE] = function() -- APPEARANCE
				local fs = {
					"image[0,0;", notebook_width, ",0.5;mc_pixel.png^[multiply:#737373]",
					"image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
					"tooltip[exit;Exit;#325140;#ffffff]",
					"hypertext[", text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Appearance</b></center></style>]",
					"hypertext[", panel_width + text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Appearance</b></center></style>]",
					"style_type[textarea;font=mono,bold;textcolor=#000000]",
					"textarea[", text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Coming soon!]"
				}
				return fs
			end,
			[mc_student.TABS.HELP] = function() -- HELP + REPORTS
				local set = minetest.settings
				local fs = {
					"image[0,0;", notebook_width, ",0.5;mc_pixel.png^[multiply:#737373]",
					"image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
					"tooltip[exit;Exit;#325140;#ffffff]",
					"hypertext[", text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Help</b></center></style>]",
					"hypertext[", panel_width + text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Reports</b></center></style>]",
					"style_type[textarea;font=mono,bold;textcolor=#000000]",
					"textarea[", text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Game controls]",
					"textarea[", panel_width + text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Need to report an issue?]",
					"textarea[", panel_width + text_spacer, ",6.1;", panel_width - 2*text_spacer, ",1;;;Report message]",
					"textarea[", panel_width + text_spacer, ",4.8;", panel_width - 2*text_spacer, ",1;;;Report type]",
					"style_type[textarea;font=mono]",
					"style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:#1e1e1e]",

					-- Controls + keybinds
					"textarea[", text_spacer, ",1.5;", panel_width - 2*text_spacer, ",8.3;;;",
					"Move forwards: ", clean_key(set:get("keymap_forward") or "KEY_KEY_W"), "\n",
					"Move backwards: ", clean_key(set:get("keymap_backward") or "KEY_KEY_S"), "\n",
					"Move left: ", clean_key(set:get("keymap_left") or "KEY_KEY_A"), "\n",
					"Move right: ", clean_key(set:get("keymap_right") or "KEY_KEY_D"), "\n",
					"Jump/climb up: ", clean_key(set:get("keymap_jump") or "KEY_SPACE"), "\n",
					"Sneak", set:get("aux1_descends") == "true" and "" or "/climb down", ": ", clean_key(set:get("keymap_sneak") or "KEY_LSHIFT"), "\n",
					"Sprint", set:get("aux1_descends") == "true" and "/climb down" or "", ": ", clean_key(set:get("keymap_aux1") or "KEY_KEY_E"), "\n",
					"Zoom: ", clean_key(set:get("keymap_zoom") or "KEY_KEY_Z"), "\n",
					"\n",
					"Dig block/use tool: ", set:get("keymap_dig") and clean_key(set:get("keymap_dig")) or "LEFT CLICK", "\n",
					"Place block: ", set:get("keymap_dig") and clean_key(set:get("keymap_dig")) or "RIGHT CLICK", "\n",
					"Select hotbar item: SCROLL WHEEL or SLOT NUMBER (1-8)\n",
					"Select next hotbar item: ", clean_key(set:get("keymap_hotbar_next") or "KEY_KEY_N"), "\n",
					"Select previous hotbar item: ", clean_key(set:get("keymap_hotbar_previous") or "KEY_KEY_B"), "\n",
					"Drop item: ", clean_key(set:get("keymap_drop") or "KEY_KEY_Q"), "\n",
					"\n",
					"Open inventory: ", clean_key(set:get("keymap_inventory") or "KEY_KEY_I"), "\n",
					"Open chat: ", clean_key(set:get("keymap_chat") or "KEY_KEY_T"), "\n",
					"View minimap: ", clean_key(set:get("keymap_minimap") or "KEY_KEY_V"), "\n",
					"Take a screenshot: ", clean_key(set:get("keymap_screenshot") or "KEY_F12"), "\n",
					"Change camera perspective: ", clean_key(set:get("keymap_camera_mode") or "KEY_KEY_C"), "\n",
					"\n",
					"Enable/disable sprint: ", clean_key(set:get("keymap_fastmove") or "KEY_KEY_J"), "\n",
					"Enable/disable fly mode: ", clean_key(set:get("keymap_freemove") or "KEY_KEY_K"), "\n",
					"Enable/disable noclip mode: ", clean_key(set:get("keymap_noclip") or "KEY_KEY_H"), "\n",
					"Show/hide HUD (display): ", clean_key(set:get("keymap_toggle_hud") or "KEY_F1"), "\n",
					"Show/hide chat: ", clean_key(set:get("keymap_toggle_chat") or "KEY_F2"), "\n",
					"Show/hide world fog: ", clean_key(set:get("keymap_toggle_force_fog_off") or "KEY_F3"),
					"]",

					"textarea[", panel_width + text_spacer, ",1.5;", panel_width - 2*text_spacer, ",3;;;", minetest.formspec_escape("If you need to report a server issue or player, you can write a message in the box below that will be privately sent to "), 
					pairs(mc_teacher.teachers) ~= nil and "all teachers that are currently online" or "the first teacher that joins the server", ".\n",
					minetest.formspec_escape("Your report message will be logged and visible to all teachers, so don't include any personal information in it. The server will also automatically log the current date and time, your classroom, and your world position in the report, so you don't need to include that information in your report message."), "]",
					"dropdown[", panel_width + spacer, ",5.2;", panel_width - 2*spacer, ",0.7;reporttype;", table.concat(mc_student.REPORT_TYPE, ","), ";1;false]",
					"textarea[", panel_width + spacer, ",6.5;", panel_width - 2*spacer, ",2.4;report;;]",
					"button[", panel_width + spacer, ",9;", panel_width - 2*spacer, ",0.8;submitreport;Submit Report]",
				}

				return fs
			end
		}
		
		local bookmarked_tab = pmeta:get_string("default_student_tab")
		if not tab_map[bookmarked_tab] then
			bookmarked_tab = nil
			pmeta:set_string("default_student_tab", nil)
		end
		local selected_tab = (tab_map[tab] and tab) or (tab_map[context.tab] and context.tab) or bookmarked_tab or "1"
		context.tab = selected_tab

		local student_formtable = {
			"formspec_version[6]",
			"size[", notebook_width, ",", notebook_height, "]",
			mc_core.draw_book_fs(notebook_width, notebook_height, {divider = "#969696"}),
			"style[tabheader;noclip=true]",
			"tabheader[0,-0.25;", notebook_width, ",0.55;record_nav;Overview,Classrooms,Map,Appearance,Help;", selected_tab, ";true;false]",
			table.concat(tab_map[selected_tab](), "")
		}

		if bookmarked_tab == selected_tab then
			table.insert(student_formtable, table.concat({
				"style_type[image;noclip=true]",
				"image[", notebook_width - 0.6, ",-0.25;0.5,0.7;mc_student_bookmark_filled.png]",
				"tooltip[", notebook_width - 0.6, ",-0.25;0.5,0.8;This tab is currently bookmarked;#325140;#ffffff]",
			}))
		else
			table.insert(student_formtable, table.concat({
				"image_button[", notebook_width - 0.6, ",-0.25;0.5,0.5;mc_student_bookmark_hollow.png^[colorize:#FFFFFF:127;default_tab;;true;false]",
				"tooltip[default_tab;Bookmark this tab?;#325140;#ffffff]",
			}))
		end

		minetest.show_formspec(pname, "mc_student:notebook_fs", table.concat(student_formtable, ""))
		return true
	end
end

--[[
NEW FORMSPEC CLEAN COPIES

TAB GROUPING:
[1] OVERVIEW + RULES
[2] CLASSROOMS + ONLINE PLAYERS (classrooms)
[3] MAP + COORDINATES (map)
[4] APPEARANCE (appearance)
[5] HELP + REPORTS (help)

OVERVIEW + RULES:
formspec_version[6]
size[16.6,10.4]
box[0,0;16.6,0.5;#737373]
box[8.275,0;0.05,10.4;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.2,1;;;Overview]
textarea[8.75,0.1;7.2,1;;;Dashboard]
textarea[0.55,1;7.1,1;;;Welcome to Minetest Classroom!]
textarea[0.55,1.5;7.2,2.8;;;This is the Student Notebook\, your tool for accessing classrooms and other features. You cannot drop or delete the Student Notebook\, so you will never lose it\, but you can move it out of your hotbar and into your inventory or the toolbox.]
textarea[0.55,4.4;7.2,1;;;Server Rules]
textarea[0.55,4.9;7.2,4.9;;;These are the server rules!]
image_button[8.9,1;1.7,1.6;mc_teacher_classrooms.png;classrooms;;false;true]
image_button[8.9,2.8;1.7,1.6;mc_teacher_map.png;map;;false;true]
image_button[8.9,4.6;1.7,1.6;mc_teacher_appearance.png;appearance;;false;true]
image_button[8.9,6.4;1.7,1.6;mc_teacher_help.png;help;;false;true]
textarea[10.7,1.3;5.25,1.6;;;Classrooms\nfind classrooms or players]
textarea[10.7,3.1;5.25,1.6;;;Map\nrecord and share locations]
textarea[10.7,4.9;5.25,1.6;;;Appearance\npersonalize your avatar]
textarea[10.7,6.7;5.25,1.6;;;Help\nReport a player or server issue]
image[16,-0.25;0.5,0.8;mc_student_bookmark.png]

CLASSROOMS + ONLINE PLAYERS:
formspec_version[6]
size[16.6,10.4]
box[0,0;16.6,0.5;#737373]
box[8.275,0;0.05,10.4;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.2,1;;;Classrooms]
textarea[8.75,0.1;7.2,1;;;Online Players]
textarea[0.55,1;7.2,1;;;Available Classrooms]
textlist[0.6,1.4;7.1,7.5;classroomlist;;1;false]
button[0.6,9;7.1,0.8;teleportrealm;Teleport]
textarea[8.85,1;7.2,1;;;Teachers]
image[8.9,1.5;0.5,0.4;]
textarea[9.5,1.45;6.4,1;;;teacher1]
image[8.9,2;0.5,0.4;]
textarea[9.5,1.95;6.4,1;;;teacher2]
textarea[8.85,2.5;7.2,1;;;Students]
image[8.9,3;0.5,0.4;]
textarea[9.5,2.95;6.4,1;;;student]
box[16.3,0.5;0.3,9.7;#ffffff]

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
image_button[8.9,5.9;1.34,1.1;blank.png;go;TP;false;true]
image_button[11.78,5.9;1.34,1.1;blank.png;mark;MK;false;true]
image_button[10.34,5.9;1.34,1.1;blank.png;share;SH;false;true]
image_button[13.22,5.9;1.34,1.1;blank.png;delete;DL;false;true]
image_button[14.66,5.9;1.34,1.1;blank.png;clear;DL_A;false;true]

APPEARANCE:
formspec_version[6]
size[16.6,10.4]
box[0,0;16.6,0.5;#737373]
box[8.275,0;0.05,10.4;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.1,1;;;Appearance]
textarea[8.85,0.1;7.1,1;;;Appearance]
textarea[0.55,1;7.2,1;;;Coming soon!]

HELP + REPORTS:
formspec_version[6]
size[16.6,10.4]
box[0,0;16.6,0.5;#737373]
box[8.275,0;0.05,10.4;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.1,1;;;Help]
textarea[8.85,0.1;7.1,1;;;Reports]
textarea[0.55,1;7.2,1;;;Controls]
textarea[8.85,1;7.2,1;;;Need to report an issue?]
textarea[8.85,6.1;7.2,1;;;Report message]
textarea[8.85,4.8;7.2,1;;;Report type]
textarea[0.55,1.5;7.2,8.3;;;Add controls here!]
textarea[8.9,1.5;7.1,3;a;;Add info about reporting here!]
dropdown[8.9,5.2;7.1,0.8;reporttype;Server Issue,Misbehaving Player,Question,Suggestion,Other;1;false]
textarea[8.9,6.5;7.1,2.4;report;;]
button[8.9,9;7.1,0.8;submitreport;Submit Report]

ACCEPTED EMOJI CHARS
- ✔
- ✈
]]