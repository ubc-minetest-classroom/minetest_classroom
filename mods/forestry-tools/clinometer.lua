local S = forestry_tools.S
local HUD_showing = false
local curr_pitch = 0
local bg_angle

local mainAngleHud = mhud.init()
local function show_main_angle_hud(player)
	mainAngleHud:add(player, "angle", {
		hud_elem_type = "text",
		text = "",
		alignment = {x = "left", y = "centre"},
		position = {x = 0.7, y = 0.5}, 
		scale = {x = 6.5, y = 6.5},
		offset = {x = -40, y = -4}
	})
end

local oneUpHud = mhud.init()
local function show_one_up_hud(player)
	oneUpHud:add(player, "oneup", {
		hud_elem_type = "text",
		text = "",
		alignment = {x = "left", y = "centre"},
		position = {x = 0.7, y = 0.5}, 
		scale = {x = 6.5, y = 6.5},
		offset = {x = -40, y = -70}
	})
end

local twoUpHud = mhud.init()
local function show_two_up_hud(player)
	twoUpHud:add(player, "twoup", {
		hud_elem_type = "text",
		text = "",
		alignment = {x = "left", y = "centre"},
		position = {x = 0.7, y = 0.5}, 
		scale = {x = 6.5, y = 6.5},
		offset = {x = -40, y = -135}
	})
end

local oneDownHud = mhud.init()
local function show_one_down_hud(player)
	oneDownHud:add(player, "onedown", {
		hud_elem_type = "text",
		text = "",
		alignment = {x = "left", y = "centre"},
		position = {x = 0.7, y = 0.5}, 
		scale = {x = 6.5, y = 6.5},
		offset = {x = -40, y = 62}
	})
end

