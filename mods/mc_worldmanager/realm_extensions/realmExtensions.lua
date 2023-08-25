realmExtensions = {}

dofile(minetest.get_modpath("mc_worldmanager") .. "/realm_extensions/realmMusic.lua")

Realm.RegisterOnJoinCallback(function(realm, player)
    minetest.sound_play("teleport", {to_player = player:get_player_name(), gain = 1.0, pitch = 1.0,}, true)
end)