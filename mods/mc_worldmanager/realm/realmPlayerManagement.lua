function Realm:TeleportPlayer(player)
    local newRealmID, OldRealmID = self:UpdatePlayerMetaData(player)

    if (OldRealmID ~= nil) then
        local oldRealm = Realm.realmDict[OldRealmID]
        if (oldRealm ~= nil) then
            oldRealm:RunTeleportOutFunctions(player)
            oldRealm:RemovePlayer(player)
        end
    end

    self:RunTeleportInFunctions(player)
    local spawn = self.SpawnPoint
    player:set_pos(spawn)

    self:AddPlayer(player)
    mc_worldManager.updateHud(player)
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

function Realm:AddPlayer(player)
    local table = self:get_tmpData("Inhabitants")
    if (table == nil) then
        table = {}
    end
    table[player:get_player_name()] = true
    self:set_tmpData("Inhabitants", table)
end

function Realm:RemovePlayer(player)
    local table = self:get_tmpData("Inhabitants")
    if (table == nil) then
        table = {}
    end
    table[player:get_player_name()] = nil
    self:set_tmpData("Inhabitants", table)
end

function Realm.ScanForPlayers()

end


function Realm.GetRealmFromPlayer(player)
    local pmeta = player:get_meta()
    local playerRealmID = pmeta:get_int("realm")

    local realm = Realm.realmDict[playerRealmID]
    return realm
end