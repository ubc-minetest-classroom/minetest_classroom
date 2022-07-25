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

    local latlongPosition = Realm.UTMToLatLong(position.x, position.z, utmInfo.zone, utmInfo.northernHemisphere)

    return { x = latlongPosition.latitude, y = position.y, z = latlongPosition.longitude }
end



-- The following two methods are taken from the following StackOverflow post: https://stackoverflow.com/questions/2689836/converting-utm-wsg84-coordinates-to-latitude-and-longitude
-- First method by: Playful https://stackoverflow.com/users/2255765/playful
-- Second method by: Mohammed Sadeq https://stackoverflow.com/users/7780768/mohammed-sadeq-ale-isaac


--[[

function Realm.UTMToLatLong(utmX, utmY, utmZone, utmHemisphere)
    local diflat = -0.00066286966871111111111111111111111111;
    local diflon = -0.0003868060578;

    local zone = tonumber(utmZone)

    local c_sa = 6378137.000000;
    local c_sb = 6356752.314245;

    local e2 = ((c_sa ^ 2 - c_sb ^ 2) ^ 0.5) / c_sb;
    local e2cuadrada = e2 ^ 2;
    local c = c_sa ^ 2 / c_sb;
    local x = utmX - 500000;

    local y
    if (utmHemisphere) then
        y = utmY;
    else
        y = utmY - 10000000;
    end

    local s = (zone * 6) - 183
    local lat = y / (c_sa * 0.9996);
    local v = (c / (1 + (e2cuadrada * (math.cos(lat) ^ 2)) ^ 0.5)) * 0.9996;
    local a = x / v
    local a1 = math.sin(2 * lat)
    local a2 = a1 * (math.cos(lat) ^ 2)
    local j2 = lat + (a1 / 2)
    local j4 = ((3 * j2) + a2) / 4
    local j6 = ((5 * j4) + (a2 * (math.cos(lat) ^ 2))) / 3
    local alfa = (3 / 4) * e2cuadrada;
    local beta = (5 / 3) * (alfa ^ 2);
    local gama = (35 / 27) * (alfa ^ 3);
    local bm = 0.9996 * c * (lat - alfa * j2 + beta * j4 - gama * j6)
    local b = (y - bm) / v
    local epsi = ((e2cuadrada * (a ^ 2)) / 2) * (math.cos(lat) ^ 2)
    local eps = a * (1 - (epsi / 3))
    local nab = (b * (1 - epsi)) + lat
    local senoheps = (math.exp(eps) - math.exp(-eps)) / 2
    local delt = math.atan(senoheps / (math.cos(nab)))

    local tao = math.atan(math.cos(delt) * math.tan(nab))

    local longitude = ((delt * (180 / math.pi)) + s) + diflon
    local latitude = ((lat + (1 + e2cuadrada * math.pow(math.cos(lat), 2) - (3.0 / 2.0) * e2cuadrada * math.sin(lat) * math.cos(lat) * (tao - lat)) * (tao - lat)) * (180.0 / math.pi)) + diflat;

    return {
        longitude = longitude,
        latitude = latitude
    }
end
]]--

