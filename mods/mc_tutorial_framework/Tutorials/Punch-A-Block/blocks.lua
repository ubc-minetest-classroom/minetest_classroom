minetest.register_node("mc_tf:blankBlock", {
    description = "A blank grey block",
    tiles = { "mc_tf_blankBlock.png" },
    color = { a = 255, r = 75, g = 75, b = 75 },
    is_ground_content = true,
    groups = { oddly_breakable_by_hand = 1},
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        minetest.set_timeofday(0.5)
        minetest.add_particlespawner({
            amount = 100,
            time = 0.1,
            minpos = {x=pos.x - 0.5, y=pos.y - 0.5, z=pos.z - 0.5},
            maxpos = {x=pos.x + 0.5, y=pos.y + 0.5, z=pos.z + 0.5},
            minvel = {x=-0.5, y=0.1, z=-0.5},
            maxvel = {x=0.5, y=0.5, z=0.5},
            minacc = {x=0, y=1, z=0},
            maxacc = {x=0, y=1, z=0},
            minexptime = 2,
            maxexptime = 4,
            minsize = 0,
            maxsize = 1,
            node = {name = "mc_tf:blankBlock", param2 = oldnode.param2}
        })
        local pmeta = digger:get_meta()
        local oldBTBValue = pmeta:get_int("breakTutorialBlock") or 0
        pmeta:set_int("breakTutorialBlock", oldBTBValue + 1)
        minetest.debug(oldBTBValue + 1)

        tutorial.blockDestroyed(digger)
    end,
})