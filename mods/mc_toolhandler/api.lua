--- @public
--- Returns a detached inventory containing all tools `player` has the privileges to use, which `player` can freely take copies of as desired
--- It is recommended to call this every time access to the detached inventory is needed in case player privileges change between uses
--- @param player Player to generate the detached inventory for
--- @return InvRef
function mc_toolhandler.create_tool_inventory(player)
    local pname = player:get_player_name()

    -- get detached inventory, or initialize if it doesn't already exist
    local store_inv = minetest.get_inventory({type = "detached", name = "mc_toolhandler:"..pname})
    if not store_inv then
        store_inv = minetest.create_detached_inventory("mc_toolhandler:"..pname, {
            allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
                -- static inventory: do not allow items to be moved
                return 0
            end,
            allow_put = function(inv, listname, index, stack, player)
                -- static inventory: do not allow items to be put in
                return 0
            end,
            allow_take = function(inv, listname, index, stack, player)
                if not mc_helpers.checkPrivs(player, stack:get_definition()._mc_tool_privs) then
                    -- no permissions: do not allow player to take item
                    return 0
                else
                    -- permissions: allow player to take copy of item, keep original copy
                    return -1
                end
            end,
        }, pname)
    end

    -- clear existing store list
    store_inv:set_list("store", {})
    local tools_to_check = table.insert_all(table.copy(mc_toolhandler.reg_tools), mc_toolhandler.reg_group_tools)
    local count = 0

    -- add items to store
    for i,item in pairs(tools_to_check)
        local stack = ItemStack(item)
        if stack and mc_helpers.checkPrivs(player, stack:get_definition()._mc_tool_privs) then
            count = count + 1
            store_inv:set_size("store", count)
            store_inv:add_item("store", stack)
        end
    end

    return store_inv
end