function Realm.UTMToLatLong(Easting, Northing, Zone, Hemisphere)
    local DtoR = math.pi / 180
    local RtoD = 180 / math.pi;

    local a = 6378137
    local f = 0.00335281066474748071984552861852
    local northernN0 = 0
    local southernN0 = 10000000
    local E0 = 500000

    -- Caching our Math variables for better performance
    local Math = { }
    Math.Pow = math.pow
    Math.Sin = math.sin
    Math.Cos = math.cos
    Math.Asin = math.asin
    Math.Atan = math.atan
    Math.Cosh = math.cosh
    Math.Sinh = math.sinh

    local n = f / (2 - f)
    local k0 = 0.9996
    local A = a * (1 + (1 / 4) * Math.Pow(n, 2) + (1 / 64) * Math.Pow(n, 4) + (1 / 256) * Math.Pow(n, 6) + (25 / 16384) * Math.Pow(n, 8) + (49 / 65536) * Math.Pow(n, 10)) / (1 + n)

    local beta1 = n / 2 - (2 / 3) * Math.Pow(n, 2) + (37 / 96) * Math.Pow(n, 3) - (1 / 360) * Math.Pow(n, 4) - (81 / 512) * Math.Pow(n, 5) + (96199 / 604800) * Math.Pow(n, 6) - (5406467 / 38707200) * Math.Pow(n, 7) + (7944359 / 67737600) * Math.Pow(n, 8) - (7378753979 / 97542144000) * Math.Pow(n, 9) + (25123531261 / 804722688000) * Math.Pow(n, 10)
    local beta2 = (1 / 48) * Math.Pow(n, 2) + (1 / 15) * Math.Pow(n, 3) - (437 / 1440) * Math.Pow(n, 4) + (46 / 105) * Math.Pow(n, 5) - (1118711 / 3870720) * Math.Pow(n, 6) + (51841 / 1209600) * Math.Pow(n, 7) + (24749483 / 348364800) * Math.Pow(n, 8) - (115295683 / 1397088000) * Math.Pow(n, 9) + (5487737251099 / 51502252032000) * Math.Pow(n, 10)
    local beta3 = (17 / 480) * Math.Pow(n, 3) - (37 / 840) * Math.Pow(n, 4) - (209 / 4480) * Math.Pow(n, 5) + (5569 / 90720) * Math.Pow(n, 6) + (9261899 / 58060800) * Math.Pow(n, 7) - (6457463 / 17740800) * Math.Pow(n, 8) + (2473691167 / 9289728000) * Math.Pow(n, 9) - (852549456029 / 20922789888000) * Math.Pow(n, 10)
    local beta4 = (4397 / 161280) * Math.Pow(n, 4) - (11 / 504) * Math.Pow(n, 5) - (830251 / 7257600) * Math.Pow(n, 6) + (466511 / 2494800) * Math.Pow(n, 7) + (324154477 / 7664025600) * Math.Pow(n, 8) - (937932223 / 3891888000) * Math.Pow(n, 9) - (89112264211 / 5230697472000) * Math.Pow(n, 10)
    local beta5 = (4583 / 161280) * Math.Pow(n, 5) - (108847 / 3991680) * Math.Pow(n, 6) - (8005831 / 63866880) * Math.Pow(n, 7) + (22894433 / 124540416) * Math.Pow(n, 8) + (112731569449 / 557941063680) * Math.Pow(n, 9) - (5391039814733 / 10461394944000) * Math.Pow(n, 10)
    local beta6 = (20648693 / 638668800) * Math.Pow(n, 6) - (16363163 / 518918400) * Math.Pow(n, 7) - (2204645983 / 12915302400) * Math.Pow(n, 8) + (4543317553 / 18162144000) * Math.Pow(n, 9) + (54894890298749 / 167382319104000) * Math.Pow(n, 10)
    local beta7 = (219941297 / 5535129600) * Math.Pow(n, 7) - (497323811 / 12454041600) * Math.Pow(n, 8) - (79431132943 / 332107776000) * Math.Pow(n, 9) + (4346429528407 / 12703122432000) * Math.Pow(n, 10)
    local beta8 = (191773887257 / 3719607091200) * Math.Pow(n, 8) - (17822319343 / 336825216000) * Math.Pow(n, 9) - (497155444501631 / 1422749712384000) * Math.Pow(n, 10)
    local beta9 = (11025641854267 / 158083301376000) * Math.Pow(n, 9) - (492293158444691 / 6758061133824000) * Math.Pow(n, 10)
    local beta10 = (7028504530429621 / 72085985427456000) * Math.Pow(n, 10)

    local delta1 = 2 * n - (2 / 3) * Math.Pow(n, 2) - 2 * Math.Pow(n, 3)
    local delta2 = (7 / 3) * Math.Pow(n, 2) - (8 / 5) * Math.Pow(n, 3)
    local delta3 = (56 / 15) * Math.Pow(n, 3)

    local ksi = (Northing / 100 - northernN0) / (k0 * A)
    local eta = (Easting / 100 - E0) / (k0 * A)

    local ksi_prime = ksi - (beta1 * Math.Sin(2 * ksi) * Math.Cosh(2 * eta) + beta2 * Math.Sin(4 * ksi) * Math.Cosh(4 * eta) +
            beta3 * Math.Sin(6 * ksi) * Math.Cosh(6 * eta) + beta4 * Math.Sin(8 * ksi) * Math.Cosh(8 * eta) +
            beta5 * Math.Sin(10 * ksi) * Math.Cosh(10 * eta) + beta6 * Math.Sin(12 * ksi) * Math.Cosh(12 * eta) +
            beta7 * Math.Sin(14 * ksi) * Math.Cosh(14 * eta) + beta8 * Math.Sin(16 * ksi) * Math.Cosh(16 * eta) +
            beta9 * Math.Sin(18 * ksi) * Math.Cosh(18 * eta) + beta10 * Math.Sin(20 * ksi) * Math.Cosh(20 * eta))

    local eta_prime = eta - (beta1 * Math.Cos(2 * ksi) * Math.Sinh(2 * eta) + beta2 * Math.Cos(4 * ksi) * Math.Sinh(4 * eta) + beta3 * Math.Cos(6 * ksi) * Math.Sinh(6 * eta))
    local sigma_prime = 1 - (2 * beta1 * Math.Cos(2 * ksi) * Math.Cosh(2 * eta) + 2 * beta2 * Math.Cos(4 * ksi) * Math.Cosh(4 * eta) + 2 * beta3 * Math.Cos(6 * ksi) * Math.Cosh(6 * eta))
    local taw_prime = 2 * beta1 * Math.Sin(2 * ksi) * Math.Sinh(2 * eta) + 2 * beta2 * Math.Sin(4 * ksi) * Math.Sinh(4 * eta) + 2 * beta3 * Math.Sin(6 * ksi) * Math.Sinh(6 * eta)

    local ki = Math.Asin(Math.Sin(ksi_prime) / Math.Cosh(eta_prime))

    local latitude = (ki + delta1 * Math.Sin(2 * ki) + delta2 * Math.Sin(4 * ki) + delta3 * Math.Sin(6 * ki)) * RtoD

    local longitude0 = Zone * 6 * DtoR - 183 * DtoR
    local longitude = (longitude0 + Math.Atan(Math.Sinh(eta_prime) / Math.Cos(ksi_prime))) * RtoD

    return latitude, longitude

end






