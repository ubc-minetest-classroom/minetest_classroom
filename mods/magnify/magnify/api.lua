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

--- Saves data to a player's magnify metadata
--- @param player Player to save data for
--- @param data Data to save
--- @return boolean
function magnify.save_mdata(player, data)
    if not player:is_player() or type(data) ~= "table" then
        return false -- invalid player/metadata
    end

    local meta = player:get_meta()
    meta:set_string("magnify:pdata", minetest.serialize(data))
    return true
end

--- Gets data from a player's `magnify` metadata
--- @param player Player to get data for
--- @return table or nil
function magnify.get_mdata(player)
    if not player:is_player() then
        return nil -- invalid player
    end

    local meta = player:get_meta()
    local data = minetest.deserialize(meta:get("magnify:pdata") or minetest.serialize(nil))
    
    if not data or type(data) ~= "table" then
        data = {
            discovered = {},
            favourites = {},
            format = 1,
        }
        magnify.save_mdata(player, data)
    elseif not data.format or data.format < 1 then
        -- temp b/c only format 1 exists
        data.format = 1
        magnify.save_mdata(player, data)
    end
    return data
end

--- @private
--- Searches for a reference key with information matching the information in def_table, and returns it if found, along with a string indicating the format of the reference key
--- Otherwise, returns the next unused reference key, and the latest format
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
    elseif type(def_table) ~= "table" or not def_table.sci_name then
        return nil -- invalid definition table
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

--- @public
--- Returns a tree of all the species registered in the `magnify` species database, indexed by family name
--- Each family points to a table indexed by genus name, each genus points to a table indexed by species name, each species points to its associated reference key
--- @return table
function magnify.get_registered_species_tree()
    local storage_data = magnify.species.ref:to_table()
    local fam_list = {}

    for k,v in pairs(storage_data.fields) do
        local info = minetest.deserialize(v)
        if info and tonumber(k) then
            local split_table = info.sci_name and string.split(info.sci_name, " ", false, 1)
            if split_table then
                local genus, species = unpack(split_table)
                local genus_list = fam_list[info.fam_name or "Unknown"] or {}
                local species_list = genus_list[genus] or {}

                species_list[species] = k
                genus_list[genus] = species_list
                fam_list[info.fam_name or "Unknown"] = genus_list
            end
        end
    end
    return fam_list
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
--- @return string, string, string
local function get_cons_status_info(cons_status)
    if cons_status then
        local status = (type(cons_status) == "table" and (cons_status.ns_global or cons_status.ns_bc)) or cons_status
        local status_info = magnify.map.ns_global[status] or magnify.map.ns_bc[status]
        if status_info then
            local desc = status_info["desc"]
            return status, status_info["col"], desc ~= "" and desc or ""
        else
            return status
        end
    else
        return nil
    end
end

