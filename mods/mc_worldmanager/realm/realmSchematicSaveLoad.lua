---@public
---Save_Schematic
---@return string, boolean The filepath of the schematic; whether the settings file wrote succesfully.
---@public
---Save_Schematic
---@return string, boolean The filepath of the schematic; whether the settings file wrote succesfully.
function Realm:Save_Schematic(author)
    author = author or "unknown"

    local folderpath = minetest.get_worldpath() .. "\\schematics\\"

    minetest.mkdir(folderpath)

    local fileName = "Realm " .. self.ID .. " "
    for i = 1, 4 do
        fileName = fileName .. math.random(0, 9)
    end

    fileName = fileName .. os.date(" %Y%m%d %H%M")

    local filepath = folderpath .. "\\" .. fileName

    minetest.create_schematic(self.StartPos, self.EndPos, nil, filepath .. ".mts", nil)

    local settings = Settings(filepath .. ".conf")
    settings:set("author", author)
    settings:set("name", self.Name)
    settings:set("spawn_pos_x", self.SpawnPoint.x - self.StartPos.x)
    settings:set("spawn_pos_y", self.SpawnPoint.y - self.StartPos.y)
    settings:set("spawn_pos_z", self.SpawnPoint.z - self.StartPos.z)

    settings:set("schematic_size_x", self.EndPos.x - self.StartPos.x)
    settings:set("schematic_size_y", self.EndPos.y - self.StartPos.y)
    settings:set("schematic_size_z", self.EndPos.z - self.StartPos.z)

    local settingsWrote = settings:write()

    return filepath, settingsWrote
end

---@public
---Load_Schematic
---@param key string the corresponding value for this schematic as registered by the schematic manager.
---@return boolean whether the schematic fit entirely in the realm when loading.
function Realm:Load_Schematic(schematic, config)

    self.Name = config.name

    --TODO: Add code to check if the realm is large enough to support the schematic; If not, create a new realm that can;
    self.EndPos = self:LocalToWorldPosition(config.endPos)

    -- Read data into LVM
    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(self.StartPos, self.EndPos)
    local a = VoxelArea:new {
        MinEdge = emin,
        MaxEdge = emax
    }

    -- Place Schematic
    -- local results = minetest.place_schematic(self.StartPos, schematic, 0, nil, true)

    local results = minetest.place_schematic_on_vmanip(vm, self.StartPos, schematic, 0, nil, true)
    vm:write_to_map(true)

    if (config.tableName ~= nil) then
        if (config.onSchematicPlaceFunction ~= nil) then
            local table = loadstring("return " .. config.tableName)()
            table[config.onSchematicPlaceFunction](self)
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

    return results
end

function Realm:NewFromSchematic(name, key)
    local schematic, config = schematicManager.getSchematic(key)

    local newRealm = Realm:New(name, config.endPos)
    newRealm:Load_Schematic(schematic, config)
    newRealm:CreateBarriers()

    return newRealm
end