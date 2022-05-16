-- SECTIONS BORROWED FROM:
-- https://github.com/minetest-mods/nether/blob/master/portal_api.lua

local S
if minetest.get_translator ~= nil then
	S = minetest.get_translator("portals")
else
	-- mock the translator function for MT 0.4
	S = function(str, ...)
		local args={...}
		return str:gsub(
			"@%d+",
			function(match) return args[tonumber(match:sub(2))]	end
		)
	end
end

portals                = {}
portals.modname        = minetest.get_current_modname()
portals.path           = minetest.get_modpath(portals.modname)
portals.get_translator = S

-- Load files
dofile(portals.path .. "/portals_api.lua")

minetest.register_node("portals:portalstone", {
    description = "Portal Stone",
    tiles = {"portals_portalstone.png"},
    groups = {choppy = 3, stone = 1},
    is_ground_content = true
})

portals.register_wormhole_node("portals:portal", {
	description = S("Portal"),
	post_effect_color = {
		-- hopefully blue enough to work with blue portals, and green enough to
		-- work with cyan portals.
		a = 120, r = 0, g = 128, b = 188
	}
})

minetest.register_alias("portalstone", "portals:portalstone")
portalstone = minetest.registered_aliases[portalstone] or portalstone

minetest.register_tool("portals:portalwand", {
    description = "Portal Wand",
    inventory_image = "portals_portalwand.png",
    tool_capabilities = {
        groupcaps = {
            choppy = {
                maxlevel = 4,
                uses = 0,
                times = { [1]=1.60, [2]=1.20, [3]=0.80 }
            },
        },
    },
})

minetest.register_alias("portalwand", "portals:portalwand")
portalwand = minetest.registered_aliases[portalwand] or portalwand

-- Portals are ignited by right-clicking with a portalwand
portals.register_portal_ignition_item("portals:portalwand")

local SURFACE_TRAVEL_DISTANCE = 26

portals.register_portal("surface_portal", {
    shape               = portals.PortalShape_Traditional,
    frame_node_name     = "portals:portalstone",
    wormhole_node_color = 4, -- 4 is cyan
    title = S("Surface Portal"),

    is_within_realm = function(pos) -- return true if pos is inside the realm, TODO: integrate with realms system
        return true
    end,

    find_realm_anchorPos = function(surface_anchorPos, player_name)
        minetest.log("error" , "find_realm_anchorPos called for surface portal")
		return {x=0, y=0, z=0}
    end,

    find_surface_anchorPos = function(realm_anchorPos, player_name)
        -- A portal definition doesn't normally need to provide a find_surface_anchorPos() function,
        -- since find_surface_target_y() will be used by default, but these portals travel around the
        -- surface (following a Moore curve) so will be calculating a different x and z to realm_anchorPos.

        local cellCount = 512
        local maxDistFromOrigin = 30000 -- the world edges are at X=30927, X=−30912, Z=30927 and Z=−30912

        -- clip realm_anchorPos to maxDistFromOrigin, and move the origin so that all values are positive
        local x = math.min(maxDistFromOrigin, math.max(-maxDistFromOrigin, realm_anchorPos.x)) + maxDistFromOrigin
        local z = math.min(maxDistFromOrigin, math.max(-maxDistFromOrigin, realm_anchorPos.z)) + maxDistFromOrigin

        local divisor = math.ceil(maxDistFromOrigin * 2 / cellCount)
        local distance = get_moore_distance(cellCount, math.floor(x / divisor + 0.5), math.floor(z / divisor + 0.5))
        local destination_distance = (distance + SURFACE_TRAVEL_DISTANCE) % (cellCount * cellCount)
        local moore_pos = get_moore_coords(cellCount, destination_distance)
        local target_x = moore_pos.x * divisor - maxDistFromOrigin
        local target_z = moore_pos.y * divisor - maxDistFromOrigin

        local search_radius = divisor / 2 - 5 -- any portal within this area will do

        -- a y_factor of 0 makes the search ignore the altitude of the portals
        local existing_portal_location, existing_portal_orientation =
            portals.find_nearest_working_portal("surface_portal", {x = target_x, y = 0, z = target_z}, search_radius, 0)

        if existing_portal_location ~= nil then
            -- use the existing portal that was found near target_x, target_z
            return existing_portal_location, existing_portal_orientation
        else
            -- find a good location for the new portal, or if that isn't possible then at
            -- least adjust the coords a little so portals don't line up in a grid
            local adj_x, adj_z = 0, 0

            -- Deterministically look for a location in the cell where get_spawn_level() can give
            -- us a surface height, since nether.find_surface_target_y() works *much* better when
            -- it can use get_spawn_level()
            local prng = PcgRandom( -- seed the prng so that all portals for these Moore Curve coords will use the same random location
                moore_pos.x * 65732 +
                moore_pos.y * 729   +
                minetest.get_mapgen_setting("seed") * 3
            )

            local attemptLimit = 15 -- how many attempts we'll make at finding a good location
            for attempt = 1, attemptLimit do
                adj_x = math.floor(prng:rand_normal_dist(-search_radius, search_radius, 2) + 0.5)
                adj_z = math.floor(prng:rand_normal_dist(-search_radius, search_radius, 2) + 0.5)
                if minetest.get_spawn_level == nil or minetest.get_spawn_level(target_x + adj_x, target_z + adj_z)	~= nil then
                    -- Found a location which will be at ground level - unless a player has built there.
                    -- Or this is MT 0.4 which does not have get_spawn_level(), so there's no point looking
                    -- at any further further random locations.
                    break
                end
            end

            local destination_pos = {x = target_x + adj_x, y = 0, z = target_z + adj_z}
            destination_pos.y = portals.find_surface_target_y(destination_pos.x, destination_pos.z, "surface_portal", player_name)

            return destination_pos
        end
    end,

    on_ignite = function(portalDef, anchorPos, orientation)

        local p1, p2 = portalDef.shape:get_p1_and_p2_from_anchorPos(anchorPos, orientation)
        local pos = vector.divide(vector.add(p1, p2), 2)

        local textureName = portalDef.particle_texture
        if type(textureName) == "table" then textureName = textureName.name end

        minetest.add_particlespawner({
            amount = 110,
            time   = 0.1,
            minpos = {x = pos.x - 0.5, y = pos.y - 1.2, z = pos.z - 0.5},
            maxpos = {x = pos.x + 0.5, y = pos.y + 1.2, z = pos.z + 0.5},
            minvel = {x = -5, y = -1, z = -5},
            maxvel = {x =  5, y =  1, z =  5},
            minacc = {x =  0, y =  0, z =  0},
            maxacc = {x =  0, y =  0, z =  0},
            minexptime = 0.1,
            maxexptime = 0.5,
            minsize = 0.2 * portalDef.particle_texture_scale,
            maxsize = 0.8 * portalDef.particle_texture_scale,
            collisiondetection = false,
            texture = textureName .. "^[colorize:#F4F:alpha",
            animation = portalDef.particle_texture_animation,
            glow = 8
        })

    end
})



