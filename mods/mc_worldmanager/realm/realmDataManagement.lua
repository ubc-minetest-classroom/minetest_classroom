---@private
---Loads the persistant global data for the realm class
---@return void
function Realm.LoadDataFromStorage()
    Realm.realmCount = tonumber(mc_worldManager.storage:get_string("realmCount"))
    if Realm.realmCount == nil then
        Realm.realmCount = 0
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
function Realm.SaveDataToStorage ()
    mc_worldManager.storage:set_string("realmDict", minetest.serialize(Realm.realmDict))
    mc_worldManager.storage:set_string("realmCount", tostring(Realm.realmCount))
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
        MetaStorage = template.MetaStorage
    }

    --Reconstruct the class metatables
    setmetatable(this, self)

    --Insert ourselves into the realmDict
    table.insert(Realm.realmDict, this.ID, this)
    return this
end


function Realm:set_string(key, value)
    self.MetaStorage[key] = value
end

function Realm:get_string(key)
    return self.MetaStorage[key]
end

function Realm:set_int(key, value)
    self.MetaStorage[key] = tostring(value)
end

function Realm:get_int(key)
    return tonumber(self.MetaStorage[key])
end