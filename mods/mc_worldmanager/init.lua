mc_worldManager = { storage = minetest.get_mod_storage() }
-- Source files
dofile(minetest.get_modpath("mc_worldmanager") .. "/refractor.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/realm.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/nodes.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/commands.lua")

function mc_worldManager.save_data()
    mc_worldManager.storage:set_string("spawnRealmID", tostring(mc_worldManager.spawnRealmID))
end

function mc_worldManager.load_data()
    mc_worldManager.spawnRealmID = tonumber(mc_worldManager.storage:get_string("spawnRealmID"))
end

mc_worldManager.load_data()

local function createSpawnRealm()
    local spawnRealm = Realm:New("Spawn Realm", 80, 80)
    mc_worldManager.spawnRealmID = spawnRealm.ID
    spawnRealm:CreateGround("stone")
    spawnRealm:CreateBarriers()
    mc_worldManager.save_data()
    return spawnRealm
end

function mc_worldManager.GetSpawnRealm()

    local spawnRealm = Realm.realmDict[mc_worldManager.spawnRealmID]
    if (spawnRealm == nil) then
        spawnRealm = createSpawnRealm()
    end
    return spawnRealm
end

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
