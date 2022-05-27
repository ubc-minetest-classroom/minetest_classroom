minetest.register_node("mc_tf:blankBlock", {
    description = "A blank block",
    tiles = { "mc_tf_blankBlock.png" },
    color = { a = 255, r = 75, g = 75, b = 75 },
    is_ground_content = true,
    groups = { cracky = 3, stone = 1 },
    walkable = true, -- The player falls through
    pointable = true, -- The player can't highlight it
    diggable = true, -- The player can't dig it
})