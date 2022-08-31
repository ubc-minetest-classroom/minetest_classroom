-------------------------
-- GLOBALS + CONSTANTS --
-------------------------

magnify = {
    path = minetest.get_modpath("magnify"),
    S = minetest.get_translator("magnify"),
    species = {ref = minetest.get_mod_storage(), node = {}},
    map = {},
    context = {},
}
-- DATABASE HARD RESET SNIPPET: ONLY USE FOR DEBUGGING PURPOSES
--magnify.species.ref:from_table(nil)

dofile(magnify.path.."/api.lua")
dofile(magnify.path.."/map.lua")

-- constants
local tool_name = "magnify:magnifying_tool"
local priv_table = {interact = true}
local MENU, STANDARD_VIEW, TECH_VIEW = 1, 2, 3
local RELOAD = {
    FULL = 1,
    GEN_UP = 2,
    SPC_UP = 3,
}
local CHECKBOXES = {
    get_all = function(self)
        local all = {}
        for k,list in pairs(self) do
            if type(list) == "table" then
                for i,v in ipairs(list) do
                    table.insert(all, k.."_"..v)
                end
            end
        end
        return all
    end,
    form = {"tree", "shrub",},
    leaf = {"deciduous", "evergreen",},
    cons = {"gx", "gh", "g1", "g2", "g3", "g4", "g5", "na",},
    misc = {"bc_native",}
}


----------------------
-- HELPER FUNCTIONS --
----------------------

-- Checks for adequate privileges
local function check_perm(player)
    return minetest.check_player_privs(player, priv_table)
end

-- Gets the player's magnify formspec context
local function get_context(player)
    local pname = (type(player) == "string" and player) or (player:is_player() and player:get_player_name()) or ""
    if not magnify.context[pname] then
        magnify.context[pname] = {
            clear = function(self)
                magnify.context[pname] = nil
            end,
            page = 0,
            family = {
                selected = 1,
                list = {}
            },
            genus = {
                selected = 1,
                list = {}
            },
            species = {
                selected = 1,
                list = {}
            },
            filter_parity = 0,
            image = 1,
            nav = {
                index = 0,
                list = {}
            },
        }
    end
    return magnify.context[pname]
end

-- Inserts the given page table into (selected index + 1) in the navigation sequence, and clears all events after (selected index + 1)
local function nav_append(context, page_table)
    -- add to navigation queue
    local index = context.nav.index + 1
    context.nav.list[index] = page_table
    -- remove all pages beyond inserted page
    for i,_ in pairs(context.nav.list) do
        if i > index then
            context.nav.list[i] = nil
        end
    end
    context.nav.index = index
    --minetest.log(minetest.serialize(context.nav.list)) -- debug
end

-- Updates the keys in update_table for the current page's table in the navigation sequence
local function nav_update_current(context, update_table)
    local page_table = context.nav.list[context.nav.index]
    for k,v in pairs(update_table) do
        page_table[k] = v
    end
    --minetest.log(minetest.serialize(context.nav.list)) -- debug
end

-- Reloads the given formspec
local function reload_fs(player, fs_name, fs)
    if not fs then return end
    if fs_name == "" then
        return player:set_inventory_formspec(fs)
    else
        return minetest.show_formspec(player:get_player_name(), fs_name, fs)
    end
end

-- Opens the given formspec in the appropriate location (inventory or external formspec), then appends it to the navigation list
local function open_fs(player, fs_name, fs)
    if not fs then return end
    minetest.sound_play("page_turn", {to_player = player:get_player_name(), gain = 1.0, pitch = 1.0,}, true)
    reload_fs(player, fs_name, fs)
end

local function get_blank_filter_table()
    local table = {select = {}, active = {}}
    for k,list in pairs(CHECKBOXES) do
        if type(list) == "table" then
            table.select[k] = {}
            table.active[k] = {}
        end
    end
    return table
end

-- Extracts the scientific name from a common name string
local function extract_sci_text(str)
    return string.match(str, "%((.-)%)$") or str
end

-- Sorts strings based on their results when fed into the extract_sci_text function
local function extract_sort(a, b)
    local extr_a = extract_sci_text(a)
    local extr_b = extract_sci_text(b)
    return extr_a < extr_b
end

--- Return the reference key of the species that is currently selected
--- @param context Magnify player context table
--- @return string
local function get_selected_species_ref(context)
    if context.ref then
        return context.ref
    end

    local fam, gen, spc = context.family, context.genus, context.species
    local sel = {
        f = fam.list[fam.selected] and (context.show_common and extract_sci_text(fam.list[fam.selected]) or fam.list[fam.selected]) or "",
        g = gen.list[gen.selected] and (context.show_common and extract_sci_text(gen.list[gen.selected]) or gen.list[gen.selected]) or "",
        s = spc.list[spc.selected] and (context.show_common and extract_sci_text(spc.list[spc.selected]) or spc.list[spc.selected]) or "",
    }
    return context.tree and context.tree[sel.f] and context.tree[sel.f][sel.g] and context.tree[sel.f][sel.g][sel.s]
end

--- Dynamically creates a square table of node images
--- @param nodes The nodes to include images for in the table
--- @param x X position of the table in the formspec
--- @param y Y position of the table in the formspec
--- @param side_length Width and height of the table in the formspec
--- @return formspec element string
local function create_image_table(nodes, x, y, side_length)
    local node_count = #nodes
    local node_ctr = 0
    local spacer = 0.2
    local row_cells = math.ceil(math.sqrt(node_count))
    local cell_length = (side_length - spacer*(row_cells - 1)) / row_cells
    local output = {}
    local x_0 = 0
    local y_0 = side_length - cell_length

    for k,v in pairs(nodes) do
        -- create formspec element
        local string_table = {
            "item_image[", x + x_0, ",", y + y_0, ";", cell_length, ",", cell_length, ";", v, "]"
        }
        table.insert(output, table.concat(string_table, ""))
        node_ctr = node_ctr + 1

        -- adjust sizing: move across a column
        if x_0 >= row_cells then
            -- move up a row
            x_0 = 0
            y_0 = y_0 - cell_length - spacer
            if node_count - node_ctr < row_cells then
                -- center remaining elements in new row
                local increment = (row_cells - node_count + node_ctr) * (cell_length + spacer) / 2
                x_0 = x_0 + increment
            end
        else
            x_0 = x_0 + cell_length + spacer
        end
    end

    return table.concat(output, "")
end

