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
    local utmInfo = self:get_data("UTMInfo")

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
        utmInfo = { zone = 0, utm_is_north = true, easting = 0, northing = 0 }
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

function Realm:WorldToLatLong(position)
    local utmInfo = self:get_data("UTMInfo")
    if (utmInfo == nil) then
        utmInfo = { zone = 0, utm_is_north = true, easting = 0, northing = 0 }
    end

    local position = self:WorldToUTM(position)

    local latlongPosition = Realm.UTMToLatLong(position.x, position.z, utmInfo.zone, utmInfo.utm_is_north)

    return { x = latlongPosition.latitude, y = position.y, z = latlongPosition.longitude }
end



-- The following method is adapted from the following StackOverflow post: https://stackoverflow.com/questions/2689836/converting-utm-wsg84-coordinates-to-latitude-and-longitude
-- Method originally by: Playful https://stackoverflow.com/users/2255765/playful


function Realm.UTMToLatLong(utmX, utmY, zone, isNorthHemisphere)

    -- Caching our Math variables for better performance
    local Math = { }
    Math.PI = math.pi
    Math.Pow = math.pow
    Math.Exp = math.exp
    Math.Sin = math.sin
    Math.Cos = math.cos
    Math.Tan = math.tan
    Math.Asin = math.asin
    Math.Atan = math.atan
    Math.Cosh = math.cosh
    Math.Sinh = math.sinh
    Math.Tanh = math.tanh


    local diflat = -0.00066286966871111111111111111111111111
    local diflon = -0.0003868060578
    local c_sa = 6378137.000000
    local c_sb = 6356752.314245

    local e2 = Math.Pow((Math.Pow(c_sa, 2) - Math.Pow(c_sb, 2)), 0.5) / c_sb
    local e2cuadrada = Math.Pow(e2, 2)
    local c = Math.Pow(c_sa, 2) / c_sb
    local x = utmX - 500000
    local y = utmY
    if (isNorthHemisphere) then
        y = utmY
    else
        y = utmY - 10000000
    end

    local s = ((zone * 6.0) - 183.0)
    local lat = y / (c_sa * 0.9996)
    local v = (c / Math.Pow(1 + (e2cuadrada * Math.Pow(Math.Cos(lat), 2)), 0.5)) * 0.9996

    local a = x / v
    local a1 = Math.Sin(2 * lat)
    local a2 = a1 * Math.Pow((Math.Cos(lat)), 2)

    local j2 = lat + (a1 / 2.0)
    local j4 = ((3 * j2) + a2) / 4.0
    local j6 = ((5 * j4) + Math.Pow(a2 * (Math.Cos(lat)), 2)) / 3.0

    local alfa = (3.0 / 4.0) * e2cuadrada
    local beta = (5.0 / 3.0) * Math.Pow(alfa, 2)
    local gama = (35.0 / 27.0) * Math.Pow(alfa, 3)

    local bm = 0.9996 * c * (lat - alfa * j2 + beta * j4 - gama * j6)
    local b = (y - bm) / v
    local epsi = ((e2cuadrada * Math.Pow(a, 2)) / 2.0) * Math.Pow((Math.Cos(lat)), 2)
    local eps = a * (1 - (epsi / 3.0))
    local nab = (b * (1 - epsi)) + lat
    local senoheps = (Math.Exp(eps) - Math.Exp(-eps)) / 2.0
    local delt = Math.Atan(senoheps / (Math.Cos(nab)))
    local tao = Math.Atan(Math.Cos(delt) * Math.Tan(nab))

    local longitude = mc_helpers.round(((delt * (180.0 / Math.PI)) + s) + diflon,5)
    local latitude = mc_helpers.round(((lat + (1 + e2cuadrada * Math.Pow(Math.Cos(lat), 2) - (3.0 / 2.0) * e2cuadrada * Math.Sin(lat) * Math.Cos(lat) * (tao - lat)) * (tao - lat)) * (180.0 / Math.PI)) + diflat,5)

    return {
        longitude = longitude,
        latitude = latitude
    }
end




