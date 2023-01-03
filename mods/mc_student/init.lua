-- Global variables
mc_student = {
	path = minetest.get_modpath("mc_student"),
	teachers = {},
	students = {},
	markers = {},
	meta = minetest.get_mod_storage(),
	hud = mhud.init(),
	fs_context = {}
}

dofile(mc_student.path .. "/functions.lua")
dofile(mc_student.path .. "/callbacks.lua")
dofile(mc_student.path .. "/tools.lua")
dofile(mc_student.path .. "/gui.lua")