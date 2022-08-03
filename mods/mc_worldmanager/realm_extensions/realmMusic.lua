realmExtensions.playerSounds = {}

Realm.RegisterOnJoinCallback(function(realm, player)
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
    if (realmExtensions.playerSounds[player:get_player_name()] ~= nil) then
        minetest.sound_stop(realmExtensions.playerSounds[player:get_player_name()])
        realmExtensions.playerSounds[player:get_player_name()] = nil
    end
end)