--- Create particles from start_pos to end_pos to help player locate end_pos
--- @param player Player who can view particles
--- @param start_pos Position to spart particle line from
--- @param end_pos Position to end particles at
local function create_locator_particles(player, start_pos, end_pos)
    local diff = {time = 0.08, dist = 1, expire = 0.15}
    local shift = {x = end_pos.x - start_pos.x, y = end_pos.y - start_pos.y, z = end_pos.z - start_pos.z}
    local line_length = math.hypot(math.hypot(shift.x, shift.y), shift.z)
    local pname = player:get_player_name()
    
    -- create particle line
    for i=1,math.floor(line_length / diff.dist)-1 do
        minetest.after(i * diff.time, minetest.add_particle, {
            pos = {x = start_pos.x + i * (shift.x * diff.dist / line_length), y = start_pos.y + i * (shift.y * diff.dist / line_length), z = start_pos.z + i * (shift.z * diff.dist / line_length)},
            expirationtime = 4 + i * diff.expire,
            glow = 5,
            size = 1.4,
            playername = pname,
            texture = "magnify_locator_particle.png"
        })
    end
    -- create particle spawner at end_pos
    minetest.add_particlespawner({
        time = 45,
        amount = 600,
        playername = pname,
        glow = 7,
        --collisiondetection = true,
        --collision_removal = true,
        minpos = {x = end_pos.x - 2.5, y = end_pos.y - 2.5, z = end_pos.z - 2.5},
        maxpos = {x = end_pos.x + 2.5, y = end_pos.y + 2.5, z = end_pos.z + 2.5},
        minvel = {x = -0.4, y = -0.4, z = -0.4},
        maxvel = {x = 0.4, y = 0.4, z = 0.4},
        minexptime = 1,
        maxexptime = 3,
        minsize = 0.3,
        maxsize = 1.8,
        texture = "magnify_locator_particle.png"
    })
end

local function search_for_nearby_node(player, context, nodes)
    local player_pos = player:get_pos()
    local node_pos = minetest.find_node_near(player_pos, 120, nodes, true)
    if node_pos then
        -- send location + create locator particles
        local node = minetest.get_node(node_pos)
        minetest.chat_send_player(player:get_player_name(), "Found species node \""..node.name.."\" at ("..node_pos.x..", "..node_pos.y..", "..node_pos.z..")")
        create_locator_particles(player, {x = player_pos.x, y = player_pos.y + 1.3, z = player_pos.z}, node_pos)
    else
        minetest.chat_send_player(player:get_player_name(), "No nodes for this species were found within 120 blocks of your current position.")
    end
    context.search_in_progress = false
end

--- Filters tree of species down to species for which filter_func returns a true value
--- @param tree Species tree
--- @param filter_func Function to filter by
--- @return table, number
local function species_tree_filter_abstract(tree, filter_func)
    local function tree_tr(res_tree, res_count, k, v, p, k_wl, v_wl, p_wl)
        if not k or not v or not p then
            return res_tree, res_count
        else
            if type(v) == "string" or type(v) == "number" then
                if filter_func(magnify.get_species_from_ref(v)) then
                    local fam, gen, spc = p[1], p[2], k
                    local f_g_list = res_tree[fam] or {}
                    local f_s_list = f_g_list[gen] or {}
                    f_s_list[spc] = v
                    f_g_list[gen] = f_s_list
                    res_tree[fam] = f_g_list
                    res_count = res_count + 1
                end
            elseif type(v) == "table" then
                local n_p = table.copy(p)
                table.insert(n_p, k)
                for n_k, n_v in pairs(v) do
                    table.insert(k_wl, n_k)
                    table.insert(v_wl, n_v)
                    table.insert(p_wl, n_p)
                end
            end

            local next_k = table.remove(k_wl, 1)
            local next_v = table.remove(v_wl, 1)
            local next_p = table.remove(p_wl, 1)
            return tree_tr(res_tree, res_count, next_k, next_v, next_p, k_wl, v_wl, p_wl)
        end
    end

    -- initialization
    local keys = {}
    local vals = {}
    local paths = {}
    for k, v in pairs(tree) do
        table.insert(keys, k)
        table.insert(vals, v)
        table.insert(paths, {})
    end
    local first_k = table.remove(keys, 1)
    local first_v = table.remove(vals, 1)
    local first_p = table.remove(paths, 1)

    -- recursion
    return tree_tr({}, 0, first_k, first_v, first_p, keys, vals, paths)
end

--- Filters tree of all species down to species which are tagged with the given tags
--- @param tree Species tree
--- @param filters Tags to filter by
--- @return table
local function species_tag_filter(tree, filter)
    local filters_active = false
    local filtered_tree, count

    -- check status filters (not tags)
    if next(filter.cons) then
        filters_active = true
        filtered_tree, count = species_tree_filter_abstract(filtered_tree or tree, function(species)
            local statuses_to_check = {}
            for k,_ in pairs(filter.cons) do
                if magnify.map.stat_key[k] then
                    table.insert_all(statuses_to_check, magnify.map.stat_key[k])
                end
            end
            return magnify.table_has(statuses_to_check, species.cons_status.ns_global or "NA")
        end)
    end

    -- check remaining filters
    local function tag_match(spc_tags, filter_tags)
        for tag,_ in pairs(filter_tags) do
            if magnify.table_has(spc_tags, tag) then return true end
        end
        return false
    end
    filtered_tree, count = species_tree_filter_abstract(filtered_tree or tree, function(species)
        for name,list in pairs(filter) do
            if name ~= "cons" and next(list) then
                filters_active = true
                if not tag_match(species.tags, list) then return false end
            end
        end
        return true
    end)

    if filters_active then
        return filtered_tree, count
    else
        return tree
    end
end

--- Filters tree of all species down to species whose reference keys, common names, scientific names or family names contain the substring `query`
--- @param tree Species tree
--- @param query Substring to search for
--- @return table
local function species_search_filter(tree, query)
    local function match_query(str)
        return string.find(string.lower(str or ""), string.lower(query:trim()), 1, true)
    end
    return species_tree_filter_abstract(tree, function(species)
        return match_query(species.com_name) or match_query(species.sci_name) or match_query(species.fam_name) or match_query(ref) or match_query(magnify.map.family[species.fam_name])
    end)
end

local function create_compendium_checkbox(context, pos_x, pos_y, name, label)
    local name_split = string.split(name, "_", false, 2)
    local cat, tag = name_split[2], name_split[3]
    local fs_checkbox = table.concat({
        context.filter.active[cat][tag] and table.concat({"box[", pos_x - 0.05, ",", pos_y - 0.2, ";0.4,0.4;#8EE88E]"}) or "",
        "checkbox[", pos_x, ",", pos_y, ";", context.filter_parity % 2 == 0 and "x" or "f", name, ";", label, ";", (context.filter.select[cat][tag] and "true") or "false", "]"
    })
    return fs_checkbox
end

local function filters_active(filter_loc)
    for n,list in pairs(filter_loc) do
        if next(list) then return true end
    end
    return false
end

