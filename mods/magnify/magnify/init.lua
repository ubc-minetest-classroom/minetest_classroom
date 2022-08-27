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

-- Checks for adequate privileges
local function check_perm(player)
    return minetest.check_player_privs(player:get_player_name(), priv_table)
end

local function get_context(player)
    local pname = (type(player) == "string" and player) or (player:is_player() and player:get_player_name()) or ""
    if not magnify.context[pname] then
        magnify.context[pname] = {
            clear = function(self)
                self = nil
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
        }
    end
    return magnify.context[pname]
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
                local species_formspec = magnify.build_formspec_from_ref(ref_key, true, false)
                if species_formspec then
                    -- good: open formspec
                    local context = get_context(pname)
                    context.ref = ref_key
                    minetest.show_formspec(pname, "magnify:view", species_formspec)
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
    local row_cells = math.ceil(math.sqrt(node_count))
    local cell_length = side_length / row_cells
    local output = {}
    local x_0 = 0
    local y_0 = side_length - cell_length

    -- adjustment factor based on scaling
    cell_length = cell_length + 0.6 * (1/4)^(row_cells-1)
    if row_cells == 1 then
        y_0 = y_0 - 0.1
        x_0 = x_0 + 0.2
    end

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
            y_0 = y_0 - cell_length
            if node_count - node_ctr < row_cells then
                -- center remaining elements in new row
                local increment = (row_cells - node_count + node_ctr) * cell_length / 2
                x_0 = x_0 + increment
            end
        else
            x_0 = x_0 + cell_length
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

--- Return the technical formspec for a species
--- @param ref Reference key of species
--- @return formspec string, size
local function get_technical_formspec(ref)
    local info,nodes = magnify.get_species_from_ref(ref)
    if info and nodes then
        local sorted_nodes = table.sort(nodes)
        local size = "size[12.4,6.7]"
        local formtable = {
            "formspec_version[5]", size,
            "box[0,0;12.2,0.8;#9192a3]",
            "label[4.8,0.2;Technical Information]",
            "label[0,1;", minetest.formspec_escape(info.com_name) or minetest.formspec_escape(info.sci_name) or "Unknown", " @ ref. ", minetest.formspec_escape(ref), "]",
            "textlist[0,2.1;7.4,3.7;associated_nodes;", table.concat(sorted_nodes or nodes, ","), ";1;false]",
            "label[0,1.6;Associated nodes:]",
            "button[6.2,6.2;6.2,0.6;back;Back]",
            "button[0,6.2;6.2,0.6;locate;Locate nearest node]",
            create_image_table(sorted_nodes or nodes, 7.6, 1.2, 4.8)
        }
        return table.concat(formtable, ""), size
    else
        return nil
    end
end

