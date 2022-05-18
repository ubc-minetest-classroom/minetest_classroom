-- Realms are up-to 12 mapchunk areas seperated by a 1 mapchunk border of void (in each dimension);
-- TODO: add helper functions to do stuff like teleport players into the maps
-- TODO: assign realm ID based on first available ID rather than realm count

local realmSize = 80 * 6 -- 12 mapchunks
local realmBuffer = 80 * 4
local realmHeight = 80 * 4

---@public
---Class that manages all realms in Minetest_Classroom.
---@class
Realm = { realmDict = {} }
Realm.__index = Realm

---We load our global realm data from storage
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

---We save our global realm data to storage
function Realm.SaveDataToStorage ()
    mc_worldManager.storage:set_string("realmDict", minetest.serialize(Realm.realmDict))
    mc_worldManager.storage:set_string("realmCount", tostring(Realm.realmCount))
end

---@public
---creates a new Dimension.
---@return self
function Realm:New(name, size, height)
    size = size or realmSize
    height = height or realmHeight

    if (name == nil) then
        name = "Unnamed Realm"
    end

    local this = {
        Name = name,
        ID = Realm.realmCount + 1,
        StartPos = { x = 0, y = 0, z = 0 },
        EndPos = { x = 0, y = 0, z = 0 },
        SpawnPoint = { x = 0, y = 0, z = 0 }
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

    this.EndPos = { x = this.StartPos.x + finalRealmSize, y = this.StartPos.y + finalRealmHeight, z = this.StartPos.z + finalRealmSize }

    -- Temporary spawn point calculation
    this.SpawnPoint = { x = (this.StartPos.x + this.EndPos.x) / 2, y = ((this.StartPos.y + this.EndPos.y) / 2) + 2, z = (this.StartPos.z + this.EndPos.z) / 2 }

    setmetatable(this, self)
    table.insert(Realm.realmDict, this.ID, this)
    Realm.SaveDataToStorage()

    return this
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
        SpawnPoint = { x = template.SpawnPoint.x, y = template.SpawnPoint.y, z = template.SpawnPoint.z }
    }

    setmetatable(this, self)
    table.insert(Realm.realmDict, this.ID, this)
    return this
end

---@public
---Deletes the realm based on class instance.
---Make sure you clear any references to the realm so that memory can be released by the GC.
---@return void
function Realm:Delete()
    self:ClearNodes()
    table.remove(Realm.realmDict, self.ID)
    Realm.SaveDataToStorage()
end

---@public
---Sets all nodes in a realm to air.
---@return void
function Realm:ClearNodes()
    local function emerge_callback(blockpos, action,
                                   num_calls_remaining, context)
        -- On first call, record number of blocks
        if not context.total_blocks then
            context.total_blocks = num_calls_remaining + 1
            context.loaded_blocks = 0
        end

        -- Increment number of blocks loaded
        context.loaded_blocks = context.loaded_blocks + 1

        -- Send progress message
        -- Send progress message
        if context.total_blocks == context.loaded_blocks then
            minetest.chat_send_all("Finished deleting realm!")
        else
            local perc = 100 * context.loaded_blocks / context.total_blocks
            local msg = string.format("deleting realm %d %d/%d (%.2f%%) done!",
                    context.realm.ID, context.loaded_blocks, context.total_blocks, perc)
            minetest.chat_send_all(msg)
        end

        local pos1 = { x = blockpos.x * 16, y = blockpos.y * 16, z = blockpos.z * 16 }
        local pos2 = { x = blockpos.x * 16 + 15, y = blockpos.y * 16 + 15, z = blockpos.z * 16 + 15 }

        context.realm:SetNodes(pos1, pos2, "air")
    end

    local context = {} -- persist data between callback calls
    context.realm = self
    minetest.emerge_area(self.StartPos, self.EndPos, emerge_callback, context)
end

---@public
---Creates a ground plane between the realms start and end positions.
---@return void
function Realm:CreateGround(nodeType)
    nodeType = nodeType or "mc_worldmanager:temp"
    local pos1 = { x = self.StartPos.x, y = (self.StartPos.y + self.EndPos.y) / 2, z = self.StartPos.z }
    local pos2 = { x = self.EndPos.x, y = (self.StartPos.y + self.EndPos.y) / 2, z = self.EndPos.z }

    self:SetNodes(pos1, pos2, nodeType)
end

