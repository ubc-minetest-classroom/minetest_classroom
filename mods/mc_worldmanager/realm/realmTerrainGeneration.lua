minetest.set_mapgen_setting('mg_name', 'singlenode', true)
minetest.set_mapgen_setting('flags', 'nolight', true)

Realm.WorldGen = {}
local heightMapGenerator = {}
local MapDecorator = {}
local VegetationDecorator = {}

function Realm.WorldGen.RegisterHeightMapGenerator(name, heightMapGeneratorFunction)
    if (heightMapGenerator[name] ~= nil) then
        Debug.log("HeightMapGenerator " .. name .. " already exists.")
        return
    end
    heightMapGenerator[name] = heightMapGeneratorFunction
end

function Realm.WorldGen.GetHeightmapGenerators()
    local keyset = {}
    for k, v in pairs(heightMapGenerator) do
        keyset[#keyset + 1] = k
    end
    return keyset
end

function Realm.WorldGen.GetTerrainDecorator()
    local keyset = {}
    for k, v in pairs(MapDecorator) do
        keyset[#keyset + 1] = k
    end
    return keyset
end

function Realm.WorldGen.RegisterMapDecorator(name, NodeDecoratorFunction, VegetationDecoratorFunction)
    if (MapDecorator[name] ~= nil) then
        Debug.log("MapDecorator " .. name .. " already exists.")
        return
    end
    MapDecorator[name] = NodeDecoratorFunction
    VegetationDecorator[name] = VegetationDecoratorFunction
end

function Realm:GenerateTerrain(seed, seaLevel, heightMapGeneratorName, mapDecoratorName, paramTable)

    self:set_data("worldSeed", seed)
    self:set_data("seaLevel", seaLevel)
    self:set_data("worldMapGenerator", heightMapGeneratorName)
    self:set_data("worldDecoratorName", mapDecoratorName)
    self:set_data("worldExtraGenParams", paramTable)

    local heightMapGen = heightMapGenerator[heightMapGeneratorName]
    local mapDecorator = MapDecorator[mapDecoratorName]
    local vegetationDecorator = VegetationDecorator[mapDecoratorName]

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
    local heightMapTable = heightMapGen(self.StartPos, self.EndPos, vm, area, data, seed, self.StartPos.y, seaLevel, paramTable)

    local decoratorData = { }
    if mapDecorator ~= nil then
        decoratorData = mapDecorator(self.StartPos, self.EndPos, vm, area, data, heightMapTable, seed, seaLevel, paramTable)
    end

    Debug.log("Saving and loading map...")

    vm:set_data(data)
    vm:write_to_map()

    if (vegetationDecorator ~= nil) then
        vegetationDecorator(self.StartPos, self.EndPos, area, data, heightMapTable, decoratorData, seed, seaLevel, paramTable)
    end

    -- Set our new spawnpoint
    local spawnPos = self.SpawnPoint
    local surfaceLevel = ptable.get2D(heightMapTable, { x = spawnPos.x, y = spawnPos.z })

    if (surfaceLevel == nil) then
        local spawnPos = { x = (self.StartPos.x + self.EndPos.x) / 2, y = (self.StartPos.y + self.EndPos.y) / 2, z = (self.StartPos.z + self.EndPos.z) / 2 }
        surfaceLevel = ptable.get2D(heightMapTable, { x = spawnPos.x, y = spawnPos.z })

        if (surfaceLevel == nil) then
            surfaceLevel = self.EndPos.y - 5
        end
    end

    self:UpdateSpawn(self:WorldToLocalSpace({ x = spawnPos.x, y = surfaceLevel + 1, z = spawnPos.z }))
end