minetest.register_chatcommand("newRealm", {
    privs = {
        interact = true,
    },
    func = function(name, param)
        local testRealm = Realm:new()
        testRealm:ground()
        return true, "executed command. New realm has ID: " .. testRealm.ID
    end,
})


---Test command to display realm information
minetest.register_chatcommand("realm", {
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


        return true, "Realm " .. param ..  " has a spawn point of "
                .. "x:" .. tostring(spawn.x) .. " y:" .. tostring(spawn.y) .. " z:" .. tostring(spawn.z)
                .. "; startPos of "
                .. "x:" .. tostring(startPos.x) .. " y:" .. tostring(startPos.y) .. " z:" .. tostring(startPos.z)
                .. "; endPos of "
                .. "x:" .. tostring(endPos.x) .. " y:" .. tostring(endPos.y) .. " z:" .. tostring(endPos.z)
    end,
})