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

    -- migrate old format reference keys
    if format ~= "v2" then
        if format == "v1" then
            magnify.species.ref:set_string(ref, "")
            ref = string.sub(ref, 5)
        else
            return nil -- could not determine ref key
        end
    end

    -- clean and add additional properties to definition table
    def_table.origin = minetest.get_current_modname()
    if def_table.texture and type(def_table.texture) ~= "table" then
        def_table.texture = {def_table.texture}
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
