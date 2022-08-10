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
      
    local genus_raw = {}
    for fam,gen_raw in pairs(context.tree) do
        table.insert(context.family.list, fam)
        table.insert(genus_raw, gen_raw)
    end
    table.insert(context.family.list, minetest.formspec_escape("#CCFFCC[Select a family]"))
    table.sort(context.family.list)
  
    if context.family.selected > 1 then
        -- build specific genus list
        local family = context.family.list[context.family.selected]
        local genus_list = context.tree[family]
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

    local size = "size[17,12.6]"
    local formtable = {
        "formspec_version[6]", size,
        "box[0,0;17,0.6;#FFFFFF]",
        "label[6.7,0.3;Plant Compendium]",
        "button[0,0;1.7,0.6;back;      Back]",
        "image[0,0;0.6,0.6;texture.png]",
        "field[0.4,1.3;6.7,0.7;search;Search by common/scientific name;]",
        "button[7.1,1.3;2.2,0.7;search_go;       Search]",
        "image[7.1,1.3;0.7,0.7;texture.png]",
        "button[9.2,1.3;1.9,0.7;search_x;       Clear]",
        "image[9.2,1.3;0.7,0.7;texture.png]",
        --"image[14.8,1;1.8,1;species.png]",
        --"textarea[11.5,0.9;3.3,1.1;;;]",
        "box[0.4,2.4;3.5,0.7;#A0A0A0]",
        "label[1.6,2.8;Family]",
        "textlist[0.4,3.2;3.5,9;family_list;", table.concat(context.family.list, ","), ";", context.family.selected or 1, ";false]",
        "box[4,2.4;3.5,0.7;#A0A0A0]",
        "label[5.2,2.8;Genus]",
        "textlist[4,3.2;3.5,9;genus_list;", table.concat(context.genus.list, ","), ";", context.genus.selected or 1, ";false]",
        "box[7.6,2.4;3.5,0.7;#A0A0A0]",
        "label[8.7,2.8;Species]",
        "textlist[7.6,3.2;3.5,9;species_list;", table.concat(context.species.list, ","), ";", context.species.selected or 1, ";false]",
        "container[0,1.1]",
        "box[11.5,1.3;5.1,0.7;#A0A0A0]",
        "label[13.7,1.7;Filter]",
        "box[11.5,2.0;5.1,7.9;#121212]",
        "label[11.8,2.5;Form:]",
        "checkbox[11.8,3;form_tree;Tree;false]",
        "checkbox[11.8,3.4;form_shrub;Shrub;false]",
        "label[11.8,4.1;Leaves:]",
        "checkbox[11.8,4.6;leaf_conif;Coniferous;false]",
        "checkbox[11.8,5.0;leaf_decid;Deciduous;false]",
        "checkbox[11.8,5.4;leaf_ever;Evergreen;false]",
        "label[11.8,6.1;Conservation Status:]",
        "checkbox[11.8,6.6;cons_gx;GX (Presumed Extinct);false]",
        "checkbox[11.8,7;cons_gh;GH (Possibly Extinct);false]",
        "checkbox[11.8,7.4;cons_g1;G1 (Critcally Imperiled);false]",
        "checkbox[11.8,7.8;cons_g2;G2 (Imperiled);false]",
        "checkbox[11.8,8.2;cons_g3;G3 (Vulnerable);false]",
        "checkbox[11.8,8.6;cons_g4;G4 (Apparently Secure);false]",
        "checkbox[11.8,9;cons_g5;G5 (Secure);false]",
        "checkbox[11.8,9.4;cons_na;GNR/GU/GNA (Unranked);false]",
        "container_end[]",

        --[["bgcolor[#00FF00;true]", -- #172e1b
        "set_focus[species_list]",
        "textlist[0,0;7.8,3.75;species_list;", table.concat(species_list, ","), ";", context.species_selected or 1, ";false]",
        "button[0,4.05;4,0.6;standard_view;View Species]",
        "button[4,4.05;4,0.6;technical_view;View Technical Info]",
        "field_close_on_enter[search;false]",
        "field[0.3,5.72;5.56,1;search;Search for a species", (context.species_search and " (current: \""..minetest.formspec_escape(context.species_search).."\")") or "", ";]",
        "button[5.5,5.4;1.3,1;search_search;Search]",
        "button[6.7,5.4;1.3,1;search_clear;Clear]"]]
    }
    return table.concat(formtable, ""), size
