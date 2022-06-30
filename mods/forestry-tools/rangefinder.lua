local range = 32
local RAY_RANGE = 500
local MODES = {
    {key = "HT",  lim = 3, desc = "height"},
    {key = "SD",  lim = 2, desc = "slope dist."},
    {key = "VD",  lim = 2, desc = "vertical dist."},
    {key = "HD",  lim = 2, desc = "horizontal dist."},
    {key = "INC", lim = 2, desc = "inclination"},
    {key = "AZ",  lim = 2, desc = "azimuth"},
    {key = "ML",  lim = 2, desc = "missing line"}
}
local MODE_POS = {x = 0.075, y = 0.8855}

forestry_tools.rangefinder = {hud = {}}
local hud = mhud.init()

local function clear_saved_casts(player, itemstack)
    local meta = itemstack:get_meta()
    meta:set_string("casts", "")
    local mark_table = minetest.deserialize(meta:get("marks") or minetest.serialize({}))
    for i,id in pairs(mark_table) do
        if hud:get(player, id) then
            hud:remove(player, id)
        end
    end
    meta:set_string("marks", "")
end

local function track_raycast_hit(player, itemstack)
    local meta = itemstack:get_meta()
    if meta then
        -- log hit in rangefinder
        local cast_table = minetest.deserialize(meta:get("casts") or minetest.serialize({}))
        local mark_table = minetest.deserialize(meta:get("marks") or minetest.serialize({}))

        local mode = tonumber(meta:get("mode") or 1)

        if #cast_table >= MODES[mode]["lim"] then
            -- clear hits
            clear_saved_casts(player, itemstack)
            minetest.chat_send_player(player:get_player_name(), "Rangefinder reset")
            return itemstack
        end

        local player_pos = vector.offset(player:get_pos(), 0, player:get_properties().eye_height, 0)
        local ray = minetest.raycast(player_pos, vector.add(player_pos, vector.multiply(player:get_look_dir(), RAY_RANGE)))
        local cast_point, first_hit = ray:next(), ray:next()

        if not first_hit then
            -- no objects/nodes within range, note failed hit
            minetest.chat_send_player(player:get_player_name(), "No objects detected within range, cast not logged")
            return nil
        end

        local dir = vector.direction(cast_point.intersection_point, first_hit.intersection_point)
        local dist = vector.distance(cast_point.intersection_point, first_hit.intersection_point)
        table.insert(cast_table, {dir = dir, dist = dist})
        meta:set_string("casts", minetest.serialize(cast_table))

        -- display hit on screen + log ID in rangefinder
        table.insert(mark_table, hud:add(player, nil, {
            hud_elem_type = "image_waypoint",
            world_pos = first_hit.intersection_point,
            text = "forestry_tools_rf_marker.png",
            scale = {x = 1.5, y = 1.5},
            z_index = -300,
            alignment = {x = 0, y = 0}
        }))
        meta:set_string("marks", minetest.serialize(mark_table))
    end

    --local 

    return itemstack
end

--- Creates a HUD text element which displays the rangefinder's current mode
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

