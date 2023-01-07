-- Modified from 4aiman's mapp mod: https://github.com/4aiman/mapp/

mc_mapper = {}

local c_air = minetest.CONTENT_AIR
local registered_nodes = minetest.registered_nodes

--[[ -- TODO: remove tool registration and intgrate with student notebook
minetest.register_tool("mc_mapper:map", {
	description = "map",
	inventory_image = "map_block.png",
	on_use = function(itemstack, user, pointed_thing)
	mc_mapper.map_handler(itemstack,user,pointed_thing)
	end,
}) ]]

function mc_mapper.map_handler(player)
	local realm = Realm.GetRealmFromPlayer(player)
	local pos = player:get_pos()
	pos.x, pos.y, pos.z = math.floor(pos.x), math.floor(pos.y), math.floor(pos.z)
	local ceiling = realm.EndPos.y-1
	local player_name = player:get_player_name()
	local mapar = {}
	local map
	local p
	local pp
	local po = {x = 0, y = 0, z = 0}
	local tile = ""

	-- Cache our results in player metadata to speed things and reduce calls to SQLlite database for large realms with many players
	local pmeta = player:get_meta()
    local realmMapCache = minetest.deserialize(pmeta:get_string("realmMapCache"))
	if realmMapCache then
		-- Tile cache exists, check if the current realmID is the same as what was cached, otherwise we need to start caching again
		if realmMapCache.realmID == realm.realmID then
			-- Check if it contains [x,z] positions we already need
			local c = 1
			local xx
			local zz
			for i = -17,17,1 do
				for j = -17,17,1 do
					-- Avoid trying to cache positions outside of the realm
					if pos.x + i >= realm.StartPos.x and pos.z + j >= realm.StartPos.z and pos.x + i <= realm.EndPos.x and pos.z + j <= realm.EndPos.z then
						-- We are in the realm, check if the position is already cached
						if realmMapCache.id[pos.x+i] and realmMapCache.id[pos.x+i][pos.z+j] then
							-- do nothing
						else
							if not xx then xx = {} end
							if not zz then zz = {} end
							xx[c] = pos.x + i
							zz[c] = pos.z + j
							c = c + 1
						end
					end
				end
			end
			if xx and zz then
				-- The cache is missing some tiles so return the smallest possible LVM area
				local minxx = realm.EndPos.x
				local maxxx = realm.StartPos.z
				local minzz = realm.EndPos.z
				local maxzz = realm.StartPos.z
				if #xx > 1 then
					for a = 1, #xx  do minxx = minxx < xx[a] and minxx or xx[a] end
					for b = 1, #zz  do minzz = minzz < zz[b] and minzz or zz[b] end
					for c = 1, #xx  do maxxx = maxxx > xx[c] and maxxx or xx[c] end
					for d = 1, #zz  do maxzz = maxzz > zz[d] and maxzz or zz[d] end	
				else
					-- Only one tile to update
					minxx, maxxx = xx, xx
					minzz, maxzz = zz, zz
				end

				local vm = minetest.get_voxel_manip()
				local emin, emax = vm:read_from_map({x=math.floor(minxx), y=realm.StartPos.y, z=math.floor(minzz)}, {x=math.floor(maxxx), y=realm.EndPos.y, z=math.floor(maxzz)})
				local a = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
				local data = vm:get_data()
				local param2data = vm:get_param2_data()
				local p2
				local def
				local k

				for i = -17,17,1 do
					mapar[i+17] = {}
					if not realmMapCache.id[pos.x+i] then 
						realmMapCache.id[pos.x+i] = {} 
						realmMapCache.y[pos.x+i] = {}
						realmMapCache.param2[pos.x+i] = {}
					end
					for j = -17,17,1 do
						mapar[i+17][j+17] = {}
						if realmMapCache.id[pos.x+i] and realmMapCache.id[pos.x+i][pos.z+j] then
							def = registered_nodes[minetest.get_name_from_content_id(realmMapCache.id[pos.x+i][pos.z+j])]
							k = realmMapCache.y[pos.x+i][pos.z+j]
							p2 = realmMapCache.param2[pos.x+i][pos.z+j]
						else
							realmMapCache.id[pos.x+i][pos.z+j] = {}
							realmMapCache.y[pos.x+i][pos.z+j] = {}
							realmMapCache.param2[pos.x+i][pos.z+j] = {}
							local idx = a:index(pos.x+i, ceiling, pos.z+j)
							local k = ceiling
							local c_no = data[idx]
							if c_no == c_air then
								while c_no == c_air do
									k = k - 1
									idx = a:index(pos.x+i, k, pos.z+j)
									c_no = data[idx]
								end
							end
							p2 = param2data[idx]
							if not c_no then c_no = c_air end
							def = registered_nodes[minetest.get_name_from_content_id(c_no)]
							realmMapCache.id[pos.x+i][pos.z+j] = c_no
							realmMapCache.y[pos.x+i][pos.z+j] = k
							realmMapCache.param2[pos.x+i][pos.z+j] = p2
						end
						local tiles
						if def then 
							tiles = def["tiles"]
							if tiles ~= nil then
								tile = tiles[1]
								local palette = mc_helpers.split(def["name"], ":")
								if type(tile) == "table" then
									tile = tile["name"]
								end
								mapar[i+17][j+17].y = k
								mapar[i+17][j+17].im = tile
								if palette[1] == "colorbrewer" then 
									mapar[i+17][j+17].pa = palette[2] 
									mapar[i+17][j+17].p2 = p2
								end
							end
						end
					end
				end
				-- Update newly cached tiles
				pmeta:set_string("realmMapCache", minetest.serialize(realmMapCache))
			else
				-- The cache already contains all the tiles we need, return them without calling the LVM
				local def
				local k
				local p2
				local tiles
				local palette
				for i = -17,17,1 do
					mapar[i+17] = {}
					for j = -17,17,1 do
						mapar[i+17][j+17] = {}
						def = registered_nodes[minetest.get_name_from_content_id(realmMapCache.id[pos.x+i][pos.z+j])]
						k = realmMapCache.y[pos.x+i][pos.z+j]
						p2 = realmMapCache.param2[pos.x+i][pos.z+j]
						if def then 
							tiles = def["tiles"]
							if tiles ~= nil then
								tile = tiles[1]
								palette = mc_helpers.split(def["name"], ":")
								if type(tile) == "table" then
									tile = tile["name"]
								end
								mapar[i+17][j+17].y = k
								mapar[i+17][j+17].im = tile
								if palette[1] == "colorbrewer" then 
									mapar[i+17][j+17].pa = palette[2] 
									mapar[i+17][j+17].p2 = p2
								end
							end
						end
					end
				end
			end
		else
			-- There is a cache, but it is for a different realm, clear it and initialize again
			local realmMapCache = nil
			pmeta:set_string("realmMapCache", minetest.serialize(realmMapCache))
			local realmMapCache = {}
			realmMapCache.id = {}
			realmMapCache.y = {}
			realmMapCache.param2 = {}
			realmMapCache.realmID = {}
			local vm = minetest.get_voxel_manip()
			local emin, emax = vm:read_from_map({x=pos.x-17, y=realm.StartPos.y, z=pos.z-17}, {x=pos.x+17, y=realm.EndPos.y, z=pos.z+17})
			local a = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
			local data = vm:get_data()
			local param2data = vm:get_param2_data()
			local p2
		
			for i = -17,17,1 do
				mapar[i+17] = {}
				realmMapCache.id[pos.x+i] = {}
				realmMapCache.y[pos.x+i] = {}
				realmMapCache.param2[pos.x+i] = {}
				for j = -17,17,1 do
					mapar[i+17][j+17] = {}
					realmMapCache.id[pos.x+i][pos.z+j] = {}
					realmMapCache.y[pos.x+i][pos.z+j] = {}
					realmMapCache.param2[pos.x+i][pos.z+j] = {}
					local idx = a:index(pos.x+i, ceiling, pos.z+j)
					local k = ceiling
					local c_no = data[idx]
					if c_no == c_air then
						while c_no == c_air do
							k = k - 1
							idx = a:index(pos.x+i, k, pos.z+j)
							c_no = data[idx]
						end
					end
					p2 = param2data[idx]
					if not c_no then c_no = c_air end
					realmMapCache.id[pos.x+i][pos.z+j] = c_no
					realmMapCache.y[pos.x+i][pos.z+j] = k
					realmMapCache.param2[pos.x+i][pos.z+j] = p2
					def = registered_nodes[minetest.get_name_from_content_id(c_no)]
					local tiles
					if def then 
						tiles = def["tiles"]
						if tiles ~= nil then
							tile = tiles[1]
							local palette = mc_helpers.split(def["name"], ":")
							if type(tile) == "table" then
								tile = tile["name"]
							end
							mapar[i+17][j+17].y = k
							mapar[i+17][j+17].im = tile
							if palette[1] == "colorbrewer" then 
								mapar[i+17][j+17].pa = palette[2] 
								mapar[i+17][j+17].p2 = p2
							end
						end
					end
				end
			end
			-- Update newly cached tiles
			realmMapCache.realmID = realm.realmID
			pmeta:set_string("realmMapCache", minetest.serialize(realmMapCache))
		end
	else
		-- No cache initialized for the player, so create it and populate
		local realmMapCache = {}
		realmMapCache.id = {}
		realmMapCache.y = {}
		realmMapCache.param2 = {}
		realmMapCache.realmID = {}
		local vm = minetest.get_voxel_manip()
		local emin, emax = vm:read_from_map({x=pos.x-17, y=realm.StartPos.y, z=pos.z-17}, {x=pos.x+17, y=realm.EndPos.y, z=pos.z+17})
		local a = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
		local data = vm:get_data()
		local param2data = vm:get_param2_data()
		local p2
	
		for i = -17,17,1 do
			mapar[i+17] = {}
			realmMapCache.id[pos.x+i] = {}
			realmMapCache.y[pos.x+i] = {}
			realmMapCache.param2[pos.x+i] = {}
			for j = -17,17,1 do
				mapar[i+17][j+17] = {}
				realmMapCache.id[pos.x+i][pos.z+j] = {}
				realmMapCache.y[pos.x+i][pos.z+j] = {}
				realmMapCache.param2[pos.x+i][pos.z+j] = {}
				local idx = a:index(pos.x+i, ceiling, pos.z+j)
				local k = ceiling
				local c_no = data[idx]
				if c_no == c_air then
					while c_no == c_air do
						k = k - 1
						idx = a:index(pos.x+i, k, pos.z+j)
						c_no = data[idx]
					end
				end
				p2 = param2data[idx]
				if not c_no then c_no = c_air end
				realmMapCache.id[pos.x+i][pos.z+j] = c_no
				realmMapCache.y[pos.x+i][pos.z+j] = k
				realmMapCache.param2[pos.x+i][pos.z+j] = p2
				def = registered_nodes[minetest.get_name_from_content_id(c_no)]
				local tiles
				if def then 
					tiles = def["tiles"]
					if tiles ~= nil then
						tile = tiles[1]
						local palette = mc_helpers.split(def["name"], ":")
						if type(tile) == "table" then
							tile = tile["name"]
						end
						mapar[i+17][j+17].y = k
						mapar[i+17][j+17].im = tile
						if palette[1] == "colorbrewer" then 
							mapar[i+17][j+17].pa = palette[2] 
							mapar[i+17][j+17].p2 = p2
						end
					end
				end
			end
		end
		-- Update newly cached tiles
		realmMapCache.realmID = realm.realmID
		pmeta:set_string("realmMapCache", minetest.serialize(realmMapCache))
	end

	return mapar
	--minetest.show_formspec(player_name, "mc_mapper:map", map)
end
