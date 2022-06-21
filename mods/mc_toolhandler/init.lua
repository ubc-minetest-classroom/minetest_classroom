mc_toolhandler = {reg_tools = {}}

-- Returns name of list item is in, if it is in player's inventory
local function get_player_item_location(player, itemstack)
    local inv = player:get_inventory()
    for list,_ in pairs(inv:get_lists()) do
        if inv:contains_item(list, itemstack) then
            return list
        end
    end
    return nil
end

-- Returns name of list and index of first item with mc_tool_group in player's inventory, if an item with mc_tool_group is in player's inventory
local function get_player_item_group_location(player, mc_tool_group)
    local inv = player:get_inventory()
    for list,data in pairs(inv:get_lists()) do
        for i,item in pairs(data) do
            if item:get_definition()._mc_tool_group == mc_tool_group then
                return list,i
            end
        end
    end
    return nil
end

-- Returns true if player has 2 of more of itemstack, false otherwise
local function player_has_multiple_copies(player, itemstack)
    local inv = player:get_inventory()
    local stack_2 = ItemStack(itemstack)
    stack_2:set_count(2)
    local count = 0
    for list,data in pairs(inv:get_lists()) do
        if inv:contains_item(list, stack_2) then
            return true
        elseif inv:contains_item(list, itemstack) then
            count = count + 1
            if count >= 2 then
                return true
            end
        end
    end
    return false
end

-- Returns true if player has 2 of more items with mc_tool_group, false otherwise
local function player_has_multiple_group_copies(player, mc_tool_group)
    local inv = player:get_inventory()
    local count = 0
    for list,data in pairs(inv:get_lists()) do
        for i,item in pairs(data) do
            if item:get_definition()._mc_tool_group == mc_tool_group then
                count = count + 1
                if count >= 2 then
                    return true
                end
            end
        end
    end
    return false
end

-- Removes all copies of itemstack from player's inventory, except the one at i_0 in list_0
local function remove_item_copies_except(player, itemstack, i_0, list_0)
    local inv = player:get_inventory()
    for list,data in pairs(inv:get_lists()) do
        if inv:contains_item(list, itemstack) then
            for i,_ in pairs(data) do
                if inv:get_stack(list, i):get_name() == itemstack:get_name() and (i ~= i_0 or list ~= list_0) then
                    inv:set_stack(list, i, ItemStack(nil))
                end
            end
        end
    end
end

-- Removes all items in group from player's inventory, except the one at i_0 in list_0
local function remove_item_group_copies_except(player, mc_tool_group, i_0, list_0)
    local inv = player:get_inventory()
    for list,data in pairs(inv:get_lists()) do
        for i,item in pairs(data) do
            if item:get_definition()._mc_tool_group == mc_tool_group and (i ~= i_0 or list ~= list_0) then
                inv:set_stack(list, i, ItemStack(nil))
            end
        end
    end
end

