minetest.register_node("openstreetmap:node", {
    description = "OSM Node",
    tiles = {"node.png"},
    inventory_image = "node.png",
    wield_image = "node.png",
    sunlight_propagates = true,
    paramtype = "light",
    drawtype = "glasslike",
    walkable = true,
    buildable_to = true,
})

minetest.register_node("openstreetmap:way", {
    description = "OSM Way",
    tiles = {"way.png"},
    inventory_image = "way.png",
    wield_image = "way.png",
    sunlight_propagates = true,
    paramtype = "light",
    drawtype = "glasslike",
    walkable = true,
    buildable_to = true,
})

minetest.register_node("openstreetmap:relation", {
    description = "OSM Relation",
    tiles = {"relation.png"},
    inventory_image = "relation.png",
    wield_image = "relation.png",
    sunlight_propagates = true,
    paramtype = "light",
    drawtype = "glasslike",
    walkable = true,
    buildable_to = true,
})

-- Register the textures as nodes
for tag, texture in pairs(openstreetmap.osm_textures) do
    minetest.register_node("openstreetmap:" .. tag, {
        description = "OSM " .. tag:gsub("_", " "):gsub("^%l", string.upper),
        tiles = {texture},
        inventory_image = texture,
        wield_image = texture,
        sunlight_propagates = true,
        paramtype = "light",
        drawtype = "glasslike",
        walkable = true,
        buildable_to = true,
    })
end