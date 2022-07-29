-- TODO:
----- add tutorial progress and completion to player meta
----- get/set pdata.active from player meta
----- make tutorials dependent on other tutorials (sequence of tutorials)
----- update png texture for tutorialbook - consider revising this to a new icon different from student notebook
----- add sequence of formspecs or HUD elements to guide teacher through recording different gameplay options
----- make tutorial_fs dynamic to show what a player will get on_completion: use add item_image[]
----- need a way for the player to access the pdata.active instructions and possibly accompanying item_images and models
----- update the record_fs menu so that on_completion items and tools are displayed in an inventory and the number of items given can be set by the player recording the tutorial
----- add option to display a message after completing a specific action, like "now do this next"\

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
-- local constants
local RW_LIST, RW_SELECT = 1, 2

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
mc_tutorial.check_interval = math.max(tonumber(mc_tutorial.fetch_setting("check_interval")), 0.1) or 1
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
    local pmeta = player:get_meta()
    local pdata = minetest.deserialize(pmeta:get_string("mc_tutorial:tutorials"))
    if not pdata or not next(pdata) or not pdata.format or pdata.format ~= 3 then
        -- data not initialized, initialize and serialize a table to hold everything
        pdata = {
            active = {},
            player_seq = {},
            completed = {}, -- TODO: use this to change the tutorial_fs to indicate tutorials that are completed
            listener = {
                wield = false,
                key = false
            },
            format = 3
        }
        pmeta:set_string("mc_tutorial:tutorials", minetest.serialize(pdata))
    end
end)

local function save_temp_fields(player, fields)
    local pname = player:get_player_name()
    mc_tutorial.record.temp[pname].title = fields.title or mc_tutorial.record.temp[pname].title
    mc_tutorial.record.temp[pname].description = fields.description or mc_tutorial.record.temp[pname].description
    mc_tutorial.record.temp[pname].on_completion.message = fields.message or mc_tutorial.record.temp[pname].on_completion.message
end

local function get_reward_desc(type_id, item)
    if not type_id or not item then
        return minetest.formspec_escape("No reward selected!")
    end

    local desc = ""
    if type_id == "P" then
        desc = minetest.registered_privileges[item] and minetest.registered_privileges[item].description or ""
    elseif ItemStack(item):is_known() then
        local stack = ItemStack(item)
        desc = stack:get_description() or stack:get_short_description()
    end
    return minetest.formspec_escape(item).."\n"..desc
end

local function get_selected_reward_info(context, list_id)
    local pattern = "(.-)"..string.gsub(minetest.formspec_escape("["), "%[", "%%%[").."(%w)"..string.gsub(minetest.formspec_escape("]"), "%]", "%%%]").."(.*)"
    local selection = context.reward_selected[list_id]
    local col, type_id, item = string.match(list_id == RW_LIST and context.rewards[selection] or list_id == RW_SELECT and context.selected_rewards[selection] or "", pattern)
    return col and mc_helpers.trim(col), type_id and mc_helpers.trim(type_id), item and mc_helpers.trim(item)
end

