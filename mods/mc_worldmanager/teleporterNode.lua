minetest.register_node("mc_worldmanager:teleporter", {
    description = "Teleporter Node",
    tiles = { { name = "mc_worldmanager_teleporter.png", color = "white" } },
    overlay_tiles = { { name = "mc_worldmanager_teleporter_crystal.png" } },
    palette = "mc_worldmanager_palette.png",
    paramtype2 = "color",
    groups = { crumbly = 3, soil = 1 },

    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)

        local meta = minetest.get_meta(pos)

        local realmID = meta:get_int("realm")
        local instanced = (meta:get_string("instanced") == "true")

        local realmName = (meta:get_string("name"))
        local realmSchematic = (meta:get_string("schematic"))

        if (realmSchematic == "") then
            realmSchematic = nil
        end

        -- Special case so that we can have teleporters that always point towards spawn.
        if (realmID == 0 and realmName == "spawn" and not instanced) then
            local spawn = mc_worldManager.GetSpawnRealm()
            spawn:TeleportPlayer(clicker)
            return
        end

        if (realmID == 0 and not instanced) then
            minetest.chat_send_player(clicker:get_player_name(), "This teleporter is not linked to a realm. Linking to this realm...")
            realmID = Realm.GetRealmFromPlayer(clicker).ID

            meta:set_int("realm", realmID)

            meta:set_string("instanced", "false")

            minetest.swap_node(pos, { name = "mc_worldmanager:teleporter", param2 = math.ceil(math.sin(realmID) * 255) })

            return nil
        end

        if (instanced) then
            local realmObject = mc_worldManager.GetCreateInstancedRealm(realmName, clicker, realmSchematic)

            realmObject:TeleportPlayer(clicker)

        else
            local realmObject = Realm.GetRealm(realmID)

            if (realmObject == nil) then
                return nil
            end

            realmObject:TeleportPlayer(clicker)
        end

        return nil
    end,
    preserve_metadata = function(pos, oldnode, oldmeta, drops)

        local meta = drops[1]:get_meta()

        local realmID = oldmeta["realm"]
        local instanced = oldmeta["instanced"]
        local name = oldmeta["name"]
        local schematic = oldmeta["schematic"]

        meta:set_int('realm', realmID)
        meta:set_string("instanced", instanced)
        meta:set_string("name", name)
        meta:set_string("schematic", schematic)

        if (instanced == "true") then
            meta:set_string("description", "A teleporter linked to the realm " .. name .. ".")
        elseif (realmID ~= 0 and realmID ~= "") then
            meta:set_string("description", "A teleporter linked to the realm " .. Realm.GetRealm(realmID).Name .. ".")
        else
            meta:set_string("description", "A teleporter not linked to any realm.")
        end
    end,

    after_place_node = function(pos, placer, itemstack, pointed_thing)
        Debug.log("after_Place_node")

        local itemMeta = itemstack:get_meta()
        local nodeMeta = minetest.get_meta(pos)

        local realmID = itemMeta:get_int("realm")
        local instanced = itemMeta:get_string("instanced")
        local name = itemMeta:get_string("name")
        local schematic = itemMeta:get_string("schematic")

        nodeMeta:set_int('realm', realmID)
        nodeMeta:set_string("instanced", instanced)
        nodeMeta:set_string("name", name)
        nodeMeta:set_string("schematic", schematic)

        minetest.swap_node(pos, { name = "mc_worldmanager:teleporter", param2 = math.ceil(math.sin(realmID) * 255) })
    end
})

function mc_worldManager.GetTeleporterItemStack(count, instanced, realmID, name, schematic)
    local item = ItemStack({ name = "mc_worldmanager:teleporter", count = count })
    local itemMeta = item:get_meta()

    if (realmID == nil) then
        realmID = 0
    end

    if (name == nil) then
        name = "Unnamed Realm"
    end

    if (instanced) then
        itemMeta:set_string("instanced", "true")
        itemMeta:set_string("name", name)
        itemMeta:set_string("schematic", schematic)
        itemMeta:set_string("description", "A teleporter linked to an instanced realm.")
    else
        itemMeta:set_string("instanced", "false")
        itemMeta:set_int("realm", realmID)
        itemMeta:set_string("description", "A teleporter linked to the realm " .. Realm.GetRealm(realmID).Name .. ".")
    end

    return item
end