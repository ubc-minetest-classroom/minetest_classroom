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
    self:ApplyPrivileges(player)
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