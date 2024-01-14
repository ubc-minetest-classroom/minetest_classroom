-- The controller for accessing the OSM functions on nodes
minetest.register_tool("openstreetmap:inspector", {
    description = "Inspector for viewing OSM data",
    inventory_image = "inspector.png",

    on_use = function(itemstack, player, pointed_thing)
        local pos = minetest.get_pointed_thing_position(pointed_thing, above)
        if pos ~= nil then
            openstreetmap.pointed_thing_pos = pos
            -- Check if we need to stop identifying nodes
            if openstreetmap.select_nodes then 
                -- Done selecting
                openstreetmap.select_nodes = false
                -- Remove the HUD
                player:hud_remove(openstreetmap.hud_idx)
                -- Replace selected nodes with their original type
                for i=1, #openstreetmap.temp_node_pos do
                    local node = minetest.get_node(openstreetmap.temp_node_pos[i])
                    node.name = minetest.get_meta(openstreetmap.temp_node_pos[i]):get_string("osm_placeholder")
                    minetest.swap_node(openstreetmap.temp_node_pos[i], node)
                    -- TODO: Add the node positions to the database
                end
            end
            openstreetmap.show_osm_tags_fs(player,pos)
        end
    end,

    -- Destroy the inspector on drop
    on_drop = function(itemstack, dropper, pos)
    end,
})