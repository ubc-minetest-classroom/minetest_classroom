local function createRealmInfoHudString(player)
    local realm = Realm.GetRealmFromPlayer(player)
    local string = "Realm "
    if (realm ~= nil) then
        string = string .. realm.ID
        string = string .. " : " .. realm.Name
    end
    return string
end

function mc_worldManager.CreateRealmHud(player)
    mc_worldManager.hud:add(player, "worldManager:currentRealm", {
        hud_elem_type = "text",
        position = { x = 1, y = 0 },
        offset = { x = -16, y = 5 },
        alignment = { x = "left", y = "down" },
        text = createRealmInfoHudString(player),
        color = 0xFFFFFF,
    })
end

function mc_worldManager.UpdateRealmHud(player)
    if (not mc_worldManager.hud:exists(player, "worldManager:currentRealm")) then
        return false
    end
    mc_worldManager.hud:change(player, "worldManager:currentRealm", {
        hud_elem_type = "text",
        position = { x = 1, y = 0 },
        offset = { x = -16, y = 5 },
        alignment = { x = "left", y = "down" },
        text = createRealmInfoHudString(player),
        color = 0xFFFFFF,
    })

    return true
end

function mc_worldManager.RemoveRealmHud(player)
    mc_worldManager.hud:remove(player)
end

local positionText = {}

positionText["latlong"] = function(player, realm)
    local pos = realm:WorldToLatLong(player:get_pos())
    local text = "Lat: " .. pos.x .. " Long: " .. pos.z
    return text
end

positionText["UTM"] = function(player, realm)
    local pos = realm:WorldToUTM(player:get_pos())
    local text = "E: " .. math.ceil(pos.x) .. " N: " .. math.ceil(pos.z)
    return text
end

positionText["local"] = function(player, realm)
    local pos = realm:WorldToLocal(player:get_pos())
    local text = "X: " .. math.ceil(pos.x) .. " Y: " .. math.ceil(pos.y) .. " Z: " .. math.ceil(pos.z)
    return text
end

positionText["world"] = function(player, realm)
    local pos = player:get_pos()
    local text = "X: " .. math.ceil(pos.x) .. " Y: " .. math.ceil(pos.y) .. " Z: " .. math.ceil(pos.z)
    return text
end

positionText["grid"] = function(player, realm)
    local pos = realm:worldToGridSpace(player:get_pos())
    local text = "X: " .. pos.x .. " Y: " .. pos.y .. " Z: " .. pos.z
    return text
end

mc_worldManager.positionTextFunctions = positionText

-- Creating strings so often is very problematic and will create lots of garbage.
-- There is no way (to my limited knowledge) around this under current requirements.
-- I will try to fix this in the future.
-- See http://lua-users.org/wiki/OptimisingGarbageCollection for more info on string garbage.
function mc_worldManager.UpdatePositionHud(player, positionMode)
    if (not mc_worldManager.hud:exists(player, "worldManager:position")) then
        mc_worldManager.hud:add(player, "worldManager:position", {
            hud_elem_type = "text",
            position = { x = 1, y = 0 },
            offset = { x = -16, y = 25 },
            alignment = { x = "left", y = "down" },
            text = "",
            color = 0xFFFFFF,
        })
    end

    local realm = Realm.GetRealmFromPlayer(player)

    mc_worldManager.hud:change(player, "worldManager:position", {
        hud_elem_type = "text",
        position = { x = 1, y = 0 },
        offset = { x = -16, y = 25 },
        alignment = { x = "left", y = "down" },
        text = positionText[positionMode](player, realm),
        color = 0xFFFFFF,
    })

    return true
end

function mc_worldManager.RemovePositionHud(player)
    mc_worldManager.hud:remove(player, "worldManager:position")
end