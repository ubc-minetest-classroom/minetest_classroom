local bit = dofile(minetest.get_modpath("mc_core") .. "/numberlua.lua")

-- Register the punch, dig, and place callbacks
minetest.register_on_punchnode(function(pos, node, player, pointed_thing)
    local pname = player:get_player_name()
    if mc_tutorial.record.active[pname] == "record" or mc_tutorial.active[pname] then
        local func
        if mc_tutorial.record.active[pname] == "record" then
            func = mc_tutorial.register_tutorial_action
        elseif mc_tutorial.active[pname] then
            func = mc_tutorial.check_tutorial_progress
        end
        func(player, mc_tutorial.ACTION.PUNCH, {tool = player:get_wielded_item():get_name(), node = node.name})
    end
end)

minetest.register_on_dignode(function(pos, oldnode, player)
    local pname = player:get_player_name()
    if mc_tutorial.record.active[pname] == "record"  or mc_tutorial.active[pname] then
        local func
        if mc_tutorial.record.active[pname] == "record"  then
            func = mc_tutorial.register_tutorial_action
        elseif mc_tutorial.active[pname] then
            func = mc_tutorial.check_tutorial_progress
        end
        local tool_stack = player:get_wielded_item()
        local node_stack_def = ItemStack(oldnode):get_definition()
        func(player, mc_tutorial.ACTION.DIG, {
            tool = (tool_stack:get_name() ~= node_stack_def.drop or tool_stack:get_count() >= 2) and tool_stack:get_name() or "",
            node = oldnode.name
        })
    end
end)

minetest.register_on_placenode(function(pos, newnode, player, oldnode, itemstack, pointed_thing)
    if player then
        local pname = player:get_player_name()
        if mc_tutorial.record.active[pname] == "record"  or mc_tutorial.active[pname] then
            local func
            if mc_tutorial.record.active[pname] == "record"  then
                func = mc_tutorial.register_tutorial_action
            elseif mc_tutorial.active[pname] then
                func = mc_tutorial.check_tutorial_progress
            end
            func(player, mc_tutorial.ACTION.PLACE, {node = newnode.name})
        end
    end
end)

-- Listener for wield and player control (key strike)
minetest.register_globalstep(function(dtime)
    if mc_tutorial and next(mc_tutorial.record.active) and (next(mc_tutorial.record.listener.wield) or next(mc_tutorial.record.listener.key)) then
        for pname,_ in pairs(mc_tutorial.record.active) do
            local reset_timer = false
            local timer = (mc_tutorial.record.timer[pname] or 0) + dtime
            local player = minetest.get_player_by_name(pname)

            -- Listen for wield_item
            if timer > 5 and mc_tutorial.record.listener.wield[pname] then
                reset_timer = true
                local wield = player:get_wielded_item():get_name()

                if wield ~= "mc_tutorial:recording_tool" then
                    minetest.chat_send_player(pname, "[Tutorial] Wielded item "..wield.." recorded.")
                    mc_tutorial.register_tutorial_action(player, mc_tutorial.ACTION.WIELD, {tool = wield})
                    mc_tutorial.record.listener.wield[pname] = nil
                end
            end

            -- Listen for keystroke, if triggered
            if timer > 1 and mc_tutorial.record.listener.key[pname] == "track" then
                reset_timer = true
                local key_bits = player:get_player_control_bits()

                if bit.band(0x27F, key_bits) > 0 then
                    local keys = mc_tutorial.bits_to_keys(key_bits)
                    local msg = "[Tutorial] Keystroke "..table.concat(keys, " + ").." recorded."
                    minetest.chat_send_player(pname, msg)
                    mc_tutorial.register_tutorial_action(player, mc_tutorial.ACTION.KEY, {key_bit = bit.band(0x27F, key_bits)})
                    mc_tutorial.record.listener.key[pname] = nil
                end
            end

            -- Start keystroke timer
            if mc_tutorial.record.listener.key[pname] == true then
                local key_bits = player:get_player_control_bits()
                if bit.band(0x27F, key_bits) > 0 then
                    minetest.chat_send_player(pname, "[Tutorial] Recording keystroke, please continue to hold the player control keys you would like to record.")
                    mc_tutorial.record.listener.key[pname] = "track"
                    reset_timer = true
                end
            end

            mc_tutorial.record.timer[pname] = (reset_timer and 0) or timer
        end
    end
end)
