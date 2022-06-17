forestry_tools = { path = minetest.get_modpath("forestry_tools") }

local priv_table = { shout = true }
function forestry_tools.check_perm(player)
	return minetest.check_player_privs(player:get_player_name(), priv_table)
end

dofile(forestry_tools.path .. "/measuring_tape.lua")
dofile(forestry_tools.path .. "/compass.lua")

-------------------------------
--  RANGEFINDER FUNCTIONS   --
-------------------------------

local function show_rangefinder(player)
	if forestry_tools.check_perm(player) then
		local pname = player:get_player_name()
		return true
	end
end

minetest.register_tool("forestry_tools:rangefinder" , {
	description = "Rangefinder",
	inventory_image = "rangefinder.jpeg",
    _mc_tool_privs = priv_table,
	-- Left-click the tool activate function
	on_use = function (itemstack, user, pointed_thing)
        local pname = user:get_player_name()
		-- Check for shout privileges
		if forestry_tools.check_perm(user) then
			show_rangefinder(user)
		end
	end,
	-- Destroy the item on_drop to keep things tidy
	on_drop = function (itemstack, dropper, pos)
	end,
})


minetest.register_alias("rangefinder", "forestry_tools:rangefinder")
rangefinder = minetest.registered_aliases[rangefinder] or rangefinder
