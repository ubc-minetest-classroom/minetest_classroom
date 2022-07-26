minetest.register_node("mc_trees:stage1_sapling", {
    description = "Sapling",
    tiles = { "Sapling.png" },
    paramtype = "light",
    drawtype = "plantlike",
    paramtype2 = "meshoptions",
    sunlight_propagates = true,
    walkable = false,
    move_resistance = 2,
    waving = 1,
    param2 = 2,
    groups = { oddly_breakable_by_hand = 3, tree = 1, flammable = 2, attached_node = 1, sapling = 1 },
    on_construct = function(pos)
        minetest.get_node_timer(pos):start(math.random(0, 5))
    end,
    on_timer = function(pos, elapsed)
        minetest.set_node(pos, { name = "air" })
        minetest.set_node({ x = pos.x, y = pos.y - 1, z = pos.z }, { name = "mc_trees:stage2_sapling", param2 = 32 })

    end
})

minetest.register_node("mc_trees:stage2_sapling", {
    description = "Sapling",
    tiles = { "Stump.png" },
    special_tiles = { { name = "Sapling2.png" } },
    paramtype = "light",
    drawtype = "plantlike_rooted",
    paramtype2 = "leveled",
    param2 = 127,
    groups = { oddly_breakable_by_hand = 3, tree = 1, flammable = 2, attached_node = 1, sapling = 1 },
    on_construct = function(pos)
        minetest.get_node_timer(pos):start(math.random(0, 2))
    end,
    on_timer = function(pos, elapsed)
        Debug.log("Increasing stage2 sapling height")
        local oldParam2 = minetest.get_node(pos).param2
        minetest.swap_node(pos, { name = "mc_trees:stage2_sapling", param2 = oldParam2 + 1 })

        if (oldParam2 < 126) then
            minetest.get_node_timer(pos):start(math.random(0, 2))
        end

    end
})

local maxScale = 20
for i = 1, maxScale do
    minetest.register_node("mc_trees:trunk" .. tostring(i) , {
        description = "Trunk Piece " .. tostring(i),
        drawtype = "nodebox",
        tiles = { "Stump.png" },
        paramtype = "light",
        visual_scale = i / maxScale
    })

end