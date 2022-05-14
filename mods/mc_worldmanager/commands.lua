minetest.register_chatcommand("realmNew", {
    privs = {
        interact = true,
    },
    func = function(name, param)
        param = param or "Unnamed Realm"
        local testRealm = Realm:New(param, 80, 80)
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

        local spawn = requestedRealm.SpawnPoint
        player:set_pos(spawn)


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