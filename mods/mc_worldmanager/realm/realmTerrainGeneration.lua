minetest.set_mapgen_setting('mg_name', 'singlenode', true)
minetest.set_mapgen_setting('flags', 'nolight', true)

Realm.WorldGen = {}
local heightMapGenerator = {}
local MapDecorator = {}

function Realm.WorldGen.RegisterHeightMapGenerator(name, func)
    if (heightMapGenerator[name] ~= nil) then
        Debug.log("HeightMapGenerator " .. name .. " already exists.")
        return
    end
    heightMapGenerator[name] = func
end

function Realm.WorldGen.RegisterMapDecorator(name, func)
    if (MapDecorator[name] ~= nil) then
        Debug.log("MapDecorator " .. name .. " already exists.")
        return
    end
    MapDecorator[name] = func
end

function Realm:GenerateTerrain(seed, seaLevel, heightMapGeneratorName, mapDecoratorName)

    self:set_data("worldSeed", seed)

    local heightMapGen = heightMapGenerator[heightMapGeneratorName]
    local mapDecorator = MapDecorator[mapDecoratorName]

    if (heightMapGen == nil) then
        Debug.log("Height map generator with name: " .. heightMapGeneratorName .. " does not exist.")
        return false
    end

    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(self.StartPos, self.EndPos)
    local area = VoxelArea:new {
        MinEdge = emin,
        MaxEdge = emax
    }

    local data = vm:get_data()
    local heightMapTable = heightMapGen(self.StartPos, self.EndPos, vm, area, data, seed, self.StartPos.y, seaLevel)

    if mapDecorator ~= nil then
        mapDecorator(self.StartPos, self.EndPos, vm, area, data, heightMapTable, seed, seaLevel)
    end

    Debug.log("Saving and loading map...")

    vm:set_data(data)
    vm:write_to_map()

    -- Set our new spawnpoint
    local oldSpawnPos = self.SpawnPoint
    local surfaceLevel = ptable.get2D(heightMapTable, { x = oldSpawnPos.x, y = oldSpawnPos.z })

    self:UpdateSpawn(self:WorldToLocalPosition({ x = oldSpawnPos.x, y = surfaceLevel, z = oldSpawnPos.z }))
end