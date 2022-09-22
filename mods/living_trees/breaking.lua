function break_childs(pos, oldnode, is_root)
    local param2 = oldnode.param2
    if param2 ~= 3 or is_root then
        local curpos = vector.add(pos, { x = -1, y = 0, z = 0 })
        local node = minetest.get_node(curpos)
        if node.name:sub(0, 19) == "living_trees:branch" and node.param2 == 2 then
            minetest.dig_node(curpos)
        end
    end
    if param2 ~= 2 or is_root then
        curpos = vector.add(pos, { x = 1, y = 0, z = 0 })
        node = minetest.get_node(curpos)
        if node.name:sub(0, 19) == "living_trees:branch" and node.param2 == 3 then
            minetest.dig_node(curpos)
        end
    end
    if param2 ~= 1 or is_root then
        curpos = vector.add(pos, { x = 0, y = -1, z = 0 })
        node = minetest.get_node(curpos)
        if node.name:sub(0, 19) == "living_trees:branch" and node.param2 == 0 then
            minetest.dig_node(curpos)
        end
    end
    if param2 ~= 0 or is_root then
        curpos = vector.add(pos, { x = 0, y = 1, z = 0 })
        node = minetest.get_node(curpos)
        if node.name:sub(0, 19) == "living_trees:branch" and node.param2 == 1 then
            minetest.dig_node(curpos)
        end
    end
    if param2 ~= 5 or is_root then
        curpos = vector.add(pos, { x = 0, y = 0, z = -1 })
        node = minetest.get_node(curpos)
        if node.name:sub(0, 19) == "living_trees:branch" and node.param2 == 4 then
            minetest.dig_node(curpos)
        end
    end
    if param2 ~= 4 or is_root then
        curpos = vector.add(pos, { x = 0, y = 0, z = 1 })
        node = minetest.get_node(curpos)
        if node.name:sub(0, 19) == "living_trees:branch" and node.param2 == 5 then
            minetest.dig_node(curpos)
        end
    end
end
