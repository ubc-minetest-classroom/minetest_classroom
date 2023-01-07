---@public
---TeleportPlayer
---Teleports a player to this realm.
---@param player
function Realm:TeleportPlayer(player)
    -- STOP: Before modifying this function, make sure that you have a good reason for doing so.
    -- Most additions to this function should be made by registering a callback with
    -- Realm.RegisterOnJoinCallback(function(realm, player) ... end) or Realm.RegisterOnLeaveCallback(function(realm, player) ... end)

    -- We check if the player has privilege to join this realm based on the realms category.
    local realmCategory = self:getCategory()
    local joinable, reason = realmCategory.joinable(self, player)
    if (not joinable and not minetest.check_player_privs(player, { teacher = true })) then
        return false, "Player does not have permission to join this realm."
    end

    -- We remove the player from their old realm.
    local newRealmID, OldRealmID = self:UpdatePlayerMetaData(player)
    if (OldRealmID ~= nil) then
        local oldRealm = Realm.realmDict[OldRealmID]
        if (oldRealm ~= nil) then
            oldRealm:RunTeleportOutFunctions(player)
            oldRealm:DeregisterPlayer(player)
        end
    end

    -- We teleport the player to the realm.
    local spawn = self.SpawnPoint
    player:set_pos(spawn)

    -- We register the player with the new realm, and apply their realm-specific privileges.
    self:RegisterPlayer(player)
    self:ApplyPrivileges(player)

    -- We run the teleport functions of the new realm. These are added by non-core features, other mods, and realms.
    self:RunTeleportInFunctions(player)

    -- Remove active huds that are realm-specific
    mc_student.remove_marker(player:get_player_name())

    return true, "Successfully teleported to realm."
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
    self:CallOnJoinCallbacks(player)
end

---@private
function Realm:RunTeleportOutFunctions(player)
    self:RunFunctionFromTable(self.PlayerLeaveTable, player)
    self:CallOnLeaveCallbacks(player)
end

---@private
---@param table table
function Realm:RegisterPlayer(player)
    local table = self:get_tmpData("Inhabitants")
    if (table == nil) then
        table = {}
    end
    table[player:get_player_name()] = true
    self:set_tmpData("Inhabitants", table)
end

---@private
---@param player
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

---@public
---GetPlayers retrieves a table containing the current inhabitants of this realm.
---@return table containing the names of players currently in this realm.
function Realm:GetPlayers()
    return self:get_tmpData("Inhabitants")
end

function Realm:GetPlayersAsArray()
    local players = self:GetPlayers()
    local retval = {}
    for k, v in pairs(players) do
        if (v == true) then
            table.insert(retval, k)
        end
    end
    return retval
end

---@public
---GetPlayerCount retrieves the number of players currently in this realm.
---@return number of players currently in this realm.
function Realm:GetPlayerCount()
    local inhabitants = self:get_tmpData("Inhabitants")
    if inhabitants then
        local countInhabitants = 0
        for _ in pairs(inhabitants) do countInhabitants = countInhabitants + 1 end
        return countInhabitants
    else
        return 0
    end
end