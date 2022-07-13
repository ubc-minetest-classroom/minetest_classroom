--- @private
--- Searches for a reference key with information matching the information in def_table, and returns it if found. Otherwise, returns the next unused reference key
--- @param def_table Plant species definition table
--- @return number
local function find_registration_ref(def_table)
    -- search for a matching scientific name
    local storage_data = magnify_plants.ref:to_table()
    for k,v in pairs(storage_data.fields) do
        local data = minetest.deserialize(v)
        if type(data) == "table" and def_table.sci_name and (def_table.sci_name == data.sci_name) then
            return tonumber(k)
        end
    end

    local count = tonumber(magnify_plants.ref:get("count") or 1)
    magnify_plants.ref:set_int("count", count + 1)
    return count
end

--- @public
--- Registers a plant species in the `magnify` plant database
--- Should only be called on mod load-in 
--- @param def_table Plant species definition table
--- @param nodes Table of stringified nodes the species corresponds to in the MineTest world
--- @see README.md > API > Registration
function magnify.register_plant(def_table, nodes)
    local ref = find_registration_ref(def_table)
    def_table["origin"] = minetest.get_current_modname()

    local serial_table = minetest.serialize(def_table)
    magnify_plants.ref:set_string(ref, serial_table)
    for k,v in pairs(nodes) do
        magnify_plants.node[v] = ref
    end
end

--- @public
--- Returns the reference key associated with `node` in the `magnify` plant database
--- @param node Stringified node
--- @return number or nil
function magnify.get_ref(node)
    return magnify_plants.node[node]
end

--- @public
--- Clears a plant species and all its associated nodes from the `magnify` plant database
--- @param ref Reference key of the plant species to clear
function magnify.clear_ref(ref)
    local storage_data = magnify_plants.ref:to_table()
    for k,v in pairs(storage_data.fields) do
        if k == ref or v == ref then
            magnify_plants.ref:set_string(k, "")
        end
    end
    for k,v in pairs(magnify_plants.node) do
        if k == ref or v == ref then
            magnify_plants.node[k] = nil
        end
    end
end

--- @private
--- Clears a node from the magnify database and returns the reference key the removed node key pointed to
--- @param node Stringified node to clear
--- @return string or nil
local function clear_node_key(node)
    old_ref = magnify.get_ref(node)
    magnify_plants.node[node] = nil
    return old_ref
end

--- @public
--- Clears the nodes in `nodes` from the `magnify` plant database
--- Then, clears any plants species that are no longer associated with any nodes as a result of clearing the nodes in `nodes`
--- @param nodes Table of stringified nodes to clear
function magnify.clear_nodes(nodes)
    -- remove node keys
    local changed_refs = {}
    for _,node in pairs(nodes) do
        table.insert(changed_refs, clear_node_key(node))
    end

    -- check affected refs to ensure that nodes still point to them
    for k,v in pairs(magnify_plants.node) do
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
--- Returns the plant definition table the species indexed at `ref` in the `magnify` plant database, and a list of nodes the species is associated with
--- @param ref Reference key of the plant species
--- @return table, table or nil
function magnify.get_species_from_ref(ref)
    local output_nodes = {}
  
    if magnify_plants.ref:get(tostring(ref)) then
        local data = minetest.deserialize(magnify_plants.ref:get_string(tostring(ref)))
        if data then
            for k,v in pairs(magnify_plants.node) do
                if v == ref then
                    table.insert(output_nodes, k)
                end
            end
            return data,output_nodes
        else
            return nil
        end
    else
        return nil
    end
end

--- @private
--- Sorting comparison function for registered plant species
--- Sorts by common name, then scientific name, in alphabetical order
--- Fallbacks:
--- If both ref_a and ref_b are invalid, returns ref_a < ref_b (default sort)
--- If exactly one of ref_a and ref_b is invalid, returns whether ref_a is valid or not
--- @param ref_a Reference key of the first species to be sorted
--- @param ref_b Reference key of the second species to be sorted
--- @return boolean
local function species_compare(ref_a, ref_b)
    local species_a = magnify.get_species_from_ref(ref_a)
    local species_b = magnify.get_species_from_ref(ref_b)
    if species_a and species_b then
        if species_a.com_name ~= species_b.com_name then
            return species_a.com_name < species_b.com_name
        else
            return species_a.sci_name < species_b.sci_name
        end
    elseif not species_a and not species_b then
        return ref_a < ref_b
    else
        return species_a or false
    end
