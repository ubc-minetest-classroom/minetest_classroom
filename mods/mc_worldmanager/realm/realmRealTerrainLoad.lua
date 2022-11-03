---@public
---Load_RealTerrain
---@param key string the corresponding value for this DEM as registered by the realterrain manager.
---@return boolean whether the DEM will fit entirely in the realm when loading.
function Realm:Load_RealTerrain(DEM_PATH, config)

    local DEMStartPos = self:LocalToWorldSpace(config.startOffset)
    local DEMEndPos = self:LocalToWorldSpace(config.DEMSize)

    if (DEMEndPos.x > self.EndPos.x or DEMEndPos.y > self.EndPos.y or DEMEndPos.z > self.EndPos.z) then
        Debug.log("DEM is too large for realm, creating a new realm with the same name but larger size")
        local newRealm = self:New(self.Name, DEMEndPos, true)
        self:Delete()
        self = newRealm
    else
        if (DEMEndPos.x == nil or DEMEndPos == 0) then
            DEMEndPos.x = 80
            Debug.log("DEM size x is 0, setting to 80")
        end

        if (DEMEndPos.y == nil or DEMEndPos == 0) then
            DEMEndPos.y = 80
            Debug.log("DEM size y is 0, setting to 80")
        end

        if (DEMEndPos.z == nil or DEMEndPos == 0) then
            DEMEndPos.z = 80
            Debug.log("DEM size z is 0, setting to 80")
        end

        self.EndPos = DEMEndPos
    end

    if (config.utmInfo ~= nil) then
        self:set_data("UTMInfo", config.utmInfo)
    end

    for k, v in pairs(config.miscData) do
        self:set_data(k, v)
    end

    self:set_data("seaLevel", self.StartPos.y + config.elevationOffset)

    if (config.tableName ~= nil) then
        if (config.onDEMPlaceFunction ~= nil) then
            local table = loadstring("return " .. config.tableName)()
            table[config.onDEMPlaceFunction](self)
        end

        if (config.onTeleportInFunction ~= nil) then
            table.insert(self.PlayerJoinTable, { tableName = config.tableName, functionName = config.onTeleportInFunction })
        end

        if (config.onTeleportOutFunction ~= nil) then
            table.insert(self.PlayerLeaveTable, { tableName = config.tableName, functionName = config.onTeleportOutFunction })
        end

        if (config.onRealmDeleteFunction ~= nil) then
            table.insert(self.RealmDeleteTable, { tableName = config.tableName, functionName = config.onRealmDeleteFunction })
        end

    end

    self:UpdateSpawn(config.spawnPoint)

    -- Queue the realm
    realterrain.loadRealm = self
    realterrain.realmEmergeContinue = true
    realterrain.init(DEM_PATH)
end

function Realm:NewFromDEM(name, key)
    local DEM_PATH, config = realterrainManager.getDEM(key)
    realterrain.queued_key = key

    if (name == "" or name == nil) then
        name = config.name
    end

    local newRealm = Realm:New(name, config.DEMSize, false)
    newRealm:Load_RealTerrain(DEM_PATH, config)
    newRealm:CreateBarriersFast()

    newRealm:CallOnCreateCallbacks()

    return newRealm
end