end

--[[
formspec_version[6]
size[17,12.6]
box[0,0;17,0.6;#FFFFFF]
label[6.7,0.3;Plant Compendium]
button[0,0;1.7,0.6;back;      Back]
image[0,0;0.6,0.6;]
field[0.4,1.3;6.7,0.7;search;Search by common/scientific name;]
button[7.1,1.3;2.2,0.7;search_go;       Search]
image[7.1,1.3;0.7,0.7;texture.png]
button[9.2,1.3;1.9,0.7;search_x;       Clear]
image[9.2,1.3;0.7,0.7;texture.png]
image[14.8,1;1.8,1;species.png]
textarea[11.5,0.9;3.3,1.1;;;]
box[0.4,2.4;3.5,0.7;#A0A0A0]
label[1.7,2.8;Family]
textlist[0.4,3.2;3.5,9;;;1;false]
box[4,2.4;3.5,0.7;#A0A0A0]
label[5.3,2.8;Genus]
textlist[4,3.2;3.5,9;;;1;false]
box[7.6,2.4;3.5,0.7;#A0A0A0]
label[8.8,2.8;Species]
textlist[7.6,3.2;3.5,9;;;1;false]
box[11.5,1.3;5.1,0.7;#A0A0A0]
"label[13.7,1.7;Filter]
box[11.5,2.0;5.1,7.9;#121212]
label[11.8,2.5;Form:]
checkbox[11.8,3;form_tree;Tree;false]
checkbox[11.8,3.4;form_shrub;Shrub;false]
label[11.8,4.1;Leaves:]
checkbox[11.8,4.6;leaf_conif;Coniferous;false]
checkbox[11.8,5.0;leaf_decid;Deciduous;false]
checkbox[11.8,5.4;leaf_ever;Evergreen;false]
label[11.8,6.1;Conservation Status:]
checkbox[11.8,6.6;cons_gx;GX (Presumed Extinct);false]
checkbox[11.8,7;cons_gh;GH (Possibly Extinct);false]
checkbox[11.8,7.4;cons_g1;G1 (Critcally Imperiled);false]
checkbox[11.8,7.8;cons_g2;G2 (Imperiled);false]
checkbox[11.8,8.2;cons_g3;G3 (Vulnerable);false]
checkbox[11.8,8.6;cons_g4;G4 (Apparently Secure);false]
checkbox[11.8,9;cons_g5;G5 (Secure);false]
checkbox[11.8,9.4;cons_na;GNR/GU/GNA (Unranked);false]
]]

--- Filters lists of all species down to species whose reference keys, common names, scientific names or family names contain the substring `query`
--- @param query Substring to search for
--- @param species_list List of species name to filter
--- @param ref_list List of reference keys to filter
--- @return table, table
local function species_search_filter(query, species_list, ref_list)
    local filtered_lists = {species = {}, ref = {}}
    local function match_query(str)
        return string.find(string.lower(str), string.lower(query:trim()), 1, true)
    end

    for i,ref in ipairs(ref_list) do
        local species = magnify.get_species_from_ref(ref)
        local match = match_query(species.com_name) or match_query(species.sci_name) or match_query(species.fam_name) or match_query(ref)
        if match then
            table.insert(filtered_lists.species, species_list[i])
            table.insert(filtered_lists.ref, ref_list[i])
        end
    end
    return filtered_lists.species, filtered_lists.ref
end

-- Registers the plant compendium as an inventory tab
--[[sfinv.register_page("magnify:compendium", {
    title = "Plant Compendium", -- add translations
    get = function(self, player, context)
        if context.species_view == STANDARD_VIEW or context.species_view == TECH_VIEW then
            -- create species/technical view
            local pname = player:get_player_name()
            local ref = get_species_ref(context.species_i_to_ref, context.species_selected)
            
            local formtable, size = nil, nil

            if context.species_view == STANDARD_VIEW then
                formtable,size = magnify.build_formspec_from_ref(ref, false, true)
            elseif context.species_view == TECH_VIEW then
                formtable,size = get_expanded_species_formspec(ref)
            end
                
            minetest.sound_play("page_turn", {to_player = pname, gain = 1.0, pitch = 1.0,}, true)

            if not formtable then
                formtable = "label[0,0;Uh oh, something went wrong...]button[0,0.5;5,0.6;back;Back]" -- fallback
            end

            return sfinv.make_formspec(player, context, formtable, false, size)
        else
            local species_list, ref_list = magnify.get_all_registered_species()
            if context.species_search then
                -- filter species by search results
                species_list, ref_list = species_search_filter(context.species_search, species_list, ref_list)
            end

            -- log which species are present in the menu
            context.species_i_to_ref = {}
            for i,ref in pairs(ref_list) do
                context.species_i_to_ref[i] = tonumber(ref)
            end
            local formspec,size = get_compendium_formspec(context)
            -- create menu
            return sfinv.make_formspec(player, context, formspec, false, size)
        end
    end,
    on_enter = function(self, player, context)
        context.species_view = context.species_view or MENU
        context.species_selected = context.species_selected or 1
    end,
    on_player_receive_fields = function(self, player, context, fields)
        if fields.key_enter_field == "search" or fields.search_go then
            -- note search query + reset selection
            context.species_search = fields.search
            context.species_selected = 1
            -- refresh inventory formspec
            sfinv.set_player_inventory_formspec(player)
        elseif fields.search_x then
            -- clear search + reset selection
            context.species_search = nil
            context.species_selected = 1
            -- refresh inventory formspec
            sfinv.set_player_inventory_formspec(player)
        elseif fields.species_list then
            local event = minetest.explode_textlist_event(fields.species_list)
            if event.type == "CHG" then
                context.species_selected = event.index
            end
        elseif fields.standard_view or fields.technical_view then
            if context.species_selected then
                local pname = player:get_player_name()
                local ref = get_species_ref(context.species_i_to_ref, context.species_selected)
                
                if magnify.get_species_from_ref(ref) then
                    if fields.standard_view then -- standard
                        context.species_view = STANDARD_VIEW
                    else -- technical
                        context.species_view = TECH_VIEW
                    end
                else
                    minetest.chat_send_player(pname, "An entry for this species exists, but could not be found in the species database.\nPlease contact an administrator and ask them to check your server's species database files to ensure all species were registered properly.")
                end

                -- refresh inventory formspec
                sfinv.set_player_inventory_formspec(player)
            end
        elseif fields.back then
            context.species_view = MENU
            -- refresh inventory formspec
            sfinv.set_player_inventory_formspec(player)
        elseif fields.locate then
            local ref = get_species_ref(context.species_i_to_ref, context.species_selected)
            local info,nodes = magnify.get_species_from_ref(ref)

            if not context.search_in_progress then
                context.search_in_progress = true
                minetest.chat_send_player(player:get_player_name(), "Searching for nearby nodes, please wait...")
                search_for_nearby_node(player, context, nodes)
            else
                minetest.chat_send_player(player:get_player_name(), "There is already a node search in progress! Please wait for your current search to finish before starting another.")
            end
        end
    end,
    is_in_nav = function(self, player, context)
        -- only shows the compendium to players with adequate privileges
        return check_perm(player)
    end
})]]

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
                elseif event.type == "DCL" then
                    -- open viewer
                    local view_fs = magnify.build_formspec_from_ref(get_selected_species_ref(context), false)
                    if view_fs then
                        context.page = STANDARD_VIEW
                        return player:set_inventory_formspec(view_fs)
                    end
                end
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
