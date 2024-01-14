local node_def = {
    sunlight_propagates = false,
    drawtype = "mesh",
    mesh = "ubc_sign_final.obj",
    tiles = {"ubc_sign_texture.png"},
    groups = {oddly_breakable_by_hand=3}
}
minetest.register_node("ubcv_campus_objects:ubc_sign",node_def)

local node_def = {
    sunlight_propagates = false,
    drawtype = "mesh",
    mesh = "totem_final_3.obj",
    tiles = {"totem_pole_texture.png"},
    groups = {oddly_breakable_by_hand=3}
}
minetest.register_node("ubcv_campus_objects:musqueam_post",node_def)


local node_def = {
    sunlight_propagates = false,
    drawtype = "mesh",
    mesh = "engineer_block.obj",
    tiles = {"e-white.png", "e-red.png"},
    groups = {oddly_breakable_by_hand=3}
}
minetest.register_node("ubcv_campus_objects:engineering_cairn",node_def)

local node_def = {
    sunlight_propagates = false,
    drawtype = "mesh",
    mesh = "icisis_model.obj",
    tiles = {"black.png", "green.png", "blue.png", "red.png"},
    groups = {oddly_breakable_by_hand=3}
}
minetest.register_node("ubcv_campus_objects:icisis",node_def)

local node_def = {
    sunlight_propagates = false,
    drawtype = "mesh",
    mesh = "banner_v1.obj",
    tiles = {"pole_base.png", "pole_light.png", "banner.png"},
    groups = {oddly_breakable_by_hand=3}
}
minetest.register_node("ubcv_campus_objects:light_pole_1",node_def)

local node_def = {
    sunlight_propagates = true,
    drawtype = "mesh",
    mesh = "banner_v2.obj",
    tiles = {"pole_top_v2.png", "pole_light.png", "pole_base_v2.png", "pole_black_v2.png", "banner.png"},
    groups = {oddly_breakable_by_hand=3}
}
minetest.register_node("ubcv_campus_objects:light_pole_2",node_def)

local node_def = {
    sunlight_propagates = false,
    drawtype = "mesh",
    mesh = "banner_v3.obj",
    tiles = {"pole_base.png", "pole_base_v3.png", "pole_light.png", "banner.png"},
    groups = {oddly_breakable_by_hand=3}
}
minetest.register_node("ubcv_campus_objects:light_pole_3",node_def)

local node_def = {
    sunlight_propagates = true,
    drawtype = "mesh",
    mesh = "light_pole.obj",
    tiles = {"pole_base.png", "pole_light.png", "banner.png"},
    groups = {oddly_breakable_by_hand=3}
}
minetest.register_node("ubcv_campus_objects:light_pole_no_banner",node_def)

local node_def = {
    sunlight_propagates = false,
    drawtype = "mesh",
    mesh = "fountaun_final.obj",
    tiles = {{name = "default_aspen_wood.png"}, 
    {name = "default_water_source_animated.png", 
    backface_culling = true,
    animation = {
        type = "vertical_frames",
        aspect_w = 16,
        aspect_h = 16,
        length = 2.0}}, 
    {name = "base.png"}, {name = "watersproutbase.png"}, {name = "steel_texture.png"}, {name =  "outer_tile.png"}, 
    {name = "bottom_tile.png"}},
    groups = {oddly_breakable_by_hand=3}
}
minetest.register_node("ubcv_campus_objects:water_fountain",node_def)

local node_def = {
    sunlight_propagates = false,
    drawtype = "mesh",
    mesh = "clocktower.obj",
    tiles = {{name = "clock_tower_base.png"}, {name = "clock_white.png"}, 
    {name = "clock_black.png"}, {name = "clock_blue.png"}, {name = "clock_orange.png"}},
    groups = {oddly_breakable_by_hand=3}
}
minetest.register_node("ubcv_campus_objects:clock_tower",node_def)


local node_def = {
    sunlight_propagates = true,
    drawtype = "mesh",
    mesh = "bench.obj",
    tiles = {{name = "default_aspen_wood.png"}, {name = "default_steel_block.png"}},
    groups = {oddly_breakable_by_hand=3}
}
minetest.register_node("ubcv_campus_objects:bench",node_def)

local node_def = {
    sunlight_propagates = true,
    drawtype = "mesh",
    mesh = "bike_rack.obj",
    tiles = {{name = "default_steel_block.png"}},
    groups = {oddly_breakable_by_hand=3}
}
minetest.register_node("ubcv_campus_objects:bike_rack",node_def)

local node_def = {
    sunlight_propagates = true,
    drawtype = "mesh",
    mesh = "emergency_phone.obj",
    tiles = {{name = "emergency_phone_blue.png"}, {name = "emergency_phone_sign1.png"}, {name = "emergency_phone_sign2.png"}, 
    {name = "emergency_phone_sign3.png"}, {name = "emergency_phone_light.png"}, {name = "default_glass.png"}},
    groups = {oddly_breakable_by_hand=3}
}
minetest.register_node("ubcv_campus_objects:emergency_phone",node_def)

local node_def = {
    sunlight_propagates = true,
    drawtype = "mesh",
    mesh = "reconcilation_pole.obj",
    tiles = {{name = "totem_base.png"}, {name = "totem_black.png"}, {
        name = "totem_white.png"}, {name = "totem_extra_1.png"}, 
        {name = "totem_extra_2.png"}, {name = "totem_extra_3.png"}},
    groups = {oddly_breakable_by_hand=3}
}
minetest.register_node("ubcv_campus_objects:reconcilation_pole",node_def)

local node_def = {
    sunlight_propagates = true,
    drawtype = "mesh",
    mesh = "waste_bin.obj",
    tiles = {"waste_bin_texture.png"},
    groups = {oddly_breakable_by_hand=3}
}
minetest.register_node("ubcv_campus_objects:waste_bin",node_def)

-- Below are temporary for visualizing on server

local node_def = {
    sunlight_propagates = true,
    drawtype = "allfaces_optional",
	new_style_leaves = 1,
    tiles = {"snowberry_fall.png"},
    groups = {oddly_breakable_by_hand=3}
}
minetest.register_node("ubcv_campus_objects:snowberry_fall",node_def)

local node_def = {
    sunlight_propagates = true,
    drawtype = "allfaces_optional",
	new_style_leaves = 1,
    tiles = {"snowberry_spring.png"},
    groups = {oddly_breakable_by_hand=3}
}
minetest.register_node("ubcv_campus_objects:snowberry_spring",node_def)

local node_def = {
    sunlight_propagates = true,
    drawtype = "allfaces_optional",
	new_style_leaves = 1,
    tiles = {"snowberry_summer.png"},
    groups = {oddly_breakable_by_hand=3}
}
minetest.register_node("ubcv_campus_objects:snowberry_summer",node_def)

local node_def = {
    sunlight_propagates = true,
    drawtype = "allfaces_optional",
	new_style_leaves = 1,
    tiles = {"snowberry_winter.png"},
    groups = {oddly_breakable_by_hand=3}
}
minetest.register_node("ubcv_campus_objects:snowberry_winter",node_def)
