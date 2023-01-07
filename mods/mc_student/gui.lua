local selectedCoord = nil
local selectedClassroom = nil
local selectedRealmID = nil
local marker_expiry = 30

function mc_student.show_notebook_fs(player,tab)
	local notebook_width = 16.4
	local notebook_height = 10.2
    local pname = player:get_player_name()
	local pmeta = player:get_meta()
	if mc_helpers.checkPrivs(player,{interact = true}) then
		local student_formtable = {
			"formspec_version[6]",
			"size[",
			tostring(notebook_width),
			",",
			tostring(notebook_height),
			"]",
			mc_core.draw_book_fs(notebook_width, notebook_height, {bg = "#63406a", shadow = "#3e2b45", binding = "#5d345e", divider = "#d9d9d9"}),
			"style[tabheader;noclip=true]",
			"tabheader[0,-0.25;16,0.55;record_nav;Overview,Classrooms,Map,Players Online,Appearance,Rules and Help;", tab or pmeta:get_string("default_student_tab") or mc_student.fs_context.tab or "1", ";true;false]"
		}
		local tab_map = {
			["1"] = function() -- OVERVIEW
				local fsx, fsy, last_height, last_width
				fsx = notebook_width/2+1
				fsy = 0.85
				local fs = {}
				if pmeta:get_string("default_student_tab") == "1" then
					fs[#fs + 1] = "style_type[label;font_size=*0.8;textcolor=#000]label[0.2,"
					fs[#fs + 1] = tostring(notebook_height-0.2)
					fs[#fs + 1] = ";This tab is the default]"
				else
					fs[#fs + 1] = "checkbox[0.2,"
					fs[#fs + 1] = tostring(notebook_height-0.2)
					fs[#fs + 1] = ";default_tab;"
					fs[#fs + 1] = minetest.colorize("#000","Bookmark?")
					fs[#fs + 1] = ";false]"
				end
				fs[#fs + 1] = "style_type[label;font_size=*1.2]label[2,0.4;"
				fs[#fs + 1] = minetest.colorize("#000", "Welcome to Minetest Classroom!")
				fs[#fs + 1] = "]style[overviewmsg;textcolor=#000;border=false]textarea[1,0.85;"
				fs[#fs + 1] = tostring((notebook_width/8)*3.5)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(notebook_height-1.7)
				fs[#fs + 1] = ";overviewmsg;;This is the Student Notebook, your tool for accessing classrooms and other features. You cannot drop or delete the Student Notebook, so you will never lose it, but you can move it out of your hotbar and into your inventory.]"
				fsx = notebook_width/2+1
				fsy = 0.85
				fs[#fs + 1] = "style_type[label;font_size=*1.2]label["
				fs[#fs + 1] = tostring(notebook_width/2+3.3)
				fs[#fs + 1] = ",0.4;"
				fs[#fs + 1] = minetest.colorize("#000","Student Dashboard")
				fs[#fs + 1] = "]style[classrooms;bgcolor=#FFFFFF]image_button["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(fsy)
				last_height = 1.43
				last_width = 1.514
				fs[#fs + 1] = ";"
				fs[#fs + 1] = last_width
				fs[#fs + 1] = ","
				fs[#fs + 1] = last_height
				fs[#fs + 1] = ";icon_classrooms.png;classrooms;;true;false;]style[map;bgcolor=#FFFFFF]image_button["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fsy = fsy + 1.625
				fs[#fs + 1] = tostring(fsy)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = last_width
				fs[#fs + 1] = ","
				fs[#fs + 1] = last_height
				fs[#fs + 1] = ";icon_map.png;map;;true;false;]style[map;bgcolor=#FFFFFF]image_button["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fsy = fsy + 1.625
				fs[#fs + 1] = tostring(fsy)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = last_width
				fs[#fs + 1] = ","
				fs[#fs + 1] = last_height
				fs[#fs + 1] = ";icon_players_online.png;playersonline;;true;false;]style[map;bgcolor=#FFFFFF]image_button["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fsy = fsy + 1.625
				fs[#fs + 1] = tostring(fsy)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = last_width
				fs[#fs + 1] = ","
				fs[#fs + 1] = last_height
				fs[#fs + 1] = ";icon_appearance.png;appearance;;true;false;]style[map;bgcolor=#FFFFFF]image_button["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fsy = fsy + 1.625
				fs[#fs + 1] = tostring(fsy)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = last_width
				fs[#fs + 1] = ","
				fs[#fs + 1] = last_height
				fs[#fs + 1] = ";icon_help.png;help;;true;false;]"
				-- Labels go here to increment fsx properly
				fsy = 1.3
				fsx = fsx + last_width + 0.2
				fs[#fs + 1] = "style_type[label;font_size=*1;font=bold]label["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(fsy)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = minetest.colorize("#000","Classrooms")
				fsy = fsy + 0.4
				fs[#fs + 1] = "]style_type[label;font_size=*1;font=normal]label["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(fsy)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = minetest.colorize("#000","Find classrooms to join")
				fs[#fs + 1] = "]"
				fsy = fsy + 1.225
				fs[#fs + 1] = "style_type[label;font_size=*1;font=bold]label["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(fsy)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = minetest.colorize("#000","Map")
				fs[#fs + 1] = "]"
				fsy = fsy + 0.4
				fs[#fs + 1] = "]style_type[label;font_size=*1;font=normal]label["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(fsy)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = minetest.colorize("#000","Record locations and take spatial notes")
				fs[#fs + 1] = "]"
				fsy = fsy + 1.225
				fs[#fs + 1] = "style_type[label;font_size=*1;font=bold]label["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(fsy)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = minetest.colorize("#000","Players Online")
				fs[#fs + 1] = "]"
				fsy = fsy + 0.4
				fs[#fs + 1] = "]style_type[label;font_size=*1;font=normal]label["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(fsy)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = minetest.colorize("#000","See who's online")
				fs[#fs + 1] = "]"
				fsy = fsy + 1.225
				fs[#fs + 1] = "style_type[label;font_size=*1;font=bold]label["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(fsy)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = minetest.colorize("#000","Appearance")
				fs[#fs + 1] = "]"
				fsy = fsy + 0.4
				fs[#fs + 1] = "]style_type[label;font_size=*1;font=normal]label["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(fsy)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = minetest.colorize("#000","Personalize your avatar")
				fs[#fs + 1] = "]"
				fsy = fsy + 1.225
				fs[#fs + 1] = "style_type[label;font_size=*1;font=bold]label["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(fsy)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = minetest.colorize("#000","Help")
				fs[#fs + 1] = "]"
				fsy = fsy + 0.4
				fs[#fs + 1] = "]style_type[label;font_size=*1;font=normal]label["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(fsy)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = minetest.colorize("#000","Report an issue or player")
				fs[#fs + 1] = "]"
				return fs
			end,
			["2"] = function() -- CLASSROOMS
				local fsx, fsy, last_height
				fsx = notebook_width/2+1
				fsy = 0.85
				local fs = {}
				if pmeta:get_string("default_student_tab") == "2" then
					fs[#fs + 1] = "style_type[label;font_size=*0.8;textcolor=#000]label[0.2,"
					fs[#fs + 1] = tostring(notebook_height-0.2)
					fs[#fs + 1] = ";This tab is the default]"
				else
					fs[#fs + 1] = "checkbox[0.2,"
					fs[#fs + 1] = tostring(notebook_height-0.2)
					fs[#fs + 1] = ";default_tab;"
					fs[#fs + 1] = minetest.colorize("#000","Bookmark?")
					fs[#fs + 1] = ";false]"
				end
				-- PAGE TWO
				fs[#fs + 1] = "style_type[label;font_size=*1.2]label["
				fs[#fs + 1] = tostring(notebook_width/2+3)
				fs[#fs + 1] = ",0.4;"
				fs[#fs + 1] = minetest.colorize("#000","Available Classrooms")
				fs[#fs + 1] = "]textlist["
				fs[#fs + 1] = tostring((notebook_width/2)+1)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(fsy)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = tostring((notebook_width/8)*3.5)
				fs[#fs + 1] = ","
				last_height = notebook_height/3
				fs[#fs + 1] = tostring(last_height)
				fs[#fs + 1] = ";classroomlist;"

				--[[ -- METHODS
				Realm:TeleportPlayer(player)
				Realm.GetRealmFromPlayer(player)
				mc_worldManager.GetSpawnRealm()
				Realm:getCategory() -- default, spawn, classroom
				Realm.GetRealm(ID) ]]

				-- below is realm structure
				--[[ local this = {
					Name = name,
					ID = Realm.realmCount + 1,
					StartPos = { x = 0, y = 0, z = 0 },
					EndPos = { x = 0, y = 0, z = 0 },
					SpawnPoint = { x = 0, y = 0, z = 0 },
					PlayerJoinTable = {}, -- Table should be populated with tables as follows {{tableName=tableName, functionName=functionName}}
					PlayerLeaveTable = {}, -- Table should be populated with tables as follows {{tableName=tableName, functionName=functionName}}
					RealmDeleteTable = {}, -- Table should be populated with tables as follows {{tableName=tableName, functionName=functionName}}
					Permissions = {},
					MetaStorage = {}
				} ]]
				
				-- return all realms
				local counter = 0
				local countRealms = mc_worldManager.storage:get_string("realmCount")
				-- Quickly update where players are
				Realm.ScanForPlayerRealms()
				for _,thisRealm in pairs(Realm.realmDict) do
					counter = counter + 1
					-- check if the realm is something that should be shown to this player
					if mc_helpers.checkPrivs(player,{teacher = true}) then
						-- show all realms to teachers
						fs[#fs + 1] = thisRealm.Name
						fs[#fs + 1] = " ("
						local playerCount = tonumber(thisRealm:GetPlayerCount())
						fs[#fs + 1] = tostring(playerCount)
						if playerCount == 1 then
							fs[#fs + 1] = " Player)"
						else
							fs[#fs + 1] = " Players)"
						end
					else
						-- check the category
						local realmCategory = thisRealm:getCategory()
						local joinable, reason = realmCategory.joinable(thisRealm, player)
						if joinable then
							fs[#fs + 1] = thisRealm.Name
							fs[#fs + 1] = " ("
							local playerCount = tonumber(thisRealm:GetPlayerCount())
							fs[#fs + 1] = tostring(playerCount)
							if playerCount == 1 then
								fs[#fs + 1] = " Player)"
							else
								fs[#fs + 1] = " Players)"
							end
						end
					end
					if counter ~= countRealms then fs[#fs + 1] = "," end
				end
				if not selectedRealmID then selectedRealmID = mc_worldManager.spawnRealmID end
				local realm = Realm.GetRealm(tonumber(selectedRealmID))
				fs[#fs + 1] = ";1;false]button["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fsy = fsy + last_height + 0.2
				fs[#fs + 1] = tostring(fsy)
				fs[#fs + 1] = ";1.7,"
				last_height = 0.6
				fs[#fs + 1] = tostring(last_height)
				fs[#fs + 1] = ";teleportrealm;Teleport]"
				--[[ fs[#fs + 1] = "style_type[label;font_size=*1,font=bold]label["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fsy = fsy + last_height + 0.2
				last_height = 0.3
				fs[#fs + 1] = tostring(fsy)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = minetest.colorize("#000","Classroom Name: ")
				fs[#fs + 1] = minetest.colorize("#000",realm.Name)
				fs[#fs + 1] = "]style_type[label;font_size=*1,font=bold]label["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fsy = fsy + last_height + 0.2
				last_height = 0.3
				fs[#fs + 1] = tostring(fsy)
				fs[#fs + 1] = ";" ]]
				--[[ -- TODO: add area owner information
				fs[#fs + 1] = ";"
				fs[#fs + 1] = minetest.colorize("#000","Classroom Owner: "..)
				fs[#fs + 1] = "]style_type[label;font_size=*1,font=bold]label["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fsy = fsy + last_height + 0.2
				last_height = 0.3
				fs[#fs + 1] = tostring(fsy)
				fs[#fs + 1] = ";" ]]
				--[[ local privs = ""
				counter = 0
				for priv,v in pairs(realm.Permissions) do
					if v then privs = privs .. priv end
					if counter ~= #realm.Permissions then privs = privs .. ", " end
				end
				fs[#fs + 1] = minetest.colorize("#000","Privileges: ")
				fs[#fs + 1] = minetest.colorize("#000",privs)
				fs[#fs + 1] = "]style_type[label;font_size=*1,font=bold]label["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fsy = fsy + last_height + 0.2
				last_height = 0.3
				fs[#fs + 1] = tostring(fsy)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = minetest.colorize("#000","Status: You can join this classroom")
				fs[#fs + 1] = "]" ]]
				return fs
			end,
			["3"] = function() -- MAP
				local fs = {}
				if pmeta:get_string("default_student_tab") == "3" then
					fs[#fs + 1] = "style_type[label;font_size=*0.8;textcolor=#000]label[0.2,"
					fs[#fs + 1] = tostring(notebook_height-0.2)
					fs[#fs + 1] = ";This tab is the default]"
				else
					fs[#fs + 1] = "checkbox[0.2,"
					fs[#fs + 1] = tostring(notebook_height-0.2)
					fs[#fs + 1] = ";default_tab;"
					fs[#fs + 1] = minetest.colorize("#000","Bookmark?")
					fs[#fs + 1] = ";false]"
				end
				local yaw
				local rotate = 0
				yaw = player:get_look_horizontal()
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
				fs[#fs + 1] = "]style[note;textcolor=#000]textarea["
				fs[#fs + 1] = tostring(fsx)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(32*0.15+fsy+0.9)
				fs[#fs + 1] = ";"
				fs[#fs + 1] = tostring((notebook_width/8)*3.5)
				fs[#fs + 1] = ","
				fs[#fs + 1] = tostring(notebook_height/4)
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
			["4"] = function() -- PLAYERS ONLINE
				local fs = {}
				if pmeta:get_string("default_student_tab") == "4" then
					fs[#fs + 1] = "style_type[label;font_size=*0.8;textcolor=#000]label[0.2,"
					fs[#fs + 1] = tostring(notebook_height-0.2)
					fs[#fs + 1] = ";This tab is the default]"
				else
					fs[#fs + 1] = "checkbox[0.2,"
					fs[#fs + 1] = tostring(notebook_height-0.2)
					fs[#fs + 1] = ";default_tab;"
					fs[#fs + 1] = minetest.colorize("#000","Bookmark?")
					fs[#fs + 1] = ";false]"
				end
				local fsy = 0.65
				local fsx, ping_texture
				local fscount = 0
				local studentidx = 0
				local teacheridx = 0
				-- List Teachers first
				for teacher,_ in pairs(mc_teacher.teachers) do
					if teacher then
						teacheridx = teacheridx + 1
						local pinf = minetest.get_player_information(teacher)
						if pinf then
							local ping = pinf.avg_rtt / 2
							ping = math.floor(ping * 1000)
							if ping >= 0 and ping <= 49 then
								ping_texture = "[combine:10x8:0,0=ping.png"
							elseif ping >= 50 and ping <= 149 then
								ping_texture = "[combine:10x8:0,-8=ping.png"
							elseif ping >= 150 and ping <= 349 then
								ping_texture = "[combine:10x8:0,-16=ping.png"
							elseif ping >= 350 and ping <= 749 then
								ping_texture = "[combine:10x8:0,-24=ping.png"
							elseif ping >= 750 then
								ping_texture = "[combine:10x8:0,-32=ping.png"
							end
						else
							ping_texture = "[combine:10x8:0,-40=ping.png"
						end
						fscount = fscount + 1
						if fscount < 15 then fsx = 1.1 end
						if fscount == 1 then 
							fs[#fs + 1] = "style_type[label;font_size=*1,font=bold]label["
							fs[#fs + 1] = tostring(fsx)
							fs[#fs + 1] = ","
							fs[#fs + 1] = tostring(fsy)
							fs[#fs + 1] = ";"
							fs[#fs + 1] = minetest.colorize("#000","Teachers Online")
							fs[#fs + 1] = "]"
							fsy = fsy + 0.25
							fscount = fscount + 1
							teacheridx = teacheridx + 1
						end
						if fscount == 15 then
							fsx = notebook_width/2 + 1.1
							fsy = 0.9
						end
						if fscount < 28 then
							fs[#fs + 1] = "image["
							fs[#fs + 1] = tostring(fsx)
							fs[#fs + 1] = ","
							fs[#fs + 1] = tostring(fsy)
							fs[#fs + 1] = ";0.454,0.568;"
							fs[#fs + 1] = ping_texture
							fs[#fs + 1] = "]style_type[label;font_size=*1,font=normal]label["
							fs[#fs + 1] = tostring(fsx+0.55)
							fs[#fs + 1] = ","
							fs[#fs + 1] = tostring(fsy+0.35)
							fs[#fs + 1] = ";"
							fs[#fs + 1] = minetest.colorize("#000", pname)
							fs[#fs + 1] = "]"
							fsy = fsy + 0.65
							teacheridx = teacheridx + 1
						end -- TODO: add pages to show more than 28 connected players
					end
				end

--[[ 				-- Below for testing offline
				local pingtable = {"0", "-8", "-16", "-24", "-32", "-40"}
				for i=1, 4 do
					teacheridx = teacheridx + 1
					local ping_texture = "[combine:10x8:0,"..pingtable[math.random(#pingtable)].."=ping.png"
					fscount = fscount + 1
					if fscount < 15 then fsx = 1.1 end
					if fscount == 15 then
						fsx = notebook_width/2 + 1.1
						fsy = 0.9
					end
					if fscount == 1 then
						fsy = fsy + 0.4
						fs[#fs + 1] = "label["
						fs[#fs + 1] = tostring(fsx)
						fs[#fs + 1] = ","
						fs[#fs + 1] = tostring(fsy)
						fs[#fs + 1] = ";"
						fs[#fs + 1] = minetest.colorize("#000","Teachers Online")
						fs[#fs + 1] = "]"
						fsy = fsy + 0.25
						fscount = fscount + 1
						first_student = false
					end
					if fscount < 28 then
						fs[#fs + 1] = "image["
						fs[#fs + 1] = tostring(fsx)
						fs[#fs + 1] = ","
						fs[#fs + 1] = tostring(fsy)
						fs[#fs + 1] = ";0.454,0.568;"
						fs[#fs + 1] = ping_texture
						fs[#fs + 1] = "]style_type[label;font=normal]label["
						fs[#fs + 1] = tostring(fsx+0.55)
						fs[#fs + 1] = ","
						fs[#fs + 1] = tostring(fsy+0.35)
						fs[#fs + 1] = ";"
						fs[#fs + 1] = minetest.colorize("#000", "Teacher "..tostring(i))
						fs[#fs + 1] = "]"
						fsy = fsy + 0.65
					end
				end
				for i=1, 28 do
					local ping_texture = "[combine:10x8:0,"..pingtable[math.random(#pingtable)].."=ping.png"
					fscount = fscount + 1
					if fscount < 15 then fsx = 1.1 end
					if fscount == 15 then
						fsx = notebook_width/2 + 1.1
						fsy = 0.9
					end
					if studentidx == 0 then
						fsy = fsy + 0.4
						fs[#fs + 1] = "style_type[label;font=bold]label["
						fs[#fs + 1] = tostring(fsx)
						fs[#fs + 1] = ","
						fs[#fs + 1] = tostring(fsy)
						fs[#fs + 1] = ";"
						fs[#fs + 1] = minetest.colorize("#000","Students Online")
						fs[#fs + 1] = "]"
						fsy = fsy + 0.25
						fscount = fscount + 1
						studentidx = studentidx + 1
					end
					if fscount < 28 then
						fs[#fs + 1] = "image["
						fs[#fs + 1] = tostring(fsx)
						fs[#fs + 1] = ","
						fs[#fs + 1] = tostring(fsy)
						fs[#fs + 1] = ";0.454,0.568;"
						fs[#fs + 1] = ping_texture
						fs[#fs + 1] = "]style_type[label;font=normal]label["
						fs[#fs + 1] = tostring(fsx+0.55)
						fs[#fs + 1] = ","
						fs[#fs + 1] = tostring(fsy+0.35)
						fs[#fs + 1] = ";"
						fs[#fs + 1] = minetest.colorize("#000", "Student "..tostring(i))
						fs[#fs + 1] = "]"
						fsy = fsy + 0.65
						studentidx = studentidx + 1
					end
				end ]]

				-- List Students second
				for student,_ in pairs(mc_student.students) do
					if student then
						local pinf = minetest.get_player_information(student)
						if pinf then
							local ping = pinf.avg_rtt / 2
							ping = math.floor(ping * 1000)
							if ping >= 0 and ping <= 49 then
								ping_texture = "[combine:10x8:0,0=ping.png"
							elseif ping >= 50 and ping <= 149 then
								ping_texture = "[combine:10x8:0,-8=ping.png"
							elseif ping >= 150 and ping <= 349 then
								ping_texture = "[combine:10x8:0,-16=ping.png"
							elseif ping >= 350 and ping <= 749 then
								ping_texture = "[combine:10x8:0,-24=ping.png"
							elseif ping >= 750 then
								ping_texture = "[combine:10x8:0,-32=ping.png"
							end
						else
							ping_texture = "[combine:10x8:0,-40=ping.png"
						end
						fscount = fscount + 1
						if fscount < 15 then fsx = 1.1 end
						if fscount == 15 then
							fsx = notebook_width/2 + 1.1
							fsy = 0.9
						end
						if studentidx == 0 then
							fsy = fsy + 0.4
							fs[#fs + 1] = "style_type[label;font_size=*1,font=bold]label["
							fs[#fs + 1] = tostring(fsx)
							fs[#fs + 1] = ","
							fs[#fs + 1] = tostring(fsy)
							fs[#fs + 1] = ";"
							fs[#fs + 1] = minetest.colorize("#000","Students Online")
							fs[#fs + 1] = "]"
							fsy = fsy + 0.25
							fscount = fscount + 1
							studentidx = studentidx + 1
						end
						if fscount < 28 then
							fs[#fs + 1] = "image["
							fs[#fs + 1] = tostring(fsx)
							fs[#fs + 1] = ","
							fs[#fs + 1] = tostring(fsy)
							fs[#fs + 1] = ";0.454,0.568;"
							fs[#fs + 1] = ping_texture
							fs[#fs + 1] = "]style_type[label;font_size=*1,font=normal]label["
							fs[#fs + 1] = tostring(fsx+0.55)
							fs[#fs + 1] = ","
							fs[#fs + 1] = tostring(fsy+0.35)
							fs[#fs + 1] = ";"
							fs[#fs + 1] = minetest.colorize("#000", student)
							fs[#fs + 1] = "]"
							fsy = fsy + 0.65
							studentidx = studentidx + 1
						end -- TODO: add pages to show more than 28 connected players
					end
				end
				return fs
			end,
			["5"] = function() -- APPEARANCE
				local fs = {}
				if pmeta:get_string("default_student_tab") == "5" then
					fs[#fs + 1] = "style_type[label;font_size=*0.8;textcolor=#000]label[0.2,"
					fs[#fs + 1] = tostring(notebook_height-0.2)
					fs[#fs + 1] = ";This tab is the default]"
				else
					fs[#fs + 1] = "checkbox[0.2,"
					fs[#fs + 1] = tostring(notebook_height-0.2)
					fs[#fs + 1] = ";default_tab;"
					fs[#fs + 1] = minetest.colorize("#000","Bookmark?")
					fs[#fs + 1] = ";false]"
				end
				fs[#fs + 1] = "style_type[textarea;font=mono,bold;textcolor=black]"
				fs[#fs + 1] = "textarea[0.55,0.5;7.1,1;;;Coming Soon]"
				return fs
			end,
			["6"] = function() -- RULES AND HELP
				local fs, mapar, fsx, fsy
				local fs = {}
				if pmeta:get_string("default_student_tab") == "6" then
					fs[#fs + 1] = "style_type[label;font_size=*0.8;textcolor=#000]label[0.2,"
					fs[#fs + 1] = tostring(notebook_height-0.2)
					fs[#fs + 1] = ";This tab is the default]"
				else
					fs[#fs + 1] = "checkbox[0.2,"
					fs[#fs + 1] = tostring(notebook_height-0.2)
					fs[#fs + 1] = ";default_tab;"
					fs[#fs + 1] = minetest.colorize("#000","Bookmark?")
					fs[#fs + 1] = ";false]"
				end
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
		table.insert(student_formtable, table.concat(tab_map[tab or pmeta:get_string("default_student_tab") or mc_student.fs_context.tab or "1"](), ""))
		minetest.show_formspec(pname, "mc_student:notebook_fs", table.concat(student_formtable, ""))
		return true
	end
end