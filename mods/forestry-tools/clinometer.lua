local HUD_showing = false
local curr_pitch, curr_percent = 0
local bg_angle

----------------------------
--- HUDS FOR DEGREE SIDE ---
----------------------------

local degreePlus0Hud = mhud.init()
local function show_degree_plus_0_hud(player)
	degreePlus0Hud:add(player, "degreePlus0", {
		hud_elem_type = "text",
		text = "",
		alignment = {x = "left", y = "centre"},
		position = {x = 0.7, y = 0.5}, 
		scale = {x = 6.5, y = 6.5},
		offset = {x = -40, y = -4}
	})
end

local degreePlus10Hud = mhud.init()
local function show_degree_plus_10_hud(player)
	degreePlus10Hud:add(player, "degreePlus10", {
		hud_elem_type = "text",
		text = "",
		alignment = {x = "left", y = "centre"},
		position = {x = 0.7, y = 0.5}, 
		scale = {x = 6.5, y = 6.5},
		offset = {x = -40, y = -70}
	})
end

local degreePlus20Hud = mhud.init()
local function show_degree_plus_20_hud(player)
	degreePlus20Hud:add(player, "degreePlus20", {
		hud_elem_type = "text",
		text = "",
		alignment = {x = "left", y = "centre"},
		position = {x = 0.7, y = 0.5}, 
		scale = {x = 6.5, y = 6.5},
		offset = {x = -40, y = -135}
	})
end

local degreeMinus10Hud = mhud.init()
local function show_degree_minus_10_hud(player)
	degreeMinus10Hud:add(player, "degreeMinus10", {
		hud_elem_type = "text",
		text = "",
		alignment = {x = "left", y = "centre"},
		position = {x = 0.7, y = 0.5}, 
		scale = {x = 6.5, y = 6.5},
		offset = {x = -40, y = 62}
	})
end

local degreeMinus20Hud = mhud.init()
local function show_degree_minus_20_hud(player)
	degreeMinus20Hud:add(player, "degreeMinus20", {
		hud_elem_type = "text",
		text = "",
		alignment = {x = "left", y = "centre"},
		position = {x = 0.7, y = 0.5}, 
		scale = {x = 6.5, y = 6.5},
		offset = {x = -40, y = 125}
	})
end

-----------------------------
--- HUDS FOR PERCENT SIDE ---
-----------------------------

local percentPlus0Hud = mhud.init()
local function show_percent_plus_0_hud(player)
	percentPlus0Hud:add(player, "percentPlus0", {
		hud_elem_type = "text",
		text = "test0",
		alignment = {x = "right", y = "centre"},
		position = {x = 0.7, y = 0.5}, 
		scale = {x = 6.5, y = 6.5},
		offset = {x = 35, y = -4}
	})
end

local percentPlus10Hud = mhud.init()
local function show_percent_plus_10_hud(player)
	percentPlus10Hud:add(player, "percentPlus10", {
		hud_elem_type = "text",
		text = "test10",
		alignment = {x = "right", y = "centre"},
		position = {x = 0.7, y = 0.5}, 
		scale = {x = 6.5, y = 6.5},
		offset = {x = 35, y = -43}
	})
end

local percentPlus20Hud = mhud.init()
local function show_percent_plus_20_hud(player)
	percentPlus20Hud:add(player, "percentPlus20", {
		hud_elem_type = "text",
		text = "test20",
		alignment = {x = "right", y = "centre"},
		position = {x = 0.7, y = 0.5}, 
		scale = {x = 6.5, y = 6.5},
		offset = {x = 35, y = -83}
	})
end

local percentPlus30Hud = mhud.init()
local function show_percent_plus_30_hud(player)
	percentPlus30Hud:add(player, "percentPlus30", {
		hud_elem_type = "text",
		text = "test30",
		alignment = {x = "right", y = "centre"},
		position = {x = 0.7, y = 0.5}, 
		scale = {x = 6.5, y = 6.5},
		offset = {x = 35, y = -120}
	})
end

local percentPlus40Hud = mhud.init()
local function show_percent_plus_40_hud(player)
	percentPlus40Hud:add(player, "percentPlus40", {
		hud_elem_type = "text",
		text = "test40",
		alignment = {x = "right", y = "centre"},
		position = {x = 0.7, y = 0.5}, 
		scale = {x = 6.5, y = 6.5},
		offset = {x = 35, y = -160}
	})
end

