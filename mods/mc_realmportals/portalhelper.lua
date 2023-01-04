-- This file creates functionality which lets us create new realms associated with portals.
-- We will eventually hook this up with a config file and tutorial schematics.
-- Portal frame blocks are dynamically created and colored based on realm name.

function mc_realmportals.newPortal(modName, realmName, playerInstanced, schematic)
    playerInstanced = playerInstanced or false
    schematic = schematic or nil

    local portalColor = mc_core.stringToColor(realmName)

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
            local spawnRealm = mc_worldManager.GetSpawnRealm()

            local inRealm = false

            -- We assume and test that we're in spawn.
            -- If we're in any position that indicates otherwise, we know that we're in a realm
            if (pos.x < spawnRealm.StartPos.x or pos.x > spawnRealm.EndPos.x) then
                inRealm = true
            elseif (pos.z < spawnRealm.StartPos.z or pos.z > spawnRealm.EndPos.z) then
                inRealm = true
            elseif (pos.y < spawnRealm.StartPos.y or pos.y > spawnRealm.EndPos.y) then
                inRealm = true
            else
                inRealm = false
            end
            return inRealm
        end,

        find_realm_anchorPos = function(surface_anchorPos, player_name)
            -- When finding our way to a realm, we use this function


            local instanceRealmName = realmName

            if (playerInstanced) then
                instanceRealmName = instanceRealmName .. " instanced for " .. player_name
            end

            local realm = mc_realmportals.CreateGetRealm(instanceRealmName, schematic)
            local player = minetest.get_player_by_name(player_name)

            local pos = realm.SpawnPoint
            pos.y = pos.y - 1

            return pos
        end,

        find_surface_anchorPos = function(realm_anchorPos, player_name)
            -- when finding our way back to spawn, we use this function
            local spawnRealm = mc_worldManager.GetSpawnRealm()
            local player = minetest.get_player_by_name(player_name)

            local pos = spawnRealm.SpawnPoint
            pos.y = pos.y - 1

            return pos
        end,

        on_player_teleported = function(portalDef, player, oldPos, newPos)
            local spawnRealm = mc_worldManager.GetSpawnRealm()

            local isWithinRealm = portalDef.is_within_realm(newPos, portalDef)

            --Since we're not running the methods that our own teleport methods normally run,
            --we're calling them here. They run immediately after players teleport via portal
            if (isWithinRealm ~= true) then
                minetest.debug("Entering Spawn")
                -- Since we're entering spawn, we already have all the references we need and this is easy.
                local newRealmID, OldRealmID = spawnRealm:UpdatePlayerMetaData(player)
                spawnRealm:RunTeleportInFunctions(player)

                local oldRealm = Realm.realmDict[OldRealmID]
                oldRealm:RunTeleportOutFunctions(player)
            else
                minetest.debug("Leaving Spawn")

                --Firstly, we figure out where the player is teleporting to. This mirrors the portal pathfinding logic.
                local instanceRealmName = realmName
                local player_name = player:get_player_name()
                if (playerInstanced) then
                    instanceRealmName = instanceRealmName .. " instanced for " .. player_name
                end
                local realm = mc_realmportals.CreateGetRealm(instanceRealmName, schematic)

                -- Next we tell the realm that the player is teleporting to, to update their metainfo
                -- In the process, we get the OldRealmID for the realm that the player is teleporting from.
                -- Usually this should be the spawn realm, but we have no idea; so it's good not to assume
                local newRealmID, OldRealmID = realm:UpdatePlayerMetaData(player)
                realm:RunTeleportInFunctions(player)

                -- We get the instance for the old realm by its ID
                local oldRealm = Realm.realmDict[OldRealmID]

                -- We run the teleportOut functions (e.g., the callbacks for that realm)
                oldRealm:RunTeleportOutFunctions(player)
            end
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

    --TODO: Move to MC_WorldManager
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

    --TODO: Move to MC_WorldManager
    function mc_realmportals.CreateRealmByName(realmName, schematic)
        local realm
        if (schematic == nil) then
            realm = Realm:New(realmName, { x = 80, y = 80, z = 80 })
            realm:CreateGround("stone")
            realm:CreateBarriers()
        else
            realm = Realm:NewFromSchematic(realmName, schematic)
        end

        mc_realmportals.RealmIDTable[realmName] = realm.ID
        mc_realmportals.SaveDataToStorage()
        return realm
    end
end