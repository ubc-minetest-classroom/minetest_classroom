mc_teacher = {
    teachers = {},
    students = {},
    meta = minetest.get_mod_storage(),
    path = minetest.get_modpath("mc_teacher"),
    marker_expiry = 120,
    fs_spacer = 0.6,
    fs_t_spacer = 0.55,
    fs_context = {},
    restart_scheduled = {},
    -- named constants
    TABS = {
        OVERVIEW = "1",
        CLASSROOMS = "2",
        MAP = "3",
        PLAYERS = "4",
        MODERATION = "5",
        REPORTS = "6",
        HELP = "7",
        SERVER = "8", -- TODO: make dynamic for easier modification of notebook
    },
    CTAB = {PUBLIC = "1", PRIVATE = "2", HIDDEN = "3"},
    PTAB = {STUDENTS = "1", TEACHERS = "2", CLASSROOM = "3", N = 3},
    STAB = {BANNED = "1", ONLINE = "2", MODS = "3"},
    ROLES = {
        STUDENT = "1",
        TEACHER = "2",
        ADMIN = "3",
    },
    --MODES = {EMPTY = "1", SCHEMATIC = "2", TWIN = "3"},
    MODES = {FLAT = "1", RANDOM = "2", SCHEMATIC = "3", LIDAR = "4"},
    PMODE = {SELECTED = "1", TAB = "2", ALL = "3"},
    M = {
        MODE = {SERVER_ANON = "1", SERVER_PLAYER = "2", PLAYER = "3"},
        RECIP = {
            STUDENT = "students",
            TEACHER = "teachers",
            ADMIN = "admins",
            ALL = "everyone",
        }
    },
    R = {
        GEN = {NONE = "1", V1 = "2", V2 = "3", DNR = "4"},
        DEC = {NONE = "1", V1 = "2", V2 = "3", BIOME = "4"},
        GEN_MAP = {["1"] = "nil", ["2"] = "v1", ["3"] = "v2", ["4"] = "dnr"},
        DEC_MAP = {["1"] = "nil", ["2"] = "v1", ["3"] = "v2", ["4"] = "biomegen"},
        CAT_KEY = {OPEN = "1", RESTRICTED = "2", SPAWN = "3", PRIVATE = "4"},
        CAT_MAP = {["1"] = "open", ["2"] = "restricted", ["3"] = "spawn", ["4"] = "private"},
        CAT_RMAP = {open = "1", restricted = "2", spawn = "3", private = "4"},
    },
    T_INDEX = {
        ["30 seconds"] = {i = 1, t = 30},
        ["1 minute"] = {i = 2, t = 60},
        ["5 minutes"] = {i = 3, t = 300},
        ["10 minutes"] = {i = 4, t = 600},
        ["15 minutes"] = {i = 5, t = 900},
        ["30 minutes"] = {i = 6, t = 1800},
        ["45 minutes"] = {i = 7, t = 2700},
        ["1 hour"] = {i = 8, t = 3600},
        ["2 hours"] = {i = 9, t = 7200},
        ["3 hours"] = {i = 10, t = 10800},
        ["6 hours"] = {i = 11, t = 21600},
        ["12 hours"] = {i = 12, t = 43200},
        ["24 hours"] = {i = 13, t = 86400}
    }
}

-- Source files
dofile(mc_teacher.path .. "/functions.lua") 
dofile(mc_teacher.path .. "/callbacks.lua") 
dofile(mc_teacher.path .. "/tools.lua") 
dofile(mc_teacher.path .. "/gui.lua")