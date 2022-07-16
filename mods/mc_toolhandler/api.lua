--- @public
--- Returns a detached inventory containing all tools `player` has the privileges to use, which `player` can freely take copies of as desired
--- It is recommended to call this every time access to the detached inventory is needed in case player privileges change between uses
--- @param player Player to generate the detached inventory for
--- @return InvRef, string, string
function mc_toolhandler.create_tool_inventory(player)
    local pname = player:get_player_name()
    local inv_name = "mc_toolhandler:"..pname
    local list_name = "store"

    -- get detached inventory, or initialize if it doesn't already exist
    local store_inv = minetest.get_inventory({type = "detached", name = inv_name})
    if not store_inv then
        store_inv = minetest.create_detached_inventory(inv_name, {
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
    store_inv:set_list(list_name, {})
    local tools_to_check = table.insert_all(mc_helpers.shallowCopy(mc_toolhandler.reg_tools), mc_toolhandler.reg_group_tools)
    local count = 0

    -- add items to store
    for i,item in pairs(tools_to_check) do
        local stack = ItemStack(item)
        if stack and mc_helpers.checkPrivs(player, stack:get_definition()._mc_tool_privs) then
            count = count + 1
            store_inv:set_size(list_name, count)
            store_inv:add_item(list_name, stack)
        end
    end

    return store_inv, inv_name, list_name
end

-- TOOL STORE TEST NODE
minetest.register_node("mc_toolhandler:test_store", {
    description = "Tool store test node",
    tiles = {"mc_toolhandler_test_store.png"},
    groups = {dig_immediate = 2},
    on_rightclick = function(pos, node, player, itemstack, pointed_thing)
        local pname = player:get_player_name()
        local store, inv_name, list_name = mc_toolhandler.create_tool_inventory(player)
        local formtable = {
            "formspec_version[5]",
            "size[10.5,11]",
            "list[detached:", inv_name, ";", list_name, ";0.4,0.9;8,2;0]",
            "list[current_player;main;0.4,5.9;8,4;0]",
            "listring[]",
            "label[0.4,0.5;", minetest.formspec_escape("[TEST]"), " Shopping time!]",
        }
        minetest.show_formspec(pname, "mc_toolhandler:store", table.concat(formtable, ""))
    end
})