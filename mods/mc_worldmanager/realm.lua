-- Realms are 3,000 node * 3,000 node areas seperated by a 1,000 block border of void (in each dimension);
-- TODO: make realm size dynamic

local realmSettings = { size = 3000, buffer = 1000, worldSize = 20000 }

Realm = { realmCount = 0 }
Realm.__index = Realm

---@public
---creates a new Dimension
---@return self
function Realm:Create()

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
    this.Position.x = -realmSettings.worldSize + (realmSettings.size * realmLocation.x) + realmSettings.buffer
    this.Position.z = -realmSettings.worldSize + (realmSettings.size * realmLocation.z) + realmSettings.buffer

    -- Temporary spawn point calculation
    this.SpawnPoint = this.Position
    this.SpawnPoint.y = this.Position.y + 2

    setmetatable(this, Realm)
    return this
end

---@public
---@return void
function Realm:Delete()

end

