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
    tutorial.register_tutorial_action(puncher,action,tool,node,pos,dir,key)
    tutorial.check_tutorial_progress(puncher,action,tool,node)
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
    tutorial.register_tutorial_action(digger,action,tool,node,pos,dir,key)
    tutorial.check_tutorial_progress(digger,action,tool,node)
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
    tutorial.register_tutorial_action(placer,action,tool,node,pos,dir,key)
    tutorial.check_tutorial_progress(placer,action,tool,node)
end)

-- Listener for wield and player control (key strike)
local timer = 0 
minetest.register_globalstep(function(dtime)
    local reset_timer = false
    timer = timer + dtime

    -- Listen for wieldedThing
    if tutorial and #tutorial.record.active > 0 then
        if timer > 5 then
            reset_timer = true
            for pname,_ in pairs(tutorial.record.active) do
                if tutorial.record.listener.wield[pname] then
                    local player = minetest.get_player_by_name(pname)
                    local wieldedThing = player:get_wielded_item():get_name()

                    if wieldedThing ~= "tutorial:recording_tool" then
                        -- This is needed because no wielded item is an empty string, which conflcits with the default value of tutorialSequence.node
                        if wieldedThing == "" then
                            wieldedThing = "bare hands"
                        end 
                        minetest.chat_send_player(pname, "[Tutorial] Wielded item "..wieldedThing.." was recorded.")
                        table.insert(tutorial.record.temp[pname].tutorialSequence.action, "wield")
                        table.insert(tutorial.record.temp[pname].tutorialSequence.tool, "")
                        table.insert(tutorial.record.temp[pname].tutorialSequence.node, wieldedThing)
                        table.insert(tutorial.record.temp[pname].tutorialSequence.pos, {})
                        table.insert(tutorial.record.temp[pname].tutorialSequence.dir, -1)
                        table.insert(tutorial.record.temp[pname].tutorialSequence.key, {})
                        tutorial.record.temp[pname].length = tutorial.record.temp[pname].length + 1
                        tutorial.record.listener.wield[pname] = nil
                    end
                end
            end
        end

        -- Listen for keyStrike
        if timer > 1 then
            reset_timer = true

            for pname,_ in pairs(tutorial.record.active) do
                if tutorial.record.listener.key[pname] then
                    minetest.chat_send_player(pname, tostring(os.clock()).."[Tutorial] Listening for keystrike, press a player control key now.")
                    local player = minetest.get_player_by_name(pname)
                    local keyStrike = player:get_player_control()

                    if keyStrike.up or keyStrike.down or keyStrike.right or keyStrike.left or keyStrike.aux1 or keyStrike.jump or keyStrike.sneak then
                        tutorial.record.temp[pname].keys = {}
                        for k,v in pairs(keyStrike) do
                            if v then table.insert(tutorial.record.temp[pname].keys, k) end
                        end
                        --minetest.chat_send_all(tostring(_G.dump(keys)))
                        local msg = "[Tutorial] Key strike "..table.concat(tutorial.record.temp[pname].keys, " + ").." was recorded."
                        --for _,v in pairs(tutorial.record.temp[pname].keys) do msg = msg .. v .. " " end
                        --local msg = msg .. "was recorded."
                        minetest.chat_send_player(pname, msg)
                        table.insert(tutorial.record.temp[pname].tutorialSequence.action, "player control")
                        table.insert(tutorial.record.temp[pname].tutorialSequence.tool, "")
                        table.insert(tutorial.record.temp[pname].tutorialSequence.node, "")
                        table.insert(tutorial.record.temp[pname].tutorialSequence.pos, {})
                        table.insert(tutorial.record.temp[pname].tutorialSequence.dir, -1)
                        table.insert(tutorial.record.temp[pname].tutorialSequence.key, tutorial.record.temp[pname].keys)
                        tutorial.record.temp[pname].length = tutorial.record.temp[pname].length + 1
                        tutorial.record.listener.key[pname] = nil
                    end
                end
            end
        end
    end

    if reset_timer then
        timer = 0
    end
end)