mc_toolmenu = minetest.get_mod_storage()

sfinv.register_page("mc_toolmenu:tools", {
    title = "Toolbox",
    get = function(self, player, context)
        local formtable = {
            "box[-0.28,-0.30;8.35,4.9;#555555]",
            "label[0,0;Soon, this will be made into a working toolbox!]",
            "list[current_player;mc_toolmenu:tools;0,0.5;8,1;0]"
        }
        return sfinv.make_formspec(player, context, table.concat(formtable, ""), true)
    end
})

-- debug
--minetest.remove_detached_inventory("mc_toolmenu:test")

minetest.register_on_joinplayer(function(player)
    if not player:is_player() then
        return
    end

    local pname = player:get_player_name()
    local inv_list = mc_toolmenu:get(pname)

    inv = minetest.create_detached_inventory("mc_toolmenu:"..pname, {
        --allow_move = function(inv, from_list, from_index, to_list, to_index, count, player),
        -- Called when a player wants to move items inside the inventory.
        -- Return value: number of items allowed to move.

        --allow_put = function(inv, listname, index, stack, player),
        -- Called when a player wants to put something into the inventory.
        -- Return value: number of items allowed to put.
        -- Return value -1: Allow and don't modify item count in inventory.

        --allow_take = function(inv, listname, index, stack, player),
        -- Called when a player wants to take something out of the inventory.
        -- Return value: number of items allowed to take.
        -- Return value -1: Allow and don't modify item count in inventory.

        --on_move = function(inv, from_list, from_index, to_list, to_index, count, player),
        --on_put = function(inv, listname, index, stack, player),
        --on_take = function(inv, listname, index, stack, player),
        -- Called after the actual action has happened, according to what was
        -- allowed.
        -- No return value.
    }, player:get_player_name())

    if not inv_list then
        mc_toolmenu:set_string(pname, minetest.serialize(inv:get_lists()))
    end
    --local inv = minetest.get_inventory({type = "detached", name = "mc_toolmenu:"..pname}) 
    
    local existing_lists = inv:get_lists()
    inv:set_list("tools", {})

    -- debug
    minetest.chat_send_all(minetest.serialize(existing_lists))
    minetest.chat_send_all(minetest.serialize(inv:get_lists()))
end)

--[[ player inventory snippet
local inv = minetest.get_inventory({type = "player", name = pname})
if not inv:get_list("mc_toolmenu:tools") then
    inv:set_list("mc_toolmenu:tools", {})
    inv:set_size("mc_toolmenu:tools", 3)
end
]]