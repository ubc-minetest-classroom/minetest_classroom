local marker_expiry = mc_student.marker_expiry

--- Returns true if the given player can join the given realm, false otherwise
local function player_can_join_realm(player, realm)
	local realmCategory = realm:getCategory()
	local joinable, reason = realmCategory.joinable(realm, player)
	return joinable
end

--- Returns a list of classrooms that the given player can join
local function get_fs_classroom_list(player)
	local list = {}
	Realm.ScanForPlayerRealms()

	for _,realm in pairs(Realm.realmDict) do
		-- check if the realm is something that should be shown to this player
		if mc_core.checkPrivs(player, {teacher = true}) or player_can_join_realm(player, realm) then
			local playerCount = tonumber(realm:GetPlayerCount())
			table.insert(list, table.concat({
				realm.Name, " (", playerCount, " player", playerCount == 1 and "" or "s", ")"
			}))
		end
	end
	return table.concat(list, ",")
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
	return "mc_student_ping.png^[sheet:1x6:0,"..tile
end

--- Returns a list containing the names of the given player's saved coordinates
local function get_saved_coords(player)
	local pmeta = player:get_meta()
	local realm = Realm.GetRealmFromPlayer(player)
	local pdata = minetest.deserialize(pmeta:get_string("coordinates"))
	local coord_list = {}

	if pdata == nil or pdata == {} then
		return coord_list
	elseif pdata.realms then
		local newData, newCoords, newNotes, newRealms = {}, {}, {}, {}	
		for i,_ in pairs(pdata.realms) do
			local coordrealm = Realm.GetRealm(pdata.realms[i])
			if realm and coordrealm then
				-- Remove coordinates saved in other realms
				if coordrealm.ID == realm.ID and pdata.notes[i] ~= "" then
					table.insert(coord_list, pdata.notes[i])
				end
				-- Remove coordinates saved in realms that no longer exist
				table.insert(newCoords, pdata.coords[i])
				table.insert(newNotes, pdata.notes[i])
				table.insert(newRealms, pdata.realms[i])
			end
		end

		if #newCoords > 0 then
			newData = {coords = newCoords, notes = newNotes, realms = newRealms}
		else
			newData = nil
		end

		pmeta:set_string("coordinates", minetest.serialize(newData))
		return coord_list
	end
end

--- Rounds a yaw measurement to the nearest multiple which a texture exists for
local function round_to_texture_multiple(yaw)
	local adjust = math.floor(yaw / 90)
	local yaw_ref = math.fmod(yaw, 90)
	local angle_table = {10, 20, 30, 40, 45, 50, 60, 70, 80, 90}
	local best = {angle = 0, diff = math.abs(yaw_ref)}

	for _,angle in pairs(angle_table) do
		local diff = math.abs(yaw_ref - angle)
		if diff < best.diff then
			best.diff = diff
			best.angle = angle
		end
	end
	return best.angle + (adjust * 90)
end