-- Initializes the context for the compendium formspec
local function initialize_context(context)
    if context.reload == nil then
        -- initialize full reload if not set
        context.reload = 1
    end
    local reload = context.reload

    if not context.tree or (reload and reload <= 1) then
        -- build tree and family list
        context.tree = magnify.get_registered_species_tree()
    end
    if not context.filter then
        context.filter = get_blank_filter_table()
    end

    local tree = context.tree
    local genus_raw = {}
    local count

    if filters_active(context.filter.active) then
        tree, count = species_tag_filter(tree, context.filter.active)
    end
    if context.search then
        tree, count = species_search_filter(tree, context.search)
    end

    -- Auto-select when only 1 species matches filter criteria
    if count == 1 then
        context.family.selected = 2
        context.genus.selected = 2
        context.species.selected = 2
    end

    if reload and reload <= 1 then
        context.family.list = {minetest.formspec_escape("#CCFFCC[Select a family]")}
        for fam,gen_raw in pairs(tree) do
            if context.show_common then
                table.insert(context.family.list, (magnify.map.family[fam] and magnify.map.family[fam].." " or "").."("..fam..")")
            else
                table.insert(context.family.list, fam)
            end
            table.insert(genus_raw, gen_raw)
        end
        table.sort(context.family.list, context.show_common and extract_sort or nil)
    end
  
    if context.family.selected > 1 then
        -- build specific genus list
        local family = context.show_common and extract_sci_text(context.family.list[context.family.selected]) or context.family.list[context.family.selected]
        local genus_list = tree[family]

        if reload and reload <= 2 then
            context.genus.list = {minetest.formspec_escape("#CCFFCC[Select a genus]")}
            for gen,_ in pairs(genus_list) do
                if context.show_common then
                    table.insert(context.genus.list, (magnify.map.genus[gen] and magnify.map.genus[gen].." " or "").."("..gen..")")
                else
                    table.insert(context.genus.list, gen)
                end
            end
            table.sort(context.genus.list, context.show_common and extract_sort or nil)
        end
    
        if context.genus.shift then
            for i,g_raw in ipairs(context.genus.list) do
                local g = context.show_common and extract_sci_text(g_raw) or g_raw
                if g == context.genus.shift then
                    context.genus.shift = nil
                    context.genus.selected = i
                    break
                end
            end
            if context.genus.shift then
                context.genus.selected = 1
            end
        end
        if context.genus.selected > 1 then
            -- build species list
            local genus = context.show_common and extract_sci_text(context.genus.list[context.genus.selected]) or context.genus.list[context.genus.selected]
            local species_list = genus_list[genus]

            if reload and reload <= 3 then
                context.species.list = {minetest.formspec_escape("#CCFFCC[Select a species]")}
                for spec,ref in pairs(species_list) do
                    if context.show_common then
                        local info = magnify.get_species_from_ref(ref)
                        table.insert(context.species.list, (info.com_name and info.com_name.." " or "").."("..spec..")")
                    else
                        table.insert(context.species.list, spec)
                    end
                end
                table.sort(context.species.list, context.show_common and extract_sort or nil)
            end
        else
            context.species.list = {minetest.formspec_escape("#B0B0B0[Select a genus first]")}
        end
    elseif reload and reload <= 2 then
        -- build general genus list
        context.genus.list = {minetest.formspec_escape("#CCFFCC[Select a genus]")}
        for i,list in pairs(genus_raw) do
            for gen,_ in pairs(list) do
                if context.show_common then
                    table.insert(context.genus.list, (magnify.map.genus[gen] and magnify.map.genus[gen].." " or "").."("..gen..")")
                else
                    table.insert(context.genus.list, gen)
                end
            end
        end
        table.sort(context.genus.list, context.show_common and extract_sort or nil)
        context.species.list = {minetest.formspec_escape("#B0B0B0[Select a genus first]")}
    end
end

--- Selects the species in the species tree with the given reference key
--- @param context Magnify player context table
--- @param ref Reference key of species ot select
local function select_species_with_ref(context, ref)
    if context.family.selected <= 1 or context.genus.selected <= 1 or context.species.selected <= 1 then
        -- clear fallback ref so that selection is prioritized
        context.ref = nil

        local info = magnify.get_species_from_ref(ref)
        if info then
            local split_table = info.sci_name and string.split(info.sci_name, " ", false, 1)
            local family, genus, species = info.fam_name or "Unknown", unpack(split_table)

            -- reload family list
            initialize_context(context)
            for i,fam in ipairs(context.family.list) do
                if fam == family then
                    context.family.selected = i
                    break
                end
            end
            
            if context.family.selected > 1 then
                -- reload genus list
                initialize_context(context)
                for i,gen in ipairs(context.genus.list) do
                    if gen == genus then
                        context.genus.selected = i
                        break
                    end
                end
                
                if context.genus.selected > 1 then
                    -- reload species list
                    initialize_context(context)
                    for i,spc in ipairs(context.species.list) do
                        if spc == species then
                            context.species.selected = i
                            break
                        end
                    end
                end
            end
        end
    end
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