local twoDownHud = mhud.init()
local function show_two_down_hud(player)
	twoDownHud:add(player, "twodown", {
		hud_elem_type = "text",
		text = "",
		alignment = {x = "left", y = "centre"},
		position = {x = 0.7, y = 0.5}, 
		scale = {x = 6.5, y = 6.5},
		offset = {x = -40, y = 125}
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

local function show_angle_huds(player)
	show_bg_hud(player)
	show_main_angle_hud(player)
	show_one_up_hud(player)
	show_two_up_hud(player)
	show_one_down_hud(player)
	show_two_down_hud(player)
	HUD_showing = true
end

local function hide_huds(player)
	bgHud:remove_all()
	mainAngleHud:remove_all()
	oneUpHud:remove_all()
	twoUpHud:remove_all()
	oneDownHud:remove_all()
	twoDownHud:remove_all()
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
			hide_huds(player)
		else
			show_angle_huds(player)
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

local function update_angles(player)
	if curr_pitch >= 80 and curr_pitch < 89 then
		update_hud(player, twoUpHud, "twoup", "")  
	elseif curr_pitch >= 89 then
		update_hud(player, oneUpHud, "oneup", "") 
	elseif curr_pitch <= -80 and curr_pitch > -89 then
		update_hud(player, twoDownHud, "twodown", "") 
	elseif curr_pitch <= -89 then
		update_hud(player, oneDownHud, "onedown", "") 
	else 
		update_hud(player, oneUpHud, "oneup", tostring(curr_pitch + 10))
		update_hud(player, twoUpHud, "twoup", tostring(curr_pitch + 20))
		update_hud(player, oneDownHud, "onedown", tostring(curr_pitch - 10))
		update_hud(player, twoDownHud, "twodown", tostring(curr_pitch - 20)) 
	end

	update_hud(player, bgHud, "background", bg_angle) 
	update_hud(player, mainAngleHud, "angle", tostring(curr_pitch)) 
end


minetest.register_globalstep(function(dtime)
	local players  = minetest.get_connected_players()
	for i,player in ipairs(players) do

		if HUD_showing then
			local pitch = -1 * math.deg(player:get_look_vertical())
			curr_pitch = math.floor(pitch)

			if curr_pitch >= 70 then 
				if curr_pitch < 80 then
					bg_angle = "70"
				elseif curr_pitch >= 80 and curr_pitch < 89 then
					bg_angle = "80"
				elseif curr_pitch >= 89 then
					bg_angle = "90"
				end
			elseif curr_pitch <= -70 then
				if curr_pitch > -80 then
					bg_angle = "70.1"
				elseif curr_pitch <= -80 and curr_pitch > -89 then
					bg_angle = "80.1"
				elseif curr_pitch <= -89 then
					bg_angle = "90.1"
				end
			else 
				bg_angle = "0"
			end

			update_angles(player) 
		end
	end
end)



-- -- IN-PROGRESS: show yaw (horizontal angle) and pitch (vertical viewing angle) in degrees.

-- -- <!> This is important, since calls to S() are made in this file - without this, the game will crash
-- local S = forestry_tools.S
-- local HUD_showing = false; 



-- minetest.register_tool("forestry_tools:clinometer", {
-- 	description = S("Yaw (horizontal) and Sextant (vertical)"),
-- 	_tt_help = S("Shows your pitch"),
-- 	_doc_items_longdesc = S("It shows your pitch (vertical viewing angle) in degrees. and your sextant (horizontal viewing angle) in degrees"),
-- 	_doc_items_usagehelp = use,
-- 	wield_image = "clinometer.png",
-- 	inventory_image = "clinometer.png",
-- 	groups = { disable_repair = 1 },
-- 	_mc_tool_privs = forestry_tools.priv_table,

			
-- 		-- On left-click
--     on_use = function(itemstack, player, pointed_thing)
-- 		if HUD_showing then
-- 			clinHud:remove_all()
-- 			HUD_showing = false
-- 		else
-- 			show_clin_hud(player)
-- 		end
-- 	end,
		
--     	-- Destroy the item on_drop to keep things tidy
-- 	on_drop = function (itemstack, dropper, pos)
-- 	end
-- })



-- minetest.register_alias("clinometer", "forestry_tools:clinometer")
-- clinometer = minetest.registered_aliases[clinometer] or clinometer






	
-- -- minetest.register_on_newplayer(clin_hud.init_hud)
-- -- minetest.register_on_joinplayer(clin_hud.init_hud)

-- -- minetest.register_on_leaveplayer(function(player)
-- -- 	clin_hud.playerhuds[player:get_player_name()] = nil
-- -- end)


-- local clinHud = mhud.init()
-- local function show_clin_hud(player)
-- 	clinHud:add(player, "clinometer", {
-- 		hud_elem_type = "text",
-- 		text = "",
-- 		number =  "0xFF0000",
-- 		position={x = 0.5, y = 0}, 
-- 		scale={x = 10, y = 10},
-- 		offset = {x = 0, y = 15},
-- 		z_index = 0,
			
-- 	})
-- end



-- function update_hud_displays(player)
-- 	local toDegrees = 180/math.pi
-- 	local name = player:get_player_name()
-- 	local clinometer
-- 	local pos = vector.round(player:get_pos())
	
	
-- 	if tool_active(player, "forestry_tools:clinometer") then 
-- 		clinometer = true 
-- 	end 
	
	
	
-- 	-- Minetest goes counter clokwise
-- 	local yaw = 360 - player:get_look_horizontal()*toDegrees
-- 	local pitch = player:get_look_vertical()*toDegrees
	
-- 	if (clinometer) then
-- 		str_angles = S("Yaw: @1°, pitch: @2°", string.format("%.1f", yaw), string.format("%.1f", pitch))
-- 	end
	

-- 	if str_angles ~= "" then 
-- 		player:hud_change(name, "text", strs_angles)
-- 	end
-- end
	
-- 	-- issues w updating HUD 
	  


-- minetest.register_globalstep(function(dtime)
-- 	local players  = minetest.get_connected_players()
-- 	for i,player in ipairs(players) do

-- 		if HUD_showing then
-- 			-- Remove HUD when player is no longer wielding the clinometer
-- 			if player:get_wielded_item():get_name() ~= "forestry_tools:clinometer" then
-- 				clinHud:remove_all()
-- 				HUD_showing = false
-- 			else
				

-- 			-- not sure(?)
-- 			update_hud_displays(player)
    
-- 		end

			
-- 		end
-- 	end
	
-- end)
	
	
-- -- have to account for change of player FOV, direction, update HUD to display

-- -- <!> These two lines currently crash the game - please replace with functions if they are intended to be used
-- --minetest.register_on_newplayer(clinHud)
-- --minetest.register_on_joinplayer(clinHud)



-- -- local clin_hud = {}
-- -- clin_hud.playerhuds = {}
-- -- clin_hud.settings = {}
-- -- clin_hud.settings.hud_pos = { x = 0.5, y = 0 }
-- -- clin_hud.settings.hud_offset = { x = 0, y = 15 }
-- -- clin_hud.settings.hud_alignment = { x = 0, y = 0 }

-- -- local set = tonumber(minetest.settings:get("clin_hud_pos_x"))
-- -- if set then clin_hud.settings.hud_pos.x = set end
-- -- set = tonumber(minetest.settings:get("clin_hud_pos_y"))
-- -- if set then clin_hud.settings.hud_pos.y = set end
-- -- set = tonumber(minetest.settings:get("clin_hud_offset_x"))
-- -- if set then clin_hud.settings.hud_offset.x = set end
-- -- set = tonumber(minetest.settings:get("clin_hud_offset_y"))
-- -- if set then clin_hud.settings.hud_offset.y = set end
-- -- set = minetest.settings:get("clin_hud_alignment")
-- -- if set == "left" then
-- -- 	clin_hud.settings.hud_alignment.x = 1
-- -- elseif set == "center" then
-- -- 	clin_hud.settings.hud_alignment.x = 0
-- -- elseif set == "right" then
-- -- 	clin_hud.settings.hud_alignment.x = -1
-- -- end

-- -- local lines = 4 -- # of HUD Lines


-- -- DIsplay player horizontal and vertical It shows you your pitch (vertical viewing angle) in degrees.



-- -- function init_hud(player)
-- -- 	update_automapper(player)
-- -- 	local name = player:get_player_name()
-- -- 	playerhuds[name] = {}
-- -- 	for i=1, o_lines do
-- -- 			playerhuds[name]["o_line"..i] = player:hud_add({
-- -- 			hud_elem_type = "text",
-- -- 			text = "",
-- -- 			position = clin_hud.settings.hud_pos,
-- -- 			offset = { x = clin_hud.settings.hud_offset.x, y = clin_hud.settings.hud_offset.y + 20*(i-1) },
-- -- 			alignment = clin_hud.settings.hud_alignment,
-- -- 			number = 0xFFFFFF,
-- -- 			scale= { x = 100, y = 20 },
-- -- 			z_index = 0,
-- -- 		})
-- -- 	end
-- -- end


-- -- function clin_hud.update_automapper(player)
-- -- 	if clin_hud.tool_active(player, "forestry_tools:clinometer") or minetest.is_creative_enabled(player:get_player_name()) then
-- -- 		player:hud_set_flags({minimap = true, minimap_radar = true})
	
-- -- 	else
-- -- 		player:hud_set_flags({minimap = false, minimap_radar = false})
-- -- 	end
-- -- end

	




