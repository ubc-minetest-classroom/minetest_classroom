minetest.set_mapgen_setting('mg_name', 'singlenode', true)
minetest.set_mapgen_setting('flags', 'nolight', true)

local c_stone = minetest.get_content_id("default:stone")
local c_water = minetest.get_content_id("default:water_source")
local c_air = minetest.get_content_id("air")
local c_dirt = minetest.get_content_id("default:dirt")
local c_grass = minetest.get_content_id("default:dirt_with_grass")
local c_sand = minetest.get_content_id("default:sand")

local function getBlock(posX, posY, posZ, groundLevel, seed, mainPerlin, continentality, erosion)

    local noise = mainPerlin:get_2d({ x = posX, y = posZ })
    local noise2 = continentality:get_2d({ x = posX, y = posZ })
    local noise3 = erosion:get_2d({ x = posX, y = posZ })

    local surfaceLevel = groundLevel + (noise2 * 5) + (noise * noise3 * 20)
    local stoneLevel = surfaceLevel - (noise * noise2 * 10) - 5
    local seaLevel = groundLevel

    local node = c_air

    if (posY < stoneLevel) then
        node = c_stone
    elseif (posY < surfaceLevel) then
        node = c_dirt
    elseif (posY < seaLevel) then
        node = c_water
    else
        node = c_air
    end
    return node
end

function Realm:GenerateTerrain(seed, groundLevel)

    local perlin = minetest.get_perlin(seed, 4, 0.5, 100)
    local continentality = minetest.get_perlin(seed * 2, 4, 0.5, 100)
    local erosion = minetest.get_perlin(seed * 3, 4, 0.25, 25)

    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(self.StartPos, self.EndPos)
    local a = VoxelArea:new {
        MinEdge = emin,
        MaxEdge = emax
    }

    local data = vm:get_data()

    for z = self.StartPos.z, self.EndPos.z do
        for y = self.StartPos.y, self.EndPos.y do
            for x = self.StartPos.x, self.EndPos.x do
                -- vi, voxel index, is a common variable name here
                local vi = a:index(x, y, z)
                data[vi] = getBlock(x, y, z, groundLevel, seed, perlin, continentality, erosion)
            end
        end
    end

    for z = self.StartPos.z, self.EndPos.z do
        for y = self.StartPos.y, self.EndPos.y do
            for x = self.StartPos.x, self.EndPos.x do
                -- vi, voxel index, is a common variable name here
                local vi = a:index(x, y, z)
                local viAbove = a:index(x, y + 1, z)
                local viBelow = a:index(x, y - 1, z)


                if (data[viAbove] == c_water and data[viBelow] == c_dirt) then
                    data[viBelow] = c_sand
                    data[vi] = c_sand
                end

                if (data[viAbove] == c_air and data[vi] == c_dirt) then
                    data[vi] = c_grass
                end
            end
        end
    end

    vm:set_data(data)
    vm:write_to_map()
end