local function check_perm(player)
    return minetest.check_player_privs(player:get_player_name(), { teacher = true })
end

function mc_worldManager.place_map(player,map_name,pos)
    local pname = player:get_player_name()
    if check_perm(player) then
        minetest.place_schematic(pos, minetest.get_modpath("mc_teacher").."/maps/"..map_name..".mts", 0, nil, true)
    else
        minetest.chat_send_player(pname,pname..": You do not have the teacher privilege to create a new map. Check with the server administrator.")
    end
end



