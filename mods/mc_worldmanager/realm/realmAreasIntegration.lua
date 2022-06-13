function Realm:AddPlayerArea(player)
    local playerName = player:get_player_name()
    local realmArea = self:get_string("protectionID")

    if (self.MetaStorage.areas == nil) then
        self.MetaStorage.areas = {}
    end
    local playerArea = self.MetaStorage.areas[playerName]

    if (playerArea == nil) then
        Debug.log(realmArea)
        self.MetaStorage.areas[player:get_player_name()] = areas:add(playerName, playerName .. " Zone in " .. self.Name, self.StartPos, self.EndPos, realmArea)
        areas:save()
    end
end

function Realm:RemovePlayerArea(player)
    local playerName = player:get_player_name()

    if (self.MetaStorage.areas == nil) then
        self.MetaStorage.areas = {}
    end
    local playerArea = self.MetaStorage.areas[playerName]
    if (playerArea ~= nil) then
        areas:remove(playerArea, true)
        areas:save()
        self.MetaStorage.areas[playerName] = nil
    end
end