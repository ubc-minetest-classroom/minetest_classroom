local function createHudString(player)
    local realm = Realm.GetRealmFromPlayer(player)
    local string = "Realm "
    if (realm ~= nil) then
        string = string .. realm.ID
        string = string .. " : " .. realm.Name
    end
    return string
end

function mc_worldManager.CreateHud(player)
    mc_worldManager.hud:add(player, "worldManager:currentRealm", {
        hud_elem_type = "text",
        position = { x = 1, y = 0 },
        offset = { x = -16, y = 5 },
        alignment = { x = "left", y = "down" },
        text = createHudString(player),
        color = 0xFFFFFF,
    })
end

function mc_worldManager.updateHud(player)
    if (not mc_worldManager.hud:exists(player, "worldManager:currentRealm")) then
        return false
    end
    mc_worldManager.hud:change(player, "worldManager:currentRealm", {
        hud_elem_type = "text",
        position = { x = 1, y = 0 },
        offset = { x = -16, y = 5 },
        alignment = { x = "left", y = "down" },
        text = createHudString(player),
        color = 0xFFFFFF,
    })

    return true
end

function mc_worldManager.RemoveHud(player)
    mc_worldManager.hud:remove(player)
end