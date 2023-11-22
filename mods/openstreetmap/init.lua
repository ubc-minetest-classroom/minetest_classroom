-- Local variables
local worldpath = minetest.get_worldpath()
local modname = minetest.get_current_modname()
local MOD_PATH = minetest.get_modpath(modname)

-- Global variables
openstreetmap = {}
openstreetmap.meta = minetest.get_mod_storage()
openstreetmap.mod_path = MOD_PATH
openstreetmap.hud_idx = nil
openstreetmap.pointed_thing_pos = nil
openstreetmap.temp_node_pos = nil
openstreetmap.select_nodes_counter = 0
openstreetmap.NODE_ITEMSTRINGS = {}
openstreetmap.fill_depth = 0
openstreetmap.fill_enclosures = true
openstreetmap.write_metadata = false
openstreetmap.temp = {
    sizeX = nil,
    sizeY = nil,
    sizeZ = nil,
    min_easting = nil,
    min_northing = nil,
    utm_zone_min = nil,
    nodedata = nil,
    waydata = nil,
    relationdata = nil,
    realmID = nil,
    node_value_texture_table = {},
    node_value_extrusion_table = {},
    node_value_itemstring_table = {},
    node_value_itemstring_list = {},
    way_value_texture_table = {},
    way_value_extrusion_table = {},
    way_value_itemstring_table = {},
    way_value_itemstring_list = {},
}
openstreetmap.osm_textures = {
    water = "osm_water.png",
    art_installation = "osm_art_installation.png",
    artwork = "osm_artwork.png",
    attached_rock_boulder = "osm_attached_rock_boulder.png",
    baseball_field = "osm_baseball_field.png",
    basketball_court = "osm_basketball_court.png",
    bay = "osm_bay.png",
    beach = "osm_beach.png",
    bench = "osm_bench.png",
    bicycle_parking = "osm_bicycle_parking.png",
    bollard = "osm_bollard.png",
    bookstore = "osm_bookstore.png",
    botanical_garden = "osm_botanical_garden.png",
    building = "osm_building.png",
    christian_church = "osm_christian_church.png",
    coastline = "osm_coastline.png",
    community_center = "osm_community_center.png",
    construction_area = "osm_construction_area.png",
    crossing_with_pedestrian_signals = "osm_crossing_with_pedestrian_signals.png",
    dog_park = "osm_dog_park.png",
    dormitory = "osm_dormitory.png",
    emergency_phone = "osm_emergency_phone.png",
    entrance_exit = "osm_entrance_exit.png",
    farmland = "osm_farmland.png",
    fence = "osm_fence.png",
    fire_hydrant = "osm_fire_hydrant.png",
    foot_path = "osm_foot_path.png",
    garage_landuse = "osm_garage_landuse.png",
    garbage_dumpster = "osm_garbage_dumpster.png",
    garden = "osm_garden.png",
    garden_center = "osm_garden_center.png",
    gate = "osm_gate.png",
    golf_cartpath = "osm_golf_cartpath.png",
    grass = "osm_grass.png",
    greenhouse = "osm_greenhouse.png",
    hospice = "osm_hospice.png",
    industrial = "osm_industrial.png",
    information_board = "osm_information_board.png",
    lateral_water_hazard = "osm_lateral_water_hazard.png",
    library = "osm_library.png",
    line = "osm_line.png",
    locality = "osm_locality.png",
    mail_drop_box = "osm_mail_drop_box.png",
    mailbox = "osm_mailbox.png",
    manhole = "osm_manhole.png",
    map = "osm_map.png",
    marked_crosswalk = "osm_marked_crosswalk.png",
    memorial = "osm_memorial.png",
    minor_unclassified_road = "osm_minor_unclassified_road.png",
    monument = "osm_monument.png",
    multilevel_parking_garage = "osm_multilevel_parking_garage.png",
    museum = "osm_museum.png",
    natural_wood = "osm_natural_wood.png",
    no_exit = "osm_no_exit.png",
    nursery_childcare = "osm_nursery_childcare.png",
    park = "osm_park.png",
    parking_aisle = "osm_parking_aisle.png",
    parking_lot = "osm_parking_lot.png",
    parking_ticket_vending_machine = "osm_parking_ticket_vending_machine.png",
    path = "osm_path.png",
    pedestrian_street = "osm_pedestrian_street.png",
    picnic_table = "osm_picnic_table.png",
    pit_latrine = "osm_pit_latrine.png",
    playground = "osm_playground.png",
    point = "osm_point.png",
    power_generator = "osm_power_generator.png",
    power_pole = "osm_power_pole.png",
    preschool_kindergarten = "osm_preschool_kindergarten.png",
    putting_green = "osm_putting_green.png",
    real_estate_office = "osm_real_estate_office.png",
    research_institute_grounds = "osm_research_institute_grounds.png",
    research_office = "osm_research_office.png",
    residential_area = "osm_residential_area.png",
    residential = "osm_residential.png",
    residential_road = "osm_residential_road.png",
    road_under_construction = "osm_road_under_construction.png",
    roof = "osm_roof.png",
    rough = "osm_rough.png",
    rowhouses = "osm_rowhouses.png",
    running_track = "osm_running_track.png",
    sand_trap = "osm_sand_trap.png",
    sculpture = "osm_sculpture.png",
    secondary_road = "osm_secondary_road.png",
    service_road = "osm_service_road.png",
    sidewalk = "osm_sidewalk.png",
    smoke_area = "osm_smoke_area.png",
    soccer_field = "osm_soccer_field.png",
    sport_center_complex = "osm_sport_center_complex.png",
    sport_pitch = "osm_sport_pitch.png",
    steps = "osm_steps.png",
    stop_sign = "osm_stop_sign.png",
    stream = "osm_stream.png",
    street_lamp = "osm_street_lamp.png",
    substation = "osm_substation.png",
    swimming_pool = "osm_swimming_pool..png",
    telephone = "osm_telephone.png",
    temple = "osm_temple.png",
    tennis_court = "osm_tennis_court.png",
    tertiary_road = "osm_tertiary_road.png",
    theater = "osm_theater.png",
    traffic_signals = "osm_traffic_signals.png",
    tree = "osm_tree.png",
    turning_circle = "osm_turning_circle.png",
    university = "osm_university.png",
    viewpoint = "osm_viewpoint.png",
    waste_basket = "osm_waste_basket.png",
    water = "osm_water.png"
}

-- Load files
dofile(MOD_PATH .. "/functions.lua")
dofile(MOD_PATH .. "/commands.lua")
dofile(MOD_PATH .. "/gui.lua")
dofile(MOD_PATH .. "/nodes.lua")
dofile(MOD_PATH .. "/tags.lua")
dofile(MOD_PATH .. "/spatial_functions.lua")
dofile(MOD_PATH .. "/tools.lua")
dofile(MOD_PATH .. "/entities.lua")

-- Check if HTTP API is available
openstreetmap.http = minetest.request_http_api()
if not openstreetmap.http then
    minetest.log("error", "Failed to access HTTP API")
    return
end

-- List of itemstrings for registered nodes
for node,_ in pairs(minetest.registered_nodes) do
    if mc_core.trim(node) ~= "" then
        table.insert(openstreetmap.NODE_ITEMSTRINGS, mc_core.trim(node))
    end
end
table.sort(openstreetmap.NODE_ITEMSTRINGS)