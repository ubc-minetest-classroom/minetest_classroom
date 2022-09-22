local large_nodebox = {
    type = "fixed",
    fixed = {
        { -0.375, -0.0625, -0.375, 0.375, 0.375, 0.375 },
        { -0.5, -0.5, -0.5, 0.5, -0.0625, 0.5 },
    }
}
local medium_nodebox = {
    type = "fixed",
    fixed = {
        { -0.25, -0.1875, -0.25, 0.25, 0.25, 0.25 },
        { -0.375, -0.625, -0.375, 0.375, -0.1875, 0.375 },
    }
}
local small_nodebox = {
    type = "fixed",
    fixed = {
        { -0.125, -0.3125, -0.125, 0.125, 0.125, 0.125 },
        { -0.25, -0.75, -0.25, 0.25, -0.3125, 0.25 },
    }
}
local stick_nodebox = {
    type = "fixed",
    fixed = {
        { -0.0625, -0.4375, -0.0625, 0.0625, 0.0625, 0.0625 },
        { -0.125, -0.875, -0.125, 0.125, -0.4375, 0.125 },
    }
}

function register_branches(name, texture)
    minetest.register_node("living_trees:branch_T_1_" .. name, {
        description = "Large " .. name .. " branch",
        tiles = {
            {
                name = texture,
                backface_culling = true,
            }
        },
        drawtype = "mesh",
        mesh = "trunk_to_large.obj",
        paramtype = "light",
        paramtype2 = "wallmounted",
        drop = "default:stick",
        groups = { oddly_breakable_by_hand = 2 },
        selection_box = large_nodebox,
        collision_box = large_nodebox,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            break_childs(pos, oldnode)
        end
    })

    minetest.register_node("living_trees:branch_1_2_" .. name, {
        description = "Medium " .. name .. " branch",
        tiles = {
            {
                name = texture,
                backface_culling = true,
            }
        },
        drawtype = "mesh",
        mesh = "large_to_medium.obj",
        paramtype = "light",
        paramtype2 = "wallmounted",
        drop = "default:stick",
        groups = { oddly_breakable_by_hand = 2 },
        selection_box = medium_nodebox,
        collision_box = medium_nodebox,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            break_childs(pos, oldnode)
        end
    })

    minetest.register_node("living_trees:branch_2_3_" .. name, {
        description = "Small " .. name .. " branch",
        tiles = {
            {
                name = texture,
                backface_culling = true,
            }
        },
        drawtype = "mesh",
        mesh = "medium_to_small.obj",
        paramtype = "light",
        paramtype2 = "wallmounted",
        drop = "default:stick",
        groups = { oddly_breakable_by_hand = 2 },
        selection_box = small_nodebox,
        collision_box = small_nodebox,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            break_childs(pos, oldnode)
        end
    })

    minetest.register_node("living_trees:branch_3_4_" .. name, {
        description = "Tiny " .. name .. " branch",
        tiles = {
            {
                name = texture,
                backface_culling = true,
            }
        },
        drawtype = "mesh",
        mesh = "small_to_stick.obj",
        paramtype = "light",
        paramtype2 = "wallmounted",
        drop = "default:stick",
        groups = { oddly_breakable_by_hand = 2 },
        selection_box = stick_nodebox,
        collision_box = stick_nodebox,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            break_childs(pos, oldnode)
        end
    })

    minetest.register_node("living_trees:branch_1_" .. name, {
        description = "Large " .. name .. " branch",
        tiles = { texture },
        drawtype = "nodebox",
        paramtype = "light",
        paramtype2 = "wallmounted",
        drop = "default:stick",
        groups = { oddly_breakable_by_hand = 2 },
        node_box = {
            type = "fixed",
            fixed = {
                { -0.375, -0.625, -0.375, 0.375, 0.375, 0.375 },
            }
        },
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            break_childs(pos, oldnode)
        end
    })

    minetest.register_node("living_trees:branch_2_" .. name, {
        description = "Medium " .. name .. " branch",
        tiles = { texture },
        drawtype = "nodebox",
        paramtype = "light",
        paramtype2 = "wallmounted",
        drop = "default:stick",
        groups = { oddly_breakable_by_hand = 2 },
        node_box = {
            type = "fixed",
            fixed = {
                { -0.25, -0.75, -0.25, 0.25, 0.25, 0.25 },
            }
        },
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            break_childs(pos, oldnode)
        end
    })

    minetest.register_node("living_trees:branch_3_" .. name, {
        description = "Small " .. name .. " branch",
        tiles = { texture },
        drawtype = "nodebox",
        paramtype = "light",
        paramtype2 = "wallmounted",
        drop = "default:stick",
        groups = { oddly_breakable_by_hand = 2 },
        node_box = {
            type = "fixed",
            fixed = {
                { -0.125, -0.875, -0.125, 0.125, 0.125, 0.125 },
            }
        },
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            break_childs(pos, oldnode)
        end
    })

    minetest.register_node("living_trees:branch_4_" .. name, {
        description = "Tiny " .. name .. " branch",
        tiles = { texture },
        drawtype = "nodebox",
        paramtype = "light",
        paramtype2 = "wallmounted",
        drop = "default:stick",
        groups = { oddly_breakable_by_hand = 2 },
        node_box = {
            type = "fixed",
            fixed = {
                { -0.0625, -0.9375, -0.0625, 0.0625, 0.0625, 0.0625 },
            }
        },
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            break_childs(pos, oldnode)
        end
    })
end
