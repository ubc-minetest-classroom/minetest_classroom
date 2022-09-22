living_trees = {}

local modpath = minetest.get_modpath("living_trees")
dofile(modpath .. "/breaking.lua")
dofile(modpath .. "/branches.lua")

function opposite_dir(dir)
    if dir % 2 == 0 then
        return dir + 1
    else
        return dir - 1
    end
end

function wallmounted_to_facedir(dir)
    if dir == 0 then
        return 0
    elseif dir == 1 then
        return 5
    elseif dir == 2 then
        return 3
    elseif dir == 3 then
        return 4
    elseif dir == 4 then
        return 1
    elseif dir == 5 then
        return 2
    end
end

function add_dir_to_pos(pos, dir)
    if dir == 0 then
        pos.y = pos.y + 1
    elseif dir == 1 then
        pos.y = pos.y - 1
    elseif dir == 2 then
        pos.x = pos.x + 1
    elseif dir == 3 then
        pos.x = pos.x - 1
    elseif dir == 4 then
        pos.z = pos.z + 1
    elseif dir == 5 then
        pos.z = pos.z - 1
    end
    return pos
end

function living_trees.register_tree(tree)

    tree.name = tree.name:lower()

    minetest.register_craftitem("living_trees:" .. tree.name .. "_seed", {
        description = tree.name .. " seed",
        tiles = { "seed.png" },
        inventory_image = "seed.png",
        groups = { seed = 1 },
        on_place = function(itemstack, placer, pointed_thing)
            local pos = pointed_thing.above
            if minetest.get_node(pos).name == "air" then
                minetest.add_entity(pos, "living_trees:" .. tree.name .. "_seedEntity")
                itemstack:take_item(1)
            end
            return itemstack
        end,
        on_drop = function(itemstack, dropper, pos)
            minetest.add_entity(pos, "living_trees:" .. tree.name .. "_seedEntity")
            local stack = ItemStack({ name = "living_trees:" .. tree.name .. "_seed", count = 1 })

            dropper:get_inventory():remove_item("main", stack)
            itemstack:take_item(1)
        end,
    })

    minetest.register_entity("living_trees:" .. tree.name .. "_seedEntity", {
        visual = "wielditem",
        wield_item = "living_trees:" .. tree.name .. "_seed",
        visual_size = { x = 0.25, y = 0.25, z = 0.25 },
        collisionbox = { -0.25, 0.0, -0.25, 0.25, 0.25, 0.25 },
        physical = true,
        automatic_rotate = 1,
        collide_with_objects = false,
        on_step = function(self, dtime, moveresult)
            if (moveresult.touching_ground) then
                local velocity = self.object:get_velocity()
                self.object:add_velocity({ x = -velocity.x, y = -velocity.y, z = -velocity.z })
            end
        end,
        on_activate = function(self, staticdata, dtime_s)
            self.object:set_acceleration(vector.new(0, -9.8, 0))

            local placeTree = function()
            end

            placeTree = function(chance, age)
                local pos = self.object:getpos()
                if (chance == nil) then
                    chance = 1
                end

                if (age == nil) then
                    age = 1
                end

                if (age >= 10) then
                    self.object:remove()
                    return
                end


                -- Seed expires if it sits around for too long. This is for performance reasons.
                --TODO: make a small seed node that will occasionally check for favourable conditions
                --      and if so, turn back into the seed entity.
                if (chance > 50 or pos == nil) then
                    minetest.after(tree.growthInterval, placeTree, chance + 1, age + 1)
                    return
                end

                -- Check seed light levels. If it is too low, reduce health and don't try to grow...
                local lightLevel = minetest.get_node_light({ x = pos.x, y = pos.y + 1, z = pos.z }, 0.5)
                if (lightLevel ~= nil and lightLevel <= 9) then
                    minetest.after(tree.growthInterval, placeTree, chance + 1, age + 1)
                    return
                end

                if (math.random(0, 100) <= chance) then
                    local node = minetest.get_node(pos)

                    local nodeGroup = minetest.get_item_group(node.name, "soil")

                    if (nodeGroup ~= nil and nodeGroup > 0) then
                        minetest.set_node(pos, { name = "living_trees:" .. tree.name .. "_roots" })
                        minetest.set_node({ x = pos.x, y = pos.y + 1, z = pos.z }, { name = "living_trees:" .. tree.name .. "_sapling" })
                        self.object:remove()
                    else
                        minetest.after(tree.growthInterval, placeTree, 100, age + 2)
                    end
                else
                    minetest.after(tree.growthInterval, placeTree, chance + 1, age)
                end
            end

            minetest.after(tree.growthInterval, placeTree, 1)
        end,
        on_punch = function(self, clicker, time_from_last_punch, tool_capabilities, dir)
            local stack = ItemStack({ name = "living_trees:" .. tree.name .. "_seed", count = 1 })
            clicker:get_inventory():add_item("main", stack)
            self.object:remove()
        end
    })

    if (tree.leaves) then
        minetest.override_item(tree.leaves,
                { drop = { max_items = 0 },
                  groups = { flammable = 1 },
                  after_destruct = function(pos, oldnode)

                      local seedPos = { x = pos.x, y = pos.y + 5, z = pos.z }
                      if (minetest.get_node(seedPos).name == "air" and math.random(0, 100) >= 95) then

                          local entity = minetest.add_entity(pos, "living_trees:" .. tree.name .. "_seedEntity")
                          entity:add_velocity(vector.new(math.random(-15, 15), math.random(-15, 15), math.random(-15, 15)))
                      end
                  end })
    end

    minetest.register_node("living_trees:" .. tree.name .. "_roots", {
        description = tree.name .. " roots",
        tiles = { "default_dirt.png^living_trees_roots.png" },
        on_construct = function(pos)
            local meta = minetest.get_meta(pos)
            meta:set_string("lstring", tree.lstring)
        end,
        drop = { max_items = 1, items = { { rarity = 1, items = { "default:dirt" } } } },
        on_drop = function(itemstack, dropper, pos)
            return false
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            break_childs(pos, oldnode, true)
        end,
        groups = { crumbly = 2, choppy = 1 }
    })

    minetest.register_node("living_trees:" .. tree.name .. "_sapling", {
        description = tree.name .. "sapling",
        tiles = { "Sapling.png" },
        paramtype = "light",
        drawtype = "plantlike",
        paramtype2 = "meshoptions",
        sunlight_propagates = true,
        walkable = false,
        move_resistance = 2,
        waving = 1,
        param2 = 2,
        groups = { oddly_breakable_by_hand = 3, tree = 1, flammable = 5, attached_node = 1, sapling = 1 },
        on_construct = function(pos)
            minetest.get_node_timer(pos):start(math.random(1, tree.growthInterval * 2))
        end,
        on_timer = function(pos, elapsed)
            minetest.set_node({ x = pos.x, y = pos.y - 1, z = pos.z }, { name = "living_trees:" .. tree.name .. "_roots", param2 = 32 })
        end,
        after_dig_node = function(pos)
            minetest.set_node({ x = pos.x, y = pos.y - 1, z = pos.z }, { name = "default:dirt" })
        end,
    })

    tree.sapling = "living_trees:" .. tree.name .. "_sapling"
    tree.roots = { "living_trees:" .. tree.name .. "_roots" }


    local trunk_def = table.copy(minetest.registered_nodes[tree.trunk])
    trunk_def.description = tree.name .. " trunk"
    trunk_def.groups.flammable = 4
    trunk_def.drop = tree.trunk
    trunk_def.paramtype2 = "wallmounted"
    trunk_def.on_place = nil
    trunk_def.after_dig_node = function(pos, oldnode, oldmetadata, digger)
        break_childs(pos, oldnode)
    end

    minetest.register_node("living_trees:branch_trunk_" .. tree.name, trunk_def)

    local branch_trunk = "living_trees:branch_trunk_" .. tree.name

    register_branches(tree.name, tree.texture)
    local branch_3_4 = "living_trees:branch_3_4_" .. tree.name
    local branch_2_3 = "living_trees:branch_2_3_" .. tree.name
    local branch_1_2 = "living_trees:branch_1_2_" .. tree.name
    local branch_T_1 = "living_trees:branch_T_1_" .. tree.name
    local branch_4 = "living_trees:branch_4_" .. tree.name
    local branch_3 = "living_trees:branch_3_" .. tree.name
    local branch_2 = "living_trees:branch_2_" .. tree.name
    local branch_1 = "living_trees:branch_1_" .. tree.name

    minetest.register_abm({
        nodenames = tree.roots,
        interval = tree.growthInterval * 2,
        chance = tree.growthInterval / 2,
        catch_up = true,
        action = function(pos, node, active_object_count, active_object_count_wider)
            local curpos = pos
            local currot = { dir = 0, up = 3, left = 4 }        -- In wallmounted numbers
            local meta = minetest.get_meta(pos)
            local lstr = meta:get_string("lstring")
            local stack = {}
            local skipbranch = 0
            for i = 1, #lstr do

                local c = lstr:sub(i, i)

                if c == "]" then
                    if skipbranch > 1 then
                        skipbranch = skipbranch - 1
                    else
                        skipbranch = 0
                        currot = table.remove(stack)
                        curpos = table.remove(stack)
                    end
                elseif c == "[" then
                    if skipbranch > 0 then
                        skipbranch = skipbranch + 1
                    else
                        local savedpos = {}
                        for k, v in pairs(curpos) do
                            savedpos[k] = v
                        end
                        local savedrot = {}
                        for k, v in pairs(currot) do
                            savedrot[k] = v
                        end
                        table.insert(stack, savedpos)
                        table.insert(stack, savedrot)
                    end
                elseif skipbranch > 0 then
                elseif c == "T" then
                    add_dir_to_pos(curpos, currot.dir)
                    local name = minetest.get_node(curpos).name
                    if name == "air" or name == tree.leaves or name == tree.sapling then
                        minetest.set_node(curpos, { name = branch_3_4, param2 = opposite_dir(currot.dir) })
                        skipbranch = skipbranch + 1
                    elseif name == branch_3_4 then
                        minetest.set_node(curpos, { name = branch_2_3, param2 = opposite_dir(currot.dir) })
                    elseif name == branch_2_3 then
                        minetest.set_node(curpos, { name = branch_1_2, param2 = opposite_dir(currot.dir) })
                    elseif name == branch_1_2 then
                        minetest.set_node(curpos, { name = branch_T_1, param2 = opposite_dir(currot.dir) })
                    elseif name == branch_T_1 then
                        minetest.set_node(curpos, { name = branch_trunk, param2 = opposite_dir(currot.dir) }) --wallmounted_to_facedir(currot.dir) * 4})
                    elseif name ~= branch_trunk then
                        skipbranch = skipbranch + 1
                    end
                elseif c == "Q" then
                    add_dir_to_pos(curpos, currot.dir)
                    local name = minetest.get_node(curpos).name
                    if name == "air" or name == tree.leaves then
                        minetest.set_node(curpos, { name = branch_3_4, param2 = opposite_dir(currot.dir) })
                        skipbranch = skipbranch + 1
                    elseif name == branch_3_4 then
                        minetest.set_node(curpos, { name = branch_2_3, param2 = opposite_dir(currot.dir) })
                    elseif name == branch_2_3 then
                        minetest.set_node(curpos, { name = branch_1_2, param2 = opposite_dir(currot.dir) })
                    elseif name == branch_1_2 then
                        minetest.set_node(curpos, { name = branch_T_1, param2 = opposite_dir(currot.dir) })
                    elseif name ~= branch_T_1 then
                        skipbranch = skipbranch + 1
                    end
                elseif c == "W" then
                    add_dir_to_pos(curpos, currot.dir)
                    local name = minetest.get_node(curpos).name
                    if name == "air" or name == tree.leaves then
                        minetest.set_node(curpos, { name = branch_3_4, param2 = opposite_dir(currot.dir) })
                        skipbranch = skipbranch + 1
                    elseif name == branch_3_4 then
                        minetest.set_node(curpos, { name = branch_2_3, param2 = opposite_dir(currot.dir) })
                    elseif name == branch_2_3 then
                        minetest.set_node(curpos, { name = branch_1_2, param2 = opposite_dir(currot.dir) })
                    elseif name ~= branch_1_2 then
                        skipbranch = skipbranch + 1
                    end
                elseif c == "E" then
                    add_dir_to_pos(curpos, currot.dir)
                    local name = minetest.get_node(curpos).name
                    if name == "air" or name == tree.leaves then
                        minetest.set_node(curpos, { name = branch_3_4, param2 = opposite_dir(currot.dir) })
                        skipbranch = skipbranch + 1
                    elseif name == branch_3_4 then
                        minetest.set_node(curpos, { name = branch_2_3, param2 = opposite_dir(currot.dir) })
                    elseif name ~= branch_2_3 then
                        skipbranch = skipbranch + 1
                    end
                elseif c == "R" then
                    add_dir_to_pos(curpos, currot.dir)
                    local name = minetest.get_node(curpos).name
                    if name == "air" or name == tree.leaves then
                        minetest.set_node(curpos, { name = branch_3_4, param2 = opposite_dir(currot.dir) })
                        skipbranch = skipbranch + 1
                    elseif name ~= branch_3_4 then
                        skipbranch = skipbranch + 1
                    end
                elseif c == "1" then
                    add_dir_to_pos(curpos, currot.dir)
                    local name = minetest.get_node(curpos).name
                    if name == "air" or name == tree.leaves then
                        minetest.set_node(curpos, { name = branch_4, param2 = opposite_dir(currot.dir) })
                        skipbranch = skipbranch + 1
                    elseif name == branch_4 then
                        minetest.set_node(curpos, { name = branch_3, param2 = opposite_dir(currot.dir) })
                    elseif name == branch_3 then
                        minetest.set_node(curpos, { name = branch_2, param2 = opposite_dir(currot.dir) })
                    elseif name == branch_2 then
                        minetest.set_node(curpos, { name = branch_1, param2 = opposite_dir(currot.dir) })
                    elseif name ~= branch_1 then
                        skipbranch = skipbranch + 1
                    end
                elseif c == "2" then
                    add_dir_to_pos(curpos, currot.dir)
                    local name = minetest.get_node(curpos).name
                    if name == "air" or name == tree.leaves then
                        minetest.set_node(curpos, { name = branch_4, param2 = opposite_dir(currot.dir) })
                        skipbranch = skipbranch + 1
                    elseif name == branch_4 then
                        minetest.set_node(curpos, { name = branch_3, param2 = opposite_dir(currot.dir) })
                    elseif name == branch_3 then
                        minetest.set_node(curpos, { name = branch_2, param2 = opposite_dir(currot.dir) })
                    elseif name ~= branch_2 then
                        skipbranch = skipbranch + 1
                    end
                elseif c == "3" then
                    add_dir_to_pos(curpos, currot.dir)
                    local name = minetest.get_node(curpos).name
                    if name == "air" or name == tree.leaves then
                        minetest.set_node(curpos, { name = branch_4, param2 = opposite_dir(currot.dir) })
                        skipbranch = skipbranch + 1
                    elseif name == branch_4 then
                        minetest.set_node(curpos, { name = branch_3, param2 = opposite_dir(currot.dir) })
                    elseif name ~= branch_3 then
                        skipbranch = skipbranch + 1
                    end
                elseif c == "4" then
                    add_dir_to_pos(curpos, currot.dir)
                    local name = minetest.get_node(curpos).name
                    if name == "air" or name == tree.leaves then
                        minetest.set_node(curpos, { name = branch_4, param2 = opposite_dir(currot.dir) })
                        skipbranch = skipbranch + 1
                    elseif name ~= branch_4 then
                        skipbranch = skipbranch + 1
                    end
                elseif c == "^" then
                    local temp = opposite_dir(currot.dir)
                    currot.dir = currot.up
                    currot.up = temp
                elseif c == "&" then
                    local temp = opposite_dir(currot.up)
                    currot.up = currot.dir
                    currot.dir = temp
                elseif c == "+" then
                    local temp = opposite_dir(currot.left)
                    currot.left = currot.dir
                    currot.dir = temp
                elseif c == "-" then
                    local temp = opposite_dir(currot.dir)
                    currot.dir = currot.left
                    currot.left = temp
                elseif c == "/" then
                    local temp = opposite_dir(currot.left)
                    currot.left = currot.up
                    currot.up = temp
                elseif c == "*" then
                    local temp = opposite_dir(currot.up)
                    currot.up = currot.left
                    currot.left = temp
                end
            end
        end
    })

    if tree.leaves then
        minetest.register_abm({
            label = "Leaf growth (" .. tree.name .. ")",
            nodenames = { branch_3, branch_3_4, branch_4 },
            interval = tree.growthInterval,
            chance = tree.growthInterval / 2,
            catch_up = true,
            action = function(pos, node, active_object_count, active_object_count_wider)
                for x = -1, 1 do
                    for y = -1, 1 do
                        for z = -1, 1 do
                            local curpos = { x = x, y = y, z = z }
                            curpos = vector.add(pos, curpos)
                            if minetest.get_node(curpos).name == "air" and (y == 0 or x == 0 or z == 0) then
                                minetest.set_node(curpos, { name = tree.leaves })
                            end
                        end
                    end
                end
            end
        })
    end

end

dofile(modpath .. "/default_trees.lua")
