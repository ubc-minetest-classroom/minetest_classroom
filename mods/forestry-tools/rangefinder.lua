local function show_rangefinder(player)
	if forestry_tools.check_perm(player) then
		local pname = player:get_player_name()
		return true
	end
end

minetest.register_tool("forestry_tools:rangefinder" , {
	description = "Rangefinder",
	inventory_image = "rangefinder.jpeg",
    _mc_tool_privs = forestry_tools.priv_table,
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
