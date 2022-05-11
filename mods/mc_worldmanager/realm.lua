-- Realms are 3,000 node * 3,000 node areas seperated by a 1,000 block border of void (in each dimension);
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
        Position = { x = 0, y = 0, z = 0 },
        SpawnPoint = { x = 0, y = 0, z = 0 }
    }

    Realm.realmCount = this.ID

    -- Calculate where on the realm grid we are located; based on our realm ID
    local realmLocation = { x = 0, z = 0 }
    realmLocation.x = this.ID % 10
    realmLocation.z = Math.ceil(this.ID / 10)

    -- Calculate our world position based on our location on the realm grid
    this.Position.x = -20000 + (3000 * realmLocation.x) + 1000
    this.Position.z = -20000 + (3000 * realmLocation.z) + 1000

    -- Temporary spawn point calculation
    this.SpawnPoint = this.Position
    this.SpawnPoint.y = this.Position.y + 2

    Realm.realmDict[this.ID] = this

    setmetatable(this, self)
    return this
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

