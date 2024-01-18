mc_worldManager = {
    storage = minetest.get_mod_storage(),
    path = minetest.get_modpath("mc_worldmanager"),
    spawnRealmSchematic = "vancouver_osm",
    hud = mhud.init()
}

-- Include our source files
dofile(minetest.get_modpath("mc_worldmanager") .. "/realm/realm.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/nodes.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/commands.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/schematicmanager.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/hooks.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/hud.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/universalPrivilege.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/teleporterNode.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/WorldGen.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/realm_extensions/realmExtensions.lua")

-- Scan the world realm schematics folder and add them to the schematics list.
local files = minetest.get_dir_list(minetest.get_worldpath() .. "\\realmSchematics\\", false)
if files then minetest.chat_send_all("DEBUG: schematic files is not nil") end
for k, fileName in pairs(files) do
    local filePath = minetest.get_worldpath() .. "\\realmSchematics\\" .. fileName
    local ext = string.sub(filePath, -5)
    if (ext == ".conf") then
        local path = string.sub(filePath, 1, -6)
        local key = string.sub(fileName, 1, -6)
        schematicManager.registerSchematicPath(key, path)
        minetest.chat_send_all("DEBUG: Registered schematic key "..key.." at path "..path)
    end
end

---@private
---Loads the persistent mod data for mc_worldManager.
---@return void
function mc_worldManager.save_data()
    mc_worldManager.storage:set_string("spawnRealmID", tostring(mc_worldManager.spawnRealmID))
end

---@private
---Saves the persistent mod data for mc_worldManager.
---@return void
function mc_worldManager.load_data()
    mc_worldManager.spawnRealmID = tonumber(mc_worldManager.storage:get_string("spawnRealmID"))
end

mc_worldManager.load_data()

---@public
---Gets the spawn realm of the world.
---It's important to use this function to grab the world spawn to ensure that it always exists.
---Note that although the realm ID for spawn is usually 1, it can change without notice.
---This function ensures that systems that rely on a spawn don't break.
---@return table Realm
function mc_worldManager.GetSpawnRealm()
    local spawnRealm = Realm.GetRealm(mc_worldManager.spawnRealmID)
    if (spawnRealm == nil) then
        spawnRealm = Realm:NewFromSchematic("Spawn", mc_worldManager.spawnRealmSchematic)
        spawnRealm:setCategoryKey("spawn")
        mc_worldManager.spawnRealmID = spawnRealm.ID
        mc_worldManager.save_data()
    end
    return spawnRealm
end

---@public
---Sets the world spawn realm to the realm supplied in param newSpawnRealm.
---@param newSpawnRealm table realm to set as spawn.
---@return boolean whether the operation succeeded or not.
function mc_worldManager.SetSpawnRealm(newSpawnRealm)
    if (newSpawnRealm ~= nil) then
        if (mc_worldManager.SpawnGenerated()) then
            local oldSpawnRealm = mc_worldManager.GetSpawnRealm()
            oldSpawnRealm:setCategoryKey("default")
        end
        mc_worldManager.spawnRealmID = newSpawnRealm.ID
        newSpawnRealm:setCategoryKey("spawn")
        mc_worldManager.save_data()
        return true
    end
    return false
end

---@public
---Returns whether or not spawn has been generated.
---@return boolean whether or not spawn has been generated.
function mc_worldManager.SpawnGenerated()
    return Realm.realmDict[mc_worldManager.spawnRealmID] ~= nil
end

function mc_worldManager.GetRealmByName(realmName)
    for _, realm in pairs(Realm.realmDict) do
        if (realm.Name == realmName and not realm:isDeleted()) then
            return realm
        end
    end
    return nil
end

function mc_worldManager.GetCreateInstancedRealm(realmName, player, schematic, temporary, size)
    local pmeta = player:get_meta()
    local realmKey = realmName:lower()
    local realmSize = size or {}

    local realmInstanceTable = minetest.deserialize(pmeta:get_string("mc_worldmanager_realm_instances"))
    if (realmInstanceTable == nil) then
        realmInstanceTable = {}
    end

    if (mc_worldManager.KeyIDTable == nil) then
        mc_worldManager.KeyIDTable = {}
    end

    local realm = mc_worldManager.KeyIDTable[realmKey]

    if (realm == nil) then
        if (schematic == nil or schematic == "" or schematic == "nil") then
            realm = Realm:New(realmName, {x = realmSize.x or 80, y = realmSize.y or 80, z = realmSize.z or 80})
            realm:CreateGround()
            realm:CreateBarriers()
        else
            realm = Realm:NewFromSchematic(realmName, schematic)
        end

        realmInstanceTable[realmKey] = realm.ID
        realm:setCategoryKey("instanced")
        realm:AddOwner(player:get_player_name())

        if (temporary == nil) then
            temporary = false
        end

        if (temporary) then
            table.insert(realm.PlayerLeaveTable, { tableName = "mc_worldManager", functionName = "InstancedDelete" })
        end

    end

    return realm
end

function mc_worldManager.InstancedDelete(realm, player)
    local owners = realm:GetOwners()

    if (owners ~= nil and owners[player:get_player_name()] ~= nil) then
        realm:Delete()
    end
end

-- Registration
schematicManager.registerSchematicPath("shack", mc_worldManager.path .. "/schematics/shack")
