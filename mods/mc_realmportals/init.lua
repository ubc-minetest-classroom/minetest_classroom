-- RealmIDTable stores the name of portal realms as a key, and the ID of the associated realm as the value.

mc_realmportals = { RealmIDTable = {} }

function mc_realmportals.newPortal(realmName, playerInstanced)
    playerInstanced = playerInstanced or false

    local portalColor = mc_realmportals.stringToColor(realmName)

    minetest.register_node("mc_realmportals:" .. realmName .. "stone", {
        description = realmName .. " Portal Stone",
        tiles = { "portalFrame.png" },
        color = portalColor,
        groups = { stone = 1 },
        is_ground_content = true
    })

    portals.register_wormhole_node("mc_realmportals:" .. realmName .. "portal", {
        description = ("Portal"),
        color = portalColor,
        post_effect_color = portalColor
    })

    portals.register_portal(realmName .. "_portal", {
        shape = portals.PortalShape_Traditional,
        frame_node_name = "mc_realmportals:" .. realmName .. "stone",
        wormhole_node_name = "mc_realmportals:" .. realmName .. "portal",
        wormhole_node_color = 7, -- 4 is cyan


        title = (realmName .. " Portal"),

        is_within_realm = function(pos, definition)


            local realm = mc_realmportals.CreateGetRealm(realmName)
            -- We can also solve this using a dot product, but that would increase CPU cycles.
            -- Although this solution is not as pretty, it only uses ~6 cycles (assuming 1 cycle per comparison).
            -- A dot-product would use ~36 cycles (10 per multiplication + comparisons).
            if (pos.x < realm.StartPos.x or pos.x > realm.EndPos.x) then
                return false
            elseif (pos.z < realm.StartPos.z or pos.z > realm.EndPos.z) then
                return false
            elseif (pos.y < realm.StartPos.y or pos.y > realm.EndPos.y) then
                return false
            else
                return true
            end
        end,

        find_realm_anchorPos = function(surface_anchorPos, player_name)
            -- When finding our way to a realm, we use this function

            minetest.log("error", "find_realm_anchorPos called for surface portal")
            local realm = mc_realmportals.CreateGetRealm(realmName)

            local pos = realm.SpawnPoint
            pos.y = pos.y - 1

            return pos
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

    function mc_realmportals.CreateGetRealm(realmName)
        local realmID = mc_realmportals.RealmIDTable[realmName]

        if (realmID == nil) then
            return mc_realmportals.CreateRalmByName(realmName)
        end

        local realm = Realm.realmDict[realmID]

        if (realm == nil) then
            return mc_realmportals.CreateRalmByName(realmName)
        end

        return realm
    end

    function mc_realmportals.CreateRalmByName(realmName)
        local realm = Realm:New(realmName, 80, 80)
        realm:CreateGround("stone")
        realm:CreateBarriers()
        mc_realmportals.RealmIDTable[realmName] = realm.ID
        return realm
    end
end

function mc_realmportals.stringToColor(name)
    local seed = 0
    for c in name:gmatch(".") do
        seed = seed + string.byte(c)
    end

    math.randomseed(seed)

    local alpha = 255
    local red = math.random(255)
    local green = math.random(255)
    local blue = math.random(255)

    return { a = alpha, r = red, g = green, b = blue }
end

-- Defining all our portal realms

mc_realmportals.newPortal("testRealm", false)
mc_realmportals.newPortal("lukieRealm", false)
mc_realmportals.newPortal("realm1024", false)
mc_realmportals.newPortal("123", false)
mc_realmportals.newPortal("456", false)

