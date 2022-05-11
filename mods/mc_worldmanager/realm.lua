-- Realms are 1,000 node * 1,000 node areas seperated by a 500 block border of void (in each dimension);
-- TODO: make realm size dynamic
-- TODO: save realm info to storage
-- TODO: add helper functions to do stuff like teleport players into the maps
-- TODO: add invisible world border around realms


---@public
---Class that manages all realms in Minetest_Classroom.
---@class
Realm = { realmCount = 0, realmDict = {} }
Realm.__index = Realm

---@public
---creates a new Dimension.
---@return self
function Realm:new()

    local this = {
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
    this.StartPos.x = -20000 + (1000 * realmLocation.x) + 250
    this.StartPos.z = -20000 + (1000 * realmLocation.z) + 250

    this.EndPos = this.StartPos
    this.EndPos.x = this.EndPos.x + 1000
    this.EndPos.z = this.EndPos.z + 1000

    -- Temporary spawn point calculation
    this.SpawnPoint = this.StartPos
    this.SpawnPoint.y = this.StartPos.y + 2

    Realm.realmDict[this.ID] = this

    return setmetatable(this, self)
end

---@public
---Deletes the realm based on class instance.
---@return void
function Realm:Delete()
    Realm.DeleteByID(self.ID)
end

---@public
---Deletes the realm based on the supplied realm ID.
---@param ID number
---@return void
function Realm.DeleteByID(ID)
    --TODO: Clear world blocks in the realm before removing reference in the realmDICT
    Realm.realmDict[ID] = nil
end

function Realm:ground()
    local temp_node = minetest.get_content_id("mc_worldmanager:temp")
    local pos1 = self.StartPos
    local pos2 = self.EndPos

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
                local pos = { x = x, y = y, z = z }
                data[vi] = temp_node
            end
        end
    end

    -- Write data
    vm:set_data(data)
    vm:write_to_map(true)
end

function Realm:test()
    minetest.debug(self.ID)
end