--=========================================--
-- Hilbert curve and Moore curve functions --
--=========================================--

-- These are space-filling curves, used by the surface_portal example as a way to determine where
-- to place portals. https://en.wikipedia.org/wiki/Moore_curve


-- Flip a quadrant on a diagonal axis
-- cell_count is the number of cells across the square is split into, and must be a power of 2
-- if flip_twice is true then pos does not change (even numbers of flips cancel out)
-- if flip_direction is true then the position is flipped along the \ diagonal
-- if flip_direction is false then the position is flipped along the / diagonal
local function hilbert_flip(cell_count, pos, flip_direction, flip_twice)
	if not flip_twice then
		if flip_direction then
			pos.x = (cell_count - 1) - pos.x;
			pos.y = (cell_count - 1) - pos.y;
		end

		local temp_x = pos.x;
		pos.x = pos.y;
		pos.y = temp_x;
	end
end

local function test_bit(cell_count, value, flag)
	local bit_value = cell_count / 2
	while bit_value > flag and bit_value >= 1  do
		if value >= bit_value then value = value - bit_value end
		bit_value = bit_value / 2
	end
	return value >= bit_value
end

-- Converts (x,y) to distance
-- starts at bottom left corner, i.e. (0, 0)
-- ends at bottom right corner, i.e. (cell_count - 1, 0)
local function get_hilbert_distance (cell_count, x, y)
	local distance = 0
	local pos = {x=x, y=y}
	local rx, ry

	local s = cell_count / 2
	while s > 0 do

		if test_bit(cell_count, pos.x, s) then rx = 1 else rx = 0 end
		if test_bit(cell_count, pos.y, s) then ry = 1 else ry = 0 end

		local rx_XOR_ry = rx
		if ry == 1 then rx_XOR_ry = 1 - rx_XOR_ry end -- XOR'd ry against rx

		distance = distance + s * s * (2 * rx + rx_XOR_ry)
		hilbert_flip(cell_count, pos, rx > 0, ry > 0);

		s = math.floor(s / 2)
	end
	return distance;
end

-- Converts distance to (x,y)
local function get_hilbert_coords(cell_count, distance)
	local pos = {x=0, y=0}
	local rx, ry

	local s = 1
	while s < cell_count do
		rx = math.floor(distance / 2) % 2
		ry = distance % 2
		if rx == 1 then ry = 1 - ry end -- XOR ry with rx

		hilbert_flip(s, pos, rx > 0, ry > 0);
		pos.x = pos.x + s * rx
		pos.y = pos.y + s * ry
		distance = math.floor(distance / 4)

		s = s * 2
	end
	return pos
end


-- Converts (x,y) to distance
-- A Moore curve is a variation of the Hilbert curve that has the start and
-- end next to each other.
-- Top middle point is the start/end location
get_moore_distance = function(cell_count, x, y)

	local quadLength = cell_count / 2
	local quadrant = 1 - math.floor(y / quadLength)
	if math.floor(x / quadLength) == 1 then quadrant = 3 - quadrant end
	local flipDirection = x < quadLength

	local pos = {x = x % quadLength, y = y % quadLength}
	hilbert_flip(quadLength, pos, flipDirection, false)

	return (quadrant * quadLength * quadLength) + get_hilbert_distance(quadLength, pos.x, pos.y)
end


-- Converts distance to (x,y)
-- A Moore curve is a variation of the Hilbert curve that has the start and
-- end next to each other.
-- Top middle point is the start/end location
get_moore_coords = function(cell_count, distance)
	local quadLength = cell_count / 2
	local quadDistance = quadLength * quadLength
	local quadrant = math.floor(distance / quadDistance)
	local flipDirection = distance * 2 < cell_count * cell_count
	local pos = get_hilbert_coords(quadLength, distance % quadDistance)
	hilbert_flip(quadLength, pos, flipDirection, false)

	if quadrant >= 2     then pos.x = pos.x + quadLength end
	if quadrant % 3 == 0 then pos.y = pos.y + quadLength end

	return pos
end






