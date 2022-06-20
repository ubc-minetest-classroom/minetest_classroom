range = 32

local finder_on = function(pos, facedir_param2, range)
    local meta = minetest.get_meta(pos)
    local block_pos = vector.new(pos)
    local beam_pos = vector.new(pos)
    local beam_direction = minetest.facedir_to_dir(facedir_param2)

	
    for i = 1, range + 1, 1 do
        beam_pos = vector.add(block_pos, vector.multiply(beam_direction, i))
        if minetest.get_node(beam_pos).name == "air" or minetest.get_node(beam_pos).name == "forestry_tools:rangefinder" then
            if i <= range then
                minetest.set_node(beam_pos, {name = "forestry_tools:rangefinder", param2 = facedir_param2})
                meta:set_string("infotext", "Distance: " .. tostring(i) .. "m")
                meta:set_int("range", i)
            else
                meta:set_string("infotext", "out of range")
                meta:set_int("range", range)
            end
        else
            break
        end
    end
end



local range_off = function(pos, facedir_param2, range)
    local meta = minetest.get_meta(pos)
    local block_pos = vector.new(pos)
    local beam_pos = vector.new(pos)
    local beam_direction = minetest.facedir_to_dir(facedir_param2)

    for i = range, 0, -1 do
        beam_pos = vector.add(block_pos, vector.multiply(beam_direction, i))
        if minetest.get_node(beam_pos).name == "forestry_tools:rangefinder" and minetest.get_node(beam_pos).param2 == facedir_param2 then
            minetest.set_node(beam_pos, {name="air"})
        end
    end
end

local range_check = function(pos, facedir_param2, range)
    local block_pos = vector.new(pos)
    local beam_pos = vector.new(pos)
    local beam_direction = minetest.facedir_to_dir(facedir_param2)
    local is_not_beam = false
    
    for i = 1, range + 1, 1 do
        beam_pos = vector.add(block_pos, vector.multiply(beam_direction, i))
        if minetest.get_node(beam_pos).name ~= "forestry_tools:rangefinder" and i <= range then
            is_not_beam = true
        elseif minetest.get_node(beam_pos).name == "air" and i <= laser_range then
            is_not_beam = true
        end
    end
    return is_not_beam
end


-- have to add register node(?) or tool(?) as well as laser between rangefinder obj and point of interest 








-- local function show_rangefinder(player)
-- 	if check_perm(player) then
-- 		local pname = player:get_player_name()
-- 		return true
-- 	end
-- end

-- minetest.register_tool("forestry_tools:rangefinder" , {
-- 	description = "Rangefinder",
-- 	inventory_image = "rangefinder.jpeg",
-- 	-- Left-click the tool activate function
-- 	on_use = function (itemstack, user, pointed_thing)
--         local pname = user:get_player_name()
-- 		-- Check for shout privileges
-- 		if check_perm(user) then
-- 			show_rangefinder(user)
-- 		end
-- 	end,
-- 	-- Destroy the item on_drop to keep things tidy
-- 	on_drop = function (itemstack, dropper, pos)
-- 		minetest.set_node(pos, {name="air"})
-- 	end,
-- })


-- minetest.register_alias("rangefinder", "forestry_tools:rangefinder")
-- rangefinder = minetest.registered_aliases[rangefinder] or rangefinder

-- minetest.register_on_joinplayer(function(player)
--     local inv = player:get_inventory()
--     if inv:contains_item("main", ItemStack("forestry_tools:rangefinder")) then
--         -- Player has the rangefinder
--         if check_perm(player) then
--             -- The player should have the rangefinder
--             return
--         else   
--             -- The player should not have the rangefinder
--             player:get_inventory():remove_item('main', "forestry_tools:rangefinder")
--         end
--     else
--         -- Player does not have the rangefinder
--         if check_perm(player) then
--             -- The player should have the rangefinder
--             player:get_inventory():add_item('main', "forestry_tools:rangefinder")
--         else
--             -- The player should not have the rangefinder
--             return
--         end     
--     end
-- end)