function mc_student.show_notebook_fs(player, tab)
	local notebook_width = 16.4
	local notebook_height = 10.2
    local pname = player:get_player_name()
	local pmeta = player:get_meta()
	local context = mc_student.get_fs_context(player)

	if mc_core.checkPrivs(player,{interact = true}) then
		local tab_map = {
			[mc_student.TABS.OVERVIEW] = function() -- OVERVIEW + RULES
				local button_width = 1.7
				local button_height = 1.6
				local rules = mc_rules.meta:get_string("rules")
				if not rules or rules == "" then
					rules = "Rules have not yet been set for this server. Please contact a teacher for more information."
				end

				local fs = {
					"image[0,0;16.4,0.5;mc_pixel.png^[multiply:#acacac]",
					"image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
					"tooltip[exit;Exit]",
					"hypertext[0.55,0.1;7.1,1;;<style font=mono><center><b>Overview</b></center></style>]",
					"hypertext[8.75,0.1;7.1,1;;<style font=mono><center><b>Dashboard</b></center></style>]",

					"style_type[textarea;font=mono,bold;textcolor=#000000]",
					"textarea[0.55,1;7.1,1;;;Welcome to Minetest Classroom!]",
					"textarea[0.55,4.4;7.1,1;;;Server Rules]",
					"style_type[textarea;font=normal]",
					"textarea[0.55,1.5;7.1,2.8;;;", minetest.formspec_escape("This is the Student Notebook, your tool for accessing classrooms and other features."),
					"\n", minetest.formspec_escape("You cannot drop or delete the Student Notebook, so you will never lose it. However, you can move it out of your hotbar and into your inventory or the toolbox."), "]",
					"textarea[0.55,4.9;7.1,4.7;;;", minetest.formspec_escape(rules), "]",

					"image_button[8.8,1.0;", button_width, ",", button_height, ";mc_student_classrooms.png;classrooms;;false;false]",
					"image_button[8.8,2.75;", button_width, ",", button_height, ";mc_student_map.png;map;;false;false]",
					"image_button[8.8,4.5;", button_width, ",", button_height, ";mc_student_appearance.png;appearance;;false;false]",
					"image_button[8.8,6.25;", button_width, ",", button_height, ";mc_student_help.png;help;;false;false]",
					"hypertext[10.6,1.3;5.25,1.6;;<style color=#000000><b>Classrooms</b>\n", minetest.formspec_escape("Find classrooms or players"), "</style>]",
					"hypertext[10.6,3.05;5.25,1.6;;<style color=#000000><b>Map</b>\n", minetest.formspec_escape("Record and share locations"), "</style>]",
					"hypertext[10.6,4.8;5.25,1.6;;<style color=#000000><b>Appearance</b>\n", minetest.formspec_escape("Personalize your avatar"), "</style>]",
					"hypertext[10.6,6.55;5.25,1.6;;<style color=#000000><b>Help</b>\n", minetest.formspec_escape("Report a player or server issue"), "</style>]",
				}
				return fs
			end,
			[mc_student.TABS.CLASSROOMS] = function() -- CLASSROOMS + ONLINE PLAYERS
				-- TODO: add area/realm owner information
				local fs = {
					"image[0,0;16.4,0.5;mc_pixel.png^[multiply:#acacac]",
					"image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
					"tooltip[exit;Exit]",
					"hypertext[0.55,0.1;7.1,1;;<style font=mono><center><b>Classrooms</b></center></style>]",
					"hypertext[8.75,0.1;7.1,1;;<style font=mono><center><b>Online Players</b></center></style>]",

					"style_type[textarea;font=mono,bold;textcolor=#000000]",
					"textarea[0.55,1;7.1,1;;;Available Classrooms]",
					"textlist[0.6,1.5;7,7.2;classroomlist;", get_fs_classroom_list(player), ";", context.selected_realm or "1", ";false]",
					"style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:#1e1e1e]",
					"button[0.6,8.8;7,0.8;teleportrealm;Teleport]",
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
							"image[0.6,", fsy - 0.05, ";0.5,0.4;", ping_texture, "]",
							"textarea[1.2,", fsy, ";6.4,1;;;", teacher, "]"
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
				for student,_ in pairs(mc_student.students) do
					if student then
						local pinfo = minetest.get_player_information(student)
						local ping_texture = get_ping_texture(pinfo)
						table.insert(player_lists.student, table.concat({
							"image[0.6,", fsy - 0.05, ";0.5,0.4;", ping_texture, "]",
							"textarea[1.2,", fsy, ";6.4,1;;;", student, "]"
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
						"scrollbar[16.1,0.5;0.3,", Y_SIZE, ";vertical;playerscroll;", context.playerscroll or 0, "]"
					}) or "",
					"scroll_container[8.2,0.5;7.9,", Y_SIZE, ";playerscroll;vertical;", FACTOR, "]",

					#player_lists.teacher > 0 and ("textarea[0.55,"..label_height.teacher..";7.1,1;;;Teachers]") or "",
					#player_lists.student > 0 and ("textarea[0.55,"..label_height.student..";7.1,1;;;Students]") or "",
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
				local map_x = 0.65
				local map_y = 1.55
				local fs = {
					"image[0,0;16.4,0.5;mc_pixel.png^[multiply:#acacac]",
					"image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
					"tooltip[exit;Exit]",
					"hypertext[0.55,0.1;7.1,1;;<style font=mono><center><b>Map</b></center></style>]",
					"hypertext[8.75,0.1;7.1,1;;<style font=mono><center><b>Coordinates</b></center></style>]",
					"style_type[textarea;font=mono,bold;textcolor=#000000]",
					"textarea[0.55,1;7.1,1;;;Surrounding Area]",
					"image[", map_x - 0.05, ",", map_y - 0.05, ";7,6.55;mc_pixel.png^[multiply:#000000]",
					"image[", map_x, ",", map_y, ";6.9,6.45;mc_pixel.png^[multiply:#808080]",
				}
				
				local bounds = {xmin = -24, xmax = 23, zmin = -22, zmax = 22}
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
							if mapar[i][j].y ~= mapar[i][j+1].y then mapar[i][j].im = mapar[i][j].im .. "^1black_blockt.png" end
							if mapar[i][j].y ~= mapar[i][j-1].y then mapar[i][j].im = mapar[i][j].im .. "^1black_blockb.png" end
							if mapar[i][j].y ~= mapar[i-1][j].y then mapar[i][j].im = mapar[i][j].im .. "^1black_blockl.png" end
							if mapar[i][j].y ~= mapar[i+1][j].y then mapar[i][j].im = mapar[i][j].im .. "^1black_blockr.png" end
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
					yaw = math.fmod(round_to_texture_multiple(math.deg(yaw)), 360)
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
					"image[", 3.975 + (pos.x - round_px)*0.15, ",", 4.625 - (pos.z - round_pz)*0.15,
					";0.4,0.4;mc_student_d", yaw, ".png^[transformFY", rotate ~= 0 and ("R"..rotate) or "", "]",
					"textarea[0.55,8.3;7.1,1;;;Coordinate and Elevation Display]",
					"style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:#1e1e1e]",
					"button[0.6,8.8;1.675,0.8;utmcoords;UTM]",
					"button[2.375,8.8;1.675,0.8;latloncoords;Lat/Lon]",
					"button[4.15,8.8;1.675,0.8;classroomcoords;Local]",
					"button[5.925,8.8;1.675,0.8;coordsoff;Off]",
					"textarea[8.75,1;7.1,1;;;Saved Coordinates]",
				}))

				local coord_list = get_saved_coords(player)
				table.insert(fs, table.concat({
					"textlist[8.8,1.5;7,3.9;coordlist;", coord_list and #coord_list > 0 and table.concat(coord_list, ",") or "No coordinates saved!", ";", context.selected_coord or 1, ";false]",
					"image_button[14.6,1;1.2,0.5;mc_student_clear.png;clear;Clear;false;false]",
					coord_list and #coord_list > 0 and "" or "style_type[button;bgimg=mc_pixel.png^[multiply:#acacac]",
					"button[8.8,5.5;3.45,0.8;", coord_list and #coord_list > 0 and "go" or "blocked_go", ";Teleport]",
					"button[12.35,5.5;3.45,0.8;", coord_list and #coord_list > 0 and "delete" or "blocked_delete", ";Delete]",
					"button[8.8,6.4;3.45,0.8;", coord_list and #coord_list > 0 and "share" or "blocked_share", ";Share in Chat]",
					"button[12.35,6.4;3.45,0.8;", coord_list and #coord_list > 0 and "mark" or "blocked_mark", ";Place a Marker]",
					coord_list and #coord_list > 0 and "" or "style_type[button;bgimg=mc_pixel.png^[multiply:#1e1e1e]",
					"textarea[8.75,7.55;7.1,1;;;Save current coordinates]",
					"style_type[textarea;font=mono]",
					"textarea[8.8,8;6.1,1.6;note;;]",
					"image_button[14.9,8;0.9,1.6;mc_student_save.png;record;Save;false;false]",
					"tooltip[utmcoords;Displays real-world UTM coordinates]",
					"tooltip[latloncoords;Displays real-world latitude and longitude]",
					"tooltip[classroomcoords;Displays in-game coordinates, relative to the classroom]",
					"tooltip[coordsoff;Disables coordinate display]",
					"tooltip[note;Add a note here!]",
				}))

				return fs
			end,
			[mc_student.TABS.APPEARANCE] = function() -- APPEARANCE
				local fs = {}
				fs[#fs + 1] = "style_type[textarea;font=mono,bold;textcolor=black]"
				fs[#fs + 1] = "textarea[0.55,0.5;7.1,1;;;Coming Soon]"
				return fs
			end,
			[mc_student.TABS.HELP] = function() -- HELP + REPORTS
				local fs, mapar, fsx, fsy
				local fs = {}
				fsy = 1
				fsx = ((notebook_width/2)-(0.15*32))/2
				fs[#fs + 1] = "style_type[label;font_size=*1.2]label[3.3,0.4;"
				fs[#fs + 1] = minetest.colorize("#000", "Server Rules")
				fs[#fs + 1] = "]style[rulesmsg;textcolor=#000;border=false]textarea[1,0.85;"
				fs[#fs + 1] = tostring((notebook_width/8)*3.5)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(notebook_height-1.7)
				fs[#fs + 1] = ";rulesmsg;;"
				local rules_text = mc_rules.meta:get_string("rules")
				if rules_text and rules_text ~= "" then
					fs[#fs + 1] = rules_text
				else
					fs[#fs + 1] = "Rules have not yet been set for this server. Please contact a Teacher for more information."
				end
				fs[#fs + 1] = "]style_type[label;font_size=*1.2]label["
				fs[#fs + 1] = tostring(notebook_width/2+3.3)
				fs[#fs + 1] = ",0.4;"
				fs[#fs + 1] = minetest.colorize("#000","Report a Problem")
				fs[#fs + 1] = "]style[instructions;textcolor=#000;border=false]textarea["
				fs[#fs + 1] = tostring(notebook_width/2+1)
				fs[#fs + 1] = ",1.1;"
				fs[#fs + 1] = tostring((notebook_width/8)*3.5)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(notebook_height/3)
				fs[#fs + 1] = ";instructions;"
				fs[#fs + 1] = minetest.colorize("#000","Instructions")
				fs[#fs + 1] = ";"
				fs[#fs + 1] = minetest.colorize("#000","Found a bug? Need to report a problem with a player? You can submit a message below that will be sent to all Teachers on this server. Your message is private and will only notify any Teachers online, but do not share personal information. If no Teacher is online right now, then your report will be shown to the first Teacher who joins the server.")
				fs[#fs + 1] = "]style[report;textcolor=#A0A0A0]textarea["
				fs[#fs + 1] = tostring(notebook_width/2+1)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring((notebook_height/3)+2.5)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = tostring((notebook_width/8)*3.5)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring((notebook_height/3)+0.1)
				fs[#fs + 1] = ";report;"
				fs[#fs + 1] = minetest.colorize("#000","What are you reporting?")
				fs[#fs + 1] = ";The server automatically logs the current date and time along with your current position and classroom information, so you do not need to include this information in your report.]button["
				fs[#fs + 1] = tostring((notebook_width/2)+((notebook_width/2)-(((notebook_width/8)*3)))/2)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(32*0.15+fsy+(notebook_height/4)+1.1)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = tostring(((notebook_width/2)-(fsx*2))/2)
				fs[#fs + 1] = ",0.6;submitreport;Report]"
				return fs
			end,
		}
		
		local bookmarked_tab = pmeta:get_string("default_student_tab")
		if not tab_map[bookmarked_tab] then
			bookmarked_tab = nil
			pmeta:set_string("default_student_tab", nil)
		end
		local selected_tab = (tab_map[tab] and tab) or bookmarked_tab or (tab_map[context.tab] and context.tab) or "1"

		local student_formtable = {
			"formspec_version[6]",
			"size[", tostring(notebook_width), ",", tostring(notebook_height), "]",
			mc_core.draw_book_fs(notebook_width, notebook_height, {divider = "#d9d9d9"}),
			"style[tabheader;noclip=true]",
			"tabheader[0,-0.25;16,0.55;record_nav;Overview,Classrooms,Map,Appearance,Help;", tab or bookmarked_tab or context.tab or "1", ";true;false]",
			table.concat(tab_map[selected_tab](), "")
		}

		if bookmarked_tab == selected_tab then
			table.insert(student_formtable, table.concat{
				"style_type[image;noclip=true]",
				"image[15.8,-0.25;0.5,0.7;mc_student_bookmark_filled.png]",
				"tooltip[15.8,-0.25;0.5,0.8;This tab is currently bookmarked]",
			})
		else
			table.insert(student_formtable, table.concat{
				"image_button[15.8,-0.25;0.5,0.5;mc_student_bookmark_hollow.png^[colorize:#FFFFFF:127;default_tab;;true;false]",
				"tooltip[default_tab;Bookmark this tab?]",
			})
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

OVERVIEW + RULES TAB:
formspec_version[6]
size[16.4,10.2]
box[0,0;16.4,0.5;#acacac]
box[8.195,0;0.05,10.2;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0;7.1,1;;;Overview]
textarea[8.75,0;7.1,1;;;Dashboard]
textarea[0.55,1;7.1,1;;;Welcome to Minetest Classroom!]
textarea[0.55,1.5;7.1,2.8;;;This is the Student Notebook\, your tool for accessing classrooms and other features. You cannot drop or delete the Student Notebook\, so you will never lose it\, but you can move it out of your hotbar and into your inventory or the toolbox.]
textarea[0.55,4.4;7.1,1;;;Server Rules]
textarea[0.55,4.9;7.1,4.7;;;These are the server rules!]
image_button[8.8,1;1.7,1.6;mc_student_classrooms.png;classrooms;;false;true]
image_button[8.8,2.75;1.7,1.6;mc_student_map.png;map;;false;true]
image_button[8.8,4.5;1.7,1.6;mc_student_appearance.png;appearance;;false;true]
image_button[8.8,6.25;1.7,1.6;mc_student_help.png;help;;false;true]
textarea[10.6,1.3;5.25,1.6;;;Classrooms\nfind classrooms or players]
textarea[10.6,3.05;5.25,1.6;;;Map\nrecord and share locations]
textarea[10.6,4.8;5.25,1.6;;;Appearance\npersonalize your avatar]
textarea[10.6,6.55;5.25,1.6;;;Help\nReport a player or server issue]
image[15.8,-0.25;0.5,0.8;mc_student_bookmark.png]

CLASSROOMS + ONLINE PLAYERS TAB:
formspec_version[6]
size[16.4,10.2]
box[0,0;16.4,0.5;#acacac]
box[8.195,0;0.05,10.2;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0;7.1,1;;;Classrooms]
textarea[8.75,0;7.1,1;;;Online Players]
textarea[0.55,1;7.1,1;;;Available Classrooms]
textlist[0.6,1.5;7,7.2;classroomlist;;1;false]
button[0.6,8.8;7,0.8;teleportrealm;Teleport]
textarea[8.75,1;7.1,1;;;Teachers]
image[8.8,1.5;0.5,0.4;]
textarea[9.4,1.45;6.4,1;;;teacher1]
image[8.8,2;0.5,0.4;]
textarea[9.4,1.95;6.4,1;;;teacher2]
textarea[8.75,2.5;7.1,1;;;Students]
image[8.8,3;0.5,0.4;]
textarea[9.4,2.95;6.4,1;;;student]
box[16.1,0.5;0.3,9.7;#ffffff]

MAP + COORDINATES
formspec_version[6]
size[16.4,10.2]
box[0,0;16.4,0.5;#acacac]
box[8.195,0;0.05,10.2;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0;7.1,1;;;Map]
textarea[8.75,0;7.1,1;;;Coordinates]
textarea[0.55,1;7.1,1;;;Surrounding Area]
box[0.6,1.5;7,6.4;#000000]
box[0.65,1.55;6.9,6.3;#808080]
image[3.9,4.5;0.4,0.4;]
textarea[0.55,8.3;7.1,1;;;Coordinate and Elevation Display]
button[0.6,8.8;1.675,0.8;utmcoords;UTM]
button[2.375,8.8;1.675,0.8;latloncoords;Lat/Long]
button[4.15,8.8;1.675,0.8;classroomcoords;Local]
button[5.925,8.8;1.675,0.8;coordsoff;Off]
textarea[8.75,1;7.1,1;;;Saved Coordinates]
textlist[8.8,1.5;7,3.9;coordlist;;8;false]
image_button[14.6,1;1.2,0.5;blank.png;clear;Clear;false;false]
button[8.8,5.5;3.45,0.8;go;Teleport]
button[12.35,5.5;3.45,0.8;delete;Delete]
button[8.8,6.4;3.45,0.8;share;Share in Chat]
button[12.35,6.4;3.45,0.8;mark;Place a Marker]
textarea[8.75,7.55;7.1,1;;;Save current coordinates]
textarea[8.8,8;6.1,1.6;note;;]
image_button[14.9,8;0.9,1.6;blank.png;;Save;false;false]
]]