-- TODO:
----- refactor mod/table name to prevent potential mod naming conflicts
----- add tutorial progress and completion to player meta
----- get/set pdata.tutorials.activeTutorial from player meta
----- make tutorials dependent on other tutorials (sequence of tutorials)
----- update png texture for tutorialbook - consider revising this to a new icon different from student notebook
----- add sequence of formspecs or HUD elements to guide teacher through recording different gameplay options
----- make tutorial_fs dynamic to show what a player will get on_complettion: use add item_image[]
----- need a way for the player to access the pdata.tutorials.activeTutorial instructions and possibly accompanying item_images and models
----- update the record_fs menu so that on_completion items and tools are displayed in an inventory and the number of items given can be set by the palyer recording the tutorial
----- add option to display a message after completing a specific action, like "now do this next"\
----- fix tutorial wield/key listener

tutorial = {
    path = minetest.get_modpath("tutorial"),
    tutorials = minetest.get_mod_storage(),
    record = {
        active = {},
        temp = {},
        edit = {},
        listener = {
            wield = {},
            key = {}
        }
    }
}

-- Store and load default settings in the tutorial_settings.conf file
local settings = Settings(tutorial.path .. "/tutorial_settings.conf")
function tutorial.fetch_setting(name)
    local sname = "tutorial." .. name
    return settings and settings:get(sname) or minetest.settings:get(sname)
end
function tutorial.fetch_setting_table(name)
    local setting_string = tutorial.fetch_setting(name)
    local table = mc_helpers.split(setting_string, ",")
    for i,v in ipairs(table) do
        table[i] = v:trim()
    end
    return table
end
function tutorial.fetch_setting_privtable(name)
    local output = {}
    for _,priv in pairs(tutorial.fetch_setting_table(name) or {}) do
        output[priv] = true
    end
    return output
end

tutorial.player_priv_table = tutorial.fetch_setting_privtable("player_priv_table") or {interact = true}
tutorial.recorder_priv_table = tutorial.fetch_setting_privtable("recorder_priv_table") or {teacher = true, interact = true}
tutorial.check_interval = tutorial.fetch_setting("check_interval") or 1
tutorial.check_dir_tolerance = tutorial.fetch_setting("check_dir_tolerance") or 0.01745
tutorial.check_pos_x_tolerance = tonumber(tutorial.fetch_setting("check_pos_x_tolerance") or 4) * tutorial.check_interval
tutorial.check_pos_y_tolerance = tonumber(tutorial.fetch_setting("check_pos_y_tolerance") or 4) * tutorial.check_interval
tutorial.check_pos_z_tolerance = tonumber(tutorial.fetch_setting("check_pos_z_tolerance") or 4) * tutorial.check_interval

-- Load other scripts
dofile(tutorial.path .. "/functions.lua")
dofile(tutorial.path .. "/tools.lua")
dofile(tutorial.path .. "/callbacks.lua")

minetest.register_on_joinplayer(function(player)
    -- Load player meta
    pmeta = player:get_meta()
    pdata = minetest.deserialize(pmeta:get_string("tutorial:tutorials"))
    if pdata == nil or next(pdata) == nil then
        -- Nothing to see here so initialize and serialize a table to hold everything
        pdata = {
            tutorials = {
                activeTutorial = {},
                playerSequence = {},
                completedTutorials = {}, -- TODO: use this to change the tutorial_fs to indicate tutorials that are completed
                weildedThingListener = false,
                keyStrikeListener = false,
            }
        }
        pmeta:set_string("tutorial:tutorials", minetest.serialize(pdata))
    end

    --[[
    -- When a player joins, check if they have the correct priv and then give the tutorialbook and/or the recording tool
	local inv = player:get_inventory()
	-- tutorialbook
    if inv:contains_item("main", ItemStack("tutorial:tutorialbook")) then
		if tutorial.checkPrivs(player,tutorial.player_priv_table) then
			return
		else
			inv:remove_item('main', 'tutorial:tutorialbook')
		end
	else
		if tutorial.checkPrivs(player,tutorial.player_priv_table) then
			inv:add_item('main', 'tutorial:tutorialbook')
		else
			return
		end
	end
    -- recording_tool
    if inv:contains_item("main", ItemStack("tutorial:recording_tool")) then
		if tutorial.checkPrivs(player,tutorial.recorder_priv_table) then
			return
		else
			inv:remove_item('main', 'tutorial:recording_tool')
		end
	else
		if tutorial.checkPrivs(player,tutorial.recorder_priv_table) then
			inv:add_item('main', 'tutorial:recording_tool')
		else
			return
		end
	end]]
end)

