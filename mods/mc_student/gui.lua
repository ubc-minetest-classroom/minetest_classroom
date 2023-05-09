local marker_expiry = mc_student.marker_expiry

local function player_can_join_realm(player, realm)
	local realmCategory = realm:getCategory()
	local joinable, reason = realmCategory.joinable(realm, player)
	return joinable
end

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
				local fs = {}
				local yaw
				local rotate = 0
				yaw = player:get_look_yaw()
				if yaw ~= nil then
					-- Find rotation and texture based on yaw.
					yaw = math.deg(yaw)
					yaw = math.fmod (yaw, 360)
					if yaw<0 then yaw = 360 + yaw end
					if yaw>360 then yaw = yaw - 360 end           
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
					yaw = math.floor(yaw / 10) * 10   
				end

				local mapar, fsx, fsy
				fsy = 1
				fsx = (((notebook_width/8)*3.5)-(0.15*32))/2+1
				mapar = mc_mapper.map_handler(player)
				fs[#fs + 1] = "box["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ",1.1;"
				fs[#fs + 1] = tostring(0.15*(32))
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(0.15*(32))
				fs[#fs + 1] = ";#000000]"

				for i=1,32,1 do
					for j=1,32,1 do
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
							fs[#fs + 1] = "image["
							fs[#fs + 1] = tostring(fsx+0.15*(i-1))
							fs[#fs + 1] = ","
							fs[#fs + 1] = tostring(fsy+0.15*(32-j)+0.1)
							fs[#fs + 1] = ";0.2,0.2;"
							fs[#fs + 1] = mapar[i][j].im
							fs[#fs + 1] = "]"
						end
					end
				end
			
				if rotate ~= 0 then
					fs[#fs + 1] = "image["
					fs[#fs + 1] = tostring(fsx+0.15*(16)+0.075)
					fs[#fs + 1] = ","
					fs[#fs + 1] = tostring(fsy+0.15*(16)-0.085)
					fs[#fs + 1] = ";0.4,0.4;d"
					fs[#fs + 1] = tostring(yaw)
					fs[#fs + 1] = ".png^[transformFYR"
					fs[#fs + 1] = tostring(rotate)
					fs[#fs + 1] = "]"
				else
					fs[#fs + 1] = "image["
					fs[#fs + 1] = tostring(fsx+0.15*(16)+0.075)
					fs[#fs + 1] = ","
					fs[#fs + 1] = tostring(fsy+0.15*(16)-0.085)
					fs[#fs + 1] = ";0.4,0.4;d"
					fs[#fs + 1] = tostring(yaw) 
					fs[#fs + 1] = ".png^[transformFY]"
				end

				fsx = ((notebook_width/2)-(((notebook_width/8)*3)))/2
				fs[#fs + 1] = "style_type[label;font_size=*1.2]label[2.9,0.4;"
				fs[#fs + 1] = minetest.colorize("#000","Map of Surroundings")
				fs[#fs + 1] = "]style[note;textcolor=#000]"
				fs[#fs + 1] = "style_type[label;font_size=*1]label["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(32*0.15+fsy+0.6)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = minetest.colorize("#000","Display Coordinates and Elevation")
				fs[#fs + 1] = "]"
				fs[#fs + 1] = "button["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(32*0.15+fsy+0.9)
				fs[#fs + 1] = ";1,0.6;utmcoords;UTM]"
				fs[#fs + 1] = "button["
				fs[#fs + 1] = tostring(fsx+1.2)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(32*0.15+fsy+0.9)
				fs[#fs + 1] = ";1.7,0.6;latloncoords;Lat/Long]"
				fs[#fs + 1] = "button["
				fs[#fs + 1] = tostring(fsx+1.2+1.9)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(32*0.15+fsy+0.9)
				fs[#fs + 1] = ";1.7,0.6;classroomcoords;Classroom]"
				fs[#fs + 1] = "button["
				fs[#fs + 1] = tostring(fsx+1.2+1.9+1.9)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(32*0.15+fsy+0.9)
				fs[#fs + 1] = ";1,0.6;coordsoff;Off]"
				fs[#fs + 1] = "textarea["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(32*0.15+fsy+0.9+1.3)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = tostring((notebook_width/8)*3.5)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring((notebook_height/4)-1.3)
				fs[#fs + 1] = ";note;"
				fs[#fs + 1] = minetest.colorize("#000","Add a note at your current location")
				fs[#fs + 1] = ";]button["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(32*0.15+fsy+(notebook_height/4)+0.9)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = tostring(((notebook_width/2)-(fsx*2))/2)
				fs[#fs + 1] = ",0.6;record;Record]style_type[label;font_size=*1.2]label["
				fs[#fs + 1] = tostring(notebook_width/2+1.6)
				fs[#fs + 1] = ",0.4;"
				fs[#fs + 1] = minetest.colorize("#000","Coordinates Stored in this Classroom")
				fs[#fs + 1] = "]textlist["
				fs[#fs + 1] = tostring(fsx+(notebook_width/2))
				fs[#fs + 1] = ",1.1;"
				fs[#fs + 1] = tostring((notebook_width/8)*3.5)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(notebook_height/3)
				fs[#fs + 1] = ";coordlist;"

				-- Get the stored coordinates for the player
				local pmeta = player:get_meta()
				local realm = Realm.GetRealmFromPlayer(player)
				local pdata
				pdata = minetest.deserialize(pmeta:get_string("coordinates"))
				if pdata == nil then
					fs[#fs + 1] = "No Coordinates Stored"
				else
					local prealms = pdata.realms
					local pcoords = pdata.coords
					local pnotes = pdata.notes
					local newData, newCoords, newNotes, newRealms = {}, {}, {}, {}	
					if prealms then
						local coordcount = 0
						for i in pairs(prealms) do
							local coordrealm = Realm.GetRealm(prealms[i])
							-- Make sure the realm still exists
							if coordrealm then
								-- Not all coordinates stored in player metadata are for the current realm
								if realm and coordrealm and coordrealm.ID == realm.ID then
									coordcount = coordcount + 1
									local pos = pcoords[i]
									if pnotes[i] ~= "" then 
										-- Truncate (...) long entries
										if #pnotes[i] > 35 then
											fs[#fs + 1] = string.sub(pnotes[i], 1, 35)
											fs[#fs + 1] = "..."
										else
											fs[#fs + 1] = pnotes[i] 
										end
									end
									if i ~= #pcoords then fs[#fs + 1] = "," end
								end
								-- Below deletes any coordinates stored in player meta for which a realm no longer exists
								table.insert(newCoords, pdata.coords[i])
								table.insert(newNotes, pdata.notes[i])
								table.insert(newRealms, pdata.realms[i])
								
							end
						end
						if newCoords then
							newData = {coords = newCoords, notes = newNotes, realms = newRealms}
						else
							newData = nil
						end
						pmeta:set_string("coordinates", minetest.serialize(newData))
						if coordcount == 0 then fs[#fs + 1] = "No Coordinates Stored" end
					end
				end
				fs[#fs + 1] = ";1;false]"
				
				-- Check if any coordinates are available, otherwise suppress buttons
				local pmeta = player:get_meta()
				local pdata
				pdata = minetest.deserialize(pmeta:get_string("coordinates"))
				if pdata then
					local prealms = pdata.realms
					local pcoords = pdata.coords
					local pnotes = pdata.notes
					local newData, newCoords, newNotes, newRealms = {}, {}, {}, {}
					if prealms then
						for i in pairs(prealms) do
							local coordrealm = Realm.GetRealm(prealms[i])
							-- Make sure the realm still exists
							if coordrealm then
								local realm = Realm.GetRealmFromPlayer(player)
								-- Not all coordinates stored in player metadata are for the current realm
								if realm and coordrealm and coordrealm.ID == realm.ID then
									fs[#fs + 1] = "button["
									fs[#fs + 1] = tostring(fsx+(notebook_width/2))
									fs[#fs + 1] = ","
									fs[#fs + 1] = tostring(32*0.15+fsy+(notebook_height/4)+0.9)
									fs[#fs + 1] = ";"
									fs[#fs + 1] = tostring(((notebook_width/2)-(fsx*2))/3)
									fs[#fs + 1] = ",0.6;go;Go]button["
									fs[#fs + 1] = tostring(fsx+(notebook_width/2))
									fs[#fs + 1] = ","
									fs[#fs + 1] = tostring((notebook_height/3)+1.1)
									fs[#fs + 1] = ";1.7,0.6;delete;Delete]button["
									fs[#fs + 1] = tostring(notebook_width/2+1.1+1.7+0.2)
									fs[#fs + 1] = ","
									fs[#fs + 1] = tostring((notebook_height/3)+1.1)
									fs[#fs + 1] = ";1.7,0.6;clear;Clear All]"
									if mc_core.checkPrivs(player, {shout = true}) then
										fs[#fs + 1] = "button["
										fs[#fs + 1] = tostring(fsx+(notebook_width/2)+(((notebook_width/2)-(fsx*2))/3)+0.2)
										fs[#fs + 1] = ","
										fs[#fs + 1] = tostring(32*0.15+fsy+(notebook_height/4)+0.9)
										fs[#fs + 1] = ";"
										fs[#fs + 1] = tostring(((notebook_width/2)-(fsx*2))/3)
										fs[#fs + 1] = ",0.6;share;Share in Chat]button["
										fs[#fs + 1] = tostring(fsx+(notebook_width/2)+(((notebook_width/2)-(fsx*2))/3)+0.2+(((notebook_width/2)-(fsx*2))/3)+0.2)
										fs[#fs + 1] = ","
										fs[#fs + 1] = tostring(32*0.15+fsy+(notebook_height/4)+0.9)
										fs[#fs + 1] = ";"
										fs[#fs + 1] = tostring(((notebook_width/2)-(fsx*2))/3)
										fs[#fs + 1] = ",0.6;mark;Place Marker]"
									end
--[[ 									fs[#fs + 1] = "style_type[label;font_size=16]label["
									fs[#fs + 1] = tostring(fsx+(notebook_width/2))
									fs[#fs + 1] = ","
									fs[#fs + 1] = tostring((notebook_height/3)+2.5)
									fs[#fs + 1] = ";"
									fs[#fs + 1] = minetest.colorize("#000","Selected Coordinate:")
									fs[#fs + 1] = "]"
									fs[#fs + 1] = "style_type[label;font_size=16]label["
									fs[#fs + 1] = tostring(fsx+(notebook_width/2))
									fs[#fs + 1] = ","
									fs[#fs + 1] = tostring((notebook_height/3)+2.4+0.7)
									fs[#fs + 1] = ";"
									fs[#fs + 1] = minetest.colorize("#000","Latitude and Longitude")
									fs[#fs + 1] = "]"
									fs[#fs + 1] = "style_type[label;font_size=16]label["
									fs[#fs + 1] = tostring(fsx+(notebook_width/2))
									fs[#fs + 1] = ","
									fs[#fs + 1] = tostring((notebook_height/3)+2.4+0.7+0.7)
									fs[#fs + 1] = ";"
									fs[#fs + 1] = minetest.colorize("#000","Local Position {x, y, z}")
									fs[#fs + 1] = "]" ]]
								end
								-- Below deletes any coordinates stored in player metadata for which a realm no longer exists
								table.insert(newCoords, pdata.coords[i])
								table.insert(newNotes, pdata.notes[i])
								table.insert(newRealms, pdata.realms[i])
							end
						end
						if newCoords and #newCoords > 0 then
							newData = {coords = newCoords, notes = newNotes, realms = newRealms}
						else
							netData = nil
						end
						pmeta:set_string("coordinates", minetest.serialize(newData))
					end
				end
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
]]