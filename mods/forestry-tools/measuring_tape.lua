
-- 'Enum' to keep track of current operation
local none_set, pos1_set, pos2_set = 0, 1, 2

local distance
local instances = {}
tape_range = 30

-- Give the measuring tape to any player who joins with adequate privileges or take it away if they do not have them
minetest.register_on_joinplayer(function(player)
	instances[player:get_player_name()] = {
		pos1 = {x=0, y=0, z=0},
		pos2 = {x=0, y=0, z=0},
		node1 = {name = ""},
		node2 = {name = ""},
		mark_status = none_set
	}

    local inv = player:get_inventory()
    if inv:contains_item("main", ItemStack("forestry_tools:measuringTape")) then
        -- Player has the measuring tape
        if check_perm(player) then
            -- The player should have the measuring tape
            return
        else   
            -- The player should not have the measuring tape
            player:get_inventory():remove_item('main', "forestry_tools:measuringTape")
        end
    else
        -- Player does not have the measuring tape
        if check_perm(player) then
            -- The player should have the measuring tape
            player:get_inventory():add_item('main', "forestry_tools:measuringTape")
        else
            -- The player should not have the measuring tape
            return
        end     
    end
end)


-- pos1 marker node
minetest.register_node("forestry_tools:measure_pos1", {
	description = "Measure Pos1",
	tiles = {"measure_pos1.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	light_source = minetest.LIGHT_MAX,
	groups = {not_in_creative_inventory, immortal}	
})

-- pos2 marker node
minetest.register_node("forestry_tools:measure_pos2", {
	description = "Measure Pos2",
	tiles = {"measure_pos2.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	light_source = minetest.LIGHT_MAX,
	groups = {not_in_creative_inventory, immortal}
})

-- Marks pos1
function mark_pos1(player, pos)
	instances[player].pos1 = pos
	instances[player].node1 = minetest.get_node(pos)
    -- TODO: don't want it to swap just want it to place on top
	minetest.swap_node(pos, {name = "forestry_tools:measure_pos1"})
	tell_player(player, "pos1 marked!")
	instances[player].mark_status = pos1_set
end

-- Marks pos2 and performs calculations
function mark_pos2(player, pos, facedir_param2, range)
	instances[player].pos2 = pos
	instances[player].node2 = minetest.get_node(pos)
	minetest.swap_node(pos, {name = "forestry_tools:measure_pos2"})
	tell_player(player, "pos2 marked!")
	instances[player].mark_status = pos2_set
	
	-- Calculate the distance and display output
	distance = math.floor(vector.distance(instances[player].pos1, instances[player].pos2) + 0.5)

	for i = 1, distance do
		if pos.z == instances[player].pos1.z then
			if pos.x < instances[player].pos1.x then
				local newPos = {x = pos.x + i, y = pos.y, z = pos.z}
				minetest.swap_node(newPos, {name = "forestry_tools:measure_pos1"})
			else 
				local newPos = {x = pos.x - i, y = pos.y, z = pos.z}
				minetest.swap_node(newPos, {name = "forestry_tools:measure_pos1"})
			end
		elseif pos.x == instances[player].pos1.x then
			if pos.z < instances[player].pos1.z then
				local newPos = {x = pos.x, y = pos.y, z = pos.z + i}
				minetest.swap_node(newPos, {name = "forestry_tools:measure_pos1"})
			else 
				local newPos = {x = pos.x, y = pos.y, z = pos.z - i}
				minetest.swap_node(newPos, {name = "forestry_tools:measure_pos1"})
			end
		end
	end

	tell_player(player, "Distance: " .. minetest.colorize("#FFFF00", distance) .. "m")

	-- Reads auto-reset duration from conf, defaults to 20 seconds if setting non-existent
	local auto_reset = tonumber(minetest.settings:get("forestry_tools.auto_reset"))
	if not auto_reset then
		auto_reset = 20
		minetest.settings:set("forestry_tools.auto_reset", auto_reset)
	end
			
	-- Auto-reset is disabled if auto_reset == 0
	if auto_reset ~= 0 then
		 minetest.after(auto_reset, reset, player)
	end
end

-- Resets pos1 and pos2; replaces marker nodes with the old nodes
function reset(player)
	if instances[player].mark_status == none_set then
		return
	end
	
	if instances[player].mark_status == pos1_set then
		minetest.swap_node(instances[player].pos1, instances[player].node1)
	elseif instances[player].mark_status == pos2_set then
		minetest.swap_node(instances[player].pos1, instances[player].node1)
		minetest.swap_node(instances[player].pos2, instances[player].node2)
	end
		
	instances[player].mark_status = none_set
	
	
	if minetest.get_player_by_name(player) then
		tell_player(player, "pos1 and pos2 have been reset.")
	end
end

-- Convenience method which just calls minetest.chat_send_player() after prefixing msg with " -!- Measuring Tape: "
function tell_player(player_name, msg)
	minetest.chat_send_player(player_name, "Measuring Tape - " .. msg)	
end

minetest.register_tool("forestry_tools:measuringTape" , {
	description = "Measuring Tape",
	inventory_image = "measuring_tape.png",
    stack_max = 1,
	liquids_pointable = true,

	-- On left-click
    on_use = function(itemstack, placer, pointed_thing, pos)
	
		placer = placer:get_player_name()
		if pointed_thing.type == "node" then
		
			local pointed_node = minetest.get_node(pointed_thing.under).name
			if pointed_node == "forestry_tools:measure_pos1" or pointed_node == "forestry_tools:measure_pos2" then
				reset(placer)
				return
			end
					
			-- If pos1 not marked, mark pos1
			if instances[placer].mark_status == none_set then
				mark_pos1(placer, pointed_thing.under)
			
			-- If pos1 marked, mark pos2 perform calculations, and trigger auto-reset
			elseif instances[placer].mark_status == pos1_set then
				local node = minetest.get_node(pointed_thing.under)
				mark_pos2(placer, pointed_thing.under, node.param2, tape_range)
				
			end
		end
		
		return itemstack
	end,

	-- Destroy the item on_drop to keep things tidy
	on_drop = function (itemstack, dropper, pos)
		minetest.set_node(pos, {name="air"})
	end,
})

minetest.register_alias("measuringTape", "forestry_tools:measuringTape")
measuringTape = minetest.registered_aliases[measuringTape] or measuringTape





-- -- TODO: might want each block to be less than a meter

-- -- TODO: might not need range, currently set to average tape measure length (30m)
-- tape_range = 30

-- local in_use = function(pos, facedir_param2, range)
--     local meta = minetest.get_meta(pos)
--     local block_pos = vector.new(pos)
--     local tape_pos = vector.new(pos)
--     local tape_direction = minetest.facedir_to_dir(facedir_param2)

--     for i = 1, range + 1, 1 do
--         tape_pos = vector.add(block_pos, vector.multiply(tape_direction, i))
--         if minetest.get_node(tape_pos).name == "air" or minetest.get_node(tape_pos).name == "tape" then
--             if i <= range then
--                 minetest.set_node(tape_pos, {name = "tape", param2 = facedir_param2})
--                 meta:set_string("infotext", "Distance: " .. tostring(i) .. "m")
--                 meta:set_int("range", i)
--             else
--                 meta:set_string("infotext", "Distance: out of range")
--                 meta:set_int("range", tape_range)
--             end
--         else
--             break
--         end
--     end
-- end

-- local not_in_use = function(pos, facedir_param2, range)
--     local meta = minetest.get_meta(pos)
--     local block_pos = vector.new(pos)
--     local tape_pos = vector.new(pos)
--     local tape_direction = minetest.facedir_to_dir(facedir_param2)

--     for i = range, 0, -1 do
--         tape_pos = vector.add(block_pos, vector.multiply(tape_direction, i))
--         if minetest.get_node(tape_pos).name == "tape" and minetest.get_node(tape_pos).param2 == facedir_param2 then
--             minetest.set_node(tape_pos, {name="air"})
--         end
--     end
-- end

-- local tape_check = function(pos, facedir_param2, range)
--     local block_pos = vector.new(pos)
--     local tape_pos = vector.new(pos)
--     local tape_direction = minetest.facedir_to_dir(facedir_param2)
--     local is_not_tape = false
    
--     for i = 1, range + 1, 1 do
--         tape_pos = vector.add(block_pos, vector.multiply(tape_direction, i))
--         if minetest.get_node(tape_pos).name ~= "tape" and i <= range then
--             is_not_tape = true
--         elseif minetest.get_node(tape_pos).name == "air" and i <= tape_range then
--             is_not_tape = true
--         end
--     end
--     return is_not_tape
-- end

-- minetest.register_node("forestry_tools:measuring_tape", {
--     description = "Measuring Tape",
--     inventory_image = "measuring_tape.png",
--     -- drawtype = "mesh",
--     -- mesh = "ldm32_casing.obj",
--     tiles = {"measuring_tape.png"},
--     --          "ldm32_casing.png",},
--     selection_box = {
--         type = "fixed",
--         fixed = {{-0.07, -0.5, -0.5, 0.07, -0.25, 0.5},}
--     },
--     collision_box = {
--         type = "fixed",
--         fixed = {{-0.07, -0.5, -0.5, 0.07, -0.25, 0.5},}
--     },
--     stack_max = 1,
--     is_ground_content = true,
--     paramtype2 = "facedir",
--     groups = {snappy = 3, dig_immediate = 3},
--     on_place = minetest.rotate_node,

--     on_timer = function(pos)
--         local meta = minetest.get_meta(pos)
--         local node = minetest.get_node(pos)
--         local timer = minetest.get_node_timer(pos)
--         local is_not_tape = false
--         local is_air = false

--         if meta:get_string("is_in_use") == "true" then
--             if tape_check(pos, node.param2, meta:get_int("range")) then
--                 not_in_use(pos, node.param2, meta:get_int("range"))
--                 in_use(pos, node.param2, tape_range)
--             end
--             if meta:get_int("facedir") ~= node.param2 and meta:get_string("is_in_use") then
--                 not_in_use(pos, meta:get_int("facedir"), tape_range)
--                 in_use(pos, node.param2, tape_range)
--                 meta:set_int("facedir", node.param2)
--             end
--         end
--         timer:start(1)
--     end,

--     on_construct = function(pos)
--         local meta = minetest.get_meta(pos)
--         local node = minetest.get_node(pos)
--         meta:set_string("infotext","Off")
--         meta:set_string("is_in_use", "false")
--         meta:set_int("facedir", node.param2)
--     end,

--     after_destruct = function(pos, oldnode, oldmetadata)
--         local meta = minetest.get_meta(pos)
--         not_in_use(pos, oldnode.param2, tape_range)
--         meta:set_string("infotext", "Off")
--         meta:set_string("is_in_use", "false")
--     end,

--     after_dig_node = function(pos, oldnode)
--         local meta = minetest.get_meta(pos)
--         not_in_usef(pos, oldnode.param2, tape_range)
--         meta:set_string("infotext", "Off")
--         meta:set_string("is_in_use", "false")
--     end,

--     on_rightclick = function(pos, node, player, itemstack, pointed_thing)
--         local meta = minetest.get_meta(pos)
--         local node = minetest.get_node(pos)
--         local timer = minetest.get_node_timer(pos)

--         if meta:get_string("is_in_use") == "false" then
--             in_use(pos, node.param2, tape_range)
--             meta:set_string("is_in_use", "true")
--             timer:start(1)
--         else
--             not_in_use(pos, node.param2, meta:get_int("range"))
--             meta:set_string("infotext", "Off")
--             meta:set_string("is_in_use", "false")
--             timer:stop()
--         end
--     end,
-- })

-- minetest.register_node("forestry_tools:tape", {
--     description = "Tape",
--     -- drawtype = "mesh",
--     -- mesh = "ldm32_laser_beam.obj",
--     tiles = {"tape.png"},
--     paramtype = "light",
--     paramtype2 = "facedir",
--     use_texture_alpha = true,
--     --alpha = 0,
--     light_source = 4,
--     post_effect_color = {r=240,g=230,b=140, a=128},
--     sunlight_propagates = true,
--     walkable = false,
--     pointable = false,
--     diggable = false,
--     buildable_to = true,
-- })

