minetest.register_node("mc_worldmanager:temp", {
    description = "A temporary test block",
    tiles = { "mc_worldmanager_testnode.png" },
    is_ground_content = true
})

minetest.register_node("mc_worldmanager:teleporter", {
    description = "Teleporter Node",
    tiles = { "mc_worldmanager_testnode.png" },
    paramtype = "none",
    paramtype2 = "none",
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)


        local realmID = node.param1 + node.param2

        Debug.log(realmID)

        if (realmID == 0) then
            realmID = Realm.GetRealmFromPlayer(clicker).ID

            local par2 = realmID - 255
            local par1 = realmID - par2

            minetest.swap_node(pos, { name = "mc_worldmanager:teleporter", param1 = par1, param2 = par2 })
            Debug.log("Teleport block not set to a realm. Setting to realm ID: " .. realmID)
            return nil
        end

        local realmObject = Realm.GetRealm(realmID)

        if (realmObject == nil) then
            return nil
        end

        realmObject:TeleportPlayer(clicker)

        return nil
    end
})