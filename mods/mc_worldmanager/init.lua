mc_worldManager = {}
-- Source files
dofile(minetest.get_modpath("mc_worldmanager") .. "/refractor.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/realm.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/nodes.lua")
dofile(minetest.get_modpath("mc_worldmanager") .. "/commands.lua")



-- To test, we are making a new realm for each new player
minetest.register_on_newplayer(function(player)

    local NewPlayerRealm = Realm.realmDict[1]

    if (NewPlayerRealm == nil) then
        NewPlayerRealm = Realm:New("Tutorial Realm")
        NewPlayerRealm:CreateGround()
    end

    local name = player:get_player_name()
    player:set_pos({x=NewPlayerRealm.SpawnPoint.x,y=NewPlayerRealm.SpawnPoint.y+5,z=NewPlayerRealm.SpawnPoint.z})
end)