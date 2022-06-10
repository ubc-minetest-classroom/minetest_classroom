--- @public
--- Gets the detached toolbox inventory for player
--- @param player Player object
--- @return InvRef for player toolbox
function mc_toolmenu.get_toolbox(player)
    local pname = player:get_player_name()
    return minetest.get_inventory({type = "detached", name = "mc_toolmenu:"..pname})
end