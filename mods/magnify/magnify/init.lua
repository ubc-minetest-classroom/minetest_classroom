magnify_plants = minetest.get_mod_storage()
dofile(minetest.get_modpath("magnify") .. "/api.lua")

-- constants
local tool_name = "magnify:magnifying_tool"
local priv_table = {interact = true}
local MENU = 1
local STANDARD_VIEW = 2
local TECH_VIEW = 3

-- Checks for adequate privileges
local function check_perm(player)
    return minetest.check_player_privs(player:get_player_name(), priv_table)
end

-- Clears the plant database
local function clear_table()
    local storage_data = magnify_plants:to_table()
    for k,v in pairs(storage_data.fields) do
        magnify_plants:set_string(k, "")
    end
end

-- reset: ensure count is initialized at 1
-- clear_table() -- find an alternative for this so that only species that have not been registered get removed
magnify_plants:set_int("count", 1)

-- Registers the magnifying glass tool
minetest.register_tool(tool_name, {
    description = "Magnifying Glass",
    _doc_items_longdesc = "This tool can be used to quickly learn more about about one's closer environment. It identifies and analyzes plant-type blocks and it shows extensive information about the thing on which it is used.",
    _doc_items_usagehelp = "Punch any block resembling a plant you wish to learn more about. This will open up the appropriate help entry.",
    _doc_items_hidden = false,
    _mc_privs = priv_table,
    tool_capabilities = {},
    range = 10,
    groups = { disable_repair = 1 }, 
    wield_image = "magnifying_tool.png",
    inventory_image = "magnifying_tool.png",
    liquids_pointable = false,
    on_use = function(itemstack, player, pointed_thing)
        if not check_perm(player) or pointed_thing.type ~= "node" then
            return nil
        else
            local pname = player:get_player_name()
            local node = minetest.get_node(pointed_thing.under).name
            local ref_key = magnify.get_ref(node)
    
            if ref_key then
                -- try to build formspec
                local species_formspec = magnify.build_formspec_from_ref(ref_key, true, false)
                if species_formspec then
                    -- good: open formspec
                    minetest.show_formspec(pname, "magnifying_tool:identify", species_formspec)
                else
                    -- bad: display corrupted node message in chat
                    minetest.chat_send_player(pname, "An entry for this item exists, but could not be found in the plant database.\nPlease contact an administrator and ask them to check your server's plant database files to ensure all plants were registered properly.")
                end
            else
                -- bad: display failure message in chat
                minetest.chat_send_player(pname, "No entry for this item could be found.")
            end
            return nil
        end
    end,
    -- makes the tool undroppable in MineTest Classroom
    on_drop = function(itemstack, dropper, pos)
        -- should eventually be replaced with a more flexible check
        if not minetest.get_modpath("mc_core") then
            minetest.item_drop(itemstack, dropper, pos)
            dropper:set_wielded_item(nil) -- removes the item from inventory: does not work without this
        end
    end
})

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

--- Return the reference key of the species at the given index in the species list
--- @param index The position in the species list to get the reference key for
--- @return string
--- @see magnify.get_all_registered_species()
local function get_species_ref(index)
    local list = magnify.get_all_registered_species()
    local elem = list[tonumber(index)]
    local ref_num_split = string.split(elem, ":") -- "###num:rest"
    local ref_str = ref_num_split[1]
    local ref_num = string.sub(ref_str, 4) -- removes "###" from "###num"
    return "ref_"..ref_num
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

--- Return the technical formspec for a species
--- @return formspec string, size
local function get_expanded_species_formspec(ref)
    local info,nodes = magnify.get_species_from_ref(ref)
    if info and nodes then
        local sorted_nodes = table.sort(nodes, function(a, b) return a < b end)
        local size = "size[12.4,6.7]"
        local formtable = {    
            "formspec_version[5]", size,
            "box[0,0;12.2,0.8;#9192a3]",
            "label[4.8,0.2;Technical Information]",
            "label[0,1;", info.com_name or info.sci_name or "Unknown", " @ ", ref, "]",
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

-- Registers the plant compendium as an inventory tab
sfinv.register_page("magnify:compendium", {
    title = "Plant Compendium", -- add translations
    get = function(self, player, context)
        if context.species_view == STANDARD_VIEW or context.species_view == TECH_VIEW then
            -- create species/technical view
            local pname = player:get_player_name()
            local ref = get_species_ref(context.species_selected)
            
            local formtable, size = nil, nil

            if context.species_view == STANDARD_VIEW then
                formtable,size = magnify.build_formspec_from_ref(ref, false, true)
            elseif context.species_view == TECH_VIEW then
                formtable,size = get_expanded_species_formspec(ref)
            end

            if not formtable then
                formtable = "label[0,0;Uh oh, something went wrong...]button[0,0.5;5,0.6;back;Back]" -- fallback
            end

            return sfinv.make_formspec(player, context, formtable, false, size)
        else
            -- create menu
            local species = table.concat(magnify.get_all_registered_species(), ",")
            local formtable = {
                "bgcolor[#00FF00;true]", -- #172e1b
                "textlist[0,0;7.8,3.75;species_list;", species, ";", context.species_selected or 1, ";false]",
                "button[0,4.05;4,0.6;standard_view;View Species]",
                "button[4,4.05;4,0.6;technical_view;View Technical Info]"
            }
            return sfinv.make_formspec(player, context, table.concat(formtable, ""), true)
        end
    end,
    on_enter = function(self, player, context)
        if context.species_view == nil then
            context.species_view = MENU
        end
        if context.species_selected == nil then
            context.species_selected = 1
        end
    end,
    on_player_receive_fields = function(self, player, context, fields)
        if fields.species_list then
            local event = minetest.explode_textlist_event(fields.species_list)
            if event.type == "CHG" then
                context.species_selected = event.index
            end
        elseif fields.standard_view or fields.technical_view then
            if context.species_selected then
                local pname = player:get_player_name()
                local ref = get_species_ref(context.species_selected)
                
                if magnify.get_species_from_ref(ref) then
                    if fields.standard_view then -- standard
                        context.species_view = STANDARD_VIEW
                    else -- technical
                        context.species_view = TECH_VIEW
                    end
                else
                    minetest.chat_send_player(pname, "An entry for this species exists, but could not be found in the plant database.\nPlease contact an administrator and ask them to check your server's plant database files to ensure all plants were registered properly.")
                end

                -- refresh inventory formspec
                sfinv.set_player_inventory_formspec(player)
            end
        elseif fields.back then
            context.species_view = MENU
            -- refresh inventory formspec
            sfinv.set_player_inventory_formspec(player)
        elseif fields.locate then
            local ref = get_species_ref(context.species_selected)
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
})
