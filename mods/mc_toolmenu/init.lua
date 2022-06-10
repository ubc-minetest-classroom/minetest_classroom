mc_toolmenu = {}
mc_toolmenu.inv_storage = minetest.get_mod_storage()
dofile(minetest.get_modpath("mc_toolmenu") .. "/api.lua")

sfinv.register_page("mc_toolmenu:tools", {
    title = "Toolbox",
    get = function(self, player, context)
        local pname = player:get_player_name()
        local formtable = {
            "box[-0.28,-0.30;8.35,4.9;#555555]",
            "label[0,0;(WIP) Only tools can be stored here!]",
            "list[detached:mc_toolmenu:", pname, ";mc_toolmenu:tools;0,0.5;8,4;0]"
        }
        return sfinv.make_formspec(player, context, table.concat(formtable, ""), true)
    end
})

-- Gets the saved toolbox serialization from mod storage
local function get_saved_toolbox(player)
    local pname = player:get_player_name()
    return minetest.deserialize(mc_toolmenu.inv_storage:get_string(pname))
end

-- Saves the player's entire toolbox to mod storage
local function save_full_toolbox(toolbox, player)
    local toolbox_table = {}
    local pname = player:get_player_name()
    local lists = toolbox:get_lists()

    for list,data in pairs(lists) do
        local list_table = {}
        for i,item in pairs(data) do
            list_table[i] = item:to_table()
        end
        toolbox_table[list] = {inv = list_table, size = toolbox:get_size(list)}
    end

    mc_toolmenu.inv_storage:set_string(pname, minetest.serialize(toolbox_table))
end

-- Loads the saved toolbox data into MineTest
local function load_saved_toolbox(toolbox, player)
    local save = get_saved_toolbox(player)
    for list,data in pairs(save) do
        toolbox:set_list(list, {})
        toolbox:set_size(list, data.size)
        for i,item in pairs(data.inv) do
            toolbox:set_stack(list, i, ItemStack(item))
        end
    end
end

-- Adds an ItemStack to the saved toolbox in mod storage
local function add_item_and_save(toolbox, list, index, stack, player)
    local save = get_saved_toolbox(player)
    local list_to_modify = save[list]
    if list_to_modify then
        list_to_modify["inv"][index] = stack:to_table()
        save[list] = list_to_modify
        mc_toolmenu.inv_storage:set_string(player:get_player_name(), minetest.serialize(save))
    else
        -- fallback: save entire toolbox
        save_full_toolbox(toolbox, player)
    end
end

-- Removes an ItemStack from the saved toolbox in mod storage
local function remove_item_and_save(toolbox, list, index, stack, player)
    local save = get_saved_toolbox(player)
    local list_to_modify = save[list]
    if list_to_modify then
        list_to_modify["inv"][index] = nil
        save[list] = list_to_modify
        mc_toolmenu.inv_storage:set_string(player:get_player_name(), minetest.serialize(save))
    else
        -- fallback: save entire toolbox
        save_full_toolbox(toolbox, player)
    end
end

local function move_item_and_save(toolbox, old_list, old_index, new_list, new_index, count, player)
    local save = get_saved_toolbox(player)
end


minetest.register_on_joinplayer(function(player)
    -- player check
    if not player:is_player() then return end

    local pname = player:get_player_name()
    local toolbox = minetest.create_detached_inventory("mc_toolmenu:"..pname, {
        allow_put = function(inv, listname, index, stack, player)
            -- 1 if item is registered tool, 0 otherwise
            if minetest.registered_tools[stack:get_name()] then 
                return 1 -- allow 1 item to be put in
            else
                return 0 -- do not allow item to be put in
            end
        end,
        allow_take = function(inv, listname, index, stack, player)
            -- 1 if item is registered tool, 0 and delete item otherwise
            if minetest.registered_tools[stack:get_name()] then
                return 1 -- allow 1 item to be taken
            else
                inv:remove_item(listname, stack)
                return 0 -- do not allow item to be taken
            end
        end,
        --allow_move = function(inv, from_list, from_index, to_list, to_index, count, player),
            -- Called when a player wants to move items inside the inventory.
            -- Return value: number of items allowed to move.
        on_put = function(inv, listname, index, stack, player)
            add_item_and_save(inv, listname, index, stack, player)
        end,
        on_take = function(inv, listname, index, stack, player)
            remove_item_and_save(inv, listname, index, stack, player)
        end,
        on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
            -- hard to optimize, but will look into doing so
            save_full_toolbox(inv, player)
        end
    }, pname)

    -- create a saved toolbox if it does not already exist
    if not mc_toolmenu.inv_storage:get(pname) then
        mc_toolmenu.inv_storage:set_string(pname, minetest.serialize({tools = {inv = {}, size = 32}}))
    end
    
    -- load the saved toolbox into MineTest
    load_saved_toolbox(toolbox, player)
end)

minetest.register_on_leaveplayer(function(player)
    -- player check
    if not player:is_player() then return end

    local inv = mc_toolmenu.get_toolbox(player)

    -- save to storage for good measure, then remove unused detached inventory to free up resources
    save_full_toolbox(inv, player)
    minetest.remove_detached_inventory("mc_toolmenu:"..pname)
end)
