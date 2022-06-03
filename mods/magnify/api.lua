-- EXPORTED MAGNIFY FUNCTIONS
magnify = {}

-- Instantiate unique time code for plant updates
--local prev_date_str = magnify_plants:get_string("reg_time_old")
--magnify_plants:set_string("reg_time_old", prev_date_str)
--local date_str = os.date("%Y%m%d%H%M%S-V1", os.time())
--magnify_plants:set_string("reg_time", date_str)

--- @public
--- Adds a plant to the magnify plant database
--- @param def_table Definition table for the species being added
--- @param blocks Table of stringified nodes this species corresponds to in the MineTest world
--- @see Magnify documentation for more information on how to register a plant species
function magnify.register_plant(def_table, blocks) 
    local ref = magnify_plants:get_int("count")
    local serial_table = minetest.serialize(def_table)
    magnify_plants:set_string("ref_"..ref, serial_table)

    --local key_table = {key = "ref_"..ref, reg_time = date_str}
    --local serial_ref = minetest.serialize(key_table)
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
                local ref_num = string.sub(k, 5)
                local name_string = "###" .. ref_num .. ": " .. info.com_name .. " (" .. info.sci_name .. ")" -- if changed, update get_species_ref in mc_teacher/gui_dash.lua
                table.insert(output, name_string)
            end
        end
    end
    table.sort(output, mc_helpers.numSubstringCompare)
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

--- @private
--- Removes a node key from the magnify database
--- @param node_name Name of the node to clear
--- @return reference key the removed node key pointed to, nil if the node did not exist
local function clear_node_key(node_name)
    old_ref = magnify_plants:get_string("node_"..node_name)
    magnify_plants:set_string("node_"..node_name, "")
    return (old_ref ~= "" and old_ref) or nil
end

--- @public
--- Removes the keys for all nodes in the given table from the magnify database
--- Then, removes any reference tables that are no longer being pointed to by any nodes as a result of the node key removal
--- @param node_table Table of nodes to remove, all in the format "modname:name"
function magnify.clear_nodes(node_table)
    -- remove node keys
    local changed_refs = {}
    for _,node in pairs(node_table) do
        table.insert(changed_refs, clear_node_key(node))
    end

    -- check affected refs to ensure that node still point to them
    local storage_data = magnify_plants:to_table()
    for k,v in pairs(storage_data.fields) do
        for i,ref in pairs(changed_refs) do
            if v == ref then
                changed_refs[i] = nil
            end
        end
    end

    -- remove affected refs which no longer have nodes pointing to them
    for _,ref in pairs(changed_refs) do
        magnify.clear_ref(ref)
    end
end

--- @public
--- Returns information about the plant species indexed at the given reference key
--- @param ref The reference key of the plant species
--- @return table, table
function magnify.get_species_from_ref(ref)
    local storage_data = magnify_plants:to_table()
    local output_nodes = {}
  
    if magnify_plants:get(ref) then
        local data = minetest.deserialize(magnify_plants:get_string(ref))
        if data then
            for k,v in pairs(storage_data.fields) do
                if v == ref then
                    table.insert(output_nodes, string.sub(k, 6))
                end
            end
            return data,output_nodes
        else
            return nil,nil
        end
    else
        return nil,nil
    end
end

