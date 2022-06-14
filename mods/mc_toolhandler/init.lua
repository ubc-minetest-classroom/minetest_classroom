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

        if not list and mc_helpers.checkPrivs(player, data._mc_tool_privs) then
            -- Player should have the tool but does not: give one copy
            player:get_inventory():add_item("main", tool_name)
        elseif not mc_helpers.checkPrivs(player, data._mc_tool_privs) then
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
        if name == nil or not mc_helpers.tableHas(data._mc_tool_privs, priv) or not minetest.get_player_by_name(name) then
            return true -- skip this callback, continue to next callback
        end
    
        local stack = ItemStack(tool_name)
        local player = minetest.get_player_by_name(name)
        local list = get_player_item_location(player, stack)

        if not list and mc_helpers.checkPrivs(player, data._mc_tool_privs) then
            -- Player should have the tool but does not: give one copy
            player:get_inventory():add_item("main", tool_name)
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
            while list do
                player:get_inventory():remove_item(list, tool_name)
                list = get_player_item_location(player, stack)
            end
        end
    
        return true -- continue to next callback
    end)
end

-- Open and read mod.conf file from iterator
local register_tools_from = {} 
local conf_reader = io.lines(minetest.get_modpath("mc_toolhandler") .. "/mod.conf")
elem = conf_reader()
while elem do
    -- Manage tools for all optional dependencies 
    local match = string.match(elem, "^optional_depends = (.*)")
    if match then
        local mods = string.split(match, ",")
        for _,mod in pairs(mods) do
            table.insert(register_tools_from, string.trim(mod))
        end
    end
    -- get next element, break from loop if none
    elem = conf_reader()
    if not elem then break end
end

-- Register give/take callbacks for all MineTest classroom tools
for name,data in pairs(minetest.registered_tools) do
    for _,mod in pairs(register_tools_from) do
        if data._mc_tool_include or data._mc_tool_privs and (data.mod_origin == mod or string.match(name, "^"..mod..":.*")) then
            -- register give/take callbacks for tool
            register_callbacks(name, data)
        end
    end
end
