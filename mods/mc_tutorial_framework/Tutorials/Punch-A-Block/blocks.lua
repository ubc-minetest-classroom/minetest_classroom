pab = {}

function pab.createBreakableBlock(groups, ID)
    groups = groups or { oddly_breakable_by_hand = 1 }
    ID = ID or minetest.serialize(groups)


    minetest.register_node("mc_tf:" .. ID .. "Block", {
        tiles = { "mc_tf_blankBlock.png" },
        color = mc_helpers.stringToColor(minetest.serialize(groups)),
        is_ground_content = true,
        groups = groups,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            minetest.set_timeofday(0.5)
            minetest.add_particlespawner({
                amount = 100,
                time = 0.1,
                minpos = { x = pos.x - 0.5, y = pos.y - 0.5, z = pos.z - 0.5 },
                maxpos = { x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5 },
                minvel = { x = -0.5, y = 0.1, z = -0.5 },
                maxvel = { x = 0.5, y = 0.5, z = 0.5 },
                minacc = { x = 0, y = 1, z = 0 },
                maxacc = { x = 0, y = 1, z = 0 },
                minexptime = 2,
                maxexptime = 4,
                minsize = 0,
                maxsize = 1,
                node = { name = "mc_tf:" .. ID .. "Block", param2 = oldnode.param2 }
            })

            tutorial.blockDestroyed(digger,ID)
        end,
    })
end