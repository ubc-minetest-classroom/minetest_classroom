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

function Realm.WorldGen.RegisterMapDecorator(name, NodeDecoratorFunction, VegetationDecoratorFunction)
    if (MapDecorator[name] ~= nil) then
        Debug.log("MapDecorator " .. name .. " already exists.")
        return
    end
    MapDecorator[name] = NodeDecoratorFunction
    VegetationDecorator[name] = VegetationDecoratorFunction
end

function Realm:GenerateTerrain(seed, seaLevel, heightMapGeneratorName, mapDecoratorName)

    self:set_data("worldSeed", seed)
    self:set_data("worldSeaLevel", seaLevel)
    self:set_data("worldMapGenerator", heightMapGeneratorName)
    self:set_data("worldDecoratorName", mapDecoratorName)

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
    local heightMapTable = heightMapGen(self.StartPos, self.EndPos, vm, area, data, seed, self.StartPos.y, seaLevel)

    local mapAlreadySaved = false
    if mapDecorator ~= nil then
        mapAlreadySaved = mapDecorator(self.StartPos, self.EndPos, vm, area, data, heightMapTable, seed, seaLevel)
    end

    Debug.log("Saving and loading map...")

    vm:set_data(data)
    vm:write_to_map()

    if (vegetationDecorator ~= nil) then
        vegetationDecorator(self.StartPos, self.EndPos, area, data, heightMapTable, seed, seaLevel)
    end

    -- Set our new spawnpoint
    local oldSpawnPos = self.SpawnPoint
    local surfaceLevel = ptable.get2D(heightMapTable, { x = oldSpawnPos.x, y = oldSpawnPos.z })

    self:UpdateSpawn(self:WorldToLocalPosition({ x = oldSpawnPos.x, y = surfaceLevel, z = oldSpawnPos.z }))
end