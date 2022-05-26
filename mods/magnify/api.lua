-- EXPORTED MAGNIFY FUNCTIONS
magnify = {}

--- @public
--- Adds a plant to the magnify plant database
--- @param def_table Definition table for the species being added
--- @param blocks Table of stringified nodes this species corresponds to in the MineTest world
--- @see Magnify documentation for more information on how to register a plant species
function magnify.register_plant(def_table, blocks)
    local ref = magnify_plants:get_int("count")
    local serial_table = minetest.serialize(def_table)
    magnify_plants:set_string("ref_"..ref, serial_table)
    for k,v in pairs(blocks) do
		magnify_plants:set_string("node_"..v, "ref_"..ref)
    end
    magnify_plants:set_int("count", ref + 1)
end

--- @public
--- Returns human-readable names of all species in the magnify plant database
--- @return table
function magnify.get_all_registered_species()
	local storage_data = magnify_plants:to_table()
  	local output = {}
	for k,v in pairs(storage_data.fields) do
		if string.sub(k, 1, 4) == "ref_" then
			local info = minetest.deserialize(v)
			if info then
				local name_string = "###" .. string.sub(k, 5) .. ": " .. info.com_name .. " (" .. info.sci_name .. ")" -- if changed, update get_species_ref in mc_teacher/gui_dash.lua
				table.insert(output, name_string)
			end
		end
  	end
	table.sort(output)
	return output
end

--- @public
--- Clears the given reference key from the magnify plant database
--- @param ref The reference key of the plant species to be cleared from the database
function magnify.clear_ref(ref)
	local storage_data = magnify_plants:to_table()
	for k,v in pairs(storage_data.fields) do
		if k == ref or v == ref then
			magnify_plants:set_string(k, "")
		end
	end
end

--- @public
--- Returns information about the plant species indexed at the given reference key
--- @param ref The reference key of the plant species
--- @return table {data, nodes}
function magnify.get_species_from_ref(ref)
  	local storage_data = magnify_plants:to_table()
	local output = {nodes = {}}
  
  	if magnify_plants:get(ref) then
		local data = minetest.deserialize(magnify_plants:get_string(ref))
		if data then
    		output["data"] = data
			for k,v in pairs(storage_data.fields) do
				if v == ref then
        			table.insert(output.nodes, string.sub(k, 6))
    			end
			end
    		return output
		else
			return nil
		end
    else
    	return nil
    end
end

--- @public
--- Builds the magnifying glass info formspec for the plant species with the given reference key
--- @param ref The reference key of the plant species
--- @param exit true if the back button should be type "button_exit", false if the back button should be type "button"
--- @return formspec string
function magnify.build_formspec_from_ref(ref, is_exit)
	local info = minetest.deserialize(magnify_plants:get(ref))

	if info ~= nil then
		-- entry good, return formspec
		local formtable = {  
    		"formspec_version[5]",
			"size[18.2,7.7]",
			"box[0.4,0.4;11.6,1.6;", minetest.formspec_escape(info.status_col or "#9192a3"), "]",
			"label[0.5,0.7;", minetest.formspec_escape(info.sci_name or "N/A"), "]",
			"label[0.5,1.2;", minetest.formspec_escape((info.com_name and "Common name: "..info.com_name) or "Common name unknown"), "]",
    		"label[0.5,1.7;", minetest.formspec_escape((info.fam_name and "Family: "..info.fam_name) or "Family unknown"), "]",
			--"image[12.4,0.4;5.4,5.4;", minetest.formspec_escape(info.texture or "test.png"), "]",
			"model[12.4,0.4;5.4,5.4;test_tree;tree_test.obj;default_acacia_tree_top.png,default_dry_grass_2.png,default_dry_dirt.png^default_dry_grass_side.png,default_acacia_leaves.png,default_acacia_tree.png,default_dry_grass_1.png,default_dry_grass_3.png,default_dry_grass_4.png,default_dry_grass.png;0,180;false;true;;]",
    
			"label[0.4,2.5;-]",
    		"label[0.4,3;-]",
			"label[0.4,3.5;-]",
    		"label[0.4,4;-]",
			"label[0.7,2.5;", minetest.formspec_escape(info.cons_status or "Conservation status unknown"), "]",
    		"label[0.7,3;", minetest.formspec_escape((info.region and "Native to "..info.region) or "Native region unknown"), "]",
			"label[0.7,3.5;", minetest.formspec_escape(info.height or "Height unknown"), "]",
			"label[0.7,4;", minetest.formspec_escape(info.bloom or "Bloom pattern unknown"), "]",
		
    		"textarea[0.35,4.45;11.5,1.3;;;", minetest.formspec_escape(info.more_info or ""), "]",
    		"label[0.4,6.25;", minetest.formspec_escape((info.img_copyright and "Image © "..info.img_copyright) or (info.img_credit and "Image courtesy of "..info.img_credit) or ""), "]",
			"label[0.4,6.75;", minetest.formspec_escape((info.external_link and "You can find more information at:") or ""), "]",
    		"textarea[0.35,6.9;11.6,0.6;;;", minetest.formspec_escape(info.external_link or ""), "]",
		
    		"button", (is_exit and "_exit") or "", "[12.4,6.1;5.4,1.2;back;Back]"
    	}
		return table.concat(formtable, "")
	else
		-- entry bad, go to fallback
		return nil
	end
end