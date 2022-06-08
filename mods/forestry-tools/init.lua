forestry_tools = { path = minetest.get_modpath("forestry_tools") }

function check_perm(player)
	return minetest.check_player_privs(player:get_player_name(), { shout = true })
end

dofile(forestry_tools.path .. "/measuring_tape.lua")

--------------------------------
--  RANGEFINDER FUNCTIONS   --
---------------------------------

local function show_rangefinder(player)
	if check_perm(player) then
		local pname = player:get_player_name()
		return true
	end
end

minetest.register_tool("forestry_tools:rangefinder" , {
	description = "Rangefinder",
	inventory_image = "rangefinder.jpeg",
	-- Left-click the tool activate function
	on_use = function (itemstack, user, pointed_thing)
        local pname = user:get_player_name()
		-- Check for shout privileges
		if check_perm(user) then
			show_rangefinder(user)
		end
	end,
	-- Destroy the item on_drop to keep things tidy
	on_drop = function (itemstack, dropper, pos)
		minetest.set_node(pos, {name="air"})
	end,
})


minetest.register_alias("rangefinder", "forestry_tools:rangefinder")
rangefinder = minetest.registered_aliases[rangefinder] or rangefinder

minetest.register_on_joinplayer(function(player)
    local inv = player:get_inventory()
    if inv:contains_item("main", ItemStack("forestry_tools:rangefinder")) then
        -- Player has the rangefinder
        if check_perm(player) then
            -- The player should have the rangefinder
            return
        else   
            -- The player should not have the rangefinder
            player:get_inventory():remove_item('main', "forestry_tools:rangefinder")
        end
    else
        -- Player does not have the rangefinder
        if check_perm(player) then
            -- The player should have the rangefinder
            player:get_inventory():add_item('main', "forestry_tools:rangefinder")
        else
            -- The player should not have the rangefinder
            return
        end     
    end
end)




--------------------------------
-- COMPASS FUNCTIONS   --
---------------------------------


local activewidth=8 

minetest.register_globalstep(function(dtime)
	local players  = minetest.get_connected_players()
	for i,player in ipairs(players) do

		local gotacompass=false
		local wielded=false
		local activeinv=nil
		local stackidx=0
		--first check to see if the user has a compass
		local wielded_item = player:get_wielded_item():get_name()
		if string.sub(wielded_item, 0, 12) == "forestry_tools:compass:" then
			--if the player is wields a compass, change the wielded image
			wielded=true
			stackidx=player:get_wield_index()
			gotacompass=true
		else
			--check to see if compass is in active inventory
			if player:get_inventory() then
				--check  entire list since arrays are not sorted 
				
				for i,stack in ipairs(player:get_inventory():get_list("main")) do
					if i<=activewidth and string.sub(stack:get_name(), 0, 12) == "forestry_tools:compass:" then
						activeinv=stack  --store the stack so we can update it later with new image
						stackidx=i --store the index so we can add image at correct location
						gotacompass=true
						break
					end --if i<=activewidth
				end --for loop
			end -- get_inventory
		end --if wielded else

		
		if gotacompass then
			local dir = player:get_look_horizontal()
			local angle_relative = math.deg(dir)
			local compass_image = math.floor((angle_relative/22.5) + 0.5)%16
            -- hopefully correct math 

			--update compass image to point at target
			if wielded then
				player:set_wielded_item("forestry_tools:compass:"..compass_image)
			elseif activeinv then
				player:get_inventory():set_stack("main",stackidx,"forestry_tools:compass:"..compass_image)
			end --if wielded elsif activin
		end --if gotacompass
	end --for i,player in ipairs(players)
end) -- register_globalstep

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

-- table to get correct images 

local i
for i,img in ipairs(images) do
		local inv = 1
		if i == 1 then
				inv = 0
		end
		minetest.register_tool("forestry_tools:compass:"..(i-1), {
				description = "ACompass",
				inventory_image = img,
				wield_image = img,
				groups = {not_in_creative_inventory=inv}
		})
end

-- do i register on join?

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
    
    



-- crafting recipe 
if minetest.get_modpath("default") ~= nil then
	minetest.register_craft({
			output = 'realcompass:0',
			recipe = {
					{'', 'default:steel_ingot', ''},
					{'default:copper_ingot', 'default:glass', 'default:copper_ingot'},
					{'', 'default:copper_ingot', ''}
			}
	})
end