function mc_tutorial.show_record_fs(player)
    local pname = player:get_player_name()
	if mc_tutorial.check_privs(player, mc_tutorial.recorder_priv_table) then
        -- Tutorial formspec for recording a tutorial
        local context = get_context(pname)
        local temp = mc_tutorial.record.temp[pname] or {}

        -- Get all recorded events
        if not context.events then
            local events = {}
            local action_map = {
                [mc_tutorial.ACTION.PUNCH] = function(event)
                    return "punch node "..(event.node or "[?]")..(event.tool and event.tool ~= "" and " with "..event.tool or "")
                end,
                [mc_tutorial.ACTION.DIG] = function(event)
                    return "dig node "..(event.node or "[?]")..(event.tool and event.tool ~= "" and " with "..event.tool or "")
                end,
                [mc_tutorial.ACTION.PLACE] = function(event)
                    return "place node "..(event.node or "[?]")..(event.tool and event.tool ~= "" and " while wielding "..event.tool or "")
                end,
                [mc_tutorial.ACTION.WIELD] = function(event)
                    return "wield "..(event.tool and (event.tool == "" and "nothing" or event.tool) or "[?]")
                end,
                [mc_tutorial.ACTION.KEY] = function(event)
                    return "press key"..(event.key and (#event.key > 1 and "s " or " ")..table.concat(event.key, " + ") or " [?]")
                end,
                [mc_tutorial.ACTION.LOOK_YAW] = function(event)
                    return "look at yaw (horizontal) "..(event.dir and math.deg(event.dir).."°" or "[?]")
                end,
                [mc_tutorial.ACTION.LOOK_PITCH] = function(event)
                    return "look at pitch (vertical) "..(event.dir and math.deg(event.dir).."°" or "[?]")
                end,
                [mc_tutorial.ACTION.LOOK_DIR] = function(event)
                    -- directional vector: simplify representation?
                    local yaw_vect = event.dir and vector.new(event.dir.x, 0, event.dir.z)
                    local yaw = math.deg(vector.angle(vector.new(0, 0, 1), yaw_vect or vector.new(0, 0, 1)))
                    return "look in direction "..(event.dir and "(yaw = "..(math.sign(yaw_vect.x) == -1 and (360 - yaw) or yaw).."°, pitch = "..math.sign(event.dir.y)*math.deg(vector.angle(event.dir, yaw_vect)).."°)" or "[?]")
                end,
                [mc_tutorial.ACTION.POS] = function(event)
                    return "go to position "..(event.pos and "(x = "..event.pos.x..", y = "..event.pos.y..", z = "..event.pos.z..")" or "[?]")
                end,
            }
            for i,event in ipairs(mc_tutorial.record.temp[pname].sequence) do
                if event.action then
                    table.insert(events, minetest.formspec_escape(action_map[event.action](event)))
                end
            end
            context.events = events
        end

        -- Get all available rewards
        if not context.rewards then
            local rewards = {}
            local selected_rewards = {}
            for priv,_ in pairs(minetest.registered_privileges) do
                if mc_helpers.tableHas(mc_tutorial.record.temp[pname].on_completion.privs, priv) then
                    table.insert(selected_rewards, "#FFCCFF"..minetest.formspec_escape("[P] "..priv))
                else
                    table.insert(rewards, "#FFCCFF"..minetest.formspec_escape("[P] "..priv))
                end
            end

            local item_map = {
                ["tool"] = "#CCFFFF"..minetest.formspec_escape("[T] "),
                ["node"] = "#CCFFCC"..minetest.formspec_escape("[N] "),
            }
            for item,def in pairs(minetest.registered_items) do
                local item_trim = mc_helpers.trim(item)
                if item_trim ~= "" then
                    if mc_helpers.tableHas(mc_tutorial.record.temp[pname].on_completion.items, item) then
                        table.insert(selected_rewards, (item_map[def.type] or "#FFFFCC"..minetest.formspec_escape("[I] "))..item_trim)
                    else
                        table.insert(rewards, (item_map[def.type] or "#FFFFCC"..minetest.formspec_escape("[I] "))..item_trim)
                    end
                end
            end
            table.sort(rewards)
            table.sort(selected_rewards)
            context.rewards = rewards
            context.selected_rewards = selected_rewards
        end

        local tutorials = mc_tutorial.tutorials:to_table()
        local record_formtable = {
            "formspec_version[6]",
            "size[14.2,10]",
            "tabheader[0,0;record_nav;Overview,Events,Rewards", tutorials and next(tutorials.fields) and ",Dependencies" or "", ";", context.tab or "1", ";false;false]"
        }
        local tab_map = {
            ["1"] = function() -- OVERVIEW
                return {
                    "field[0.4,0.7;13.4,0.7;title;Title;", temp.title or "", "]",
                    "textarea[0.4,1.9;13.4,1.3;description;Description;", temp.description or "", "]",
                    "textarea[0.4,3.7;13.4,1.3;message;Completion message;", temp.on_completion and temp.on_completion.message or "", "]",
                    "textarea[0.4,5.5;13.4,3.2;;Tutorial summary;", minetest.formspec_escape("[TBD]"), "]",
                    "button_exit[0.4,8.8;13.4,0.8;finish;Finish and save]",
                    "tooltip[title;Title of tutorial, will be listed in the tutorial book]",
                    "tooltip[message;Message sent to chat when the player completes the tutorial]",
                    "tooltip[description;This description will be displayed in the tutorial book]",
                }
            end,
            ["2"] = function() -- EVENTS
                return { 
                    "textlist[0.4,0.8;13.4,7.3;eventlist;", table.concat(context.events, ","), ";1;false]",
                    "label[0.4,0.6;Recorded events]",
                    "image_button[0.4,8.2;1.4,1.4;mc_tutorial_add_event.png;eventlist_add_event;;false;true]",
                    "image_button[1.9,8.2;1.4,1.4;mc_tutorial_add_group.png;eventlist_add_group;;false;true]",
                    "image_button[3.4,8.2;1.4,1.4;mc_tutorial_edit.png;eventlist_edit;;false;true]",
                    "image_button[4.9,8.2;1.4,1.4;mc_tutorial_delete.png;eventlist_delete;;false;true]",
                    "image_button[6.4,8.2;1.4,1.4;mc_tutorial_duplicate.png;eventlist_duplicate;;false;true]",
                    "image_button[7.9,8.2;1.4,1.4;mc_tutorial_move_top.png;eventlist_move_top;;false;true]",
                    "image_button[9.4,8.2;1.4,1.4;mc_tutorial_move_up.png;eventlist_move_up;;false;true]",
                    "image_button[10.9,8.2;1.4,1.4;mc_tutorial_move_down.png;eventlist_move_down;;false;true]",
                    "image_button[12.4,8.2;1.4,1.4;mc_tutorial_move_bottom.png;eventlist_move_bottom;;false;true]",
                    "tooltip[eventlist_add_event;Add new event]",
                    "tooltip[eventlist_add_group;Add new group]",
                    "tooltip[eventlist_edit;Edit]",
                    "tooltip[eventlist_delete;Delete]",
                    "tooltip[eventlist_duplicate;Duplicate]",
                    "tooltip[eventlist_move_top;Move to top]",
                    "tooltip[eventlist_move_up;Move up 1]",
                    "tooltip[eventlist_move_down;Move down 1]",
                    "tooltip[eventlist_move_bottom;Move to bottom]",
                }
            end,
            ["3"] = function()
                -- TODO: limit rewards to items tutorial creator has access to in order to limit abuse?
                context.reward_selected = context.reward_selected or {[RW_LIST] = 1, [RW_SELECT] = 1, ["active"] = RW_LIST}
                local col, type_id, item = get_selected_reward_info(context, context.reward_selected["active"])

                return { -- REWARDS
                    "label[0.4,0.6;Available rewards]",
                    "label[7.5,0.6;Selected rewards]",
                    "textlist[0.4,0.8;6.3,6;reward_list;", table.concat(context.rewards, ","), ";", context.reward_selected and context.reward_selected[1] or 1, ";false]",
                    "textlist[7.5,0.8;6.3,6;reward_selection;", table.concat(context.selected_rewards, ","), ";", context.reward_selected and context.reward_selected[2] or 1, ";false]",
                    "image_button[6.7,0.8;0.8,3;mc_tutorial_reward_add.png;reward_add;;false;true]",
                    "image_button[6.7,3.8;0.8,3;mc_tutorial_reward_delete.png;reward_delete;;false;true]",
                    "field[7,7.4;4.9,0.8;reward_quantity;Quantity;1]",
                    "button[11.9,7.4;1.9,0.8;reward_quantity_update;Update]",
                    "field[7,8.8;6.8,0.8;reward_search;Search for items/privileges/nodes;]",
                    "image_button[12.2,8.8;0.8,0.8;mc_tutorial_search.png;reward_search_go;;false;false]",
                    "image_button[13,8.8;0.8,0.8;mc_tutorial_cancel.png;reward_search_x;;false;false]",
                    "label[0.4,7.2;Selected reward]",
                    type_id and type_id ~= "P" and "item_" or "", "image[0.4,7.5;2.1,2.1;", type_id and (type_id ~= "P" and item or "mc_tutorial_tutorialbook.png") or "mc_tutorial_cancel.png", "]",
                    "textarea[2.6,7.4;4.2,2.2;;;", get_reward_desc(type_id, item), "]",
                    "tooltip[reward_add;Add reward]",
                    "tooltip[reward_delete;Remove reward]",
                    "tooltip[reward_search_go;Search]",
                    "tooltip[reward_search_x;Clear search]",
                }
            end,
            ["4"] = function()
                return { -- DEPENDENCIES
                    "label[0.4,0.6;Available tutorials]",
                    "label[7.3,0.6;Dependencies]",
                    "label[7.3,5.3;Dependents]",
                    "textlist[0.4,0.8;6.5,6.5;depend_tutorials;", table.concat({}, ","), ";1;false]",
                    "textlist[7.3,0.8;6.5,3.3;dependencies;", table.concat({}, ","), ";1;false]",
                    "textlist[7.3,5.5;6.5,3.3;dependents;", table.concat({}, ","), ";1;false]",
                    "button[0.4,7.4;3.2,0.8;dependencies_add;Add dependency]",
                    "button[7.3,4.1;6.5,0.8;dependencies_delete;Delete dependency]",
                    "button[3.7,7.4;3.2,0.8;dependents_add;Add dependent]",
                    "button[7.3,8.8;6.5,0.8;dependents_delete;Delete dependent]",
                    "field[0.4,8.8;6.5,0.8;depend_search;Search for tutorials;]",
                    "image_button[5.3,8.8;0.8,0.8;mc_tutorial_search.png;depend_search_go;;false;false]",
                    "image_button[6.1,8.8;0.8,0.8;mc_tutorial_cancel.png;depend_search_x;;false;false]",
                    "tooltip[depend_search_go;Search]",
                    "tooltip[dependencies;List of tutorials that must be completed before this tutorial can be started]",
                    "tooltip[dependents;List of tutorials which can only be started after this tutorial has been completed]",
                }
            end,
        }
        table.insert(record_formtable, table.concat(tab_map[context.tab or "1"](), ""))
        save_context(player, context)

		minetest.show_formspec(pname, "mc_tutorial:record_fs", table.concat(record_formtable, ""))
		return true
	end
end

--[[
NEW FORMSPEC CLEAN COPIES

OVERVIEW TAB:
formspec_version[6]
size[14.2,10]
field[0.4,0.7;13.4,0.7;title;Title;]
textarea[0.4,1.9;13.4,1.3;description;Description;]
textarea[0.4,3.7;13.4,1.3;message;Completion message;]
textarea[0.4,5.5;13.4,3.2;;Tutorial summary;]
button_exit[0.4,8.8;13.4,0.8;finish;Finish and save]

EVENT/GROUP TAB:
formspec_version[6]
size[14.2,10]
textlist[0.4,0.8;13.4,7.3;eventlist;;1;false]
label[0.4,0.6;Recorded events]
image_button[0.4,8.2;1.4,1.4;blank.png;eventlist_add_event;;false;true]
image_button[1.9,8.2;1.4,1.4;blank.png;eventlist_add_group;;false;true]
image_button[3.4,8.2;1.4,1.4;blank.png;eventlist_edit;;false;true]
image_button[4.9,8.2;1.4,1.4;blank.png;eventlist_delete;;false;true]
image_button[6.4,8.2;1.4,1.4;blank.png;eventlist_duplicate;;false;true]
image_button[7.9,8.2;1.4,1.4;blank.png;eventlist_move_top;;false;true]
image_button[9.4,8.2;1.4,1.4;blank.png;eventlist_move_up;;false;true]
image_button[10.9,8.2;1.4,1.4;blank.png;eventlist_move_down;;false;true]
image_button[12.4,8.2;1.4,1.4;blank.png;eventlist_move_bottom;;false;true]

REWARDS TAB:
formspec_version[6]
size[14.2,10]
label[0.4,0.6;Available items/privileges to reward]
label[7.5,0.6;Selected rewards]
textlist[0.4,0.8;6.3,6;reward_list;;1;false]
textlist[7.5,0.8;6.3,6;reward_selection;;1;false]
image_button[6.7,0.8;0.8,3;blank.png;reward_add;-->;false;true]
image_button[6.7,3.8;0.8,3;blank.png;button_delete;<--;false;true]
field[7.5,7.4;4.4,0.8;reward_quantity;Quantity;1]
button[11.9,7.4;1.9,0.8;reward_quantity_update;Update]
field[7.5,8.8;6.3,0.8;reward_search;Search for items/privileges/nodes;]
image_button[12.2,8.8;0.8,0.8;blank.png;reward_search_go;Go!;false;false]
image_button[13,8.8;0.8,0.8;blank.png;reward_search_x;X;false;false]
image[0.4,7.5;2.1,2.1;blank.png]
textarea[2.6,7.4;4.2,2.2;;;This is the info text! Lorem ipsum dolor\, sit amet.]
label[0.4,7.2;Selected reward]

DEPENDENCIES TAB:
formspec_version[6]
size[14.2,10]
label[0.4,0.6;Available tutorials]
label[7.3,0.6;Dependencies (required BEFORE)]
label[7.3,5.3;Dependents (unlocked AFTER)]
textlist[0.4,0.8;6.5,6.5;depend_tutorials;;1;false]
textlist[7.3,0.8;6.5,3.3;dependencies;;1;false]
textlist[7.3,5.5;6.5,3.3;dependents;;1;false]
button[0.4,7.4;3.2,0.8;dependencies_add;Add dependency]
button[7.3,4.1;6.5,0.8;dependencies_delete;Delete selected dependency]
button[3.7,7.4;3.2,0.8;dependents_add;Add dependent]
button[7.3,8.8;6.5,0.8;dependents_delete;Delete selected dependent]
field[0.4,8.8;6.5,0.8;depend_search;Search for tutorials;]
image_button[5.3,8.8;0.8,0.8;blank.png;depend_search_go;Go!;false;false]
image_button[6.1,8.8;0.8,0.8;blank.png;depend_search_x;X;false;false]
]]

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
    local context = get_context(player)
    local tutorials = mc_tutorial.tutorials:to_table()
    local fs_core = {
        "formspec_version[5]",
        "size[13,10]",
        "button_exit[11.3,8.9;1.5,0.8;exit;Exit]"
    }
    local fs = {}
    
    local count = 1
    context.tutorial_i_to_id = {}
    if tutorials and next(tutorials.fields) then
        for id,_ in pairs(tutorials.fields) do
            if tonumber(id) then
                context.tutorial_i_to_id[count] = id
                count = count + 1
            end
        end
    end
        
    if count > 1 then
        local titles = {}
        for id,tutorial in pairs(tutorials.fields) do
            if tonumber(id) then
                local tutorial_info = minetest.deserialize(tutorial)
                table.insert(titles, tutorial_info.title)
            end
        end
        context.tutorial_selected = context.tutorial_selected or 1
        local selected_info = minetest.deserialize(tutorials.fields[tostring(context.tutorial_i_to_id[context.tutorial_selected])] or minetest.serialize(nil))
        
        fs = {
            "box[0.1,8.8;5.7,1;#00FF00]",
            "button_exit[0.2,8.9;5.5,0.8;start;Start Tutorial]",
            "textlist[0.2,0.2;4.6,8.4;tutoriallist;", table.concat(titles, ","), ";", context.tutorial_selected, ";false]",
            "textarea[5,0.2;7.8,8.4;;;", selected_info and selected_info.description or "", "]",
        }

        -- Add edit/delete options for those privileged
        if mc_tutorial.check_privs(player,mc_tutorial.recorder_priv_table) then
            table.insert(fs, "box[5.9,8.8;5.2,1;#FF0000]")
            table.insert(fs, "button[6,8.9;2.3,0.8;delete;Delete]")
            table.insert(fs, "button[8.6,8.9;2.4,0.8;edit;Edit]")
        end
    else
        fs = {"textlist[0.2,0.2;4.6,8.4;tutoriallist;No Tutorials Found;1;false]"}
    end

    local pname = player:get_player_name()
    save_context(player, context)
    minetest.show_formspec(pname, "mc_tutorial:tutorials", table.concat(fs_core, "")..table.concat(fs, ""))
    return true
end

local function move_list_item(index, from_list, to_list)
    local item_to_move = table.remove(from_list, index)
    table.insert(to_list, item_to_move)
    table.sort(to_list)
    for i,v in pairs(to_list) do
        if v == item_to_move then
            return from_list, to_list, i
        end
    end
    return from_list, to_list
end

-- REWORK
minetest.register_on_player_receive_fields(function(player, formname, fields)
    local pname = player:get_player_name()
    local context = get_context(pname)
	mc_tutorial.wait(0.05) --popups don't work without this

	-- Manage recorded tutorials
    if formname == "mc_tutorial:tutorials" then
        local tutorials = mc_tutorial.tutorials:to_table() --minetest.deserialize(mc_tutorial.tutorials:get_string("mc_tutorial:tutorials"))
        if fields.tutoriallist then
            local event = minetest.explode_textlist_event(fields.tutoriallist)
            if event.type == "CHG" then
                context.tutorial_selected = tonumber(event.index)
                save_context(player, context)
            end
            mc_tutorial.show_tutorials(player)
        elseif fields.delete then
            if mc_tutorial.check_privs(player, mc_tutorial.recorder_priv_table) then
                if tutorials and next(tutorials.fields) then
                    mc_tutorial.tutorials:set_string(context.tutorial_i_to_id[context.tutorial_selected], "")

                    context.tutorial_selected = 1
                    save_context(player, context)

                    mc_tutorial.show_tutorials(player)
                else
                    return
                end
            else
                minetest.chat_send_player(pname, "[Tutorial] You do not have sufficient privileges to delete tutorials.")
            end
        elseif fields.edit then
            if mc_tutorial.check_privs(player, mc_tutorial.recorder_priv_table) then
                mc_tutorial.record.temp[pname] = minetest.deserialize(tutorials.fields[context.tutorial_i_to_id[context.tutorial_selected]])
                mc_tutorial.record.edit[pname] = true
                if mc_tutorial.record.temp[pname] then
                    mc_tutorial.show_record_fs(player)
                end
            else
                minetest.chat_send_player(pname, "[Tutorial] You do not have sufficient privileges to edit tutorials.")
            end
        elseif fields.start then
            if tutorials and tutorials.fields[context.tutorial_i_to_id[context.tutorial_selected]] then
                pmeta = player:get_meta()
                pdata = minetest.deserialize(pmeta:get_string("mc_tutorial:tutorials"))
                local tutorial_to_start = minetest.deserialize(tutorials.fields[tostring(context.tutorial_i_to_id[context.tutorial_selected])])
                if not tutorial_to_start.format or tutorial_to_start.format ~= 3 then
                    minetest.chat_send_player(pname, "[Tutorial] This tutorial was saved in an outdated format and can no longer be accessed.")
                    return
                end

                pdata.active = tutorial_to_start
                mc_tutorial.active[pname] = tostring(context.tutorial_i_to_id[context.tutorial_selected])
                pmeta:set_string("mc_tutorial:tutorials", minetest.serialize(pdata))
                minetest.chat_send_player(pname, "[Tutorial] Tutorial has started: "..pdata.active.title)

                -- Check if there is an action in the sequence that requires the tutorial_progress_listener
                -- This saves us from unnecessarily burning cycles server-side
                local action_map = {
                    [mc_tutorial.ACTION.POS] = true,
                    [mc_tutorial.ACTION.LOOK_DIR] = true,
                    [mc_tutorial.ACTION.LOOK_PITCH] = true,
                    [mc_tutorial.ACTION.LOOK_YAW] = true,
                    [mc_tutorial.ACTION.WIELD] = true,
                    [mc_tutorial.ACTION.KEY] = true
                }
                local listener_needed = false
                for _,event in ipairs(pdata.active.sequence) do
                    listener_needed = action_map[event.action] or listener_needed
                end
                if listener_needed then
                    minetest.after(0.1, mc_tutorial.tutorial_progress_listener, player)
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
            local reg_success = mc_tutorial.register_tutorial_action(player, mc_tutorial.ACTION.POS, {pos = pos})
            if reg_success ~= false then
                minetest.chat_send_player(pname, "[Tutorial] Your current position was recorded. Continue to record new actions or left-click the tool to end the recording.")
            else
                minetest.chat_send_player(pname, "[Tutorial] Your current position could not be recorded, please try again.")
            end
        end
        
        if fields.getlookdir then
            local dir = player:get_look_dir()
            local reg_success = mc_tutorial.register_tutorial_action(player, mc_tutorial.ACTION.LOOK_DIR, {dir = dir})
            if reg_success ~= false then
                minetest.chat_send_player(pname, "[Tutorial] Your current look direction was recorded. Continue to record new actions or left-click the tool to end the recording.")
            else
                minetest.chat_send_player(pname, "[Tutorial] Your current look direction could not be recorded, please try again.")
            end
        end

        if fields.lookvertical then
            local pitch = player:get_look_vertical()
            local reg_success = mc_tutorial.register_tutorial_action(player, mc_tutorial.ACTION.LOOK_PITCH, {dir = pitch})
            if reg_success ~= false then
                minetest.chat_send_player(pname, "[Tutorial] Your current look pitch was recorded. Continue to record new actions or left-click the tool to end the recording.")
            else
                minetest.chat_send_player(pname, "[Tutorial] Your current look pitch could not be recorded, please try again.")
            end
        end

        if fields.lookhorizontal then
            local yaw = player:get_look_horizontal()
            local reg_success = mc_tutorial.register_tutorial_action(player, mc_tutorial.ACTION.LOOK_YAW, {dir = yaw})
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

        -- NAV + SELECTION
        if fields.record_nav then
            context.tab = fields.record_nav
            save_temp_fields(player, fields)
            save_context(player, context)
            mc_tutorial.show_record_fs(player)
        end
        if fields.eventlist then
            local event = minetest.explode_textlist_event(fields.eventlist)
            if event.type == "CHG" then
                context.event_selected = event.index
                save_context(player, context)
            end
        end
        if fields.reward_list then
            local event = minetest.explode_textlist_event(fields.reward_list)
            if event.type == "CHG" then
                context.reward_selected = context.reward_selected or {[RW_LIST] = 1, [RW_SELECT] = 1, ["active"] = RW_LIST}
                context.reward_selected[RW_LIST] = event.index
                context.reward_selected["active"] = RW_LIST

                save_context(player, context)
                mc_tutorial.show_record_fs(player)
            end
        end
        if fields.reward_selection then
            local event = minetest.explode_textlist_event(fields.reward_selection)
            if event.type == "CHG" then
                context.reward_selected = context.reward_selected or {[RW_LIST] = 1, [RW_SELECT] = 1, ["active"] = RW_LIST}
                context.reward_selected[RW_SELECT] = event.index
                context.reward_selected["active"] = RW_SELECT

                save_context(player, context)
                mc_tutorial.show_record_fs(player)
            end
        end

        -- BUTTONS
        if fields.reward_add and #context.rewards > 0 then
            context.reward_selected = context.reward_selected or {[RW_LIST] = 1, [RW_SELECT] = 1, ["active"] = RW_LIST}
            local col, type_id, item = get_selected_reward_info(context, RW_LIST)
            if type_id == "P" then
                table.insert(mc_tutorial.record.temp[pname].on_completion.privs, item)
            else
                table.insert(mc_tutorial.record.temp[pname].on_completion.items, item)
            end

            context.rewards, context.selected_rewards, new_index = move_list_item(context.reward_selected[RW_LIST], context.rewards, context.selected_rewards)
            context.reward_selected = {
                [RW_LIST] = math.max(1, math.min(context.reward_selected[RW_LIST], #context.rewards)),
                [RW_SELECT] = new_index,
                ["active"] = RW_SELECT
            }
            save_context(player, context)
            mc_tutorial.show_record_fs(player)
        end
        if fields.reward_delete and #context.selected_rewards > 0 then
            context.reward_selected = context.reward_selected or {[RW_LIST] = 1, [RW_SELECT] = 1, ["active"] = RW_LIST}
            local col, type_id, item = get_selected_reward_info(context, RW_SELECT)
            if type_id == "P" then
                for i,reward in pairs(mc_tutorial.record.temp[pname].on_completion.privs) do
                    if item == reward then
                        table.remove(mc_tutorial.record.temp[pname].on_completion.privs, i)
                    end
                end
            else
                for i,reward in pairs(mc_tutorial.record.temp[pname].on_completion.items) do
                    if item == reward then
                        table.remove(mc_tutorial.record.temp[pname].on_completion.items, i)
                    end
                end
            end

            context.selected_rewards, context.rewards, new_index = move_list_item(context.reward_selected[RW_SELECT], context.selected_rewards, context.rewards)
            context.reward_selected = {
                [RW_LIST] = new_index,
                [RW_SELECT] = math.max(1, math.min(context.reward_selected[RW_SELECT], #context.selected_rewards)),
                ["active"] = RW_LIST
            }
            save_context(player, context)
            mc_tutorial.show_record_fs(player)
        end

        --[[if fields.delete then
            if context.selected_event then
                table.remove(mc_tutorial.record.temp[pname].sequence, context.selected_event)
                mc_tutorial.record.temp[pname].length = mc_tutorial.record.temp[pname].length - 1
                mc_tutorial.show_record_fs(player)
            end
        end]]

        if fields.finish then
            if mc_tutorial.record.temp[pname].length > 0 then
                save_temp_fields(player, fields)

                -- Build the tutorial table to send to mod storage
                local recorded_tutorial = {
                    dependencies = mc_tutorial.record.temp[pname].dependencies or {}, -- table of tutorial IDs that must be compeleted before the player can attempt this tutorial
                    dependents = mc_tutorial.record.temp[pname].dependents or {}, -- table of tutorial IDs that completing this tutorial unlocks
                    title = (mc_tutorial.record.temp[pname].title ~= "" and mc_tutorial.record.temp[pname].title) or "Untitled",
                    length = mc_tutorial.record.temp[pname].length or 0,
                    seq_index = 1, -- default search always starts on the first element in the sequence
                    description = (mc_tutorial.record.temp[pname].description ~= "" and mc_tutorial.record.temp[pname].description) or "No description provided",
                    sequence = mc_tutorial.record.temp[pname].sequence or {},
                    on_completion = {
                        message = (mc_tutorial.record.temp[pname].on_completion.message ~= "" and mc_tutorial.record.temp[pname].on_completion.message) or "You completed the tutorial!",
                        items = mc_tutorial.record.temp[pname].on_completion.items or {},
                        privs = mc_tutorial.record.temp[pname].on_completion.privs or {}
                    },
                    format = mc_tutorial.record.temp[pname].format
                }

                -- Send to mod storage
                local tutorials = mc_tutorial.tutorials:to_table()
                if not tutorials or not next(tutorials.fields) then
                    mc_tutorial.tutorials:set_int("next_id", 2)
                    mc_tutorial.tutorials:set_string("1", minetest.serialize(recorded_tutorial))
                else
                    if mc_tutorial.record.edit[pname] then
                        -- We are editing an existing tutorial
                        mc_tutorial.tutorials:set_string(context.tutorial_i_to_id[context.tutorial_selected], minetest.serialize(recorded_tutorial))
                    else
                        -- We are appending a new tutorial
                        local next_id = mc_tutorial.tutorials:get("next_id") or 1
                        mc_tutorial.tutorials:set_string(tostring(next_id), minetest.serialize(recorded_tutorial))
                        mc_tutorial.tutorials:set_int("next_id", next_id + 1)
                    end
                end
                minetest.chat_send_player(pname, "[Tutorial] Your tutorial was successfully saved!")
            else
                minetest.chat_send_player(pname, "[Tutorial] No tutorial was saved.")
            end

            -- Ensure global temp is recycled + context is cleared
            mc_tutorial.record.temp[pname] = nil
            save_context(player, nil)
        elseif fields.quit then -- forced quit
            minetest.chat_send_player(pname, "[Tutorial] No tutorial was saved.")
            mc_tutorial.record.temp[pname] = nil
            save_context(player, nil)
        end
    end
end)

minetest.register_on_leaveplayer(function(player)
    local pname = player:get_player_name()
    local pmeta = player:get_meta()
    local pdata = minetest.deserialize(pmeta:get_string("mc_tutorial:tutorials"))
    pdata.active = nil
    pmeta:set_string("mc_tutorial:tutorials", minetest.serialize(pdata))

    mc_tutorial.active[pname] = nil
    for list,_ in pairs(mc_tutorial.record) do
        mc_tutorial.record[list][pname] = nil
    end
    mc_tutorial.record.listener.wield[pname] = nil
    mc_tutorial.record.listener.key[pname] = nil
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
        mc_tutorial.tutorials:from_table(nil) -- refactor to :set_string()
        minetest.chat_send_all("[Tutorial] All tutorials have been cleared from memory.")
	end
})

minetest.register_chatcommand("listTutorials", {
	description = "List titles of all stored tutorials.",
	privs = mc_tutorial.recorder_priv_table,
	func = function(name, param)
        local tutorials = mc_tutorial.tutorials:to_table()
        if tutorials and next(tutorials.fields) then
            minetest.chat_send_all("Recorded tutorials:")
            for k,serial_tutorial in pairs(tutorials.fields) do
                if tonumber(k) then
                    local tutorial = minetest.deserialize(serial_tutorial)
                    minetest.chat_send_player(name, "- " .. tutorial.title)
                end
            end
        else
            minetest.chat_send_player(name, "No tutorials have been recorded.")
        end
	end
})

minetest.register_chatcommand("dumpTutorials", {
	description = "Dumps mc_tutorial mod storage table.",
	privs = mc_tutorial.recorder_priv_table,
	func = function(name, param)
        local tutorials = mc_tutorial.tutorials:to_table()
        minetest.chat_send_player(name, tostring(_G.dump(tutorials)))
	end
})

minetest.register_chatcommand("dumppdata", {
	description = "Dumps player meta table.",
	privs = mc_tutorial.recorder_priv_table,
	func = function(name, param)
        local player = minetest.get_player_by_name(name)
        local pmeta = player:get_meta()
        local pdata = minetest.deserialize(pmeta:get_string("mc_tutorial:tutorials"))
        minetest.chat_send_player(name, tostring(_G.dump(pdata)))
	end
})