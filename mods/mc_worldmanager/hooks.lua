local function makePlayerImmortal(player)
    local groups = player:get_armor_groups() or {}
    groups["immortal"] = 1
    player:set_armor_groups(groups)
    
    local prop_table = player:get_properties()
    if prop_table.hp_max then
        player:set_hp(prop_table.hp_max, "immortality")
    end
end

local function makePlayerMortal(player)
    local groups = player:get_armor_groups() or {}
    groups["immortal"] = 0
    player:set_armor_groups(groups)
end

-- on first player spawn, we assign them to the world spawn realm
-- and set their position to that spawnpoint .
minetest.register_on_newplayer(function(player)
    local spawnRealm = mc_worldManager.GetSpawnRealm()
    local pmeta = player:get_meta()
    pmeta:set_int("realm", spawnRealm.ID)
    pmeta:set_string("universalPrivs", minetest.serialize(minetest.get_player_privs(player:get_player_name())))
    spawnRealm:TeleportPlayer(player)

    makePlayerImmortal(player)
end)

-- When players respawn, we teleport them to the spawnpoint of the realm they belong to
minetest.register_on_respawnplayer(function(player)
    local realm = Realm.GetRealmFromPlayer(player)

    if (realm ~= nil) then
        mc_core.temp_unfreeze_and_run(player, player.set_pos, player, realm.SpawnPoint)
    else
        mc_core.temp_unfreeze_and_run(player, player.set_pos, player, mc_worldManager.GetSpawnRealm().SpawnPoint)
    end

    makePlayerImmortal(player)
    return true
end)

-- When player joins the game, we make sure all pmeta is set correctly, create their hud, etc.,
minetest.register_on_joinplayer(function(player, last_login)
    local pmeta = player:get_meta()
    if (pmeta:get_int("realm") == nil) then
        pmeta:set_int("realm", mc_worldManager.GetSpawnRealm().ID)
    end

    if (pmeta:get_string("universalPrivs") == nil) then
        pmeta:set_string("universalPrivs", minetest.serialize(minetest.get_player_privs(player:get_player_name())))
    end

    local realm = Realm.GetRealmFromPlayer(player)

    if (realm ~= nil) then
        -- don't allow players to enter realms they no longer have access to when joining
        if not realm:Joinable(player) then
            realm = mc_worldManager.GetSpawnRealm()
            mc_core.temp_unfreeze_and_run(player, realm.TeleportPlayer, realm, player)
            pmeta:set_int("realm", realm.ID)
        end

        mc_worldManager.UpdateRealmHud(player)
        realm:RegisterPlayer(player)
        realm:RunTeleportInFunctions(player)
        realm:ApplyPrivileges(player)
        realm:ApplySkybox(player)
        mc_core.update_marker_visibility(player:get_player_name(), realm.ID)
    end
end)

-- When player leave the game, we delete their hud
minetest.register_on_leaveplayer(function(player, timed_out)
    mc_worldManager.RemoveHud(player)

    --[[ NOTE: instanced realms are no longer required to be temporary, so this block is obsolete for the time being
         TODO: add some way to differentiate temporary instances and "long term" instances (i.e. private realms)
    local realm = Realm.GetRealmFromPlayer(player)
    if (realm:getCategory().key == "instanced") then
        mc_worldManager.GetSpawnRealm():TeleportPlayer(player)
    end]]

    local realm = Realm.GetRealmFromPlayer(player)
    if (realm ~= nil) then
        realm:DeregisterPlayer(player)
        realm:RunTeleportOutFunctions(player)
    end
end)

mc_worldManager.tick = 0
mc_worldManager.voidTick = 0
mc_worldManager.outOfBoundPlayers = {}
minetest.register_globalstep(function(deltaTime)

    if #minetest.get_connected_players() == 0 then
        return -- Don't run the following code if no players are online
    end

    mc_worldManager.tick = mc_worldManager.tick + deltaTime
    if (mc_worldManager.tick > 10) then
        mc_worldManager.tick = 0

        for id, player in ipairs(minetest.get_connected_players()) do
            -- Loop through all players online
            local pmeta = player:get_meta()
            local realm = Realm.realmDict[pmeta:get_int("realm")]

            if (realm == nil) then
                -- If the player doesn't have a realm, this is a good place to move them to spawn.
                mc_worldManager.GetSpawnRealm():TeleportPlayer(player)
                return
            end

            local pos = player:get_pos()

            if (not realm:ContainsCoordinate(pos)) then
                table.insert(mc_worldManager.outOfBoundPlayers, player:get_player_name())
                makePlayerMortal(player)
            end
        end
    end

    if #mc_worldManager.outOfBoundPlayers == 0 then
        return -- Don't run the following code if no players are out of bounds
    end

    -- Run the code to damage players out of bounds more frequently to give that "void" damage effect from Minecraft.
    mc_worldManager.voidTick = mc_worldManager.voidTick + deltaTime
    if (mc_worldManager.voidTick > 0.5) then
        mc_worldManager.voidTick = 0

        for id, playerName in ipairs(mc_worldManager.outOfBoundPlayers) do
            local player = minetest.get_player_by_name(playerName)

            -- If the player is now in a realm, we remove their name from the outOfBoundPlayers table so that we don't keep punishing them.
            local pmeta = player:get_meta()
            local realm = Realm.realmDict[pmeta:get_int("realm")]

            if (realm == nil) then
                -- If the player doesn't have a realm, this is a good place to move them to spawn.
                mc_worldManager.GetSpawnRealm():TeleportPlayer(player)
                return
            end

            local pos = player:get_pos()

            if (realm:ContainsCoordinate(pos)) then
                table.remove(mc_worldManager.outOfBoundPlayers, id)
                makePlayerImmortal(player)
                return
            end

            local hp = player:get_hp() - 4
            if (hp <= 0) then
                hp = 0
                table.remove(mc_worldManager.outOfBoundPlayers, id)
                realm:TeleportPlayer(player)
            end

            player:set_hp(hp, "void")

            if (player:get_hp() < 0) then
                player:set_hp(0, "void")
            end
        end
    end
end)

mc_worldManager.hudTick = 0
minetest.register_globalstep(function(deltaTime)
    mc_worldManager.hudTick = mc_worldManager.hudTick + deltaTime

    if (mc_worldManager.hudTick > 0.5) then
        mc_worldManager.hudTick = 0

        for id, player in ipairs(minetest.get_connected_players()) do
            local pmeta = player:get_meta()
            local positionHudMode = pmeta:get_string("positionHudMode")
            if (positionHudMode ~= "") then
                mc_worldManager.UpdatePositionHud(player, positionHudMode)
            end
        end
    end

end)

minetest.register_on_shutdown(function()
    Realm.SaveDataToStorage()
end)

minetest.register_on_mods_loaded(function()
    for id,realm in pairs(Realm.realmDict) do
        -- Ensure that there is only one spawn realm
        local cat = realm:getCategory().key
        if cat == "spawn" and tonumber(id) ~= tonumber(mc_worldManager.spawnRealmID) then
            realm:setCategoryKey("default")
        elseif cat ~= "spawn" and tonumber(id) == tonumber(mc_worldManager.spawnRealmID) then
            realm:setCategoryKey("spawn")
        end

        -- Apply old default skybox to realms with undefined skyboxes
        local sky = realm:GetSkybox()
        if not sky then
            realm:UpdateSkybox(skybox.get_default_sky())
        end
    end
end)
