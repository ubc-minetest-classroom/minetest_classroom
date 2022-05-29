function Realm:TeleportPlayer(player)
    local pmeta = player:get_meta()
    pmeta:set_int("realm", self.ID)

    local spawn = self.SpawnPoint
    player:set_pos(spawn)
end