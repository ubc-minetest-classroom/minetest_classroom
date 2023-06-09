-- Realms are up-to 8 mapchunk areas seperated by a 4 mapchunk border of void (in each dimension);
-- TODO: assign realm ID based on first available ID rather than realm count

-- "const" values
local realmSize = 80 * 8 -- 8 mapchunks
local realmHeight = 80 * 4

---@public
---Class that manages all realms in Minetest_Classroom.
---@class
Realm = { realmDict = {}, const = { worldSize = math.floor(30000), worldGridLimit = math.floor((30927 * 2) / 80), bufferSize = 4 } }
Realm.__index = Realm


-- Load the different parts of our class from their individual files
-- This was done because this file started getting very big and very unmanageable.
-- In lua, this is an evil necessity for readability. That said, we should revisit this
-- in the future and re-organize into individual files based on function.
dofile(minetest.get_modpath("mc_worldmanager") .. "/realm/realmNodeManipulation.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/realm/realmDataManagement.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/realm/realmSchematicSaveLoad.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/realm/realmRealTerrainLoad.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/realm/realmPlayerManagement.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/realm/realmCoordinateConversion.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/realm/realmPrivileges.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/realm/realmIntegrationHelpers.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/realm/realmCategory.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/realm/realmTerrainGeneration.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/realm/realmEntityManipulation.lua")

if (areas) then
    dofile(minetest.get_modpath("mc_worldmanager") .. "/realm/realmAreasIntegration.lua")
end

---@public
---The constructor for the realm class.
---@param name string The name of the realm
---@param area table Size of the realm in {x,y,z} format
---@return table a new "Realm" table object / class.
function Realm:New(name, area, callbacks)

    if (callbacks == nil) then
        callbacks = true
    end

    if (area.x == nil or area.x == 0) then
        area.x = 80
    end

    if (area.y == nil or area.y == 0) then
        area.y = 80
    end

    if (area.z == nil or area.z == 0) then
        area.z = 80
    end

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
        Permissions = {},
        PermissionsOverride = {},
        MetaStorage = {}
    }

    setmetatable(this, self)
    Realm.realmDict[this.ID] = this

    Realm.realmCount = this.ID

    local gridStartPos, gridEndPos = Realm.CalculateStartEndPosition(area)

    -- Calculate our world position based on our location on the realm grid
    this.StartPos = Realm.gridToWorldSpace(gridStartPos)
    this.EndPos = Realm.gridToWorldSpace(gridEndPos)


    -- Temporary spawn point calculation
    this.SpawnPoint = { x = (this.StartPos.x + this.EndPos.x) / 2,
                        y = (this.StartPos.y + 2),
                        z = (this.StartPos.z + this.EndPos.z) / 2 }

    -- if (areas) then
    --     local protectionID = areas:add("Server", this.ID .. this.Name, this.StartPos, this.EndPos)
    --     this:set_data("protectionID", protectionID)
    --     areas:save()
    -- end

    Realm.SaveDataToStorage()

    if (callbacks) then
        this:CallOnCreateCallbacks()
    end

    return this
end

---GetRealm
---@param ID number
---Returns the realm corresponding to the ID parameter.
function Realm.GetRealm(ID)
    return Realm.realmDict[tonumber(ID)]
end

-- Online bin packing... A pretty challenging problem to solve.
-- To simplify the problem, we'll create new bins for each new realm we make.
-- When we need to create new realms, we'll run the bin packing algorithm
-- If the realm doesn't fit into any of the existing bins, we'll create a new one.

-- We'll use a mapchunk has the smallest denominator for world delineation
-- What we'll do is keep track of the last realm position as well as areas where realms were deleted.
-- When creating a new realm, we'll see if the empty space we have can contain a new realm. If it can't,
-- We'll create the realm after the last realm position.
Realm.lastRealmPosition = { xStart = Realm.const.bufferSize,
                            yStart = Realm.const.bufferSize,
                            zStart = Realm.const.bufferSize }

Realm.maxRealmSize = { x = 0, y = 0, z = 0 }
Realm.EmptyChunks = {}

