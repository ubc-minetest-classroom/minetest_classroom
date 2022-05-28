pab = {}

function pab.CreateBlockFromGroups(groups, callback)
    groups = groups or { oddly_breakable_by_hand = 1 }

    local nodeName = "mc_tf:" .. tostring(mc_helpers.stringToNumber(minetest.serialize(groups))) .. "Block"
    minetest.debug(nodeName)

    minetest.register_node(nodeName, {
        description = minetest.serialize(groups),
        tiles = { "mc_tf_blankBlock.png" },
        color = mc_helpers.stringToColor(nodeName),
        is_ground_content = true,
        groups = groups,


        after_dig_node = function(pos, oldnode, oldmetadata, digger)
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
                node = { name = nodeName, param2 = oldnode.param2 }
            })

            if (callback ~= nil) then
                callback(pos, oldnode, oldmetadata, digger, nodeName)
            end
        end,
        drop = "",
    })
end