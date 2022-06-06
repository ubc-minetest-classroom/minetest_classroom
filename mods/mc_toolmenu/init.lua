mc_toolmenu = minetest.get_mod_storage()

sfinv.register_page("mc_toolmenu:tools", {
    title = "Toolbox",
    get = function(self, player, context)
        local pname = player:get_player_name()
        local formtable = {
            "box[-0.28,-0.30;8.35,4.9;#555555]",
            "label[0,0;Soon, this will be made into a working toolbox!]",
            "list[detached:mc_toolmenu:", pname, ";tools;0,0.5;8,4;0]"
        }
        return sfinv.make_formspec(player, context, table.concat(formtable, ""), true)
    end
})

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

    mc_toolmenu:set_string(pname, minetest.serialize(toolbox_table))
end

-- Loads the saved toolbox data into MineTest
local function load_saved_toolbox(toolbox, player)
    local pname = player:get_player_name()
    local save = minetest.deserialize(mc_toolmenu:get_string(pname))

    for list,data in pairs(save) do
        toolbox:set_list(list, {})
        toolbox:set_size(list, data.size)
        for i,item in pairs(data.inv) do
            toolbox:set_stack(list, i, ItemStack(item))
        end
    end
end

minetest.register_on_joinplayer(function(player)
    -- player check
    if not player:is_player() then return end

    local pname = player:get_player_name()
    local toolbox = minetest.create_detached_inventory("mc_toolmenu:"..pname, {
        --allow_move = function(inv, from_list, from_index, to_list, to_index, count, player),
        -- Called when a player wants to move items inside the inventory.
        -- Return value: number of items allowed to move.

        allow_put = function(inv, listname, index, stack, player)
            return 65536 -- stub
        end,
        -- Called when a player wants to put something into the inventory.
        -- Return value: number of items allowed to put.
        -- Return value -1: Allow and don't modify item count in inventory.

        allow_take = function(inv, listname, index, stack, player)
            return 65536 -- stub
        end,
        -- Called when a player wants to take something out of the inventory.
        -- Return value: number of items allowed to take.
        -- Return value -1: Allow and don't modify item count in inventory.

        on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
            save_full_toolbox(inv, player) -- will optimize later
        end,
        on_put = function(inv, listname, index, stack, player)
            save_full_toolbox(inv, player) -- will optimize later
        end,
        on_take = function(inv, listname, index, stack, player)
            save_full_toolbox(inv, player) -- will optimize later
        end
    }, pname)

    -- create a saved toolbox if it does not already exist
    local toolbox_save = mc_toolmenu:get(pname)
    if not toolbox_save then
        mc_toolmenu:set_string(pname, minetest.serialize({tools = {inv = {}, size = 32}}))
        toolbox_save = mc_toolmenu:get(pname)
    end
    
    -- load the saved toolbox into MineTest
    load_saved_toolbox(toolbox, player)
end)


minetest.register_on_leaveplayer(function(player)
    -- player check
    if not player:is_player() then return end

    local pname = player:get_player_name()
    local inv = minetest.get_inventory({type = "detached", name = "mc_toolmenu:"..pname}) 

    -- save to storage for good measure
    save_full_toolbox(inv, player)
    -- remove unused detached inventory to free up resources
    minetest.remove_detached_inventory("mc_toolmenu:"..pname)
end)

--[[
-- May be useful for periodically saving data, though an ABM/LBM may be better since this event is fired roughly every 0.1 seconds
minetest.register_globalstep(function(dtime)

end)
]]