--- @public
--- Builds the general species information formspec for the species indexed at `ref` in the `magnify` species database 
--- If player is unspecified, player-dependent features (ex. favourites) are blocked
--- @param ref Reference key of the species
--- @param is_exit true if clicking the "Back" button should exit the formspec, false otherwise
--- @param player Player to build the formspec for
--- @return (formspec string, formspec "size[]" string) or nil
function magnify.build_formspec_from_ref(ref, is_exit, player)
    local info = ref and minetest.deserialize(magnify.species.ref:get(ref))
  
    if info ~= nil then
        -- entry good, return V3 formspec
        local model_spec_loc = (info.model_obj and info.origin) and get_obj_directory(info.origin, info.model_obj)
        local status, status_col, status_desc = get_cons_status_info(info.cons_status)
        local size = "size[19,13]"
        local formtable_v3 = {
            "formspec_version[6]", size,

            "no_prepend[]",
            "bgcolor[#00000000;true;]",
            "background[0,0;0,0;magnify_pixel.png^[multiply:#000000^[opacity:69;true]",
            "image[0,0;19,0.6;magnify_pixel.png^[multiply:#F5F5F5^[opacity:76]",
            "style_type[label;font=mono,bold]",
            "label[7.8,0.3;Plant Compendium]",
            "style_type[label;font=normal]",
            "image_button", is_exit and "_exit" or "", "[0,0;0.6,0.6;magnify_compendium_x.png;back;;false;false]",
            "image_button[0.7,0;0.6,0.6;magnify_compendium_nav_back.png;nav_backward;;false;false]",
            "image_button[1.4,0;0.6,0.6;magnify_compendium_nav_fwd.png;nav_forward;;false;false]",
            "tooltip[back;Back]",
            "tooltip[nav_forward;Next]",
            "tooltip[nav_backward;Previous]",

            "style_type[button;font=mono;textcolor=black;border=false;bgimg=magnify_pixel.png^[multiply:#F5F5F5]",
            "style_type[image_button;font=mono;textcolor=black;border=false;bgimg=magnify_pixel.png^[multiply:#F5F5F5]",
            "button[6.6,0.8;4.6,0.6;view;   View in Compendium]",
            "image[6.6,0.8;0.6,0.6;magnify_compendium_icon.png]",
            "button[11.3,0.8;2.2,0.6;locate;   Locate]",
            "image[11.3,0.8;0.6,0.6;magnify_compendium_locate.png]",
            "button[13.6,0.8;3.8,0.6;tech_view;   Technical Info]",
            "image[13.6,0.8;0.6,0.6;magnify_compendium_tech_info.png]",
        }

        -- Add favourites 
        if player and player:is_player() then
            local mdata = magnify.get_mdata(player)
            table.insert(formtable_v3, table.concat({
                "image_button[17.5,0.8;0.6,0.6;magnify_compendium_heart_", mdata.favourites and mdata.favourites[ref] and "filled" or "hollow", ".png;favourite;;false;false]",
                "tooltip[favourite;", mdata.favourites[ref] and "Remove from " or "Add to ", "Favourites]",
            }))
        else
            table.insert(formtable_v3, table.concat({
                "image_button[17.5,0.8;0.6,0.6;magnify_compendium_heart_hollow.png^[colorize:#909090:alpha;favourite_blocked;;false;false]",
                "tooltip[favourite_blocked;Favourites inaccessible]",
            }))
        end
        
        table.insert(formtable_v3, table.concat({
            "image_button[18.2,0.8;0.6,0.6;magnify_compendium_settings.png^[multiply:#000000;settings;;false;false]",
            "image[10.8,1.4;8.0,4.9;magnify_pixel.png^[multiply:#F5F5F5^[opacity:255]",
            "tooltip[settings;Settings]",

            "image[0.2,1.4;18.6,0.1;magnify_pixel.png^[multiply:#F5F5F5^[opacity:255]",
            "image[0.2,1.4;0.1,4.9;magnify_pixel.png^[multiply:#F5F5F5^[opacity:255]",
            "image[0.2,6.2;18.6,0.1;magnify_pixel.png^[multiply:#F5F5F5^[opacity:255]",
      
            "style_type[textarea;font=mono,bold;textcolor=black;font_size=*0.85]",
            "image[0.5,1.7;1.3,0.5;magnify_pixel.png^[multiply:#F5F5F5^[opacity:255]",
            "textarea[0.6,1.8;1.3,0.8;;;FAMILY]",
        }))
    
        if false and info.fam_name then
            -- gamified family area
            table.insert(formtable_v3, table.concat({
                
            }))
        else
            -- default family area
            table.insert(formtable_v3, table.concat({
            	"style_type[textarea;font=mono;textcolor=white;font_size=*1]",
                "textarea[2,1.75;8.95,0.8;;;", minetest.formspec_escape((info.fam_name and info.fam_name..(magnify.map.family[info.fam_name] and " ("..magnify.map.family[info.fam_name]..")" or "")) or "Unknown"), "]",
            }))
        end
        
        table.insert(formtable_v3, table.concat({
            "style_type[textarea;font=mono;font_size=*1.25]",
            "textarea[0.45,2.4;10.4,1;;;", minetest.formspec_escape(info.sci_name or "Scientific name unknown"), "]",
            "style_type[textarea;font_size=*2.25;font=mono,bold]",
            "textarea[0.45,2.9;10.4,1.8;;;", minetest.formspec_escape(info.com_name or "Common name unknown"), "]",
        }))

        -- add status + tags
        if status or info.tags then
            local tag_table = {}
            local x_pos = 0

            -- add tags to tag table
            if status then
                table.insert(tag_table, table.concat({
                    "image[", x_pos, ",0.2;", 0.42 + 0.2*string.len(status), ",0.6;magnify_round_rect_9.png^[resize:24.08x24.08^[multiply:", status_col or "#9192A3", "^[opacity:127;12]",
                    "label[", x_pos + 0.19, ",0.5;", status, "]",
                }))
                x_pos = x_pos + 0.42 + 0.2*string.len(status) + 0.2
            end
            for i,tag_key in pairs(info.tags or {}) do
                local tag = magnify.map.tag[tag_key] or {col = "#9192A3", desc = tag_key}
                table.insert(tag_table, table.concat({
                    "image[", x_pos, ",0.2;", 0.42 + 0.2*string.len(tag.desc), ",0.6;magnify_round_rect_9.png^[resize:24.08x24.08^[multiply:", tag.col or "#9192A3", "^[opacity:127;12]",
                    "label[", x_pos + 0.19, ",0.5;", tag.desc, "]",
                }))
                x_pos = x_pos + 0.42 + 0.2*string.len(tag.desc) + 0.2
            end

            table.insert(formtable_v3, table.concat({
                "style_type[label;font=mono]",
                x_pos > 10.3 and "scrollbaroptions[min=0;max="..math.max((x_pos - 10.3)/0.4, 0).."]" or "",
                x_pos > 10.3 and "scrollbar[0.3,6;10.5,0.2;horizontal;tag_scroll;0]" or "",
                "scroll_container[0.5,5.2;10.1,0.8;tag_scroll;horizontal;0.4]",
                table.concat(tag_table),
                "scroll_container_end[]",
                "style_type[label;font=normal]",
            }))
        end

        table.insert(formtable_v3, table.concat({
            "image[10.9,1.5;7.8,4.4;", (type(info.texture) == "table" and info.texture[1]) or info.texture or "test.png", "]",
            "style_type[textarea;font=mono;font_size=*1]",
            "textarea[0.2,6.6;10.7,5.9;;;", -- info area
            --"- ", minetest.formspec_escape(cons_status_desc or "Conservation status unknown"), "\n",
            "- ", minetest.formspec_escape((info.region and "Found in "..info.region) or "Location range unknown"), "\n",
            "- ", minetest.formspec_escape(info.height or "Height unknown"), "\n",
            "\n",
            minetest.formspec_escape((info.more_info and info.more_info.."\n") or ""),
            minetest.formspec_escape(info.bloom or "Bloom pattern unknown"),
            "]",
        
            "style_type[image_button;bgimg=blank.png]",
            "image_button[10.9,6.5;1.9,1.1;", type(info.texture) == "table" and info.texture[2] or "test.png", ";image_2;;false;false]",
            "image_button[12.9,6.5;1.9,1.1;", type(info.texture) == "table" and info.texture[3] or "test.png", ";image_3;;false;false]",
            "image_button[14.9,6.5;1.9,1.1;", type(info.texture) == "table" and info.texture[4] or "test.png", ";image_4;;false;false]",
            "image_button[16.9,6.5;1.9,1.1;", type(info.texture) == "table" and info.texture[5] or "test.png", ";image_5;;false;false]",
        }))
        
        if model_spec_loc then
              -- add model + image 6
            local model_spec = read_obj_textures(model_spec_loc)
            table.insert(formtable_v3, table.concat({
                "style[plant_model;bgcolor=#466577]",
                "model[10.9,7.7;3.9,4.7;plant_model;", info.model_obj, ";", table.concat(model_spec, ","), ";", info.model_rot_verti or info.model_rot_x or "0", ",", info.model_rot_horiz or info.model_rot_y or "180", ";false;true;;]",
                "image[14.9,7.7;3.9,4.7;", (type(info.texture) == "table" and info.texture[6]) or "test.png", "]",
            }))
        else
            -- add images 6 + 7
            table.insert(formtable_v3, table.concat({
                "image[10.9,7.7;3.9,4.7;", (type(info.texture) == "table" and info.texture[6]) or "test.png", "]",
                "image[14.9,7.7;3.9,4.7;", (type(info.texture) == "table" and info.texture[7]) or "test.png", "]",
            }))
        end
    
        table.insert(formtable_v3, table.concat({
            "style_type[textarea;font=mono;font_size=*0.7;textcolor=black]",
            "textarea[10.85,5.95;7.9,0.39;;;", minetest.formspec_escape((info.img_copyright and "Image © "..info.img_copyright) or (info.img_credit and "Image courtesy of "..info.img_credit) or ""), "]",
            "image[0,12.6;19,0.4;magnify_pixel.png^[multiply:#F5F5F5^[opacity:76]",
            "style_type[textarea;font=mono;font_size=*0.9;textcolor=white]",
            "textarea[0.2,12.62;18.6,0.5;;;", info.info_source and "Source: "..info.info_source or "Source unknown", info.last_updated and "  -  Last updated on "..info.last_updated or "", "]", 
        }))

        return table.concat(formtable_v3, ""), size
    else
        -- entry bad, go to fallback
        return nil
    end
