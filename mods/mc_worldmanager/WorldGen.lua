local c_stone = minetest.get_content_id("default:stone")
local c_water = minetest.get_content_id("default:water_source")
local c_air = minetest.get_content_id("air")
local c_dirt = minetest.get_content_id("default:dirt")
local c_dirtGrass = minetest.get_content_id("default:dirt_with_grass")
local c_sand = minetest.get_content_id("default:sand")

local c_grass = minetest.get_content_id("default:grass_1")
local c_rose = minetest.get_content_id("flowers:rose")

Realm.WorldGen.RegisterHeightMapGenerator("v1", function(startPos, endPos, vm, area, data, seed, realmFloorLevel, seaLevel, paramTable)
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
                    local noise = mainPerlin:get_2d({ x = posX - startPos.x, y = posZ - startPos.z })
                    local noise2 = erosionPerlin:get_2d({ x = posX - startPos.x, y = posZ - startPos.z })

                    surfaceHeight = math.ceil(realmFloorLevel + (noise * 5) + (noise * noise2 * 20) + 30)

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

Realm.WorldGen.RegisterHeightMapGenerator("v2", function(startPos, endPos, vm, area, data, seed, realmFloorLevel, seaLevel, paramTable)
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
                    local noise = mainPerlin:get_2d({ x = posX - startPos.x, y = posZ - startPos.z })
                    local noise2 = erosionPerlin:get_2d({ x = posX - startPos.x, y = posZ - startPos.z })

                    local noise4 = mountainPerlin:get_2d({ x = posX - startPos.x, y = posZ - startPos.z })

                    local mountainNoise = 0

                    if (noise4 >= 0.5) then
                        mountainNoise = mountainNoise + (noise + noise2) * ((noise4 - 0.5) * 2)
                    end

                    if (noise2 >= 0.7) then
                        mountainNoise = mountainNoise + noise2 * ((noise2 - 0.7) * 3)
                    end

                    noise = (noise - 0.5) * 2

                    surfaceHeight = math.ceil(realmFloorLevel + (noise * 5) + (noise * noise2 * 10)) + (mountainNoise * 10) + 40

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

Realm.WorldGen.RegisterMapDecorator("v1", function(startPos, endPos, vm, area, data, heightMapTable, seed, seaLevel, paramTable)
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
                            data[vi] = c_dirtGrass
                        end
                    end


                end
            end
        end
    end
end)

Realm.WorldGen.RegisterMapDecorator("v2",
        function(startPos, endPos, vm, area, data, heightMapTable, seed, seaLevel, paramTable)
            Debug.log("Calling map decorator v2")

            local erosionPerlin = minetest.get_perlin(seed * 2, 4, 0.5, 400)
            local fertilityPerlin = minetest.get_perlin(seed * 2, 1, 0.5, 25)

            for posZ = startPos.z, endPos.z do
                for posY = startPos.y, endPos.y do
                    for posX = startPos.x, endPos.x do
                        -- vi, voxel index, is a common variable name here
                        local vi = area:index(posX, posY, posZ)
                        local viAbove = area:index(posX, posY + 1, posZ)
                        local viBelow = area:index(posX, posY - 1, posZ)

                        if (data[vi] == c_stone) then

                            local erosionNoise = erosionPerlin:get_2d({ x = posX, y = posZ })
                            local fertilityNoise = fertilityPerlin:get_2d({ x = posX, y = posZ })

                            local surfaceHeight = ptable.get2D(heightMapTable, { x = posX, y = posZ })
                            if (posY > surfaceHeight - ((1 - erosionNoise) * 5)) then
                                data[vi] = c_dirt
                            end

                            if (posY >= surfaceHeight - 1 and data[vi] == c_dirt) then
                                if (posY <= seaLevel) then
                                    data[vi] = c_sand
                                    if (data[viBelow] == c_dirt) then
                                        data[viBelow] = c_sand
                                    end
                                else
                                    data[vi] = c_dirtGrass
                                    if (erosionNoise <= 0.75 and fertilityNoise >= 0.8) then
                                        data[viAbove] = c_grass
                                    end

                                    if (fertilityNoise == erosionNoise) then
                                        data[viAbove] = c_rose
                                    end

                                end
                            end
                        end
                    end
                end
            end

        end,

        function(startPos, endPos, area, data, heightMapTable, decoratorData, seed, seaLevel, paramTable)
            Debug.log("Calling map decorator v2")

            local treedef = {
                axiom = "FaF[-FFFF][+FFFF][&FFFF][^FFFF]FFFF[---FF][+++FF][&&&FF][^^^FF]FFf",
                rules_a = "FFa",
                rules_b = "",
                trunk = "default:tree",
                leaves = "default:leaves",
                angle = 30,
                iterations = 4,
                random_level = 2,
                trunk_type = "single",
                thin_branches = true,
                fruit_chance = 0,
                fruit = "default:apple"
            }

            local ps = PcgRandom(seed)

            local realmArea = (endPos.x - startPos.x) * (endPos.z - startPos.z)
            for i = 1, (realmArea / 200) do

                local treeX = ps:next(startPos.x, endPos.x)

                local treeZ = ps:next(startPos.z, endPos.z)
                local treeY = ptable.get2D(heightMapTable, { x = treeX, y = treeZ })

                if (treeY > seaLevel) then
                    local vi = area:index(treeX, treeY - 1, treeZ)
                    if (data[vi] == c_dirtGrass) then
                        local pos = { x = treeX, y = treeY, z = treeZ }
                        minetest.remove_node(pos)
                        minetest.spawn_tree(pos, treedef)
                    end
                end
            end

        end)

Realm.WorldGen.RegisterMapDecorator("biomegen", function(startPos, endPos, vm, area, data, heightMapTable, seed, seaLevel, paramTable)
    Debug.log("Calling biomegen map decorator")

    local forcedBiomeName = nil
    local elevation_chill = 0.5
    if (paramTable ~= nil) then
        if (tonumber(paramTable[1]) ~= nil) then
            elevation_chill = tonumber(paramTable[1])
            if (paramTable[2] ~= nil) then
                forcedBiomeName = tostring(paramTable[2])
            end
        elseif (paramTable[2] == nil and paramTable[1] ~= nil) then
            forcedBiomeName = paramTable[1]
        end
    end

    biomegen.set_elevation_chill(elevation_chill)
    biomegen.generate_all(data, area, vm, startPos, endPos, seed, seaLevel + 1, forcedBiomeName)
end)