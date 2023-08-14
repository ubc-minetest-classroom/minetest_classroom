-- Privilege registration
minetest.register_privilege("teacher", {
    give_to_singleplayer = true
})
minetest.register_privilege("student", {
    give_to_singleplayer = true
})

-- Ensures that we can use the server and Server usernames
minetest.register_on_prejoinplayer(function(name, ip)
    if (string.lower(name) == "server") then
        return "Invalid username: '" .. name .. "'. Please use a different name."
    end
end)

minetest.register_on_joinplayer(function(player)
    local pname = player:get_player_name()
    if mc_core.markers[pname] then
        mc_core.remove_marker(pname)
    end
    if mc_core.is_frozen(player) then
		mc_core.freeze(player)
	end
end)

minetest.register_on_respawnplayer(function(player)
    if mc_core.is_frozen(player) then
		mc_core.freeze(player)
	end
end)

minetest.register_on_leaveplayer(function(player)
    mc_core.hud:clear(player)
    local pname = player:get_player_name()
    if mc_core.markers[pname] then
        mc_core.remove_marker(pname)
    end
end)