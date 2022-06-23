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
---@param position table coordinates in worldspace
---@return table worldspace coordinates
function Realm:WorldToLocalPosition(position)
    local pos = position
    pos.x = pos.x - self.StartPos.x
    pos.y = pos.y - self.StartPos.y
    pos.z = pos.z - self.StartPos.z
    return pos
end

---gridToWorldSpace
---@param coords table coordinates in gridspace
---@return table coordinates in worldspace
function Realm.gridToWorldSpace(coords)
    local val = { x = 0, y = 0, z = 0 }
    val.x = (tonumber(coords.x) * 80) - Realm.const.worldSize
    val.y = (tonumber(coords.y) * 80) - Realm.const.worldSize
    val.z = (tonumber(coords.z) * 80) - Realm.const.worldSize
    return val
end

---worldToGridSpace
---@param coords table coordinates in worldspace
---@return table coordinates in gridspace.
function Realm.worldToGridSpace(coords)
    Debug.logCoords(coords, "worldToGridSpaceStart")

    local val = { x = 0, y = 0, z = 0 }
    val.x = math.ceil((tonumber(coords.x) + Realm.const.worldSize) / 80)
    val.y = math.ceil((tonumber(coords.y) + Realm.const.worldSize) / 80)
    val.z = math.ceil((tonumber(coords.z) + Realm.const.worldSize) / 80)

    Debug.logCoords(val, "worldToGridSpaceEnd")

    return val
end