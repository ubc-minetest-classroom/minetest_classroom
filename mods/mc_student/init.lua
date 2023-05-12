-- Global variables
mc_student = {
	path = minetest.get_modpath("mc_student"),
	teachers = {},
	students = {},
	markers = {},
	meta = minetest.get_mod_storage(),
	hud = mhud.init(),
	fs_context = {},
	marker_expiry = 30,
	TABS = {
		OVERVIEW = "1",
		CLASSROOMS = "2",
		MAP = "3",
		APPEARANCE = "4",
		HELP = "5"
	},
	REPORT_TYPE = {
		"Server Issue",
		"Misbehaving Player",
		"Question",
		"Suggestion",
		"Other"
	}
}

dofile(mc_student.path .. "/functions.lua")
dofile(mc_student.path .. "/callbacks.lua")
dofile(mc_student.path .. "/tools.lua")
dofile(mc_student.path .. "/gui.lua")