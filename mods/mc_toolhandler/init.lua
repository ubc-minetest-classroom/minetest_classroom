-- global constants
mc_toolhandler = {
    MAIN_INV = 1, -- player inventory
    TOOLBOX = 2 -- player toolbox
}
dofile(minetest.get_modpath("mc_toolhandler") .. "/api.lua")

-- will be replaced with dynamic code later
local register_tools_from = {--[["mc_teacher", "mc_student",]] "magnify"}

-- Registers give/take callbacks for all applicable tools
local function register_callbacks(tool_name, data)
    -- Give the tool to any player who joins with adequate privileges or take it away if they do not have them
    minetest.register_on_joinplayer(function(player)
        local stack = ItemStack(tool_name)
        local location,list = mc_toolhandler.get_player_item_location(player, stack)

        if location then
            -- Player has the tool
            if not mc_helpers.checkPrivs(player, data._mc_toolhandler_privs) then
                -- The player should not have the tool; remove it
                if location == mc_toolhandler.MAIN_INV then
                    player:get_inventory():remove_item(list, tool_name)
                elseif location == mc_toolhandler.TOOLBOX then
                    mc_toolmenu.get_toolbox(player):remove_item(list, tool_name)
                end 
            end
        elseif mc_helpers.checkPrivs(player, data._mc_toolhandler_privs) then
            -- The player should have the tool; give it
            player:get_inventory():add_item("main", tool_name)
        end
    end)

    -- Give the tool to any player who is granted adequate privileges
    minetest.register_on_priv_grant(function(name, granter, priv)
        -- Check if priv has an effect on the privileges needed for the tool
        if name == nil or not mc_helpers.tableHas(data._mc_toolhandler_privs, priv) or not minetest.get_player_by_name(name) then
            return true -- skip this callback, continue to next callback
        end
    
        local player = minetest.get_player_by_name(name)
        local location,list = mc_toolhandler.get_player_item_location(player, stack)
        minetest.log(location)
        minetest.log(list)

        if not location and mc_helpers.checkPrivs(player, data._mc_toolhandler_privs) then
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
    
        local player = minetest.get_player_by_name(name)
        local location,list = mc_toolhandler.get_player_item_location(player, stack)
        --local inv = player:get_inventory()
    
        if location and not mc_helpers.checkPrivs(player, data._mc_toolhandler_privs) then
            if location == mc_toolhandler.MAIN_INV then
                player:get_inventory():remove_item(list, tool_name)
            elseif location == mc_toolhandler.TOOLBOX then
                mc_toolmenu.get_toolbox(player):remove_item(list, tool_name)
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