--- @public
--- Builds the magnifying glass info formspec for the plant species with the given reference key
--- @param ref The reference key of the plant species
--- @param is_exit true if the back button should be type "button_exit", false if the back button should be type "button"
--- @param is_inv true if the formspec is being used in the inventory, false otherwise
--- @return formspec string, formspec size[] string
function magnify.build_formspec_from_ref(ref, is_exit, is_inv)
    local info = minetest.deserialize(magnify_plants:get(ref))
    
    -- TODO: create V1 and V2 formtables
    if info ~= nil then
        -- entry good, return formspec
        if info.model_obj and info.model_spec and info.texture then
            -- v2: model and image
            local size = (is_inv and "size[13.8,7.2]") or "size[17.4,9.3]"
            local formtable_v2 = {
                "formspec_version[5]", size,

                "box[", (is_inv and "0,0;10,1.6") or "0.4,0.4;12,1.6", ";", minetest.formspec_escape(info.status_col or "#9192A3"), "]",
                "textarea[", (is_inv and "0.45,0.08;10.4,0.7") or "0.45,0.45;12.4,0.7", ";;;", minetest.formspec_escape(info.sci_name or "N/A"), "]",
                "textarea[", (is_inv and "0.45,0.59;10.4,0.7") or "0.45,0.96;12.4,0.7", ";;;", minetest.formspec_escape((info.com_name and "Common name: "..info.com_name) or "Common name unknown"), "]",
                "textarea[", (is_inv and "0.45,1.1;10.4,0.7") or "0.45,1.47;12.4,0.7", ";;;", minetest.formspec_escape((info.fam_name and "Family: "..info.fam_name) or "Family unknown"), "]",

                "image[", (is_inv and "10.3,0") or "12.8,0.4", ";4.2,4.2;", info.texture or "test.png", "]",
                "box[", (is_inv and "10.3,3.7;3.35,3.65") or "12.8,4.7;4.2,4.2", ";#789cbf]",
                "model[", (is_inv and "10.3,3.7") or "12.8,4.7", ";4.2,4.2;plant_model;", info.model_obj, ";", info.model_spec, ";0,180;false;true;;]",

                "textarea[", (is_inv and "0.3,1.8;10.45,4.7") or "0.35,2.3;12.4,4.7", ";;;", -- info area
                "- ", minetest.formspec_escape(info.cons_status or "Conservation status unknown"), "\n",
                "- ", minetest.formspec_escape((info.region and "Found in "..info.region) or "Location range unknown"), "\n",
                "- ", minetest.formspec_escape(info.height or "Height unknown"), "\n",
                "\n",
                minetest.formspec_escape((info.more_info and info.more_info.."\n") or ""),
                minetest.formspec_escape(info.bloom or "Bloom pattern unknown"),
                "]",

                "textarea[", (is_inv and "0.3,6;10.4,0.7") or "0.35,7.2;12.4,0.7", ";;;", minetest.formspec_escape((info.img_copyright and "Image © "..info.img_copyright) or (info.img_credit and "Image courtesy of "..info.img_credit) or ""), "]",
                --"label[0.4,7.15;", minetest.formspec_escape((info.external_link and "You can find more information at:") or ""), "]",
                --"textarea[0.35,7.35;12.2,0.6;;;", minetest.formspec_escape(info.external_link or ""), "]",
                "button", (is_exit and "_exit") or "", "[", (is_inv and "0,6.75;10.2,0.6") or "0.4,8;12,0.9", ";back;Back]"
            }
            return table.concat(formtable_v2, ""), size
        else
            -- v1: image
            local size = (is_inv and "size[14.7,5.9]") or "size[18.5,7.7]"
            local formtable_v1 = {  
                "formspec_version[5]", size,
                
                "box[", (is_inv and "0,0;9.6,1.6") or "0.4,0.4;11.6,1.6", ";", minetest.formspec_escape(info.status_col or "#9192a3"), "]",
                "textarea[", (is_inv and "0.45,0.08;10,0.7") or "0.45,0.45;12.4,0.7", ";;;", minetest.formspec_escape(info.sci_name or "N/A"), "]",
                "textarea[", (is_inv and "0.45,0.59;10,0.7") or "0.45,0.96;12.4,0.7", ";;;", minetest.formspec_escape((info.com_name and "Common name: "..info.com_name) or "Common name unknown"), "]",
                "textarea[", (is_inv and "0.45,1.1;10,0.7") or "0.45,1.47;12.4,0.7", ";;;", minetest.formspec_escape((info.fam_name and "Family: "..info.fam_name) or "Family unknown"), "]",
                "image[", (is_inv and "9.9,0") or "12.4,0.4", ";5.7,5.7;", info.texture or "test.png", "]",
                --"model[12.4,0.4;5.4,5.4;test_tree;tree_test.obj;default_acacia_tree_top.png,default_dry_grass_2.png,default_dry_dirt.png^default_dry_grass_side.png,default_acacia_leaves.png,default_acacia_tree.png,default_dry_grass_1.png,default_dry_grass_3.png,default_dry_grass_4.png,default_dry_grass.png;0,180;false;true;;]",
    
                "textarea[", (is_inv and "0.3,1.8;10.05,4.3") or "0.35,2.3;12,4.4", ";;;", -- info area
                "- ", minetest.formspec_escape(info.cons_status or "Conservation status unknown"), "\n",
                "- ", minetest.formspec_escape((info.region and "Found in "..info.region) or "Location range unknown"), "\n",
                "- ", minetest.formspec_escape(info.height or "Height unknown"), "\n",
                "\n",
                minetest.formspec_escape((info.more_info and info.more_info.."\n") or ""),
                minetest.formspec_escape(info.bloom or "Bloom pattern unknown"),
                "]",

                "textarea[", (is_inv and "0.3,5.6;11.6,0.7") or "0.35,6.9;11.6,0.7", ";;;", minetest.formspec_escape((info.img_copyright and "Image © "..info.img_copyright) or (info.img_credit and "Image courtesy of "..info.img_credit) or ""), "]",
                --"label[0.4,6.75;", minetest.formspec_escape((info.external_link and "You can find more information at:") or ""), "]",
                --"textarea[0.35,6.9;11.6,0.6;;;", minetest.formspec_escape(info.external_link or ""), "]",
		
                "button", (is_exit and "_exit") or "", "[", (is_inv and "9.9,5.4;4.8,0.6") or "12.4,6.4;5.7,0.9", ";back;Back]"
            }
            return table.concat(formtable_v1, ""), size
        end
    else
        -- entry bad, go to fallback
        return nil
    end