--- Registers give/take callbacks for a tool
--- @param tool_name Name of the tool
--- @param data Tool definition table
local function register_callbacks(tool_name, data)
    -- Give the tool to any player who joins with adequate privileges or take it away if they do not have them
    minetest.register_on_joinplayer(function(player)
        local stack = ItemStack(tool_name)
        local list = get_player_item_location(player, stack)

        if not list and mc_helpers.checkPrivs(player, data._mc_tool_privs) then
            -- Player should have the tool but does not: give one copy
            player:get_inventory():add_item("main", tool_name)
        elseif not mc_helpers.checkPrivs(player, data._mc_tool_privs) then
            -- Player has the tool but should not: remove all copies
            local inv = player:get_inventory()
            while list do
                inv:remove_item(list, tool_name)
                list = get_player_item_location(player, stack)
            end
        else
            -- Make sure player only has one copy of the tool
            if player_has_multiple_copies(player, ItemStack(tool_name)) then
                for i,item in pairs(player:get_inventory():get_list(list)) do
                    if item:get_name() == tool_name then
                        remove_item_copies_except(player, stack, i, list)
                        break
                    end
                end
            end
        end
    end)

    -- Give the tool to any player who is granted adequate privileges
    minetest.register_on_priv_grant(function(name, granter, priv)
        -- Check if priv has an effect on the privileges needed for the tool
        if name == nil or not mc_helpers.tableHas(data._mc_tool_privs, priv) or not minetest.get_player_by_name(name) then
            return true -- skip this callback, continue to next callback
        end
    
        local stack = ItemStack(tool_name)
        local player = minetest.get_player_by_name(name)
        local list = get_player_item_location(player, stack)

        if mc_helpers.checkPrivs(player, data._mc_tool_privs) then
            if not list then
                -- Player should have the tool but does not: give one copy
                player:get_inventory():add_item("main", tool_name)
            elseif player_has_multiple_copies(player, ItemStack(tool_name)) then
                -- Player has multiple copies of the tool already: remove all but one
                for i,item in pairs(player:get_inventory():get_list(list)) do
                    if item:get_name() == tool_name then
                        remove_item_copies_except(player, stack, i, list)
                        break
                    end
                end
            end
        end
        return true -- continue to next callback
    end)
    
    -- Take the tool away from anyone who is revoked privileges and no longer has adequate ones
    minetest.register_on_priv_revoke(function(name, revoker, priv)
        -- Check if priv has an effect on the privileges needed for the tool
        if name == nil or not mc_helpers.tableHas(data._mc_tool_privs, priv) or not minetest.get_player_by_name(name) then
            return true -- skip this callback, continue to next callback
        end
    
        local stack = ItemStack(tool_name)
        local player = minetest.get_player_by_name(name)
        local list = get_player_item_location(player, stack)
    
        if list and not mc_helpers.checkPrivs(player, data._mc_tool_privs) then
            -- Player has the tool but should not: remove all copies
            local inv = player:get_inventory()
            while list do
                inv:remove_item(list, tool_name)
                list = get_player_item_location(player, stack)
            end
        end
        return true -- continue to next callback
    end)
end

--- Registers give/take callbacks for all tools in a tool group
--- @param tool_name Name of the tool to give by default
--- @param data Tool definition table
local function register_group_callbacks(tool_name, data)
    -- Give the tool to any player who joins with adequate privileges or take it away if they do not have them
    minetest.register_on_joinplayer(function(player)
        local list,i = get_player_item_group_location(player, data._mc_tool_group)

        if not list and mc_helpers.checkPrivs(player, data._mc_tool_privs) then
            -- Player should have the tool but does not: give one copy
            player:get_inventory():add_item("main", tool_name)
        elseif not mc_helpers.checkPrivs(player, data._mc_tool_privs) then
            -- Player has the tool but should not: remove all copies
            local inv = player:get_inventory()
            while list do
                inv:set_stack(list, i, ItemStack(nil))
                list,i = get_player_item_group_location(player, data._mc_tool_group)
            end
        else
            -- Make sure player only has one copy of the tool
            if player_has_multiple_group_copies(player, data._mc_tool_group) then
                remove_item_group_copies_except(player, stack, i, list)
            end
        end
    end)

    -- Give the tool to any player who is granted adequate privileges
    minetest.register_on_priv_grant(function(name, granter, priv)
        -- Check if priv has an effect on the privileges needed for the tool
        if name == nil or not mc_helpers.tableHas(data._mc_tool_privs, priv) or not minetest.get_player_by_name(name) then
            return true -- skip this callback, continue to next callback
        end
    
        local player = minetest.get_player_by_name(name)
        local list,i = get_player_item_group_location(player, data._mc_tool_group)

        if mc_helpers.checkPrivs(player, data._mc_tool_privs) then
            if not list then
                -- Player should have the tool but does not: give one copy
                player:get_inventory():add_item("main", tool_name)
            elseif player_has_multiple_group_copies(player, data._mc_tool_group) then
                -- Player has multiple copies of the tool already: remove all but one
                remove_item_group_copies_except(player, stack, i, list)
            end
        end

        return true -- continue to next callback
    end)
    
    -- Take the tool away from anyone who is revoked privileges and no longer has adequate ones
    minetest.register_on_priv_revoke(function(name, revoker, priv)
        -- Check if priv has an effect on the privileges needed for the tool
        if name == nil or not mc_helpers.tableHas(data._mc_tool_privs, priv) or not minetest.get_player_by_name(name) then
            return true -- skip this callback, continue to next callback
        end
    
        local player = minetest.get_player_by_name(name)
        local list,i = get_player_item_group_location(player, data._mc_tool_group)
    
        if list and not mc_helpers.checkPrivs(player, data._mc_tool_privs) then
            -- Player has the tool but should not: remove all copies
            local inv = player:get_inventory()
            while list do
                inv:set_stack(list, i, ItemStack(nil))
                list,i = get_player_item_group_location(player, data._mc_tool_group)
            end
        end
        return true -- continue to next callback
    end)
