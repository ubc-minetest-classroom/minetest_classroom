-- on player spawn, we teleport them to the world spawn.
minetest.register_on_newplayer(function(player)

    local spawnRealm = mc_worldManager.GetSpawnRealm()

    local pmeta = player:get_meta()
    pmeta:set_int("realm",spawnRealm.ID)


    player:set_pos(spawnRealm.SpawnPoint)
end)

-- When players respawn, we also teleport them to the world spawn.
-- This might be changed in the future to spawn the players at their own spawn;
-- could be set by travelling to other realms?
minetest.register_on_respawnplayer(function(player)
    local spawnRealm = mc_worldManager.GetSpawnRealm()

    player:set_pos(spawnRealm.SpawnPoint)
    return true
end)
