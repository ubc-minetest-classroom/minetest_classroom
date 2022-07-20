-- TODO:
----- refactor mod/table name to prevent potential mod naming conflicts
----- add tutorial progress and completion to player meta
----- get/set pdata.tutorials.activeTutorial from player meta
----- make tutorials dependent on other tutorials (sequence of tutorials)
----- update png texture for tutorialbook - consider revising this to a new icon different from student notebook
----- add sequence of formspecs or HUD elements to guide teacher through recording different gameplay options
----- make tutorial_fs dynamic to show what a player will get on_complettion: use add item_image[]
----- need a way for the player to access the pdata.tutorials.activeTutorial instructions and possibly accompanying item_images and models
----- update the record_fs menu so that on_completion items and tools are displayed in an inventory and the number of items given can be set by the player recording the tutorial
----- add option to display a message after completing a specific action, like "now do this next"\
----- fix tutorial wield/key listener

mc_tutorial = {
    path = minetest.get_modpath("mc_tutorial"),
    tutorials = minetest.get_mod_storage(),
    record = {
        active = {},
        temp = {},
        edit = {},
        listener = {
            wield = {},
            key = {}
        },
        timer = {}
    },
    fs_context = {},
    active = {},

    ACTION = { -- action constants
        PUNCH = 1,
        DIG = 2,
        PLACE = 3,
        WIELD = 4,
        KEY = 5,
        LOOK_YAW = 6,
        LOOK_PITCH = 7,
        LOOK_DIR = 8,
        POS = 9
    }
}

local function get_context(player)
    local pname = (type(player) == "string" and player) or (player:is_player() and player:get_player_name()) or ""
    return mc_tutorial.fs_context[pname] or {}
end
local function save_context(player, context)
    local pname = (type(player) == "string" and player) or (player:is_player() and player:get_player_name())
    if pname then
        mc_tutorial.fs_context[pname] = context
    end
end

-- Store and load default settings in the tutorial_settings.conf file
local settings = Settings(mc_tutorial.path .. "/tutorial_settings.conf")
function mc_tutorial.fetch_setting(name)
    local sname = "mc_tutorial." .. name
    return settings and settings:get(sname) or minetest.settings:get(sname)
end
function mc_tutorial.fetch_setting_table(name)
    local setting_string = mc_tutorial.fetch_setting(name)
    local table = mc_helpers.split(setting_string, ",")
    for i,v in ipairs(table) do
        table[i] = v:trim()
    end
    return table
end
function mc_tutorial.fetch_setting_key_table(name)
    local output = {}
    for _,priv in pairs(mc_tutorial.fetch_setting_table(name) or {}) do
        output[priv] = true
    end
    return output
end

mc_tutorial.player_priv_table = mc_tutorial.fetch_setting_key_table("player_priv_table") or {interact = true}
mc_tutorial.recorder_priv_table = mc_tutorial.fetch_setting_key_table("recorder_priv_table") or {teacher = true, interact = true}
mc_tutorial.check_interval = mc_tutorial.fetch_setting("check_interval") or 1
mc_tutorial.check_dir_tolerance = mc_tutorial.fetch_setting("check_dir_tolerance") or 0.01745
mc_tutorial.check_pos_x_tolerance = tonumber(mc_tutorial.fetch_setting("check_pos_x_tolerance") or 4) * mc_tutorial.check_interval
mc_tutorial.check_pos_y_tolerance = tonumber(mc_tutorial.fetch_setting("check_pos_y_tolerance") or 4) * mc_tutorial.check_interval
mc_tutorial.check_pos_z_tolerance = tonumber(mc_tutorial.fetch_setting("check_pos_z_tolerance") or 4) * mc_tutorial.check_interval

-- Load other scripts
dofile(mc_tutorial.path .. "/functions.lua")
dofile(mc_tutorial.path .. "/tools.lua")
dofile(mc_tutorial.path .. "/callbacks.lua")

minetest.register_on_joinplayer(function(player)
    -- Load player meta
    pmeta = player:get_meta()
    pdata = minetest.deserialize(pmeta:get_string("mc_tutorial:tutorials"))
    if pdata == nil or next(pdata) == nil then
        -- Nothing to see here so initialize and serialize a table to hold everything
        pdata = {
            tutorials = {
                activeTutorial = {},
                playerSequence = {},
                completedTutorials = {}, -- TODO: use this to change the tutorial_fs to indicate tutorials that are completed
                wieldThingListener = false,
                keyStrikeListener = false,
            }
        }
        pmeta:set_string("mc_tutorial:tutorials", minetest.serialize(pdata))
    end
end)

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

