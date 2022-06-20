local HUD_showing = false

local hud = mhud.init()
local function show_compass_hud(player)
	hud:add(player, "compass", {
		hud_elem_type = "image",
		text = "compass_0.png^[transformR90",
		position={x = 1, y = 0}, 
		scale={x = 8, y = 8}, 
		alignment={x = -1, y = 1}, 
		offset={x = -8, y = 4}
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
	hud:remove_all()
	HUD_showing = false

	local pname = player:get_player_name()
	minetest.show_formspec(pname, "compass:adjustments_menu", table.concat(adjustments_menu, ""))
end

minetest.register_tool("forestry_tools:compass" , {
	description = "Compass",
	inventory_image = "compass_0.png",
    stack_max = 1,
	liquids_pointable = true,
	_mc_tool_privs = forestry_tools.priv_table,

	-- On left-click
    on_use = function(itemstack, player, pointed_thing)
		if HUD_showing then
			show_adjustments_menu(player)
		else
			show_compass_hud(player)
		end
	end,

	-- Destroy the item on_drop to keep things tidy
	on_drop = function (itemstack, dropper, pos)
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
			local dir = player:get_look_horizontal()
			local angle_relative = math.deg(dir)
			local compass_image = math.floor((angle_relative/22.5) + 0.5)%16
			
		-- update HUD image (use helper for rotation, e.g. if >90 pick the right image of the 11 and then call helper)
			local img = "compass_" .. compass_image .. ".png"
			hud:change(player, "compass", {
				text = img
			})
		end
	end
end)





-- local activewidth=8 


-- local hud = mhud.init()

-- local scale_const = 6

-- compass_hud = {
-- 	zoom = {}
-- }

-- local zoom = compass_hud.zoom



-- minetest.register_globalstep(function(dtime)
-- 	local players  = minetest.get_connected_players()
-- 	for i,player in ipairs(players) do

-- 		local gotacompass=false
-- 		local wielded=false
-- 		local activeinv=nil
-- 		local stackidx=0
-- 		--check to see if the user has a compass, 
		
-- 		local wielded_item = player:get_wielded_item():get_name()
-- 		if string.sub(wielded_item, 0, 22) == "forestry_tools:compass" then
-- 			--if the player is wielding a compass, change the wielded image
-- 			wielded=true
-- 			stackidx=player:get_wield_index()
-- 			gotacompass=true
-- 		else
-- 			--check if in active inventory
-- 			if player:get_inventory() then
		
-- 				for i,stack in ipairs(player:get_inventory():get_list("main")) do
-- 					if i<=activewidth and string.sub(stack:get_name(), 0, 22) == "forestry_tools:compass" then
-- 						activeinv=stack  --store the stack 
-- 						stackidx=i --store the index 
-- 						gotacompass=true
-- 						break
-- 					end 
-- 				end 
-- 			end 
-- 		end 

-- 		if gotacompass then
-- 			local dir = player:get_look_horizontal()
-- 			local angle_relative = math.deg(dir)
-- 			local compass_image = math.floor((angle_relative/22.5) + 0.5)%16

-- 			--update image to point 
-- 			if wielded then
-- 				player:set_wielded_item("forestry_tools:compass".."_"..compass_image)
-- 			elseif activeinv then
-- 				player:get_inventory():set_stack("main",stackidx,"forestry_tools:compass".."_"..compass_image)
-- 			end 
-- 		end 
-- 	end 
-- end) 

-- local images = {
-- 		"compass_0.png",
-- 		"compass_1.png",
-- 		"compass_2.png",
-- 		"compass_3.png",
-- 		"compass_4.png",
-- 		"compass_5.png",
-- 		"compass_6.png",
-- 		"compass_7.png",
-- 		"compass_8.png",
-- 		"compass_9.png",
-- 		"compass_10.png",
-- 		"compass_11.png",
-- 		"compass_12.png",
-- 		"compass_13.png",
-- 		"compass_14.png",
-- 		"compass_15.png",
-- }


-- local i
-- for i,img in ipairs(images) do
-- 		local inv = 1
-- 		if i == 1 then
-- 				inv = 0
-- 		end
-- 		minetest.register_tool("forestry_tools:compass".."_"..(i-1), {
-- 				description = "A live Compass",
-- 				inventory_image = img,
-- 				wield_image = img,
-- 				groups = {not_in_creative_inventory=inv},
-- 				rightclick_func = function(itemstack, user, pointed, ...)
-- 					if zoom[user:get_player_name()] then
-- 						hide_compass(user:get_player_name())
-- 					else 
-- 						local item_name = itemstack:get_name():gsub("forestrytools:compass", "")
-- 						show_compass(user:get_player_name(), item_name,4)

-- 					end
-- 				end		
-- 		})
-- end

    
    

-- function show_compass(name, item_name, fov_mult)
-- 	local player = minetest.get_player_by_name(name)
-- 	if not player then
-- 		return
-- 	end

-- zoom[name] = {

-- 	item_name = item_name,
-- 	wielditem = player:hud_get_flags().wielditem 

-- }
	
-- hud:add(player, "compass_hud:zoom", {

-- 		hud_elem_type = "image",
-- 		position = {x = 0.5, y = 0.5},
-- 		text = img,
-- 		scale = {x = scale_const, y = scale_const},
-- 		alignment = {x = "center", y = "center"},
		
-- })


-- player:set_fov(1 / fov_mult, true)
-- physics.set(name, "compass:zoom", {speed = 0.1, jump = 0})
-- player:hud_set_flags({wielditem = false})


-- end


-- function hide_compass(name)
-- 	local player = minetest.get_player_by_name(name)
-- 	if not player then 
-- 		return 
-- 	end 

-- 	hud:remove(name,"compass_hud:zoom")
-- 	player:set_fov(0)
-- 	physics.remove(name,"compass:zoom")
-- 	player:hud_set_flags({wielditem = zoom[name].wielditem})
-- 	zoom[name] = nil

-- end





