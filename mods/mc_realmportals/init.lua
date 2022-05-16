mc_realmportals = {}

function mc_realmportals.newPortal(realmName, playerInstanced)
    playerInstanced = playerInstanced or false


    local realm = mc_realmportals.realms[realmName]
    if (realm == nil) then
        realm = Realm:New(realmName, 80, 80)
        mc_realmportals.realms[realmName] = realm
    end

    local portalColor = stringToColor(realmName)

    minetest.register_node("mc_realmportals:" .. realmName .. "stone", {
        description = realmName .. " Portal Stone",
        tiles = { "portalFrame.png" },
        color = portalColor,
        groups = { stone = 1 },
        is_ground_content = true
    })

    portals.register_wormhole_node("mc_realmportals:" .. realmName .. "portal", {
        description = S("Portal"),
        post_effect_color = portalColor
    })

    minetest.register_tool("mc_realmportals:" .. realmName .. "portalwand", {
        description = realmName .. "Portal Wand",
        inventory_image = "portals_portalwand.png",
        color = portalColor,
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

    portals.register_portal_ignition_item("mc_realmportals:" .. realmName .. "portalwand")

    portals.register_portal(realmName .. "_portal", {
        shape = portals.PortalShape_Traditional,
        frame_node_name = "mc_realmportals:" .. realmName .. "stone",
        wormhole_node_color = 4, -- 4 is cyan
        title = S("Surface Portal"),

        is_within_realm = function(pos)
            -- return true if pos is inside the realm, TODO: integrate with realms system
            return true
        end,

        find_realm_anchorPos = function(surface_anchorPos, player_name)
            -- When finding our way to a realm, we use this function

            minetest.log("error", "find_realm_anchorPos called for surface portal")
            return realm.SpawnPoint
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


end

local encoding = { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "x", "y", "z" }
local reverse_encoding = table_invert(encoding)

function stringToColor(name)
    local seed = 0
    for c in name:gmatch(".") do
        seed = seed + reverse_encoding[c]
    end

    math.randomseed(seed)

    local alpha = math.random(255)
    local red = math.random(255)
    local green = math.random(255)
    local blue = math.random(255)

    return { a = alpha, r = red, g = green, b = blue }
end

function table_invert(t)
    local s = {}
    for k, v in ipairs(t) do
        s[v] = k
    end
    return s
end