-- TODO:
----- add tutorial progress and completion to player meta
----- get/set pdata.active from player meta
----- update png texture for tutorialbook - consider revising this to a new icon different from student notebook
----- add sequence of formspecs or HUD elements to guide teacher through recording different gameplay options
----- make tutorial_fs dynamic to show what a player will get on_completion: use add item_image[]
----- need a way for the player to access the pdata.active instructions and possibly accompanying item_images and models
----- update the record_fs menu so that on_completion items and tools are displayed in an inventory and the number of items given can be set by the player recording the tutorial
----- add option to display a message after completing a specific action, like "now do this next"

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
    listeners = {},

    ACTION = { -- action constants
        PUNCH = 1,
        DIG = 2,
        PLACE = 3,
        WIELD = 4,
        KEY = 5,
        LOOK_YAW = 6,
        LOOK_PITCH = 7,
        LOOK_DIR = 8,
        POS_ABS = 9,
        GROUP = 10,
        -- WIP beyond this point
        POS_REL = 11, 
        MSG_CHAT = 12,
        MSG_POPUP = 13,
        INV_PUT = 14,
        INV_TAKE = 15,
        INV_MOVE = 16,
        CRAFT = 17,
        LOOK_NODE = 18,
    },
    GROUP = { -- group type constants
        START = 1,
        END = 2
    },
    EPOP_LIST = {
        NONE = 0,
        ITEM = 1,
        KEY = 2,
        NODE = 3,
    },
    DIR = {
        YAW_PITCH = 1,
        VECTOR = 2,
    }
}
-- local constants
local RW_LIST, RW_SELECT = 1, 2

local function get_context(player)
    local pname = (type(player) == "string" and player) or (player:is_player() and player:get_player_name()) or ""
    mc_tutorial.fs_context[pname] = mc_tutorial.fs_context[pname] or {
        clear = function(self)
            mc_tutorial.fs_context[pname] = nil
        end
    }
    return mc_tutorial.fs_context[pname]
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
mc_tutorial.check_dir_tolerance = math.rad(tonumber(mc_tutorial.fetch_setting("check_dir_tolerance") or 2))
mc_tutorial.check_pos_x_tolerance = tonumber(mc_tutorial.fetch_setting("check_pos_x_tolerance") or 4) * mc_tutorial.check_interval
mc_tutorial.check_pos_y_tolerance = tonumber(mc_tutorial.fetch_setting("check_pos_y_tolerance") or 4) * mc_tutorial.check_interval
mc_tutorial.check_pos_z_tolerance = tonumber(mc_tutorial.fetch_setting("check_pos_z_tolerance") or 4) * mc_tutorial.check_interval

-- Load other scripts
dofile(mc_tutorial.path .. "/functions.lua")
dofile(mc_tutorial.path .. "/tools.lua")
dofile(mc_tutorial.path .. "/callbacks.lua")
dofile(mc_tutorial.path .. "/commands.lua")

minetest.register_on_joinplayer(function(player)
    -- Load player meta
    local pmeta = player:get_meta()
    local pdata = minetest.deserialize(pmeta:get_string("mc_tutorial:tutorials"))
    if not pdata or not next(pdata) or not pdata.format or pdata.format < 3 then
        -- data not initialized, initialize and serialize a table to hold everything
        pdata = {
            active = {},
            completed = {},
            listener = {
                wield = false,
                key = false
            },
            format = 3
        }
        pmeta:set_string("mc_tutorial:tutorials", minetest.serialize(pdata))
    end
end)

-- Returns true if the id is not in the given list, false if it is
local function tutorial_id_safety_check(id, list)
    for _,l_id in pairs(list) do
        if tonumber(id) == tonumber(l_id) then
            return false
        end
    end
    return true
end

local function check_dependencies(pdata, dep_list)
    for dep,_ in pairs(dep_list) do
        if mc_tutorial.tutorials:get(dep) and not mc_helpers.tableHas(pdata.completed, dep) then
            return false
        end
    end
    return true
end

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
        desc = minetest.registered_privileges[item] and minettutorial_id_safety_checkest.registered_privileges[item].description or ""
    elseif ItemStack(item):is_known() then
        local stack = ItemStack(item)
        desc = stack:get_description() or stack:get_short_description()
    end
    return minetest.formspec_escape(item).."\n"..desc
end

local function get_selected_reward_info(context, list_id)
    local pattern = string.gsub(minetest.formspec_escape("["), "%[", "%%%[").."(%w)"..string.gsub(minetest.formspec_escape("]"), "%]", "%%%]").."(.*)"
    local selection = context.reward_selected[list_id]
    local reward = list_id == RW_LIST and context.rewards[selection] or list_id == RW_SELECT and context.selected_rewards[selection]
    local type_id, item = string.match(reward and reward.s or "", pattern)
    return reward and (reward.col_override or reward.col), type_id and mc_helpers.trim(type_id), item and mc_helpers.trim(item)
end

--- @return string or nil
local function extract_id(id_str)
    if type(id_str) == "string" then
        return string.match(id_str, "ID%s(%d+):") or nil
    else
        return nil
    end
end

--- @return boolean
local function id_compare(a, b)
    local match_a = extract_id(a)
    local match_b = extract_id(b)
    if not match_a and not match_b then
        return a < band
    elseif not match_a or not match_b then
        return match_a
    else
        return tonumber(match_a) < tonumber(match_b)
    end
end

--- @return boolean
local function col_field_compare(a, b)
    local type_a = type(a) == "table"
    local type_b = type(b) == "table"
    if (not type_a or not a.s) and (not type_b or not b.s) then
        return a < b
    elseif (not type_a or not a.s) or (not type_b or not b.s) then
        return type_a
    else
        return a.s < b.s
    end
end

-- Concatenates a list of colour fields using the given separator
local function concat_col_field_list(list, separator)
    local col_list = {}
    for i,elem in ipairs(list) do
        local string = (elem.col_override or elem.col or "")..(elem.s or "")
        table.insert(col_list, string)
    end
    return table.concat(col_list, separator)
end

local function vect_to_yp(vect)
    local yaw_vect = vect and vector.new(vect.x, 0, vect.z)
    local raw_yaw = math.deg(vector.angle(vector.new(0, 0, 1), yaw_vect or vector.new(0, 0, 1)))
    return math.sign(yaw_vect.x) == 1 and (360 - raw_yaw) or raw_yaw, vect and math.sign(vect.y) * math.deg(vector.angle(vect, yaw_vect)) or 0
end

local function yp_to_vect(yaw, pitch)
    return vector.rotate(vector.new(0, 0, 1), vector.new(math.rad(pitch or 0), math.rad(yaw or 0), 0))
end

