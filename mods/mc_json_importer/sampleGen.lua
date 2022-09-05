local sampleTables = {}
sampleTables["sampleBiome"] = {
    _jsonType = "biome",
    name = "mc_json_importer:sample_biome",
    node_top = "default:dirt_with_grass",
    depth_top = 1,
    node_filler = "default:dirt",
    depth_filler = 3,
    node_stone = "default:stone",
    node_water_top = "default:water_source",
    depth_water_top = 10,
    node_water = "default:water_source",
    node_riverbed = "default:water_source",
    depth_riverbed = 2,
    node_cave_liquid = "default:water_source",
    y_max = 31000,
    y_min = -31000,
    vertical_blend = 8,
    heat_point = 50,
    humidity_point = 50
}

sampleTables["sampleNode"] = {
    _jsonType = "node",
    name = "mc_json_importer:sample_node",
    description = "Test Node",
    drawtype = "normal",
    tiles = { "default_dirt.png" },
    is_ground_content = true,
    groups = { crumbly = 3 },
    drop = "default:dirt"
}

sampleTables["craftItem"] = {
    _jsonType = "craft_item",
    description = "Sample Item",
    short_description = "Sample Axe",
    groups = {},
    inventory_image = "default_tool_steelaxe.png",
    inventory_overlay = "overlay.png",
    wield_image = "",
    wield_overlay = "",
    wield_scale = { x = 1, y = 1, z = 1 },
    stack_max = 99,
    range = 4.0,
    liquids_pointable = false,
    light_source = 0,
}

sampleTables["tool"] = {
    _jsonType = "tool",
    description = "Sample Axe",
    short_description = "Steel Axe",
    groups = {},
    inventory_image = "default_tool_steelaxe.png",
    inventory_overlay = "overlay.png",
    wield_image = "",
    wield_overlay = "",
    wield_scale = { x = 1, y = 1, z = 1 },
    stack_max = 99,
    range = 4.0,
    liquids_pointable = false,
    light_source = 0,
}

sampleTables["recipe"] = {
    _jsonType = "craft_recipe",
    output = "default:pick_stone",
    recipe = {
        {"default:cobble", "default:cobble", "default:cobble"},
        {"", "default:stick", ""},
        {"", "default:stick", ""},  -- Also groups; e.g. "group:crumbly"
    },
}

for k, sampleTable in pairs(sampleTables) do
    local dataPath = json_importer.path .. "\\data\\" .. sampleTable._jsonType .. "s\\"
    minetest.mkdir(dataPath)

    -- Write our sample json files to the mod's folder
    local jsonText = minetest.write_json(sampleTable, true)
    local f = io.open(dataPath .. k .. ".json", "wb")
    local content = f:write(jsonText)
    f:close()
end
