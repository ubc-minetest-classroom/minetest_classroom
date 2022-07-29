function mc_tutorial.check_privs(player, priv_table)
    local priv_table = priv_table or {interact = true}
    local name = player:get_player_name()
    return minetest.check_player_privs(name, priv_table)
end

function mc_tutorial.wait(seconds)
    local t = os.clock()
    while os.clock() - t < seconds do end
end

function mc_tutorial.get_temp_shell()
    return {
        dependencies = {}, -- table of tutorial IDs that must be compeleted before the player can attempt this tutorial
        dependents = {}, -- table of tutorial IDs that completing this tutorial unlocks
        sequence = {},
        length = 0,
        on_completion = {
            message = "",
            items = {},
            privs = {}
        },
        format = 3
    }
end

function mc_tutorial.register_tutorial_action(player, action, action_table)
    -- Every entry must have an action and an action table
    if not action or type(action_table) ~= "table" then
        return false
    end
    local pname = player:get_player_name()

    if mc_tutorial.check_privs(player,mc_tutorial.recorder_priv_table) and mc_tutorial.record.active[pname] then
        if not mc_tutorial.record.temp[pname] then
            -- This is the first entry for the tutorial, apply default values
            mc_tutorial.record.temp[pname] = mc_tutorial.get_temp_shell()
        end
        action_table["action"] = action
        table.insert(mc_tutorial.record.temp[pname].sequence, action_table)
        mc_tutorial.record.temp[pname].length = mc_tutorial.record.temp[pname].length + 1
    end
end

-- If needed, this function runs continuously after starting a mc_tutorial.
-- It listens for specific actions in the sequence that do not have callbacks (punch, dig, place).
-- If the action is heard, then it checks against the expected value.
-- if the action matches the expected value, then the listener registers the completed action.
-- Once active.continue = false (i.e., the tutorial is completed), the listener turns off.
function mc_tutorial.tutorial_progress_listener(player)
    local pmeta = player:get_meta()
    local pdata = minetest.deserialize(pmeta:get_string("mc_tutorial:tutorials"))
    local pname = player:get_player_name()

    if pdata.active and not mc_tutorial.record.active[pname] then
        -- Figure out the type of action to call the correct listener
        local listener_map = {
            [mc_tutorial.ACTION.POS] = function()
                minetest.chat_send_player(pname, "[Tutorial] Listening for position...")

                pdata.player_seq.pos = player:get_pos()
                check_pos = pdata.active.sequence[pdata.active.seq_index].pos
                -- minetest.get_objects_inside_radius(pos, radius) may be better here?
                -- minetest.get_objects_in_area(pos1, pos2) would also work
                if (pdata.player_seq.pos.x >= check_pos.x - mc_tutorial.check_pos_x_tolerance) and (pdata.player_seq.pos.x <= check_pos.x + mc_tutorial.check_pos_x_tolerance) and (pdata.player_seq.pos.y >= check_pos.y - mc_tutorial.check_pos_y_tolerance) and (pdata.player_seq.pos.y <= check_pos.y + mc_tutorial.check_pos_y_tolerance) and (pdata.player_seq.pos.z >= check_pos.z - mc_tutorial.check_pos_z_tolerance) and (pdata.player_seq.pos.z <= check_pos.z + mc_tutorial.check_pos_z_tolerance) then
                    mc_tutorial.completed_action(player)
                end
            end,
            [mc_tutorial.ACTION.LOOK_DIR] = function()
                -- TODO
                minetest.chat_send_player(pname, "[Tutorial] Listening for look direction...")
            end,
            [mc_tutorial.ACTION.LOOK_PITCH] = function()
                minetest.chat_send_player(pname, "[Tutorial] Listening for look pitch...")

                pdata.player_seq.dir = player:get_look_vertical()
                check_dir = pdata.active.sequence[pdata.active.seq_index].dir
                if (pdata.player_seq.dir >= check_dir - mc_tutorial.check_dir_tolerance) and (pdata.player_seq.dir <= check_dir + mc_tutorial.check_dir_tolerance) then
                    mc_tutorial.completed_action(player)
                end
            end,
            [mc_tutorial.ACTION.LOOK_YAW] = function()
                minetest.chat_send_player(pname, "[Tutorial] Listening for look yaw...")

                pdata.player_seq.dir = player:get_look_horizontal()
                check_dir = pdata.active.sequence[pdata.active.seq_index].dir
                if (pdata.player_seq.dir >= check_dir - mc_tutorial.check_dir_tolerance) and (pdata.player_seq.dir <= check_dir + mc_tutorial.check_dir_tolerance) then
                    mc_tutorial.completed_action(player)
                end
            end,
            [mc_tutorial.ACTION.WIELD] = function()
                minetest.chat_send_player(pname, "[Tutorial] Listening for wield...")

                pdata.player_seq.wield = player:get_wielded_item():get_name()
                if pdata.player_seq.wield == pdata.active.sequence[pdata.active.seq_index].tool then
                    mc_tutorial.completed_action(player)
                end
            end,
            [mc_tutorial.ACTION.KEY] = function()
                minetest.chat_send_player(pname, "[Tutorial] Listening for keystroke...")

                pdata.player_seq.key_control = player:get_player_control()
                if pdata.player_seq.key_control.up or pdata.player_seq.key_control.down or pdata.player_seq.key_control.right or pdata.player_seq.key_control.left or pdata.player_seq.key_control.aux1 or pdata.player_seq.key_control.jump or pdata.player_seq.key_control.sneak then
                    pdata.player_seq.keys = {}
                    -- TODO: redesign (concat + sequence may be arbitrary)
                    for k,v in pairs(pdata.player_seq.key_control) do
                        if v then
                            table.insert(pdata.player_seq.keys, k)
                        end
                    end
                    if table.concat(pdata.player_seq.keys, " ") == table.concat(pdata.active.sequence[pdata.active.seq_index].key, " ") then
                        mc_tutorial.completed_action(player)
                    end
                end
            end
        }

        -- Perform check for appropriate listener
        if pdata.active.sequence[pdata.active.seq_index] and listener_map[pdata.active.sequence[pdata.active.seq_index].action] then
            listener_map[pdata.active.sequence[pdata.active.seq_index].action]()
        end
        -- Continue listener cycle
        minetest.after(mc_tutorial.check_interval, mc_tutorial.tutorial_progress_listener, player)
    end
