
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
	{"TropicalSunnyDay", "#f1f4ee", 1.0, { density = 0.25, color = "#fffffffb", ambient = "#000000",
		height = 120, thickness = 8, speed = {x = -2, y = 0},}},
}

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
		player:set_attribute("skybox:skybox", sky[1])
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
	player:set_sun({visible = true, sunrise_visible = true})
	player:set_moon({visible = true})
	player:set_stars({visible = true})

	player:set_attribute("skybox:skybox", "off")
end

--
-- registrations and load/save code
--

minetest.register_on_joinplayer(function(player)
	local sky = player:get_attribute("skybox:skybox")
	-- Default to TropicalSunnyDay onjoin
	skybox.clear(player)
	skybox.set(player, 1)
end)
