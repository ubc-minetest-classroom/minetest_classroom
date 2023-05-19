--- Returns a list of classrooms that the given player can join
local function get_fs_classroom_list(player)
	local list = {}
	Realm.ScanForPlayerRealms()

	for _,realm in pairs(Realm.realmDict) do
        local playerCount = tonumber(realm:GetPlayerCount())
        table.insert(list, table.concat({
            realm.Name, " (", playerCount, " player", playerCount == 1 and "" or "s", ")"
        }))
	end
	return table.concat(list, ",")
end

function mc_teacher.show_controller_fs(player,tab)
	local controller_width = 16.4
	local controller_height = 10.2
    local page_width = (controller_width/8)*3.5
    local pname = player:get_player_name()
	local pmeta = player:get_meta()
	local context = mc_teacher.get_fs_context(player)

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

                local Y_SIZE, FACTOR = 9.7, 0.05
				local fs = {
					"image[0,0;16.4,0.5;mc_pixel.png^[multiply:#737373]",
					"image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
					"tooltip[exit;Exit]",
					"hypertext[0.55,0.1;7.1,1;;<style font=mono><center><b>Overview</b></center></style>]",
					"hypertext[8.75,0.1;7.1,1;;<style font=mono><center><b>Dashboard</b></center></style>]",

					"style_type[textarea;font=mono,bold;textcolor=#000000]",
					"textarea[0.55,1;7.1,1;;;Welcome to Minetest Classroom!]",
					"textarea[0.55,4.4;7.1,1;;;Server Rules]",
					"style_type[textarea;font=mono]",
					"textarea[0.55,1.5;7.1,2.6;;;", minetest.formspec_escape("This is the Teacher Controller, your tool for managing classrooms, player privileges, and server settings."),
					"\n", minetest.formspec_escape("You cannot drop this tool, so you will never lose it. However, you can move it out of your hotbar and into your inventory or the toolbox."), "]",
					"textarea[0.55,4.9;7.1,", has_server_privs and 3.8 or 4.7, ";;;", minetest.formspec_escape(rules), "]",
                    has_server_privs and "button[0.6,8.8;7,0.8;modifyrules;Edit Server Rules]" or "",

                    "scrollbaroptions[min=0;max=", (11.45 + (has_server_privs and 1.65 or 0) - Y_SIZE)/FACTOR, ";smallstep=", 0.8/FACTOR, ";largestep=", 4.8/FACTOR, ";thumbsize=", 1/FACTOR, "]",
                    "scrollbar[16.1,0.5;0.3,", Y_SIZE, ";vertical;overviewscroll;", context.overviewscroll or 0, "]",
                    "scroll_container[8.2,0.5;7.9,", Y_SIZE, ";overviewscroll;vertical;", FACTOR, "]",

					"image_button[0.6,0.5;", button_width, ",", button_height, ";mc_teacher_classrooms.png;classrooms;;false;false]",
                    "hypertext[2.4,0.8;5.25,1.6;;<style color=#000000><b>Classrooms</b>\n", minetest.formspec_escape("Create and manage classrooms"), "</style>]",
					"image_button[0.6,2.25;", button_width, ",", button_height, ";mc_teacher_map.png;map;;false;false]",
					"hypertext[2.4,2.55;5.25,1.6;;<style color=#000000><b>Map</b>\n", minetest.formspec_escape("Record and share locations"), "</style>]",
                    "image_button[0.6,4;", button_width, ",", button_height, ";mc_teacher_players.png;players;;false;false]",
                    "hypertext[2.4,4.3;5.25,1.6;;<style color=#000000><b>Players</b>\n", minetest.formspec_escape("Manage player privileges"), "</style>]",
					"image_button[0.6,5.75;", button_width, ",", button_height, ";mc_teacher_isometric_crop.png;moderation;;false;false]",
                    "hypertext[2.4,6.05;5.25,1.6;;<style color=#000000><b>Moderation</b>\n", minetest.formspec_escape("View player chat logs"), "</style>]",
                    "image_button[0.6,7.5;", button_width, ",", button_height, ";mc_teacher_isometric_crop.png;reports;;false;false]",
					"hypertext[2.4,7.8;5.25,1.6;;<style color=#000000><b>Reports</b>\n", minetest.formspec_escape("View and resolve player reports"), "</style>]",
                    "image_button[0.6,9.25;", button_width, ",", button_height, ";mc_teacher_help.png;help;;false;false]",
                    "hypertext[2.4,9.55;5.25,1.6;;<style color=#000000><b>Help</b>\n", minetest.formspec_escape("View guides and resources"), "</style>]",
                }

                if has_server_privs then
                    table.insert(fs, table.concat({
                        "image_button[0.6,11;", button_width, ",", button_height, ";mc_teacher_isometric_crop.png;server;;false;false]",
                        "hypertext[2.4,11.3;5.25,1.6;;<style color=#000000><b>Server</b>\n", minetest.formspec_escape("Manage server settings"), "</style>]",
                    }))
                end
                table.insert(fs, "scroll_container_end[]")

				return fs
			end,
			["2"] = function() -- CLASSROOMS
                local fs = {
                    "image[0,0;16.4,0.5;mc_pixel.png^[multiply:#737373]",
					"image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
					"tooltip[exit;Exit]",
					"hypertext[0.55,0.1;7.1,1;;<style font=mono><center><b>Classrooms</b></center></style>]",
					"hypertext[8.75,0.1;7.1,1;;<style font=mono><center><b>Build a Classroom</b></center></style>]",

                    "style_type[textarea;font=mono,bold;textcolor=#000000]",
                    "style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:#1e1e1e]",
                    "textarea[0.55,1;7.1,1;;;Available Classrooms]",
                    "textlist[0.6,1.5;7,7.2;classroomlist;", get_fs_classroom_list(player), ";", context.selected_realm_id or 1, ";false]",
                    "button[0.6,8.8;1.675,0.8;teleportrealm;Go]",
                    "button[4.15,8.8;1.675,0.8;deleterealm;Delete]",
                    "button[2.375,8.8;1.675,0.8;editrealm;Edit]",
                    "button[5.925,8.8;1.7,0.8;resetrealm;Reset]",

                    "style_type[field;font=mono;textcolor=#000000]",
                    "textarea[8.75,1;7.1,1;;;Name]",
                    "field[8.8,1.45;7,0.7;realmname;;]",
                    "textarea[8.75,2.2;3.5,1;;;Type]",
                    "dropdown[8.8,2.65;3.45,0.7;realmcategory;Default,Spawn,Classroom,Instanced;", context.selected_realm_type or 1, ";true]",
                    "textarea[12.3,2.2;3.5,1;;;Generation]",
                    "dropdown[12.35,2.65;3.45,0.7;mode;Empty World,Schematic,Digital Twin;", context.selected_mode or 1, ";true]",
                }

                if context.selected_mode == mc_teacher.MODES.EMPTY then
                    table.insert(fs, table.concat({
                        "textarea[8.75,3.4;7.1,1;;;Classroom Size]",
                        "textarea[8.75,4;1,1;;;X =]",
                        "textarea[11.15,4;1,1;;;Y =]",
                        "textarea[13.55,4;1,1;;;Z =]",
                        "field[9.6,3.85;1.4,0.7;realm_x_size;;25]",
                        "field[12,3.85;1.4,0.7;realm_y_size;;25]",
                        "field[14.4,3.85;1.4,0.7;realm_z_size;;25]",
                    }))
                elseif context.selected_mode == mc_teacher.MODES.SCHEMATIC then
                    table.insert(fs, table.concat({
                        "textarea[8.75,3.4;7.1,1;;;Schematic]",
                        "dropdown[8.8,3.85;7,0.7;schematic;;", context.selected_schematic_index or 1, ";true]",
                    }))
                elseif context.selected_mode == mc_teacher.MODES.TWIN then
                    table.insert(fs, table.concat({
                        "textarea[8.75,3.4;7.1,1;;;Digital Twin World]",
                        "dropdown[8.8,3.85;7,0.7;realterrain;;", context.selected_dem_index or 1, ";true]",
                    }))
                else
                    table.insert(fs, table.concat({
                        "textarea[8.75,3.4;7.1,1.2;;;Select a generation mode for more options!]",
                    }))
                end
                    
                table.insert(fs, table.concat({
                    "textarea[8.75,4.7;7.1,1;;;Default Privileges]",
                    "style_type[textarea;font=mono]",
                    "textarea[9.25,5.15;1.8,1;;;interact]",
                    "textarea[9.25,5.55;1.8,1;;;shout]",
                    "textarea[11.65,5.15;1.8,1;;;fast]",
                    "textarea[11.65,5.55;1.8,1;;;fly]",
                    "textarea[14.05,5.15;1.8,1;;;noclip]",
                    "textarea[14.05,5.55;1.8,1;;;give]",
                    "checkbox[8.8,5.35;priv_interact;;false]",
                    "checkbox[8.8,5.75;priv_shout;;false]",
                    "checkbox[11.2,5.35;priv_fast;;false]",
                    "checkbox[11.2,5.75;priv_fly;;false]",
                    "checkbox[13.6,5.35;priv_noclip;;false]",
                    "checkbox[13.6,5.75;priv_give;;false]",
                    "style_type[textarea;font=mono,bold]",
                    "textarea[8.75,6;7.1,1;;;Background Music]",
                    "dropdown[8.8,6.45;7,0.7;bgmusic;;1;false]",
                    "textarea[8.75,7.2;7.1,1;;;Skybox]",
                    "dropdown[8.8,7.65;7,0.7;;;1;false]",
                    "button[8.8,8.8;7,0.8;requestrealm;Generate Classroom]",
                }))

                return fs

				--[[ SAVED POPULATION CODE FROM OLD FORMSPEC

                    for _ in pairs(schematicManager.schematics) do count = count + 1 end
                    for name, path in pairs(schematicManager.schematics) do
                        counter = counter + 1
                        fs[#fs + 1] = name
                        if counter ~= count then fs[#fs + 1] = "," end
                    end

                    fs[#fs + 1] = ";realterrain;Select a Digital Twin,"
                    -- iterate through registered DEMs
                    local count, counter = 0, 0
                    for _ in pairs(realterrainManager.dems) do count = count + 1 end
                    for name, path in pairs(realterrainManager.dems) do
                        counter = counter + 1
                        fs[#fs + 1] = name
                        if counter ~= count then fs[#fs + 1] = "," end
                    end
                    fs[#fs + 1] = ";"
                
                -- World Gen

                -- Colorbrewer an symbology options

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
				return {}
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

		local teacher_formtable = {
			"formspec_version[6]",
			"size[", controller_width, ",", controller_height, "]",
			mc_core.draw_book_fs(controller_width, controller_height, {bg = "#404040", shadow = "#303030", binding = "#333333", divider = "#969696"}),
			"style[tabheader;noclip=true]",
			"tabheader[0,-0.25;16,0.55;record_nav;Overview,Classrooms,Map,Players,Moderation,Reports,Help",
            has_server_privs and ",Server" or "", ";", selected_tab, ";true;false]",
			table.concat(tab_map[selected_tab](), "")
		}

		if bookmarked_tab == selected_tab then
			table.insert(teacher_formtable, table.concat({
				"style_type[image;noclip=true]",
				"image[15.8,-0.25;0.5,0.7;mc_teacher_bookmark_filled.png]",
				"tooltip[15.8,-0.25;0.5,0.8;This tab is currently bookmarked]",
			}))
		else
			table.insert(teacher_formtable, table.concat({
				"image_button[15.8,-0.25;0.5,0.5;mc_teacher_bookmark_hollow.png^[colorize:#FFFFFF:127;default_tab;;true;false]",
				"tooltip[default_tab;Bookmark this tab?]",
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
size[16.4,10.2]
box[0,0;16.4,0.5;#737373]
box[8.195,0;0.05,10.2;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.1,1;;;Overview]
textarea[8.75,0.1;7.1,1;;;Dashboard]
textarea[0.55,1;7.1,1;;;Welcome to Minetest Classroom!]
textarea[0.55,1.5;7.1,2.8;;;This is the Teacher Controller\, your tool for managing classrooms\, player privileges\, and server settings. You cannot drop or delete this tool\, so you will never lose it\, but you can move it out of your hotbar and into your inventory or the toolbox.]
textarea[0.55,4.4;7.1,1;;;Server Rules]
textarea[0.55,4.9;7.1,3.8;;;These are the server rules!]
button[0.6,8.8;7,0.8;modifyrules;Edit Server Rules]
image_button[8.8,1;1.7,1.6;mc_teacher_classrooms.png;classrooms;;false;false]
image_button[8.8,2.75;1.7,1.6;mc_teacher_map.png;map;;false;false]
image_button[8.8,4.5;1.7,1.6;mc_teacher_players.png;players;;false;false]
image_button[8.8,6.25;1.7,1.6;mc_teacher_isometric.png;help;;false;false]
image_button[8.8,8;1.7,1.6;mc_teacher_isometric.png;help;;false;false]
textarea[10.6,1.3;5.25,1.6;;;ClassroomsnFind classrooms or players]
textarea[10.6,3.05;5.25,1.6;;;MapnRecord and share locations]
textarea[10.6,4.8;5.25,1.6;;;PlayersnManage player privileges]
textarea[10.6,6.55;5.25,1.6;;;ModerationnView player chat logs]
textarea[10.6,8.3;5.25,1.6;;;ReportsnView player reports]
image[15.8,-0.25;0.5,0.8;mc_teacher_bookmark.png]

CLASSROOMS:
formspec_version[6]
size[16.4,10.2]
box[0,0;16.4,0.5;#737373]
box[8.195,0;0.05,10.2;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.1,1;;;Classrooms]
textarea[8.75,0.1;7.1,1;;;Build a Classroom]
textarea[0.55,1;7.1,1;;;Available Classrooms]
textlist[0.6,1.5;7,7.2;classroomlist;;1;false]
button[0.6,8.8;1.675,0.8;teleportrealm;Go]
button[4.15,8.8;1.675,0.8;deleterealm;Delete]
button[2.375,8.8;1.675,0.8;editrealm;Edit]
button[5.925,8.8;1.7,0.8;resetrealm;Reset]
textarea[8.75,1;7.1,1;;;Name]
field[8.8,1.45;7,0.7;realmname;;]
textarea[8.75,2.2;3.5,1;;;Type]
dropdown[8.8,2.65;3.45,0.7;realmcategory;Default,Spawn,Classroom,Instanced;1;true]
textarea[12.3,2.2;3.5,1;;;Generation]
dropdown[12.35,2.65;3.45,0.7;mode;Empty World,Schematic,Digital Twin;1;true]
textarea[8.75,3.4;7.1,1;;;OPTIONS]
dropdown[8.8,3.85;7,0.7;;;1;true]
textarea[8.75,4.7;7.1,1;;;Default Privileges]
textarea[9.25,5.15;1.8,1;;;interact]
textarea[9.25,5.55;1.8,1;;;shout]
textarea[11.65,5.15;1.8,1;;;fast]
textarea[11.65,5.55;1.8,1;;;fly]
textarea[14.05,5.15;1.8,1;;;noclip]
textarea[14.05,5.55;1.8,1;;;give]
checkbox[8.8,5.35;priv_interact;;false]
checkbox[8.8,5.75;priv_shout;;false]
checkbox[11.2,5.35;priv_fast;;false]
checkbox[11.2,5.75;priv_fly;;false]
checkbox[13.6,5.35;priv_noclip;;false]
checkbox[13.6,5.75;priv_give;;false]
textarea[8.75,6;7.1,1;;;Background Music]
dropdown[8.8,6.45;7,0.7;bgmusic;;1;true]
textarea[8.75,7.2;7.1,1;;;Skybox]
dropdown[8.8,7.65;7,0.7;;;1;true]
button[8.8,8.8;7,0.8;requestrealm;Generate Classroom]
textarea[9.25,5.1;1.8,1;;;interact]
textarea[9.25,5.5;1.8,1;;;shout]
textarea[11.65,5.1;1.8,1;;;fast]
textarea[11.65,5.5;1.8,1;;;fly]
textarea[14.05,5.1;1.8,1;;;noclip]
textarea[14.05,5.5;1.8,1;;;give]
]]
