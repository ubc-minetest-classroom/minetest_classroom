-- This file creates functionality which lets us create new realms associated with portals.
-- We will eventually hook this up with a config file and tutorial schematics.
-- Portal frame blocks are dynamically created and colored based on realm name.

function mc_realmportals.newPortal(modName, realmName, playerInstanced, schematic)
    playerInstanced = playerInstanced or false
    schematic = schematic or nil

    local portalColor = mc_helpers.stringToColor(realmName)

    minetest.register_node(modName .. ":" .. realmName .. "stone", {
        description = realmName .. " Portal Stone",
        tiles = { "portalFrame.png" },
        color = portalColor,
        groups = { stone = 1, portalstone = 1 },
        is_ground_content = true
    })

    portals.register_wormhole_node(modName .. ":" .. realmName .. "portal", {
        description = ("Portal"),
        color = portalColor,
        post_effect_color = { a = 50, r = portalColor.r, g = portalColor.g, b = portalColor.b }
    })

    portals.register_portal(realmName .. "_portal", {
        shape = portals.PortalShape_Traditional,
        frame_node_name = modName .. ":" .. realmName .. "stone",
        wormhole_node_name = modName .. ":" .. realmName .. "portal",
        wormhole_node_color = 7, -- 4 is cyan


        title = (realmName .. " Portal"),

        is_within_realm = function(pos, definition)

            -- We check if we're in the spawn realm, if not, we are in a realm.
            local realm = mc_worldManager.GetSpawnRealm()

            if (pos.x > realm.StartPos.x or pos.x < realm.EndPos.x) then
                return false
            elseif (pos.z > realm.StartPos.z or pos.z < realm.EndPos.z) then
                return false
            elseif (pos.y > realm.StartPos.y or pos.y < realm.EndPos.y) then
                return false
            else
                return true
            end
        end,

        find_realm_anchorPos = function(surface_anchorPos, player_name)
            -- When finding our way to a realm, we use this function


            local instanceRealmName = realmName

            if (playerInstanced) then
                instanceRealmName = instanceRealmName .. " instanced for " .. player_name
            end

            local realm = mc_realmportals.CreateGetRealm(instanceRealmName, schematic)
            local player = minetest.get_player_by_name(player_name)

            realm:UpdatePlayerMetaData(player)

            local pos = realm.SpawnPoint
            pos.y = pos.y - 1

            return pos
        end,

        find_surface_anchorPos = function(realm_anchorPos, player_name)
            -- when finding our way back to spawn, we use this function
            local spawnRealm = mc_worldManager.GetSpawnRealm()
            local player = minetest.get_player_by_name(player_name)
            spawnRealm:UpdatePlayerMetaData(player)

            local pos = spawnRealm.SpawnPoint
            pos.y = pos.y - 1

            return pos
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

    function mc_realmportals.CreateGetRealm(realmName, schematic)
        local realmID = mc_realmportals.RealmIDTable[realmName]

        if (realmID == nil) then
            return mc_realmportals.CreateRealmByName(realmName, schematic)
        end

        local realm = Realm.realmDict[realmID]

        if (realm == nil) then
            return mc_realmportals.CreateRealmByName(realmName, schematic)
        end

        return realm
    end

    function mc_realmportals.CreateRealmByName(realmName, schematic)
        local realm = Realm:New(realmName, 80, 80)

        if (schematic == nil) then
            realm:CreateGround("stone")
        else
            realm:Load_Schematic(schematic)
        end

        realm:CreateBarriers()

        mc_realmportals.RealmIDTable[realmName] = realm.ID
        mc_realmportals.SaveDataToStorage()
        return realm
    end
end