-- All the functionality from these commands will added to a realm book.
-- These commands are currently just for testing

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

minetest.register_chatcommand("realmSchematic", {
    params = "Realm ID",
    privs = {
        interact = true,
    },
    func = function(name, param)
        local requestedRealm = Realm.realmDict[tonumber(param)]
        if (requestedRealm == nil) then
            return false, "Requested realm of ID:" .. param .. " does not exist."
        end

        local path = requestedRealm:Save_Schematic(name)

        return true, "Saved realm with ID " .. param .. " at path: " .. path
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

minetest.register_chatcommand("realmWalls", {
    params = "Realm ID",
    privs = {
        interact = true,
    },
    func = function(name, param)
        local requestedRealm = Realm.realmDict[tonumber(param)]
        if (requestedRealm == nil) then
            return false, "Requested realm of ID:" .. param .. " does not exist."
        end

        requestedRealm:CreateBarriers()


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

minetest.register_chatcommand("realmSetSpawn", {
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

        requestedRealm:UpdateSpawn(position)

        return true, "Updated spawnpoint for realm with ID: " .. param
    end,
})

minetest.register_chatcommand("realmCleanup", {
    privs = {
        interact = true,
    },
    func = function(name, param)
        Realm.consolidateEmptySpace()
        Realm.SaveDataToStorage()
        return true, "consolidated realms"
    end,
})



