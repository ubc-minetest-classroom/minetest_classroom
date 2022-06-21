-- on first player spawn, we assign them to the world spawn realm
-- and set their position to that spawnpoint .
minetest.register_on_newplayer(function(player)
    local spawnRealm = mc_worldManager.GetSpawnRealm()
    spawnRealm:TeleportPlayer(player)
end)

-- When players respawn, we teleport them to the spawnpoint of the realm they belong to
minetest.register_on_respawnplayer(function(player)
    local realm = Realm.GetRealmFromPlayer(player)

    if (realm ~= nil) then
        player:set_pos(realm.SpawnPoint)
    else
        player:set_pos(mc_worldManager.GetSpawnRealm().SpawnPoint)
    end
    
    return true
end)

-- When player joins the game, we create their hud
minetest.register_on_joinplayer(function(player, last_login)
    mc_worldManager.CreateHud(player)

    local realm = Realm.GetRealmFromPlayer(player)
    if (realm ~= nil) then
        realm:AddPlayer(player)
    end

end)

-- When player leave the game, we create their hud
minetest.register_on_leaveplayer(function(player, timed_out)
    mc_worldManager.RemoveHud(player)

    local realm = Realm.GetRealmFromPlayer(player)
    if (realm ~= nil) then
        realm:RemovePlayer(player)
    end

end)

minetest.register_on_shutdown(function()
    Realm.SaveDataToStorage()
end)
