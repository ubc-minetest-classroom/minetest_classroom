local range = 32
local RAY_RANGE = 500
local MODES = {"HT", "SD", "VD", "HD", "INC", "AZ", "ML"}

local function track_raycast_hit(player)
    local player_pos = vector.offset(player:get_pos(), 0, player:get_properties().eye_height, 0)
    local ray = minetest.raycast(player_pos, vector.add(player_pos, vector.multiply(player:get_look_dir(), RAY_RANGE)))
    local p, first_hit = ray:next(), ray:next()

    if not first_hit then
        return minetest.chat_send_player(player:get_player_name(), "No objects detected within range, cast not logged")
    end
    player:hud_add({
        hud_elem_type = "image_waypoint",
        world_pos = first_hit.intersection_point,
        text = "forestry_tools_rf_marker.png",
        scale = {x = 1.25, y = 1.25},
        z_index = -300,
        alignment = {x = 0, y = 0}
    })
end

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

minetest.register_tool("forestry_tools:rangefinder" , {
 	description = "Rangefinder",
 	inventory_image = "rangefinder.jpg",
 	-- Left-click the tool activate function
 	on_use = function (itemstack, player, pointed_thing)
        local pname = player:get_player_name()
 		-- Check for shout privileges
 		if check_perm(player) then
            track_raycast_hit(player)
 			--show_rangefinder(player)
 		end
 	end,
 	-- Destroy the item on_drop to keep things tidy
 	on_drop = function (itemstack, dropper, pos)
 	end,
})


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




