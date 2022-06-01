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
--- @param exit true if the back button should be type "button_exit", false if the back button should be type "button"
--- @return formspec string
function magnify.build_formspec_from_ref(ref, is_exit)
    local info = minetest.deserialize(magnify_plants:get(ref))
    
    -- TODO: create V1 and V2 formtables
    if info ~= nil then
        -- entry good, return formspec
        if info.model_obj and info.model_spec and info.texture then
            -- v2: model and image
            local size = "size[17.4,9.3]"
            local formtable_v2 = {
                "formspec_version[5]", size,
      
                "box[0.4,0.4;12,1.6;", minetest.formspec_escape(info.status_col or "#9192a3"), "]",
                "textarea[0.45,0.45;12,0.6;;;", minetest.formspec_escape(info.sci_name or "Scientific name unknown"), "]",
                "label[0.5,1.2;", minetest.formspec_escape((info.com_name and "Common name:") or "Common name unknown"), "]",
                (info.com_name and "textarea[2.94,0.97;9.59,0.6;;;"..minetest.formspec_escape(info.com_name).."]"),
                "label[0.5,1.7;", minetest.formspec_escape((info.fam_name and "Family:") or "Family unknown"), "]",
                (info.fam_name and "textarea[1.63,1.47;10.92,0.6;;;"..minetest.formspec_escape(info.fam_name).."]"),

                "image[12.8,0.4;4.2,4.2;", info.texture or "test.png", "]",
                "box[12.8,4.7;4.2,4.2;#789cbf]",
                "model[12.8,4.7;4.2,4.2;plant_model;", info.model_obj, ";", info.model_spec, ";0,180;false;true;;]",
            
                "label[0.45,2.48;-]",
                "label[0.45,2.98;-]",
                "label[0.45,3.48;-]",
                "textarea[0.64,2.25;11.91,0.6;;;", minetest.formspec_escape(info.cons_status or "Conservation status unknown"), "]",
                "textarea[0.64,2.75;11.91,0.6;;;", minetest.formspec_escape((info.region and "Native to "..info.region) or "Native region unknown"), "]",
                "textarea[0.64,3.25;11.91,0.6;;;", minetest.formspec_escape(info.height or "Height unknown"), "]",
      
                "textarea[0.35,3.9;12.2,2.2;;;", minetest.formspec_escape((info.more_info and info.more_info.."\n") or ""), minetest.formspec_escape(info.bloom or "Bloom pattern unknown"), "]",
      
                "label[0.4,6.55;", minetest.formspec_escape((info.img_copyright and "Image © "..info.img_copyright) or (info.img_credit and "Image courtesy of "..info.img_credit) or ""), "]",
                --"label[0.4,7.15;", minetest.formspec_escape((info.external_link and "You can find more information at:") or ""), "]",
                --"textarea[0.35,7.35;12.2,0.6;;;", minetest.formspec_escape(info.external_link or ""), "]",
                "button", (is_exit and "_exit") or "", "[0.4,8;12,0.9;back;Back]"
            }
            return table.concat(formtable_v2, ""), size
        else
            -- v1: image
            local size = "size[18.2,7.7]"
            local formtable_v1 = {  
                "formspec_version[5]", size,
                
                "box[0.4,0.4;11.6,1.6;", minetest.formspec_escape(info.status_col or "#9192a3"), "]",
                "label[0.5,0.7;", minetest.formspec_escape(info.sci_name or "N/A"), "]",
                "label[0.5,1.2;", minetest.formspec_escape((info.com_name and "Common name: "..info.com_name) or "Common name unknown"), "]",
                "label[0.5,1.7;", minetest.formspec_escape((info.fam_name and "Family: "..info.fam_name) or "Family unknown"), "]",
                "image[12.4,0.4;5.4,5.4;", info.texture or "test.png", "]",
                --"model[12.4,0.4;5.4,5.4;test_tree;tree_test.obj;default_acacia_tree_top.png,default_dry_grass_2.png,default_dry_dirt.png^default_dry_grass_side.png,default_acacia_leaves.png,default_acacia_tree.png,default_dry_grass_1.png,default_dry_grass_3.png,default_dry_grass_4.png,default_dry_grass.png;0,180;false;true;;]",
    
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
                --"label[0.4,6.75;", minetest.formspec_escape((info.external_link and "You can find more information at:") or ""), "]",
                --"textarea[0.35,6.9;11.6,0.6;;;", minetest.formspec_escape(info.external_link or ""), "]",
        
                "button", (is_exit and "_exit") or "", "[12.4,6.1;5.4,1.2;back;Back]"
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
box[0.4,0.4;12,1.6;", minetest.formspec_escape(info.status_col or "#9192a3"), "]
textarea[0.45,0.45;12,0.6;;;", minetest.formspec_escape(info.sci_name or "Scientific name unknown"), "]
label[0.5,1.2;", minetest.formspec_escape((info.com_name and "Common name:") or "Common name unknown"), "]
textarea[2.94,0.97;9.59,0.6;;;"..minetest.formspec_escape(info.com_name).."]
label[0.5,1.7;", minetest.formspec_escape((info.fam_name and "Family:") or "Family unknown"), "]
textarea[1.63,1.47;10.92,0.6;;;"..minetest.formspec_escape(info.fam_name).."]
image[12.8,0.4;4.2,4.2;", minetest.formspec_escape(info.texture or "test.png"), "]
box[12.8,4.7;4.2,4.2;#008000]
label[0.45,2.48;-]
label[0.45,2.98;-]
label[0.45,3.48;-]
textarea[0.64,2.25;11.91,0.6;;;", minetest.formspec_escape(info.cons_status or "Conservation status unknown"), "]
textarea[0.64,2.75;11.91,0.6;;;", minetest.formspec_escape((info.region and "Native to "..info.region) or "Native region unknown"), "]
textarea[0.64,3.25;11.91,0.6;;;", minetest.formspec_escape(info.height or "Height unknown"), "]
textarea[0.35,3.9;12.2,2.2;;;", minetest.formspec_escape((info.more_info and info.more_info.."\n") or ""), minetest.formspec_escape(info.bloom or "Bloom pattern unknown"), "]
label[0.4,6.55;", minetest.formspec_escape((info.img_copyright and "Image © "..info.img_copyright) or (info.img_credit and "Image courtesy of "..info.img_credit) or ""), "]
label[0.4,7.15;", minetest.formspec_escape((info.external_link and "You can find more information at:") or ""), "]
textarea[0.35,7.35;12.2,0.6;;;", minetest.formspec_escape(info.external_link or ""), "]
button[0.4,8;12,0.9;back;Back]

-- V1
formspec_version[5]
size[18.2,7.7]
box[0.4,0.4;11.6,1.6;", minetest.formspec_escape(info.status_col or "#9192a3"), "]
label[0.5,0.7;", minetest.formspec_escape(info.sci_name or "N/A"), "]
label[0.5,1.2;", minetest.formspec_escape((info.com_name and "Common name: "..info.com_name) or "Common name unknown"), "]
label[0.5,1.7;", minetest.formspec_escape((info.fam_name and "Family: "..info.fam_name) or "Family unknown"), "]
image[12.4,0.4;5.4,5.4;", minetest.formspec_escape(info.texture or "test.png"), "]
label[0.4,2.5;-]
label[0.4,3;-]
label[0.4,3.5;-]
label[0.4,4;-]
label[0.7,2.5;", minetest.formspec_escape(info.cons_status or "Conservation status unknown"), "]
label[0.7,3;", minetest.formspec_escape((info.region and "Native to "..info.region) or "Native region unknown"), "]
label[0.7,3.5;", minetest.formspec_escape(info.height or "Height unknown"), "]
label[0.7,4;", minetest.formspec_escape(info.bloom or "Bloom pattern unknown"), "]
textarea[0.35,4.45;11.5,1.3;;;", minetest.formspec_escape(info.more_info or ""), "]
label[0.4,6.25;", minetest.formspec_escape((info.img_copyright and "Image © "..info.img_copyright) or (info.img_credit and "Image courtesy of "..info.img_credit) or ""), "]
label[0.4,6.75;", minetest.formspec_escape((info.external_link and "You can find more information at:") or ""), "]
textarea[0.35,6.9;11.6,0.6;;;", minetest.formspec_escape(info.external_link or ""), "]
button[12.4,6.1;5.4,1.2;back;Back]
]]