mc_toolmenu = {}
mc_toolmenu.inv_storage = minetest.get_mod_storage()
dofile(minetest.get_modpath("mc_toolmenu") .. "/api.lua")

sfinv.register_page("mc_toolmenu:tools", {
    title = "Toolbox",
    get = function(self, player, context)
        local pname = player:get_player_name()
        local formtable = {
            "box[-0.28,-0.30;8.35,4.9;#555555]",
            "label[0,0;(WIP) Only tools can be stored here!]",
            "list[current_player;mc_toolmenu:tools;0,0.5;8,4;0]"
        }
        return sfinv.make_formspec(player, context, table.concat(formtable, ""), true)
    end
})

minetest.register_on_joinplayer(function(player)
    -- player check
    if not player:is_player() then return end

    local pname = player:get_player_name()
    local inv = player:get_inventory()

    -- register inventory, if not created
    if not inv:get_list("mc_toolmenu:tools") then
        inv:set_list("mc_toolmenu:tools", {})
        inv:set_size("mc_toolmenu:tools", 32)
    end
end)

minetest.register_allow_player_inventory_action(function(player, action, inventory, inv_info)
    -- initial check
    list_info = inv_info.listname or (inv_info.to_list == "mc_toolmenu:tools" and inv_info.to_list or inv_info.from_list)
    if list_info ~= "mc_toolmenu:tools" then
        return -- toolbox not affected, ignore
    end

    minetest.log("Inventory action with toolbox: "..action)
    if action == "move" then
        if inv_info.to_list == "mc_toolmenu:tools" then
            -- putting item into toolbox, run checks
            local moving_stack = inventory:get_stack(inv_info.from_list, inv_info.from_index)
            if minetest.registered_tools[moving_stack:get_name()] then 
                return 1 -- allow 1 item (tool) to be put in
            else
                return 0 -- do not allow item to be put in
            end
        else
            return -- no items going into toolbox, ignore
        end
    elseif action == "put" and inv_info.listname == "mc_toolmenu:tools" then
        if minetest.registered_tools[inv_info.stack:get_name()] then 
            return 1 -- allow 1 item (tool) to be put in
        else
            return 0 -- do not allow item to be put in
        end
    else
        return -- ignore
    end
end)

