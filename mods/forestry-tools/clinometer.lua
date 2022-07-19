local HUD_showing = false
local curr_pitch, curr_percent = 0
local bg_angle
local degreePlus0Hud, degreePlus10Hud, degreePlus20Hud, degreeMinus10Hud, degreeMinus20Hud = mhud.init(), mhud.init(), mhud.init(), mhud.init(), mhud.init()
local percentPlus0Hud, percentPlus10Hud, percentPlus20Hud, percentPlus30Hud, percentPlus40Hud = mhud.init(), mhud.init(), mhud.init(), mhud.init(), mhud.init()
local percentMinus10Hud, percentMinus20Hud, percentMinus30Hud, percentMinus40Hud = mhud.init(), mhud.init(), mhud.init(), mhud.init()

-- local measurementHuds = {}

-- table.insert(measurementHuds, { hudObject = degreePlus0Hud, string = "degreePlus0", xAlignment = "left", xOffset = -40, yOffset = -4 })
-- table.insert(measurementHuds, { hudObject = degreePlus10Hud, string = "degreePlus10", xAlignment = "left", xOffset = -40, yOffset = -70 })
-- table.insert(measurementHuds, { hudObject = degreePlus20Hud, string = "degreePlus20", xAlignment = "left", xOffset = -40, yOffset = -135 })
-- table.insert(measurementHuds, { hudObject = degreeMinus10Hud, string = "degreeMinus10", xAlignment = "left", xOffset = -40, yOffset = 62 })
-- table.insert(measurementHuds, { hudObject = degreeMinus20Hud, string = "degreeMinus20", xAlignment = "left", xOffset = -40, yOffset = 125 })

-- local degreeHuds = {
-- 	plus0 = {
-- 		hudObject = degreePlus0Hud,
-- 		title = "degreePlus0",
-- 		xAlignment = "left",
-- 		xOffset = -40,
-- 		yOffset = -4
-- 	},
-- 	plus10 = {
-- 		hudObject = degreePlus10Hud,
-- 		title = "degreePlus10",
-- 		xAlignment = "left",
-- 		xOffset = -40,
-- 		yOffset = -70
-- 	},
-- 	plus20 = {
-- 		hudObject = degreePlus20Hud,
-- 		title = "degreePlus20",
-- 		xAlignment = "left",
-- 		xOffset = -40,
-- 		yOffset = -135
-- 	},
-- 	minus10 = {
-- 		hudObject = degreeMinus10Hud,
-- 		title = "degreeMinus10",
-- 		xAlignment = "left",
-- 		xOffset = -40,
-- 		yOffset = 62
-- 	},
-- 	minus20 = {
-- 		hudObject = degreeMinus20Hud,
-- 		title = "degreeMinus20",
-- 		xAlignment = "left",
-- 		xOffset = -40,
-- 		yOffset = 125
-- 	}
-- }

local function show_measurement_hud(player, hudName, string, xAlignment, xOffset, yOffset)
	hudName:add(player, string, {
		hud_elem_type = "text",
		text = "",
		alignment = {x = xAlignment, y = "centre"},
		position = {x = 0.7, y = 0.5}, 
		scale = {x = 6.5, y = 6.5},
		offset = {x = xOffset, y = yOffset}
	})
end

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

local function show_all_huds(player)
	show_bg_hud(player)

	-- for _,hud in ipairs(degreeHuds) do
	-- 	show_measurement_hud(player, hud.hudObject, hud.title, hud.xAlignment, hud.xOffset, hud.yOffset)
	-- end

	show_measurement_hud(player, degreePlus0Hud, "degreePlus0", "left", -40, -4)
	show_measurement_hud(player, degreePlus10Hud, "degreePlus10", "left", -40, -70)
	show_measurement_hud(player, degreePlus20Hud, "degreePlus20", "left", -40, -135)
	show_measurement_hud(player, degreeMinus10Hud, "degreeMinus10", "left", -40, 62)
	show_measurement_hud(player, degreeMinus20Hud, "degreeMinus20", "left", -40, 125)

	show_measurement_hud(player, percentPlus0Hud, "percentPlus0", "right", 35, -4)
	show_measurement_hud(player, percentPlus10Hud, "percentPlus10", "right", 35, -43)
	show_measurement_hud(player, percentPlus20Hud, "percentPlus20", "right", 35, -83)
	show_measurement_hud(player, percentPlus30Hud, "percentPlus30", "right", 35, -120)
	show_measurement_hud(player, percentPlus40Hud, "percentPlus40", "right", 35, -160)
	show_measurement_hud(player, percentMinus10Hud, "percentMinus10", "right", 35, 37)
	show_measurement_hud(player, percentMinus20Hud, "percentMinus20", "right", 35, 75)
	show_measurement_hud(player, percentMinus30Hud, "percentMinus30", "right", 35, 115)
	show_measurement_hud(player, percentMinus40Hud, "percentMinus40", "right", 35, 153)
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
			show_all_huds(player)
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

