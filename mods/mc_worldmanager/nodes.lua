minetest.register_node("mc_worldmanager:temp", {
    description = "A temporary test block",
    tiles = { "mc_worldmanager_testnode.png" },
    is_ground_content = true
})

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

        if (realmID == 0) then
            minetest.chat_send_player(clicker:get_player_name(), "This teleporter is not linked to a realm.")
        end

        if (realmID == 0) then
            realmID = Realm.GetRealmFromPlayer(clicker).ID

            meta:set_int("realm", realmID)

            minetest.swap_node(pos, { name = "mc_worldmanager:teleporter", param2 = math.ceil(math.sin(realmID) * 255) })

            Debug.log("Teleport block not set to a realm. Setting to realm ID: " .. realmID)
            return nil
        end

        local realmObject = Realm.GetRealm(realmID)

        if (realmObject == nil) then
            return nil
        end

        realmObject:TeleportPlayer(clicker)

        return nil
    end,
    preserve_metadata = function(pos, oldnode, oldmeta, drops)

        local meta = drops[1]:get_meta()

        local realmID = oldmeta["realm"]

        if (realmID == nil) then
            meta:set_string("description", "A teleporter not linked to any realm.")
            return nil
        end

        meta:set_int('realm', realmID)
        meta:set_string("description", "A teleporter to realm " .. tostring(meta:get_int("realm")) .. ".")

    end,

    after_place_node = function(pos, placer, itemstack, pointed_thing)
        local itemMeta = itemstack:get_meta()

        local nodeMeta = minetest.get_meta(pos)
        nodeMeta:set_int('realm', itemMeta:get_int('realm'))
    end

})