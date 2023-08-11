Realm.tempData = {}


---@private
---Loads the persistant global data for the realm class
---@return void
function Realm.LoadDataFromStorage()
    Realm.realmCount = tonumber(mc_worldManager.storage:get_string("realmCount"))
    if Realm.realmCount == nil then
        Realm.realmCount = 0
    end

    Realm.lastRealmPosition = minetest.deserialize(mc_worldManager.storage:get_string("realmLastPosition"))
    if Realm.lastRealmPosition == nil then
        Realm.lastRealmPosition = { x = 0, y = 0, z = 0 }
    end

    Realm.maxRealmSize = minetest.deserialize(mc_worldManager.storage:get_string("realmMaxSize"))
    if Realm.maxRealmSize == nil then
        Realm.maxRealmSize = { x = 0, y = 0, z = 0 }
    end

    Realm.EmptyChunks = minetest.deserialize(mc_worldManager.storage:get_string("realmEmptyChunks"))
    if Realm.EmptyChunks == nil then
        Realm.EmptyChunks = {}
    end

    local tmpRealmDict = minetest.deserialize(mc_worldManager.storage:get_string("realmDict"))
    if tmpRealmDict == nil then
        tmpRealmDict = {}
    end

    for key, realm in pairs(tmpRealmDict) do
        Realm:Restore(realm)
    end
end

---@private
---Saves the persistant global data for the realm class
---@return void
function Realm.SaveDataToStorage()
    mc_worldManager.storage:set_string("realmDict", minetest.serialize(Realm.realmDict))
    mc_worldManager.storage:set_string("realmCount", tostring(Realm.realmCount))

    mc_worldManager.storage:set_string("realmLastPosition", minetest.serialize(Realm.lastRealmPosition))
    mc_worldManager.storage:set_string("realmMaxSize", minetest.serialize(Realm.maxRealmSize))
    mc_worldManager.storage:set_string("realmMaxSize", minetest.serialize(Realm.maxRealmSize))
    mc_worldManager.storage:set_string("realmEmptyChunks", minetest.serialize(Realm.EmptyChunks))
end

---@private
---Restores a dimension based on supplied parameters. Do not use this method to make new dimensions; use Realm:New() instead
---@return self
function Realm:Restore(template)

    --We are sanitizing input to help stop shenanigans from happening
    local this = {
        Name = tostring(template.Name),
        ID = tonumber(template.ID),
        StartPos = { x = template.StartPos.x, y = template.StartPos.y, z = template.StartPos.z },
        EndPos = { x = template.EndPos.x, y = template.EndPos.y, z = template.EndPos.z },
        SpawnPoint = { x = template.SpawnPoint.x, y = template.SpawnPoint.y, z = template.SpawnPoint.z },
        PlayerJoinTable = template.PlayerJoinTable,
        PlayerLeaveTable = template.PlayerLeaveTable,
        RealmDeleteTable = template.RealmDeleteTable,
        Permissions = template.Permissions,
        PermissionsOverride = template.PermissionsOverride,
        MetaStorage = template.MetaStorage
    }

    --Reconstruct the class metatables
    setmetatable(this, self)

    --Insert ourselves into the realmDict
    table.insert(Realm.realmDict, this.ID, this)
    return this
end

---@public
---set_data
---Saves data into the realms metadata. This data will be serialized and saved with the realm.
---@param key any
---@param value any
function Realm:set_data(key, value)
    if (self.MetaStorage == nil) then
        self.MetaStorage = {}
    end

    self.MetaStorage[key] = value
end

---@public
---get_data
---Retrieves data from the realms metadata.
---@param key any
---@return any
function Realm:get_data(key)
    if (self.MetaStorage == nil) then
        self.MetaStorage = {}
    end

    return self.MetaStorage[key]
end

---@public
---set_tmpData
---Saves data into temporary realm metadata. This data is not saved with the realm.
---@param key any
---@param value any
function Realm:set_tmpData(key, value)
    if (Realm.tempData[self] == nil) then
        Realm.tempData[self] = {}
    end

    Realm.tempData[self][string.lower(key)] = value
end

---@public
---get_data
---Retrieves data from the realms temporary metadata.
---@param key any
---@return any
function Realm:get_tmpData(key)
    if (Realm.tempData[self] == nil) then
        Realm.tempData[self] = {}
    end

    return Realm.tempData[self][string.lower(key)]
end
