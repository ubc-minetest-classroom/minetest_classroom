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

    Debug.log(minetest.serialize(privs))

    -- Revoke all privs
    for k, v in pairs(privs) do
        privs[k] = nil
    end

    local defaultPerms = minetest.deserialize(pmeta:get_string("defaultPerms"))
    for k, v in pairs(defaultPerms) do
        privs[k] = v
    end

    local realmPermissions = self:get_data("perms")
    if (realmPermissions ~= nil) then
        for k, v in pairs(realmPermissions) do
            privs[k] = v
        end
    end

    Debug.log(minetest.serialize(privs))

    minetest.set_player_privs(name, privs)
end