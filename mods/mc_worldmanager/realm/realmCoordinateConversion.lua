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

function Realm:LocalToUTM(position)
    local utmInfo = self:get_data("utmInfo")

    if (utmInfo == nil) then
        utmInfo = {}
        utmInfo.easting = 0
        utmInfo.northing = 0
    end

    local x = position.x + utmInfo.easting
    local z = position.z + utmInfo.northing

    return {
        x = math.floor(x),
        y = math.floor(position.y),
        z = math.floor(z)
    }
end

function Realm:WorldToUTM(position)
    return self:LocalToUTM(self:WorldToLocalPosition(position))
end

function Realm:UTMToLocal(position)
    local utmInfo = self:get_data("utmInfo")

    if (utmInfo == nil) then
        utmInfo = {}
        utmInfo.easting = 0
        utmInfo.northing = 0
    end

    local x = position.x - utmInfo.easting
    local z = position.z - utmInfo.northing

    return {
        x = x,
        y = position.y,
        z = z
    }
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

function Realm.UTMToLatLong(utmX, utmY, utmZone, latitude, longitude)
    local isNorthernHemi = false -- TODO: get this from the utmZone
    local diflat = -00066286966871111111111111111111111111
    local diflon = -0.0003868060578

    local zone = tonumber(utmZone) -- TODO

    local c_sa = 6378137.000000;
    local c_sb = 6356752.314245;

    local e2 = ((c_sa ^ 2 - c_sb ^ 2) ^ 0.5) / c_sb;
    local e2cuadrada = e2 ^ 2;
    local c = c_sa ^ 2 / c_sb;
    local x = utmX - 500000;

    local y
    if (isNorthernHemi) then
        y = utmY;
    else
        y = utmY - 10000000;
    end

    local s = (zone * 6) - 183
    local lat = y / (c_sa * 0.9996);
    local v = (c / (1 + (e2cuadrada * (cos(lat) ^ 2)) ^ 0.5)) * 0.9996;
    local a = x / v
    local a1 = math.sin(2 * lat)
    local a2 = a1 * (Math.cos(lat)^2)
    local j2 = lat + (a1 / 2)
    local j4 = ((3 * j2) + a2) / 4
    local j6 = ((5 * j4) + (a2 * (Math.cos(lat)^2))) / 3
    local alfa = (3 / 4) * e2cuadrada;
    local beta = (5 / 3) * (alfa ^ 2);
    local gama = (35 / 27) * (alfa ^ 3);
    local bm = 0.9996 * c * (lat - alfa * j2 + beta * j4 - gama * j6)
    local b = (y - bm) / v
    local epsi = ((e2cuadrada * (a^2)) / 2) * (math.cos(lat) ^ 2)
    local eps = a * (1 - (epsi / 3))
    local nab = (b * (1 - epsi)) + lat
    local senoheps = (math.exp(eps) - math.exp(-eps)) / 2
    local delt = math.atan(senoheps / (math.cos(nab)))
    local tao = math.atan(math.cos(delt) * math.tan(nab))

    local longitude = ((delt * (180 / math.pi)) + s) + diflon
    local latitude = (lat + (1 + e2cuadrada * (math.cos(lat)^2) - (3.0/2.0)*e2cuadrada*math.sin(lat)*math.cos(lat)*(tao-lat)) * (tao - lat)) * (180/math.pi) + diflat

end