function Realm.CalculateStartEndPosition(areaInBlocks)

    -- Note that all of the coordinates used in this function are in "gridSpace"
    -- This roughly correlates to the chunk coordinates in MineTest
    -- 1 unit in gridSpace is 80 blocks in worldSpace

    -- calculate our realm size in grid units
    local realmSize = { x = math.ceil(areaInBlocks.x / 80),
                        y = math.ceil(areaInBlocks.y / 80),
                        z = math.ceil(areaInBlocks.z / 80) }

    local reuseBin = false
    local StartPos = { x = 0, y = 0, z = 0 }
    local BinEndPos = { x = 0, y = 0, z = 0 }

    for i, v in ipairs(Realm.EmptyChunks) do
        if (v.area.x >= realmSize.x + Realm.const.bufferSize and v.area.y >= realmSize.y + Realm.const.bufferSize and v.area.z >= realmSize.z + Realm.const.bufferSize) then
            table.remove(Realm.EmptyChunks, i)
            StartPos = { x = v.startPos.x + Realm.const.bufferSize, y = v.startPos.y + Realm.const.bufferSize, z = v.startPos.z + Realm.const.bufferSize }
            BinEndPos = { x = v.startPos.x + v.area.x, y = v.startPos.y + v.area.y, v.startPos.z + v.area.z }
            reuseBin = true
            break
        end
    end

    if (reuseBin == false) then
        StartPos = Realm.lastRealmPosition

        -- Calculate our start position on the grid. We're lining realms up on the X-Pos
        StartPos.x = Realm.maxRealmSize.x + Realm.const.bufferSize

        if (StartPos.x > (Realm.const.worldGridLimit)) then
            StartPos.z = Realm.maxRealmSize.z + Realm.const.bufferSize
            StartPos.x = 0
            Realm.maxRealmSize.x = 0
        end

        if (StartPos.z > (Realm.const.worldGridLimit)) then
            StartPos.y = Realm.maxRealmSize.y + Realm.const.bufferSize
            StartPos.x = 0
            StartPos.z = 0
            Realm.maxRealmSize.x = 0
            Realm.maxRealmSize.z = 0
        end

        if (StartPos.y > (Realm.const.worldGridLimit)) then
            assert(StartPos.y, "Unable to create another realm; world has been completely filled. Please delete a realm and try again.")
        end
    end


    -- Calculate our end position on the grid
    local EndPos = { x = 0, y = 0, z = 0 }
    EndPos = { x = StartPos.x + realmSize.x,
               y = StartPos.y + realmSize.y,
               z = StartPos.z + realmSize.z }

    if (reuseBin == false) then
        -- If the realm EndPos was larger than anything before, we make sure to update it;
        -- This ensures that we don't try to place a realm on another realm;
        if (EndPos.x > Realm.maxRealmSize.x) then
            Realm.maxRealmSize.x = EndPos.x
        end

        if (EndPos.y > Realm.maxRealmSize.y) then
            Realm.maxRealmSize.y = EndPos.y
        end

        if (EndPos.z > Realm.maxRealmSize.z) then
            Realm.maxRealmSize.z = EndPos.z
        end
        BinEndPos = Realm.maxRealmSize
    end

    -- We're checking reuseBin multiple times
    if (reuseBin == true) then

        local emptySpace = {
            top = { startPos = { x = StartPos.x, y = EndPos.y, z = StartPos.z, }, endPos = { x = EndPos.x, y = BinEndPos.y, x = EndPos.z } },
            xAxis = { startPos = { x = EndPos.x, y = StartPos.y, z = StartPos.z, }, endPos = { x = BinEndPos.x, y = EndPos.y, z = EndPos.z } },
            zAxis = { startPos = { x = StartPos.z, y = StartPos.y, z = EndPos.z, }, endPos = { x = EndPos.z, y = EndPos.y, z = BinEndPos.z } }
        }

        Realm.markSpaceAsFree(emptySpace.top.startPos, emptySpace.top.endPos)
        Realm.markSpaceAsFree(emptySpace.xAxis.startPos, emptySpace.xAxis.endPos)
        Realm.markSpaceAsFree(emptySpace.zAxis.startPos, emptySpace.zAxis.endPos)
    end

    mc_worldManager.storage:set_string("realmEmptyChunks", minetest.serialize(Realm.EmptyChunks))

    return StartPos, EndPos
end

