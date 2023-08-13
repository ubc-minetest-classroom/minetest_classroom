
--[[

Copyright (C) 2017 - Auke Kok <sofar@foo-projects.org>

"skybox" is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2.1
of the license, or (at your option) any later version.

]]--

--
-- Builtin sky box textures and color/shadings, clouds
--

local skies = {
	{"DarkStormy", "#1f2226", 0.5, { density = 0.5, color = "#aaaaaae0", ambient = "#000000",
		height = 64, thickness = 32, speed = {x = 6, y = -6},}},
	{"CloudyLightRays", "#5f5f5e", 0.9, { density = 0.4, color = "#efe3d5d0", ambient = "#000000",
		height = 96, thickness = 24, speed = {x = 4, y = 0},}},
	{"FullMoon", "#24292c", 0.2, { density = 0.25, color = "#ffffff80", ambient = "#404040",
		height = 140, thickness = 8, speed = {x = -2, y = 2},}},
	{"SunSet", "#72624d", 0.4, { density = 0.2, color = "#f8d8e8e0", ambient = "#000000",
		height = 120, thickness = 16, speed = {x = 0, y = -2},}},
	{"ThickCloudsWater", "#a57850", 0.8, { density = 0.35, color = "#ebe4ddfb", ambient = "#000000",
		height = 80, thickness = 32, speed = {x = 4, y = 3},}},
	{"TropicalSunnyDay", "#f1f4ee", 1.0, { density = 0.25, color = "#fffffffb", ambient = "#000000",
		height = 120, thickness = 8, speed = {x = -2, y = 0},}},
}
local skymap = {["None"] = 0}
for i, def in pairs(skies) do
	skymap[def[1]] = i
end

--
-- API
--

skybox = {}

skybox.set = function(player, number)
	if number == 0 then
		skybox.clear(player)
	else
		local sky = skies[number]
		player:override_day_night_ratio(sky[3])
		local textures = {
			sky[1] .. "Up.jpg",
			sky[1] .. "Down.jpg",
			sky[1] .. "Front.jpg",
			sky[1] .. "Back.jpg",
			sky[1] .. "Left.jpg",
			sky[1] .. "Right.jpg",
		}
		if player.get_sky_color ~= nil then
			player:set_sky({
				base_color = sky[2],
				type = "skybox",
				textures = textures,
				clouds = true
			})
			player:set_sun({visible = false, sunrise_visible = false})
			player:set_moon({visible = false})
			player:set_stars({visible = false})
		else
			player:set_sky(sky[2], "skybox", textures, true)
		end
		player:set_clouds(sky[4])
		player:get_meta():set_string("skybox:skybox", sky[1])
	end
end

skybox.clear = function(player)
	player:override_day_night_ratio(nil)
	if player.get_sky_color ~= nil then
		player:set_sky({base_color = "white", type = "regular"})
	else
		player:set_sky("white", "regular")
	end
	player:set_clouds({
		density = 0.4,
		color = "#fff0f0e5",
		ambient = "#000000",
		height = 120,
		thickness = 16,
		speed = {x = 0, y = -2},
	})
	player:set_sun({visible = true, sunrise_visible = true, texture = ""})
	player:set_moon({visible = true, texture = ""})
	player:set_stars({visible = true})

	player:get_meta():set_string("skybox:skybox", "off")
end

skybox.add = function(def)
	table.insert(skies, def)
	skymap[def[1]] = #skies
end

skybox.get_skies = function()
	return table.copy(skies)
end

skybox.get_sky_number = function(name)
	return skymap[name]
end

skybox.get_default_sky = function()
	return skies[6][1]
end
