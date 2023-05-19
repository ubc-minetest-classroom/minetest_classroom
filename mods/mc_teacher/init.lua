mc_teacher = {
    teachers = {},
    students = {},
    meta = minetest.get_mod_storage(),
    path = minetest.get_modpath("mc_teacher"),
    fs_context = {},
    restart_scheduled = {},
    TABS = {
        OVERVIEW = "1",
        CLASSROOMS = "2",
        MAP = "3",
        PLAYERS = "4",
        MODERATION = "5",
        REPORTS = "6",
        HELP = "7",
        SERVER = "8" -- TODO: make dynamic for easier modification of notebook
    },
    MODES = {
        NONE = "1",
        SIZE = "2",
        SCHEMATIC = "3",
        TWIN = "4"
    }
}

-- Source files
dofile(mc_teacher.path .. "/functions.lua") 
dofile(mc_teacher.path .. "/callbacks.lua") 
dofile(mc_teacher.path .. "/tools.lua") 
dofile(mc_teacher.path .. "/gui.lua")

schematicManager.registerSchematicPath("vancouver_osm", minetest.get_modpath("mc_teacher") .. "/maps/vancouver_osm")
schematicManager.registerSchematicPath("MKRF512_all", minetest.get_modpath("mc_teacher") .. "/maps/MKRF512_all")
schematicManager.registerSchematicPath("MKRF512_aspect", minetest.get_modpath("mc_teacher") .. "/maps/MKRF512_aspect")
schematicManager.registerSchematicPath("MKRF512_dtm", minetest.get_modpath("mc_teacher") .. "/maps/MKRF512_dtm")
schematicManager.registerSchematicPath("MKRF512_hillshade", minetest.get_modpath("mc_teacher") .. "/maps/MKRF512_hillshade")
schematicManager.registerSchematicPath("MKRF512_slope", minetest.get_modpath("mc_teacher") .. "/maps/MKRF512_slope")
schematicManager.registerSchematicPath("MKRF512_tpi", minetest.get_modpath("mc_teacher") .. "/maps/MKRF512_tpi")