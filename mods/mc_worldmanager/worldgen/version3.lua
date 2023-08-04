Realm.WorldGen.RegisterHeightMapGenerator("v2", function(startPos, endPos, vm, area, data, seed, realmFloorLevel, seaLevel, paramTable)
    Debug.log("Calling heightmap generator v2")

    local mainPerlin = minetest.get_perlin(seed, 4, 0.5, 100)
    local erosionPerlin = minetest.get_perlin(seed * 2, 4, 0.5, 400)
    local mountainPerlin = minetest.get_perlin(seed * 3, 1, 0.5, 50)
    local ravinePerlin = minetest.get_perlin(seed * 4, 2, 0.5, 200)

    local heightMapTable = {}

    for posZ = startPos.z, endPos.z do
        for posY = startPos.y, endPos.y do
            for posX = startPos.x, endPos.x do
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

                    -- Ravines
                    local ravineNoise = ravinePerlin:get_2d({ x = posX, y = posZ })
                    if ravineNoise < 0.3 then
                        surfaceHeight = surfaceHeight - ravineNoise * 30
                    end

                    -- Slope-based Erosion
                    local leftHeight = ptable.get2D(heightMapTable, { x = posX - 1, y = posZ }) or surfaceHeight
                    local rightHeight = ptable.get2D(heightMapTable, { x = posX + 1, y = posZ }) or surfaceHeight
                    local frontHeight = ptable.get2D(heightMapTable, { x = posX, y = posZ - 1 }) or surfaceHeight
                    local backHeight = ptable.get2D(heightMapTable, { x = posX, y = posZ + 1 }) or surfaceHeight
                    local slope = math.max(math.abs(surfaceHeight - leftHeight), math.abs(surfaceHeight - rightHeight), math.abs(surfaceHeight - frontHeight), math.abs(surfaceHeight - backHeight))
                    surfaceHeight = surfaceHeight - slope * 0.2 -- Eroding the terrain based on slope

                    ptable.store2D(heightMapTable, { x = posX, y = posZ }, surfaceHeight)
                else
                    surfaceHeight = ptable.get2D(heightMapTable, { x = posX, y = posZ })
                end

                if posY <= surfaceHeight then
                    data[vi] = c_stone
                elseif posY < seaLevel then
                    data[vi] = c_water
                else
                    data[vi] = c_air
                end
            end
        end
    end

    return heightMapTable
end)




Realm.WorldGen.RegisterMapDecorator("v3", function(startPos, endPos, vm, area, data, heightMapTable, seed, seaLevel, paramTable)
    Debug.log("Calling map decorator v3")

    local erosionPerlin = minetest.get_perlin(seed * 2, 4, 0.5, 400)
    local fertilityPerlin = minetest.get_perlin(seed * 2, 1, 0.5, 25)

    for posZ = startPos.z, endPos.z do
        for posY = startPos.y, endPos.y do
            for posX = startPos.x, endPos.x do
                local vi = area:index(posX, posY, posZ)
                local viAbove = area:index(posX, posY + 1, posZ)
                local viBelow = area:index(posX, posY - 1, posZ)

                if data[vi] == c_stone then
                    local erosionNoise = erosionPerlin:get_2d({ x = posX, y = posZ })
                    local fertilityNoise = fertilityPerlin:get_2d({ x = posX, y = posZ })

                    local surfaceHeight = ptable.get2D(heightMapTable, { x = posX, y = posZ })

                    -- Slope-based Erosion
                    local leftHeight = ptable.get2D(heightMapTable, { x = posX - 1, y = posZ }) or surfaceHeight
                    local rightHeight = ptable.get2D(heightMapTable, { x = posX + 1, y = posZ }) or surfaceHeight
                    local frontHeight = ptable.get2D(heightMapTable, { x = posX, y = posZ - 1 }) or surfaceHeight
                    local backHeight = ptable.get2D(heightMapTable, { x = posX, y = posZ + 1 }) or surfaceHeight
                    local slope = math.max(math.abs(surfaceHeight - leftHeight), math.abs(surfaceHeight - rightHeight), math.abs(surfaceHeight - frontHeight), math.abs(surfaceHeight - backHeight))

                    if slope > 5 then -- Threshold for slope-based erosion
                        surfaceHeight = surfaceHeight - slope * 0.2 -- Eroding the terrain based on slope
                        ptable.store2D(heightMapTable, { x = posX, y = posZ }, surfaceHeight)
                    end

                    if posY >= surfaceHeight - ((1 - erosionNoise) * 5) then
                        data[vi] = c_dirt
                    end

                    if posY == surfaceHeight then
                        if posY <= seaLevel then
                            data[vi] = c_sand
                            if data[viBelow] == c_dirt then
                                data[viBelow] = c_sand
                            end
                        else
                            data[vi] = c_dirtGrass
                            if erosionNoise <= 0.75 and fertilityNoise >= 0.8 then
                                data[viAbove] = c_grass
                            end

                            if fertilityNoise == erosionNoise then
                                data[viAbove] = c_rose
                            end
                        end
                    end
                end
            end
        end
    end
end)

