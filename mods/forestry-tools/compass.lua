local closed_HUD_showing, open_HUD_showing = false, false
local mag_declination, azimuth, curr_azimuth = 0, 0, 0
local curr_needle, curr_bezel = "needle_0.png", "bezel_0.png"

-- Give the compass to any player who joins with adequate privileges or take it away if they do not have them
minetest.register_on_joinplayer(function(player)
    local inv = player:get_inventory()
    if inv:contains_item("main", ItemStack("forestry_tools:compass")) then
        -- Player has the compass
        if check_perm(player) then
            -- The player should have the compass
            return
        else   
            -- The player should not have the compass
            player:get_inventory():remove_item('main', "forestry_tools:compass")
        end
    else
        -- Player does not have the compass
        if check_perm(player) then
            -- The player should have the compass
            player:get_inventory():add_item('main', "forestry_tools:compass")
        else
            -- The player should not have the compass
            return
        end     
    end
end)


---------------------------
--- FORMSPEC MANAGEMENT ---
---------------------------

local adjustments_menu = {
	"formspec_version[5]",
	"size[13,7]",
	"textarea[5,0.2;3,0.5;;;Compass Settings]",
	"textarea[0.5,1.3;5,0.5;declination;Set Magnetic Declination;]",
	"textarea[0.5,2.5;5,0.5;azimuth;Set Azimuth;]",
	"button_exit[0.1,0.1;0.5,0.5;exit;X]",
	"button[8,5.8;3,0.8;save;Adjust Compass]",
	"button[0.5,3.3;3.5,0.8;getAzimuth;Get Current Azimuth]",
	"box[0.5,4.2;5,0.5;#808080]",
	"textarea[0.5,4.2;5,0.5;;;]",
	"image[7.67,1.75;3.8,3.1;needle_0.png]",
	"image[6.9,1.1;5.2,4.3;bezel_0.png]"
}

-- gives the appearance that the formspec remembers the previously set value for the given field
local function remember_field(formTableName, index, preText, newText, postText)
	local textarea = formTableName[index]
	textarea = preText .. newText .. postText
	formTableName[index] = textarea
end

local function show_adjustments_menu(player) 
	remember_field(adjustments_menu, 4, "textarea[0.5,1.3;5,0.5;declination;Set Magnetic Declination;", mag_declination, "]")
	remember_field(adjustments_menu, 5, "textarea[0.5,2.5;5,0.5;azimuth;Set Azimuth;", azimuth, "]")
	minetest.show_formspec(player:get_player_name(), "compass:adjustments_menu", table.concat(adjustments_menu, ""))
end

local function update_formspec_needle(player)
	adjustments_menu[11] = "image[7.67,1.75;3.8,3.1;" .. curr_needle .. "]"
	show_adjustments_menu(player)
end

