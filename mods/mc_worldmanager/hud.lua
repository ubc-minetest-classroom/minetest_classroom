local function createRealmInfoHudString(player)
    local realm = Realm.GetRealmFromPlayer(player)
    local string = "Realm "
    if (realm ~= nil) then
        string = string .. realm.ID
        string = string .. " : " .. realm.Name
    end
    return string
end

function mc_worldManager.UpdateRealmHud(player)
    if (not mc_worldManager.hud:exists(player, "worldManager:currentRealm")) then
        mc_worldManager.hud:add(player, "worldManager:currentRealm", {
            hud_elem_type = "text",
            position = { x = 0, y = 1 },
            offset = { x = 5, y = -5 },
            alignment = { x = "right", y = "up" },
            text = createRealmInfoHudString(player),
            color = 0xFFFFFF,
        })
    end

    mc_worldManager.hud:change(player, "worldManager:currentRealm", {
        hud_elem_type = "text",
        position = { x = 0, y = 1 },
        offset = { x = 5, y = -5 },
        alignment = { x = "right", y = "up" },
        text = createRealmInfoHudString(player),
        color = 0xFFFFFF,
    })

    return true
end

function mc_worldManager.RemoveHud(player)
    mc_worldManager.hud:remove(player)
    mc_worldManager.UpdateRealmHud(player)
end

local positionText = {}

positionText["latlong"] = function(player, realm)
    local pos = realm:WorldToLatLongSpace(player:get_pos())
    local text = "Lat: " .. pos.x .. " Long: " .. pos.z
    return text
end

positionText["UTM"] = function(player, realm)
    local pos = realm:WorldToUTMSpace(player:get_pos())
    local text = "E: " .. math.ceil(pos.x) .. " N: " .. math.ceil(pos.z)
    return text
end

positionText["local"] = function(player, realm)
    local pos = realm:WorldToLocalSpace(player:get_pos())
    local text = "X: " .. math.ceil(pos.x) .. " Y: " .. math.ceil(pos.y) .. " Z: " .. math.ceil(pos.z)
    return text
end

positionText["world"] = function(player, realm)
    local pos = player:get_pos()
    local text = "X: " .. math.ceil(pos.x) .. " Y: " .. math.ceil(pos.y) .. " Z: " .. math.ceil(pos.z)
    return text
end

positionText["grid"] = function(player, realm)
    local pos = realm.worldToGridSpace(player:get_pos())
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
            position = { x = 0, y = 1 },
            offset = { x = 5, y = -25 },
            alignment = { x = "right", y = "up" },
            text = "",
            color = 0xFFFFFF,
        })
    end

    if (not mc_worldManager.hud:exists(player, "worldManager:elevation")) then
        mc_worldManager.hud:add(player, "worldManager:elevation", {
            hud_elem_type = "text",
            position = { x = 0, y = 1 },
            offset = { x = 5, y = -45 },
            alignment = { x = "right", y = "up" },
            text = "",
            color = 0xFFFFFF,
        })
    end

    local realm = Realm.GetRealmFromPlayer(player)
    local seaLevel = realm:get_data("seaLevel")

    mc_worldManager.hud:change(player, "worldManager:position", {
        hud_elem_type = "text",
        position = { x = 0, y = 1 },
        offset = { x = 5, y = -25 },
        alignment = { x = "right", y = "up" },
        text = positionText[positionMode](player, realm),
        color = 0xFFFFFF,
    })

    if (seaLevel == nil) then
        seaLevel = realm.StartPos.y
    end

    mc_worldManager.hud:change(player, "worldManager:elevation", {
        hud_elem_type = "text",
        position = { x = 0, y = 1 },
        offset = { x = 5, y = -45 },
        alignment = { x = "right", y = "up" },
        text = "Elevation: " .. math.ceil(player:get_pos().y - seaLevel) .. " m",
        color = 0xFFFFFF,
    })

    return true
end

Realm.RegisterOnJoinCallback(function(realm, player)
    mc_worldManager.UpdateRealmHud(player)
end)