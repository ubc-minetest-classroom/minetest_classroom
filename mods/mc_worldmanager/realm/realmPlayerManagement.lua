function Realm:TeleportPlayer(player)
    self:UpdatePlayerMetaData(player)
    self:RunTeleportInFunctions(player)
    local spawn = self.SpawnPoint
    player:set_pos(spawn)
end

function Realm:UpdatePlayerMetaData(player)
    local pmeta = player:get_meta()
    pmeta:set_int("realm", self.ID)
end

function Realm:RunTeleportInFunctions(player)

    if (self.PlayerJoinTable ~= nil) then
        for key, value in pairs(self.PlayerJoinTable) do
            minetest.debug(value.tableName)
            minetest.debug(value.functionName)
            if (value.tableName ~= nil and value.functionName ~= nil) then
                local table = loadstring("return " .. value.tableName)()
                table[value.functionName](self, player)
            end


        end
    end
end