end

--- @public
--- Returns a human-readable list of all species registered in the `magnify` plant database, and a list of reference keys corresponding to them
--- Each species and its corresponding reference key will be at the same index in both lists
--- @return table, table
function magnify.get_all_registered_species()
    local storage_data = magnify_plants.ref:to_table()
    local raw_name_table = {}
    local ref_keys = {}

    for k,v in pairs(storage_data.fields) do
        local info = minetest.deserialize(v)
        if info then
            raw_name_table[k]  = info.com_name .. " (" .. info.sci_name .. ")"
            table.insert(ref_keys, k)
        end
    end

    local name_table = {}
    table.sort(ref_keys, species_compare)
    for i,k in ipairs(ref_keys) do
        name_table[i] = raw_name_table[k]
    end

    return name_table, ref_keys
end

--- @private
--- Returns the path of obj in origin's mod directory, or nil if obj could not be found
--- @param origin Name of mod whose directory should be searched
--- @param obj File to search for
--- @return string or nil
local function get_obj_directory(origin, obj)
    local root = minetest.get_modpath(origin)
    if not root then
        return nil
    end

    -- check if the "models" contains the object
    if magnify.table_has(minetest.get_dir_list(root.."/models", false), obj) then
        -- Return path to object in "models" directory
        return root.."/models/"..obj
    else
        local dir = table.remove(string.split(root, "\\"))
        local trimmed_root = string.sub(root, 1, #root - #dir - 1)

        --- Recursively searches for obj: returns the path of obj in the root directory, or nil if obj could not be found
        --- @param file File currently being compared with obj
        --- @param path Path to file
        --- @param file_wl List of remaining files to be compared with obj
        --- @param path_wl Corresponding list of paths to files in file_wl
        --- @return string or nil
        local function get_file_directory_tr(file, path, file_wl, path_wl)
            if not file then
                return nil
            elseif file == obj then
                return path.."/"..file
            else
                -- add new files/folders to list
                local new_files = minetest.get_dir_list(path.."/"..file)
                local new_paths = {}
                for k,v in ipairs(new_files) do
                    table.insert(new_paths, path.."/"..file)
                end
                table.insert_all(file_wl, new_files)
                table.insert_all(path_wl, new_paths)

                -- get next file/folder to search
                local next_file = table.remove(file_wl, 1)
                local next_path = table.remove(path_wl, 1)

                -- continue recursive search, if file exists
                return get_file_directory_tr(next_file, next_path, file_wl, path_wl)
            end
        end

        -- Begin tail-recursive search
        return get_file_directory_tr(dir, trimmed_root, {}, {})
    end
end

--- @private
--- Reads the textures from a .obj file and returns them as a table of strings
--- @param target_obj Object file to read
--- @return table
local function read_obj_textures(target_obj)
    local textures = {}
    local model_iter = io.lines(target_obj, "r")
    local line = model_iter()
    while line do 
        local match = string.match(line, "^g (.*)")
        if match then
            table.insert(textures, match)
        end
        line = model_iter()
        if not line then break end
    end
    return textures
end

--- @public
--- Builds the general plant information formspec for the species indexed at `ref` in the `magnify` plant database 
--- @param ref Reference key of the plant species
--- @param is_exit true if clicking the "Back" button should exit the formspec, false otherwise
--- @param is_inv true if the formspec is being used in the player inventory, false otherwise
--- @return (formspec string, formspec "size[]" string) or nil
function magnify.build_formspec_from_ref(ref, is_exit, is_inv)
    local info = minetest.deserialize(magnify_plants.ref:get(ref))
    
    -- TODO: create V1 and V2 formtables
    if info ~= nil then
        -- entry good, return formspec
        local model_spec_loc = (info.model_obj and info.origin) and get_obj_directory(info.origin, info.model_obj)
        if model_spec_loc then
            -- v2: model and image
            local model_spec = read_obj_textures(model_spec_loc)
            local size = (is_inv and "size[13.8,7.2]") or "size[17.4,9.3]"
            local formtable_v2 = {
                "formspec_version[5]", size,

                "box[", (is_inv and "0,0;10,1.6") or "0.4,0.4;12,1.6", ";", minetest.formspec_escape(info.status_col or "#9192A3"), "]",
                "textarea[", (is_inv and "0.45,0.08;10.4,0.7") or "0.45,0.45;12.4,0.7", ";;;", minetest.formspec_escape(info.sci_name or "N/A"), "]",
                "textarea[", (is_inv and "0.45,0.59;10.4,0.7") or "0.45,0.96;12.4,0.7", ";;;", minetest.formspec_escape((info.com_name and "Common name: "..info.com_name) or "Common name unknown"), "]",
                "textarea[", (is_inv and "0.45,1.1;10.4,0.7") or "0.45,1.47;12.4,0.7", ";;;", minetest.formspec_escape((info.fam_name and "Family: "..info.fam_name) or "Family unknown"), "]",

                "image[", (is_inv and "10.3,0") or "12.8,0.4", ";4.2,4.2;", (type(info.texture) == "table" and info.texture[1]) or info.texture or "test.png", "]",
                "box[", (is_inv and "10.3,3.7;3.35,3.65") or "12.8,4.7;4.2,4.2", ";#789cbf]",
                "model[", (is_inv and "10.3,3.7") or "12.8,4.7", ";4.2,4.2;plant_model;", info.model_obj, ";", table.concat(model_spec, ","), ";", info.model_rot_x or "0", ",", info.model_rot_y or "180", ";false;true;;]",

                "textarea[", (is_inv and "0.3,1.8;10.45,4.7") or "0.35,2.3;12.4,4.7", ";;;", -- info area
                "- ", minetest.formspec_escape(info.cons_status or "Conservation status unknown"), "\n",
                "- ", minetest.formspec_escape((info.region and "Found in "..info.region) or "Location range unknown"), "\n",
                "- ", minetest.formspec_escape(info.height or "Height unknown"), "\n",
                "\n",
                minetest.formspec_escape((info.more_info and info.more_info.."\n") or ""),
                minetest.formspec_escape(info.bloom or "Bloom pattern unknown"),
                "]",

                "textarea[", (is_inv and "0.3,6;10.4,0.7") or "0.35,7.2;12.4,0.7", ";;;", minetest.formspec_escape((info.img_copyright and "Image © "..info.img_copyright) or (info.img_credit and "Image courtesy of "..info.img_credit) or ""), "]",
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
                "image[", (is_inv and "9.9,0") or "12.4,0.4", ";5.7,5.7;", (type(info.texture) == "table" and info.texture[1]) or info.texture or "test.png", "]",
    
                "textarea[", (is_inv and "0.3,1.8;10.05,4.3") or "0.35,2.3;12,4.4", ";;;", -- info area
                "- ", minetest.formspec_escape(info.cons_status or "Conservation status unknown"), "\n",
                "- ", minetest.formspec_escape((info.region and "Found in "..info.region) or "Location range unknown"), "\n",
                "- ", minetest.formspec_escape(info.height or "Height unknown"), "\n",
                "\n",
                minetest.formspec_escape((info.more_info and info.more_info.."\n") or ""),
                minetest.formspec_escape(info.bloom or "Bloom pattern unknown"),
                "]",

                "textarea[", (is_inv and "0.3,5.6;11.6,0.7") or "0.35,6.9;11.6,0.7", ";;;", minetest.formspec_escape((info.img_copyright and "Image © "..info.img_copyright) or (info.img_credit and "Image courtesy of "..info.img_credit) or ""), "]",
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
image[12.8,0.4;4.2,4.2;", (type(info.texture) == "table" and info.texture[1]) or info.texture or "test.png", "]
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
image[12.4,0.4;5.7,5.7;", (type(info.texture) == "table" and info.texture[1]) or info.texture or "test.png", "]
textarea[0.35,2.3;12,4.4;;;"add the original giant text box here"]
textarea[0.35,6.9;11.6,0.7;;;", minetest.formspec_escape((info.img_copyright and "Image © "..info.img_copyright) or (info.img_credit and "Image courtesy of "..info.img_credit) or ""), "]
button[12.4,6.4;5.4,0.9;back;Back]
]]

--- @public
--- Returns true if any of the keys or values in `table` match `val`, false otherwise
--- @param table The table to check
--- @param val The key/value to check for
--- @return boolean
function magnify.table_has(table, val)
    if not table or not val then return false end
    for k,v in pairs(table) do
        if k == val or v == val then return true end
    end
    return false
end