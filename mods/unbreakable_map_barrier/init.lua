minetest.register_node("unbreakable_map_barrier:barrier", {
        description = "Indestructible Map Block Barrier",
		drawtype = "glasslike_framed_optional",
		tiles = {"default_glass_detail.png"},
		use_texture_alpha = "clip",
		paramtype = "light",
		paramtype2 = "glasslikeliquidlevel",
		sunlight_propagates = true,
        is_ground_content = false,	
        on_blast = function() end,
        on_destruct = function () end,
        can_dig = function() return false end,
        diggable = false,
		pointable = false, -- The player can't highlight it
		drop = "",
})

minetest.register_chatcommand("mapbarrier", {
	params = "<x0>,<x1>,<y0>,<y1>,<z0>,<z1>",
	description = "Generate an unbreakable map barrier",
	privs = {interact=true},
	func = function(name, param)
		x0, x1, y0, y1, z0, z1 = string.match(param, "^([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
		minetest.chat_send_all("Values given: x0="..x0.." x1="..x1.." y0="..y0.." y1="..y1.." z0="..z0.." z1="..z1)
		x0, x1, y0, y1, z0, z1 = tonumber(x0),tonumber(x1),tonumber(y0),tonumber(y1),tonumber(z0),tonumber(z1)
		-- top
		minetest.chat_send_all("Writing top unbreakable blocks...")
		pos1 = {x = x0, y = y0, z = z0}
		pos2 = {x = x1, y = y1, z = z0}
		vm = minetest.get_voxel_manip()
		edge0, edge1 = vm:read_from_map(pos1, pos2)
		area = VoxelArea:new{MinEdge=edge0, MaxEdge=edge1}
		data = vm:get_data()
		for x=x0-1,x1 do
			for y=y0-1,y1 do
				j = area:index(tonumber(x), tonumber(y), tonumber(z0))
				data[j] = minetest.get_content_id ("unbreakable_map_barrier:barrier")
			end
		end
		vm:set_data(data)
		vm:write_to_map()
		
		-- bottom
		minetest.chat_send_all("Writing bottom unbreakable blocks...")
		pos1 = {x = x0, y = y0, z = z1}
		pos2 = {x = x1, y = y0, z = z0}		
		vm = minetest.get_voxel_manip()
		edge0, edge1 = vm:read_from_map(pos1, pos2)
		area = VoxelArea:new{MinEdge=edge0, MaxEdge=edge1}
		data = vm:get_data()
		for x=x0-1,x1 do
			for z=z0-1,z1 do
				j = area:index(tonumber(x), tonumber(y0), tonumber(z))
				data[j] = minetest.get_content_id ("unbreakable_map_barrier:barrier")
			end
		end
		vm:set_data(data)
		vm:write_to_map()
		pos1, pos2, vm, edge0, edge1, area, data = {}, {}, {}, {}, {}, {}, {}
		
		-- front
		minetest.chat_send_all("Writing unbreakable front blocks...")
		pos1 = {x = x0, y = y0, z = z0}
		pos2 = {x = x0, y = y1, z = z1}	
		vm = minetest.get_voxel_manip()
		edge0, edge1 = vm:read_from_map(pos1, pos2)
		area = VoxelArea:new{MinEdge=edge0, MaxEdge=edge1}
		data = vm:get_data()
		for y=y0-1,y1 do
			for z=z0-1,z1 do
				j = area:index(tonumber(x0), tonumber(y), tonumber(z))
				data[j] = minetest.get_content_id ("unbreakable_map_barrier:barrier")
			end
		end
		vm:set_data(data)
		vm:write_to_map()

		-- back
		minetest.chat_send_all("Writing unbreakable back blocks...")
		pos1 = {x = x1, y = y0, z = z0}
		pos2 = {x = x1, y = y1, z = z1}	
		vm = minetest.get_voxel_manip()
		edge0, edge1 = vm:read_from_map(pos1, pos2)
		area = VoxelArea:new{MinEdge=edge0, MaxEdge=edge1}
		data = vm:get_data()
		for y=y0-1,y1 do
			for z=z0-1,z1 do
				j = area:index(tonumber(x1), tonumber(y), tonumber(z))
				data[j] = minetest.get_content_id ("unbreakable_map_barrier:barrier")
			end
		end
		vm:set_data(data)
		vm:write_to_map()

		-- right
		minetest.chat_send_all("Writing unbreakable right blocks...")
		pos1 = {x = x0, y = y1, z = z0}
		pos2 = {x = x1, y = y1, z = z1}
		vm = minetest.get_voxel_manip()
		edge0, edge1 = vm:read_from_map(pos1, pos2)
		area = VoxelArea:new{MinEdge=edge0, MaxEdge=edge1}
		data = vm:get_data()
		for x=x0-1,x1+1 do
			for z=z0-1,z1+1 do
				j = area:index(tonumber(x), tonumber(y1), tonumber(z))
				data[j] = minetest.get_content_id ("unbreakable_map_barrier:barrier")
			end
		end
		vm:set_data(data)
		vm:write_to_map()

		-- left
		minetest.chat_send_all("Writing unbreakable left blocks...")
		pos1 = {x = x0, y = y0, z = z1}
		pos2 = {x = x1, y = y1, z = z1}
		vm = minetest.get_voxel_manip()
		edge0, edge1 = vm:read_from_map(pos1, pos2)
		area = VoxelArea:new{MinEdge=edge0, MaxEdge=edge1}
		data = vm:get_data()
		for x=x0-1,x1 do
			for y=y0-1,y1 do
				j = area:index(tonumber(x), tonumber(y), tonumber(z1))
				data[j] = minetest.get_content_id ("unbreakable_map_barrier:barrier")
			end
		end
		vm:set_data(data)
		vm:write_to_map()
	end,
})