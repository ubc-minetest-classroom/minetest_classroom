realmExtensions = {}

realmExtensions.playerSounds = {}

function realmExtensions.playbackgroundSound(realm, player)
    Debug.log("Trying to play background music for realm " .. realm.Name)
    local backgroundSound = realm:get_data("backgroundSound")
    if (backgroundSound ~= nil) then
        local reference = minetest.sound_play(backgroundSound, {
            to_player = player:get_player_name(),
            gain = 1.0,
            object = player,
            loop = true })

        realmExtensions.playerSounds[player:get_player_name()] = reference
    end
end