local function create_mode_hud_background(player, oper)
    if not hud:get(player, "forestry_tools:rf:mode_bg") then
        hud:add(player, "forestry_tools:rf:mode_bg", {
            hud_elem_type = "image",
            position = {x = MODE_POS.x, y = MODE_POS.y},
            alignment = {x = 0, y = 0},
            offset = {x = 5, y = -5},
            scale = {x = -15, y = -12.7},
            text = "forestry_tools_rf_bg.png",
            z_index = -2,
        })
        hud:add(player, "forestry_tools:rf:mode_bg_upper", {
            hud_elem_type = "image",
            position = {x = MODE_POS.x, y = MODE_POS.y - 0.09},
            alignment = {x = 0, y = 0},
            offset = {x = 5, y = -5},
            scale = {x = -5, y = -4.7},
            text = "forestry_tools_rf_bg_alt.png",
            z_index = -3,
        })
        hud:add(player, "forestry_tools:rf:mode_bg_lower", {
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

local function update_mode_hud_arrows(player, keys)
    local arrow_1 = {
        hud_elem_type = "image",
        position = {x = MODE_POS.x, y = MODE_POS.y + 0.063},
        alignment = {x = 0, y = 0},
        offset = {x = 5, y = -5},
        scale = {x = -1, y = -1},
        text = (keys.aux1 and "forestry_tools_rf_arrow_down.png") or "forestry_tools_rf_arrow_up.png",
        z_index = -1,
    }
    local arrow_2 = {
        hud_elem_type = "image",
        position = {x = MODE_POS.x, y = MODE_POS.y - 0.063},
        alignment = {x = 0, y = 0},
        offset = {x = 5, y = -5},
        scale = {x = -1, y = -1},
        text = (keys.aux1 and "forestry_tools_rf_arrow_down.png") or "forestry_tools_rf_arrow_up.png",
        z_index = -1,
    }
    if not hud:get(player, "forestry_tools:rf:mode_arrow_1") then
        hud:add(player, "forestry_tools:rf:mode_arrow_1", arrow_1)
        hud:add(player, "forestry_tools:rf:mode_arrow_2", arrow_2)
    else
        hud:change(player, "forestry_tools:rf:mode_arrow_1", arrow_1)
        hud:change(player, "forestry_tools:rf:mode_arrow_2", arrow_2)
    end
end

local function update_rangefinder_hud(player, itemstack)
    local meta = itemstack:get_meta()
    if meta then
        local mode_num = meta:contains("mode") and meta:get_int("mode") or 1
        local mode_surround = {
            next = (mode_num + 1 <= #MODES and mode_num + 1) or 1,
            prev = (mode_num - 1 >= 1 and mode_num - 1) or #MODES
        }
        local mode_hud_exists = hud:get(player, "forestry_tools:rf:mode")
        mode_hud_text_abstract(player, (mode_hud_exists and "change") or "add", "forestry_tools:rf:mode", MODES[mode_num]["key"], {y = -0.02}, nil, 4, 1)
        mode_hud_text_abstract(player, (mode_hud_exists and "change") or "add", "forestry_tools:rf:mode_desc", MODES[mode_num]["desc"], {y = 0.0325}, nil, 2, 0)
        mode_hud_text_abstract(player, (mode_hud_exists and "change") or "add", "forestry_tools:rf:mode_prev", MODES[mode_surround.prev]["key"], {y = -0.09}, 0xbbbbbb, 2, 0)
        mode_hud_text_abstract(player, (mode_hud_exists and "change") or "add", "forestry_tools:rf:mode_next", MODES[mode_surround.next]["key"], {y = 0.09}, 0xbbbbbb, 2, 0)
        create_mode_hud_background(player)
    end
end

local function show_zoom_hud(player)
    if not hud:get(player, "forestry_tools:rf:overlay") then
        hud:add(player, "forestry_tools:rf:overlay", {
            hud_elem_type = "image",
            position = {x = 0.5, y = 0.5},
            text = "forestry_tools_rf_overlay.png",
            scale = {x = -60, y = -60},
            z_index = -100,
            alignment = {x = 0, y = 0}
        })
    end
end

local function hide_zoom_hud(player)
    if hud:get(player, "forestry_tools:rf:overlay") then
        hud:remove(player, "forestry_tools:rf:overlay")
    end
end

local function rangefinder_mode_switch(itemstack, player, pointed_thing)
    local meta = itemstack:get_meta()
    local current_mode = meta:get("mode") or 1
    local keys = player:get_player_control()
    local new_mode = nil

    if keys.aux1 then -- cycle mode backwards
        new_mode = (current_mode - 1 >= 1 and current_mode - 1) or #MODES
    else -- cycle mode forwards
        new_mode = (current_mode + 1 <= #MODES and current_mode + 1) or 1
    end
    meta:set_int("mode", new_mode)
    
    update_rangefinder_hud(player, itemstack)
    clear_saved_casts(player, itemstack)
    return itemstack
end

minetest.register_tool("forestry_tools:rangefinder" , {
 	description = "Rangefinder",
 	inventory_image = "rangefinder.jpg",
    _mc_tool_privs = { interact = true },
 	-- Left-click the tool activate function
 	on_use = function(itemstack, player, pointed_thing)
        local pname = player:get_player_name()
 		-- Check for shout privileges
 		if check_perm(player) then
            local new_stack = track_raycast_hit(player, itemstack)

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

minetest.register_alias("rangefinder", "forestry_tools:rangefinder")
minetest.register_alias("forestry_tools:rf", "forestry_tools:rangefinder")

minetest.register_globalstep(function(dtime)
    local online_players = minetest.get_connected_players()

    if #online_players == 0 then
        return
    end

    for _,player in pairs(online_players) do
        local wield = player:get_wielded_item()
        if wield:get_name() == "forestry_tools:rangefinder" then
            if not hud:get(player, "forestry_tools:rf:mode") then
                update_rangefinder_hud(player, wield)
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
