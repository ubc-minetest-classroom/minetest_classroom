


-- on player spawn, we teleport them to the world spawn.
minetest.register_on_newplayer(function(player)

    local spawnRealm = mc_worldManager.GetSpawnRealm()

    player:set_pos(spawnRealm.SpawnPoint)
end)

minetest.register_on_respawnplayer(function(player)
    local spawnRealm = mc_worldManager.GetSpawnRealm()

    player:set_pos(spawnRealm.SpawnPoint)
    return true
end)