function Realm.markSpaceAsFree(startPos, endPos)
    Debug.logCoords(startPos, "start pos")
    Debug.logCoords(endPos, "end pos")

    -- Crashes on a value of 3 when deleting spawns, but only when deleting spawns. I don't know why.
    -- The values in the calling function 'Delete' are all correct.
    -- Somehow, the value is turning from '3' to nil between method calls.
    if (endPos.z == nil) then
        endPos.z = startPos.z
        Debug.log("endPos.z is nil")
    end

    local entry = {}
    entry.startPos = { x = startPos.x, y = startPos.y, z = startPos.z }
    entry.area = { x = endPos.x - startPos.x,
                   y = endPos.y - startPos.y,
                   z = endPos.z - startPos.z }

    table.insert(Realm.EmptyChunks, entry)
end

function Realm.consolidateEmptySpace()
    -- Generate a point grid from the freespace table
    -- Generate volumes from the point data
    -- replace the freespace table
    local pointGrid = {  }

    -- There is a much more elegant solution that can generate these points quicker than O(n^4);
    -- That said, it's a bit more complex so I'll leave this simple code for now
    -- When there is lots of empty space, this might use a lot of memory; but it needs more testing
    for k, entry in pairs(Realm.EmptyChunks) do
        for x = entry.startPos.x, entry.startPos.x + entry.area.x do
            for y = entry.startPos.y, entry.startPos.y + entry.area.y do
                for z = entry.startPos.z, entry.startPos.z + entry.area.z do
                    ptable.store(pointGrid, { x = x, y = y, z = z }, true)
                end
            end
        end
    end

    -- Run a nearest neighbor search to group points up according to their neighbors
    local function buildGroups(pointGrid)

        local function isNeighbor(lastPos, currentPos, coord)
            local difference = math.abs(currentPos - lastPos)
            if (difference == 0 or difference == 1) then
                return true
            end
            return false
        end

        local groups = {}
        local groupCounter = 0

        local repeatFlag = false

        while (repeatFlag) do
            repeatFlag = false
            local lastX = nil
            local lastY = nil
            local lastZ = nil

            for kx, xTable in mc_core.pairsByKeys(pointGrid) do
                if (lastX == nil) then
                    lastX = kx
                end

                lastY = nil
                lastZ = nil

                if (isNeighbor(lastX, kx, "x")) then
                    lastX = kx
                else
                    groupCounter = groupCounter + 1

                    -- Alternative of GOTO is a while loop with a boolean flag
                    repeatFlag = true
                    break
                end

                if (repeatFlag == false) then
                    for ky, yTable in mc_core.pairsByKeys(xTable) do
                        if (lastY == nil) then
                            lastY = ky
                        end

                        if (isNeighbor(lastY, ky, "y")) then
                            lastY = ky
                        else

                            break
                        end

                        for kz, zTable in mc_core.pairsByKeys(yTable) do
                            if (lastZ == nil) then
                                lastZ = kz
                            end

                            if (isNeighbor(lastZ, kz, "z")) then
                                lastZ = kz
                            else

                                break
                            end

                            local coords = { x = kx, y = ky, z = kz }

                            if (zTable == true) then
                                if (groups[groupCounter] == nil) then
                                    groups[groupCounter] = {}
                                end

                                table.insert(groups[groupCounter], coords)
                                ptable.delete(pointGrid, coords)
                            end
                        end
                    end

                end
            end
        end

        return groups
    end

    local groups = buildGroups(pointGrid)

    -- To build our volumes, we just need to order the points in the group from smallest, to largest
    -- Our volume starting position is the smallest point in the group; Our ending position is the largest

    local volumes = {}

    for k, group in pairs(groups) do
        local smallestCoord = nil
        local largestCoord = nil

        for i, coord in pairs(group) do
            if (smallestCoord == nil) then
                smallestCoord = { x = coord.x, y = coord.y, z = coord.z }
            end

            if (largestCoord == nil) then
                largestCoord = { x = coord.x, y = coord.y, z = coord.z }
            end
            --

            if (smallestCoord.x > coord.x) then
                smallestCoord.x = coord.x
            end

            if (smallestCoord.y > coord.y) then
                smallestCoord.y = coord.y
            end

            if (smallestCoord.z > coord.z) then
                smallestCoord.z = coord.z
            end
            --

            if (largestCoord.x < coord.x) then
                largestCoord.x = coord.x
            end

            if (largestCoord.y < coord.y) then
                largestCoord.y = coord.y
            end

            if (largestCoord.z < coord.z) then
                largestCoord.z = coord.z
            end

        end

        local entry = {}
        entry.startPos = smallestCoord
        entry.area = { x = largestCoord.x - smallestCoord.x,
                       y = largestCoord.y - smallestCoord.y,
                       z = largestCoord.z - smallestCoord.z }

        table.insert(volumes, entry)
    end


    -- Replace our current emptyChunks array with our consolidated one;
    -- TODO: If remove the tail end empty chunks after they're combined, and decrease our grid end position
    -- This will shrink our active address space and use less memory

    Realm.EmptyChunks = volumes