function Realm:CreateBarriers()
    local pos1 = { x = self.StartPos.x, y = self.StartPos.y, z = self.StartPos.z }
    local pos2 = { x = self.StartPos.x, y = self.EndPos.y, z = self.EndPos.z }
    self:SetNodes(pos1, pos2, "unbreakable_map_barrier:barrier")

    local pos1 = { x = self.EndPos.x, y = self.StartPos.y, z = self.StartPos.z }
    local pos2 = { x = self.EndPos.x, y = self.EndPos.y, z = self.EndPos.z }
    self:SetNodes(pos1, pos2, "unbreakable_map_barrier:barrier")

    local pos1 = { x = self.StartPos.x, y = self.StartPos.y, z = self.StartPos.z }
    local pos2 = { x = self.EndPos.x, y = self.StartPos.y, z = self.EndPos.z }
    self:SetNodes(pos1, pos2, "unbreakable_map_barrier:barrier")

    local pos1 = { x = self.StartPos.x, y = self.EndPos.y, z = self.StartPos.z }
    local pos2 = { x = self.EndPos.x, y = self.EndPos.y, z = self.EndPos.z }
    self:SetNodes(pos1, pos2, "unbreakable_map_barrier:barrier")

    local pos1 = { x = self.StartPos.x, y = self.StartPos.y, z = self.StartPos.z }
    local pos2 = { x = self.EndPos.x, y = self.EndPos.y, z = self.StartPos.z }
    self:SetNodes(pos1, pos2, "unbreakable_map_barrier:barrier")

    local pos1 = { x = self.StartPos.x, y = self.StartPos.y, z = self.EndPos.z }
    local pos2 = { x = self.EndPos.x, y = self.EndPos.y, z = self.EndPos.z }
    self:SetNodes(pos1, pos2, "unbreakable_map_barrier:barrier")
end

---Helper function to set cubic areas of nodes based on world coordinates and node type
---@param pos1 table
---@param pos2 table
---@param pos2 string
function Realm:SetNodes(pos1, pos2, node)
    local node_id = minetest.get_content_id(node)

    -- Read data into LVM
    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(pos1, pos2)
    local a = VoxelArea:new {
        MinEdge = emin,
        MaxEdge = emax
    }
    local data = vm:get_data()

    -- Modify data
    for z = pos1.z, pos2.z do
        for y = pos1.y, pos2.y do
            for x = pos1.x, pos2.x do
                local vi = a:index(x, y, z)
                data[vi] = node_id
            end
        end
    end

    -- Write data to world
    vm:set_data(data)
    vm:write_to_map(true)
end

function Realm:Save_Schematic()
    local folderpath = minetest.get_worldpath() .. "\\schematics\\"

    minetest.mkdir(folderpath)

    local fileName = "Realm " .. self.ID .. " "
    for i = 1, 4 do
        fileName = fileName .. math.random(0, 9)
    end

    fileName = fileName .. os.date(" %Y%m%d %H%M")

    local filepath = folderpath .. "\\" .. fileName

    minetest.create_schematic(self.StartPos, self.EndPos, nil, filepath .. ".schematic", nil)

    local settings = Settings(filepath .. ".conf")
    settings:set("author", "unknown")
    settings:set("name", "unknown")
    settings:set("spawn_pos_x", self.SpawnPoint.x)
    settings:set("spawn_pos_y", self.SpawnPoint.y)
    settings:set("spawn_pos_z", self.SpawnPoint.z)

    settings:set("schematic_size_x", self.EndPos.x - self.StartPos.x)
    settings:set("schematic_size_y", self.EndPos.y - self.StartPos.y)
    settings:set("schematic_size_z", self.EndPos.z - self.StartPos.z)

    local settingsWrote = settings:write()

    return filepath, settingsWrote
end

function Realm:Load_Schematic(key)
    local schematic, config = schematicManager.getSchematic(key)

    self.EndPos.x = self.StartPos.x + config.size.x
    self.EndPos.y = self.StartPos.y + config.size.y
    self.EndPos.z = self.StartPos.z + config.size.z


    -- Read data into LVM
    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(self.StartPos, self.EndPos)
    local a = VoxelArea:new {
        MinEdge = emin,
        MaxEdge = emax
    }

    -- Place Schematic
    -- local results = minetest.place_schematic(self.StartPos, schematic, 0, nil, true)

    local results = minetest.place_schematic_on_vmanip(vm, self.StartPos, schematic, 0, nil, true)
    vm:write_to_map(true)

    self:UpdateSpawn(config.spawnPoint)
    return results
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

---LocalToWorldPosition
---@param position table
---@return table
function Realm:LocalToWorldPosition(position)
    local pos = position
    pos.x = pos.x + self.StartPos.x
    pos.y = pos.y + self.StartPos.y
    pos.z = pos.z + self.StartPos.z
    return pos
end

---WorldToLocalPosition
---@param position table
---@return table
function Realm:WorldToLocalPosition(position)
    local pos = position
    pos.x = pos.x - self.StartPos.x
    pos.y = pos.y - self.StartPos.y
    pos.z = pos.z - self.StartPos.z
    return pos
end

function Realm:CalculateSpawn()
    local posX = self.SpawnPoint.x
    local posZ = self.SpawnPoint.z
    local posY = minetest.get_spawn_level(x, z)

    if (posY == nil) then
        return nil
    else
        local pos = { x = posX, y = posY, z = posZ }
        self.SpawnPoint = pos
        return pos
    end
end

Realm.LoadDataFromStorage()