--[[
formspec_version[5]
size[12.4,6.7]
box[0,0;12.2,0.8;#9192a3]
label[4.8,0.2;Technical Information]
label[0,1;", info.com_name or info.sci_name or "Unknown", " @ ", ref, "]
textlist[0,2.1;7.4,3.7;associated_nodes;", table.concat(sorted_nodes or nodes, ","), ";1;false]
label[0,1.6;Associated nodes:]
button[6.2,6.2;6.2,0.6;back;Back]
button[0,6.2;6.2,0.6;locate;Locate nearest node]
]]

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

--- Filters tree of all species down to species which are tagges with the selected tags
--- @param tree Species tree
--- @param filters Selected tags to filter by
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

    --[[local function tag_match(species)
        return magnify.table_has(species.tags, tag)
    end
    return species_tree_filter_abstract(tree, function(species)

    end)]]

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

--- Return the plant compendium formspec, built from the given list of species
--- @return formspec string, size
local function get_compendium_formspec(context)
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

    if next(context.filter.active) then
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

    local size = "size[19,13]"
    local formtable = {
        "formspec_version[6]", size,

        "no_prepend[]",
        "bgcolor[#00000000;true;]",
        "background[0,0;0,0;magnify_pixel.png^[multiply:#000000^[opacity:69;true]",
        "image[0,0;19,0.6;magnify_pixel.png^[multiply:#F5F5F5^[opacity:76]",
        "style_type[label;font=mono,bold]",
        "label[7.8,0.3;Plant Compendium]",
        "image_button[0,0;0.6,0.6;magnify_compendium_x.png;back;;false;false]",
        "image_button[0.7,0;0.6,0.6;magnify_compendium_nav_back.png;nav_backward;;false;false]",
        "image_button[1.4,0;0.6,0.6;magnify_compendium_nav_fwd.png;nav_forward;;false;false]",
        "tooltip[back;Back]",
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
                info.texture and "image[17.5,1.3;1.2,0.7;"..(type(info.texture) == "table" and info.texture[1] or info.texture).."]" or "",
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
image_button[0,0;0.6,0.6;texture.png;back;;false;false]
image_button[0.7,0;0.6,0.6;texture.png;nav_forward;;false;false]
image_button[1.4,0;0.6,0.6;texture.png;nav_backward;;false;false]
field[0.4,1.3;7.2,0.7;search;Search by common or scientific name;]
button[7.6,1.3;3.2,0.7;search_go;   Search]
image[7.6,1.3;0.7,0.7;texture.png]
button[10.8,1.3;2.3,0.7;search_x;   Clear]
image[10.8,1.3;0.7,0.7;texture.png]
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

-- Registers the plant compendium as an inventory button on the main inventory page
-- Partially based on the inventory button implementation in Minetest-WorldEdit
if minetest.get_modpath("sfinv") ~= nil then
    local default_get = sfinv.pages[sfinv.get_homepage_name()].get
    sfinv.override_page(sfinv.get_homepage_name(), {
        get = function(self, player, context)
            if check_perm(player) then
                return table.concat({
                    default_get(self, player, context),
                    "image_button[7,0;1,1;magnify_magnifying_tool.png;magnify_plant_compendium;]",
                    "tooltip[magnify_plant_compendium;Plant Compendium]"
                })
            end
        end
    })

    minetest.register_on_player_receive_fields(function(player, formname, fields)
        local pname = player:get_player_name()
        local context = get_context(pname)
        local form_action = formname

        -- inventory handler
        if formname == "" then
            if fields.magnify_plant_compendium then
                context.page = MENU
                return player:set_inventory_formspec(get_compendium_formspec(context))
            end
            
            if context.page and context.page >= 1 then -- magnify inventory view active
                if fields.quit then
                    sfinv.set_page(player, sfinv.get_homepage_name(player))
                    sfinv.set_player_inventory_formspec(player)
                    return context:clear()
                end
                if fields.back then
                    if context.page == MENU then
                        sfinv.set_page(player, sfinv.get_homepage_name(player))
                        sfinv.set_player_inventory_formspec(player)
                        return context:clear()
                    elseif context.page == STANDARD_VIEW then
                        context.page = MENU
                        return player:set_inventory_formspec(get_compendium_formspec(context))
                    end
                end
                form_action = (context.page == MENU and "magnify:compendium") or (context.page == STANDARD_VIEW and "magnify:view") or (context.page == TECH_VIEW and "magnify:tech_view") or form_action
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
                    local view_fs = magnify.build_formspec_from_ref(get_selected_species_ref(context), false)
                    if view_fs then
                        context.page = STANDARD_VIEW
                        minetest.sound_play("page_turn", {to_player = pname, gain = 1.0, pitch = 1.0,}, true)
                        return player:set_inventory_formspec(view_fs)
                    end
                end
            end
            if fields.view then
                -- open viewer
                local view_fs = magnify.build_formspec_from_ref(get_selected_species_ref(context), false)
                if view_fs then
                    context.page = STANDARD_VIEW
                    minetest.sound_play("page_turn", {to_player = pname, gain = 1.0, pitch = 1.0,}, true)
                    return player:set_inventory_formspec(view_fs)
                end
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
                    end
                end
            end

            if fields.filter_apply then
                context.filter.active = table.copy(context.filter.select)
                context.family.selected = 1
                context.genus.selected = 1
                context.species.selected = 1
                reload = reload and math.min(RELOAD.FULL, reload) or RELOAD.FULL
            end
            if fields.filter_clear then
                context.filter = get_blank_filter_table()
                context.filter_parity = context.filter_parity + 1
                context.family.selected = 1
                context.genus.selected = 1
                context.species.selected = 1
                reload = reload and math.min(RELOAD.FULL, reload) or RELOAD.FULL
            end

            context.reload = reload
            if reload then
                return player:set_inventory_formspec(get_compendium_formspec(context))
            end
        elseif form_action == "magnify:view" then
            -- handle viewer functions
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

            if (fields.back or fields.quit) and formname == "magnify:view" then
                context:clear()
            end
        elseif form_action == "magnify:tech_view" then
            -- handle technical functions
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
