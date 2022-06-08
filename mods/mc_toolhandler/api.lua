--- @public
--- Returns a constant and list name if the player's inventory or toolbox contains itemstack, nil otherwise
--- @param player MineTest player object
--- @param itemstack ItemStack object to check for
--- @return number, string or nil
function mc_toolhandler.get_player_item_location(player, itemstack)
    local inv = player:get_inventory()
    for list,_ in pairs(inv:get_lists()) do
        if inv:contains_item(list, itemstack) then
            return mc_toolhandler.MAIN_INV, list
        end
    end
    inv = mc_toolmenu.get_toolbox(player)
    for list,_ in pairs(inv:get_lists()) do
        if inv:contains_item(list, itemstack) then
            return mc_toolhandler.TOOLBOX, list
        end
    end
    return nil
end