end

-- Open and read mod.conf settings file
local reg_tools_from = {}
local settings = Settings(minetest.get_modpath("mc_toolhandler") .. "/mod.conf")
local mods = string.split(settings:get("optional_depends"), ",")
for _,mod in pairs(mods) do
    table.insert(reg_tools_from, string.trim(mod))
end

-- Register give/take callbacks for all MineTest classroom tools
for name,data in pairs(minetest.registered_tools) do
    for _,mod in pairs(reg_tools_from) do
        if data._mc_tool_include ~= false then
            if data._mc_tool_include or data._mc_tool_privs and (data.mod_origin == mod or string.match(name, "^"..mod..":.*")) then
                -- register give/take callbacks for tool, if not part of a tool group
                if not data._mc_tool_group then
                    -- standard registration
                    register_callbacks(name, data)
                    table.insert(mc_toolhandler.reg_tools, name)
                elseif not mc_helpers.tableHas(mc_toolhandler.reg_tools, "group:"..data._mc_tool_group) then
                    -- tool group registration
                    register_group_callbacks(name, data)
                    table.insert(mc_toolhandler.reg_tools, "group:"..data._mc_tool_group)
                end
            end
        end
    end
end

--- Abstract function for checking if a player's inventory contains a tool, and if they have the necessary privileges to use it
--- Runs t_x & t_final if tool is a registered tool, g_x & g_final if tool is part of a tool group, where x is:
--- - np if player does not have permission required to use the tool
--- - pm if player has permissions to use the tool, but has multiple copies of it
--- - else otherwise
local function tool_perm_check_abstract(player, stack, a) --t_np, t_pm, t_else, t_final, g_np, g_pm, g_else, g_final)
    local func_return = nil
    if mc_helpers.tableHas(mc_toolhandler.reg_tools, stack:get_name()) then
        if not mc_helpers.checkPrivs(player, stack:get_definition()._mc_tool_privs) then
            func_return = a.t_np(a.t_np_p) or func_return
        elseif player_has_multiple_copies(player, stack) then
            func_return = a.t_pm(a.t_pm_p) or func_return
        else
            func_return = a.t_else(a.t_else_p) or func_return
        end
        func_return = a.t_final(a.t_final_p) or func_return
    else
        local mc_tool_group = stack:get_definition()._mc_tool_group
        if mc_tool_group and mc_helpers.tableHas(mc_toolhandler.reg_tools, "group:"..mc_tool_group) then
            if not mc_helpers.checkPrivs(player, stack:get_definition()._mc_tool_privs) then
                func_return = a.g_np(a.g_np_p) or func_return
            elseif player_has_multiple_group_copies(player, mc_tool_group) then
                func_return = a.g_pm(a.g_pm_p) or func_return
            else
                func_return = a.g_else(a.g_else_p) or func_return
            end
            func_return = a.g_final(a.g_final_p) or func_return
        end
    end
    return func_return
end