--- @private
--- Creates a row of species image buttons
--- @return string
local function create_species_image_row(textures, pos, box_size, img_size)
    local factor, spacer, shift = 0.1, 0.1, 0.2
    local image_row = {
        (#textures*(img_size.x + spacer) - spacer) > box_size.x and table.concat({
            "scrollbaroptions[min=0;max=", math.max((#textures*(img_size.x + spacer) - spacer - box_size.x)/factor, 0), ";thumbsize=2]",
            "scrollbar[", pos.x, ",", pos.y - shift, ";", box_size.x, ",", shift, ";horiozntal;image_row_scroll;0]",
        }) or "",
        "scroll_container[", pos.x, ",", pos.y, ";", box_size.x, ",", box_size.y, ";image_row_scroll;horizontal;", factor, "]",
        "style_type[image_button;bgimg=blank.png]",
    }

    for i,img in ipairs(textures) do
        table.insert(image_row, table.concat({
            "image_button[", (img_size.x + spacer)*(i - 1), ",0;", img_size.x, ",", img_size.y, ";", img, ";image_", i, ";;false;false]",
        }))
    end
    table.insert(image_row, "scroll_container_end[]")

    return table.concat(image_row)
end


-----------------------
-- FORMSPEC BUILDERS --
-----------------------

--- Builds the general species information formspec for the species indexed at `ref` in the `magnify` species database 
--- If player is unspecified, player-dependent features (ex. favourites, navigation) are disabled
--- @param ref Reference key of the species
--- @param is_exit true if clicking the "Back" button should exit the formspec, false otherwise
--- @param player Player to build the formspec for
--- @return formspec string, formspec "size[]" string
function build_viewer_formspec(ref, is_exit, player)
    local info = ref and minetest.deserialize(magnify.species.ref:get(ref))
    local context = player and player:is_player() and get_context(player)
  
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
            "image_button[0.7,0;0.6,0.6;magnify_compendium_nav_back.png", context and context.nav.list[context.nav.index - 1] and "" or "^[opacity:63", ";nav_backward;;false;false]",
            "image_button[1.4,0;0.6,0.6;magnify_compendium_nav_fwd.png", context and context.nav.list[context.nav.index + 1] and "" or "^[opacity:63", ";nav_forward;;false;false]",
            "tooltip[back;", is_exit and "Close" or "Back", "]",
            "tooltip[nav_forward;Next]",
            "tooltip[nav_backward;Previous]",

            "style_type[button;font=mono;textcolor=black;border=false;bgimg=magnify_pixel.png^[multiply:#F5F5F5]",
            "style_type[image_button;font=mono;textcolor=black;border=false;bgimg=magnify_pixel.png^[multiply:#F5F5F5]",
            "button[6.6,0.8;4.6,0.6;compendium_view;   View in Compendium]",
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
            "tooltip[settings;Settings]",

            "image[10.8,1.4;8.0,4.9;magnify_pixel.png^[multiply:#F5F5F5^[opacity:255]",
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
                x_pos > 10.3 and "scrollbaroptions[min=0;max="..math.max((x_pos - 10.3)/0.4, 0)..";thumbsize=2]" or "",
                x_pos > 10.3 and "scrollbar[0.3,6;10.5,0.2;horizontal;tag_scroll;0]" or "",
                "scroll_container[0.5,5.2;10.1,0.8;tag_scroll;horizontal;0.4]",
                table.concat(tag_table),
                "scroll_container_end[]",
                "style_type[label;font=normal]",
            }))
        end

        table.insert(formtable_v3, table.concat({
            "image[10.9,1.5;7.8,4.4;", info.texture and info.texture[context and context.image or 1] or "test.png", "]",
            "style_type[textarea;font=mono;font_size=*1]",
            "textarea[0.2,6.6;10.7,5.9;;;", -- info area
            --"- ", minetest.formspec_escape(cons_status_desc or "Conservation status unknown"), "\n",
            "- ", minetest.formspec_escape((info.region and "Found in "..info.region) or "Location range unknown"), "\n",
            "- ", minetest.formspec_escape(info.height or "Height unknown"), "\n",
            "\n",
            minetest.formspec_escape((info.more_info and info.more_info.."\n") or ""),
            minetest.formspec_escape(info.bloom or ""),
            "]",
        }))
        
        if model_spec_loc then
              -- add model + range map
            local model_spec = read_obj_textures(model_spec_loc)
            table.insert(formtable_v3, table.concat({
                "style[plant_model;bgcolor=#466577]",
                "model[10.9,7.7;3.9,4.7;plant_model;", info.model_obj, ";", table.concat(model_spec, ","), ";", info.model_rot_verti or info.model_rot_x or "0", ",", info.model_rot_horiz or info.model_rot_y or "180", ";false;true;;]",
                "image[14.9,7.7;3.9,4.7;", info.range_map or "test.png", "]",
            }))
        else
            -- add test image + range imap
            table.insert(formtable_v3, table.concat({
                "image[10.9,7.7;3.9,4.7;", "test.png", "]",
                "image[14.9,7.7;3.9,4.7;", info.range_map or "test.png", "]",
            }))
        end
    
        table.insert(formtable_v3, table.concat({
            "style_type[textarea;font=mono;font_size=*0.7;textcolor=black]",
            "textarea[10.85,5.95;7.9,0.39;;;", minetest.formspec_escape((info.img_copyright and "Image © "..info.img_copyright) or (info.img_credit and "Image courtesy of "..info.img_credit) or ""), "]",
            create_species_image_row(info.texture, {x = 10.9, y = 6.5}, {x = 7.9, y = 1.1}, {x = 1.9, y = 1.1}),

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

--- Returns the plant compendium formspec
--- @param context magnify context object
--- @param is_exit true if clicking the "Back" button should exit the formspec, false otherwise
--- @return formspec string, formspec "size[]" string
local function build_compendium_formspec(context, is_exit)
    initialize_context(context)

    local size = "size[19,13]"
    local formtable = {
        "formspec_version[6]", size,

        "no_prepend[]",
        "bgcolor[#00000000;true;]",
        "background[0,0;0,0;magnify_pixel.png^[multiply:#000000^[opacity:69;true]",
        "image[0,0;19,0.6;magnify_pixel.png^[multiply:#F5F5F5^[opacity:76]",
        "style_type[label;font=mono,bold]",
        "label[7.8,0.3;Plant Compendium]",
        "image_button", is_exit and "_exit" or "", "[0,0;0.6,0.6;magnify_compendium_x.png;back;;false;false]",
        "image_button[0.7,0;0.6,0.6;magnify_compendium_nav_back.png", context.nav.list[context.nav.index - 1] and "" or "^[opacity:63", ";nav_backward;;false;false]",
        "image_button[1.4,0;0.6,0.6;magnify_compendium_nav_fwd.png", context.nav.list[context.nav.index + 1] and "" or "^[opacity:63", ";nav_forward;;false;false]",
        "tooltip[back;", is_exit and "Close" or "Back", "]",
        "tooltip[nav_forward;Next]",
        "tooltip[nav_backward;Previous]",

        "style[search;font=mono]",
        "field[0.4,1.3;8.2,0.7;search;Search by common/scientific name;", context.search or "", "]",
        "field_close_on_enter[search;false]",
        "style_type[button;font=mono;border=false;bgimg=magnify_pixel.png^[multiply:#000000]",
        "button[8.6,1.3;2.4,0.7;search_go;   Search]",
        "image[8.6,1.3;0.7,0.7;magnify_compendium_search.png]",
        "button[11,1.3;2.2,0.7;search_x;   Clear]",
        "image[11,1.3;0.7,0.7;magnify_compendium_x.png]",
        "checkbox[0.4,2.3;toggle_common;Show common names;", context.show_common and "true" or "false", "]",

        "style_type[label;font=mono,bold]",
        "image[0.4,2.8;4.2,0.7;magnify_pixel.png^[multiply:#F5F5F5^[opacity:76]",
        "label[1.9,3.2;Family]",
        "textlist[0.4,3.5;4.2,9.1;family_list;", table.concat(context.family.list, ","), ";", context.family.selected or 1, ";false]",
        "image[4.7,2.8;4.2,0.7;magnify_pixel.png^[multiply:#F5F5F5^[opacity:76]",
        "label[6.2,3.2;Genus]",
        "textlist[4.7,3.5;4.2,9.1;genus_list;", table.concat(context.genus.list, ","), ";", context.genus.selected or 1, ";false]",
        "image[9,2.8;4.2,0.7;magnify_pixel.png^[multiply:#F5F5F5^[opacity:76]",
        "label[10.4,3.2;Species]",
        "textlist[9,3.5;4.2,9.1;species_list;", table.concat(context.species.list, ","), ";", context.species.selected or 1, ";false]",

        -- TODO: dynamically grab all tags and add as filters
        "container[0,0]",
        "image[13.6,2.8;5,0.7;magnify_pixel.png^[multiply:#F5F5F5^[opacity:76]",
        "label[15.5,3.2;Filter]",
        "image[13.6,3.5;5,9.1;magnify_pixel.png^[multiply:#1E1E1E]",
        "label[13.8,3.9;Form:]",
        create_compendium_checkbox(context, 13.8, 4.3, "f_form_tree", "Tree"),
        create_compendium_checkbox(context, 13.8, 4.7, "f_form_shrub", "Shrub"),
        "label[13.8,5.4;Leaves:]",
        create_compendium_checkbox(context, 13.8, 5.8, "f_leaf_deciduous", "Deciduous"),
        create_compendium_checkbox(context, 13.8, 6.2, "f_leaf_evergreen", "Evergreen"),
        "label[13.8,6.9;Conservation Status:]",
        create_compendium_checkbox(context, 13.8, 7.3, "f_cons_gx", "GX (Presumed Extinct)"),
        create_compendium_checkbox(context, 13.8, 7.7, "f_cons_gh", "GH (Possibly Extinct)"),
        create_compendium_checkbox(context, 13.8, 8.1, "f_cons_g1", "G1 (Critcally Imperiled)"),
        create_compendium_checkbox(context, 13.8, 8.5, "f_cons_g2", "G2 (Imperiled)"),
        create_compendium_checkbox(context, 13.8, 8.9, "f_cons_g3", "G3 (Vulnerable)"),
        create_compendium_checkbox(context, 13.8, 9.3, "f_cons_g4", "G4 (Apparently Secure)"),
        create_compendium_checkbox(context, 13.8, 9.7, "f_cons_g5", "G5 (Secure)"),
        create_compendium_checkbox(context, 13.8, 10.1, "f_cons_na", "GNR/GU/GNA (Unranked)"),
        "label[13.8,10.8;Miscellaneous:]",
        create_compendium_checkbox(context, 13.8, 11.2, "f_misc_bc_native", "Native to BC"),
        "button[13.8,11.7;2.2,0.7;filter_apply;Apply]",
        "button[16.2,11.7;2.2,0.7;filter_clear;Clear all]",
        "container_end[]",
    }
    if context.species.selected > 1 then
        local ref = get_selected_species_ref(context)
        local info = magnify.get_species_from_ref(ref)

        if info then
            table.insert(formtable, table.concat({
                "style_type[textarea;font=mono,bold]",
                "textarea[13.6,0.9;5.2,0.8;;;", info.com_name or info.sci_name or "Species unknown", "]",
                "button[13.6,1.3;5,0.7;view;View Species", info.texture and "     " or "", "]",
                info.texture and "image[17.5,1.3;1.2,0.7;"..info.texture[1].."]" or "",
                "style_type[textarea;font=normal]",
            }))
        end
    end

    return table.concat(formtable, ""), size
end

--[[
formspec_version[6]
size[19,13]
box[0,0;19,0.6;#FFFFFF]
label[7.8,0.3;Plant Compendium]
image_button[0,0;0.6,0.6;magnify_compendium_x.png;back;;false;false]
image_button[0.7,0;0.6,0.6;magnify_compendium_nav_fwd.png;nav_forward;;false;false]
image_button[1.4,0;0.6,0.6;magnify_compendium_nav_back.png;nav_backward;;false;false]
field[0.4,1.3;7.2,0.7;search;Search by common or scientific name;]
button[7.6,1.3;3.2,0.7;search_go;   Search]
image[7.6,1.3;0.7,0.7;magnify_compendium_search.png]
button[10.8,1.3;2.3,0.7;search_x;   Clear]
image[10.8,1.3;0.7,0.7;magnify_compendium_x.png]
checkbox[0.4,2.3;toggle_common;Show common names;false]
box[0.4,2.8;4.2,0.7;#A0A0A0]
label[1.9,3.2;Family]
textlist[0.4,3.5;4.2,9.1;family_list;;1;false]
box[4.7,2.8;4.2,0.7;#A0A0A0]
label[6.2,3.2;Genus]
textlist[4.7,3.5;4.2,9.1;genus_list;;1;false]
box[9,2.8;4.2,0.7;#A0A0A0]
label[10.4,3.2;Species]
textlist[9,3.5;4.2,9.1;species_list;;1;false]
box[13.6,2.8;5,0.7;#A0A0A0]
label[15.5,3.2;Filter]
box[13.6,3.5;5,9.1;#1E1E1E]
label[13.8,3.9;Form:]
checkbox[13.8,4.3;form_tree;Tree;false]
checkbox[13.8,4.7;form_shrub;Shrub;false]
label[13.8,5.4;Leaves:]
checkbox[13.8,5.8;leaf_decid;Deciduous;false]
checkbox[13.8,6.2;leaf_ever;Evergreen;false]
label[13.8,6.9;Conservation Status:]
checkbox[13.8,7.3;cons_gx;GX (Presumed Extinct);false]
checkbox[13.8,7.7;cons_gh;GH (Possibly Extinct);false]
checkbox[13.8,8.1;cons_g1;G1 (Critcally Imperiled);false]
checkbox[13.8,8.5;cons_g2;G2 (Imperiled);false]
checkbox[13.8,8.9;cons_g3;G3 (Vulnerable);false]
checkbox[13.8,9.3;cons_g4;G4 (Apparently Secure);false]
checkbox[13.8,9.7;cons_g5;G5 (Secure);false]
checkbox[13.8,10.1;cons_na;GNR/GU/GNA (Unranked);false]
label[13.8,10.8;Miscellaneous:]
checkbox[13.8,11.2;misc_bc_native;Native to BC;false]
button[13.8,11.7;2.3,0.7;filter_apply;Apply]
button[16.1,11.7;2.3,0.7;filter_clear;Clear all]
]]

--- Return the technical formspec for a species
--- If player is unspecified, player-dependent features (ex. navigation) are disabled
--- @param ref Reference key of species
--- @param is_exit true if clicking the "Back" button should exit the formspec, false otherwise
--- @param player Player to build the formspec for
--- @return formspec string, size
local function build_technical_formspec(ref, is_exit, player)
    local info, nodes = magnify.get_species_from_ref(ref)
    local context = player and player:is_player() and get_context(player)

    if info and nodes then
        local props = {}
        for k,_ in pairs(info) do
            table.insert(props, k)
        end
        table.sort(props)
        table.sort(nodes)

        local size = "size[19,13]"
        local formtable = {
            "formspec_version[6]", size,

            "no_prepend[]",
            "bgcolor[#00000000;true;]",
            "background[0,0;0,0;magnify_pixel.png^[multiply:#000000^[opacity:69;true]",
            "image[0,0;19,0.6;magnify_pixel.png^[multiply:#F5F5F5^[opacity:76]",
            "style_type[label;font=mono,bold]",
            "label[7.8,0.3;Plant Compendium]",
            "image_button", is_exit and "_exit" or "", "[0,0;0.6,0.6;magnify_compendium_x.png;back;;false;false]",
            "image_button[0.7,0;0.6,0.6;magnify_compendium_nav_back.png", context and context.nav.list[context.nav.index - 1] and "" or "^[opacity:63", ";nav_backward;;false;false]",
            "image_button[1.4,0;0.6,0.6;magnify_compendium_nav_fwd.png", context and context.nav.list[context.nav.index + 1] and "" or "^[opacity:63", ";nav_forward;;false;false]",
            "tooltip[back;", is_exit and "Close" or "Back", "]",
            "tooltip[nav_forward;Next]",
            "tooltip[nav_backward;Previous]",

            "image[0.2,1.4;16.1,0.1;magnify_pixel.png^[multiply:#F5F5F5^[opacity:255]",
            "image[0.2,1.4;0.1,4.9;magnify_pixel.png^[multiply:#F5F5F5^[opacity:255]",
            "image[0.2,6.2;16.1,0.1;magnify_pixel.png^[multiply:#F5F5F5^[opacity:255]",
            "image[16.3,1.4;0.1,4.9;magnify_pixel.png^[multiply:#F5F5F5^[opacity:255]",

            "style_type[textarea;font=mono,bold;textcolor=black;font_size=*0.85]",
            "image[0.5,1.7;2.5,0.5;magnify_pixel.png^[multiply:#F5F5F5^[opacity:255]",
            "textarea[0.6,1.8;3.0,0.8;;;REFERENCE KEY]",
            "style_type[textarea;font=mono;textcolor=white;font_size=*1]",
            "textarea[3.2,1.75;8.95,0.8;;;", minetest.formspec_escape(ref) or "Unknown", "]",

            "style_type[textarea;font=mono,bold;font_size=*2.25]",
            "textarea[0.45,2.35;15.7,1.2;;;", minetest.formspec_escape(info.com_name) or minetest.formspec_escape(info.sci_name) or "Unknown", "]",
            "style_type[textarea;font=mono;font_size=*1]",
            "textarea[0.45,3.2;15.7,2.85;;;", info.origin and "Registered by "..info.origin or "Registration origin unknown",
            "\n\n", "Defined properties: ", table.concat(props, ", "),
            "]",

            "style_type[label;font=mono,bold]",
            "label[0.3,6.7;Associated nodes:]",
            "style[associated_nodes;font=mono]",
            "textlist[0.2,6.9;16.2,5.5;associated_nodes;", table.concat(nodes, ","), ";1;false]",
            --create_image_table(sorted_nodes or nodes, 10, 1.5, 5.6)
            "box[16.6,0.8;2.2,11.6;#00FF00]", -- will eventually be replaced by image table

            "image[0,12.6;19,0.4;magnify_pixel.png^[multiply:#F5F5F5^[opacity:76]",
            "style_type[textarea;font=mono;font_size=*0.9;textcolor=white]",
            "textarea[0.2,12.62;18.6,0.5;;;", info.last_updated and "Last updated on "..info.last_updated or "", "]", 
        }
        return table.concat(formtable, ""), size
    else
        -- invalid ref
        return nil
    end
end

--[[
formspec_version[6]
size[19,13]
box[0.2,0.8;16.2,4.3;#FFFFFF]
box[0.3,0.9;16,4.1;#000000]
box[0,0;19,0.6;#FFFFFF]
label[7.8,0.3;Plant Compendium]
image_button[0,0;0.6,0.6;magnify_compendium_x.png;back;;false;false]
image_button[0.7,0;0.6,0.6;magnify_compendium_nav_fwd.png;nav_forward;;false;false]
image_button[1.4,0;0.6,0.6;magnify_compendium_nav_back.png;nav_backward;;false;false]
box[0.5,1.1;0.7,0.5;#FFFFFF]
textarea[0.45,1.8;15.7,1;;;", info.com_name or info.sci_name or "Unknown", "]
textarea[0.45,2.7;15.7,2.2;;;Add text here!]
label[0.3,5.5;Associated nodes:]
textlist[0.2,5.7;16.2,6.7;associated_nodes;", table.concat(sorted_nodes or nodes, ","), ";1;false]
box[16.6,0.8;2.2,11.6;#00FF00]
box[0,12.6;19,0.4;#FFFFFF]
textarea[0.2,12.62;18.6,0.5;;;Last updated:]
]]


---------------------------
-- CALLBACK REGISTRATION --
---------------------------

-- Registers the plant compendium as an inventory button on the main inventory page
-- Partially based on the inventory button implementation in Minetest-WorldEdit
if minetest.get_modpath("sfinv") ~= nil then
    local default_get = sfinv.pages[sfinv.get_homepage_name()].get
    sfinv.override_page(sfinv.get_homepage_name(), {
        get = function(self, player, context)
            if check_perm(player) then
                return table.concat({
                    default_get(self, player, context),
                    "image_button[7,0;1,1;magnify_compendium_icon_square.png;magnify_plant_compendium;;false;false]",
                    "tooltip[magnify_plant_compendium;Plant Compendium]"
                })
            end
        end
    })

    minetest.register_on_player_receive_fields(function(player, formname, fields)
        local pname = player:get_player_name()
        local context = get_context(pname)
        local form_action = formname

        minetest.log(minetest.serialize(context.page))

        -- inventory handler
        if formname == "" then
            if fields.magnify_plant_compendium then
                context.page = MENU
                nav_append(context, {
                    p = MENU, exit = false, com = context.show_common, filter_par = context.filter_parity,
                    filter = context.filter and table.copy(context.filter) or get_blank_filter_table(),
                    sel = {f = context.family.selected, g = context.genus.selected, s = context.species.selected}
                })
                open_fs(player, formname, build_compendium_formspec(context))
            end
            
            if context.page and context.page >= 1 then -- magnify inventory view active
                if fields.quit or (fields.back and context.page == MENU) then
                    sfinv.set_page(player, sfinv.get_homepage_name(player))
                    sfinv.set_player_inventory_formspec(player)
                    return context:clear()
                elseif fields.back then
                    if context.page == STANDARD_VIEW then
                        context.page = MENU
                        nav_append(context, {
                            p = MENU, exit = false, com = context.show_common, filter_par = context.filter_parity,
                            filter = context.filter and table.copy(context.filter) or get_blank_filter_table(),
                            sel = {f = context.family.selected, g = context.genus.selected, s = context.species.selected}
                        })
                        open_fs(player, formname, build_compendium_formspec(context))
                    elseif context.page == TECH_VIEW then
                        context.page = STANDARD_VIEW
                        nav_append(context, {
                            p = STANDARD_VIEW, exit = false, img = context.image,
                            sel = {f = context.family.selected, g = context.genus.selected, s = context.species.selected}
                        })
                        open_fs(player, formname, build_viewer_formspec(get_selected_species_ref(context), false, player))
                    end
                end
                form_action = (context.page == MENU and "magnify:compendium") or (context.page == STANDARD_VIEW and "magnify:view") or (context.page == TECH_VIEW and "magnify:tech_view") or form_action
            end
        end
    
        -- (common) navigation action handler
        if magnify.table_has({"magnify:compendium", "magnify:view", "magnify:tech_view"}, form_action) and (fields.nav_forward or fields.nav_backward) then
            local index = context.nav.index + (fields.nav_forward and 1 or -1)
            local page_table = context.nav.list[index]
            if page_table then
                -- restore selected species/ref on page
                if page_table.sel then
                    context.family.selected = page_table.sel.f
                    context.genus.selected = page_table.sel.g
                    context.species.selected = page_table.sel.s
                    context.ref = nil
                elseif page_table.ref then
                    context.family.selected = 1
                    context.genus.selected = 1
                    context.species.selected = 1
                    context.ref = page_table.ref
                end

                local page_table_map = {
                    [MENU] = function()
                        context.show_common = page_table.com
                        context.filter = page_table.filter
                        context.filter_parity = page_table.filter_par
                        reload_fs(player, formname == "" and formname or "magnify:compendium",
                            build_compendium_formspec(context, page_table.exit)
                        )
                    end,
                    [STANDARD_VIEW] = function()
                        context.image = page_table.img
                        reload_fs(player, formname == "" and formname or "magnify:view",
                            build_viewer_formspec(get_selected_species_ref(context), page_table.exit, player)
                        )
                    end,
                    [TECH_VIEW] = function()
                        reload_fs(player, formname == "" and formname or "magnify:tech_view",
                            build_technical_formspec(get_selected_species_ref(context), page_table.exit, player)
                        )
                    end,
                }
                if page_table_map[page_table.p] then
                    -- restore appropriate page in list
                    context.nav.index = index
                    context.page = page_table.p
                    return page_table_map[page_table.p]()
                end
            end
        end

        -- formspec action handler
        if form_action == "magnify:compendium" then
            local reload = false

            -- handle compendium functions
            if fields.family_list then
                local event = minetest.explode_textlist_event(fields.family_list)
                if event.type == "CHG" then
                    if context.family.selected ~= tonumber(event.index) then
                        -- Reset all lower levels
                        context.genus.selected = 1
                        context.species.selected = 1
                    end
                    context.family.selected = tonumber(event.index)
                    reload = reload and math.min(RELOAD.FULL, reload) or RELOAD.FULL
                end
            end
            if fields.genus_list then
                local event = minetest.explode_textlist_event(fields.genus_list)
                if event.type == "CHG" then
                    if context.genus.selected ~= tonumber(event.index) then
                        -- Reset all lower levels
                        context.species.selected = 1
                    end
                    context.genus.selected = tonumber(event.index)
                    reload = reload and math.min(RELOAD.GEN_UP, reload) or RELOAD.GEN_UP

                    -- Find appropriate family if genus was selected first
                    if context.family.selected <= 1 then
                        local genus = context.show_common and extract_sci_text(context.genus.list[context.genus.selected]) or context.genus.list[context.genus.selected]
                        for fam,list in pairs(context.tree) do
                            if magnify.table_has(list, genus) then
                                for i,f_raw in ipairs(context.family.list) do
                                    local f = context.show_common and extract_sci_text(f_raw) or f_raw
                                    if f == fam then
                                        context.family.selected = i
                                        break
                                    end
                                end
                                break
                            end
                        end
                        -- Set flag to update genus
                        context.genus.shift = genus
                    end
                end
            end
            if fields.species_list then
                local event = minetest.explode_textlist_event(fields.species_list)
                if event.type == "CHG" then
                    context.species.selected = tonumber(event.index)
                    reload = reload and math.min(RELOAD.SPC_UP, reload) or RELOAD.SPC_UP
                elseif event.type == "DCL" then
                    -- open viewer
                    context.image = 1
                    context.page = STANDARD_VIEW
                    nav_append(context, {
                        p = STANDARD_VIEW, exit = false, img = context.image,
                        sel = {f = context.family.selected, g = context.genus.selected, s = context.species.selected}
                    })
                    open_fs(player, formname == "" and formname or "magnify:view", build_viewer_formspec(get_selected_species_ref(context), false, player))
                end
            end
            if fields.view then
                -- open viewer
                context.image = 1
                context.page = STANDARD_VIEW
                nav_append(context, {
                    p = STANDARD_VIEW, exit = false, img = context.image,
                    sel = {f = context.family.selected, g = context.genus.selected, s = context.species.selected}
                })
                open_fs(player, formname == "" and formname or "magnify:view", build_viewer_formspec(get_selected_species_ref(context), false, player))
            end
          
            if (fields.search_go or fields.key_enter_field == "search") and fields.search ~= "" then
                -- initialize search + reset selection
                context.search = fields.search
                context.family.selected = 1
                context.genus.selected = 1
                context.species.selected = 1

                reload = reload and math.min(RELOAD.FULL, reload) or RELOAD.FULL
            end
            if fields.search_x or ((fields.search_go or fields.key_enter_field == "search") and fields.search == "") then
                -- reset search + selection
                context.search = nil
                context.family.selected = 1
                context.genus.selected = 1
                context.species.selected = 1
                reload = reload and math.min(RELOAD.FULL, reload) or RELOAD.FULL
            end

            if fields.toggle_common then
                context.show_common = (fields.toggle_common == "true" and true) or false
                nav_update_current(context, {com = context.show_common})
                reload = reload and math.min(RELOAD.FULL, reload) or RELOAD.FULL
            end

            -- checkboxes
            context.filter = context.filter or get_blank_filter_table()
            local all_boxes = CHECKBOXES:get_all()
            for name,val in pairs(fields) do
                local name_split = string.split(name, "_", false, 2)
                if magnify.table_has(all_boxes, (name_split[2] or "").."_"..(name_split[3] or "")) then
                    local cat, tag = name_split[2], name_split[3]
                    if cat and tag then
                        context.filter.select[cat] = context.filter.select[cat] or {}
                        context.filter.select[cat][tag] = val == "true" and true or nil
                        --nav_update_current(context, {filter = table.copy(context.filter)}) -- intentionally omitting
                    end
                end
            end

            if fields.filter_apply then
                context.filter.active = table.copy(context.filter.select)
                context.family.selected = 1
                context.genus.selected = 1
                context.species.selected = 1
                nav_update_current(context, {filter = table.copy(context.filter)})
                reload = reload and math.min(RELOAD.FULL, reload) or RELOAD.FULL
            end
            if fields.filter_clear then
                context.filter = get_blank_filter_table()
                context.filter_parity = context.filter_parity + 1
                context.family.selected = 1
                context.genus.selected = 1
                context.species.selected = 1
                nav_update_current(context, {filter = table.copy(context.filter), filter_par = context.filter_parity})
                reload = reload and math.min(RELOAD.FULL, reload) or RELOAD.FULL
            end

            if formname == "magnify:compendium" and (fields.back or fields.quit) then
                context:clear()
            end

            context.reload = reload
            if reload then
                nav_update_current(context, {
                    sel = {f = context.family.selected, g = context.genus.selected, s = context.species.selected}
                })
                reload_fs(player, formname, build_compendium_formspec(context, formname ~= ""))
            end
        elseif form_action == "magnify:view" then
            -- handle viewer functions
            local reload = false

            if fields.locate then
                local ref = get_selected_species_ref(context)
                local info,nodes = magnify.get_species_from_ref(ref)

                if not context.search_in_progress then
                    context.search_in_progress = true
                    minetest.chat_send_player(player:get_player_name(), "Searching for nearby nodes, please wait...")
                    minetest.after(0.1, search_for_nearby_node, player, context, nodes)
                else
                    minetest.chat_send_player(player:get_player_name(), "There is already a node search in progress! Please wait for your current search to finish before starting another.")
                end
            end
            if fields.favourite then
                local mdata = magnify.get_mdata(player)
                local ref = get_selected_species_ref(context)
                if mdata.favourites then
                    if mdata.favourites[ref] then
                        mdata.favourites[ref] = nil
                    else
                        mdata.favourites[ref] = true
                    end
                    magnify.save_mdata(player, mdata)
                    reload = true
                end
            end
            if fields.compendium_view then
                -- get selected species
                select_species_with_ref(context, get_selected_species_ref(context))

                -- view species in compendium
                context.page = MENU
                nav_append(context, {
                    p = MENU, exit = formname ~= "", com = context.show_common, filter_par = context.filter_parity,
                    filter = context.filter and table.copy(context.filter) or get_blank_filter_table(),
                    sel = {f = context.family.selected, g = context.genus.selected, s = context.species.selected}
                })
                open_fs(player, formname == "" and formname or "magnify:compendium", build_compendium_formspec(context, formname ~= ""))
            end
            if fields.tech_view then
                -- open technical viewer
                context.page = TECH_VIEW
                nav_append(context, {
                    p = TECH_VIEW, exit = false, ref = context.ref,
                    sel = not context.ref and {f = context.family.selected, g = context.genus.selected, s = context.species.selected}
                })
                open_fs(player, formname == "" and formname or "magnify:tech_view", build_technical_formspec(get_selected_species_ref(context), false, player))
            end

            for k,v in pairs(fields) do
                if string.sub(k, 1, 6) == "image_" then
                    context.image = tonumber(string.sub(k, 7, 7)) or context.image or 1
                    nav_update_current(context, {img = context.image})
                    reload = true
                end
            end

            if formname == "magnify:view" then
                if fields.quit or (fields.back and context.ref) then
                    context:clear()
                elseif fields.back then
                    -- view species in compendium
                    context.page = MENU
                    nav_append(context, {
                        p = MENU, exit = true, com = context.show_common, filter_par = context.filter_parity,
                        filter = context.filter and table.copy(context.filter) or get_blank_filter_table(),
                        sel = {f = context.family.selected, g = context.genus.selected, s = context.species.selected}
                    })
                    open_fs(player, "magnify:compendium", build_compendium_formspec(context, true))
                end
            end

            if reload == true then
                reload_fs(player, formname, build_viewer_formspec(get_selected_species_ref(context), formname ~= "" and context.ref, player))
            end
        elseif form_action == "magnify:tech_view" then
            if formname == "magnify:tech_view" then
                if fields.quit then
                    context:clear()
                end
                if fields.back then
                    -- open viewer
                    local is_exit = formname ~= "" and context.ref and true
                    context.page = STANDARD_VIEW
                    nav_append(context, {
                        p = STANDARD_VIEW, exit = is_exit, img = context.image, ref = context.ref,
                        sel = not context.ref and {f = context.family.selected, g = context.genus.selected, s = context.species.selected}
                    })
                    open_fs(player, formname == "" and formname or "magnify:view", build_viewer_formspec(get_selected_species_ref(context), is_exit, player))
                end
            end
        end
    end)
end

-- Storage cleanup function: removes any registered species that do not have any nodes associated with them
minetest.register_on_mods_loaded(function()
    local ref_list = {}
    local storage_data = magnify.species.ref:to_table()
    -- collect all refs
    for ref,_ in pairs(storage_data.fields) do
        if tonumber(ref) ~= nil then
            ref_list[tostring(ref)] = true
        end
    end
    -- check that some node is still asociated with each ref
    for _,ref in pairs(magnify.species.node) do
        ref_list[tostring(ref)] = nil
    end
    -- remove all refs that are not associated with any nodes
    for ref,_ in pairs(ref_list) do
        magnify.clear_ref(ref)
    end
end)

-- Player metadata update caller
minetest.register_on_joinplayer(function(player)
    -- Calling this will ensure that magnify player metadata exists and is in the latest format
    magnify.get_mdata(player)
end)


-----------------------
-- TOOL REGISTRATION --
-----------------------

-- Registers the magnifying glass tool
minetest.register_tool(tool_name, {
    description = "Magnifying Glass",
    _doc_items_longdesc = "This tool can be used to quickly learn more about about one's closer environment. It identifies and analyzes plant-type blocks and it shows extensive information about the thing on which it is used.",
    _doc_items_usagehelp = "Punch any block resembling a plant you wish to learn more about. This will open up the appropriate help entry.",
    _doc_items_hidden = false,
    tool_capabilities = {},
    range = 10,
    groups = { disable_repair = 1 }, 
    wield_image = "magnify_magnifying_tool.png",
    inventory_image = "magnify_magnifying_tool.png",
    liquids_pointable = false,
    on_use = function(itemstack, player, pointed_thing)
        if not check_perm(player) or pointed_thing.type ~= "node" then
            return nil
        else
            local pname = player:get_player_name()

            local node = {under = minetest.get_node(pointed_thing.under).name, above = minetest.get_node(pointed_thing.above).name}
            local ref_key = magnify.get_ref(node.under) or magnify.get_ref(node.above)
    
            if ref_key then
                -- try to build formspec
                local view_fs = build_viewer_formspec(ref_key, true, player)
                local mdata = magnify.get_mdata(player)
                if view_fs then
                    -- good: save to discovered list and open formspec
                    if mdata and mdata.discovered and not mdata.discovered[ref_key] then
                        mdata.discovered[ref_key] = true
                        magnify.save_mdata(player, mdata)
                    end
                    local context = get_context(pname)
                    context.ref = ref_key
                    nav_append(context, {
                        p = STANDARD_VIEW, exit = true, img = context.image, ref = context.ref
                    })
                    open_fs(player, "magnify:view", view_fs)
                else
                    -- bad: display corrupted node message in chat
                    minetest.chat_send_player(pname, "An entry for this item exists, but could not be found in the species database.\nPlease contact an administrator and ask them to check your server's species database files to ensure all species were registered properly.")
                end
            else
                -- bad: display failure message in chat
                minetest.chat_send_player(pname, "No entry for this item could be found.")
            end

            -- Register a node punch
            minetest.node_punch(pointed_thing.under, minetest.get_node(pointed_thing.under), player, pointed_thing)

            return nil
        end
    end,
    -- makes the tool undroppable in MineTest Classroom
    on_drop = function(itemstack, dropper, pos)
        -- should eventually be replaced with a more flexible check
        if not minetest.get_modpath("mc_core") then
            return minetest.item_drop(itemstack, dropper, pos)
        end
    end
})

if minetest.get_modpath("mc_toolhandler") then
    mc_toolhandler.register_tool_manager(tool_name, {privs = priv_table})
end

-- Register tool aliases for convenience
minetest.register_alias("magnify:magnifying_glass", tool_name)
minetest.register_alias("magnifying_tool", tool_name)
minetest.register_alias("magnifying_glass", tool_name)
minetest.register_alias("magnify_tool", tool_name)

-- Register crafting recipes for magnifying glass tool
minetest.register_craft({
    output = tool_name,
    recipe = {
        {"default:glass", "default:glass", ""},
        {"default:glass", "default:glass", ""},
        {"", "", "group:stick"}
    }
})
minetest.register_craft({
    output = tool_name,
    recipe = {
        {"", "default:glass", "default:glass"},
        {"", "default:glass", "default:glass"},
        {"group:stick", "", ""}
    }
})