local event_action_map = {
    [mc_tutorial.ACTION.PUNCH] = function(event)
        return nil, "punch node "..(event.node or "[?]")..(event.tool and event.tool ~= "" and " with "..event.tool or "")
    end,
    [mc_tutorial.ACTION.DIG] = function(event)
        return nil, "dig node "..(event.node or "[?]")..(event.tool and event.tool ~= "" and " with "..event.tool or "")
    end,
    [mc_tutorial.ACTION.PLACE] = function(event)
        return nil, "place node "..(event.node or "[?]")
    end,
    [mc_tutorial.ACTION.WIELD] = function(event)
        return nil, "wield "..(event.tool and (event.tool == "" and "nothing" or event.tool) or "[?]")
    end,
    [mc_tutorial.ACTION.KEY] = function(event)
        local keys = mc_tutorial.bits_to_keys(event.key_bit or 0)
        return nil, "press key"..(#keys > 1 and "s " or " ")..table.concat(keys, " + ") or " [?]"
    end,
    [mc_tutorial.ACTION.LOOK_YAW] = function(event)
        return nil, "look at yaw (horizontal) "..(event.dir and math.deg(event.dir).."°" or "[?]")
    end,
    [mc_tutorial.ACTION.LOOK_PITCH] = function(event)
        return nil, "look at pitch (vertical) "..(event.dir and math.deg(event.dir).."°" or "[?]")
    end,
    [mc_tutorial.ACTION.LOOK_DIR] = function(event)
        local yaw, pitch = vect_to_yp(event.dir)
        return nil, "look in direction "..(event.dir and "(yaw = "..yaw.."°, pitch = "..pitch.."°)" or "[?]")
    end,
    [mc_tutorial.ACTION.POS_ABS] = function(event)
        return nil, "go to position "..(event.pos and "(x = "..event.pos.x..", y = "..event.pos.y..", z = "..event.pos.z..")" or "[?]")
    end,
    [mc_tutorial.ACTION.GROUP] = function(event)
        if event.g_type == mc_tutorial.GROUP.START then
            return "#CCFFFF", "GROUP "..(event.g_id or "[?]").." {"
        else
            return "#CCFFFF", "} END GROUP "..(event.g_id or "[?]")
        end
    end,
}

function mc_tutorial.show_record_fs(player)
    local pname = player:get_player_name()
	if mc_tutorial.check_privs(player, mc_tutorial.recorder_priv_table) then
        -- Tutorial formspec for recording a tutorial
        local context = get_context(pname)
        mc_tutorial.record.temp[pname] = mc_tutorial.record.temp[pname] or mc_tutorial.get_temp_shell()
        local temp = mc_tutorial.record.temp[pname]

        -- Get all recorded events
        if not context.events then
            local events = {}
            for i,event in ipairs(temp.sequence) do
                if event.action then
                    local col, event_string = event_action_map[event.action](event)
                    table.insert(events, (col or "")..minetest.formspec_escape(event_string or ""))
                else
                    table.insert(events, "#FFCCCC"..minetest.formspec_escape("[?]"))
                end
            end
            context.events = events
        end

        -- Get all available rewards
        if not context.rewards then
            local rewards = {}
            local selected_rewards = {}
            for priv,_ in pairs(minetest.registered_privileges) do
                if mc_helpers.tableHas(temp.on_completion.privs, priv) then
                    table.insert(selected_rewards, {col = "#FFCCFF", s = minetest.formspec_escape("[P] ")..priv})
                else
                    table.insert(rewards, {col = "#FFCCFF", s = minetest.formspec_escape("[P] ")..priv})
                end
            end

            local item_map = {
                ["tool"] = {col = "#CCFFFF", s_pre = minetest.formspec_escape("[T] ")},
                ["node"] = {col = "#CCFFCC", s_pre = minetest.formspec_escape("[N] ")},
            }
            for item,def in pairs(minetest.registered_items) do
                local item_trim = mc_helpers.trim(item)
                if item_trim ~= "" then
                    local raw_col_field = item_map[def.type] or {col = "#FFFFCC", s_pre = minetest.formspec_escape("[I] ")}
                    if mc_helpers.tableHas(temp.on_completion.items, item) then
                        table.insert(selected_rewards, {col = raw_col_field.col, s = raw_col_field.s_pre..item_trim})
                    else
                        table.insert(rewards, {col = raw_col_field.col, s = raw_col_field.s_pre..item_trim})
                    end
                end
            end
            table.sort(rewards, col_field_compare)
            table.sort(selected_rewards, col_field_compare)
            context.rewards = rewards
            context.selected_rewards = selected_rewards
        end

        if mc_tutorial.tutorials_exist() and not context.tutorials then
            context.tutorials = {
                i_to_t = {},
                main = {
                    selected = 1,
                    list = {}
                },
                dep_cy = {
                    selected = 1,
                    list = {}
                },
                dep_nt = {
                    selected = 1,
                    list = {}
                },
            }
            for _,id in pairs(mc_tutorial.get_storage_keys()) do
                if tonumber(id) and id ~= mc_tutorial.record.edit[pname] then
                    local tut = minetest.deserialize(mc_tutorial.tutorials:get(tostring(id)))
                    if mc_helpers.tableHas(temp.dependencies, id) then
                        table.insert(context.tutorials.dep_cy.list, "ID "..id..": "..tut.title)
                    elseif mc_helpers.tableHas(temp.dependents, id) then
                        table.insert(context.tutorials.dep_nt.list, "ID "..id..": "..tut.title)
                    else
                        table.insert(context.tutorials.main.list, "ID "..id..": "..tut.title)
                    end
                end
            end
        end

        local record_formtable = {
            "formspec_version[6]",
            "size[14.2,10]",
            "tabheader[0,0;record_nav;Overview,Events,Rewards", mc_tutorial.tutorials_exist() and ",Dependencies" or "", ";", context.tab or "1", ";false;false]"
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
                    "textlist[0.4,0.8;13.4,7.3;eventlist;", table.concat(context.events, ","), ";", context.selected_event or 1, ";false]",
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
                    "textlist[0.4,0.8;6.3,6;reward_list;", concat_col_field_list(context.rewards, ","), ";", context.reward_selected and context.reward_selected[1] or 1, ";false]",
                    "textlist[7.5,0.8;6.3,6;reward_selection;", concat_col_field_list(context.selected_rewards, ","), ";", context.reward_selected and context.reward_selected[2] or 1, ";false]",
                    "image_button[6.7,0.8;0.8,3;mc_tutorial_reward_add.png;reward_add;;false;true]",
                    "image_button[6.7,3.8;0.8,3;mc_tutorial_reward_delete.png;reward_delete;;false;true]",
                    "field[7,7.4;4.9,0.8;reward_quantity;Quantity (WIP);1]",
                    "field_close_on_enter[reward_quantity;false]",
                    --"button[11.9,7.4;1.9,0.8;reward_quantity_update;Update]",
                    "field[7,8.8;6.8,0.8;reward_search;Search for items/privileges/nodes (WIP);]",
                    "field_close_on_enter[depend_search;false]",
                    --"image_button[12.2,8.8;0.8,0.8;mc_tutorial_search.png;reward_search_go;;false;false]",
                    --"image_button[13,8.8;0.8,0.8;mc_tutorial_cancel.png;reward_search_x;;false;false]",
                    "label[0.4,7.2;Selected reward]",
                    type_id and type_id ~= "P" and "item_" or "", "image[0.4,7.5;2.1,2.1;", type_id and (type_id ~= "P" and item or "mc_tutorial_tutorialbook.png") or "mc_tutorial_cancel.png", "]",
                    "textarea[2.6,7.4;4.2,2.2;;;", get_reward_desc(type_id, item), "]",
                    "tooltip[reward_add;Add reward]",
                    "tooltip[reward_delete;Remove reward]",
                    --"tooltip[reward_search_go;Search]",
                    --"tooltip[reward_search_x;Clear search]",
                }
            end,
            ["4"] = function()
                table.sort(context.tutorials.main.list, id_compare)
                table.sort(context.tutorials.dep_cy.list, id_compare)
                table.sort(context.tutorials.dep_nt.list, id_compare)

                return { -- DEPENDENCIES
                    "label[0.4,0.6;Available tutorials]",
                    "label[7.3,0.6;Dependencies]",
                    "label[7.3,5.3;Dependents]",
                    "textlist[0.4,0.8;6.5,6.5;depend_tutorials;", table.concat(context.tutorials.main.list, ","), ";", context.tutorials.main.selected or 1, ";false]",
                    "textlist[7.3,0.8;6.5,3.3;dependencies;", table.concat(context.tutorials.dep_cy.list, ","), ";", context.tutorials.dep_cy.selected or 1, ";false]",
                    "textlist[7.3,5.5;6.5,3.3;dependents;", table.concat(context.tutorials.dep_nt.list, ","), ";", context.tutorials.dep_nt.selected or 1, ";false]",
                    "button[0.4,7.4;3.2,0.8;dependencies_add;Add dependency]",
                    "button[7.3,4.1;6.5,0.8;dependencies_delete;Delete dependency]",
                    "button[3.7,7.4;3.2,0.8;dependents_add;Add dependent]",
                    "button[7.3,8.8;6.5,0.8;dependents_delete;Delete dependent]",
                    "field[0.4,8.8;6.5,0.8;depend_search;Search for tutorials (WIP);]",
                    "field_close_on_enter[depend_search;false]",
                    --"image_button[5.3,8.8;0.8,0.8;mc_tutorial_search.png;depend_search_go;;false;false]",
                    --"image_button[6.1,8.8;0.8,0.8;mc_tutorial_cancel.png;depend_search_x;;false;false]",
                    --"tooltip[depend_search_go;Search]",
                    --"tooltip[depend_search_x;Clear]",
                    "tooltip[dependencies;List of tutorials that must be completed before this tutorial can be started]",
                    "tooltip[dependents;List of tutorials which can only be started after this tutorial has been completed]",
                }
            end,
        }
        table.insert(record_formtable, table.concat(tab_map[context.tab or "1"](), ""))
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
        "formspec_version[6]",
        "size[11.4,8.3]",
        "label[3.5,0.6;What would you like to do?]",
        "box[0.4,1.1;10.6,4.7;#0090a0]",
        "box[0.4,6.2;10.6,1.7;#9040a0]",
        "label[3.9,1.5;Add an Action or Event]",
        "button_exit[0.6,1.8;5,0.8;wieldeditem;Wield an item]",
        "button_exit[5.8,1.8;5,0.8;playercontrol;Press keys]",
        "button_exit[0.6,2.8;5,0.8;getpos;Go to current position]",
        "button_exit[5.8,2.8;5,0.8;getlookdir;Look in current direction]",
        "button_exit[0.6,3.8;5,0.8;lookvertical;Look in current vertical dir.]",
        "button_exit[5.8,3.8;5,0.8;lookhorizontal;Look in current horizontal dir.]",
        "button[3.2,4.8;5,0.8;editor;Add action/event using editor]",
        "label[4.6,6.6;Other Options]",
        "button_exit[0.6,6.9;5,0.8;exit;Cancel]",
        "button_exit[5.8,6.9;5,0.8;stop;End recording]"
    }
    local pname = player:get_player_name()
	minetest.show_formspec(pname, "mc_tutorial:record_options_fs", table.concat(record_options_fs, ""))
	return true
end

