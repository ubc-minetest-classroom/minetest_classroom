local S = forestry_tools.S

-- Allows zooming
 minetest.register_tool("forestry_tools:wedgeprism", {
    description = S("Wedge Prism"),
    wield_image = "wedgeprism.jpeg",
    inventory_image = "wedgeprism.jpeg",
    _mc_tool_privs = forestry_tools.priv_table,
})

function update_wedge(player)
    local wielding = player:get_wielded_item()
    local playername = player:get_player_name()
    local privs = minetest.get_player_privs(playername)
    if not wielding:is_empty() and wielding:get_name() == "forestry_tools:wedgeprism" then
        -- Has prism
        if privs.zoom ~= true then
            privs.zoom = true
            minetest.set_player_privs(playername, privs)
        end
    else
        -- Does not have prism
        if privs.zoom == true then
            privs.zoom = nil
            minetest.set_player_privs(playername, privs)
        end
    end
end



--  function init_hud(player)   

--      update_wedge(player)