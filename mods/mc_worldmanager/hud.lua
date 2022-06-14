local function createHudString(player)
    local pmeta = player:get_meta()
    local realmID = pmeta:get_int("realm")
    local realm = Realm.realmDict[realmID]

    local string = "Realm " .. realmID

    if (realm ~= nil) then
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

    mc_worldManager.hud:change(player, "worldManager:currentRealm", {
        hud_elem_type = "text",
        position = { x = 1, y = 0 },
        offset = { x = -16, y = 5 },
        alignment = { x = "left", y = "down" },
        text = createHudString(player),
        color = 0xFFFFFF,
    })
end

function mc_worldManager.RemoveHud(player)
    mc_worldManager.hud:remove(player)
end