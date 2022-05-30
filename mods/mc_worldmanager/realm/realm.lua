-- Realms are up-to 8 mapchunk areas seperated by a 4 mapchunk border of void (in each dimension);
-- TODO: add helper functions to do stuff like teleport players into the maps
-- TODO: assign realm ID based on first available ID rather than realm count

-- "const" values
local realmSize = 80 * 8 -- 8 mapchunks
local realmBuffer = 80 * 4
local realmHeight = 80 * 4

---@public
---Class that manages all realms in Minetest_Classroom.
---@class
Realm = { realmDict = {} }
Realm.__index = Realm


-- Load the different parts of our class from their individual files
-- This was done because this file started getting very big and very unmanageable.
-- In lua, this is an evil necessity for readability. That said, we should revisit this
-- in the future and re-organize into individual files based on function.
dofile(minetest.get_modpath("mc_worldmanager") .. "/realm/realmNodeManipulation.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/realm/realmDataManagement.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/realm/realmSchematicSaveLoad.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/realm/realmPlayerManagement.lua")

---@public
---The constructor for the realm class.
---@param name string
---@param size number
---@param height number
---@return table a new "Realm" table object / class.
function Realm:New(name, size, height)
    size = size or realmSize
    height = height or realmHeight

    if (name == nil or name == "") then
        name = "Unnamed Realm"
    end

    local this = {
        Name = name,
        ID = Realm.realmCount + 1,
        StartPos = { x = 0, y = 0, z = 0 },
        EndPos = { x = 0, y = 0, z = 0 },
        SpawnPoint = { x = 0, y = 0, z = 0 },
        PlayerJoinTable = {}, -- Table should be populated with tables as follows {{tableName=tableName, functionName=functionName}}
        PlayerLeaveTable = {}, -- Table should be populated with tables as follows {{tableName=tableName, functionName=functionName}}
        RealmDeleteTable = {}, -- Table should be populated with tables as follows {{tableName=tableName, functionName=functionName}}
        MetaStorage = {}
    }

    Realm.realmCount = this.ID

    -- Calculate where on the realm grid we are located; based on our realm ID
    local realmLocation = { x = 0, z = 0 }
    realmLocation.x = this.ID % 10
    realmLocation.z = math.ceil(this.ID / 10)

    -- Calculate our world position based on our location on the realm grid
    this.StartPos.x = -20000 + (realmSize * realmLocation.x) + (realmBuffer * realmLocation.x)
    this.StartPos.z = -20000 + (realmSize * realmLocation.z) + (realmBuffer * realmLocation.z)

    -- Ensures that a realm size is no larger than our maximum size.
    local finalRealmSize = math.min(realmSize, size)
    local finalRealmHeight = math.min(realmHeight, height)

    this.EndPos = { x = this.StartPos.x + finalRealmSize,
                    y = this.StartPos.y + finalRealmHeight,
                    z = this.StartPos.z + finalRealmSize }

    -- Temporary spawn point calculation
    this.SpawnPoint = { x = (this.StartPos.x + this.EndPos.x) / 2,
                        y = ((this.StartPos.y + this.EndPos.y) / 2) + 2,
                        z = (this.StartPos.z + this.EndPos.z) / 2 }

    setmetatable(this, self)
    table.insert(Realm.realmDict, this.ID, this)
    Realm.SaveDataToStorage()

    return this
end

---@public
---Deletes the realm based on class instance.
---NOTE: remember to clear any references to the realm so that memory can be released by the GC.
---@return void
function Realm:Delete()
    self:ClearNodes()
    table.remove(Realm.realmDict, self.ID)
    Realm.SaveDataToStorage()

    self:RunFunctionFromTable(self.RealmDeleteTable)
end

---LocalToWorldPosition
---@param position table coordinates
---@return table localspace coordinates.
function Realm:LocalToWorldPosition(position)
    local pos = position
    pos.x = pos.x + self.StartPos.x
    pos.y = pos.y + self.StartPos.y
    pos.z = pos.z + self.StartPos.z
    return pos
end

---WorldToLocalPosition
---@param position table
---@return table worldspace coordinates
function Realm:WorldToLocalPosition(position)
    local pos = position
    pos.x = pos.x - self.StartPos.x
    pos.y = pos.y - self.StartPos.y
    pos.z = pos.z - self.StartPos.z
    return pos
end

---@public
---Updates and saves the spawnpoint of a realm.
---@param spawnPos table SpawnPoint in localSpace.
---@return boolean Whether the operation succeeded.
function Realm:UpdateSpawn(spawnPos)
    local pos = self:LocalToWorldPosition(spawnPos)
    self.SpawnPoint = { x = pos.x, y = pos.y, z = pos.z }
    Realm.SaveDataToStorage()
    return true
end

function Realm:RunFunctionFromTable(table, player)
    if (table ~= nil) then
        for key, value in pairs(table) do

            if (value.tableName ~= nil and value.functionName ~= nil) then
                local table = loadstring("return " .. value.tableName)
                table[value.functionName](self,player)
                --table[value.functionName](self, player)
            end
        end
    end
end

Realm.LoadDataFromStorage()