---@public
---TeleportPlayer
---Teleports a player to this realm.
---@param player objectRef
function Realm:TeleportPlayer(player)
    local newRealmID, OldRealmID = self:UpdatePlayerMetaData(player)

    if (OldRealmID ~= nil) then
        local oldRealm = Realm.realmDict[OldRealmID]
        if (oldRealm ~= nil) then
            oldRealm:RunTeleportOutFunctions(player)
            oldRealm:DeregisterPlayer(player)
        end
    end

    self:RunTeleportInFunctions(player)
    local spawn = self.SpawnPoint
    player:set_pos(spawn)

    self:RegisterPlayer(player)
    mc_worldManager.updateHud(player)
end

---@private
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

---@private
function Realm:RunTeleportInFunctions(player)
    self:RunFunctionFromTable(self.PlayerJoinTable, player)
end

---@private
function Realm:RunTeleportOutFunctions(player)
    self:RunFunctionFromTable(self.PlayerLeaveTable, player)
end

---@private
function Realm:RegisterPlayer(player)
    local table = self:get_tmpData("Inhabitants")
    if (table == nil) then
        table = {}
    end
    table[player:get_player_name()] = true
    self:set_tmpData("Inhabitants", table)
end

---@private
function Realm:DeregisterPlayer(player)
    local table = self:get_tmpData("Inhabitants")
    if (table == nil) then
        table = {}
    end
    table[player:get_player_name()] = nil
    self:set_tmpData("Inhabitants", table)
end

---@public
---Loops through all currently connected players and updates the realm inhabitant data.
---This should not be necessary, but is useful for testing to see if the realm list has become out-of-sync.
function Realm.ScanForPlayerRealms()
    for k, realm in ipairs(Realm.realmDict) do
        realm:set_tmpData("Inhabitants", {})
    end

    local connectedPlayers = minetest.get_connected_players()

    for id, player in ipairs(connectedPlayers) do
        local realm = Realm.GetRealmFromPlayer(player)
        realm:RegisterPlayer(player)
    end

end

---@public
---GetRealmFromPlayer retrieves the realm that a player is currently in.
function Realm.GetRealmFromPlayer(player)
    local pmeta = player:get_meta()
    local playerRealmID = pmeta:get_int("realm")

    local realm = Realm.realmDict[playerRealmID]
    return realm
end