local percentMinus10Hud = mhud.init()
local function show_percent_minus_10_hud(player)
	percentMinus10Hud:add(player, "percentMinus10", {
		hud_elem_type = "text",
		text = "test-10",
		alignment = {x = "right", y = "centre"},
		position = {x = 0.7, y = 0.5}, 
		scale = {x = 6.5, y = 6.5},
		offset = {x = 35, y = 37}
	})
end

local percentMinus20Hud = mhud.init()
local function show_percent_minus_20_hud(player)
	percentMinus20Hud:add(player, "percentMinus20", {
		hud_elem_type = "text",
		text = "test-20",
		alignment = {x = "right", y = "centre"},
		position = {x = 0.7, y = 0.5}, 
		scale = {x = 6.5, y = 6.5},
		offset = {x = 35, y = 75}
	})
end

local percentMinus30Hud = mhud.init()
local function show_percent_minus_30_hud(player)
	percentMinus30Hud:add(player, "percentMinus30", {
		hud_elem_type = "text",
		text = "test-30",
		alignment = {x = "right", y = "centre"},
		position = {x = 0.7, y = 0.5}, 
		scale = {x = 6.5, y = 6.5},
		offset = {x = 35, y = 115}
	})
end

local percentMinus40Hud = mhud.init()
local function show_percent_minus_40_hud(player)
	percentMinus40Hud:add(player, "percentMinus40", {
		hud_elem_type = "text",
		text = "test-40",
		alignment = {x = "right", y = "centre"},
		position = {x = 0.7, y = 0.5}, 
		scale = {x = 6.5, y = 6.5},
		offset = {x = 35, y = 153}
	})
end


----------------------
--- HUD MANAGEMENT ---
----------------------

local bgHud = mhud.init()
local function show_bg_hud(player)
	bgHud:add(player, "background", {
		hud_elem_type = "image",
		text = "clinometer_0.png",
		position = {x = 0.7, y = 0.5}, 
		scale = {x = 6.5, y = 6.5},
		offset = {x = -4, y = -4}
	})

	HUD_showing = true
end

local function show_huds(player)
	show_bg_hud(player)
	show_degree_plus_0_hud(player)
	show_degree_plus_10_hud(player)
	show_degree_plus_20_hud(player)
	show_degree_minus_10_hud(player)
	show_degree_minus_20_hud(player)
	show_percent_plus_0_hud(player)
	show_percent_plus_10_hud(player)
	show_percent_plus_20_hud(player)
	show_percent_plus_30_hud(player)
	show_percent_plus_40_hud(player)
	show_percent_minus_10_hud(player)
	show_percent_minus_20_hud(player)
	show_percent_minus_30_hud(player)
	show_percent_minus_40_hud(player)
	HUD_showing = true
end

local function hide_huds()
	bgHud:remove_all()
	degreePlus0Hud:remove_all()
	degreePlus10Hud:remove_all()
	degreePlus20Hud:remove_all()
	degreeMinus10Hud:remove_all()
	degreeMinus20Hud:remove_all()
	percentPlus0Hud:remove_all()
	percentPlus10Hud:remove_all()
	percentPlus20Hud:remove_all()
	percentPlus30Hud:remove_all()
	percentPlus40Hud:remove_all()
	percentMinus10Hud:remove_all()
	percentMinus20Hud:remove_all()
	percentMinus30Hud:remove_all()
	percentMinus40Hud:remove_all()
	HUD_showing = false
end

minetest.register_tool("forestry_tools:clinometer" , {
	description = "Clinometer",
	inventory_image = "clinometer_icon.png",
    stack_max = 1,
	liquids_pointable = true,
	_mc_tool_privs = forestry_tools.priv_table,

	-- On left-click
    on_use = function(itemstack, player, pointed_thing)
		if HUD_showing then
			hide_huds()
		else
			show_huds(player)
		end
	end,

	-- Destroy the item on_drop 
	on_drop = function (itemstack, dropper, pos)
	end,
})

local function update_hud(player, hud, hudname, text) 
	local newtext
	if hudname == "background" then
		newtext = "clinometer_" .. text .. ".png"
	else
		newtext = text
	end

	hud:change(player, hudname, {
		text = newtext
	})
end

