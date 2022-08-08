-----------------------
---     HELPERS     ---
-----------------------

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

-----------------------
---     GENERAL     ---
-----------------------

--- @private
--- Searches for a reference key with information matching the information in def_table, and returns it if found, along with a string indicating the format of the reference key
--- Otherwise, returns the next unused reference key
--- @param def_table Species definition table
--- @return string, string
local function find_registration_ref(def_table)
    -- search for a matching scientific name
    local storage_data = magnify.species.ref:to_table()
    for k,v in pairs(storage_data.fields) do
        local data = minetest.deserialize(v)
        if type(data) == "table" and def_table.sci_name and (def_table.sci_name == data.sci_name) then
            if string.sub(tostring(k), 1, 4) == "ref_" then
                return tostring(k), "v1"
            else
                return tostring(k), "v2"
            end
        end
    end

    local count = tonumber(magnify.species.ref:get("count") or 1)
    magnify.species.ref:set_int("count", count + 1)
    return tostring(count), "v2"
end

--- @public
--- Registers a species in the `magnify` species database
--- Should only be called on mod load-in 
--- @param def_table Species definition table
--- @param nodes Table of stringified nodes the species corresponds to in the MineTest world
--- @return string
--- @deprecated use magnify.register_species instead
function magnify.register_plant(def_table, nodes)
    return magnify.register_species(def_table, nodes)
end

--- @public
--- Registers a species in the `magnify` species database
--- Should only be called on mod load-in 
--- @param def_table Species definition table
--- @param nodes Table of stringified nodes the species corresponds to in the MineTest world
--- @return string or nil
--- @see README.md > API > Registration
function magnify.register_species(def_table, nodes)
    if type(nodes) ~= "table" or not next(nodes) then
        return nil -- no nodes given
    end

    local ref, format = find_registration_ref(def_table)
    def_table["origin"] = minetest.get_current_modname()

    -- migrate old format reference keys
    if format ~= "v2" then
        if format == "v1" then
            magnify.species.ref:set_string(ref, "")
            ref = string.sub(ref, 5)
        else
            return nil -- could not determine ref key
        end
    end

    local serial_table = minetest.serialize(def_table)
    magnify.species.ref:set_string(ref, serial_table)
    for k,v in pairs(nodes) do
        magnify.species.node[v] = ref
    end

    return ref
end

--- @public
--- Returns the reference key associated with `node` in the `magnify` species database
--- @param node Stringified node
--- @return string or nil
function magnify.get_ref(node)
    local ref = magnify.species.node[node]
    return ref and tostring(ref) or nil
end

--- @public
--- Clears a species and all its associated nodes from the `magnify` species database
--- @param ref Reference key of the species to clear
function magnify.clear_ref(ref)
    local storage_data = magnify.species.ref:to_table()
    for k,v in pairs(storage_data.fields) do
        if tostring(k) == tostring(ref) then
            magnify.species.ref:set_string(k, "")
        end
    end
    for k,v in pairs(magnify.species.node) do
        if tostring(v) == tostring(ref) then
            magnify.species.node[k] = nil
        end
    end
end

--- @private
--- Clears a node from the magnify database and returns the reference key the removed node key pointed to
--- @param node Stringified node to clear
--- @return string or nil
local function clear_node_key(node)
    old_ref = magnify.get_ref(node)
    magnify.species.node[node] = nil
    return old_ref
end

--- @public
--- Clears the nodes in `nodes` from the `magnify` species database,
--- then clears any species that are no longer associated with any nodes as a result of clearing the nodes in `nodes`
--- @param nodes Table of stringified nodes to clear
function magnify.clear_nodes(nodes)
    -- remove node keys
    local changed_refs = {}
    for _,node in pairs(nodes) do
        table.insert(changed_refs, clear_node_key(node))
    end

    -- check affected refs to ensure that nodes still point to them
    for k,v in pairs(magnify.species.node) do
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
--- Returns the species definition table the species indexed at `ref` in the `magnify` species database, and a list of nodes the species is associated with
--- @param ref Reference key of the species
--- @return table, table or nil
function magnify.get_species_from_ref(ref)
    local output_nodes = {}
  
    if magnify.species.ref:get(tostring(ref)) then
        local data = minetest.deserialize(magnify.species.ref:get_string(tostring(ref)))
        if data then
            for k,v in pairs(magnify.species.node) do
                if tostring(v) == tostring(ref) then
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
--- Sorting comparison function for registered species
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
--- Returns a human-readable list of all species registered in the `magnify` species database, and a list of reference keys corresponding to them
--- Each species and its corresponding reference key will be at the same index in both lists
--- @return table, table
function magnify.get_all_registered_species()
    local storage_data = magnify.species.ref:to_table()
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

