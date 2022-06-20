forestry_tools = { path = minetest.get_modpath("forestry_tools") }

local priv_table = { shout = true }
function forestry_tools.check_perm(player)
	return minetest.check_player_privs(player:get_player_name(), priv_table)
end

dofile(forestry_tools.path .. "/measuring_tape.lua")
dofile(forestry_tools.path .. "/compass.lua")
dofile(forestry_tools.path .. "/clinometer.lua")
dofile(forestry_tools.path .. "/wedgeprism.lua")
dofile(forestry_tools.path .. "/rangefinder.lua")
