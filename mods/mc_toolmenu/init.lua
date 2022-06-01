sfinv.register_page("mc_toolmenu:tools", {
    title = "Toolbox",
    get = function(self, player, context)
        local formtable = {
            "label[0.1,0.1;This will be the toolbox very soon!]",
            --"list[...]",
            --"listring[...]",
            --"listcolors[...]"
        }
        return sfinv.make_formspec(player, context, table.concat(formtable, ""), true)
    end
})

--[[
minetest.register_on_joinplayer(function(player)
    local inv = minetest.create_detached_inventory("mc_toolmenu:test", {
        allow_move = function(inv, from_list, from_index, to_list, to_index, count, player),
        -- Called when a player wants to move items inside the inventory.
        -- Return value: number of items allowed to move.

        allow_put = function(inv, listname, index, stack, player),
        -- Called when a player wants to put something into the inventory.
        -- Return value: number of items allowed to put.
        -- Return value -1: Allow and don't modify item count in inventory.

        allow_take = function(inv, listname, index, stack, player),
        -- Called when a player wants to take something out of the inventory.
        -- Return value: number of items allowed to take.
        -- Return value -1: Allow and don't modify item count in inventory.

        on_move = function(inv, from_list, from_index, to_list, to_index, count, player),
        on_put = function(inv, listname, index, stack, player),
        on_take = function(inv, listname, index, stack, player),
        -- Called after the actual action has happened, according to what was
        -- allowed.
        -- No return value.
    }, "test")
    local existing_lists = inv:get_lists()
    inv:set_list("tools", {})
)
]]