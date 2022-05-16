-- SECTIONS BORROWED FROM:
-- https://github.com/minetest-mods/nether/blob/master/portal_api.lua

local S
if minetest.get_translator ~= nil then
    S = minetest.get_translator("portals")
else
    -- mock the translator function for MT 0.4
    S = function(str, ...)
        local args = { ... }
        return str:gsub(
                "@%d+",
                function(match)
                    return args[tonumber(match:sub(2))]
                end
        )
    end
end

portals = {}
portals.modname = minetest.get_current_modname()
portals.path = minetest.get_modpath(portals.modname)
portals.get_translator = S

-- Load files
dofile(portals.path .. "/portals_api.lua")

minetest.register_node("portals:portalstone", {
    description = "Portal Stone",
    tiles = { "portals_portalstone.png" },
    groups = { choppy = 3, stone = 1 },
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
    inventory_image = "portalWand.png",
    tool_capabilities = {
        groupcaps = {
            choppy = {
                maxlevel = 4,
                uses = 0,
                times = { [1] = 1.60, [2] = 1.20, [3] = 0.80 }
            },
        },
    },
})

minetest.register_alias("portalwand", "portals:portalwand")
portalwand = minetest.registered_aliases[portalwand] or portalwand

-- Portals are ignited by right-clicking with a portalwand
portals.register_portal_ignition_item("portals:portalwand")

portals.register_portal("surface_portal", {
    shape = portals.PortalShape_Traditional,
    frame_node_name = "portals:portalstone",
    wormhole_node_color = 4, -- 4 is cyan
    title = S("Surface Portal"),

    is_within_realm = function(pos)
        -- return true if pos is inside the realm, TODO: integrate with realms system
        return true
    end,

    find_realm_anchorPos = function(surface_anchorPos, player_name)
        -- When finding our way to a realm, we use this function

        local portalRealm = Realm:New("test realm", 80, 80)
        portalRealm:CreateGround()

        minetest.log("error", "find_realm_anchorPos called for surface portal")
        return portalRealm.SpawnPoint
    end,

    find_surface_anchorPos = function(realm_anchorPos, player_name)
        -- when finding our way back to spawn, we use this function
        return mc_worldManager.GetSpawnRealm().SpawnPoint
    end,

    on_ignite = function(portalDef, anchorPos, orientation)

        local p1, p2 = portalDef.shape:get_p1_and_p2_from_anchorPos(anchorPos, orientation)
        local pos = vector.divide(vector.add(p1, p2), 2)

        local textureName = portalDef.particle_texture
        if type(textureName) == "table" then
            textureName = textureName.name
        end

        minetest.add_particlespawner({
            amount = 110,
            time = 0.1,
            minpos = { x = pos.x - 0.5, y = pos.y - 1.2, z = pos.z - 0.5 },
            maxpos = { x = pos.x + 0.5, y = pos.y + 1.2, z = pos.z + 0.5 },
            minvel = { x = -5, y = -1, z = -5 },
            maxvel = { x = 5, y = 1, z = 5 },
            minacc = { x = 0, y = 0, z = 0 },
            maxacc = { x = 0, y = 0, z = 0 },
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






