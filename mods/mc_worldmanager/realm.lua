-- Realms are 1,000 node * 1,000 node areas seperated by a 500 block border of void (in each dimension);
-- TODO: make realm size dynamic
-- TODO: save realm info to storage
-- TODO: add helper functions to do stuff like teleport players into the maps
-- TODO: add invisible world border around realms
-- TODO: assign realm ID based on first available ID rather than realm count

local realmSize = 1024
local realmBuffer = 50

---@public
---Class that manages all realms in Minetest_Classroom.
---@class
Realm = { storage = minetest.get_mod_storage(), realmDict = {} }
Realm.__index = Realm

---We load our global realm data from storage
function Realm.LoadFromStorage()
    Realm.realmCount = tonumber(Realm.storage:get_string("realmCount"))
    if Realm.realmCount == nil then
        Realm.realmCount = 0
    end

    local tmpRealmDict = minetest.deserialize(Realm.storage:get_string("realmDict"))
    if tmpRealmDict == nil then
        tmpRealmDict = {}
    end

    for key, realm in pairs(tmpRealmDict) do
        Realm:Restore(realm)
    end


end

---We save our global realm data to storage
function Realm.UpdateStorage ()

    minetest.debug(minetest.serialize(Realm.realmDict))

    Realm.storage:set_string("realmDict", minetest.serialize(Realm.realmDict))
    Realm.storage:set_string("realmCount", tostring(Realm.realmCount))
end

---@public
---creates a new Dimension.
---@return self
function Realm:New(name)

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

    this.EndPos = { x = this.StartPos.x + realmSize, y = this.StartPos.y, z = this.StartPos.z + realmSize }

    -- Temporary spawn point calculation
    this.SpawnPoint = { x = (this.StartPos.x + this.EndPos.x) / 2, y = this.StartPos.y + 2, z = (this.StartPos.z + this.EndPos.z) / 2 }

    setmetatable(this, self)
    Realm.realmDict[this.ID] = this
    Realm.UpdateStorage()

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
    self.realmDict[this.ID] = this
    return this
end

---@public
---Deletes the realm based on class instance.
---Make sure you clear any references to the realm so that memory can be released by the GC.
---@return void
function Realm:Delete()
    Realm.DeleteByID(self.ID)
end

---@public
---Deletes the realm based on the supplied realm ID.
---@param ID number
---@return void
function Realm.DeleteByID(ID)
    Realm.realmDict[ID]:ClearNodes()
    Realm.realmDict[ID] = nil
    Realm.UpdateStorage()
end

---@public
---Sets all nodes in a realm to air.
---@return void
function Realm:ClearNodes()
    local pos1 = self.StartPos
    local pos2 = self.EndPos
    self:SetNodes(pos1, pos2, "air")
end

---@public
---Creates a ground plane between the realms start and end positions.
---@return void
function Realm:CreateGround()
    self:SetNodes(self.StartPos, self.EndPos, "mc_worldmanager:temp")
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

Realm.LoadFromStorage()