function tutorial.show_record_fs(player)
    local pname = player:get_player_name()
	if tutorial.checkPrivs(player,tutorial.recorder_priv_table) then
        -- Tutorial formspec for recording a tutorial
        record_fs = {
            "formspec_version[5]",
            "size[12,12]",
            "label[2,7.5;What happens when a player completes the tutorial?]",
            "label[0.3,9.6;Give a tool]",
            "label[4.1,9.6;Give an item]",
            "label[9.1,9.5;Grant a privilege]",
            "button_exit[8,10.9;2.5,0.8;finish;Finish]",
            "label[0.5,3.9;The sequence of events that you recorded]"
        }

        -- If there is at least one other tutorial recorded, then present the option to modify dependencies
        local tutorials = minetest.deserialize(tutorial.tutorials:get_string("tutorial:tutorials"))
        if tutorials ~= nil and next(tutorials) ~= nil then
            record_fs[#record_fs + 1] = "button_exit[1.1,10.9;5.8,0.8;dependence;Select Tutorial Dependencies]"
            record_fs[#record_fs + 1] = "label[7.2,11.3;OR]" 
        end

        -- If the tutorial has already been registered then populate the fields with the values
        if tutorial.record.temp[pname].title then 
            record_fs[#record_fs + 1] = "field[0.5,0.7;11,0.8;title;Title;"..tutorial.record.temp[pname].title.."]"
        else
            record_fs[#record_fs + 1] = "field[0.5,0.7;11,0.8;title;Title;]"
        end
        if tutorial.record.temp[pname].on_completion.message then 
            record_fs[#record_fs + 1] = "field[0.4,8.4;11.1,0.7;message;Message;"..tutorial.record.temp[pname].on_completion.message.."]"
        else
            record_fs[#record_fs + 1] = "field[0.4,8.4;11.1,0.7;message;Message;]"
        end

        if tutorial.record.temp[pname].itemImages then
            -- TODO: handle item images
        else
            if tutorial.record.temp[pname].description then 
                record_fs[#record_fs + 1] = "field[0.5,2;11,1.5;description;Description;"..tutorial.record.temp[pname].description.."]"
            else
                record_fs[#record_fs + 1] = "field[0.5,2;11,1.5;description;Description;]"
            end
        end

        -- Add all registered tools to textlist
        record_fs[#record_fs + 1] = "textlist[0.3,9.8;3.7,0.8;givetool;None,"
        tutorial.selected_tool = tutorial.selected_tool or 1
        tools = {}
        for k,v in pairs(minetest.registered_items) do if v.type == "tool" then table.insert(tools,k) end end
        table.sort(tools)
        for i,itemstring in ipairs(tools) do 
            record_fs[#record_fs + 1] = itemstring
            record_fs[#record_fs + 1] = "," 
        end
        record_fs[#record_fs] = ""
        record_fs[#record_fs + 1] = ";"..tostring(tutorial.selected_tool)..";true]"

        -- Add all registered non-tool items to textlist
        record_fs[#record_fs + 1] = "textlist[4.1,9.8;4.9,0.8;giveitem;None,"
        tutorial.selected_item = tutorial.selected_item or 1
        items = {}
        for k,v in pairs(minetest.registered_items) do if v.type ~= "tool" and k ~= "" then table.insert(items,k) end end
        table.sort(items)
        for i,itemstring in ipairs(items) do 
            record_fs[#record_fs + 1] = itemstring 
            record_fs[#record_fs + 1] = "," 
        end
        record_fs[#record_fs] = ""
        record_fs[#record_fs + 1] = ";"..tostring(tutorial.selected_item)..";true]"

        -- Add all registered privileges to textlist
        record_fs[#record_fs + 1] = "textlist[9.1,9.8;2.5,0.8;grantpriv;None,"
        tutorial.selected_priv = tutorial.selected_priv or 1
        privs = {}
        for k,v in pairs(minetest.registered_privileges) do table.insert(privs,k) end
        table.sort(privs)
        for i,privv in ipairs(privs) do 
            record_fs[#record_fs + 1] = privv 
            record_fs[#record_fs + 1] = "," 
        end
        record_fs[#record_fs] = ""
        record_fs[#record_fs + 1] = ";"..tostring(tutorial.selected_priv)..";true]"

        -- Add last recorded tutorial sequence
        record_fs[#record_fs + 1] = "textlist[0.5,4.2;11,1.6;eventlist;"
        for k,action in pairs(tutorial.record.temp[pname].tutorialSequence.action) do

            -- Node was recorded
            if tutorial.record.temp[pname].tutorialSequence.node[k] ~= "" then
                record_fs[#record_fs + 1] = action .. " " .. tutorial.record.temp[pname].tutorialSequence.node[k]
                -- Tool was recorded (only used with nodes)
                if tutorial.record.temp[pname].tutorialSequence.tool[k] ~= "" then
                    record_fs[#record_fs + 1] = " with " .. tutorial.record.temp[pname].tutorialSequence.tool[k]
                    record_fs[#record_fs + 1] = ","
                else
                    record_fs[#record_fs + 1] = ","
                end
            end
            
            -- Position was recorded
            if next(tutorial.record.temp[pname].tutorialSequence.pos[k]) ~= nil then
                local pos = tutorial.record.temp[pname].tutorialSequence.pos[k]
                record_fs[#record_fs + 1] = action .. " x=" .. tostring(pos.x) .. " y=" .. tostring(pos.y) .. " z=" .. tostring(pos.z)
                record_fs[#record_fs + 1] = ","
            end

            -- Direction was recorded
            if tutorial.record.temp[pname].tutorialSequence.dir[k] ~= -1 then
                record_fs[#record_fs + 1] = action .. " " .. tostring(tutorial.record.temp[pname].tutorialSequence.dir[k])
                record_fs[#record_fs + 1] = ","
            end

            -- Key strike was recorded
            if next(tutorial.record.temp[pname].tutorialSequence.key[k]) ~= nil then
                record_fs[#record_fs + 1] = action .. " "
                for _,v in pairs(tutorial.record.temp[pname].tutorialSequence.key[k]) do record_fs[#record_fs + 1] = v .. " " end
                record_fs[#record_fs + 1] = ","
            end

        end
        record_fs[#record_fs] = ""
        record_fs[#record_fs + 1] = ";1;false]"
        if tutorial.record.temp[pname].length > 0 then 
            record_fs[#record_fs + 1] = "button[0.5,6;2.5,0.7;delete;Delete event]"
        end
        record_fs[#record_fs + 1] = "label[3.2,6.3;Total events: "
        record_fs[#record_fs + 1] = tostring(tutorial.record.temp[pname].length)
        record_fs[#record_fs + 1] = "]"

        -- Add tooltips
        record_fs[#record_fs + 1] = "tooltip[title;This short title will be listed in the tutorial book;#FFFFFF;#000000]"
        record_fs[#record_fs + 1] = "tooltip[message;This message will be sent by chat to the player when the tutorial is completed;#FFFFFF;#000000]"
        record_fs[#record_fs + 1] = "tooltip[description;This description will be displayed in the tutorial book;#FFFFFF;#000000]"
        record_fs[#record_fs + 1] = "tooltip[dependence;Select other tutorials that must be completed before this tutorial is available in the tutorial book;#FFFFFF;#000000]"

        local pname = player:get_player_name()
		minetest.show_formspec(pname, "tutorial:record_fs", table.concat(record_fs,""))
		return true
	end
end

--[[
NEW FORMSPEC PROTOTYPES

OVERVIEW TAB:
formspec_version[6]
size[12.7,10]
field[0.4,0.7;11.9,0.7;title;Title;]
textarea[0.4,1.9;11.9,1.3;description;Description;]
textarea[0.4,3.7;11.9,1.3;message;Completion message;]
textarea[0.4,5.5;11.9,3.2;;Tutorial summary;]
button_exit[0.4,8.8;11.9,0.8;finish;Finish and save]

EVENT/GROUP TAB:
formspec_version[6]
size[12.7,10]
textlist[0.4,0.8;11.9,7.2;eventlist;;1;false]
label[0.4,0.6;Recorded events]
image_button[0.4,8.2;1.4,1.4;blank.png;eventlist_add_event;Add event;false;true]
image_button[3.4,8.2;1.4,1.4;blank.png;eventlist_delete;Delete;false;true]
image_button[4.9,8.2;1.4,1.4;blank.png;eventlist_duplicate;Duplicate;false;true]
image_button[7.9,8.2;1.4,1.4;blank.png;eventlist_move_up;Move up;false;true]
image_button[9.4,8.2;1.4,1.4;blank.png;eventlist_move_down;Move down;false;true]
image_button[6.4,8.2;1.4,1.4;blank.png;eventlist_move_top;Move to top;false;true]
image_button[10.9,8.2;1.4,1.4;blank.png;eventlist_move_bottom;Move to bottom;false;true]
image_button[1.9,8.2;1.4,1.4;blank.png;eventlist_add_group;Add group;false;true]

REWARDS TAB:
formspec_version[6]
size[12.7,10]
label[0.4,0.6;Available items/privileges to reward]
label[6.8,0.6;Selected rewards]
textlist[0.4,0.8;5.5,8.8;reward_list;;1;false]
textlist[6.8,0.8;5.5,6;reward_selection;;1;false]
image_button[5.9,0.8;0.9,3;blank.png;reward_add;-->;false;true]
image_button[5.9,3.8;0.9,3;blank.png;button_delete;<--;false;true]
field[6.2,7.4;4.2,0.8;reward_quantity;Quantity;1]
button[10.4,7.4;1.9,0.8;reward_quantity_update;Update]
field[6.2,8.8;4.5,0.8;reward_search;Search for items/privileges;]
image_button[10.7,8.8;0.8,0.8;blank.png;reward_search_go;Go!;false;true]
image_button[11.5,8.8;0.8,0.8;blank.png;reward_search_x;X;false;true]

DEPENDENCIES TAB:
formspec_version[6]
size[12.7,10]
label[0.4,0.6;Available tutorials]
label[6.5,0.6;Dependencies (required BEFORE)]
label[6.5,5.3;Dependents (unlocked AFTER)]
textlist[0.4,0.8;5.7,6.5;depend_tutorials;;1;false]
textlist[6.5,0.8;5.8,3.3;dependencies;;1;false]
textlist[6.5,5.5;5.8,3.3;dependents;;1;false]
button[0.4,7.4;2.8,0.8;dependencies_add;Add dependency]
button[6.5,4.1;5.8,0.8;dependencies_delete;Delete selected dependency]
button[3.3,7.4;2.8,0.8;dependents_add;Add dependent]
button[6.5,8.8;5.8,0.8;dependents_delete;Delete selected dependent]
field[0.4,8.8;4.1,0.8;depend_search;Search for tutorials;]
image_button[4.5,8.8;0.8,0.8;blank.png;depend_search_go;Go!;false;true]
image_button[5.3,8.8;0.8,0.8;blank.png;depend_search_x;X;false;true]
]]

function tutorial.show_record_options_fs(player)
    local record_options_fs = {
        "formspec_version[5]",
        "size[10.5,5]",
        "label[3.1,0.6;What do you want to record?]",
        "button_exit[0.4,1.4;3,0.8;getpos;Current Position]",
        "button_exit[0.4,2.6;3,0.8;getlookdir;Look Direction]",
        "button_exit[3.7,2.6;3,0.8;lookvertical;Look Vertical]",
        "button_exit[7,2.6;3,0.8;lookhorizontal;Look Horizontal]",
        "button_exit[3.7,1.4;3,0.8;wieldeditem;Wielded Item]",
        "button_exit[7,1.4;3,0.8;playercontrol;Pressed Key]",
        "button_exit[3.7,3.7;3,0.8;exit;Nevermind!]"
    }
    local pname = player:get_player_name()
	minetest.show_formspec(pname, "tutorial:record_options_fs", table.concat(record_options_fs,""))
	return true
end

function tutorial.show_tutorials(player)
    local tutorials_fs = {
        "formspec_version[5]",
        "size[13,10]"
    }

    tutorials_fs[#tutorials_fs + 1] = "button_exit[11.3,8.9;1.5,0.8;exit;Exit]"

    -- Get the stored tutorials available for any player
    local tutorials = minetest.deserialize(tutorial.tutorials:get_string("tutorial:tutorials"))
    if tutorials ~= nil and tutorials[1] ~= nil then
        tutorials_fs[#tutorials_fs + 1] = "box[0.1,8.8;5.7,1;#00FF00]"
        tutorials_fs[#tutorials_fs + 1] = "button_exit[0.2,8.9;5.5,0.8;start;Start Tutorial]"
        tutorials_fs[#tutorials_fs + 1] = "textlist[0.2,0.2;4.6,8.4;tutoriallist;"
        for _,thisTutorial in pairs(tutorials) do
            tutorials_fs[#tutorials_fs + 1] = thisTutorial.title 
            tutorials_fs[#tutorials_fs + 1] = ","
        end
        tutorials_fs[#tutorials_fs] = ""
        tutorials_fs[#tutorials_fs + 1] = ";"..tostring(tutorial.tutorial_selected)..";false]"
        tutorial.tutorial_selected = tutorial.tutorial_selected or 1

        -- Check to ensure that the selected tutorial index is valid for retrieiving the description
        if tutorials[tutorial.tutorial_selected] ~= nil then
            tutorials_fs[#tutorials_fs + 1] = "textarea[5,0.2;7.8,8.4;text;;"..tutorials[tutorial.tutorial_selected].description.."]"
        else
            tutorials_fs[#tutorials_fs + 1] = "textarea[5,0.2;7.8,8.4;text;;]"
        end

        -- Add edit/delete options for those privileged
        if tutorial.checkPrivs(player,tutorial.recorder_priv_table) then 
            tutorials_fs[#tutorials_fs + 1] = "box[5.9,8.8;5.2,1;#FF0000]"
            tutorials_fs[#tutorials_fs + 1] = "button[6,8.9;2.3,0.8;delete;Delete]"
            tutorials_fs[#tutorials_fs + 1] = "button[8.6,8.9;2.4,0.8;edit;Edit]"
        end
    else
        tutorials_fs[#tutorials_fs + 1] = "textlist[0.2,0.2;4.6,8.4;tutoriallist;No Tutorials Found;1;false]"
    end

    local pname = player:get_player_name()
    minetest.show_formspec(pname, "tutorial:tutorials", table.concat(tutorials_fs, ""))
    return true
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local pname = player:get_player_name()
	tutorial.wait(0.05) --popups don't work without this

	-- Manage recorded tutorials
    if formname == "tutorial:tutorials" then
        local tutorials = minetest.deserialize(tutorial.tutorials:get_string("tutorial:tutorials"))
        if fields.tutoriallist then
            local event = minetest.explode_textlist_event(fields.tutoriallist)
            if event.type == "CHG" then
                tutorial.tutorial_selected = event.index
            end
            tutorial.show_tutorials(player)
        elseif fields.delete then
            if tutorial.checkPrivs(player,tutorial.recorder_priv_table) then
                if tutorial.tutorial_selected == nil then tutorial.tutorial_selected = 1 end
                if tutorials ~= nil then
                    table.remove(tutorials,tutorial.tutorial_selected)
                    tutorial.tutorials:set_string("tutorial:tutorials", minetest.serialize(tutorials))
                    tutorial.tutorial_selected = 1
                    tutorial.show_tutorials(player)
                else
                    return
                end
            else
                minetest.chat_send_player(pname,pname.." [Tutorial] You do not have sufficient privileges to delete tutorials.")
            end
        elseif fields.edit then
            if tutorial.tutorial_selected == nil then tutorial.tutorial_selected = 1 end
            if tutorial.checkPrivs(player,tutorial.recorder_priv_table) then
                tutorial.record.temp[pname] = tutorials[tutorial.tutorial_selected]
                tutorial.record.edit[pname] = true
                if tutorial.record.temp[pname] then
                    tutorial.show_record_fs(player)
                end
            else
                minetest.chat_send_player(pname,pname.." [Tutorial] You do not have sufficient privileges to edit tutorials.")
            end
        elseif fields.start then
            if tutorial.tutorial_selected == nil then tutorial.tutorial_selected = 1 end
            if tutorials[tutorial.tutorial_selected] then
                pmeta = player:get_meta()
                pdata = minetest.deserialize(pmeta:get_string("tutorial:tutorials"))
                pdata.tutorials.activeTutorial = tutorials[tutorial.tutorial_selected]
                pmeta:set_string("tutorial:tutorials", minetest.serialize(pdata))
                minetest.chat_send_player(pname,pname.." [Tutorial] Tutorial has started: "..pdata.tutorials.activeTutorial.title)
                -- Check if there is an action in the tutorialSequence that requires the tutorial_progress_listener
                -- This saves us from unnecessarily burning cycles server-side
                for _,action in ipairs(pdata.tutorials.activeTutorial.tutorialSequence.action) do
                    if action == "current position" or action == "look direction" or action == "look pitch" or action == "look yaw" or action == "wield" or action == "player control" then
                        tutorial.tutorial_progress_listener()
                    end
                end
                -- TODO: add HUD and/or formspec to display the instructions for the tutorial
            end
        end
    end
    
    -- Continue the recording with other options with on_right_click callback
    if formname == "tutorial:record_options_fs" then

        -- TODO: add formspec to support recording: 
                ----- put something into or modify inventory player:get_inventory() inv:contains_item() inv:is_empty() ItemStack:get_count()
                ----- press keys player:get_player_control() or player:get_player_control_bits()
        
        if tutorial.checkPrivs(player,tutorial.recorder_priv_table) and tutorial.record.active[pname] then
            -- Check if the tutorial has already been instanced by another callback
            if not tutorial.record.temp[pname] then
                -- this is the first entry for the tutorial, apply default values
                tutorial.record.temp[pname] = {
                    tutorialDependency = {}, -- table of tutorialIDs that must be compeleted before the player can attempt this tutorial
                    tutorialSequence = {
                        action = {}, -- string
                        tool = {}, -- string
                        node = {}, -- string
                        pos = {}, -- table
                        dir = {}, -- integer 
                        key = {}, -- table
                        actionMessage = {} -- table of strings displayed to player when an action is completed
                    },
                    length = 0,
                    on_completion = {
                        message = "",
                        givetool = {},
                        giveitem = {},
                        grantpriv = {}
                    }
                }
            end
        end

        if fields.getpos then
            local pos = player:get_pos()
            table.insert(tutorial.record.temp[pname].tutorialSequence.action, "current position")
            table.insert(tutorial.record.temp[pname].tutorialSequence.tool, "")
            table.insert(tutorial.record.temp[pname].tutorialSequence.node, "")
            table.insert(tutorial.record.temp[pname].tutorialSequence.pos, pos)
            table.insert(tutorial.record.temp[pname].tutorialSequence.dir, -1)
            table.insert(tutorial.record.temp[pname].tutorialSequence.key, {})
            minetest.chat_send_player(pname, "[Tutorial] Your current position was recorded. Continue to record new actions or left-click the tool to end the recording.")
            tutorial.record.temp[pname].length = tutorial.record.temp[pname].length + 1
        end
        
        if fields.getlookdir then
            local lookdir = player:get_look_dir()
            table.insert(tutorial.record.temp[pname].tutorialSequence.action, "look direction")
            table.insert(tutorial.record.temp[pname].tutorialSequence.tool, "")
            table.insert(tutorial.record.temp[pname].tutorialSequence.node, "")
            table.insert(tutorial.record.temp[pname].tutorialSequence.pos, {})
            table.insert(tutorial.record.temp[pname].tutorialSequence.dir, lookdir)
            table.insert(tutorial.record.temp[pname].tutorialSequence.key, {})
            minetest.chat_send_player(pname, "[Tutorial] Your current look direction was recorded. Continue to record new actions or left-click the tool to end the recording.")
            tutorial.record.temp[pname].length = tutorial.record.temp[pname].length + 1
        end

        if fields.lookvertical then
            local lookv = player:get_look_vertical()
            table.insert(tutorial.record.temp[pname].tutorialSequence.action, "look pitch")
            table.insert(tutorial.record.temp[pname].tutorialSequence.tool, "")
            table.insert(tutorial.record.temp[pname].tutorialSequence.node, "")
            table.insert(tutorial.record.temp[pname].tutorialSequence.pos, {})
            table.insert(tutorial.record.temp[pname].tutorialSequence.dir, lookv)
            table.insert(tutorial.record.temp[pname].tutorialSequence.key, {})
            minetest.chat_send_player(pname, "[Tutorial] Your current look pitch (radians) was recorded. Continue to record new actions or left-click the tool to end the recording.")
            tutorial.record.temp[pname].length = tutorial.record.temp[pname].length + 1
        end

        if fields.lookhorizontal then
            local lookh = player:get_look_horizontal()
            table.insert(tutorial.record.temp[pname].tutorialSequence.action, "look yaw")
            table.insert(tutorial.record.temp[pname].tutorialSequence.tool, "")
            table.insert(tutorial.record.temp[pname].tutorialSequence.node, "")
            table.insert(tutorial.record.temp[pname].tutorialSequence.pos, {})
            table.insert(tutorial.record.temp[pname].tutorialSequence.dir, lookh)
            table.insert(tutorial.record.temp[pname].tutorialSequence.key, {})
            minetest.chat_send_player(pname, "[Tutorial] Your current look yaw (radians) was recorded. Continue to record new actions or left-click the tool to end the recording.")
            tutorial.record.temp[pname].length = tutorial.record.temp[pname].length + 1
        end

        if fields.wieldeditem then
            -- TODO: add HUD or chat message to indicate timer
            -- TODO: possibly identify an alternative method for setting the weilded item that does not make use of a timed listener
            minetest.chat_send_player(pname, "[Tutorial] Make a selection from your inventory to set the wield item.")
            tutorial.record.listener.wield[pname] = true
            return
        end

        if fields.playercontrol then
            minetest.chat_send_player(pname, "[Tutorial] Press the player control key that you want to be recorded.")
            tutorial.record.listener.key[pname] = true
            return
        end

        if fields.exit then
            return
        end
    end

    -- Complete the recording
	if formname == "tutorial:record_fs" then
        if fields.eventlist then
            local event = minetest.explode_textlist_event(fields.eventlist)
            if event.type == "CHG" then
                tutorial.selected_event = event.index
            end
        end
        if fields.givetool then
            local event = minetest.explode_textlist_event(fields.givetool)
            if event.type == "CHG" then
                tutorial.selected_tool = event.index
            end
            for i,itemstring in ipairs(tools) do
                if i+1 == tutorial.selected_tool then
                    tutorial.record.temp[pname].on_completion.givetool = itemstring
                end
            end
        end
        if fields.giveitem then
            local event = minetest.explode_textlist_event(fields.giveitem)
            if event.type == "CHG" then
                tutorial.selected_item = event.index
            end
            for i,itemstring in ipairs(items) do
                if i+1 == tutorial.selected_item then
                    tutorial.record.temp[pname].on_completion.giveitem = itemstring
                end
            end
        end
        if fields.grantpriv then
            local event = minetest.explode_textlist_event(fields.grantpriv)
            if event.type == "CHG" then
                tutorial.selected_priv = event.index
            end
            for i,privv in ipairs(privs) do
                if i+1 == tutorial.selected_privt then
                    tutorial.record.temp[pname].on_completion.grantpriv = privv
                end
            end
        end
        if fields.delete then
            if tutorial.selected_event == nil then tutorial.selected_event = 1 end
            table.remove(tutorial.record.temp[pname].tutorialSequence.action,tutorial.selected_event)
            table.remove(tutorial.record.temp[pname].tutorialSequence.tool,tutorial.selected_event)
            table.remove(tutorial.record.temp[pname].tutorialSequence.node,tutorial.selected_event)
            table.remove(tutorial.record.temp[pname].tutorialSequence.pos, tutorial.selected_event)
            table.remove(tutorial.record.temp[pname].tutorialSequence.dir, tutorial.selected_event)
            table.remove(tutorial.record.temp[pname].tutorialSequence.key, tutorial.selected_event)
            tutorial.record.temp[pname].length = tutorial.record.temp[pname].length - 1
            tutorial.show_record_fs(player)
        end
        if fields.finish then
            if tutorial.record.temp[pname] then
                if tutorial.record.temp[pname].length > 0 then
                    if fields.title == "" then 
                        tutorialTitle = "Untitled" 
                    else 
                        tutorialTitle = fields.title 
                    end
                    if fields.description == "" then 
                        tutorialDescription = "No description was entered for this tutorial." 
                    else 
                        tutorialDescription = fields.description 
                    end
                    if fields.message == "" then 
                        tutorialMessage = "You completed the tutorial!" 
                    else 
                        tutorialMessage = fields.message 
                    end
                    
                    -- Quick check to make sure we are not writing invalid entries on_completion
                    if tutorial.record.temp[pname].on_completion.givetool == "None" and tutorial.record.temp[pname].on_completion.givetool == "" then
                        tutorial.record.temp[pname].on_completion.giveitem = nil
                    end
                    if tutorial.record.temp[pname].on_completion.giveitem == "None" and tutorial.record.temp[pname].on_completion.giveitem == "" then
                        tutorial.record.temp[pname].on_completion.giveitem = nil
                    end
                    if tutorial.record.temp[pname].on_completion.grantpriv == "None" and tutorial.record.temp[pname].on_completion.grantpriv == "" then
                        tutorial.record.temp[pname].on_completion.grantpriv = nil
                    end

                    -- Build the tutorial table to send to mod storage
                    local recordTutorial = {
                        tutorialDependency = {}, -- table of tutorialIDs that must be compeleted before the player can attempt this tutorial
                        title = tutorialTitle,
                        length = tutorial.record.temp[pname].length,
                        searchIndex = 1, -- default search always starts on the first element in the sequence
                        continueTutorial = true, -- default starting state of tutorial is true to automatically continue
                        completed = 0, -- default completed actions starts at zero
                        description = tutorialDescription,
                        tutorialSequence = {
                            action = tutorial.record.temp[pname].tutorialSequence.action,
                            tool = tutorial.record.temp[pname].tutorialSequence.tool,
                            node = tutorial.record.temp[pname].tutorialSequence.node,
                            pos = tutorial.record.temp[pname].tutorialSequence.pos,
                            dir = tutorial.record.temp[pname].tutorialSequence.dir,
                            key = tutorial.record.temp[pname].tutorialSequence.key,
                            actionMessage = {} -- table of strings displayed to player when an action is completed
                        },
                        on_completion = {
                            message = tutorialMessage,
                            givetool = tutorial.record.temp[pname].on_completion.givetool,
                            giveitem = tutorial.record.temp[pname].on_completion.giveitem,
                            grantpriv = tutorial.record.temp[pname].on_completion.grantpriv
                        }
                    }

                    -- Send to mod storage
                    local tutorials = minetest.deserialize(tutorial.tutorials:get_string("tutorial:tutorials"))
                    if tutorials == nil or next(tutorials) == nil then
                        local tutorials = {}
                        table.insert(tutorials, recordTutorial)
                        tutorial.tutorials:set_string("tutorial:tutorials", minetest.serialize(tutorials))
                    else
                        if tutorial.record.edit[pname] then
                            -- We are editing an existing tutorial
                            tutorials[tutorial.tutorial_selected] = recordTutorial
                        else
                            -- We are apending a new tutorial
                            table.insert(tutorials, recordTutorial)
                        end
                        tutorial.tutorials:set_string("tutorial:tutorials", minetest.serialize(tutorials))
                    end
                    minetest.chat_send_player(pname,pname.." [Tutorial] Your tutorial was successfully recorded!")
                else
                    minetest.chat_send_player(pname,pname.." [Tutorial] No tutorial was recorded.")
                end

                -- Ensure global tutorialTemp is recycled
                tutorial.record.temp[pname] = nil
            else 
                return
            end
        elseif fields.dependence then
            
        else
            -- Form submitted without entry, record nothing
            return
        end
    end

end)

minetest.register_on_leaveplayer(function(player)
    pmeta = player:get_meta()
    pdata = minetest.deserialize(pmeta:get_string("tutorial:tutorials"))
    pdata.tutorials.activeTutorial.continueTutorial = false
    pmeta:set_string("tutorial:tutorials", minetest.serialize(pdata))
end)

-- TODO: other possible callbacks
--minetest.register_allow_player_inventory_action(function(player, action, inventory, inventory_info))
--minetest.register_on_craft(func(itemstack, player, old_craft_grid, craft_inv))
--minetest.register_on_receiving_chat_messages(function(message))

-- below commands for debudding only
minetest.register_chatcommand("clearTutorials", {
	description = "Clear all tutorials from mod storage.",
	privs = tutorial.recorder_priv_table,
	func = function(name, param)
        tutorial.tutorials:set_string("tutorial:tutorials", nil)
        minetest.chat_send_all("[Tutorial] All tutorials have been cleared from memory.")
	end
})

minetest.register_chatcommand("listTutorials", {
	description = "List titles of all stored tutorials.",
	privs = tutorial.recorder_priv_table,
	func = function(name, param)
        local tutorials = minetest.deserialize(tutorial.tutorials:get_string("tutorial:tutorials"))
        if tutorials ~= nil then
            minetest.chat_send_all("[Tutorial] Recorded tutorials:")
            for _,thisTutorial in pairs(tutorials) do
                minetest.chat_send_all("[Tutorial]    " .. thisTutorial.title)
            end
        else
            minetest.chat_send_all("[Tutorial] No tutorials have been recorded.")
        end
	end
})

minetest.register_chatcommand("dumpTutorials", {
	description = "Dumps tutorials mod storage table.",
	privs = tutorial.recorder_priv_table,
	func = function(name, param)
        tutorials = minetest.deserialize(tutorial.tutorials:get_string("tutorial:tutorials"))
        minetest.chat_send_all(tostring(_G.dump(tutorials)))
	end
})

minetest.register_chatcommand("dumppdata", {
	description = "Dumps player meta table.",
	privs = tutorial.recorder_priv_table,
	func = function(name, param)
        player = minetest.get_player_by_name(name)
        pmeta = player:get_meta()
        pdata = minetest.deserialize(pmeta:get_string("tutorial:tutorials"))
        minetest.chat_send_all(tostring(_G.dump(pdata)))
	end
})