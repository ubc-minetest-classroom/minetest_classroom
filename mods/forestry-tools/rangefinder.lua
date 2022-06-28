local range = 32
local RAY_RANGE = 500
local MODES = {
    {key = "HT", desc = "height"},
    {key = "SD", desc = "slope dist."},
    {key = "VD", desc = "vertical dist."},
    {key = "HD", desc = "horizontal dist."},
    {key = "INC", desc = "inclination"},
    {key = "AZ", desc = "azimuth"},
    {key = "ML", desc = "missing line"}
}

forestry_tools.rangefinder = {hud = {}}
local hud = mhud.init()

local function track_raycast_hit(player, itemstack)
    local player_pos = vector.offset(player:get_pos(), 0, player:get_properties().eye_height, 0)
    local ray = minetest.raycast(player_pos, vector.add(player_pos, vector.multiply(player:get_look_dir(), RAY_RANGE)))
    local cast_point, first_hit = ray:next(), ray:next()

    if not first_hit then
        return minetest.chat_send_player(player:get_player_name(), "No objects detected within range, cast not logged")
    end

    local meta = itemstack:get_meta()
    if meta then
        -- log hit in rangefinder
        local cast_table = minetest.deserialize(meta:get("casts") or minetest.serialize({}))
        local mark_table = minetest.deserialize(meta:get("marks") or minetest.serialize({}))
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

        -- debug
        minetest.log(dist)
        minetest.log(minetest.serialize(cast_table))
        minetest.log(minetest.serialize(mark_table))
    end

    return itemstack
end

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

--- Creates a HUD text element which displays the rangefinder's current mode
local function mode_hud_text_abstract(player, oper, elem, text, pos_offset, col, size, style)
    local def = {
        hud_elem_type = "text",
        position = {x = 0.08 + (pos_offset and pos_offset.x or 0), y = 0.91 + (pos_offset and pos_offset.y or 0)},
        alignment = {x = 0, y = -1},
        color = col or 0xFFFFFF,
        scale = {x = 200, y = 100},
        text = text or "",
        text_scale = size or 1,
        style = style or 0
    }
    if oper == "add" then
        hud:add(player, elem, def)
    elseif oper == "change" then
        hud:change(player, elem, def)
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
        if not hud:get(player, "forestry_tools:rf:mode") then
            mode_hud_text_abstract(player, "add", "forestry_tools:rf:mode", MODES[mode_num]["key"], nil, nil, 4, 1)
            mode_hud_text_abstract(player, "add", "forestry_tools:rf:mode_desc", MODES[mode_num]["desc"], {y = 0.03}, nil, 2, 0)
            mode_hud_text_abstract(player, "add", "forestry_tools:rf:mode_prev", MODES[mode_surround.prev]["key"], {y = -0.085}, 0xbbbbbb, 2, 0)
            mode_hud_text_abstract(player, "add", "forestry_tools:rf:mode_next", MODES[mode_surround.next]["key"], {y = 0.08}, 0xbbbbbb, 2, 0)
        else
            mode_hud_text_abstract(player, "change", "forestry_tools:rf:mode", MODES[mode_num]["key"], nil, nil, 4, 1)
            mode_hud_text_abstract(player, "change", "forestry_tools:rf:mode_desc", MODES[mode_num]["desc"], {y = 0.03}, nil, 2, 0)
            mode_hud_text_abstract(player, "change", "forestry_tools:rf:mode_prev", MODES[mode_surround.prev]["key"], {y = -0.085}, 0xbbbbbb, 2, 0)
            mode_hud_text_abstract(player, "change", "forestry_tools:rf:mode_next", MODES[mode_surround.next]["key"], {y = 0.08}, 0xbbbbbb, 2, 0)
        end
    end
end

local function show_zoom_hud(player)
    if not hud:get(player, "forestry_tools:rf:overlay") then
        hud:add(player, "forestry_tools:rf:overlay", {
            hud_elem_type = "image",
            position = {x=0.5, y=0.5},
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

-- have to add register node(?) or tool(?) as well as laser between rangefinder obj and point of interest 

-- local function show_rangefinder(player)
-- 	if check_perm(player) then
-- 		local pname = player:get_player_name()
-- 		return true
-- 	end
-- end

local rangefinder_mode_switch = function(itemstack, player, pointed_thing)
    local meta = itemstack:get_meta()
    local current_mode = meta:get("mode") or 1
    local new_mode = (current_mode + 1 <= #MODES and current_mode + 1) or 1
    meta:set_int("mode", new_mode)
    clear_saved_casts(player, itemstack)
    --minetest.chat_send_player(player:get_player_name(), "Rangefinder mode set to "..MODES[new_mode]["key"].." ("..MODES[new_mode]["desc"]..")")
    return itemstack
end

minetest.register_tool("forestry_tools:rangefinder" , {
 	description = "Rangefinder",
 	inventory_image = "rangefinder.jpg",
 	-- Left-click the tool activate function
 	on_use = function(itemstack, player, pointed_thing)
        local pname = player:get_player_name()
 		-- Check for shout privileges
 		if check_perm(player) then
            local new_stack = track_raycast_hit(player, itemstack)
 			--show_rangefinder(player)

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

minetest.register_globalstep(function(dtime)
    local online_players = minetest.get_connected_players()
    for _,player in pairs(online_players) do
        local wield = player:get_wielded_item()
        if wield:get_name() == "forestry_tools:rangefinder" then
            update_rangefinder_hud(player, wield)

            local keys = player:get_player_control()
            if keys.zoom then
                show_zoom_hud(player)
            else
                hide_zoom_hud(player)
            end
        else
            hud:remove(player)
        end
    end
end)

minetest.register_alias("rangefinder", "forestry_tools:rangefinder")
minetest.register_alias("forestry_tools:rf", "forestry_tools:rangefinder")

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




