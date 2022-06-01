-- Realms are up-to 8 mapchunk areas seperated by a 4 mapchunk border of void (in each dimension);
-- TODO: add helper functions to do stuff like teleport players into the maps
-- TODO: assign realm ID based on first available ID rather than realm count

-- "const" values
local realmSize = 80 * 8 -- 8 mapchunks
local realmHeight = 80 * 4

---@public
---Class that manages all realms in Minetest_Classroom.
---@class
Realm = { realmDict = {}, const = { worldSize = math.floor(30000), worldGridLimit = math.floor((30927 * 2) / 80), bufferSize = 0 } }
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
---@param name string The name of the realm
---@param area table Size of the realm in {x,y,z} format
---@return table a new "Realm" table object / class.
function Realm:New(name, area)

    area.x = area.x or 80
    area.y = area.y or 80
    area.z = area.z or 80

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

    local gridStartPos, gridEndPos = Realm.CalculateStartEndPosition(this, area)

    -- Calculate our world position based on our location on the realm grid
    this.StartPos = {
        x = -Realm.const.worldSize + (gridStartPos.x * 80),
        y = -Realm.const.worldSize + (gridStartPos.y * 80),
        z = -Realm.const.worldSize + (gridStartPos.z * 80) }

    this.EndPos = {
        x = -Realm.const.worldSize + (gridEndPos.x * 80),
        y = -Realm.const.worldSize + (gridEndPos.y * 80),
        z = -Realm.const.worldSize + (gridEndPos.z * 80) }


    -- Temporary spawn point calculation
    this.SpawnPoint = { x = (this.StartPos.x + this.EndPos.x) / 2,
                        y = ((this.StartPos.y + this.EndPos.y) / 2) + 2,
                        z = (this.StartPos.z + this.EndPos.z) / 2 }

    setmetatable(this, self)
    table.insert(Realm.realmDict, this.ID, this)
    Realm.SaveDataToStorage()

    return this
end

-- We'll use a mapchunk has the smallest denominator for world delineation
-- What we'll do is keep track of the last realm position as well as areas where realms were deleted.
-- When creating a new realm, we'll see if the empty space we have can contain a new realm. If it can't,
-- We'll create the realm after the last realm position.

Realm.lastRealmPosition = { x = Realm.const.bufferSize, y = Realm.const.bufferSize, z = Realm.const.bufferSize }
Realm.EmptyChunks = {}

function Realm.CalculateStartEndPosition(thisTable, areaInBlocks)
    -- Note that all of the coordinates used in this function are in "gridSpace"
    -- This roughly correlates to the chunk coordinates in MineTest
    -- 1 unit in gridSpace is 80 blocks in worldSpace

    minetest.debug("areaInBlocks size:" .. " " .. areaInBlocks.x .. " " .. areaInBlocks.y .. " " .. areaInBlocks.z)

    local StartPos = Realm.lastRealmPosition

    -- Calculate our start position on the grid
    StartPos.x = StartPos.x + Realm.const.bufferSize

    if (StartPos.x > (Realm.const.worldGridLimit)) then
        StartPos.z = Realm.lastRealmPosition.z + Realm.const.bufferSize
        StartPos.x = 0
    end

    if (StartPos.z > (Realm.const.worldGridLimit)) then
        StartPos.y = Realm.lastRealmPosition.y + Realm.const.bufferSize
        StartPos.z = 0
    end

    if (StartPos.y > (Realm.const.worldGridLimit)) then
        assert(StartPos.y, "Unable to create another realm; world has been completely filled. Please delete a realm and try again.")
    end

    -- calculate our realm size in grid units
    local realmSize = { x = math.ceil(areaInBlocks.x / 80),
                        y = math.ceil(areaInBlocks.y / 80),
                        z = math.ceil(areaInBlocks.z / 80) }

    minetest.debug("realmSize:" .. " " .. realmSize.x .. " " .. realmSize.y .. " " .. realmSize.z)




    -- Calculate our end position on the grid
    local EndPos = { x = 0, y = 0, z = 0 }
    EndPos = { x = StartPos.x + realmSize.x,
               y = StartPos.y + realmSize.y,
               z = StartPos.z + realmSize.z }

    Realm.lastRealmPosition = EndPos

    return StartPos, EndPos
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
                table()[value.functionName](self, player)
            end
        end
    end
end

Realm.LoadDataFromStorage()