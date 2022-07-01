forestry_tools = { path = minetest.get_modpath("forestry_tools") }

function check_perm(player)
	return minetest.check_player_privs(player:get_player_name(), { shout = true })
end

dofile(forestry_tools.path .. "/measuring_tape.lua")
dofile(forestry_tools.path .. "/compass.lua")
