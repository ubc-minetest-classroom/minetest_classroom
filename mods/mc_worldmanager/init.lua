mc_worldManager = {}
-- Source files
dofile(minetest.get_modpath("mc_worldmanager") .. "/refractor.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/realm.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/nodes.lua")

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




        local point = requestedRealm.SpawnPoint

        local player = minetest.get_player_by_name(name)
        player:set_pos(point)
        return true, "Requested realm has a spawn point of " .. requestedRealm.SpawnPoint
    end,
})



