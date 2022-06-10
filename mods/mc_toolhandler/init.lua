-- will be replaced with dynamic code later
local register_tools_from = {"mc_teacher", "mc_student", "magnify", "mc_tf"--[[, "forestry_tools"]]} 

-- Returns name of list item is in, if it is in player's inventory (or toolbox)
local function get_player_item_location(player, itemstack)
    local inv = player:get_inventory()
    for list,_ in pairs(inv:get_lists()) do
        if inv:contains_item(list, itemstack) then
            return list
        end
    end
    return nil
end

-- Registers give/take callbacks for all applicable tools
local function register_callbacks(tool_name, data)
    -- Give the tool to any player who joins with adequate privileges or take it away if they do not have them
    minetest.register_on_joinplayer(function(player)
        local stack = ItemStack(tool_name)
        local list = get_player_item_location(player, stack)

        if not list and mc_helpers.checkPrivs(player, data._mc_toolhandler_privs) then
            -- Player should have the tool but does not: give one copy
            player:get_inventory():add_item("main", tool_name)
        elseif not mc_helpers.checkPrivs(player, data._mc_toolhandler_privs) then
            -- Player has the tool but should not: remove all copies
            while list do
                player:get_inventory():remove_item(list, tool_name)
                list = get_player_item_location(player, stack)
            end
        end
    end)

    -- Give the tool to any player who is granted adequate privileges
    minetest.register_on_priv_grant(function(name, granter, priv)
        -- Check if priv has an effect on the privileges needed for the tool
        if name == nil or not mc_helpers.tableHas(data._mc_toolhandler_privs, priv) or not minetest.get_player_by_name(name) then
            return true -- skip this callback, continue to next callback
        end
    
        local stack = ItemStack(tool_name)
        local player = minetest.get_player_by_name(name)
        local list = get_player_item_location(player, stack)

        if not list and mc_helpers.checkPrivs(player, data._mc_toolhandler_privs) then
            -- Player should have the tool but does not: give one copy
            player:get_inventory():add_item("main", tool_name)
        end

        return true -- continue to next callback
    end)
    
    -- Take the tool away from anyone who is revoked privileges and no longer has adequate ones
    minetest.register_on_priv_revoke(function(name, revoker, priv)
        -- Check if priv has an effect on the privileges needed for the tool
        if name == nil or not mc_helpers.tableHas(data._mc_toolhandler_privs, priv) or not minetest.get_player_by_name(name) then
            return true -- skip this callback, continue to next callback
        end
    
        local stack = ItemStack(tool_name)
        local player = minetest.get_player_by_name(name)
        local list = get_player_item_location(player, stack)
    
        if list and not mc_helpers.checkPrivs(player, data._mc_toolhandler_privs) then
            -- Player has the tool but should not: remove all copies
            while list do
                player:get_inventory():remove_item(list, tool_name)
                list = get_player_item_location(player, stack)
            end
        end
    
        return true -- continue to next callback
    end)
end

-- Register give/take callbacks for all MineTest classroom tools
for name,data in pairs(minetest.registered_tools) do
    for _,mod in pairs(register_tools_from) do
        if string.match(name, "^"..mod..":.*") and not data._mc_toolhandler_ignore then
            -- register give/take callbacks for tool
            register_callbacks(name, data)
        end
    end
end
