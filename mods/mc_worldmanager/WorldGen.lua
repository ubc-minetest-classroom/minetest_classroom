minetest.set_mapgen_setting('mg_name', 'singlenode', true)
minetest.set_mapgen_setting('flags', 'nolight', true)

Realm.WorldGen = {}
local heightMapGenerator = {}
local MapDecorator = {}

local c_stone = minetest.get_content_id("mapgen_stone")
local c_water = minetest.get_content_id("mapgen_water_source")
local c_air = minetest.get_content_id("air")
local c_dirt = minetest.get_content_id("default:dirt")
local c_grass = minetest.get_content_id("default:dirt_with_grass")
local c_sand = minetest.get_content_id("default:sand")

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
    local heightMapTable = heightMapGen(self.StartPos, self.EndPos, vm, area, data, seed, seaLevel)

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

Realm.WorldGen.RegisterHeightMapGenerator("v1", function(startPos, endPos, vm, area, data, seed, seaLevel)
    Debug.log("Calling heightmap generator v1")

    local mainPerlin = minetest.get_perlin(seed, 4, 0.5, 100)
    local erosionPerlin = minetest.get_perlin(seed * 2, 4, 0.5, 400)

    local heightMapTable = {}

    for posZ = startPos.z, endPos.z do
        for posY = startPos.y, endPos.y do
            for posX = startPos.x, endPos.x do
                -- vi, voxel index, is a common variable name here
                local vi = area:index(posX, posY, posZ)

                local surfaceHeight

                if (ptable.get2D(heightMapTable, { x = posX, y = posZ }) == nil) then
                    local noise = mainPerlin:get_2d({ x = posX, y = posZ })
                    local noise2 = erosionPerlin:get_2d({ x = posX, y = posZ })
                    surfaceHeight = math.ceil(seaLevel + (noise * 5) + (noise * noise2 * 20))

                    ptable.store2D(heightMapTable, { x = posX, y = posZ }, surfaceHeight)
                else
                    surfaceHeight = ptable.get2D(heightMapTable, { x = posX, y = posZ })
                end

                if (posY < surfaceHeight) then
                    data[vi] = c_stone
                elseif (posY < seaLevel) then
                    data[vi] = c_water
                else
                    data[vi] = c_air
                end
            end
        end
    end

    return heightMapTable
end)

Realm.WorldGen.RegisterHeightMapGenerator("v2", function(startPos, endPos, vm, area, data, seed, seaLevel)
    Debug.log("Calling heightmap generator v2")

    local mainPerlin = minetest.get_perlin(seed, 4, 0.5, 100)
    local erosionPerlin = minetest.get_perlin(seed * 2, 4, 0.5, 400)
    local mountainPerlin = minetest.get_perlin(seed * 3, 1, 0.5, 50)

    local heightMapTable = {}

    for posZ = startPos.z, endPos.z do
        for posY = startPos.y, endPos.y do
            for posX = startPos.x, endPos.x do
                -- vi, voxel index, is a common variable name here
                local vi = area:index(posX, posY, posZ)

                local surfaceHeight

                if (ptable.get2D(heightMapTable, { x = posX, y = posZ }) == nil) then
                    local noise = mainPerlin:get_2d({ x = posX, y = posZ })
                    local noise2 = erosionPerlin:get_2d({ x = posX, y = posZ })

                    local noise4 = mountainPerlin:get_2d({ x = posX, y = posZ })

                    local mountainNoise = 0

                    if (noise4 >= 0.5) then
                        mountainNoise = mountainNoise + (noise + noise2) * ((noise4 - 0.5) * 2)
                    end

                    if (noise2 >= 0.7) then
                        mountainNoise = mountainNoise + noise2 * ((noise2 - 0.7) * 3)
                    end

                    noise = (noise - 0.5) * 2

                    surfaceHeight = math.ceil(seaLevel + (noise * 5) + (noise * noise2 * 10)) + (mountainNoise * 10) + 5

                    ptable.store2D(heightMapTable, { x = posX, y = posZ }, surfaceHeight)
                else
                    surfaceHeight = ptable.get2D(heightMapTable, { x = posX, y = posZ })
                end

                if (posY < surfaceHeight) then
                    data[vi] = c_stone
                elseif (posY < seaLevel) then
                    data[vi] = c_water
                else
                    data[vi] = c_air
                end
            end
        end
    end

    return heightMapTable
end)

Realm.WorldGen.RegisterMapDecorator("v1", function(startPos, endPos, vm, area, data, heightMapTable, seed, seaLevel)
    Debug.log("Calling map decorator v1")

    local erosionPerlin = minetest.get_perlin(seed * 2, 4, 0.5, 400)

    for posZ = startPos.z, endPos.z do
        for posY = startPos.y, endPos.y do
            for posX = startPos.x, endPos.x do
                -- vi, voxel index, is a common variable name here
                local vi = area:index(posX, posY, posZ)
                local viAbove = area:index(posX, posY + 1, posZ)
                local viBelow = area:index(posX, posY - 1, posZ)

                if (data[vi] == c_stone) then
                    local surfaceHeight = ptable.get2D(heightMapTable, { x = posX, y = posZ })
                    if (posY > surfaceHeight - ((1 - erosionPerlin:get_2d({ x = posX, y = posZ })) * 5)) then
                        data[vi] = c_dirt
                    end

                    if (posY >= surfaceHeight - 1 and data[vi] == c_dirt) then
                        if (posY <= seaLevel) then
                            data[vi] = c_sand
                            if (data[viBelow] == c_dirt) then
                                data[viBelow] = c_sand
                            end
                        else
                            data[vi] = c_grass
                        end
                    end


                end
            end
        end
    end
end)

Realm.WorldGen.RegisterMapDecorator("biomegen", function(startPos, endPos, vm, area, data, heightMapTable, seed, seaLevel)
    Debug.log("Calling biomegen map decorator")
    biomegen.set_elevation_chill(0)
    biomegen.generate_all(data, area, vm, startPos, endPos, seed, seaLevel)
end)


