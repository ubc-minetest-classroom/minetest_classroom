
local activewidth=8 

minetest.register_globalstep(function(dtime)
	local players  = minetest.get_connected_players()
	for i,player in ipairs(players) do

		local gotacompass=false
		local wielded=false
		local activeinv=nil
		local stackidx=0
		--check to see if the user has a compass, 
		
		local wielded_item = player:get_wielded_item():get_name()
		if string.sub(wielded_item, 0, 12) == "forestry_tools:compass" then
			--if the player is wielding a compass, change the wielded image
			wielded=true
			stackidx=player:get_wield_index()
			gotacompass=true
		else
			--check if in active inventory
			if player:get_inventory() then
		
				for i,stack in ipairs(player:get_inventory():get_list("main")) do
					if i<=activewidth and string.sub(stack:get_name(), 0, 12) == "forestry_tools:compass" then
						activeinv=stack  --store the stack 
						stackidx=i --store the index 
						gotacompass=true
						break
					end 
				end 
			end 
		end 

		if gotacompass then
			local dir = player:get_look_horizontal()
			local angle_relative = math.deg(dir)
			local compass_image = math.floor((angle_relative/22.5) + 0.5)%16

			--update image to point 
			if wielded then
				player:set_wielded_item("forestry_tools:compass"..compass_image)
			elseif activeinv then
				player:get_inventory():set_stack("main",stackidx,"forestry_tools:compass"..compass_image)
			end 
		end 
	end 
end) 

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

local i
for i,img in ipairs(images) do
		local inv = 1
		if i == 1 then
				inv = 0
		end
		minetest.register_tool("forestry_tools:compass"..(i-1), {
				description = "A live Compass",
				inventory_image = img,
				wield_image = img,
				groups = {not_in_creative_inventory=inv}
		})
end

  
minetest.register_on_joinplayer(function(player)
	local inv = player:get_inventory()
	if inv:contains_item("main", ItemStack("forestry_tools:compass")) then
		
		
	else
		
		
			player:get_inventory():add_item('main', "forestry_tools:compass")
		
			return
		end     
	end
)
    
    


