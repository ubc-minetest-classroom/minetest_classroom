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











