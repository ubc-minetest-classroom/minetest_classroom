forestry_tools = { path = minetest.get_modpath("forestry_tools") }

local function check_perm(player)
	return minetest.check_player_privs(player:get_player_name(), { shout = true })
end


----------------------------------
--   MEASURING TAPE FUNCTIONS   --
----------------------------------

local function show_measuring_tape(player)
	if check_perm(player) then
		local pname = player:get_player_name()
		return true
	end
end

minetest.register_tool("forestry_tools:measuringTape" , {
	description = "Measuring Tape",
	inventory_image = "measuring_tape.png",
	-- Left-click the tool activates the function
	on_use = function (itemstack, user, pointed_thing)
        local pname = user:get_player_name()
		-- Check for shout privileges
		if check_perm(user) then
			show_measuring_tape(user)
		end
	end,
	-- Destroy the item on_drop to keep things tidy
	on_drop = function (itemstack, dropper, pos)
		minetest.set_node(pos, {name="air"})
	end,
})

minetest.register_alias("measuringTape", "forestry_tools:measuringTape")
measuringTape = minetest.registered_aliases[measuringTape] or measuringTape

-- Give the measuring tape to any player who joins with adequate privileges or take it away if they do not have them
minetest.register_on_joinplayer(function(player)
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
measuringTape = minetest.registered_aliases[rangefinder] or rangefinder

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
local function show_compass(player)
	if check_perm(player) then
		local pname = player:get_player_name()
		return true
	end
end

minetest.register_tool("forestry_tools:compass" , {
	description = "compass",
	inventory_image = "compass.png",
	-- Left-click the tool activates function
	on_use = function (itemstack, user, pointed_thing)
        local pname = user:get_player_name()
		-- Check for shout privileges
		if check_perm(user) then
			show_compass(user)
		end
	end,
	-- Destroy the item on_drop to keep things tidy
	on_drop = function (itemstack, dropper, pos)
		minetest.set_node(pos, {name="air"})
	end,
})

minetest.register_alias("compass", "forestry_tools:compass")
measuringTape = minetest.registered_aliases[compass] or compass



-- Give the compass to any player who joins with adequate privileges or take it away if they do not have them
    minetest.register_on_joinplayer(function(player)
        local inv = player:get_inventory()
        if inv:contains_item("main", ItemStack("forestry_tools:compass")) then
            -- Player has the measuring tape
            if check_perm(player) then
                -- The player should have the measuring tape
                return
            else   
                -- The player should not have the measuring tape
                player:get_inventory():remove_item('main', "forestry_tools:compass")
            end
        else
            -- Player does not have the measuring tape
            if check_perm(player) then
                -- The player should have the measuring tape
                player:get_inventory():add_item('main', "forestry_tools:compass")
            else
                -- The player should not have the measuring tape
                return
            end     
        end
    end)