local function update_formspec_bezel(player)
	adjustments_menu[12] = "image[6.7,1;5.5,4.5;" .. curr_bezel .. "]"
	show_adjustments_menu(player)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local pname = player:get_player_name()

	if formname == "compass:adjustments_menu" then

		if fields.exit then
			adjustments_menu[10] = "textarea[0.5,4.2;5,0.5;;;]"
		end

		if fields.getAzimuth then
			adjustments_menu[10] = "textarea[0.5,4.2;5,0.5;;;" .. math.floor(curr_azimuth) .. "]"
			show_adjustments_menu(player)
		end

		if fields.save then
			local pmeta = player:get_meta()

			if fields.declination ~= "" and tonumber(fields.declination) ~= mag_declination then
				local only_nums = tonumber(fields.declination) ~= nil

				if only_nums then
					local declination_entered = tonumber(fields.declination)
					if math.abs(declination_entered) > 90 or math.abs(declination_entered) < -90 then
						minetest.chat_send_player(pname, minetest.colorize("#ff0000", "Compass - magnetic declination must be a number between -90 and 90"))
					else
						mag_declination = declination_entered
						pmeta:set_int("declination", mag_declination)

						minetest.chat_send_player(pname, minetest.colorize("#00ff00", "Compass - magnetic declination set to " .. fields.declination .. "°"))

						minetest.after(0.1, update_formspec_needle, player)
						minetest.after(0.1, update_formspec_bezel, player)
					end
				else 
					minetest.chat_send_player(pname, minetest.colorize("#ff0000", "Compass - magnetic declination must be a number between -90 and 90"))
				end
			end

			if fields.azimuth ~= "" and tonumber(fields.azimuth) ~= azimuth then
				local only_nums = tonumber(fields.azimuth) ~= nil

				if only_nums then
					local azimuth_entered = tonumber(fields.azimuth)
					if azimuth_entered > 360 or azimuth_entered < 0 then
						minetest.chat_send_player(pname, minetest.colorize("#ff0000", "Compass - azimuth must be a number between 0 and 360"))
					else
						azimuth = azimuth_entered
						pmeta:set_int("azimuth", azimuth)

						minetest.chat_send_player(pname, minetest.colorize("#00ff00", "Compass - azimuth set to " .. fields.azimuth .. "°"))

						minetest.after(0.1, update_formspec_bezel, player)
					end
				else 
					minetest.chat_send_player(pname, minetest.colorize("#ff0000", "Compass - azimuth must be a number between 0 and 360"))
				end
			end

			if tonumber(fields.declination) ~= 0 and string.sub(adjustments_menu[10], 25, 26) ~= "]" then
				adjustments_menu[10] = "textarea[0.5,4.2;5,0.5;;;]"
				show_adjustments_menu(player)
			end
		end

	end
end)

--------------------------------------------
--- HUD MANAGEMENT AND TOOL REGISTRATION ---
--------------------------------------------

local closedHud = mhud.init()
local function show_closed_hud(player)
	closedHud:add(player, "closed", {
		hud_elem_type = "image",
		text = "compass_closed.png",
		position = {x = 0.5, y = 0.5}, 
		scale = {x = 9, y = 9},
		offset = {x = -4, y = -4}
	})

	closed_HUD_showing = true
end

local needleHud = mhud.init()
local function show_needle_hud(player)
	needleHud:add(player, "needle", {
		hud_elem_type = "image",
		text = "needle_0.png",
		position = {x = 0.5285, y = 0.405}, 
		scale = {x = 10.3, y = 10.3},
		offset = {x = -4, y = -4}
	})

	open_HUD_showing = true
end

local bezelHud = mhud.init()
local function show_bezel_hud(player)
	bezelHud:add(player, "bezel", {
		hud_elem_type = "image",
		text = "bezel_0.png",
		position = {x = 0.525, y = 0.4}, 
		scale = {x = 10.2, y = 10.2},
		offset = {x = -4, y = -4}
	})
end

local mirrorHud = mhud.init()
local function show_mirror_hud(player)
	mirrorHud:add(player, "mirror", {
		hud_elem_type = "image",
		text = "compass_mirror.png",
		position = {x = 0.5, y = 0.5}, 
		scale = {x = 10, y = 10},
		offset = {x = -4, y = -4}
	})
end

minetest.register_tool("forestry_tools:compass" , {
	description = "Compass",
	inventory_image = "needle_0.png",
    stack_max = 1,
	liquids_pointable = true,

	-- On left-click
    on_use = function(itemstack, player, pointed_thing)
		local pmeta = player:get_meta()
		mag_declination = pmeta:get_int("declination")
		azimuth = pmeta:get_int("azimuth")

		if not closed_HUD_showing and not open_HUD_showing then
			show_closed_hud(player)
		elseif closed_HUD_showing then
			closedHud:remove_all(player)
			closed_HUD_showing = false

			show_needle_hud(player)
			show_bezel_hud(player)
			show_mirror_hud(player)
		else
			needleHud:remove_all()
			bezelHud:remove_all()
			mirrorHud:remove_all()
			open_HUD_showing = false
		end
	end,

	-- On right-click
	on_place = function(itemstack, placer, pointed_thing)
		if open_HUD_showing then 
			update_formspec_needle(placer)
			update_formspec_bezel(placer)
			show_adjustments_menu(placer) 
		end
	end,

	on_secondary_use = function(itemstack, player, pointed_thing)
		if open_HUD_showing then 
			update_formspec_needle(player)
			update_formspec_bezel(player)
			show_adjustments_menu(player) 
		end
	end,

	-- Destroy the item on_drop 
	on_drop = function (itemstack, dropper, pos)
		minetest.set_node(pos, {name="air"})
	end,
})

