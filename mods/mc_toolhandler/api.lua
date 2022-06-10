--- @public
--- If itemstack is in player's inventory (or toolbox), returns name of list it is in. Otherwise, returns nil
--- @param player MineTest player object
--- @param itemstack ItemStack object to check for
--- @return string or nil
function mc_toolhandler.get_player_item_location(player, itemstack)
    local inv = player:get_inventory()
    for list,_ in pairs(inv:get_lists()) do
        if inv:contains_item(list, itemstack) then
            return list
        end
    end
    return nil
end