realmExtensions.playerSounds = {}

Realm.RegisterOnJoinCallback(function(realm, player)
    realm:ApplyMusic(player)
end)

-- TODO: programmatically make names look nicer in GUI without changing names internally
function Realm.GetRegisteredMusic()
    local sounds = {}
    for _,file in pairs(minetest.get_dir_list(mc_worldManager.path.."/sounds/music", false)) do
        if string.sub(file, -4) == ".ogg" then
            table.insert(sounds, string.sub(file, 1, -5))
        end
    end
    return sounds
end

function Realm:UpdateMusic(sound, volume)
    self:set_data("background_sound", sound or nil)
    self:set_data("background_volume", volume and volume/100 or nil)
    Realm.SaveDataToStorage()
end

function Realm:GetMusic()
    return self:get_data("background_sound") or "none"
end

function Realm:ApplyMusic(player)
    -- clear previous sound
    if (realmExtensions.playerSounds[player:get_player_name()] ~= nil) then
        minetest.sound_stop(realmExtensions.playerSounds[player:get_player_name()])
        realmExtensions.playerSounds[player:get_player_name()] = nil
    end

    -- apply new sound
    local backgroundSound = self:GetMusic()
    local backgroundVolume = tonumber(self:get_data("background_volume")) or 1.0
    if (backgroundSound ~= nil) then
        local reference = minetest.sound_play(backgroundSound, {
            to_player = player:get_player_name(),
            gain = backgroundVolume,
            object = player,
            loop = true
        })
        realmExtensions.playerSounds[player:get_player_name()] = reference
    end
end