end

---@public
---Deletes the realm based on class instance.
---NOTE: remember to clear any references to the realm so that memory can be released by the GC.
---@return void
function Realm:Delete()

    -- We need to first calculate where the realm is located on the realm grid.
    -- For some reason, this code sometimes does not work later on in the process...
    local gridStartPos = Realm.worldToGridSpace({
        x = self.StartPos.x,
        y = self.StartPos.y,
        z = self.StartPos.z })

    local gridEndPos = Realm.worldToGridSpace({
        x = self.EndPos.x,
        y = self.EndPos.y,
        z = self.EndPos.z })

    gridStartPos.x = gridStartPos.x - Realm.const.bufferSize
    gridStartPos.y = gridStartPos.y - Realm.const.bufferSize
    gridStartPos.z = gridStartPos.z - Realm.const.bufferSize

    if (self.ID == mc_worldManager.spawnRealmID) then
        mc_worldManager.spawnRealmID = nil
    end

    local players = self:GetPlayers()

    -- We call the functions registered with the realm's OnDelete event as well as global onDelete callbacks.

    self:RunFunctionFromTable(self.RealmDeleteTable)
    self:CallOnDeleteCallbacks()


    -- We need to remove all players from the realm
    local spawn = mc_worldManager.GetSpawnRealm()
    if (players ~= nil) then
        for k, v in pairs(players) do
            if v == true then
                spawn:TeleportPlayer(minetest.get_player_by_name(k))
            end
        end
    end

    -- We need to remove all entities from the realm
    self:ClearEntities()

    -- We clear all nodes from the realm.
    self:ClearNodes()

    -- We clear block protection
    if (areas) then
        local protectionID = self:get_data("protectionID")
        if (protectionID ~= nil) then
            areas:remove(protectionID, true)
            areas:save()
        end
    end

    -- We save the realms data to storage twice. The first time is to ensure that critical data such as the realm dict is saved to disk.
    -- The second time is to ensure that we have saved the updated realm grid.

    -- remove the realm dictionary entry.
    Realm.realmDict[self.ID] = nil
    Realm.SaveDataToStorage()

    -- We need to remove the realm from the realm grid and clear the space for other realms.
    Realm.markSpaceAsFree(gridStartPos, gridEndPos)
    Realm.SaveDataToStorage()
end

---@public
---Updates and saves the spawnpoint of a realm.
---@param spawnPos table SpawnPoint in localSpace.
---@return boolean Whether the operation succeeded.
function Realm:UpdateSpawn(spawnPos)
    local pos = self:LocalToWorldSpace(spawnPos)
    self.SpawnPoint = { x = pos.x, y = pos.y, z = pos.z }
    Realm.SaveDataToStorage()
    return true
end

function Realm:RunFunctionFromTable(table, player)
    if (table ~= nil) then
        for key, value in pairs(table) do
            if (value.tableName ~= nil and value.functionName ~= nil) then
                local table = loadstring("return " .. value.tableName)
                if (table ~= nil) then
                    local tableFunc = table()[value.functionName]
                    if (tableFunc ~= nil) then
                        tableFunc(self, player)
                    end
                end
            end
        end
    end
end

function Realm:ContainsCoordinate(coordinate)
    if (coordinate.x < self.StartPos.x or coordinate.x > self.EndPos.x) then
        return false
    end

    if (coordinate.z < self.StartPos.z or coordinate.z > self.EndPos.z) then
        return false
    end

    if (coordinate.y < self.StartPos.y or coordinate.y > self.EndPos.y) then
        return false
    end

    return true
end

Realm.LoadDataFromStorage()
Realm.consolidateEmptySpace()