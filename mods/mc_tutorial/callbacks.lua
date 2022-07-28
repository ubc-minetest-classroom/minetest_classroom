-- Register the punch, dig, and place callbacks
minetest.register_on_punchnode(function(pos, node, player, pointed_thing)
    local pname = player:get_player_name()
    if mc_tutorial.record.active[pname] or mc_tutorial.active[pname] then
        local func
        if mc_tutorial.record.active[pname] then
            func = mc_tutorial.register_tutorial_action
        elseif mc_tutorial.active[pname] then
            func = mc_tutorial.check_tutorial_progress
        end
        func(player, mc_tutorial.ACTION.PUNCH, {tool = player:get_wielded_item():get_name(), node = node.name})
    end
end)

minetest.register_on_dignode(function(pos, oldnode, player)
    local pname = player:get_player_name()
    if mc_tutorial.record.active[pname] or mc_tutorial.active[pname] then
        local func
        if mc_tutorial.record.active[pname] then
            func = mc_tutorial.register_tutorial_action
        elseif mc_tutorial.active[pname] then
            func = mc_tutorial.check_tutorial_progress
        end
        func(player, mc_tutorial.ACTION.DIG, {tool = player:get_wielded_item():get_name(), node = oldnode.name})
    end
end)

minetest.register_on_placenode(function(pos, newnode, player, oldnode, itemstack, pointed_thing)
    local pname = player:get_player_name()
    if mc_tutorial.record.active[pname] or mc_tutorial.active[pname] then
        local func
        if mc_tutorial.record.active[pname] then
            func = mc_tutorial.register_tutorial_action
        elseif mc_tutorial.active[pname] then
            func = mc_tutorial.check_tutorial_progress
        end
        func(player, mc_tutorial.ACTION.PLACE, {tool = player:get_wielded_item():get_name(), node = newnode.name})
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
                local key_control = player:get_player_control()
    
                if key_control.up or key_control.down or key_control.right or key_control.left or key_control.aux1 or key_control.jump or key_control.sneak then
                    local keys = {}
                    for k,v in pairs(key_control) do
                        if v then table.insert(keys, k) end
                    end
                    local msg = "[Tutorial] Keystroke "..table.concat(keys, " + ").." recorded."
                    minetest.chat_send_player(pname, msg)
                    mc_tutorial.register_tutorial_action(player, mc_tutorial.ACTION.KEY, {key = keys})
                    mc_tutorial.record.listener.key[pname] = nil
                end
            end

            -- Start keystroke timer
            if mc_tutorial.record.listener.key[pname] == true then
                local key_control = player:get_player_control()
                if key_control.up or key_control.down or key_control.right or key_control.left or key_control.aux1 or key_control.jump or key_control.sneak then
                    minetest.chat_send_player(pname, "[Tutorial] Recording keystroke, please continue to hold the player control keys you would like to record.")
                    mc_tutorial.record.listener.key[pname] = "track"
                    reset_timer = true
                end
            end

            mc_tutorial.record.timer[pname] = (reset_timer and 0) or timer
        end
    end
end)