minetest.register_alias("compass", "forestry_tools:compass")
compass = minetest.registered_aliases[compass] or compass


minetest.register_globalstep(function(dtime)
	local players  = minetest.get_connected_players()
	for i,player in ipairs(players) do

		if closed_HUD_showing then
			if player:get_wielded_item():get_name() ~= "forestry_tools:compass" then
				closedHud:remove_all()
				closed_HUD_showing = false
			end
		end

		if open_HUD_showing then
			-- Remove HUD when player is no longer wielding the compass
			if player:get_wielded_item():get_name() ~= "forestry_tools:compass" then
				needleHud:remove_all()
				bezelHud:remove_all()
				mirrorHud:remove_all()
				open_HUD_showing = false
			else
				local dir = player:get_look_horizontal()
				local angle_relative = math.deg(dir)

				-- Set magnetic declination
				if mag_declination > 0 and (360 - angle_relative) <= math.abs(mag_declination) then
					angle_relative = mag_declination - (360 - angle_relative)
				elseif mag_declination < 0 and angle_relative <= math.abs(mag_declination) then
					angle_relative = 360 - (math.abs(mag_declination) - angle_relative)
				else 
					angle_relative = math.deg(dir) + mag_declination
				end

				-- Update current azimuth to direction player is facing 
				curr_azimuth = 360 - angle_relative

				-- Needle rotation
				local needle_text = rotate_image(player, "needle", angle_relative)
				curr_needle = needle_text
				needleHud:change(player, "needle", {
					text = needle_text
				})

				-- Rotate bezel based on azimuth and declination set
				local shed_angle
				if mag_declination > 0 and azimuth < mag_declination then
					shed_angle = mag_declination - azimuth
				elseif mag_declination < 0 and (360 - azimuth) < math.abs(mag_declination) then
					shed_angle = mag_declination + azimuth 
				else
					shed_angle = mag_declination + (360 - azimuth)
				end

				local bezel_text = rotate_image(player, "bezel", shed_angle)
				curr_bezel = bezel_text
				bezelHud:change(player, "bezel", {
					text = bezel_text
				})
			end
		end
	end
end)

-- Helper for rotating HUD images. The needle/bezel only show an angle change in intervals of 10, with the exception of 45°, 135°, 225°, 315°
-- e.g. the needle will be in the same position from 0°-9°, then rotate to a new position for 10°-19°, etc. (same system applies to the bezel)
-- Returns the name of the corresponding texture
function rotate_image(player, hudName, referenceAngle) 
	local adjustment, transformation, imgIndex

	if referenceAngle < 90 or referenceAngle == 360 then
		adjustment = 0
		transformation = 0
	elseif referenceAngle < 180 then
		adjustment = 90
		transformation = 270
	elseif referenceAngle < 270 then
		adjustment = 180
		transformation = 180
	elseif referenceAngle < 360 then
		adjustment = 270
		transformation = 90
	end

	if hudName == "bezel" then
		local bx, by, nx, ny = -4, -4, -4, -4

		if adjustment == 90 then
			bx, nx = -1, -10
		elseif adjustment == 180 then
			by, ny, nx = -1, -8, -12
		elseif adjustment == 270 then
			bx, ny, nx = -10, -13, -8
		end

		if bx ~= -4 or by ~= -4 then
			bezelHud:change(player, "bezel", {
				offset = {x = bx, y = by}
			})
		end

		if nx ~= -4 or ny ~= -4 then
			needleHud:change(player, "needle", {
				offset = {x = nx, y = ny}
			})
		end
	end

	if math.floor(referenceAngle % 45) <= 4 and not (math.floor(referenceAngle % 90) <= 9) then
		imgIndex = 4.5
	elseif referenceAngle == 360 then
		imgIndex = 0
	else
		imgIndex = math.floor((referenceAngle - adjustment)/10)
	end

	return hudName .. "_" .. imgIndex .. ".png" .. "^[transformR" .. transformation
end