-- Removes duplicate copies of registered items and items the player does not have privileges to use
local function remove_prohibited_items(player, stack, i, list)
    if mc_helpers.tableHas(mc_toolhandler.reg_tools, stack:get_name()) then
        if not mc_helpers.checkPrivs(player, stack:get_definition()._mc_tool_privs) then
            -- Player should not have the tool: remove all copies
            local inv = player:get_inventory()
            if not list then
                list = get_player_item_location(player, stack)
            end
            while list do
                inv:remove_item(list, stack:get_name())
                list = get_player_item_location(player, stack)
            end
        elseif player_has_multiple_copies(player, stack) then
            -- Remove excess item copies
            remove_item_copies_except(player, stack, i, list)
        end
    else
        local mc_tool_group = stack:get_definition()._mc_tool_group
        if mc_tool_group and mc_helpers.tableHas(mc_toolhandler.reg_tools, "group:"..mc_tool_group) then
            if not mc_helpers.checkPrivs(player, stack:get_definition()._mc_tool_privs) then
                -- Player does not have privileges to use item: remove all copies
                local inv = player:get_inventory()
                if not list then
                    list,i = get_player_item_location(player, stack)
                end
                while list do
                    inv:set_stack(list, i, ItemStack(nil))
                    list,i = get_player_item_group_location(player, data._mc_tool_group)
                end
            elseif player_has_multiple_group_copies(player, mc_tool_group) then
                -- Remove excess item copies
                remove_item_group_copies_except(player, mc_tool_group, i, list)
            end
        end
    end
end

-- Register callbacks for removing duplicate tools and items player should not have
minetest.register_on_player_inventory_action(function(player, action, inventory, inv_info)
    if action == "put" or action == "take" then
        remove_prohibited_items(player, inv_info.stack, inv_info.index, inv_info.listname)
    elseif action == "move" then
        local stack_1 = inventory:get_stack(inv_info.to_list, inv_info.to_index)
        remove_prohibited_items(player, stack_1, inv_info.to_index, inv_info.to_list)
        local stack_2 = inventory:get_stack(inv_info.from_list, inv_info.from_index)
        remove_prohibited_items(player, stack_2, inv_info.from_index, inv_info.from_list)
    end
end)

minetest.register_on_chatcommand(function(name, command, params)
    if command == "give" or command == "giveme" then
        local p_table = string.split(params, " ")
        local player = (command == "giveme" and minetest.get_player_by_name(name)) or minetest.get_player_by_name(p_table[1])
        local stack_name = (command == "giveme" and p_table[1]) or p_table[2]
        local stack = ItemStack(stack_name)

        --[[tool_perm_check_abstract(player, stack, {
            t_np = function(name)
                minetest.chat_send_player(name, "Target player is missing privileges required for item use: TBD")
                return true
            end,
            t_np_p = {name},
            t_pm = remove_prohibited_items
        }
            remove_prohibited_items(player, stack), nil,
            function()
                if get_player_item_location(player, stack_name) then
                    minetest.chat_send_player(name, "Target player already has the requested item")
                    return true
                end
            end,
            function()
                minetest.chat_send_player(name, "Target player is missing privileges required for item use: TBD")
                return true
            end,
            remove_prohibited_items(player, stack), nil,
            function()
                if get_player_item_group_location(player, ) then
                    minetest.chat_send_player(name, "Target player already has the requested item")
                    return true
                end
            end,
        )]]

        if mc_helpers.tableHas(mc_toolhandler.reg_tools, stack_name) then
            if not mc_helpers.checkPrivs(player, stack:get_definition()._mc_tool_privs) then
                -- Player should not have the tool: do not give
                minetest.chat_send_player(name, "Target player is missing privileges required for item use: TBD")
                return true
            end
            remove_prohibited_items(player, stack)
        else
            local mc_tool_group = stack:get_definition()._mc_tool_group
            if mc_tool_group and mc_helpers.tableHas(mc_toolhandler.reg_tools, "group:"..mc_tool_group) then
                if not mc_helpers.checkPrivs(player, stack:get_definition()._mc_tool_privs) then
                    -- Player should not have the tool: do not give
                    minetest.chat_send_player(name, "Target player is missing privileges required for item use: TBD")
                    return true
                end
                remove_prohibited_items(player, stack)
            end
        end
        
    end
end)