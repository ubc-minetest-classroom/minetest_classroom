function mc_core.record_coordinates(player, message)
	if mc_core.checkPrivs(player, {interact = true}) then
		local pmeta = player:get_meta()
		local pos = player:get_pos()
		local realmID = pmeta:get_int("realm")
		local temp, clean_message
		clean_message = minetest.formspec_escape(message)
		temp = minetest.deserialize(pmeta:get_string("coordinates")) or {realms = {}, coords = {}, note_map = {}}

		if temp.realms and temp.coords then
            table.insert(temp.realms, realmID)
            table.insert(temp.coords, pos)
        else
            temp.realms = {realmID}
            temp.coords = {pos}
        end
		temp.note_map[clean_message] = #temp.realms

		pmeta:set_string("coordinates", minetest.serialize(temp))
		minetest.chat_send_player(player:get_player_name(), minetest.colorize(mc_core.col.log, "[Minetest Classroom] Your position was recorded in your notebook."))
	end
end

function mc_core.queue_marker(player, message, pos, expiry)
	if player and pos then
		local pname = player:get_player_name()
        local DEFAULT_MARKER_EXPIRY = 30

		if not message then 
			message = "m" 
		else
			message = "m: "..message
		end

		if mc_core.markers[pname] then
			mc_core.markers[pname].timer:cancel()
		end
		mc_core.markers[pname] = {
			timer = minetest.after(expiry or DEFAULT_MARKER_EXPIRY, mc_core.remove_marker, pname),
		}
		mc_core.show_marker(pname, message, pos)
	end
end

function mc_core.show_marker(pname, message, pos)
	if not mc_core.hud:get(pname, pname.."_marker") then 
		mc_core.hud:add(pname, pname.."_marker", {
			hud_elem_type = "waypoint",
			world_pos = pos,
			precision = 1,
			number = mc_core.hex_string_to_num(mc_core.col.marker),
			text = (message or "m"), --.."\n(marked by "..pname..")",
			alignment = {x = 0, y = 0},
			z_order = -300,
		})
	else
		mc_core.hud:change(pname, pname.."_marker", {
			world_pos = pos,
			text = message,
		})
	end
end

function mc_core.remove_marker(pname)
	if mc_core.markers[pname] then
		mc_core.markers[pname].timer:cancel()
		mc_core.markers[pname] = nil
	end
	if mc_core.hud:get(pname, pname.."_marker") then
		mc_core.hud:remove(pname, pname.."_marker")
	end
end

minetest.register_on_joinplayer(function(player)
    local pname = player:get_player_name()
    local pmeta = player:get_meta()
    temp = minetest.deserialize(pmeta:get_string("coordinates"))
    -- old format: convert to newer format
    if temp and temp.notes then
        temp.note_map = {}
        temp.format = 2
        for i,note in pairs(temp.notes) do
            temp.note_map[note] = i
        end
        temp.notes = nil
        pmeta:set_string("coordinates", minetest.serialize(temp))
    end
end)

minetest.register_on_leaveplayer(function(player)
    local pname = player:get_player_name()
	if mc_core.markers[pname] then
		mc_core.markers[pname].timer:cancel()
		mc_core.markers[pname] = nil
	end
end)