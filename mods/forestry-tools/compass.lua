
local HUD_showing = false

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

local hud = mhud.init()
local function show_compass_hud(player)
	hud:add(player, "compass", {
		hud_elem_type = "image",
		text = "compass_0.png",
		position={x = 0.5, y = 0.5}, 
		scale={x = 10.2, y = 10.2}
	})

	HUD_showing = true
end

local bezelHud = mhud.init()
local function show_bezel_hud(player)
	bezelHud:add(player, "bezel", {
		hud_elem_type = "image",
		text = "bezel_0.png",
		position={x = 0.5, y = 0.5}, 
		scale={x = 10, y = 10},
		offset = {x = -5.8, y = -3}
	})

	HUD_showing = true
end

local adjustments_menu = {
	"formspec_version[5]",
	"size[6,7]",
	"textarea[1.7,0.2;3,0.5;;;Compass Settings]",
	"textarea[0.5,1.3;5,1;declination;Set Magnetic Declination;]",
	"textarea[0.5,3;5,1;azimuth;Set Azimuth;]",
	"button_exit[4.2,5.9;1.5,0.8;exit;Exit]"
}

local function show_adjustments_menu(player) 
	if HUD_showing then
		hud:remove_all()
		bezelHud:remove_all()
		HUD_showing = false
	end

	local pname = player:get_player_name()
	minetest.show_formspec(pname, "compass:adjustments_menu", table.concat(adjustments_menu, ""))
end

minetest.register_tool("forestry_tools:compass" , {
	description = "Compass",
	inventory_image = "compass_0.png",
    stack_max = 1,
	liquids_pointable = true,

	-- On left-click
    on_use = function(itemstack, player, pointed_thing)
		show_compass_hud(player)
		show_bezel_hud(player)
	end,

	on_place = function(itemstack, player, pointed_thing)
		show_adjustments_menu(player)
	end,

	-- Destroy the item on_drop to keep things tidy
	on_drop = function (itemstack, dropper, pos)
		minetest.set_node(pos, {name="air"})
	end,
})

minetest.register_alias("compass", "forestry_tools:compass")
compass = minetest.registered_aliases[compass] or compass

local images = {
		"compass_0.png",
		"compass_1.png",
		"compass_2.png",
		"compass_3.png",
		"compass_4.png",
		"compass_5.png",
		"compass_6.png",
		"compass_7.png",
		"compass_8.png",
		"compass_9.png",
		"compass_10.png",
		"compass_11.png",
		"compass_12.png",
		"compass_13.png",
		"compass_14.png",
		"compass_15.png",
}


minetest.register_globalstep(function(dtime)
	local players  = minetest.get_connected_players()
	for i,player in ipairs(players) do

		if HUD_showing then
			if player:get_wielded_item():get_name() ~= "forestry_tools:compass" then
				hud:remove_all()
				bezelHud:remove_all()
				HUD_showing = false
			else
				local dir = player:get_look_horizontal()
				local angle_relative = math.deg(dir)
				local compass_image
				local adjustment, transformation

				if angle_relative < 90 then
					adjustment = 0
					transformation = 0
				elseif angle_relative < 180 then
					adjustment = 90
					transformation = 270
				elseif angle_relative < 270 then
					adjustment = 180
					transformation = 180
				elseif angle_relative < 360 then
					adjustment = 270
					transformation = 90
				end

				if angle_relative % 45 == 0 then
					compass_image = 4.5
				else
					compass_image = math.floor((angle_relative - adjustment)/10)
				end

				local img = "compass_" .. compass_image .. ".png" .. "^[transformR" .. transformation
				hud:change(player, "compass", {
					text = img
				})
			end
		end
	end
end)

