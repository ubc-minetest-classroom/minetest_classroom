-- EXPORTED MAGNIFY FUNCTIONS
local magnify = {}

-- node registration function
function magnify.register_plant(def_table, blocks)
    local ref = minetest_classroom.bc_plants:get_int("count")
    local serial_table = minetest.serialize(def_table)
    minetest_classroom.bc_plants:set_string("ref_"..ref, serial_table)
    for k,v in pairs(blocks) do
		minetest_classroom.bc_plants:set_string("node_"..v, "ref_"..ref)
    end
    minetest_classroom.bc_plants:set_int("count", ref + 1)
end

-- registered species reference table getter
function magnify.get_all_registered_species()
  	local storage_data = minetest_classroom.bc_plants:to_table()
	local output = {}
  	for k,v in pairs(storage_data.fields) do
  		if string.sub(k, 1, 4) == "ref_" then
      		local info = minetest.deserialize(v)
      		local name_string = "###" .. string.sub(k, 5) .. ": " .. info.com_name .. " (" .. info.sci_name .. ")" -- if changed, update get_species_ref in mc_teacher/gui_dash.lua
      		table.insert(output, name_string)
      	end
    end
  	return output
end

-- reference clearing function
function magnify.clear_ref(ref)
	local storage_data = minetest_classroom.bc_plants:to_table()
	for k,v in pairs(storage_data.fields) do
		if k == ref or v == ref then
			minetest_classroom.bc_plants:set_string(k, "")
		end
	end
end

-- species getter
function magnify.get_species_from_ref(ref)
  	local storage_data = minetest_classroom.bc_plants:to_table()
	local output = {nodes = {}}
  
  	if minetest_classroom.bc_plants:get(ref) then
    	output["data"] = minetest.deserialize(minetest_classroom.bc_plants:get_string(ref))
		for k,v in pairs(storage_data.fields) do
			if v == ref then
        		table.insert(output.nodes, string.sub(k, 6))
    		end
		end
    	return output
    else
    	return nil
    end
end

return magnify