--- @private
--- Gets the description for a conservation status and returns it as a string, and returns the colour associated with that status
--- @param cons_status Plant definition cons_status field
--- @return string, string
local function get_cons_status_info(cons_status)
    if cons_status then
        local status = (type(cons_status) == "table" and cons_status.ns_bc) or cons_status
        local status_info = magnify.map.ns_bc[status]
        if status_info then
            local desc = status_info["desc"]
            return status..(desc and desc ~= "" and " - "..desc or ""), status_info["col"]
        else
            return status
        end
    else
        return nil
    end
end

--- @public
--- Builds the general species information formspec for the species indexed at `ref` in the `magnify` species database 
--- @param ref Reference key of the species
--- @param is_exit true if clicking the "Back" button should exit the formspec, false otherwise
--- @param is_inv true if the formspec is being used in the player inventory, false otherwise
--- @return (formspec string, formspec "size[]" string) or nil
function magnify.build_formspec_from_ref(ref, is_exit, is_inv)
    local info = minetest.deserialize(magnify.species.ref:get(ref))
  
    if info ~= nil then
        -- entry good, return V3 formspec
        local model_spec_loc = (info.model_obj and info.origin) and get_obj_directory(info.origin, info.model_obj)
        local cons_status_desc, status_col = get_cons_status_info(info.cons_status)
        local size = "size[17,12.6]"
        local formtable_v3 = {
            "formspec_version[6]", size,
        
            -- TODO: add style elements
        
            "box[0,0;17,0.6;#FFFFFF]",
            "label[6.7,0.3;Plant Compendium]",
            "button", is_exit and "_exit" or "", "[0.8,0.8;1,0.6;back;Back]",
            "image[0.2,0.8;0.6,0.6;texture.png]",
            "button[8.1,0.8;2.6,0.6;locate;Locate in World]",
            "image[7.5,0.8;0.6,0.6;texture.png]",
            "button[11.5,0.8;3.5,0.6;view;View in Compendium]",
            "image[10.9,0.8;0.6,0.6;texture.png]",
            "button[15.8,0.8;1,0.6;save;Save]",
            "image[15.2,0.8;0.6,0.6;texture.png]",
            "box[0.2,1.4;16.6,4.8;#FFFFFF]",
            "box[0.3,1.5;8.9,4.6;#000000]",

            --"box[", (is_inv and "0,0;10,1.6") or "0.4,0.4;12,1.6", ";", minetest.formspec_escape(status_col or "#9192A3"), "]",
            "label[0.5,2.45;", minetest.formspec_escape(info.sci_name or "Scientific name unknown"), "]",
            "label[0.5,3;", minetest.formspec_escape(info.com_name or "Common name unknown"), "]",
            "label[0.5,1.9;", minetest.formspec_escape((info.fam_name and "Family: "..info.fam_name..(magnify.map.family[info.fam_name] and " ("..magnify.map.family[info.fam_name]..")" or "")) or "Family unknown"), "]",
        
            -- TODO: add tag labels dynamically
            "box[0.5,4.1;1.4,0.6;#0000FF]",
            "label[0.7,4.4;Status]",
            "box[2.1,4.1;1.2,0.6;#00FF00]",
            "label[2.3,4.4;Type]",
            "box[3.5,4.1;1.5,0.6;#00FF00]",
            "label[3.7,4.4;Type 2]",
            "box[5.2,4.1;1.5,0.6;#FFA500]",
            "label[5.4,4.4;Type 3]",
        
            "image[", "9.3,1.5;7.4,4.15;", (type(info.texture) == "table" and info.texture[1]) or info.texture or "test.png", "]",
            --"box[", (is_inv and "10.3,3.7;3.35,3.65") or "12.8,4.7;4.2,4.2", ";#789cbf]",

            "textarea[", "0.2,6.3;9,5.7", ";;;", -- info area
            --"- ", minetest.formspec_escape(cons_status_desc or "Conservation status unknown"), "\n",
            "- ", minetest.formspec_escape((info.region and "Found in "..info.region) or "Location range unknown"), "\n",
            "- ", minetest.formspec_escape(info.height or "Height unknown"), "\n",
            "\n",
            minetest.formspec_escape((info.more_info and info.more_info.."\n") or ""),
            minetest.formspec_escape(info.bloom or "Bloom pattern unknown"),
            "]",
        
            "image_button[9.3,6.3;1.8,1;", type(info.texture) == "table" and info.texture[2] or "test.png", ";;;false;false]",
            "image_button[11.2,6.3;1.8,1;", type(info.texture) == "table" and info.texture[3] or "test.png", ";;;false;false]",
            "image_button[13.1,6.3;1.8,1;", type(info.texture) == "table" and info.texture[4] or "test.png", ";;;false;false]",
            "image_button[15,6.3;1.8,1;", type(info.texture) == "table" and info.texture[5] or "test.png", ";;;false;false]",
          }
        
        if model_spec_loc then
              -- add model + image 6
              local model_spec = read_obj_textures(model_spec_loc)
              table.insert(formtable_v3, table.concat({
                "model[", "9.3,7.4;3.7,4.6", ";plant_model;", info.model_obj, ";", table.concat(model_spec, ","), ";", info.model_rot_x or "0", ",", info.model_rot_y or "180", ";false;true;;]",
                "image[", "13.1,7.4;3.7,4.6", ";", (type(info.texture) == "table" and info.texture[6]) or "test.png", "]",
              }))
        else
              -- add images 6 + 7
              table.insert(formtable_v3, table.concat({
                "image[9.3,7.4;3.7,4.6;", (type(info.texture) == "table" and info.texture[6]) or "test.png", "]",
                "image[13.1,7.4;3.7,4.6;", (type(info.texture) == "table" and info.texture[7]) or "test.png", "]",
              }))
          end
    
        table.insert(formtable_v3, table.concat({
            "textarea[", "9.3,5.65;7.4,0.7", ";;;", minetest.formspec_escape((info.img_copyright and "Image © "..info.img_copyright) or (info.img_credit and "Image courtesy of "..info.img_credit) or ""), "]",
            "box[0,12.2;17,0.4;#FFFFFF]",
            "label[0.1,12.4;Source:]", 
        }))

        return table.concat(formtable_v3, ""), size
    else
        -- entry bad, go to fallback
        return nil
    end
