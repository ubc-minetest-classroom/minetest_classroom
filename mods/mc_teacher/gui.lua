function mc_teacher.show_controller_fs(player,tab)
	local controller_width = 16.4
	local controller_height = 10.2
    local pname = player:get_player_name()
	local pmeta = player:get_meta()
	if mc_helpers.checkPrivs(player) then
		local teacher_formtable = {
			"formspec_version[6]",
			"size[",
			tostring(controller_width),
			",",
			tostring(controller_height),
			"]",
			mc_core.draw_book_fs(controller_width, controller_height, {bg = "#63406a", shadow = "#3e2b45", binding = "#5d345e", divider = "#d9d9d9"}),
			"style[tabheader;noclip=true]",
		}
        if mc_helpers.checkPrivs(player,{server = true}) then
            teacher_formtable[#teacher_formtable + 1] = "tabheader[0,-0.25;16,0.55;record_nav;Overview,Manage Classrooms,Manage Players,Manage Reports,Manage Server;" 
            teacher_formtable[#teacher_formtable + 1] = tab or pmeta:get_string("default_teacher_tab") or mc_teacher.fs_context.tab or "1"
            teacher_formtable[#teacher_formtable + 1] = ";true;false]"
        else
            teacher_formtable[#teacher_formtable + 1] = "tabheader[0,-0.25;16,0.55;record_nav;Overview,Manage Classrooms,Manage Players,Manage Reports;" 
            teacher_formtable[#teacher_formtable + 1] = tab or pmeta:get_string("default_teacher_tab") or mc_teacher.fs_context.tab or "1"
            teacher_formtable[#teacher_formtable + 1] = ";true;false]"
        end
		local tab_map = {
			["1"] = function() -- OVERVIEW
				local fs = {}
				if pmeta:get_string("default_teacher_tab") == "1" then
					fs[#fs + 1] = "style_type[label;font_size=*0.8;textcolor=#000]label[0.2,"
					fs[#fs + 1] = tostring(controller_height-0.2)
					fs[#fs + 1] = ";This tab is the default]"
				else
					fs[#fs + 1] = "checkbox[0.2,"
					fs[#fs + 1] = tostring(controller_height-0.2)
					fs[#fs + 1] = ";default_tab;"
					fs[#fs + 1] = minetest.colorize("#000","Bookmark?")
					fs[#fs + 1] = ";false]"
				end
				return fs
			end,
			["2"] = function() -- CLASSROOMS
				local fs = {}
				if pmeta:get_string("default_teacher_tab") == "2" then
					fs[#fs + 1] = "style_type[label;font_size=*0.8;textcolor=#000]label[0.2,"
					fs[#fs + 1] = tostring(controller_height-0.2)
					fs[#fs + 1] = ";This tab is the default]"
				else
					fs[#fs + 1] = "checkbox[0.2,"
					fs[#fs + 1] = tostring(controller_height-0.2)
					fs[#fs + 1] = ";default_tab;"
					fs[#fs + 1] = minetest.colorize("#000","Bookmark?")
					fs[#fs + 1] = ";false]"
				end
				return fs
			end,
			["3"] = function() -- PLAYERS
                local fs = {}
				if pmeta:get_string("default_teacher_tab") == "4" then
					fs[#fs + 1] = "style_type[label;font_size=*0.8;textcolor=#000]label[0.2,"
					fs[#fs + 1] = tostring(controller_height-0.2)
					fs[#fs + 1] = ";This tab is the default]"
				else
					fs[#fs + 1] = "checkbox[0.2,"
					fs[#fs + 1] = tostring(controller_height-0.2)
					fs[#fs + 1] = ";default_tab;"
					fs[#fs + 1] = minetest.colorize("#000","Bookmark?")
					fs[#fs + 1] = ";false]"
				end
				return fs
			end,
			["4"] = function() -- REPORTS
                local fs = {}
				if pmeta:get_string("default_teacher_tab") == "3" then
					fs[#fs + 1] = "style_type[label;font_size=*0.8;textcolor=#000]label[0.2,"
					fs[#fs + 1] = tostring(controller_height-0.2)
					fs[#fs + 1] = ";This tab is the default]"
				else
					fs[#fs + 1] = "checkbox[0.2,"
					fs[#fs + 1] = tostring(controller_height-0.2)
					fs[#fs + 1] = ";default_tab;"
					fs[#fs + 1] = minetest.colorize("#000","Bookmark?")
					fs[#fs + 1] = ";false]"
				end
				return fs
			end,
			["5"] = function() -- SERVER
                local fsx, fsy
				local fs = {}
				if pmeta:get_string("default_teacher_tab") == "5" then
					fs[#fs + 1] = "style_type[label;font_size=*0.8;textcolor=#000]label[0.2,"
					fs[#fs + 1] = tostring(controller_height-0.2)
					fs[#fs + 1] = ";This tab is the default]"
				else
					fs[#fs + 1] = "checkbox[0.2,"
					fs[#fs + 1] = tostring(controller_height-0.2)
					fs[#fs + 1] = ";default_tab;"
					fs[#fs + 1] = minetest.colorize("#000","Bookmark?")
					fs[#fs + 1] = ";false]"
				end
                fs[#fs + 1] = "field[1,0.85;"
                fs[#fs + 1] = tostring(((controller_width/8)*3.5)-1.6)
                fs[#fs + 1] = ",0.8;servermessage;"
                fs[#fs + 1] = minetest.colorize("#000","Send Message to All Connected Players")
                fs[#fs + 1] = ";]button["
                fs[#fs + 1] = tostring((controller_width/2)-1.4)
                fs[#fs + 1] = ",0.85;1.4,0.8;submitmessage;Send]style_type[label;font_size=*1;textcolor=#000]label[1,2;"
                fs[#fs + 1] = minetest.colorize("#000","Schedule Server Restart")
                fs[#fs + 1] = "]dropdown[1,2.2;3,0.8;time;1 minute,5 minutes,10 minutes,15 minutes,30 minutes,1 hour,6 hours,12 hours,24 hours;1;false]"
                fs[#fs + 1] = "button[4.2,2.2;3,0.8;submitsched;Schedule Restart]"
                fs[#fs + 1] = "button_exit[1,3.2;3,0.8;submitshutdown;Shutdown Now]"


                -- Rules


                -- Networking
                fsx = ((controller_width/2)-(((controller_width/8)*3)))/2
                fsy = 1
				fs[#fs + 1] = "style_type[label;font_size=*1.2]label["
				fs[#fs + 1] = tostring(controller_width/2+1.6)
				fs[#fs + 1] = ",0.4;"
				fs[#fs + 1] = minetest.colorize("#000","White-Listed IPv4 Addresses")
				fs[#fs + 1] = "]textlist["
				fs[#fs + 1] = tostring(fsx+(controller_width/2))
				fs[#fs + 1] = ",1.1;"
				fs[#fs + 1] = tostring((controller_width/8)*3.5)
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
				
				
--[[ 				-- Check if any coordinates are available, otherwise suppress buttons
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
									fs[#fs + 1] = tostring(fsx+(controller_width/2))
									fs[#fs + 1] = ","
									fs[#fs + 1] = tostring(32*0.15+fsy+(controller_height/4)+0.9)
									fs[#fs + 1] = ";"
									fs[#fs + 1] = tostring(((controller_width/2)-(fsx*2))/3)
									fs[#fs + 1] = ",0.6;go;Go]button["
									fs[#fs + 1] = tostring(fsx+(controller_width/2))
									fs[#fs + 1] = ","
									fs[#fs + 1] = tostring((controller_height/3)+1.1)
									fs[#fs + 1] = ";1.7,0.6;delete;Delete]button["
									fs[#fs + 1] = tostring(controller_width/2+1.1+1.7+0.2)
									fs[#fs + 1] = ","
									fs[#fs + 1] = tostring((controller_height/3)+1.1)
									fs[#fs + 1] = ";1.7,0.6;clear;Clear All]"
									if mc_core.checkPrivs(player, {shout = true}) then
										fs[#fs + 1] = "button["
										fs[#fs + 1] = tostring(fsx+(controller_width/2)+(((controller_width/2)-(fsx*2))/3)+0.2)
										fs[#fs + 1] = ","
										fs[#fs + 1] = tostring(32*0.15+fsy+(controller_height/4)+0.9)
										fs[#fs + 1] = ";"
										fs[#fs + 1] = tostring(((controller_width/2)-(fsx*2))/3)
										fs[#fs + 1] = ",0.6;share;Share in Chat]button["
										fs[#fs + 1] = tostring(fsx+(controller_width/2)+(((controller_width/2)-(fsx*2))/3)+0.2+(((controller_width/2)-(fsx*2))/3)+0.2)
										fs[#fs + 1] = ","
										fs[#fs + 1] = tostring(32*0.15+fsy+(controller_height/4)+0.9)
										fs[#fs + 1] = ";"
										fs[#fs + 1] = tostring(((controller_width/2)-(fsx*2))/3)
										fs[#fs + 1] = ",0.6;mark;Place Marker]"
									end
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
				end ]]
            

                -- Manage Bans
				return fs
			end,
		}
		table.insert(teacher_formtable, table.concat(tab_map[tab or pmeta:get_string("default_teacher_tab") or mc_teacher.fs_context.tab or "1"](), ""))
		minetest.show_formspec(pname, "mc_teacher:controller_fs", table.concat(teacher_formtable, ""))
		return true
	end
end