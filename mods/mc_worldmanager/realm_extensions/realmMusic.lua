Realm.RegisterOnJoinCallback(function(realm, player)
    Debug.log("Calling on join callback")
    Debug.log("Player: " .. player:get_player_name())
    Debug.log("Realm: " .. realm:getName())

    local backgroundSound = realm:get_data("backgroundSound")
    if (backgroundSound ~= nil) then
        local reference = minetest.sound_play(backgroundSound, {
            to_player = player:get_player_name(),
            gain = 1.0,
            object = player,
            loop = true })

        realmExtensions.playerSounds[player:get_player_name()] = reference
    end

end)

Realm.RegisterOnLeaveCallback(function(realm, player)
    Debug.log("Calling on leave callback")
    Debug.log("Player: " .. player:get_player_name())
    Debug.log("Realm: " .. realm:getName())
end)