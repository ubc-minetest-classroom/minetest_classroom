function Realm:TeleportPlayer(player)
    self:UpdatePlayerMetaData(player)
    local spawn = self.SpawnPoint
    player:set_pos(spawn)
end

function Realm:UpdatePlayerMetaData(player)
    local pmeta = player:get_meta()
    pmeta:set_int("realm", self.ID)
end