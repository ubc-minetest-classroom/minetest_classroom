minetest.set_mapgen_setting('mg_name', 'singlenode', true)
minetest.set_mapgen_setting('flags', 'nolight', true)

local c_stone = minetest.get_content_id("default:stone")
local c_water = minetest.get_content_id("default:water_source")
local c_air = minetest.get_content_id("air")

local function getBlock(posX, posY, posZ, groundLevel, seed, mainPerlin, continentality, erosion)

    local noise = mainPerlin:get_2d({ x = posX, y = posZ })
    local noise2 = continentality:get_2d({ x = posX, y = posZ })
    local noise3 = erosion:get_2d({ x = posX, y = posZ })

    local surfaceLevel = groundLevel + (noise2 * 5) + (noise * noise3 * 20)
    local seaLevel = groundLevel

    if (posY < surfaceLevel) then
        return c_stone
    elseif (posY < seaLevel) then
        return c_water
    else
        return c_air
    end
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

    vm:set_data(data)
    vm:write_to_map()
end