end

-- This function is used to update the search index on completion of an action and check if the tutorial is completed.
-- If tutorial is completed, then initiate the on_complettion callbacks: give tool, give item, grant priv.
function mc_tutorial.completed_action(player)
    local pname = player:get_player_name()
    local pmeta = player:get_meta()
    local pdata = minetest.deserialize(pmeta:get_string("mc_tutorial:tutorials"))

    -- Action was successfully completed, so update the sequence index
    pdata.active.seq_index = pdata.active.seq_index + 1 
    minetest.sound_play("bell", {gain = 1.0, pitch = 1.0, to_player = pname}, true)

    -- Check if tutorial is completed
    if pdata.active.seq_index > pdata.active.length then
        -- on_completion callbacks here
        minetest.chat_send_player(pname, "[Tutorial] "..pdata.active.on_completion.message)

        local inv = player:get_inventory()
        for _,item in pairs(pdata.active.on_completion.items) do
            if not mc_helpers.getInventoryItemLocation(inv, ItemStack(item)) then
                inv:add_item("main", item)
            end
        end

        -- TODO
        local player_privs = minetest.get_player_privs(pname)
        for _,priv in pairs(pdata.active.on_completion.privs) do
            player_privs.priv = true
        end
        minetest.set_player_privs(pname, player_privs)

        pdata.listener.wield = false
        pdata.listener.key = false
        pdata.active = nil
    end

    -- set player metedata
    pmeta:set_string("mc_tutorial:tutorials", minetest.serialize(pdata))
end

-- This function is used specifically with defined callbacks (punch, dig, place) and therefore only checks for action, tool, and node
function mc_tutorial.check_tutorial_progress(player, action, data)
    local pname = player:get_player_name()
    local pmeta = player:get_meta()
    local pdata = minetest.deserialize(pmeta:get_string("mc_tutorial:tutorials"))

    -- any player can complete a tutorial, but don't attempt a tutorial if one is being recorded
    if pdata.active and not mc_tutorial.record.active[pname] then
        if not action then
            return false
        end

        -- match the action first since this callback might not even be relevant
        if action == pdata.active.sequence[pdata.active.seq_index].action then
            -- match the node next
            if data.node == pdata.active.sequence[pdata.active.seq_index].node then
                -- finally match the tool
                if data.tool == pdata.active.sequence[pdata.active.seq_index].tool then
                    mc_tutorial.completed_action(player)
                end
            end
        end
    end
end