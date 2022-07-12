local function getDescription(instanced, temp, realmID, name, schematic)
    local descriptionString = "Teleporter Node "

    if (instanced == "true") then
        descriptionString = descriptionString .. "[Instanced] "
    end

    if (temp == "true") then
        descriptionString = descriptionString .. "[Temp] "
    end

    if (schematic ~= nil and schematic ~= "") then
        descriptionString = descriptionString .. "[" .. schematic .. "]"
    end

    if (instanced ~= "true" and realmID == 0) then
        descriptionString = descriptionString .. "(Spawn)"
    elseif (name ~= nil and name ~= "") then
        descriptionString = descriptionString .. "(" .. name .. ")"
    else
        local realm = Realm.GetRealm(tonumber(realmID))
        local realmName = "unknown"
        if (realm ~= nil) then
            realmName = realm.Name
        end
        descriptionString = descriptionString .. "(" .. realmName .. ")"
    end

    return descriptionString
end

minetest.register_node("mc_worldmanager:teleporter", {
    description = "Teleporter Node (Spawn)",
    tiles = { { name = "mc_worldmanager_teleporter.png", color = "white" } },
    overlay_tiles = { { name = "mc_worldmanager_teleporter_crystal.png" } },
    palette = "mc_worldmanager_palette.png",
    paramtype2 = "color",
    groups = { crumbly = 3, soil = 1 },

    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)

        local meta = minetest.get_meta(pos)

        local instanced = (meta:get_string("instanced"))

        local realmID = meta:get_int("realm")

        local temp = (meta:get_string("temp") == "true")

        local realmName = (meta:get_string("name"))
        local realmSchematic = (meta:get_string("schematic"))

        if (realmSchematic == "") then
            realmSchematic = nil
        end

        Debug.log(tostring(realmID) .. " " .. tostring(instanced) .. " " .. tostring(temp) .. " " .. tostring(realmName) .. " " .. tostring(realmSchematic))


        -- If our realmID is set to 0 and we're not instanced, teleport to spawn!
        if (instanced ~= "true" and realmID == 0) then
            Debug.log("Teleporting to spawn")
            local spawn = mc_worldManager.GetSpawnRealm()
            spawn:TeleportPlayer(clicker)

            return nil
        end

        -- We now need to figure out where we are teleporting players
        local realmObject = nil

        -- If we are an instanced realm, we let our realm instancing logic take care of this; Otherwise we will use the realm ID to get the realm.
        if (instanced == "true") then
            realmObject = mc_worldManager.GetCreateInstancedRealm(realmName, clicker, realmSchematic, temp)
        else
            realmObject = Realm.GetRealm(realmID)

            -- If we couldn't find the realm, we will create a new one if there is a schematic associated with this teleporter.
            if (realmObject == nil) then
                if (realmSchematic ~= nil) then
                    realmObject = Realm:NewFromSchematic(realmName, realmSchematic)
                else
                    return nil
                end

                meta:set_int("realm", realmObject.ID)
                minetest.swap_node(pos, { name = "mc_worldmanager:teleporter", param2 = math.ceil(math.sin(realmObject.ID) * 255) })
            end

        end

        -- Create a teleporter for the realm so that players can get back easier
        realmObject:CreateTeleporter()

        -- Teleport the player to the realm
        realmObject:TeleportPlayer(clicker)

        return nil
    end,
    preserve_metadata = function(pos, oldnode, oldmeta, drops)
        local meta = drops[1]:get_meta()

        local instanced = oldmeta["instanced"]
        local temp = oldmeta["temp"]
        local realmID = oldmeta["realm"]
        local name = oldmeta["name"]
        local schematic = oldmeta["schematic"]

        meta:set_string("instanced", instanced)
        meta:set_string("temp", temp)
        meta:set_int('realm', realmID)
        meta:set_string("name", name)
        meta:set_string("schematic", schematic)

        meta:set_string("description", getDescription(instanced, temp, realmID, name, schematic))
    end,

    after_place_node = function(pos, placer, itemstack, pointed_thing)
        Debug.log("after_Place_node")

        local itemMeta = itemstack:get_meta()
        local nodeMeta = minetest.get_meta(pos)

        local instanced = itemMeta:get_string("instanced")
        local temp = itemMeta:get_string("temp")
        local realmID = itemMeta:get_int("realm")
        local name = itemMeta:get_string("name")
        local schematic = itemMeta:get_string("schematic")

        nodeMeta:set_string("instanced", instanced)
        nodeMeta:set_string("temp", temp)
        nodeMeta:set_int('realm', realmID)
        nodeMeta:set_string("name", name)
        nodeMeta:set_string("schematic", schematic)

        minetest.swap_node(pos, { name = "mc_worldmanager:teleporter", param2 = math.ceil(math.sin(realmID) * 255) })
    end
})

function mc_worldManager.GetTeleporterItemStack(count, instanced, temp, realmID, name, schematic)
    local item = ItemStack({ name = "mc_worldmanager:teleporter", count = count })
    local itemMeta = item:get_meta()

    if (count == nil or count == "") then
        count = 1
    end

    if (instanced == nil or count == "") then
        instanced = "true"
    end

    if (temp == nil or temp == "") then
        temp = "true"
    end

    if (realmID == nil or realmID == "") then
        realmID = 0
    end

    if (name == nil or name == "") then
        name = "Unnamed Realm"
    end

    itemMeta:set_string("instanced", instanced)
    itemMeta:set_string("temp", temp)
    itemMeta:set_int("realm", realmID)
    itemMeta:set_string("name", name)

    if (schematic ~= nil or schematic == "") then
        itemMeta:set_string("schematic", schematic)
    end

    itemMeta:set_string("description", getDescription(instanced, temp, realmID, name, schematic))

    return item
end