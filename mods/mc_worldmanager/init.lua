mc_worldManager = { storage = minetest.get_mod_storage(), path = minetest.get_modpath("mc_worldmanager") }
-- Source files
dofile(minetest.get_modpath("mc_worldmanager") .. "/refractor.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/realm.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/nodes.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/commands.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/schematicmanager.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/hooks.lua")

function mc_worldManager.save_data()
    mc_worldManager.storage:set_string("spawnRealmID", tostring(mc_worldManager.spawnRealmID))
end

function mc_worldManager.load_data()
    mc_worldManager.spawnRealmID = tonumber(mc_worldManager.storage:get_string("spawnRealmID"))
end

mc_worldManager.load_data()

function mc_worldManager.GetSpawnRealm()

    local spawnRealm = Realm.realmDict[mc_worldManager.spawnRealmID]
    if (spawnRealm == nil) then
        spawnRealm = Realm:New("Spawn Realm", 80, 80)
        mc_worldManager.spawnRealmID = spawnRealm.ID
        local results = spawnRealm:Load_Schematic("vancouver_osm")
        spawnRealm:CreateBarriers()
        minetest.debug(tostring(results))
        mc_worldManager.save_data()
    end
    return spawnRealm
end


schematicManager.registerSchematicPath("shack", mc_worldManager.path .. "/schematics/shack.mts")

