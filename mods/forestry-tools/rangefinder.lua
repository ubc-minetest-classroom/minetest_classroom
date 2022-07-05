--[[ TODO
-- Add random chance for noise/skipping when raycast hits nodes with:
  -- node group: leaves
  -- drawtype: plantlike, plantlike_rooted
-- Determine calculation algorithms
-- Add calculation/cast outputs to HUD instead of chat
-- Auto-reset?
]]

local range = 32
local RAY_RANGE = 500
local MODES = {
    [1] = {key = "HT",  casts = 3, unit = "m", desc = "height"},
    [2] = {key = "SD",  casts = 1, unit = "m", desc = "slope dist."},
    [3] = {key = "VD",  casts = 1, unit = "m", desc = "vertical dist."},
    [4] = {key = "HD",  casts = 1, unit = "m", desc = "horizontal dist."},
    [5] = {key = "INC", casts = 1, unit = "%", desc = "inclination"},
    [6] = {key = "AZ",  casts = 1, unit = "°", desc = "azimuth"},
    [7] = {key = "ML",  casts = 2, unit = "m", desc = "missing line"}
}
local MODE_POS = {x = 0.075, y = 0.8855}

local tool_name = "forestry_tools:rangefinder"

forestry_tools.rangefinder = {hud = {}}
local hud = mhud.init()

-- Gets the internal index number for the rangefinder's current mode
local function get_mode(meta)
    return tonumber(meta:get("mode") or 1)
end

-- Clears all the logged casts from the rangefinder's metadata
local function clear_saved_casts(player, itemstack)
    local meta = itemstack:get_meta()
    local count = 0
    meta:set_string("casts", "")
    local mark_table = minetest.deserialize(meta:get("marks") or minetest.serialize({}))
    for i,id in pairs(mark_table) do
        if hud:get(player, id) then
            hud:remove(player, id)
        end
        count = count + 1
    end
    meta:set_string("marks", "")

    if count > 0 then
        minetest.chat_send_player(player:get_player_name(), "Rangefinder reset, ready to start new measurement")
    end
    return itemstack
end