function mc_tutorial.show_record_fs(player)
    local pname = player:get_player_name()
	if mc_tutorial.check_privs(player, mc_tutorial.recorder_priv_table) then
        -- Tutorial formspec for recording a tutorial
        local context = get_context(pname)
        local temp = mc_tutorial.record.temp[pname] or {}

        local record_formtable = {
            "formspec_version[6]",
            "size[12.7,10]",
            "tabheader[0,0;record_nav;Overview,Events,Rewards", next(mc_tutorial.tutorials:to_table()) and ",Dependencies" or "", ";", context.tab or "1", ";false;false]"
        }
        local tab_map = {
            ["1"] = { -- OVERVIEW
                "field[0.4,0.7;11.9,0.7;title;Title;", temp.title or "", "]",
                "textarea[0.4,1.9;11.9,1.3;description;Description;", temp.description or "", "]",
                "textarea[0.4,3.7;11.9,1.3;message;Completion message;", temp.on_completion and temp.on_completion.message or "", "]",
                "textarea[0.4,5.5;11.9,3.2;;Tutorial summary;", minetest.formspec_escape("[TBD]"), "]",
                "button_exit[0.4,8.8;11.9,0.8;finish;Finish and save]",
            },
            ["2"] = { -- EVENTS
                "textlist[0.4,0.8;11.9,7.2;eventlist;;1;false]",
                "label[0.4,0.6;Recorded events]",
                "image_button[0.4,8.2;1.4,1.4;mc_tutorial_add_event.png;eventlist_add_event;;false;true]",
                "image_button[1.9,8.2;1.4,1.4;mc_tutorial_add_group.png;eventlist_add_group;;false;true]",
                "image_button[3.4,8.2;1.4,1.4;mc_tutorial_delete.png;eventlist_delete;;false;true]",
                "image_button[4.9,8.2;1.4,1.4;mc_tutorial_duplicate.png;eventlist_duplicate;;false;true]",
                "image_button[6.4,8.2;1.4,1.4;mc_tutorial_move_top.png;eventlist_move_top;;false;true]",
                "image_button[7.9,8.2;1.4,1.4;mc_tutorial_move_up.png;eventlist_move_up;;false;true]",
                "image_button[9.4,8.2;1.4,1.4;mc_tutorial_move_down.png;eventlist_move_down;;false;true]",
                "image_button[10.9,8.2;1.4,1.4;mc_tutorial_move_bottom.png;eventlist_move_bottom;;false;true]",
                "tooltip[eventlist_add_event;Add new event]",
                "tooltip[eventlist_add_group;Add new group]",
                "tooltip[eventlist_delete;Delete]",
                "tooltip[eventlist_duplicate;Duplicate]",
                "tooltip[eventlist_move_top;Move to top]",
                "tooltip[eventlist_move_up;Move up 1]",
                "tooltip[eventlist_move_down;Move down 1]",
                "tooltip[eventlist_move_bottom;Move to bottom]",
            },
            ["3"] = { -- REWARDS
                "label[0.4,0.6;Available items/privileges to reward]",
                "label[6.8,0.6;Selected rewards]",
                "textlist[0.4,0.8;5.5,8.8;reward_list;;1;false]",
                "textlist[6.8,0.8;5.5,6;reward_selection;;1;false]",
                "image_button[5.9,0.8;0.9,3;blank.png;reward_add;-->;false;true]",
                "image_button[5.9,3.8;0.9,3;blank.png;button_delete;<--;false;true]",
                "field[6.2,7.4;4.2,0.8;reward_quantity;Quantity;1]",
                "button[10.4,7.4;1.9,0.8;reward_quantity_update;Update]",
                "field[6.2,8.8;4.5,0.8;reward_search;Search for items/privileges;]",
                "image_button[10.7,8.8;0.8,0.8;blank.png;reward_search_go;Go!;false;true]",
                "image_button[11.5,8.8;0.8,0.8;blank.png;reward_search_x;X;false;true]",
            },
            ["4"] = { -- DEPENDENCIES
                "label[0.4,0.6;Available tutorials]",
                "label[6.5,0.6;Dependencies (required BEFORE)]",
                "label[6.5,5.3;Dependents (unlocked AFTER)]",
                "textlist[0.4,0.8;5.7,6.5;depend_tutorials;;1;false]",
                "textlist[6.5,0.8;5.8,3.3;dependencies;;1;false]",
                "textlist[6.5,5.5;5.8,3.3;dependents;;1;false]",
                "button[0.4,7.4;2.8,0.8;dependencies_add;Add dependency]",
                "button[6.5,4.1;5.8,0.8;dependencies_delete;Delete selected dependency]",
                "button[3.3,7.4;2.8,0.8;dependents_add;Add dependent]",
                "button[6.5,8.8;5.8,0.8;dependents_delete;Delete selected dependent]",
                "field[0.4,8.8;4.1,0.8;depend_search;Search for tutorials;]",
                "image_button[4.5,8.8;0.8,0.8;blank.png;depend_search_go;Go!;false;true]",
                "image_button[5.3,8.8;0.8,0.8;blank.png;depend_search_x;X;false;true]",
            },
        }
        table.insert(record_formtable, table.concat(tab_map[context.tab or "1"], ""))

		minetest.show_formspec(pname, "mc_tutorial:record_fs", table.concat(record_formtable, ""))
		return true

        --[[record_fs = {
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
        local tutorials = minetest.deserialize(mc_tutorial.tutorials:get_string("tutorial:tutorials"))
        if tutorials ~= nil and next(tutorials) ~= nil then
            record_fs[#record_fs + 1] = "button_exit[1.1,10.9;5.8,0.8;dependence;Select Tutorial Dependencies]"
            record_fs[#record_fs + 1] = "label[7.2,11.3;OR]" 
        end

        -- If the tutorial has already been registered then populate the fields with the values
        if mc_tutorial.record.temp[pname].title then 
            record_fs[#record_fs + 1] = "field[0.5,0.7;11,0.8;title;Title;"..mc_tutorial.record.temp[pname].title.."]"
        else
            record_fs[#record_fs + 1] = "field[0.5,0.7;11,0.8;title;Title;]"
        end
        if mc_tutorial.record.temp[pname].on_completion.message then 
            record_fs[#record_fs + 1] = "field[0.4,8.4;11.1,0.7;message;Message;"..mc_tutorial.record.temp[pname].on_completion.message.."]"
        else
            record_fs[#record_fs + 1] = "field[0.4,8.4;11.1,0.7;message;Message;]"
        end

        if mc_tutorial.record.temp[pname].itemImages then
            -- TODO: handle item images
        else
            if mc_tutorial.record.temp[pname].description then 
                record_fs[#record_fs + 1] = "field[0.5,2;11,1.5;description;Description;"..mc_tutorial.record.temp[pname].description.."]"
            else
                record_fs[#record_fs + 1] = "field[0.5,2;11,1.5;description;Description;]"
            end
        end

        -- Add all registered tools to textlist
        record_fs[#record_fs + 1] = "textlist[0.3,9.8;3.7,0.8;givetool;None,"
        mc_tutorial.selected_tool = mc_tutorial.selected_tool or 1
        tools = {}
        for k,v in pairs(minetest.registered_items) do if v.type == "tool" then table.insert(tools,k) end end
        table.sort(tools)
        for i,itemstring in ipairs(tools) do 
            record_fs[#record_fs + 1] = itemstring
            record_fs[#record_fs + 1] = "," 
        end
        record_fs[#record_fs] = ""
        record_fs[#record_fs + 1] = ";"..tostring(mc_tutorial.selected_tool)..";true]"

        -- Add all registered non-tool items to textlist
        record_fs[#record_fs + 1] = "textlist[4.1,9.8;4.9,0.8;giveitem;None,"
        mc_tutorial.selected_item = mc_tutorial.selected_item or 1
        items = {}
        for k,v in pairs(minetest.registered_items) do if v.type ~= "tool" and k ~= "" then table.insert(items,k) end end
        table.sort(items)
        for i,itemstring in ipairs(items) do 
            record_fs[#record_fs + 1] = itemstring 
            record_fs[#record_fs + 1] = "," 
        end
        record_fs[#record_fs] = ""
        record_fs[#record_fs + 1] = ";"..tostring(mc_tutorial.selected_item)..";true]"

        -- Add all registered privileges to textlist
        record_fs[#record_fs + 1] = "textlist[9.1,9.8;2.5,0.8;grantpriv;None,"
        mc_tutorial.selected_priv = mc_tutorial.selected_priv or 1
        privs = {}
        for k,v in pairs(minetest.registered_privileges) do table.insert(privs,k) end
        table.sort(privs)
        for i,privv in ipairs(privs) do 
            record_fs[#record_fs + 1] = privv 
            record_fs[#record_fs + 1] = "," 
        end
        record_fs[#record_fs] = ""
        record_fs[#record_fs + 1] = ";"..tostring(mc_tutorial.selected_priv)..";true]"

        -- Add last recorded tutorial sequence
        record_fs[#record_fs + 1] = "textlist[0.5,4.2;11,1.6;eventlist;"
        for k,action in pairs(mc_tutorial.record.temp[pname].sequence.action) do

            -- Node was recorded
            if mc_tutorial.record.temp[pname].sequence.node[k] ~= "" then
                record_fs[#record_fs + 1] = action .. " " .. mc_tutorial.record.temp[pname].sequence.node[k]
                -- Tool was recorded (only used with nodes)
                if mc_tutorial.record.temp[pname].sequence.tool[k] ~= "" then
                    record_fs[#record_fs + 1] = " with " .. mc_tutorial.record.temp[pname].sequence.tool[k]
                    record_fs[#record_fs + 1] = ","
                else
                    record_fs[#record_fs + 1] = ","
                end
            end
            
            -- Position was recorded
            if next(mc_tutorial.record.temp[pname].sequence.pos[k]) ~= nil then
                local pos = mc_tutorial.record.temp[pname].sequence.pos[k]
                record_fs[#record_fs + 1] = action .. " x=" .. tostring(pos.x) .. " y=" .. tostring(pos.y) .. " z=" .. tostring(pos.z)
                record_fs[#record_fs + 1] = ","
            end

            -- Direction was recorded
            if mc_tutorial.record.temp[pname].sequence.dir[k] ~= -1 then
                record_fs[#record_fs + 1] = action .. " " .. tostring(mc_tutorial.record.temp[pname].sequence.dir[k])
                record_fs[#record_fs + 1] = ","
            end

            -- Key strike was recorded
            if next(mc_tutorial.record.temp[pname].sequence.key[k]) ~= nil then
                record_fs[#record_fs + 1] = action .. " "
                for _,v in pairs(mc_tutorial.record.temp[pname].sequence.key[k]) do record_fs[#record_fs + 1] = v .. " " end
                record_fs[#record_fs + 1] = ","
            end

        end
        record_fs[#record_fs] = ""
        record_fs[#record_fs + 1] = ";1;false]"
        if mc_tutorial.record.temp[pname].length > 0 then 
            record_fs[#record_fs + 1] = "button[0.5,6;2.5,0.7;delete;Delete event]"
        end
        record_fs[#record_fs + 1] = "label[3.2,6.3;Total events: "
        record_fs[#record_fs + 1] = tostring(mc_tutorial.record.temp[pname].length)
        record_fs[#record_fs + 1] = "]"

        -- Add tooltips
        record_fs[#record_fs + 1] = "tooltip[title;This short title will be listed in the tutorial book;#FFFFFF;#000000]"
        record_fs[#record_fs + 1] = "tooltip[message;This message will be sent by chat to the player when the tutorial is completed;#FFFFFF;#000000]"
        record_fs[#record_fs + 1] = "tooltip[description;This description will be displayed in the tutorial book;#FFFFFF;#000000]"
        record_fs[#record_fs + 1] = "tooltip[dependence;Select other tutorials that must be completed before this tutorial is available in the tutorial book;#FFFFFF;#000000]"]]
	end
end

function mc_tutorial.show_record_options_fs(player)
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
	minetest.show_formspec(pname, "mc_tutorial:record_options_fs", table.concat(record_options_fs, ""))
	return true
end

function mc_tutorial.show_tutorials(player)
    local tutorials_fs = {
        "formspec_version[5]",
        "size[13,10]"
    }

    tutorials_fs[#tutorials_fs + 1] = "button_exit[11.3,8.9;1.5,0.8;exit;Exit]"

    -- Get the stored tutorials available for any player
    local tutorials = minetest.deserialize(mc_tutorial.tutorials:get_string("mc_tutorial:tutorials"))
    if tutorials ~= nil and tutorials[1] ~= nil then
        tutorials_fs[#tutorials_fs + 1] = "box[0.1,8.8;5.7,1;#00FF00]"
        tutorials_fs[#tutorials_fs + 1] = "button_exit[0.2,8.9;5.5,0.8;start;Start Tutorial]"
        tutorials_fs[#tutorials_fs + 1] = "textlist[0.2,0.2;4.6,8.4;tutoriallist;"
        for _,thisTutorial in pairs(tutorials) do
            tutorials_fs[#tutorials_fs + 1] = thisTutorial.title 
            tutorials_fs[#tutorials_fs + 1] = ","
        end
        tutorials_fs[#tutorials_fs] = ""
        tutorials_fs[#tutorials_fs + 1] = ";"..tostring(mc_tutorial.tutorial_selected)..";false]"
        mc_tutorial.tutorial_selected = mc_tutorial.tutorial_selected or 1

        -- Check to ensure that the selected tutorial index is valid for retrieiving the description
        if tutorials[mc_tutorial.tutorial_selected] ~= nil then
            tutorials_fs[#tutorials_fs + 1] = "textarea[5,0.2;7.8,8.4;text;;"..tutorials[mc_tutorial.tutorial_selected].description.."]"
        else
            tutorials_fs[#tutorials_fs + 1] = "textarea[5,0.2;7.8,8.4;text;;]"
        end

        -- Add edit/delete options for those privileged
        if mc_tutorial.check_privs(player,mc_tutorial.recorder_priv_table) then 
            tutorials_fs[#tutorials_fs + 1] = "box[5.9,8.8;5.2,1;#FF0000]"
            tutorials_fs[#tutorials_fs + 1] = "button[6,8.9;2.3,0.8;delete;Delete]"
            tutorials_fs[#tutorials_fs + 1] = "button[8.6,8.9;2.4,0.8;edit;Edit]"
        end
    else
        tutorials_fs[#tutorials_fs + 1] = "textlist[0.2,0.2;4.6,8.4;tutoriallist;No Tutorials Found;1;false]"
    end

    local pname = player:get_player_name()
    minetest.show_formspec(pname, "mc_tutorial:tutorials", table.concat(tutorials_fs, ""))
    return true
end

-- REWORK
minetest.register_on_player_receive_fields(function(player, formname, fields)
    local pname = player:get_player_name()
    local context = get_context(pname)
	mc_tutorial.wait(0.05) --popups don't work without this

	-- Manage recorded tutorials
    if formname == "mc_tutorial:tutorials" then
        local tutorials = minetest.deserialize(mc_tutorial.tutorials:get_string("mc_tutorial:tutorials"))
        if fields.tutoriallist then
            local event = minetest.explode_textlist_event(fields.tutoriallist)
            if event.type == "CHG" then
                mc_tutorial.tutorial_selected = event.index
            end
            mc_tutorial.show_tutorials(player)
        elseif fields.delete then
            if mc_tutorial.check_privs(player, mc_tutorial.recorder_priv_table) then
                if mc_tutorial.tutorial_selected == nil then mc_tutorial.tutorial_selected = 1 end
                if tutorials ~= nil then
                    table.remove(tutorials, mc_tutorial.tutorial_selected)
                    mc_tutorial.tutorials:set_string("mc_tutorial:tutorials", minetest.serialize(tutorials))
                    mc_tutorial.tutorial_selected = 1
                    mc_tutorial.show_tutorials(player)
                else
                    return
                end
            else
                minetest.chat_send_player(pname, "[Tutorial] You do not have sufficient privileges to delete tutorials.")
            end
        elseif fields.edit then
            if mc_tutorial.tutorial_selected == nil then mc_tutorial.tutorial_selected = 1 end
            if mc_tutorial.check_privs(player, mc_tutorial.recorder_priv_table) then
                mc_tutorial.record.temp[pname] = tutorials[mc_tutorial.tutorial_selected]
                mc_tutorial.record.edit[pname] = true
                if mc_tutorial.record.temp[pname] then
                    mc_tutorial.show_record_fs(player)
                end
            else
                minetest.chat_send_player(pname, "[Tutorial] You do not have sufficient privileges to edit tutorials.")
            end
        elseif fields.start then
            if mc_tutorial.tutorial_selected == nil then mc_tutorial.tutorial_selected = 1 end
            if tutorials[mc_tutorial.tutorial_selected] then
                pmeta = player:get_meta()
                pdata = minetest.deserialize(pmeta:get_string("mc_tutorial:tutorials"))
                pdata.tutorials.activeTutorial = tutorials[mc_tutorial.tutorial_selected]
                pmeta:set_string("mc_tutorial:tutorials", minetest.serialize(pdata))
                minetest.chat_send_player(pname, "[Tutorial] Tutorial has started: "..pdata.tutorials.activeTutorial.title)
                -- Check if there is an action in the sequence that requires the tutorial_progress_listener
                -- This saves us from unnecessarily burning cycles server-side
                for _,action in ipairs(pdata.tutorials.activeTutorial.sequence.action) do
                    if action == "current position" or action == "look direction" or action == "look pitch" or action == "look yaw" or action == "wield" or action == "player control" then
                        mc_tutorial.tutorial_progress_listener(player)
                    end
                end
                -- TODO: add HUD and/or formspec to display the instructions for the tutorial
            end
        end
    end
    
    -- Continue the recording with other options with on_right_click callback
    if formname == "mc_tutorial:record_options_fs" then

        -- TODO: add formspec to support recording: 
                ----- put something into or modify inventory player:get_inventory() inv:contains_item() inv:is_empty() ItemStack:get_count()
                ----- press keys player:get_player_control() or player:get_player_control_bits()
        
        --[[if mc_tutorial.check_privs(player, mc_tutorial.recorder_priv_table) and mc_tutorial.record.active[pname] then
            -- Check if the tutorial has already been instanced by another callback
            if not mc_tutorial.record.temp[pname] then
                -- this is the first entry for the tutorial, apply default values
                mc_tutorial.record.temp[pname] = mc_tutorial.get_temp_shell()
            end
        end]]

        if fields.getpos then
            local pos = player:get_pos()
            local reg_success = mc_tutorial.register_tutorial_action(player, mc_tutorial.ACTION.POS, nil, nil, pos)
            if reg_success ~= false then
                minetest.chat_send_player(pname, "[Tutorial] Your current position was recorded. Continue to record new actions or left-click the tool to end the recording.")
            else
                minetest.chat_send_player(pname, "[Tutorial] Your current position could not be recorded, please try again.")
            end
        end
        
        if fields.getlookdir then
            local dir = player:get_look_dir()
            local reg_success = mc_tutorial.register_tutorial_action(player, mc_tutorial.ACTION.LOOK_DIR, nil, nil, nil, dir)
            if reg_success ~= false then
                minetest.chat_send_player(pname, "[Tutorial] Your current look direction was recorded. Continue to record new actions or left-click the tool to end the recording.")
            else
                minetest.chat_send_player(pname, "[Tutorial] Your current look direction could not be recorded, please try again.")
            end
        end

        if fields.lookvertical then
            local pitch = player:get_look_vertical()
            local reg_success = mc_tutorial.register_tutorial_action(player, mc_tutorial.ACTION.LOOK_PITCH, nil, nil, nil, pitch)
            if reg_success ~= false then
                minetest.chat_send_player(pname, "[Tutorial] Your current look pitch was recorded. Continue to record new actions or left-click the tool to end the recording.")
            else
                minetest.chat_send_player(pname, "[Tutorial] Your current look pitch could not be recorded, please try again.")
            end
        end

        if fields.lookhorizontal then
            local yaw = player:get_look_horizontal()
            local reg_success = mc_tutorial.register_tutorial_action(player, mc_tutorial.ACTION.LOOK_YAW, nil, nil, nil, yaw)
            if reg_success ~= false then
                minetest.chat_send_player(pname, "[Tutorial] Your current look yaw was recorded. Continue to record new actions or left-click the tool to end the recording.")
            else
                minetest.chat_send_player(pname, "[Tutorial] Your current look yaw could not be recorded, please try again.")
            end
        end

        if fields.wieldeditem then
            -- TODO: add HUD or chat message to indicate timer
            -- TODO: possibly identify an alternative method for setting the weilded item that does not make use of a timed listener
            minetest.chat_send_player(pname, "[Tutorial] Make a selection from your inventory to set the wield item.")
            mc_tutorial.record.listener.wield[pname] = true
            return
        end

        if fields.playercontrol then
            minetest.chat_send_player(pname, "[Tutorial] Press and hold the player control keys that you want to be recorded.")
            mc_tutorial.record.listener.key[pname] = true
            return
        end

        if fields.exit then
            return
        end
    end

    -- Complete the recording
	if formname == "mc_tutorial:record_fs" then
        if fields.record_nav then
            context.tab = fields.record_nav
            save_context(player, context)
            mc_tutorial.show_record_fs(player)
        end
        --[[if fields.eventlist then
            local event = minetest.explode_textlist_event(fields.eventlist)
            if event.type == "CHG" then
                context.event_selected = event.index
            end
        end
        if fields.givetool then
            local event = minetest.explode_textlist_event(fields.givetool)
            if event.type == "CHG" then
                --mc_tutorial.selected_tool = event.index
            end
            for i,itemstring in ipairs(tools) do
                if i+1 == mc_tutorial.selected_tool then
                    mc_tutorial.record.temp[pname].on_completion.givetool = itemstring
                end
            end
        end
        if fields.giveitem then
            local event = minetest.explode_textlist_event(fields.giveitem)
            if event.type == "CHG" then
                --mc_tutorial.selected_item = event.index
            end
            for i,itemstring in ipairs(items) do
                --[[if i+1 == mc_tutorial.selected_item then
                    mc_tutorial.record.temp[pname].on_completion.giveitem = itemstring
                end
            end
        end
        if fields.grantpriv then
            local event = minetest.explode_textlist_event(fields.grantpriv)
            if event.type == "CHG" then
                --mc_tutorial.selected_priv = event.index
            end
            for i,priv in ipairs(privs) do
                if i+1 == mc_tutorial.selected_priv then
                    mc_tutorial.record.temp[pname].on_completion.grantpriv = priv
                end
            end
        end]]
        if fields.delete then
            if context.selected_event then
                table.remove(mc_tutorial.record.temp[pname].sequence.action, context.selected_event)
                table.remove(mc_tutorial.record.temp[pname].sequence.tool, context.selected_event)
                table.remove(mc_tutorial.record.temp[pname].sequence.node, context.selected_event)
                table.remove(mc_tutorial.record.temp[pname].sequence.pos, context.selected_event)
                table.remove(mc_tutorial.record.temp[pname].sequence.dir, context.selected_event)
                table.remove(mc_tutorial.record.temp[pname].sequence.key, context.selected_event)
                mc_tutorial.record.temp[pname].length = mc_tutorial.record.temp[pname].length - 1
                mc_tutorial.show_record_fs(player)
            end
        end
        if fields.finish then
            if mc_tutorial.record.temp[pname] then
                if mc_tutorial.record.temp[pname].length > 0 then
                    -- debug
                    minetest.log(minetest.serialize(mc_tutorial.record.temp[pname]))

                    tutorialTitle = (fields.title ~= "" and fields.title) or "Untitled"
                    tutorialDescription = (fields.description ~= "" and fields.description) or "No description provided" 
                    tutorialMessage = (fields.message ~= "" and fields.message) or "You completed the tutorial!"
                    
                    -- Quick check to make sure we are not writing invalid entries on_completion
                    if mc_tutorial.record.temp[pname].on_completion.givetool == "None" and mc_tutorial.record.temp[pname].on_completion.givetool == "" then
                        mc_tutorial.record.temp[pname].on_completion.giveitem = nil
                    end
                    if mc_tutorial.record.temp[pname].on_completion.giveitem == "None" and mc_tutorial.record.temp[pname].on_completion.giveitem == "" then
                        mc_tutorial.record.temp[pname].on_completion.giveitem = nil
                    end
                    if mc_tutorial.record.temp[pname].on_completion.grantpriv == "None" and mc_tutorial.record.temp[pname].on_completion.grantpriv == "" then
                        mc_tutorial.record.temp[pname].on_completion.grantpriv = nil
                    end

                    -- Build the tutorial table to send to mod storage
                    local recordTutorial = {
                        tutorialDependency = {}, -- table of tutorialIDs that must be compeleted before the player can attempt this tutorial
                        title = tutorialTitle,
                        length = mc_tutorial.record.temp[pname].length,
                        searchIndex = 1, -- default search always starts on the first element in the sequence
                        continueTutorial = true, -- default starting state of tutorial is true to automatically continue
                        completed = 0, -- default completed actions starts at zero
                        description = tutorialDescription,
                        sequence = {
                            action = mc_tutorial.record.temp[pname].sequence.action,
                            tool = mc_tutorial.record.temp[pname].sequence.tool,
                            node = mc_tutorial.record.temp[pname].sequence.node,
                            pos = mc_tutorial.record.temp[pname].sequence.pos,
                            dir = mc_tutorial.record.temp[pname].sequence.dir,
                            key = mc_tutorial.record.temp[pname].sequence.key,
                            actionMessage = {} -- table of strings displayed to player when an action is completed
                        },
                        on_completion = {
                            message = tutorialMessage,
                            givetool = mc_tutorial.record.temp[pname].on_completion.givetool,
                            giveitem = mc_tutorial.record.temp[pname].on_completion.giveitem,
                            grantpriv = mc_tutorial.record.temp[pname].on_completion.grantpriv
                        }
                    }

                    -- Send to mod storage
                    local tutorials = minetest.deserialize(mc_tutorial.tutorials:get_string("mc_tutorial:tutorials"))
                    if tutorials == nil or next(tutorials) == nil then
                        local tutorials = {}
                        table.insert(tutorials, recordTutorial)
                        mc_tutorial.tutorials:set_string("mc_tutorial:tutorials", minetest.serialize(tutorials))
                    else
                        if mc_tutorial.record.edit[pname] then
                            -- We are editing an existing tutorial
                            tutorials[mc_tutorial.tutorial_selected] = recordTutorial
                        else
                            -- We are apending a new tutorial
                            table.insert(tutorials, recordTutorial)
                        end
                        mc_tutorial.tutorials:set_string("mc_tutorial:tutorials", minetest.serialize(tutorials))
                    end
                    minetest.chat_send_player(pname, "[Tutorial] Your tutorial was successfully recorded!")
                else
                    minetest.chat_send_player(pname, "[Tutorial] No tutorial was recorded.")
                end

                -- Ensure global tutorialTemp is recycled
                mc_tutorial.record.temp[pname] = nil
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
    pdata = minetest.deserialize(pmeta:get_string("mc_tutorial:tutorials"))
    pdata.tutorials.activeTutorial.continueTutorial = false
    pmeta:set_string("mc_tutorial:tutorials", minetest.serialize(pdata))
end)

-- TODO: other possible callbacks
--minetest.register_allow_player_inventory_action(function(player, action, inventory, inventory_info))
--minetest.register_on_craft(func(itemstack, player, old_craft_grid, craft_inv))
--minetest.register_on_receiving_chat_messages(function(message))

-- below commands for debugging only
-- consider consolidating into single tutorial command with subcommand options or removing
minetest.register_chatcommand("clearTutorials", {
	description = "Clear all tutorials from mod storage.",
	privs = mc_tutorial.recorder_priv_table,
	func = function(name, param)
        mc_tutorial.tutorials:set_string("mc_tutorial:tutorials", nil)
        minetest.chat_send_all("[Tutorial] All tutorials have been cleared from memory.")
	end
})

minetest.register_chatcommand("listTutorials", {
	description = "List titles of all stored tutorials.",
	privs = mc_tutorial.recorder_priv_table,
	func = function(name, param)
        local tutorials = minetest.deserialize(mc_tutorial.tutorials:get_string("mc_tutorial:tutorials"))
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
	privs = mc_tutorial.recorder_priv_table,
	func = function(name, param)
        tutorials = minetest.deserialize(mc_tutorial.tutorials:get_string("mc_tutorial:tutorials"))
        minetest.chat_send_all(tostring(_G.dump(tutorials)))
	end
})

minetest.register_chatcommand("dumppdata", {
	description = "Dumps player meta table.",
	privs = mc_tutorial.recorder_priv_table,
	func = function(name, param)
        player = minetest.get_player_by_name(name)
        pmeta = player:get_meta()
        pdata = minetest.deserialize(pmeta:get_string("mc_tutorial:tutorials"))
        minetest.chat_send_all(tostring(_G.dump(pdata)))
	end
})