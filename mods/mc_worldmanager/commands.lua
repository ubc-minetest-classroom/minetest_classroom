-- All the functionality from these commands will added to a realm book.
-- These commands are currently just for testing

local commands = {}

minetest.register_chatcommand("localPos", {
    privs = {
        interact = true,
    },
    func = function(name, param)


        local player = minetest.get_player_by_name(name)

        local pmeta = player:get_meta()
        local realmID = pmeta:get_int("realm")

        local requestedRealm = Realm.realmDict[realmID]

        local position = requestedRealm:WorldToLocalPosition(player:get_pos())

        return true, "Your position in the local space of realm " .. param .. " is x: " .. position.x .. " y: " .. position.y .. " z: " .. position.z


    end,
})

commands["new"] = function(name, realmID, requestedRealm, params)
    requestedRealm:CreateBarriers()
    local param = params[1] or "Unnamed Realm"
    local size = param[2]
    local sizeY = param[3]
    local testRealm = Realm:New(param, { x = size, y = sizeY, z = size })
    testRealm:CreateGround()
    testRealm:CreateBarriers()
end

commands["delete"] = function(name, realmID, requestedRealm, params)
    requestedRealm:Delete()
end

commands["list"] = function(name, realmID, requestedRealm, params)
    minetest.chat_send_player(name, "Realm Name : Realm ID")
    for i, t in pairs(Realm.realmDict) do
        minetest.chat_send_player(name, t.Name .. " : " .. t.ID)
    end

    return true
end

commands["info"] = function(name, realmID, requestedRealm, params)
    local spawn = requestedRealm.SpawnPoint
    local startPos = requestedRealm.StartPos
    local endPos = requestedRealm.EndPos

    return true, "Realm " .. param .. " has a spawn point of "
            .. "x:" .. tostring(spawn.x) .. " y:" .. tostring(spawn.y) .. " z:" .. tostring(spawn.z)
            .. "; startPos of "
            .. "x:" .. tostring(startPos.x) .. " y:" .. tostring(startPos.y) .. " z:" .. tostring(startPos.z)
            .. "; endPos of "
            .. "x:" .. tostring(endPos.x) .. " y:" .. tostring(endPos.y) .. " z:" .. tostring(endPos.z)
end


---Test command to display realm information

minetest.register_chatcommand("realmTP", {
    params = "Realm ID",
    privs = {
        interact = true,
    },
    func = function(name, param)
        local requestedRealm = Realm.realmDict[tonumber(param)]
        if (requestedRealm == nil) then
            return false, "Requested realm of ID:" .. param .. " does not exist."
        end

        player = minetest.get_player_by_name(name)

        requestedRealm:TeleportPlayer(player)
    end,
})

commands["walls"] = function(name, realmID, requestedRealm, params)
    requestedRealm:CreateBarriers()
end

commands["schematic"] = function(name, realmID, requestedRealm, params)
    if (params[1] == "schematic") then
        local subparam = params[1] or "old"
        local path = requestedRealm:Save_Schematic(name, subparam)
        return true, "Saved realm with ID " .. realmID .. " at path: " .. path
    else
        return false, "unknown sub-command..."
    end
end

commands["setspawn"] = function(name, realmID, requestedRealm, params)
    local player = minetest.get_player_by_name(name)
    local position = requestedRealm:WorldToLocalPosition(player:get_pos())

    requestedRealm:UpdateSpawn(position)

    return true, "Updated spawnpoint for realm with ID: " .. param
end

commands["setspawnrealm"] = function(name, realmID, requestedRealm, params)
    local success = mc_worldManager.SetSpawnRealm(requestedRealm)

    if (success) then
        return true, "Updated the spawn realm to realm with ID: " .. realmID
    else
        return false, "something went wrong... could not update the spawn realm."
    end
end

minetest.register_chatcommand("realm", {
    params = "Subcommand Realm ID Option",
    privs = {
        teacher = true,
    },
    func = function(name, param)

        local params = mc_helpers.split(param, " ")
        local subcommand = params[1]
        table.remove(params, 1)
        local realmID = params[1]
        table.remove(params, 1)

        local requestedRealm = Realm.realmDict[tonumber(realmID)]
        if (requestedRealm == nil) then
            return false, "Requested realm of ID:" .. realmID .. " does not exist."
        end

        if (commands[subcommand] ~= nil) then
            commands[subcommand](name, realmID, requestedRealm, params)
        elseif (subcommand == "help") then
            local helpString = ""
            for k, v in pairs(commands) do
                helpString = helpString .. " " .. v
            end
            return true, helpString
        else
            return false, "Unknown subcommand"
        end


    end,
})

minetest.register_chatcommand("realmDefine", {
    params = "name pos1X pos1Y pos1Z pos2X pos2Y pos2Z",
    func = function(name, param)
        local params = mc_helpers.split(param, " ")

        -- this is really hacky, we should come up with a better way to do this...

        local name = tostring(params[1])
        local pos1X = tonumber(params[2])
        local pos1Y = tonumber(params[3])
        local pos1Z = tonumber(params[4])
        local pos2X = tonumber(params[5])
        local pos2Y = tonumber(params[6])
        local pos2Z = tonumber(params[7])

        if (name == nil or pos1X == nil or pos1Y == nil or pos1Z == nil or pos2X == nil or pos2Y == nil or pos2Z == nil) then
            return false, "missing command parameters"
        end

        local pos1 = { x = pos1X, y = pos1Y, z = pos1Z }
        local pos2 = { x = pos2X, y = pos2Y, z = pos2Z }
        local spawnPos = { x = (pos1.x + pos2.x) / 2, y = pos2.y - 5, z = (pos1.z + pos2.z) / 2 }

        local newRealm = {
            Name = name,
            ID = Realm.realmCount + 1,
            StartPos = pos1,
            EndPos = pos2,
            SpawnPoint = spawnPos,
            PlayerJoinTable = nil,
            PlayerLeaveTable = nil,
            RealmDeleteTable = nil,
            MetaStorage = { }
        }

        Realm.realmCount = newRealm.ID
        Realm:Restore(newRealm)

    end,
})