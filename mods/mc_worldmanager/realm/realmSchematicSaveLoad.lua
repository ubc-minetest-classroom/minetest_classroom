---@public
---Save_Schematic
---@return string, boolean The filepath of the schematic; whether the settings file wrote succesfully.
function Realm:Save_Schematic()
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
    settings:set("author", "unknown")
    settings:set("name", "unknown")
    settings:set("spawn_pos_x", self.SpawnPoint.x)
    settings:set("spawn_pos_y", self.SpawnPoint.y)
    settings:set("spawn_pos_z", self.SpawnPoint.z)

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
function Realm:Load_Schematic(key)
    local schematic, config = schematicManager.getSchematic(key)

    self.EndPos.x = self.StartPos.x + config.size.x
    self.EndPos.y = self.StartPos.y + config.size.y
    self.EndPos.z = self.StartPos.z + config.size.z


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

    self:UpdateSpawn(config.spawnPoint)
    return results
end