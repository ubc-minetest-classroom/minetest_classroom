mhud = {}

function mhud.init()
	return dofile(minetest.get_modpath("mhud").."/mhud.lua")
end