--[[
OPTIONS CLEAN COPY

formspec_version[6]
size[11.4,8.3]
label[3.5,0.6;What would you like to do?]
box[0.4,6.2;10.6,1.7;#9040a0]
box[0.4,1.1;10.6,4.7;#0090a0]
label[3.9,1.5;Add an Action or Event]
button_exit[0.6,1.8;5,0.8;wieldeditem;Wield an item]
button_exit[5.8,1.8;5,0.8;playercontrol;Press keys]
button_exit[0.6,2.8;5,0.8;getpos;Go to current position]
button_exit[5.8,2.8;5,0.8;getlookdir;Look in current direction]
button_exit[0.6,3.8;5,0.8;lookvertical;Look in current vertical dir.]
button_exit[5.8,3.8;5,0.8;lookhorizontal;Look in current horizontal dir.]
button[3.2,4.8;5,0.8;editor;Add action/event using editor]
label[4.6,6.6;Other Options]
button_exit[0.6,6.9;5,0.8;exit;Cancel]
button_exit[5.8,6.9;5,0.8;stop;End recording]

label[0.4,2.7;Available items]
textlist[0.4,2.9;5.8,4.7;epop_list;;1;false]
image[6.4,6.4;1.2,1.2;]
textarea[7.7,6.3;4.6,1.3;;;Item + desc]
field[6.4,2.9;5.8,0.8;node;Punch (node);]
field[6.4,4.2;5.8,0.8;tool;With (item);]
image_button[11.4,2.9;0.8,0.8;mc_tutorial_add_event.png;node_import;;false;true]
image_button[11.4,4.2;0.8,0.8;mc_tutorial_add_event.png;tool_import;;false;true]
]]

function mc_tutorial.show_event_popup_fs(player, is_edit, is_iso)
    local pname = player:get_player_name()
	if mc_tutorial.check_privs(player, mc_tutorial.recorder_priv_table) then
        -- Event popup for adding/editing events in a tutorial
        local context = get_context(pname)

        local action_map = {
            [mc_tutorial.ACTION.PUNCH] = {
                name = "Punch a node",
                list_mode = mc_tutorial.EPOP_LIST.ITEM,
                modifies_world = false,
                fs_elem = function()
                    return {
                        "label[0.4,2.7;Registered items]",
                        "textlist[0.4,2.9;5.8,4.8;epop_list;", table.concat(context.epop.list.list, ","), ";", context.epop.list.selected or 1, ";false]",
                        "image[6.4,6.5;1.2,1.2;mc_tutorial_tutorialbook.png]",
                        "textarea[7.7,6.4;4.6,1.3;;;Item + desc]",
                        "field[6.4,2.9;5.8,0.8;node;Punch (node);", context.epop.fields.node or "", "]",
                        "field[6.4,4.2;5.8,0.8;tool;With (item);", context.epop.fields.tool or "", "]",
                        "image_button[11.1,2.9;1.1,0.8;mc_tutorial_paste.png;node_import;;false;false]",
                        "image_button[11.1,4.2;1.1,0.8;mc_tutorial_paste.png;tool_import;;false;false]",
                        "field_close_on_enter[node;false]",
                        "field_close_on_enter[tool;false]",
                        "tooltip[node_import;Paste selected]",
                        "tooltip[tool_import;Paste selected]"
                    }
                end,
            },
            [mc_tutorial.ACTION.DIG] = {
                name = "Dig a node",
                list_mode = mc_tutorial.EPOP_LIST.ITEM,
                modifies_world = true,
                fs_elem = function()
                    return {
                        "label[0.4,2.7;Registered items]",
                        "textlist[0.4,2.9;5.8,4.8;epop_list;", table.concat(context.epop.list.list, ","), ";", context.epop.list.selected or 1, ";false]",
                        "image[6.4,6.5;1.2,1.2;mc_tutorial_tutorialbook.png]",
                        "textarea[7.7,6.4;4.6,1.3;;;Item + desc]",
                        "field[6.4,2.9;5.8,0.8;node;Dig (node);", context.epop.fields.node or "", "]",
                        "field[6.4,4.2;5.8,0.8;tool;With (item);", context.epop.fields.tool or "", "]",
                        "image_button[11.1,2.9;1.1,0.8;mc_tutorial_paste.png;node_import;;false;false]",
                        "image_button[11.1,4.2;1.1,0.8;mc_tutorial_paste.png;tool_import;;false;false]",
                        "field_close_on_enter[node;false]",
                        "field_close_on_enter[tool;false]",
                        "tooltip[node_import;Paste selected]",
                        "tooltip[tool_import;Paste selected]"
                    }
                end,
            },
            [mc_tutorial.ACTION.PLACE] = {
                name = "Place a node",
                list_mode = mc_tutorial.EPOP_LIST.NODE,
                modifies_world = true,
                fs_elem = function()
                    return {
                        "label[0.4,2.7;Registered nodes]",
                        "textlist[0.4,2.9;5.8,4.8;epop_list;", table.concat(context.epop.list.list, ","), ";", context.epop.list.selected or 1, ";false]",
                        "image[6.4,6.5;1.2,1.2;mc_tutorial_tutorialbook.png]",
                        "textarea[7.7,6.4;4.6,1.3;;;Node + desc]",
                        "field[6.4,2.9;5.8,0.8;node;Place (node);", context.epop.fields.node or "", "]",
                        "image_button[11.1,2.9;1.1,0.8;mc_tutorial_paste.png;node_import;;false;false]",
                        "field_close_on_enter[node;false]",
                        "tooltip[node_import;Paste selected]",
                    }
                end,
            },
            [mc_tutorial.ACTION.WIELD] = {
                name = "Wield an item",
                list_mode = mc_tutorial.EPOP_LIST.ITEM,
                modifies_world = false,
                fs_elem = function()
                    return {
                        "label[0.4,2.7;Registered items]",
                        "textlist[0.4,2.9;5.8,4.8;epop_list;", table.concat(context.epop.list.list, ","), ";", context.epop.list.selected or 1, ";false]",
                        "image[6.4,6.5;1.2,1.2;mc_tutorial_tutorialbook.png]",
                        "textarea[7.7,6.4;4.6,1.3;;;Item + desc]",
                        "field[6.4,2.9;5.8,0.8;tool;Wield (item);", context.epop.fields.tool or "", "]",
                        "image_button[11.1,2.9;1.1,0.8;mc_tutorial_paste.png;tool_import;;false;false]",
                        "field_close_on_enter[tool;false]",
                        "tooltip[tool_import;Paste selected]"
                    }
                end,
            },
            [mc_tutorial.ACTION.KEY] = {
                name = "Press keys",
                list_mode = mc_tutorial.EPOP_LIST.KEY,
                modifies_world = false,
                fs_elem = function()
                    local keys = context.epop.fields.key or {}
                    return {
                        "label[0.4,2.7;Available keys]",
                        "textlist[0.4,2.9;5.58,4.8;epop_list;", table.concat(context.epop.list.list, ","), ";", context.epop.list.selected or 1, ";false]",
                        "label[6.7,2.7;Keys to press]",
                        "textlist[6.62,2.9;5.58,4.8;key_list;", next(keys) and table.concat(keys, ",") or minetest.formspec_escape("[none]"), ";", context.epop.fields.key_selected or 1, ";false]",
                        "image_button[5.98,2.9;0.64,2.4;mc_tutorial_reward_add.png;key_add;;false;true]",
                        "image_button[5.98,5.3;0.64,2.4;mc_tutorial_reward_delete.png;key_delete;;false;true]",
                        "tooltip[key_add;Add key]",
                        "tooltip[key_delete;Remove key]"
                    }
                end,
            },
            [mc_tutorial.ACTION.LOOK_YAW] = {
                name = "Look in a horizontal direction",
                list_mode = mc_tutorial.EPOP_LIST.NONE,
                modifies_world = false,
                fs_elem = function()
                    return {
                        "textarea[0.4,2.9;5.9,4.8;;Yaw/pitch info;",
                        "\nYaw: horizontal azimuth/heading, in degrees.\n(0 ≤ yaw < 360)\n",
                        "\nPitch: vertical inclination, in degrees.\n(-90 < pitch < 90)",
                        "]",
                        "field[6.4,2.9;5.8,0.8;yaw;Yaw (horizontal degrees);", context.epop.fields.yaw or "", "]",
                        "field_close_on_enter[yaw;false]",
                    }
                end,
            },
            [mc_tutorial.ACTION.LOOK_PITCH] = {
                name = "Look in a vertical direction",
                list_mode = mc_tutorial.EPOP_LIST.NONE,
                modifies_world = false,
                fs_elem = function()
                    return {
                        "textarea[0.4,2.9;5.9,4.8;;Yaw/pitch info;",
                        "\nYaw: horizontal azimuth/heading, in degrees.\n(0 ≤ yaw < 360)\n",
                        "\nPitch: vertical inclination, in degrees.\n(-90 < pitch < 90)",
                        "]",
                        "field[6.4,2.9;5.8,0.8;pitch;Pitch (vertical degrees);", context.epop.fields.pitch or "", "]",
                        "field_close_on_enter[pitch;false]",
                    }
                end,
            },
            [mc_tutorial.ACTION.LOOK_DIR] = {
                name = "Look in a direction",
                list_mode = mc_tutorial.EPOP_LIST.NONE,
                modifies_world = false,
                fs_elem = function()
                    local input_map = {
                        [mc_tutorial.DIR.YAW_PITCH] = {
                            name = "Yaw/pitch",
                            get = function()
                                local yaw, pitch
                                if context.epop.fields.dir then
                                    yaw, pitch = vect_to_yp(context.epop.fields.dir)
                                end
                                return table.concat({
                                    "field[6.4,4.1;5.8,0.8;dir_yaw;Yaw (horizontal degrees);", yaw or "", "]",
                                    "field[6.4,5.4;5.8,0.8;dir_pitch;Pitch (vertical degrees);", pitch or "", "]",
                                    "field_close_on_enter[dir_yaw;false]",
                                    "field_close_on_enter[dir_pitch;false]",
                                })
                            end,
                        },
                        [mc_tutorial.DIR.VECTOR] = {
                            name = "Spatial vector",
                            get = function()
                                return table.concat({
                                    "label[6.4,4.2;X =]",
                                    "label[6.4,5.1;Y =]",
                                    "label[6.4,6.0;Z =]",
                                    "field[7,3.8;5.2,0.8;dir_x;;", context.epop.fields.dir and context.epop.fields.dir.x or "", "]",
                                    "field[7,4.7;5.2,0.8;dir_y;;", context.epop.fields.dir and context.epop.fields.dir.y or "", "]",
                                    "field[7,5.6;5.2,0.8;dir_z;;", context.epop.fields.dir and context.epop.fields.dir.z or "", "]",
                                    "field_close_on_enter[dir_x;false]",
                                    "field_close_on_enter[dir_y;false]",
                                    "field_close_on_enter[dir_z;false]",
                                })
                            end,
                        },
                    }
                    local input_types = {}
                    for i,data in ipairs(input_map) do
                        input_types[i] = data.name
                    end

                    context.epop.d_input_type = context.epop.d_input_type or 1
                    return {
                        "textarea[0.4,2.9;5.9,4.8;;Input types;",
                        "\nYaw/pitch\n", "Yaw (horizontal azimuth/heading) and pitch (vertical inclination) in degrees.\n(0 ≤ yaw < 360, -90 < pitch < 90)\n",
                        "\nSpatial vector\n", "Direction of a 3D vector with components (X, Y, Z).",
                        "]",
                        "label[6.4,2.7;Selected input type]",
                        "dropdown[6.4,2.9;5.8,0.7;dir_type;", table.concat(input_types, ",") , ";", context.epop.d_input_type, ";true]",
                        input_map[context.epop.d_input_type] and input_map[context.epop.d_input_type].get() or "",
                    }
                end,
            },
            [mc_tutorial.ACTION.POS_ABS] = {
                name = "Go to a world position",
                list_mode = mc_tutorial.EPOP_LIST.NONE,
                modifies_world = false,
                fs_elem = function()
                    return {
                        "textarea[0.4,2.9;5.9,4.8;;Position info;",
                        "\nEach position is an absolute world position with 3 coordinates (X, Y, Z). You can view your position by pressing F5.\n",
                        "NOTE: In order for a player to complete a tutorials with a position action, they must go to the exact world position specified. This means that players completing these tutorials must have access to the realms the tutorials were recorded in.",
                        "]",
                        "label[6.4,2.9;X =]",
                        "label[6.4,3.8;Y =]",
                        "label[6.4,4.7;Z =]",
                        "field[7,2.5;5.2,0.8;pos_x;;", context.epop.fields.pos and context.epop.fields.pos.x or "", "]",
                        "field[7,3.4;5.2,0.8;pos_y;;", context.epop.fields.pos and context.epop.fields.pos.y or "", "]",
                        "field[7,4.3;5.2,0.8;pos_z;;", context.epop.fields.pos and context.epop.fields.pos.z or "", "]",
                        "button[6.3,5.3;5.9,0.8;pos_import_curr;Use current position]",
                        "field_close_on_enter[pos_x;false]",
                        "field_close_on_enter[pos_y;false]",
                        "field_close_on_enter[pos_z;false]",
                    }
                end,
            },
        }

        if not context.epop then
            context.epop = {
                is_edit = is_edit or false,
                is_iso = is_iso or false,
                selected = 1,
                actions = {},
                i_to_action = {},
                fields = {},
                list = {
                    list = {},
                    mode = mc_tutorial.EPOP_LIST.NONE,
                    selected = 1
                },
            }

            for k,data in pairs(action_map) do
                if not data.modifies_world or not minetest.is_protected(player:get_pos(), "") then
                    table.insert(context.epop.actions, data.name)
                    context.epop.i_to_action[#context.epop.actions] = k
                end
            end

            local temp = mc_tutorial.record.temp[pname]
            context.selected_event = context.selected_event or 1
            if context.epop.is_edit and temp and temp.sequence[context.selected_event] then
                -- select current event
                local edit_action = temp.sequence[context.selected_event]["action"]
                for i,k in pairs(context.epop.i_to_action) do
                    if k == edit_action then
                        context.epop.selected = i
                        break
                    end
                end

                -- populate fields
                context.epop.fields = {
                    tool = temp.sequence[context.selected_event]["tool"],
                    node = temp.sequence[context.selected_event]["node"],
                    pos = temp.sequence[context.selected_event]["pos"],
                    key = mc_tutorial.bits_to_keys(temp.sequence[context.selected_event]["key_bit"]),
                    dir = edit_action == mc_tutorial.ACTION.LOOK_DIR and temp.sequence[context.selected_event]["dir"],
                    yaw = edit_action == mc_tutorial.ACTION.LOOK_YAW and math.deg(temp.sequence[context.selected_event]["dir"] or 0),
                    pitch = edit_action == mc_tutorial.ACTION.LOOK_PITCH and math.deg(temp.sequence[context.selected_event]["dir"] or 0),
                }
            end
        end

        local epop_fs = {
            "formspec_version[6]",
            "size[12.6,8.1]",
            "box[0.4,0.4;11.8,1.7;#0090a0]",
            "label[4.5,0.8;", context.epop.edit and "Edit" or "Add", " an Action or Event]",
            "dropdown[0.6,1.2;5.6,0.7;action;", table.concat(context.epop.actions, ","), ";", context.epop.selected or 1, ";true]",
            "button", context.epop.is_iso and "_exit" or "", "[6.4,1.2;2.7,0.7;save;Save]",
            "button", context.epop.is_iso and "_exit" or "", "[9.3,1.2;2.7,0.7;cancel;Cancel]",
        }

        local action_info = action_map[context.epop.i_to_action[context.epop.selected]]
        if action_info then
            -- check if list needs to be updated
            local new_mode = action_info.list_mode or mc_tutorial.EPOP_LIST.NONE
            if new_mode ~= context.epop.list.mode then
                context.epop.list.mode = new_mode
                context.epop.list.list = {}
                context.epop.list.selected = 1

                if context.epop.list.mode == mc_tutorial.EPOP_LIST.KEY then
                    local keys_to_exclude = mc_tutorial.keys_to_bits(context.epop.fields.key or {})
                    context.epop.list.list = mc_tutorial.bits_to_keys(bit.bxor(0xFFFF, keys_to_exclude))
                elseif context.epop.list.mode == mc_tutorial.EPOP_LIST.ITEM then
                    for item,_ in pairs(minetest.registered_items) do
                        if mc_helpers.trim(item) ~= "" then
                            table.insert(context.epop.list.list, mc_helpers.trim(item))
                        end
                    end
                elseif context.epop.list.mode == mc_tutorial.EPOP_LIST.NODE then
                    for node,_ in pairs(minetest.registered_nodes) do
                        if mc_helpers.trim(node) ~= "" then
                            table.insert(context.epop.list.list, mc_helpers.trim(node))
                        end
                    end
                end
                table.sort(context.epop.list.list)
            end
            -- insert appropriate action dialog
            table.insert(epop_fs, table.concat(action_info.fs_elem()))
        end

        minetest.show_formspec(pname, "mc_tutorial:record_epop", table.concat(epop_fs, ""))
    end
end

--[[
UNIFIED:
formspec_version[6]
size[12.6,8.1]
box[0.4,0.4;11.8,1.7;#0090a0]
label[4.5,0.8;Add an Action or Event]
dropdown[0.6,1.2;5.6,0.7;action;;1;true]
button[6.4,1.2;2.7,0.7;save;Save]
button[9.3,1.2;2.7,0.7;cancel;Cancel]

label[0.4,2.7;Available items]
textlist[0.4,2.9;5.8,4.8;epop_list;;1;false]
image[6.4,6.5;1.2,1.2;]
textarea[7.7,6.4;4.6,1.3;;;Item + desc]
field[6.4,2.9;5.8,0.8;node;Punch (node);]
field[6.4,4.2;5.8,0.8;tool;With (item);]
image_button[11.4,2.9;0.8,0.8;mc_tutorial_add_event.png;node_import;;false;true]
image_button[11.4,4.2;0.8,0.8;mc_tutorial_add_event.png;tool_import;;false;true]


CONDENSED:
formspec_version[6]
size[8.4,8]
label[0.4,0.5;Event type]
dropdown[0.4,0.7;7,0.8;action;;1;true]
button[0.4,6.8;3.5,0.8;save;Save event]
button[3.9,6.8;3.5,0.8;cancel;Cancel]
button[7.8,0;0.6,8;expand_list;>]

EXPANDED:
formspec_version[6]
size[14.4,8]
label[0.4,0.5;Event type]
dropdown[0.4,0.7;7,0.8;action;;1;true]
button[0.4,6.8;3.5,0.8;save;Save event]
button[3.9,6.8;3.5,0.8;cancel;Cancel]
label[8,0.5;Available items]
textlist[8,0.7;5.4,5.5;epop_list;;1;false]
image[8,6.4;1.2,1.2;]
textarea[9.3,6.3;4.1,1.3;;;Item + desc]
box[7.675,0.2;0.05,7.6;#202020]
button[13.8,0;0.6,8;collapse_list;<]
]]

function mc_tutorial.show_tutorials(player)
    local pname = player:get_player_name()
    local pmeta = player:get_meta()
    local pdata = minetest.deserialize(pmeta:get_string("mc_tutorial:tutorials"))
    local context = get_context(player)
    local tutorial_keys = mc_tutorial.get_storage_keys()

    local fs_core = {
        "formspec_version[5]",
        "size[13,10]",
        "button_exit[11.3,8.9;1.5,0.8;exit;Exit]"
    }
    local fs = {}
    
    local count = 0
    context.tutorial_i_to_id = {}
    if mc_tutorial.tutorials_exist() then
        for _,id in pairs(tutorial_keys) do
            if tonumber(id) then
                context.tutorial_i_to_id[count + 1] = id
                count = count + 1
            end
        end
    end
        
    if count > 0 then
        local titles = {}
        for _,id in pairs(tutorial_keys) do
            if tonumber(id) then
                local col = ""
                local tutorial_info = minetest.deserialize(mc_tutorial.tutorials:get(tostring(id)))
                if mc_tutorial.active[pname] == id then
                    col = "#ACABFF"
                elseif not check_dependencies(pdata, tutorial_info.dependencies) then
                    col = "#F5627D"
                elseif mc_helpers.tableHas(pdata.completed, id) then
                    col = "#71EBA8"
                end
                table.insert(titles, col..tutorial_info.title)
            end
        end
        context.tutorial_selected = context.tutorial_selected or 1
        local selected_info = minetest.deserialize(mc_tutorial.tutorials:get(tostring(context.tutorial_i_to_id[context.tutorial_selected])) or minetest.serialize(nil))
        
        fs = {
            "textlist[0.2,0.2;4.6,8.4;tutoriallist;", table.concat(titles, ","), ";", context.tutorial_selected, ";false]",
            "textarea[5,0.2;7.8,8.4;;;", selected_info and selected_info.description or "", "]",
        }

        if mc_tutorial.active[pname] then
            if context.tutorial_i_to_id[context.tutorial_selected] == mc_tutorial.active[pname] then
                table.insert(fs, table.concat({
                    "box[0.1,8.8;5.7,1;#FF0000]",
                    "button[0.2,8.9;5.5,0.8;stop;Stop tutorial]",
                }))
            else
                table.insert(fs, table.concat({
                    "box[0.1,8.8;5.7,1;#FFBB00]",
                    "button_exit[0.2,8.9;5.5,0.8;start;Start tutorial (stops active tutorial)]",
                }))
            end
        else
            table.insert(fs, table.concat({
                "box[0.1,8.8;5.7,1;#00FF00]",
                "button_exit[0.2,8.9;5.5,0.8;start;Start tutorial]",
            }))
        end

        -- Add edit/delete options for those privileged
        if mc_tutorial.check_privs(player,mc_tutorial.recorder_priv_table) then
            if not mc_tutorial.active[pname] or context.tutorial_i_to_id[context.tutorial_selected] ~= mc_tutorial.active[pname] then
                table.insert(fs, table.concat({
                    "box[5.9,8.8;5.2,1;#FF0000]",
                    "button[6,8.9;2.3,0.8;delete;Delete]",
                    "button[8.6,8.9;2.4,0.8;edit;Edit]",
                }))
            end
        end
    else
        fs = {"textlist[0.2,0.2;4.6,8.4;tutoriallist;No Tutorials Found;1;false]"}
    end

    minetest.show_formspec(pname, "mc_tutorial:tutorials", table.concat(fs_core, "")..table.concat(fs, ""))
    return true
end

local function move_list_item(index, from_list, to_list, comp_func)
    local item_to_move = table.remove(from_list, index)
    table.insert(to_list, item_to_move)
    table.sort(to_list, comp_func or nil)
    for i,v in pairs(to_list) do
        if v == item_to_move then
            return from_list, to_list, i
        end
    end
    return from_list, to_list
end

local function shift_list_item(list, from_index, to_index)
    local shift = table.remove(list, from_index)
    if to_index then
        table.insert(list, to_index, shift)
    else
        table.insert(list, shift)
    end
end

local function event_shift_handler(pname, context, sequence, to_index)
    local limit = to_index
    local direction
    if sequence[context.selected_event].action == mc_tutorial.ACTION.GROUP then
        -- Prevent group markers from moving past other group markers
        direction = math.sign((to_index or #context.events) - context.selected_event)
        direction = direction ~= 0 and direction or 1

        for i = context.selected_event + direction, to_index or #context.events, direction do
            if sequence[i].action == mc_tutorial.ACTION.GROUP then
                limit = i - direction
                break
            end
        end
    end
    if limit ~= context.selected_event then
        shift_list_item(sequence, context.selected_event, limit)
        shift_list_item(context.events, context.selected_event, limit)
        context.selected_event = limit or #context.events
    else
        minetest.chat_send_player(pname, "[Tutorial] You can not move this group marker any "..(direction == -1 and "higher" or "lower")..".")
    end
end

local function group_parity_is_odd(selection, sequence)
    local parity = 0
    for i,action in ipairs(sequence) do
        if i >= selection then
            break
        end
        if action.action == mc_tutorial.ACTION.GROUP then
            if action.g_type == mc_tutorial.GROUP.START then
                parity = parity + 1
            elseif action.g_type == mc_tutorial.GROUP.END then
                parity = parity - 1
            end
        end
    end
    return parity ~= 0
end

local function reindex_groups(temp)
    local count = 1
    local group_map = {}
    for i,action in ipairs(temp.sequence) do
        if action.action == mc_tutorial.ACTION.GROUP then
            if not group_map[action.g_id] then
                group_map[action.g_id] = count
                count = count + 1
            end
            action.g_id = group_map[action.g_id]
        end
    end
    temp.next_group = count
end

local function reformat_tutorial(id)
    local tutorial_table = minetest.deserialize(mc_tutorial.tutorials:get(id))
    if not tutorial_table then return end

    if tutorial_table.format < 6 then
        reindex_groups(tutorial_table)
        tutorial_table.format = 6
    end
    if tutorial_table.format < 7 then
        -- old key format: update key events
        for i,action in pairs(tutorial_table.sequence) do
            if action.action == mc_tutorial.ACTION.KEY then
                action.key_bit = mc_tutorial.keys_to_bits(action.key)
                action.key = nil
            end
        end
        tutorial_table.format = 7
    end
    -- save changes to tutorial
    mc_tutorial.tutorials:set_string(id, minetest.serialize(tutorial_table))
end

-- REWORK
minetest.register_on_player_receive_fields(function(player, formname, fields)
    -- return if formspec is not tutorial-related
    if not mc_helpers.tableHas({"mc_tutorial:tutorials", "mc_tutorial:record_options_fs", "mc_tutorial:record_fs", "mc_tutorial:record_epop"}, formname) then
        return nil
    end

    local pname = player:get_player_name()
    local context = get_context(pname)
	mc_tutorial.wait(0.05) --popups don't work without this

	-- Manage recorded tutorials
    if formname == "mc_tutorial:tutorials" then
        if fields.tutoriallist then
            local event = minetest.explode_textlist_event(fields.tutoriallist)
            if event.type == "CHG" then
                context.tutorial_selected = tonumber(event.index)
            end
            mc_tutorial.show_tutorials(player)
        elseif fields.delete then
            -- TODO: add confirmation popup for delete
            if mc_tutorial.check_privs(player, mc_tutorial.recorder_priv_table) then
                if tutorial_id_safety_check(context.tutorial_i_to_id[context.tutorial_selected], mc_tutorial.active) then
                    if tutorial_id_safety_check(context.tutorial_i_to_id[context.tutorial_selected], mc_tutorial.record.edit) then
                        if mc_tutorial.tutorials_exist() then
                            mc_tutorial.tutorials:set_string(context.tutorial_i_to_id[context.tutorial_selected], "")
                            context.tutorial_selected = 1
                            mc_tutorial.show_tutorials(player)
                        else
                            return
                        end
                    else
                        minetest.chat_send_player(pname, "[Tutorial] You can't delete a tutorial that is being edited by another player.")
                    end
                else
                    minetest.chat_send_player(pname, "[Tutorial] You can't delete a tutorial that a player is currently playing.")
                end
            else
                minetest.chat_send_player(pname, "[Tutorial] You do not have sufficient privileges to delete tutorials.")
            end
        elseif fields.edit then
            if mc_tutorial.check_privs(player, mc_tutorial.recorder_priv_table) then
                if tutorial_id_safety_check(context.tutorial_i_to_id[context.tutorial_selected], mc_tutorial.active) then
                    if tutorial_id_safety_check(context.tutorial_i_to_id[context.tutorial_selected], mc_tutorial.record.edit) then
                        mc_tutorial.record.temp[pname] = minetest.deserialize(mc_tutorial.tutorials:get(context.tutorial_i_to_id[context.tutorial_selected]))
                        if mc_tutorial.record.temp[pname] and mc_tutorial.record.temp[pname].format and mc_tutorial.record.temp[pname].format >= 3 then
                            mc_tutorial.record.edit[pname] = context.tutorial_i_to_id[context.tutorial_selected]
                            mc_tutorial.record.temp[pname].has_actions = mc_tutorial.record.temp[pname].length and mc_tutorial.record.temp[pname].length > 0
                            mc_tutorial.record.temp[pname].depend_update = {dep_cy = {}, dep_nt = {}}
                            -- reformat tutorials if necessary
                            if mc_tutorial.record.temp[pname].format < mc_tutorial.get_temp_shell().format then
                                reformat_tutorial(tostring(context.tutorial_i_to_id[context.tutorial_selected]))
                                mc_tutorial.record.temp[pname] = minetest.deserialize(mc_tutorial.tutorials:get(context.tutorial_i_to_id[context.tutorial_selected]))
                            end
                            mc_tutorial.show_record_fs(player)
                        else
                            minetest.chat_send_player(pname, "[Tutorial] This tutorial could not be loaded. Please delete it and create a new one.")
                        end
                    else
                        minetest.chat_send_player(pname, "[Tutorial] You can't edit a tutorial that is being edited by another player.")
                    end
                else
                    minetest.chat_send_player(pname, "[Tutorial] You can't edit a tutorial that a player is currently playing.")
                end
            else
                minetest.chat_send_player(pname, "[Tutorial] You do not have sufficient privileges to edit tutorials.")
            end
        elseif fields.start then
            if mc_tutorial.tutorials_exist() then
                local tutorial_to_start = minetest.deserialize(mc_tutorial.tutorials:get(tostring(context.tutorial_i_to_id[context.tutorial_selected])))
                if not tutorial_to_start then
                    return minetest.chat_send_player(pname, "[Tutorial] You have not selected a valid tutorial.")
                end
                local pmeta = player:get_meta()
                local pdata = minetest.deserialize(pmeta:get_string("mc_tutorial:tutorials"))
                
                -- check format + update if necessary
                if not tutorial_to_start.format or tutorial_to_start.format < 3 then
                    return minetest.chat_send_player(pname, "[Tutorial] This tutorial was saved in an outdated format and can no longer be started.")
                elseif tutorial_to_start.format < mc_tutorial.get_temp_shell().format then
                    -- reformat tutorial, if necessary
                    reformat_tutorial(tostring(context.tutorial_i_to_id[context.tutorial_selected]))
                    tutorial_to_start = minetest.deserialize(mc_tutorial.tutorials:get(context.tutorial_i_to_id[context.tutorial_selected]))
                end

                -- check if all dependencies have been met by player
                if not check_dependencies(pdata, tutorial_to_start.dependencies) then
                    return minetest.chat_send_player(pname, "[Tutorial] You can't start this tutorial because you haven't completed all of its prerequisites!")
                end

                pdata.active = tutorial_to_start
                mc_tutorial.active[pname] = tostring(context.tutorial_i_to_id[context.tutorial_selected])
                mc_tutorial.initialize_action_group(pdata)
                if mc_tutorial.listeners[pname] then
                    mc_tutorial.listeners[pname]:cancel()
                    mc_tutorial.listeners[pname] = nil
                end
                pmeta:set_string("mc_tutorial:tutorials", minetest.serialize(pdata))
                minetest.chat_send_player(pname, "[Tutorial] Tutorial has started: "..pdata.active.title)

                if pdata.active.seq_index > pdata.active.length then
                    mc_tutorial.completed_action(player)
                else
                    -- Check if there is an action in the sequence that requires the tutorial_progress_listener
                    -- This saves us from unnecessarily burning cycles server-side
                    local action_map = {
                        [mc_tutorial.ACTION.POS_ABS] = true,
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
                        mc_tutorial.listeners[pname] = minetest.after(0.1, mc_tutorial.tutorial_progress_listener, player)
                    end
                end
                -- TODO: add HUD and/or formspec to display the instructions for the tutorial
            end
        elseif fields.stop then
            local pmeta = player:get_meta()
            local pdata = minetest.deserialize(pmeta:get_string("mc_tutorial:tutorials"))

            mc_tutorial.active[pname] = nil
            pdata.active = nil
            if mc_tutorial.listeners[pname] then
                mc_tutorial.listeners[pname]:cancel()
                mc_tutorial.listeners[pname] = nil
            end

            pmeta:set_string("mc_tutorial:tutorials", minetest.serialize(pdata))
            minetest.chat_send_player(pname, "[Tutorial] Tutorial has been stopped.")
            mc_tutorial.show_tutorials(player)
        end
    end
    
    -- Continue the recording with other options with on_right_click callback
    if formname == "mc_tutorial:record_options_fs" then

        -- TODO: add formspec to support recording: 
                ----- put something into or modify inventory player:get_inventory() inv:contains_item() inv:is_empty() ItemStack:get_count()

        if fields.stop then
            mc_tutorial.stop_recording(player)
        end

        if fields.getpos then
            local pos = player:get_pos()
            local reg_success = mc_tutorial.register_tutorial_action(player, mc_tutorial.ACTION.POS_ABS, {pos = pos})
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
            local pitch = -player:get_look_vertical()
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

        if fields.editor then
            return mc_tutorial.show_event_popup_fs(player, false, true)
        end

        if fields.exit or fields.quit then
            return
        end
    end

    -- Complete the recording
	if formname == "mc_tutorial:record_fs" then
        local reload = false

        -- NAV + SELECTION
        if fields.record_nav then
            context.tab = fields.record_nav
            save_temp_fields(player, fields)
            reload = true
        end
        if fields.eventlist then
            local event = minetest.explode_textlist_event(fields.eventlist)
            if event.type == "CHG" then
                context.selected_event = event.index
            end
        end
        if fields.reward_list then
            local event = minetest.explode_textlist_event(fields.reward_list)
            if event.type == "CHG" then
                context.reward_selected = context.reward_selected or {[RW_LIST] = 1, [RW_SELECT] = 1, ["active"] = RW_LIST}
                context.reward_selected[RW_LIST] = event.index
                context.reward_selected["active"] = RW_LIST
                reload = true
            end
        end
        if fields.reward_selection then
            local event = minetest.explode_textlist_event(fields.reward_selection)
            if event.type == "CHG" then
                context.reward_selected = context.reward_selected or {[RW_LIST] = 1, [RW_SELECT] = 1, ["active"] = RW_LIST}
                context.reward_selected[RW_SELECT] = event.index
                context.reward_selected["active"] = RW_SELECT
                reload = true
            end
        end
        if fields.depend_tutorials then
            local event = minetest.explode_textlist_event(fields.depend_tutorials)
            if event.type == "CHG" then
                context.tutorials.main.selected = tonumber(event.index)
            end
        end
        if fields.dependencies then
            local event = minetest.explode_textlist_event(fields.dependencies)
            if event.type == "CHG" then
                context.tutorials.dep_cy.selected = tonumber(event.index)
            end
        end
        if fields.dependents then
            local event = minetest.explode_textlist_event(fields.dependents)
            if event.type == "CHG" then
                context.tutorials.dep_nt.selected = tonumber(event.index)
            end
        end

        -- REWARDS TAB INTERACTIONS
        if fields.reward_add and #context.rewards > 0 then
            context.reward_selected = context.reward_selected or {[RW_LIST] = 1, [RW_SELECT] = 1, ["active"] = RW_LIST}
            local col, type_id, item = get_selected_reward_info(context, RW_LIST)
            if type_id == "P" then
                table.insert(mc_tutorial.record.temp[pname].on_completion.privs, item)
            else
                table.insert(mc_tutorial.record.temp[pname].on_completion.items, item)
            end

            local new_index
            context.rewards, context.selected_rewards, new_index = move_list_item(context.reward_selected[RW_LIST], context.rewards, context.selected_rewards, col_field_compare)
            context.reward_selected = {
                [RW_LIST] = math.max(1, math.min(context.reward_selected[RW_LIST], #context.rewards)),
                [RW_SELECT] = new_index,
                ["active"] = RW_SELECT
            }
            reload = true
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

            context.selected_rewards, context.rewards, new_index = move_list_item(context.reward_selected[RW_SELECT], context.selected_rewards, context.rewards, col_field_compare)
            context.reward_selected = {
                [RW_LIST] = new_index,
                [RW_SELECT] = math.max(1, math.min(context.reward_selected[RW_SELECT], #context.selected_rewards)),
                ["active"] = RW_LIST
            }
            reload = true
        end
        if fields.reward_search_go then
            -- TODO
        end
        if fields.reward_search_x then
            -- TODO
        end

        -- EVENTS TAB INTERACTIONS
        local eventlist_field_active = false
        for k,v in pairs(fields) do
            if string.sub(k, 1, 10) == "eventlist_" then
                eventlist_field_active = true
                break
            end
        end
        if eventlist_field_active then
            reload = true
            if fields.eventlist_add_event then
                context.selected_event = context.selected_event or 1
                return mc_tutorial.show_event_popup_fs(player, false, false)
            end
            if fields.eventlist_add_group then
                context.selected_event = context.selected_event or 1
                if not mc_tutorial.record.temp[pname].sequence[context.selected_event] then
                    minetest.chat_send_player(pname, "[Tutorial] Groups can not be added to empty tutorials.")
                elseif mc_tutorial.record.temp[pname].sequence[context.selected_event].action == mc_tutorial.ACTION.GROUP then
                    minetest.chat_send_player(pname, "[Tutorial] Groups can not be added around group markers.")
                elseif group_parity_is_odd(context.selected_event, mc_tutorial.record.temp[pname].sequence) then
                    minetest.chat_send_player(pname, "[Tutorial] Groups can not be added inside other groups.")
                else
                    local group = mc_tutorial.record.temp[pname].next_group or 1
                    table.insert(mc_tutorial.record.temp[pname].sequence, context.selected_event + 1, {
                        action = mc_tutorial.ACTION.GROUP,
                        g_type = mc_tutorial.GROUP.END,
                        g_id = group,
                        g_remaining = {},
                        g_length = 0,
                    })
                    table.insert(context.events, context.selected_event + 1, "#CCFFFF} END GROUP "..group)
                    table.insert(mc_tutorial.record.temp[pname].sequence, context.selected_event, {
                        action = mc_tutorial.ACTION.GROUP,
                        g_type = mc_tutorial.GROUP.START,
                        g_id = group,
                    })
                    table.insert(context.events, context.selected_event, "#CCFFFFGROUP "..group.. " {")

                    mc_tutorial.record.temp[pname].next_group = group + 1
                    mc_tutorial.record.temp[pname].has_actions = true
                end
            end
            if fields.eventlist_delete then
                context.selected_event = context.selected_event or 1
                if not mc_tutorial.record.temp[pname].sequence[context.selected_event] then
                    minetest.chat_send_player(pname, "[Tutorial] There are no actions to delete.")
                else
                    local removed = table.remove(mc_tutorial.record.temp[pname].sequence, context.selected_event)
                    table.remove(context.events, context.selected_event)
                    if removed.action == mc_tutorial.ACTION.GROUP then
                        local removed_id = removed.g_id or math.maxinteger
                        for i,event in pairs(mc_tutorial.record.temp[pname].sequence) do
                            if event.action == mc_tutorial.ACTION.GROUP and event.g_id == removed_id then
                                table.remove(mc_tutorial.record.temp[pname].sequence, i)
                                table.remove(context.events, i)
                            end
                        end
                        reindex_groups(mc_tutorial.record.temp[pname])
                        context.events = nil -- force event list to be regenerated
                    end
                    if #mc_tutorial.record.temp[pname].sequence <= 0 then
                        mc_tutorial.record.temp[pname].has_actions = false
                    end
                    context.selected_event = math.max(1, math.min(context.selected_event, #mc_tutorial.record.temp[pname].sequence))
                end
            end
            if fields.eventlist_duplicate then
                context.selected_event = context.selected_event or 1
                local copy = {
                    internal = mc_tutorial.record.temp[pname].sequence[context.selected_event],
                    external = context.events[context.selected_event]
                }
                if not copy.internal or not copy.external then
                    minetest.chat_send_player(pname, "[Tutorial] There are no actions to duplicate.")
                elseif copy.internal.action ~= mc_tutorial.ACTION.GROUP then
                    table.insert(mc_tutorial.record.temp[pname].sequence, context.selected_event + 1, copy.internal)
                    table.insert(context.events, context.selected_event + 1, copy.external)
                    mc_tutorial.record.temp[pname].has_actions = true
                else
                    -- TODO: allow entire groups to be duplicated
                    minetest.chat_send_player(pname, "[Tutorial] Group markers can not be duplicated.")
                end
            end
            if fields.eventlist_edit then
                context.selected_event = context.selected_event or 1
                if not mc_tutorial.record.temp[pname].sequence[context.selected_event] then
                    minetest.chat_send_player(pname, "[Tutorial] There are no actions to edit.")
                elseif mc_tutorial.record.temp[pname].sequence[context.selected_event].action ~= mc_tutorial.ACTION.GROUP then
                    return mc_tutorial.show_event_popup_fs(player, true, false)
                else
                    minetest.chat_send_player(pname, "[Tutorial] Group markers can not be edited.")
                end
            end
            if fields.eventlist_move_top then
                context.selected_event = context.selected_event or 1
                if context.selected_event > 1 then
                    event_shift_handler(pname, context, mc_tutorial.record.temp[pname].sequence, 1)
                else
                    minetest.chat_send_player(pname, "[Tutorial] This element can not be moved any higher.")
                end
            end
            if fields.eventlist_move_up then
                context.selected_event = context.selected_event or 1
                if context.selected_event > 1 then
                    event_shift_handler(pname, context, mc_tutorial.record.temp[pname].sequence, context.selected_event - 1)
                else
                    minetest.chat_send_player(pname, "[Tutorial] This element can not be moved any higher.")
                end
            end
            if fields.eventlist_move_down then
                context.selected_event = context.selected_event or 1
                if context.selected_event < #context.events then
                    event_shift_handler(pname, context, mc_tutorial.record.temp[pname].sequence, context.selected_event + 1)
                else
                    minetest.chat_send_player(pname, "[Tutorial] This element can not be moved any lower.")
                end
            end
            if fields.eventlist_move_bottom then
                context.selected_event = context.selected_event or 1
                if context.selected_event < #context.events then
                    event_shift_handler(pname, context, mc_tutorial.record.temp[pname].sequence)
                else
                    minetest.chat_send_player(pname, "[Tutorial] This element can not be moved any lower.")
                end
            end
        end

        -- DEPENDENCIES TAB INTERACTIONS
        if fields.dependencies_add and context.tutorials.main.list[context.tutorials.main.selected] then
            local id_string = table.remove(context.tutorials.main.list, context.tutorials.main.selected)
            local id = extract_id(id_string)
            if id then
                table.insert(context.tutorials.dep_cy.list, id_string)
                mc_tutorial.record.temp[pname].dependencies[id] = true
                mc_tutorial.record.temp[pname].depend_update.dep_cy[id] = true

                context.tutorials.main.selected = math.max(1, math.min(context.tutorials.main.selected, #context.tutorials.main.list))
                reload = true
            else
                minetest.chat_send_player(pname, "[Tutorial] Invalid tutorial ID; dependency could not be added")
            end
        end
        if fields.dependencies_delete and context.tutorials.dep_cy.list[context.tutorials.dep_cy.selected] then
            local id_string = table.remove(context.tutorials.dep_cy.list, context.tutorials.dep_cy.selected)
            local id = extract_id(id_string)
            if id then
                table.insert(context.tutorials.main.list, id_string)
                mc_tutorial.record.temp[pname].dependencies[id] = nil
                mc_tutorial.record.temp[pname].depend_update.dep_cy[id] = false

                context.tutorials.dep_cy.selected = math.max(1, math.min(context.tutorials.dep_cy.selected, #context.tutorials.dep_cy.list))
                reload = true
            else
                minetest.chat_send_player(pname, "[Tutorial] Invalid tutorial ID; dependency could not be removed")
            end
        end
        if fields.dependents_add and context.tutorials.main.list[context.tutorials.main.selected] then
            local id_string = table.remove(context.tutorials.main.list, context.tutorials.main.selected)
            local id = extract_id(id_string)
            if id then
                table.insert(context.tutorials.dep_nt.list, id_string)
                mc_tutorial.record.temp[pname].dependents[id] = true
                mc_tutorial.record.temp[pname].depend_update.dep_nt[id] = true

                context.tutorials.main.selected = math.max(1, math.min(context.tutorials.main.selected, #context.tutorials.main.list))
                reload = true
            else
                minetest.chat_send_player(pname, "[Tutorial] Invalid tutorial ID; dependent could not be added")
            end
        end
        if fields.dependents_delete and context.tutorials.dep_nt.list[context.tutorials.dep_nt.selected] then
            local id_string = table.remove(context.tutorials.dep_nt.list, context.tutorials.dep_nt.selected)
            local id = extract_id(id_string)
            if id then
                table.insert(context.tutorials.main.list, id_string)
                mc_tutorial.record.temp[pname].dependents[id] = nil
                mc_tutorial.record.temp[pname].depend_update.dep_nt[id] = false

                context.tutorials.dep_nt.selected = math.max(1, math.min(context.tutorials.dep_nt.selected, #context.tutorials.dep_nt.list))
                reload = true
            else
                minetest.chat_send_player(pname, "[Tutorial] Invalid tutorial ID; dependent could not be removed")
            end
        end

        -- MISC
        if fields.finish then
            if mc_tutorial.record.temp[pname].has_actions then
                save_temp_fields(player, fields)

                -- Build the tutorial table to send to mod storage
                local recorded_tutorial = {
                    dependencies = mc_tutorial.record.temp[pname].dependencies or {}, -- table of tutorial IDs that must be compeleted before the player can attempt this tutorial
                    dependents = mc_tutorial.record.temp[pname].dependents or {}, -- table of tutorial IDs that completing this tutorial unlocks
                    title = (mc_tutorial.record.temp[pname].title ~= "" and mc_tutorial.record.temp[pname].title) or "Untitled",
                    length = mc_tutorial.record.temp[pname].sequence and #mc_tutorial.record.temp[pname].sequence or 0,
                    seq_index = 1, -- default search always starts on the first element in the sequence
                    description = (mc_tutorial.record.temp[pname].description ~= "" and mc_tutorial.record.temp[pname].description) or "No description provided",
                    sequence = mc_tutorial.record.temp[pname].sequence or {},
                    next_group = mc_tutorial.record.temp[pname].next_group or 1,
                    on_completion = {
                        message = (mc_tutorial.record.temp[pname].on_completion.message ~= "" and mc_tutorial.record.temp[pname].on_completion.message) or "You completed the tutorial!",
                        items = mc_tutorial.record.temp[pname].on_completion.items or {},
                        privs = mc_tutorial.record.temp[pname].on_completion.privs or {}
                    },
                    format = mc_tutorial.get_temp_shell().format
                }

                -- Send to mod storage
                if not mc_tutorial.tutorials_exist() then
                    mc_tutorial.tutorials:set_int("next_id", 2)
                    mc_tutorial.tutorials:set_string("1", minetest.serialize(recorded_tutorial))
                else
                    local id = mc_tutorial.record.edit[pname] or mc_tutorial.tutorials:get("next_id") or 1
                    
                    -- Update dependencies/dependents in other tutorials
                    for k,v in pairs(mc_tutorial.record.temp[pname].depend_update.dep_cy) do
                        local serial_tut = mc_tutorial.tutorials:get(tostring(k))
                        if serial_tut then
                            local tut = minetest.deserialize(serial_tut)
                            tut.dependents[id] = v or nil
                            mc_tutorial.tutorials:set_string(tostring(k), minetest.serialize(tut))
                        else
                            -- invalid dependency, remove
                            recorded_tutorial.dependencies[k] = nil
                        end
                    end
                    for k,v in pairs(mc_tutorial.record.temp[pname].depend_update.dep_nt) do
                        local serial_tut = mc_tutorial.tutorials:get(tostring(k))
                        if serial_tut then
                            local tut = minetest.deserialize(serial_tut)
                            tut.dependencies[id] = v or nil
                            mc_tutorial.tutorials:set_string(tostring(k), minetest.serialize(tut))
                        else
                            -- invalid dependency, remove
                            recorded_tutorial.dependencies[k] = nil
                        end
                    end

                    -- Save recorded tutorial
                    mc_tutorial.tutorials:set_string(tostring(id), minetest.serialize(recorded_tutorial))
                    if not mc_tutorial.record.edit[pname] then
                        mc_tutorial.tutorials:set_int("next_id", id + 1)
                    end
                end

                minetest.chat_send_player(pname, "[Tutorial] Your tutorial was successfully saved!")
            else
                minetest.chat_send_player(pname, "[Tutorial] No tutorial was saved.")
            end

            -- Ensure global temp is recycled + context is cleared
            mc_tutorial.record.temp[pname] = nil
            mc_tutorial.record.edit[pname] = nil
            mc_tutorial.record.active[pname] = nil
            context:clear()
            return -- formspec was closed, do not continue
        elseif fields.quit then -- forced quit
            minetest.chat_send_player(pname, "[Tutorial] No tutorial was saved.")
            mc_tutorial.record.temp[pname] = nil
            mc_tutorial.record.edit[pname] = nil
            mc_tutorial.record.active[pname] = nil
            context:clear()
            return -- formspec was closed, do not continue
        end

        -- Save context and refresh formspec, if necessary
        if reload then
            mc_tutorial.show_record_fs(player)
        end
    end

    if formname == "mc_tutorial:record_epop" then
        local reload = false
        local save_exception = {}

        if fields.action then
            context.epop.selected = tonumber(fields.action)
            reload = true
        end
        if fields.epop_list then
            local event = minetest.explode_textlist_event(fields.epop_list)
            if event.type == "CHG" then
                context.epop.list.selected = tonumber(event.index)
            elseif event.type == "DCL" then
                -- add auto-pop code here
            end
        end

        if fields.node_import and context.epop.list.list and context.epop.list.list[context.epop.list.selected] then
            context.epop.fields.node = context.epop.list.list[context.epop.list.selected]
            reload = true
            save_exception["nd"] = true
        end
        if fields.tool_import and context.epop.list.list and context.epop.list.list[context.epop.list.selected] then
            context.epop.fields.tool = context.epop.list.list[context.epop.list.selected]
            reload = true
            save_exception["tl"] = true
        end

        if fields.key_list then
            local event = minetest.explode_textlist_event(fields.key_list)
            if event.type == "CHG" then
                context.epop.fields.key_selected = tonumber(event.index)
            elseif event.type == "DCL" then
                fields.key_delete = true
            end
        end
        if fields.key_add and context.epop.list.list and context.epop.list.list[context.epop.list.selected] then
            context.epop.fields.key = context.epop.fields.key or {}

            if not mc_helpers.tableHas(context.epop.fields.key, context.epop.list.list[context.epop.list.selected]) then
                table.insert(context.epop.fields.key, context.epop.list.list[context.epop.list.selected])
                table.remove(context.epop.list.list, context.epop.list.selected)
                reload = true
            end
        end
        if fields.key_delete and context.epop.list.list then
            context.epop.fields.key = context.epop.fields.key or {}
            context.epop.fields.key_selected = context.epop.fields.key_selected or 1
            
            if next(context.epop.fields.key) and context.epop.fields.key[context.epop.fields.key_selected] then
                table.insert(context.epop.list.list, context.epop.fields.key[context.epop.fields.key_selected])
                table.remove(context.epop.fields.key, context.epop.fields.key_selected)
            end
            reload = true
        end

        if fields.dir_type then
            context.epop.d_input_type = tonumber(fields.dir_type)
            reload = true
        end

        if fields.save then
            local action_map = {
                [mc_tutorial.ACTION.PUNCH] = function()
                    return fields.node and fields.node ~= "" and {node = fields.node or "", tool = fields.tool or ""}
                end,
                [mc_tutorial.ACTION.DIG] = function()
                    return fields.node and fields.node ~= "" and {node = fields.node or "", tool = fields.tool or ""}
                end,
                [mc_tutorial.ACTION.PLACE] = function()
                    return fields.node and fields.node ~= "" and {node = fields.node or ""}
                end,
                [mc_tutorial.ACTION.WIELD] = function()
                    return fields.tool and {tool = fields.tool or ""}
                end,
                [mc_tutorial.ACTION.KEY] = function()
                    return context.epop.fields.key and next(context.epop.fields.key) and {key_bit = mc_tutorial.keys_to_bits(context.epop.fields.key)}
                end,
                [mc_tutorial.ACTION.LOOK_YAW] = function()
                    return fields.yaw and fields.yaw ~= "" and {dir = math.rad(tonumber(fields.yaw or "0"))}
                end,
                [mc_tutorial.ACTION.LOOK_PITCH] = function()
                    return fields.pitch and fields.pitch ~= "" and {dir = math.rad(tonumber(fields.pitch or "0"))}
                end,
                [mc_tutorial.ACTION.LOOK_DIR] = function()
                    if fields.dir_x or fields.dir_y or fields.dir_z then
                        local dir_table = {x = tonumber(fields.dir_x ~= "" and fields.dir_x or "0"), y = tonumber(fields.dir_y ~= "" and fields.dir_y or "0"), z = tonumber(fields.dir_z ~= "" and fields.dir_z or "0")}
                        if dir_table.x ~= 0 or dir_table.y ~= 0 or dir_table.z ~= 0 then
                            return {dir = vector.normalize(vector.new(dir_table.x, dir_table.y, dir_table.z))}
                        else
                            return {dir = vector.normalize(vector.new(0, 0, 1))}
                        end
                    elseif fields.dir_yaw or fields.dir_pitch then
                        local yaw = tonumber(fields.dir_yaw ~= "" and fields.dir_yaw or "0")
                        local pitch = tonumber(fields.dir_pitch ~= "" and fields.dir_pitch or "0")
                        return {dir = yp_to_vect(yaw, pitch)}
                    else return nil end
                end,
                [mc_tutorial.ACTION.POS_ABS] = function()
                    local pos_table = {x = fields.pos_x ~= "" and fields.pos_x or "0", y = fields.pos_y ~= "" and fields.pos_y or "0", z = fields.pos_z ~= "" and fields.pos_z or "0"}
                    return {pos = {x = tonumber(pos_table.x), y = tonumber(pos_table.y), z = tonumber(pos_table.z)}}
                end,
            }

            local action = context.epop.i_to_action[context.epop.selected]
            if action_map[action] then
                local action_table = action_map[action]()
                if action_table then
                    if context.epop.is_edit then
                        -- Replace action
                        mc_tutorial.update_tutorial_action(player, context.selected_event, action, action_map[action]())
                        local col, event_string = event_action_map[action](action_table)
                        if not context.epop.is_iso then
                            context.events[context.selected_event] = (col or "")..minetest.formspec_escape(event_string or "")
                        end
                        minetest.chat_send_player(pname, "[Tutorial] Event saved!")
                    else
                        -- Add new action to end of list
                        mc_tutorial.register_tutorial_action(player, action, action_table)
                        local col, event_string = event_action_map[action](action_table)
                        if not context.epop.is_iso then
                            table.insert(context.events, (col or "")..minetest.formspec_escape(event_string or ""))
                        end
                        minetest.chat_send_player(pname, "[Tutorial] Event added!")
                    end
                else
                    minetest.chat_send_player(pname, "[Tutorial] Invalid event; event not "..(context.epop.is_edit and "saved" or "added")..".")
                end
            else
                minetest.chat_send_player(pname, "[Tutorial] Invalid event; event not "..(context.epop.is_edit and "saved" or "added")..".")
            end

            local iso = context.epop.is_iso
            context.epop = nil
            if not iso then
                return mc_tutorial.show_record_fs(player)
            end
            return
        end
        if fields.cancel or fields.quit then
            minetest.chat_send_player(pname, "[Tutorial] "..(context.epop.is_edit and "Event not saved" or "No event added")..".")
            local iso = context.epop.is_iso
            context.epop = nil
            if not iso then
                return mc_tutorial.show_record_fs(player)
            end
            return
        end

        if reload then
            -- save text fields
            if fields.node and not save_exception["nd"] then context.epop.fields.node = fields.node end
            if fields.tool and not save_exception["tl"] then context.epop.fields.tool = fields.tool end
            if fields.pitch and not save_exception["pt"] then context.epop.fields.pitch = fields.pitch end
            if fields.yaw and not save_exception["yw"] then context.epop.fields.yaw = fields.yaw end
            if (fields.pos_x or fields.pos_y or fields.pos_z) and not save_exception["po"] then
                context.epop.fields.pos = {x = tonumber(fields.pos_x ~= "" and fields.pos_x or "0"), y = tonumber(fields.pos_y ~= "" and fields.pos_y or "0"), z = tonumber(fields.pos_z ~= "" and fields.pos_z or "0")}
            end
            if not save_exception["dr"] then
                if (fields.dir_x and fields.dir_x ~= "") or (fields.dir_y and fields.dir_y ~= "") or (fields.dir_z and fields.dir_z ~= "") then
                    context.epop.fields.dir = vector.new(tonumber(fields.dir_x ~= "" and fields.dir_x or "0"), tonumber(fields.dir_y ~= "" and fields.dir_y or "0"), tonumber(fields.dir_z ~= "" and fields.dir_z or "0"))
                elseif (fields.dir_yaw or fields.dir_pitch) then
                    context.epop.fields.dir = yp_to_vect(fields.dir_yaw ~= "" and fields.dir_yaw or 0, fields.dir_pitch ~= "" and fields.dir_pitch or 0)
                end
            end

            -- save context and reload
            mc_tutorial.show_event_popup_fs(player)
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
    for list,_ in pairs(mc_tutorial.record.listener) do
        mc_tutorial.record.listener[list][pname] = nil
    end
end)

-- TODO: other possible callbacks
--minetest.register_allow_player_inventory_action(function(player, action, inventory, inventory_info))
--minetest.register_on_craft(func(itemstack, player, old_craft_grid, craft_inv))
--minetest.register_on_receiving_chat_messages(function(message))
