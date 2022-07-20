-- Register the punch, dig, and place callbacks
minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing) 
    local pname = puncher:get_player_name()
    local action = "punch"
    -- Detect if player is wielding a tool for punch
    local tool = puncher:get_wielded_item():get_name()
    local node = node.name
    local pos = {}
    local dir = -1
    local key = {}
    mc_tutorial.register_tutorial_action(puncher,action,tool,node,pos,dir,key)
    mc_tutorial.check_tutorial_progress(puncher,action,tool,node)
end)

minetest.register_on_dignode(function(pos, oldnode, digger)
    local pname = digger:get_player_name()
    local action = "dig"
    -- Detect if player is wielding a tool for dig
    local tool = digger:get_wielded_item():get_name()
    local node = oldnode.name
    local pos = {}
    local dir = -1
    local key = {}
    mc_tutorial.register_tutorial_action(digger,action,tool,node,pos,dir,key)
    mc_tutorial.check_tutorial_progress(digger,action,tool,node)
end)

minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
    local pname = placer:get_player_name()
    local action = "place"
    -- Detect if player is wielding a tool for place
    local tool = placer:get_wielded_item():get_name()
    local node = newnode.name
    local pos = {}
    local dir = -1
    local key = {}
    mc_tutorial.register_tutorial_action(placer,action,tool,node,pos,dir,key)
    mc_tutorial.check_tutorial_progress(placer,action,tool,node)
end)

-- Listener for wield and player control (key strike)
minetest.register_globalstep(function(dtime)
    if mc_tutorial and next(mc_tutorial.record.active) and (next(mc_tutorial.record.listener.wield) or next(mc_tutorial.record.listener.key)) then
        for pname,_ in pairs(mc_tutorial.record.active) do
            local reset_timer = false
            local timer = (mc_tutorial.record.timer[pname] or 0) + dtime
            local player = minetest.get_player_by_name(pname)

            -- Listen for wieldedThing
            if timer > 5 and mc_tutorial.record.listener.wield[pname] then
                reset_timer = true
                local wieldedThing = player:get_wielded_item():get_name()

                if wieldedThing ~= "mc_tutorial:recording_tool" then
                    -- This is needed because no wielded item is an empty string, which conflcits with the default value of tutorialSequence.node
                    if wieldedThing == "" then
                        wieldedThing = "bare hands"
                    end 
                    minetest.chat_send_player(pname, "[Tutorial] Wielded item "..wieldedThing.." recorded.")
                    table.insert(mc_tutorial.record.temp[pname].tutorialSequence.action, "wield")
                    table.insert(mc_tutorial.record.temp[pname].tutorialSequence.tool, "")
                    table.insert(mc_tutorial.record.temp[pname].tutorialSequence.node, wieldedThing)
                    table.insert(mc_tutorial.record.temp[pname].tutorialSequence.pos, {})
                    table.insert(mc_tutorial.record.temp[pname].tutorialSequence.dir, -1)
                    table.insert(mc_tutorial.record.temp[pname].tutorialSequence.key, {})
                    mc_tutorial.record.temp[pname].length = mc_tutorial.record.temp[pname].length + 1
                    mc_tutorial.record.listener.wield[pname] = nil
                end
            end

            -- Listen for keystroke, if triggered
            if timer > 1 and mc_tutorial.record.listener.key[pname] == "track" then
                reset_timer = true
                local keyStrike = player:get_player_control()
    
                if keyStrike.up or keyStrike.down or keyStrike.right or keyStrike.left or keyStrike.aux1 or keyStrike.jump or keyStrike.sneak then
                    mc_tutorial.record.temp[pname].keys = {}
                    for k,v in pairs(keyStrike) do
                        if v then table.insert(mc_tutorial.record.temp[pname].keys, k) end
                    end
                    --minetest.chat_send_all(tostring(_G.dump(keys)))
                    local msg = "[Tutorial] Keystroke "..table.concat(mc_tutorial.record.temp[pname].keys, " + ").." recorded."
                    --for _,v in pairs(mc_tutorial.record.temp[pname].keys) do msg = msg .. v .. " " end
                    --local msg = msg .. "was recorded."
                    minetest.chat_send_player(pname, msg)
                    table.insert(mc_tutorial.record.temp[pname].tutorialSequence.action, "player control")
                    table.insert(mc_tutorial.record.temp[pname].tutorialSequence.tool, "")
                    table.insert(mc_tutorial.record.temp[pname].tutorialSequence.node, "")
                    table.insert(mc_tutorial.record.temp[pname].tutorialSequence.pos, {})
                    table.insert(mc_tutorial.record.temp[pname].tutorialSequence.dir, -1)
                    table.insert(mc_tutorial.record.temp[pname].tutorialSequence.key, mc_tutorial.record.temp[pname].keys)
                    mc_tutorial.record.temp[pname].length = mc_tutorial.record.temp[pname].length + 1
                    mc_tutorial.record.listener.key[pname] = nil
                end
            end

            -- Start keystroke timer
            if mc_tutorial.record.listener.key[pname] == true and player:get_player_control_bits() ~= 0 then
                minetest.chat_send_player(pname, "[Tutorial] Recording keystroke, please continue to hold the player control keys.")
                mc_tutorial.record.listener.key[pname] = "track"
                reset_timer = true
            end

            mc_tutorial.record.timer[pname] = (reset_timer and 0) or timer
        end
    end
end)