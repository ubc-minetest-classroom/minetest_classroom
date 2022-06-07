-- All the functionality from these commands will added to a realm book.
-- These commands are currently just for testing

local commands = {}

minetest.register_chatcommand("realmNew", {
    privs = {
        interact = true,
    },
    func = function(name, param)
        param = param or "Unnamed Realm"
        local testRealm = Realm:New(param, { x = 20, y = 20, z = 20 })
        testRealm:CreateGround()
        testRealm:CreateBarriers()
        return true, "executed command. New realm has ID: " .. testRealm.ID
    end,
})

minetest.register_chatcommand("realmDelete", {
    params = "Realm ID",
    privs = {
        interact = true,
    },
    func = function(name, param)
        local requestedRealm = Realm.realmDict[tonumber(param)]
        if (requestedRealm == nil) then
            return false, "Requested realm of ID:" .. param .. " does not exist."
        end

        requestedRealm:Delete()

        return true, "Deleted realm with ID: " .. param
    end,
})

minetest.register_chatcommand("realmList", {
    privs = {
        interact = true,
    },
    func = function(name, param)

        minetest.chat_send_player(name, "Realm Name : Realm ID")
        for i, t in pairs(Realm.realmDict) do
            minetest.chat_send_player(name, t.Name .. " : " .. t.ID)
        end

        return true

    end,
})

---Test command to display realm information
minetest.register_chatcommand("realmInfo", {
    params = "Realm ID",
    privs = {
        interact = true,
    },
    func = function(name, param)
        local requestedRealm = Realm.realmDict[tonumber(param)]
        if (requestedRealm == nil) then
            return false, "Requested realm of ID:" .. param .. " does not exist."
        end

        local spawn = requestedRealm.SpawnPoint
        local startPos = requestedRealm.StartPos
        local endPos = requestedRealm.EndPos

        return true, "Realm " .. param .. " has a spawn point of "
                .. "x:" .. tostring(spawn.x) .. " y:" .. tostring(spawn.y) .. " z:" .. tostring(spawn.z)
                .. "; startPos of "
                .. "x:" .. tostring(startPos.x) .. " y:" .. tostring(startPos.y) .. " z:" .. tostring(startPos.z)
                .. "; endPos of "
                .. "x:" .. tostring(endPos.x) .. " y:" .. tostring(endPos.y) .. " z:" .. tostring(endPos.z)
    end,
})

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



minetest.register_chatcommand("localPos", {
    params = "Realm ID",
    privs = {
        interact = true,
    },
    func = function(name, param)
        local requestedRealm = Realm.realmDict[tonumber(param)]
        if (requestedRealm == nil) then
            return false, "Requested realm of ID:" .. param .. " does not exist."
        end

        local player = minetest.get_player_by_name(name)
        local position = requestedRealm:WorldToLocalPosition(player:get_pos())

        return true, "Your position in the local space of realm " .. param .. " is x: " .. position.x .. " y: " .. position.y .. " z: " .. position.z


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
        else
            return false, "Unknown subcommand"
        end


    end,
})