-- Casts a ray and logs where it first hit, if it hit an object/node in range
local function track_raycast_hit(player, itemstack)
    local meta = itemstack:get_meta()
    if meta then
        -- log hit in rangefinder
        local cast_table = minetest.deserialize(meta:get("casts") or minetest.serialize({}))
        local mark_table = minetest.deserialize(meta:get("marks") or minetest.serialize({}))
        local mode = get_mode(meta)

        if #cast_table >= MODES[mode]["casts"] then
            -- clear hits
            return clear_saved_casts(player, itemstack), nil, nil
        end

        local player_pos = vector.offset(player:get_pos(), 0, player:get_properties().eye_height, 0)
        local ray = minetest.raycast(player_pos, vector.add(player_pos, vector.multiply(player:get_look_dir(), RAY_RANGE)))
        local cast_point, first_hit = ray:next(), ray:next()

        if not first_hit then
            -- no objects/nodes within range, note failed hit
            minetest.chat_send_player(player:get_player_name(), "No objects detected within a 500m range, measurement not tracked")
            return itemstack, nil, nil
        end

        local dir = vector.direction(cast_point.intersection_point, first_hit.intersection_point)
        local dist = vector.distance(cast_point.intersection_point, first_hit.intersection_point)
        table.insert(cast_table, {dir = dir, dist = dist, pos = first_hit.intersection_point})
        meta:set_string("casts", minetest.serialize(cast_table))

        -- display hit on screen + log ID in rangefinder
        table.insert(mark_table, hud:add(player, nil, {
            hud_elem_type = "image_waypoint",
            world_pos = first_hit.intersection_point,
            text = (mode == 1 and #mark_table ~= 0) and "forestry_tools_rf_anglemarker.png" or "forestry_tools_rf_marker.png",
            scale = {x = 1.5, y = 1.5},
            z_index = (mode == 1 and #mark_table ~= 0) and -301 or -300,
            alignment = {x = 0, y = 0}
        }))
        meta:set_string("marks", minetest.serialize(mark_table))

        local table_length = math.min(#cast_table, #mark_table)
        local casts_reached = table_length >= MODES[mode]["casts"]
        return itemstack, table_length, casts_reached
    end
end

--- Creates a HUD text element for the rangefinder's mode display
local function mode_hud_text_abstract(player, oper, elem, text, pos_offset, col, size, style)
    local def = {
        hud_elem_type = "text",
        position = {x = MODE_POS.x + (pos_offset and pos_offset.x or 0), y = MODE_POS.y + (pos_offset and pos_offset.y or 0)},
        alignment = {x = 0, y = 0},
        offset = {x = 5, y = -5},
        color = col or 0xFFFFFF,
        scale = {x = 200, y = 100},
        text = text or "",
        text_scale = size or 1,
        style = style or 0,
        z_index = 1,
    }
    if oper == "add" then
        hud:add(player, elem, def)
    elseif oper == "change" then
        hud:change(player, elem, def)
    end
end

-- Creates the background for the rangefinder's mode display
local function create_mode_hud_background(player, oper)
    if not hud:get(player, tool_name..":mode_bg") then
        hud:add(player, tool_name..":mode_bg", {
            hud_elem_type = "image",
            position = {x = MODE_POS.x, y = MODE_POS.y},
            alignment = {x = 0, y = 0},
            offset = {x = 5, y = -5},
            scale = {x = -15, y = -12.7},
            text = "forestry_tools_rf_bg.png",
            z_index = -2,
        })
        hud:add(player, tool_name..":mode_bg_upper", {
            hud_elem_type = "image",
            position = {x = MODE_POS.x, y = MODE_POS.y - 0.09},
            alignment = {x = 0, y = 0},
            offset = {x = 5, y = -5},
            scale = {x = -5, y = -4.7},
            text = "forestry_tools_rf_bg_alt.png",
            z_index = -3,
        })
        hud:add(player, tool_name..":mode_bg_lower", {
            hud_elem_type = "image",
            position = {x = MODE_POS.x, y = MODE_POS.y + 0.09},
            alignment = {x = 0, y = 0},
            offset = {x = 5, y = -5},
            scale = {x = -5, y = -4.7},
            text = "forestry_tools_rf_bg_alt.png",
            z_index = -3,
        })
    end
end

-- Creates the arrows indicating the current mode change direction for the rangefinder's mode display
local function update_mode_hud_arrows(player, keys)
    local arrow_u = {
        hud_elem_type = "image",
        position = {x = MODE_POS.x, y = MODE_POS.y - 0.063},
        alignment = {x = 0, y = 0},
        offset = {x = 5, y = -5},
        scale = (keys.aux1 and {x = -0.75, y = -0.75}) or {x = -1.25, y = -1.25},
        text = (keys.aux1 and "forestry_tools_rf_arrow_up.png") or "forestry_tools_rf_arrow_down.png",
        z_index = -1,
    }
    local arrow_l = {
        hud_elem_type = "image",
        position = {x = MODE_POS.x, y = MODE_POS.y + 0.063},
        alignment = {x = 0, y = 0},
        offset = {x = 5, y = -5},
        scale = (keys.aux1 and {x = -1.25, y = -1.25}) or {x = -0.75, y = -0.75},
        text = (keys.aux1 and "forestry_tools_rf_arrow_up.png") or "forestry_tools_rf_arrow_down.png",
        z_index = -1,
    }

    if not hud:get(player, tool_name..":mode_arrow_u") then
        hud:add(player, tool_name..":mode_arrow_u", arrow_u)
        hud:add(player, tool_name..":mode_arrow_l", arrow_l)
    else
        hud:change(player, tool_name..":mode_arrow_u", arrow_u)
        hud:change(player, tool_name..":mode_arrow_l", arrow_l)
    end
end

-- Updates the rangefinder's mode display
local function update_rf_mode_hud(player, itemstack)
    local meta = itemstack:get_meta()
    if meta then
        local mode_num = meta:contains("mode") and meta:get_int("mode") or 1
        local mode_surround = {
            next = (mode_num + 1 <= #MODES and mode_num + 1) or 1,
            prev = (mode_num - 1 >= 1 and mode_num - 1) or #MODES
        }
        local mode_hud_exists = hud:get(player, tool_name..":mode")
        mode_hud_text_abstract(player, (mode_hud_exists and "change") or "add", tool_name..":mode", MODES[mode_num]["key"], {y = -0.02}, nil, 4, 1)
        mode_hud_text_abstract(player, (mode_hud_exists and "change") or "add", tool_name..":mode_desc", MODES[mode_num]["desc"], {y = 0.0325}, nil, 2, 0)
        mode_hud_text_abstract(player, (mode_hud_exists and "change") or "add", tool_name..":mode_prev", MODES[mode_surround.prev]["key"], {y = 0.09}, 0xd0d0d0, 2, 0)
        mode_hud_text_abstract(player, (mode_hud_exists and "change") or "add", tool_name..":mode_next", MODES[mode_surround.next]["key"], {y = -0.09}, 0xd0d0d0, 2, 0)
        create_mode_hud_background(player)
    end
end

-- Shows the rangefinder's zooming crosshair
local function show_zoom_hud(player)
    if not hud:get(player, tool_name..":overlay") then
        hud:add(player, tool_name..":overlay", {
            hud_elem_type = "image",
            position = {x = 0.5, y = 0.5},
            text = "forestry_tools_rf_overlay.png",
            scale = {x = -60, y = -60},
            z_index = -100,
            alignment = {x = 0, y = 0}
        })
    end
end

-- Hides the rangefinder's zooming crosshair
local function hide_zoom_hud(player)
    if hud:get(player, tool_name..":overlay") then
        hud:remove(player, tool_name..":overlay")
    end
end

-- Rounds num to the given number of decimal places
local function round_to_decim_places(num, places, as_string)
    local factor = 10^places
    local round_num = math.round(num * factor)
    if not as_string then
        return round_num / factor
    else
        local num_string = tostring(round_num)
        local whole = string.sub(num_string, 1, -1 - places)
        local decim = string.sub(num_string, -places)
        return decim ~= "" and (whole ~= "" and whole or "0").."."..decim or (whole ~= "" and whole or "0")
    end
end

-- Calculates the final output for the rangefinder to display
local function rangefinder_calc(meta)
    local casts = minetest.deserialize(meta:get_string("casts"))
    local mode = get_mode(meta)
    if not casts or #casts < MODES[mode]["casts"] then
        return nil
    end

    local calculation_table = {
        [1] = function() -- HT
            local gamma = vector.angle(casts[1]["dir"], vector.new(casts[1]["dir"]["x"], 0, casts[1]["dir"]["z"]))
            local alpha = vector.angle(casts[2]["dir"], vector.new(casts[2]["dir"]["x"], 0, casts[2]["dir"]["z"]))
            local beta = vector.angle(casts[3]["dir"], vector.new(casts[3]["dir"]["x"], 0, casts[3]["dir"]["z"]))

            local gamma_dist = casts[1]["dist"]
            local horiz_dist = gamma_dist * math.cos(gamma)
            local alpha_dist = horiz_dist / math.cos(alpha)
            local beta_dist = horiz_dist / math.cos(beta)

            local theta
            if math.sign(casts[2]["dir"]["y"]) == math.sign(casts[3]["dir"]["y"]) then
                theta = math.abs(alpha - beta)
            else
                theta = math.abs(alpha + beta)
            end
            return math.sqrt(alpha_dist^2 + beta_dist^2 - 2*alpha_dist*beta_dist*math.cos(theta))
        end,
        [2] = function() -- SD
            return mode
        end,
        [3] = function() -- VD
            return mode
        end,
        [4] = function() -- HD
            return mode
        end,
        [5] = function() -- INC
            return mode
        end,
        [6] = function() -- AZ
            return mode
        end,
        [7] = function() -- ML
            return mode
        end
    }
    return calculation_table[mode]()
end

-- Changes the rangefinder's mode
local function rangefinder_mode_switch(itemstack, player, pointed_thing)
    local meta = itemstack:get_meta()
    local current_mode = get_mode(meta)
    local keys = player:get_player_control()
    local new_mode = nil

    if keys.aux1 then -- cycle mode backwards
        new_mode = (current_mode - 1 >= 1 and current_mode - 1) or #MODES
    else -- cycle mode forwards
        new_mode = (current_mode + 1 <= #MODES and current_mode + 1) or 1
    end
    meta:set_int("mode", new_mode)
    
    update_rf_mode_hud(player, itemstack)
    if MODES[current_mode]["casts"] ~= MODES[new_mode]["casts"] then
        clear_saved_casts(player, itemstack)
    else
        local result = rangefinder_calc(meta)
        if result then
            local round_res = round_to_decim_places(result, 1, true)
            minetest.chat_send_player(player:get_player_name(), "Measurement for new mode: "..round_res..MODES[new_mode]["unit"])
        end
    end
    return itemstack
end

minetest.register_tool(tool_name , {
 	description = "Rangefinder",
 	inventory_image = "rangefinder.jpg",
    _mc_tool_privs = { interact = true },
 	-- Left-click the tool activate function
 	on_use = function(itemstack, player, pointed_thing)
        local pname = player:get_player_name()
 		-- Check for shout privileges
 		if check_perm(player) then
            local new_stack, cast_num, cast_complete = track_raycast_hit(player, itemstack)
            if new_stack then
                local meta = new_stack:get_meta()
                -- log cast distance
                if cast_num then
                    local casts = minetest.deserialize(meta:get_string("casts"))
                    if casts[cast_num] then
                        local cast_dist = round_to_decim_places(casts[cast_num]["dist"], 1, true)
                        minetest.chat_send_player(pname, "Cast "..cast_num.." logged - distance: "..cast_dist.."m")
                    end
                end
                -- perform and log calculation
                if cast_complete then
                    local result = rangefinder_calc(meta)
                    local mode = get_mode(meta)
                    if result then
                        local round_res = round_to_decim_places(result, 1, true)
                        minetest.chat_send_player(pname, "Final measurement: "..round_res..MODES[mode]["unit"])
                    end
                end
            end
            -- Register a node punch
            if pointed_thing.under then
                minetest.node_punch(pointed_thing.under, minetest.get_node(pointed_thing.under), player, pointed_thing)
            end
            return new_stack
 		end
 	end,
    on_secondary_use = rangefinder_mode_switch,
    on_place = rangefinder_mode_switch,
 	on_drop = function(itemstack, dropper, pos)
 	end,
})
minetest.register_alias("rangefinder", tool_name)

minetest.register_globalstep(function(dtime)
    local online_players = minetest.get_connected_players()

    if #online_players == 0 then
        return
    end

    for _,player in pairs(online_players) do
        local wield = player:get_wielded_item()
        if wield:get_name() == tool_name then
            if not hud:get(player, tool_name..":mode") then
                update_rf_mode_hud(player, wield)
            end
            local keys = player:get_player_control()
            if keys.zoom then
                show_zoom_hud(player)
            else
                hide_zoom_hud(player)
            end
            update_mode_hud_arrows(player, keys)
        else
            hud:remove(player)
        end
    end
end)

-- OLD FRAMEWORK

local finder_on = function(pos, facedir_param2, range)
    local meta = minetest.get_meta(pos)
    local block_pos = vector.new(pos)
    local beam_pos = vector.new(pos)
    local beam_direction = minetest.facedir_to_dir(facedir_param2)

    for i = 1, range + 1, 1 do
        beam_pos = vector.add(block_pos, vector.multiply(beam_direction, i))
        if minetest.get_node(beam_pos).name == "air" or minetest.get_node(beam_pos).name == "forestry_tools:rangefinder" then
            if i <= range then
                minetest.set_node(beam_pos, {name = "forestry_tools:rangefinder", param2 = facedir_param2})
                meta:set_string("infotext", "Distance: " .. tostring(i) .. "m")
                meta:set_int("range", i)
            else
                meta:set_string("infotext", "out of range")
                meta:set_int("range", range)
            end
        else
            break
        end
    end
end

local range_off = function(pos, facedir_param2, range)
    local meta = minetest.get_meta(pos)
    local block_pos = vector.new(pos)
    local beam_pos = vector.new(pos)
    local beam_direction = minetest.facedir_to_dir(facedir_param2)

    for i = range, 0, -1 do
        beam_pos = vector.add(block_pos, vector.multiply(beam_direction, i))
        if minetest.get_node(beam_pos).name == "forestry_tools:rangefinder" and minetest.get_node(beam_pos).param2 == facedir_param2 then
            minetest.set_node(beam_pos, {name="air"})
        end
    end
end

local range_check = function(pos, facedir_param2, range)
    local block_pos = vector.new(pos)
    local beam_pos = vector.new(pos)
    local beam_direction = minetest.facedir_to_dir(facedir_param2)
    local is_not_beam = false
    
    for i = 1, range + 1, 1 do
        beam_pos = vector.add(block_pos, vector.multiply(beam_direction, i))
        if minetest.get_node(beam_pos).name ~= "forestry_tools:rangefinder" and i <= range then
            is_not_beam = true
        elseif minetest.get_node(beam_pos).name == "air" and i <= laser_range then
            is_not_beam = true
        end
    end
    return is_not_beam
end

minetest.register_on_joinplayer(function(player)
    -- clear previously saved casts with rangefinder tool
    local inv = player:get_inventory()
    for list,data in pairs(inv:get_lists()) do
        for i,item in pairs(data) do
            if item:get_name() == tool_name then
                clear_saved_casts(player, item)
                inv:set_stack(list, i, item)
            end
        end
    end
end)

-- minetest.register_on_joinplayer(function(player)
--     local inv = player:get_inventory()
--     if inv:contains_item("main", ItemStack("forestry_tools:rangefinder")) then
--         -- Player has the rangefinder
--         if check_perm(player) then
--             -- The player should have the rangefinder
--             return
--         else   
--             -- The player should not have the rangefinder
--             player:get_inventory():remove_item('main', "forestry_tools:rangefinder")
--         end
--     else
--         -- Player does not have the rangefinder
--         if check_perm(player) then
--             -- The player should have the rangefinder
--             player:get_inventory():add_item('main', "forestry_tools:rangefinder")
--         else
--             -- The player should not have the rangefinder
--             return
--         end     
--     end
-- end)
