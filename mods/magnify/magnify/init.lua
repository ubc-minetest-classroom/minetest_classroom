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

-- Checks for adequate privileges
local function check_perm(player)
    return minetest.check_player_privs(player:get_player_name(), priv_table)
end

local function get_context(player)
    local pname = (type(player) == "string" and player) or (player:is_player() and player:get_player_name()) or ""
    if not magnify.context[pname] then
        magnify.context[pname] = {
            save = function(self)
                magnify.context[pname] = self
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
            filter = {
                form = {},
                leaf = {},
                status = {},
            }
        }
    end
    return magnify.context[pname]
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

--- Return the reference key of the species that is currently selected
--- @param context Magnify player context table
--- @return string
local function get_selected_species_ref(context)
    if context.ref then
        return context.ref
    end

    local sel = {
        f = context.family.list[context.family.selected] or "",
        g = context.genus.list[context.genus.selected] or "",
        s = context.species.list[context.species.selected] or "",
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
local function get_expanded_species_formspec(ref)
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

--- Filters lists of all species down to species whose reference keys, common names, scientific names or family names contain the substring `query`
--- @param query Substring to search for
--- @param tree Species tree
--- @return table
local function species_search_filter(query, tree)
    local filtered_tree = {}
    local count = 0
    local function match_query(str)
        return string.find(string.lower(str or ""), string.lower(query:trim()), 1, true)
    end

    for fam,g_list in pairs(tree) do
        for gen,s_list in pairs(g_list) do
            for spec,ref in pairs(s_list) do
                local species = magnify.get_species_from_ref(ref)
                local match = match_query(species.com_name) or match_query(species.sci_name) or match_query(species.fam_name) or match_query(ref) or match_query(magnify.map.family[species.fam_name])
                if match then
                    -- add match to filtered tree
                    local f_g_list = filtered_tree[fam] or {}
                    local f_s_list = f_g_list[gen] or {}
                    f_s_list[spec] = ref
                    f_g_list[gen] = f_s_list
                    filtered_tree[fam] = f_g_list
                    count = count + 1
                end
            end
        end
    end
    return filtered_tree, count
end

--- Return the plant compendium formspec, built from the given list of species
--- @return formspec string, size
local function get_compendium_formspec(context)
    if not context.tree then
        -- build tree and family list
        context.tree = magnify.get_registered_species_tree()
    end
    context.family.list = {}
    context.genus.list = {}
    context.species.list = {}
  
    local tree = context.tree
    local count
    if context.search then
        tree,count = species_search_filter(context.search, tree)
    end
    if context.filter.active then
        -- todo
    end

    -- Auto-select when only 1 species matches filter criteria
    if count == 1 then
        context.family.selected = 2
        context.genus.selected = 2
        context.species.selected = 2
    end
        
    local genus_raw = {}
    for fam,gen_raw in pairs(tree) do
        table.insert(context.family.list, fam)
        table.insert(genus_raw, gen_raw)
    end
    table.insert(context.family.list, minetest.formspec_escape("#CCFFCC[Select a family]"))
    table.sort(context.family.list)
  
    if context.family.selected > 1 then
        -- build specific genus list
        local family = context.family.list[context.family.selected]
        local genus_list = tree[family]
        for gen,_ in pairs(genus_list) do
            table.insert(context.genus.list, gen)
        end
        table.insert(context.genus.list, minetest.formspec_escape("#CCFFCC[Select a genus]"))
        table.sort(context.genus.list)
    
        if context.genus.shift then
            for i,g in ipairs(context.genus.list) do
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
            local genus = context.genus.list[context.genus.selected]
            local species_list = genus_list[genus]
            for spec,_ in pairs(species_list) do
                table.insert(context.species.list, spec)
            end
            table.insert(context.species.list, minetest.formspec_escape("#CCFFCC[Select a species]"))
            table.sort(context.species.list)
        else
            table.insert(context.species.list, minetest.formspec_escape("#B0B0B0[Select a genus first]"))
        end
    else
        -- build general genus list
        for i,list in pairs(genus_raw) do
            for gen,_ in pairs(list) do
                table.insert(context.genus.list, gen)
            end
        end
        table.insert(context.genus.list, minetest.formspec_escape("#CCFFCC[Select a genus]"))
        table.sort(context.genus.list)
        table.insert(context.species.list, minetest.formspec_escape("#B0B0B0[Select a genus first]"))
    end
    context:save()

    local size = "size[19,13]"
    local formtable = {
        "formspec_version[6]", size,

        "no_prepend[]",
        "bgcolor[#00000000;true;]",
        "background[0,0;0,0;magnify_pixel.png^[multiply:#000000^[opacity:69;true]",
        "image[0,0;19,0.6;magnify_pixel.png^[multiply:#F5F5F5^[opacity:76]",
        "style_type[label;font=mono]",
        "label[7.8,0.3;Plant Compendium]",
        "image_button[0,0;0.6,0.6;texture.png;back;;false;false]",
        "image_button[0.7,0;0.6,0.6;texture.png;nav_backward;;false;false]",
        "image_button[1.4,0;0.6,0.6;texture.png;nav_forward;;false;false]",
        "tooltip[back;Back]",
        "tooltip[nav_forward;Next]",
        "tooltip[nav_backward;Previous]",

        "style[search;font=mono]",
        "field[0.4,1.3;8.2,0.7;search;Search by common/scientific name;", context.search or "", "]",
        "field_close_on_enter[search;false]",
        "style_type[button;font=mono;border=false;bgimg=magnify_pixel.png^[multiply:#000000]",
        "button[8.6,1.3;2.4,0.7;search_go;   Search]",
        "image[8.6,1.3;0.7,0.7;texture.png]",
        "button[11,1.3;2.2,0.7;search_x;   Clear]",
        "image[11,1.3;0.7,0.7;texture.png]",
        "checkbox[0.4,2.3;toggle_common;Show common names;false]",

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
        "image[13.6,3.5;5,8.2;magnify_pixel.png^[multiply:#1E1E1E]",
        "label[13.8,3.9;Form:]",
        "checkbox[13.8,4.4;form_tree;Tree;false]",
        "checkbox[13.8,4.8;form_shrub;Shrub;false]",
        "label[13.8,5.5;Leaves:]",
        "checkbox[13.8,6;leaf_decid;Deciduous;false]",
        "checkbox[13.8,6.4;leaf_ever;Evergreen;false]",
        "label[13.8,7.1;Conservation Status:]",
        "checkbox[13.8,7.6;cons_gx;GX (Presumed Extinct);false]",
        "checkbox[13.8,8;cons_gh;GH (Possibly Extinct);false]",
        "checkbox[13.8,8.4;cons_g1;G1 (Critcally Imperiled);false]",
        "checkbox[13.8,8.8;cons_g2;G2 (Imperiled);false]",
        "checkbox[13.8,9.2;cons_g3;G3 (Vulnerable);false]",
        "checkbox[13.8,9.6;cons_g4;G4 (Apparently Secure);false]",
        "checkbox[13.8,10;cons_g5;G5 (Secure);false]",
        "checkbox[13.8,10.4;cons_na;GNR/GU/GNA (Unranked);false]",
        "button[13.8,10.8;4.6,0.7;filter_apply;Apply Filters]",
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
box[13.6,3.5;5,8.2;#121212]
label[13.8,3.9;Form:]
checkbox[13.8,4.4;form_tree;Tree;false]
checkbox[13.8,4.8;form_shrub;Shrub;false]
label[13.8,5.5;Leaves:]
checkbox[13.8,6;leaf_decid;Deciduous;false]
checkbox[13.8,6.4;leaf_ever;Evergreen;false]
label[13.8,7.1;Conservation Status:]
checkbox[13.8,7.6;cons_gx;GX (Presumed Extinct);false]
checkbox[13.8,8;cons_gh;GH (Possibly Extinct);false]
checkbox[13.8,8.4;cons_g1;G1 (Critcally Imperiled);false]
checkbox[13.8,8.8;cons_g2;G2 (Imperiled);false]
checkbox[13.8,9.2;cons_g3;G3 (Vulnerable);false]
checkbox[13.8,9.6;cons_g4;G4 (Apparently Secure);false]
checkbox[13.8,10;cons_g5;G5 (Secure);false]
checkbox[13.8,10.4;cons_na;GNR/GU/GNA (Unranked);false]
button[13.8,10.8;4.6,0.7;filter_apply;Apply]
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
                    return context.save(nil)
                end
                if fields.back then
                    if context.page == MENU then
                        sfinv.set_page(player, sfinv.get_homepage_name(player))
                        sfinv.set_player_inventory_formspec(player)
                        return context.save(nil)
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
                    reload = true
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
                    reload = true

                    -- Find appropriate family if genus was selected first
                    if context.family.selected <= 1 then
                        local genus = context.genus.list[context.genus.selected]
                        for fam,list in pairs(context.tree) do
                            if magnify.table_has(list, genus) then
                                for i,f in ipairs(context.family.list) do
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
                    reload = true
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
          
            if fields.search_go or fields.key_enter_field == "search" then
                -- initialize search + reset selection
                context.search = fields.search or ""
                context.family.selected = 1
                context.genus.selected = 1
                context.species.selected = 1
                reload = true
            end
            if fields.search_x then
                -- reset search + selection
                context.search = nil
                context.family.selected = 1
                context.genus.selected = 1
                context.species.selected = 1
                reload = true
            end

            if reload == true then
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
                context.save(nil)
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