end

--[[ V3 formtable clean copy, for editing
formspec_version[6]
size[19,13]
box[0,0;19,0.6;#FFFFFF]
label[7.8,0.3;Plant Compendium]
image_button[0,0;0.6,0.6;magnify_compendium_x.png;back;;false;false]
image_button[0.7,0;0.6,0.6;magnify_compendium_nav_fwd.png;nav_forward;;false;false]
image_button[1.4,0;0.6,0.6;magnify_compendium_nav_back.png;nav_backward;;false;false]
button[5.5,0.8;4.7,0.6;view;   Compendium View]
image[5.5,0.8;0.6,0.6;magnify_compendium_icon.png]
button[10.3,0.8;3.2,0.6;locate;   Locate]
image[10.3,0.8;0.6,0.6;magnify_compendium_locate.png]
button[13.6,0.8;3.8,0.6;tech_view;   Technical Info]
image[13.6,0.8;0.6,0.6;magnify_compendium_tech_info.png]
image_button[17.5,0.8;0.6,0.6;magnify_compendium_saved.png;favourite;;false;false]
image_button[18.2,0.8;0.6,0.6;magnify_compendium_settings.png;settings;;false;false]
box[0.2,1.4;18.6,4.9;#FFFFFF]
box[0.3,1.5;10.5,4.7;#000000]
textarea[0.45,1.7;10.4,0.8;;;Family:]
textarea[0.45,2.4;10.4,1;;;Scientific Name]
textarea[0.45,2.9;10.4,1.8;;;COMMON NAME]
box[0.5,5.4;1.4,0.6;#9192A3]
label[0.7,5.7;Status]
box[2.1,5.4;1.2,0.6;#00FF00]
label[2.3,5.7;Type]
box[3.5,5.4;1.5,0.6;#00FF00]
label[3.7,5.7;Type 2]
box[5.2,5.4;1.5,0.6;#FFA500]
label[5.4,5.7;Type 3]
image[10.9,1.5;7.8,4.4;texture.png]
textarea[10.85,5.9;7.9,0.39;;;Image (c) author]
textarea[0.2,6.6;10.7,5.9;;;Add information here!]
image_button[10.9,6.4;1.9,1.1;texture.png;image_2;;false;false]
image_button[12.9,6.4;1.9,1.1;texture.png;image_3;;false;false]
image_button[14.9,6.4;1.9,1.1;texture.png;image_4;;false;false]
image_button[16.9,6.4;1.9,1.1;texture.png;image_5;;false;false]
image[10.9,7.6;3.9,4.8;texture.png]
image[14.9,7.6;3.9,4.8;texture.png]
box[0,12.6;19,0.4;#FFFFFF]
label[0.3,12.8;Source:]
]]