end

--[[ formtable clean copies, for editing
-- V3
formspec_version[6]
size[17,12.6]
box[0,0;17,0.6;#FFFFFF]
label[6.7,0.3;Plant Compendium]
button[0.8,0.8;1,0.6;back;Back]
image[0.2,0.8;0.6,0.6;texture.png]
button[8.1,0.8;2.6,0.6;locate;Locate in World]
image[7.5,0.8;0.6,0.6;texture.png]
button[11.5,0.8;3.5,0.6;view;View in Compendium]
image[10.9,0.8;0.6,0.6;texture.png]
button[15.8,0.8;1,0.6;save;Save]
image[15.2,0.8;0.6,0.6;texture.png]
box[0.2,1.4;16.6,4.8;#FFFFFF]
box[0.3,1.5;8.9,4.6;#000000]
label[0.5,1.9;Family:]
label[0.5,2.45;Scientific Name]
label[0.5,3;COMMON NAME]
box[0.5,4.1;1.4,0.6;#0000FF]
label[0.7,4.4;Status]
box[2.1,4.1;1.2,0.6;#00FF00]
label[2.3,4.4;Type]
box[3.5,4.1;1.5,0.6;#00FF00]
label[3.7,4.4;Type 2]
box[5.2,4.1;1.5,0.6;#FFA500]
label[5.4,4.4;Type 3]
textarea[0.5,5.3;8.6,0.7;;Other common names:;Add names here!]
image[9.3,1.5;7.4,4.15;texture.png]
textarea[9.3,5.65;7.4,0.7;;;Image (c) author]
textarea[0.2,6.3;9,5.7;;;Add information here!]
image_button[9.3,6.3;1.8,1;texture.png;image_2;;false;false]
image_button[11.2,6.3;1.8,1;texture.png;image_3;;false;false]
image_button[13.1,6.3;1.8,1;texture.png;image_4;;false;false]
image_button[15,6.3;1.8,1;texture.png;image_5;;false;false]
image[9.3,7.4;3.7,4.6;texture.png]
image[13.1,7.4;3.7,4.6;texture.png]
box[0,12.2;17,0.4;#FFFFFF]
label[0.1,12.4;Source:]
]]