local function update_clinometer(player)
	bg_angle = "0"
	local degPlus10, degPlus20, degMinus10, degMinus20 = tostring(curr_pitch + 10), tostring(curr_pitch + 20), tostring(curr_pitch - 10), tostring(curr_pitch - 20)
	local percPlus10, percPlus20, percPlus30, percPlus40 = tostring(curr_percent + 10), tostring(curr_percent + 20), tostring(curr_percent + 30), tostring(curr_percent + 40)
	local percMinus10, percMinus20, percMinus30, percMinus40 = tostring(curr_percent - 10), tostring(curr_percent - 20), tostring(curr_percent - 30), tostring(curr_percent - 40)

	if (curr_percent + 40) < -1000 then
		percPlus10, percPlus20, percPlus30, percPlus40 = "∞", "∞", "∞", "∞"
	elseif (curr_percent + 30) < -1000 then
		percPlus10, percPlus20, percPlus30 = "∞", "∞", "∞"
	elseif (curr_percent + 20) < -1000 then
		percPlus10, percPlus20 = "∞", "∞"
	elseif (curr_percent + 10) > 1000 or (curr_percent + 10) < -1000 then
		percPlus10 = "∞"
	end

	if (curr_percent - 40) > 1000 then
		percMinus10, percMinus20, percMinus30, percMinus40 = "∞", "∞", "∞", "∞"
	elseif (curr_percent - 30) > 1000 then
		percMinus10, percMinus20, percMinus30 = "∞", "∞", "∞"
	elseif (curr_percent - 20) > 1000 then
		percMinus10, percMinus20 = "∞", "∞"
	elseif (curr_percent - 10) > 1000 or (curr_percent - 10) < -1000 then
		percMinus10 = "∞"
	end

	if curr_pitch >= 70 and curr_pitch < 80 then
		bg_angle = "70"
		percPlus40 = ""
	elseif curr_pitch >= 80 and curr_pitch < 89 then
		bg_angle = "80"
		percPlus20, percPlus30, percPlus40 = "", "", ""
		degPlus20 = ""
	elseif curr_pitch >= 89 then
		bg_angle = "90"
		percPlus10, percPlus20, percPlus30, percPlus40 = "", "", "", ""
		degPlus10, degPlus20 = "", ""
	elseif curr_pitch <= -70 and curr_pitch > -80 then
		bg_angle = "70.1"
		percMinus40 = ""
	elseif curr_pitch <= -80 and curr_pitch > -89 then
		bg_angle = "80.1"
		percMinus20, percMinus30, percMinus40 = "", "", ""
		degMinus20 = ""
	elseif curr_pitch <= -89 then
		bg_angle = "90.1"
		percMinus10, percMinus20, percMinus30, percMinus40 = "", "", "", ""
		degMinus10, degMinus20 = "", ""
	end

	update_hud(player, bgHud, "background", bg_angle) 

	if curr_percent > 1000 or curr_percent < -1000 then
		update_hud(player, percentPlus0Hud, "percentPlus0", "∞") 
	else
		update_hud(player, percentPlus0Hud, "percentPlus0", tostring(curr_percent)) 
	end

	update_hud(player, percentPlus10Hud, "percentPlus10", percPlus10)
	update_hud(player, percentPlus20Hud, "percentPlus20", percPlus20)
	update_hud(player, percentPlus30Hud, "percentPlus30", percPlus30)
	update_hud(player, percentPlus40Hud, "percentPlus40", percPlus40)
	update_hud(player, percentMinus10Hud, "percentMinus10", percMinus10)
	update_hud(player, percentMinus20Hud, "percentMinus20", percMinus20) 
	update_hud(player, percentMinus30Hud, "percentMinus30", percMinus30) 
	update_hud(player, percentMinus40Hud, "percentMinus40", percMinus40)

	update_hud(player, degreePlus0Hud, "degreePlus0", tostring(curr_pitch)) 
	update_hud(player, degreePlus10Hud, "degreePlus10", degPlus10)
	update_hud(player, degreePlus20Hud, "degreePlus20", degPlus20)
	update_hud(player, degreeMinus10Hud, "degreeMinus10", degMinus10)
	update_hud(player, degreeMinus20Hud, "degreeMinus20", degMinus20) 
end


minetest.register_globalstep(function(dtime)
	local players  = minetest.get_connected_players()
	for i,player in ipairs(players) do

		if HUD_showing then
			if player:get_wielded_item():get_name() ~= "forestry_tools:clinometer" then
				hide_huds(player)
			else
				local pitch_rad = player:get_look_vertical()
				local pitch = -1 * math.deg(pitch_rad)
				curr_pitch = math.floor(pitch)

				curr_percent = math.floor(-100 * math.tan(pitch_rad))

				update_clinometer(player)
			end
		end
	end
end)