end

--[[ formtable clean copies, for editing
-- V2
formspec_version[5]
size[17.4,9.3]
box[0.4,0.4;12,1.6;", minetest.formspec_escape(info.status_col or "#9192A3"), "]
textarea[0.45,0.45;12.4,0.7;;;", minetest.formspec_escape(info.sci_name or "N/A"), "]
textarea[0.45,0.97;12.4,0.7;;;", minetest.formspec_escape((info.com_name and "Common name: "..info.com_name) or "Common name unknown"), "]
textarea[0.45,1.47;12.4,0.7;;;", minetest.formspec_escape((info.fam_name and "Family: "..info.fam_name) or "Family unknown"), "]
image[12.8,0.4;4.2,4.2;", info.texture or "test.png", "]
box[12.8,4.7;4.2,4.2;#789cbf]
textarea[0.35,2.3;12.4,4.7;;;"add the original giant text box here"]
textarea[0.35,7.2;12.4,0.7;;;", minetest.formspec_escape((info.img_copyright and "Image © "..info.img_copyright) or (info.img_credit and "Image courtesy of "..info.img_credit) or ""), "]
button[0.4,8;12,0.9;back;Back]

-- V1
formspec_version[5]
size[18.5,7.7]
box[0.4,0.4;11.6,1.6;", minetest.formspec_escape(info.status_col or "#9192a3"), "]
textarea[0.45,0.45;12,0.7;;;", minetest.formspec_escape(info.sci_name or "N/A"), "]
textarea[0.45,0.97;12,0.7;;;", minetest.formspec_escape((info.com_name and "Common name: "..info.com_name) or "Common name unknown"), "]
textarea[0.45,1.47;12,0.7;;;", minetest.formspec_escape((info.fam_name and "Family: "..info.fam_name) or "Family unknown"), "]
image[12.4,0.4;5.7,5.7;", minetest.formspec_escape(info.texture or "test.png"), "]
textarea[0.35,2.3;12,4.4;;;"add the original giant text box here"]
textarea[0.35,6.9;11.6,0.7;;;", minetest.formspec_escape((info.img_copyright and "Image © "..info.img_copyright) or (info.img_credit and "Image courtesy of "..info.img_credit) or ""), "]
button[12.4,6.4;5.4,0.9;back;Back]
]]

---@public
---Returns true if any of the values in the given table is equal to the value provided
---@param table The table to check
---@param val The value to check for
---@return boolean whether the value exists in the table
function magnify.table_has(table, val)
    if not table or not val then return false end
    for k,v in pairs(table) do
        if k == val or v == val then return true end
    end
    return false
end