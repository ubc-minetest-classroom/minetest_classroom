-- on first player spawn, we assign them to the world spawn realm
-- and set their position to that spawnpoint .
minetest.register_on_newplayer(function(player)

    local spawnRealm = mc_worldManager.GetSpawnRealm()

    local pmeta = player:get_meta()
    pmeta:set_int("realm", spawnRealm.ID)

    player:set_pos(spawnRealm.SpawnPoint)
end)

-- When players respawn, we teleport them to the spawnpoint of the realm they belong to
minetest.register_on_respawnplayer(function(player)

    local pmeta = player:get_meta()
    local playerRealmID = pmeta:get_int("realm")

    local spawnRealm

    if (playerRealmID ~= nil) then
        spawnRealm = Realm.realmDict[playerRealmID]
    else
        spawnRealm = mc_worldManager.GetSpawnRealm()
    end

    player:set_pos(spawnRealm.SpawnPoint)
    return true
end)

-- When player joins the game, we create their hud
minetest.register_on_joinplayer(function(player, last_login)
    mc_worldManager.CreateHud(player)
end)

-- When player leave the game, we create their hud
minetest.register_on_leaveplayer(function(player, timed_out)
    mc_worldManager.RemoveHud(player)
end)
