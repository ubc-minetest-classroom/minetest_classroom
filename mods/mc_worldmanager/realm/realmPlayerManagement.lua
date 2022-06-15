function Realm:TeleportPlayer(player)
    local newRealmID, OldRealmID = self:UpdatePlayerMetaData(player)

    if (OldRealmID ~= nil) then
        local oldRealm = Realm.realmDict[OldRealmID]
        if (oldRealm ~= nil) then
            oldRealm:RunTeleportOutFunctions(player)
        end
    end

    self:RunTeleportInFunctions(player)
    local spawn = self.SpawnPoint
    player:set_pos(spawn)

    mc_worldManager.updateHud(player)
    self:ApplyPermissions(player)
end

function Realm:UpdatePlayerMetaData(player)
    local pmeta = player:get_meta()
    local oldRealmID = pmeta:get_int("realm")

    if (oldRealmID == nil) then
        oldRealmID = mc_worldManager.GetSpawnRealm()
    end

    local newRealmID = self.ID
    pmeta:set_int("realm", newRealmID)
    return newRealmID, oldRealmID
end

function Realm:RunTeleportInFunctions(player)
    self:RunFunctionFromTable(self.PlayerJoinTable, player)
end

function Realm:RunTeleportOutFunctions(player)
    self:RunFunctionFromTable(self.PlayerLeaveTable, player)
end

function Realm:ApplyPermissions(player)
    local name = player:get_player_name()
    local pmeta = player:get_meta()

    local privs = minetest.get_player_privs(name)


    -- Revoke all privileges
    for k, v in pairs(privs) do
        privs[k] = nil
    end

    -- Add the universal privileges that a player has access to.
    local defaultPerms = minetest.deserialize(pmeta:get_string("universalPrivs"))
    for k, v in pairs(defaultPerms) do
        privs[k] = v
    end

    -- Add the realm privileges for any given realm.
    if (self.Permissions ~= nil) then
        for k, v in pairs(self.Permissions) do
            privs[k] = v
        end
    end

    minetest.set_player_privs(name, privs)
end