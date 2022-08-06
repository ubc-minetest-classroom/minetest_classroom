local bit = dofile(minetest.get_modpath("mc_helpers") .. "/numberlua.lua")

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
        next_group = 1,
        on_completion = {
            message = "",
            items = {},
            privs = {}
        },
        format = 4
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
    end

    mc_tutorial.record.temp[pname].has_actions = true
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
            [mc_tutorial.ACTION.POS_ABS] = function(index)
                minetest.chat_send_player(pname, "[Tutorial] Listening for position...")

                pdata.player_seq.pos = player:get_pos()
                local check_pos = pdata.active.sequence[index].pos
                local tol = {x = mc_tutorial.check_pos_x_tolerance, y = mc_tutorial.check_pos_y_tolerance, z = mc_tutorial.check_pos_z_tolerance}
                
                local upper_pos = {x = check_pos.x + tol.x, y = check_pos.y + tol.y, z = check_pos.z + tol.z}
                local lower_pos = {x = check_pos.x - tol.x, y = check_pos.y - tol.y, z = check_pos.z - tol.z}
                for k,obj in pairs(minetest.get_objects_in_area(upper_pos, lower_pos)) do
                    if obj:is_player() and obj:get_player_name() == pname then
                        mc_tutorial.completed_action(player, index)
                    end
                end
            end,
            [mc_tutorial.ACTION.LOOK_DIR] = function(index)
                -- TODO
                minetest.chat_send_player(pname, "[Tutorial] Listening for look direction...")
            end,
            [mc_tutorial.ACTION.LOOK_PITCH] = function(index)
                minetest.chat_send_player(pname, "[Tutorial] Listening for look pitch...")

                pdata.player_seq.dir = player:get_look_vertical()
                check_dir = pdata.active.sequence[index].dir
                if (pdata.player_seq.dir >= check_dir - mc_tutorial.check_dir_tolerance) and (pdata.player_seq.dir <= check_dir + mc_tutorial.check_dir_tolerance) then
                    mc_tutorial.completed_action(player, index)
                end
            end,
            [mc_tutorial.ACTION.LOOK_YAW] = function(index)
                minetest.chat_send_player(pname, "[Tutorial] Listening for look yaw...")

                pdata.player_seq.dir = player:get_look_horizontal()
                check_dir = pdata.active.sequence[index].dir
                if (pdata.player_seq.dir >= check_dir - mc_tutorial.check_dir_tolerance) and (pdata.player_seq.dir <= check_dir + mc_tutorial.check_dir_tolerance) then
                    mc_tutorial.completed_action(player, index)
                end
            end,
            [mc_tutorial.ACTION.WIELD] = function(index)
                minetest.chat_send_player(pname, "[Tutorial] Listening for wield...")

                pdata.player_seq.wield = player:get_wielded_item():get_name()
                if pdata.player_seq.wield == pdata.active.sequence[index].tool then
                    mc_tutorial.completed_action(player, index)
                end
            end,
            [mc_tutorial.ACTION.KEY] = function(index)
                minetest.chat_send_player(pname, "[Tutorial] Listening for keystroke...")

                local bit_map = {
                    [0x001] = "up",
                    [0x002] = "down",
                    [0x004] = "left",
                    [0x008] = "right",
                    [0x010] = "jump",
                    [0x020] = "aux1",
                    [0x040] = "sneak",
                    [0x200] = "zoom",
                }
                local key_bits = player:get_player_control_bits()
                if bit.band(0x27F, key_bits) > 0 then
                    pdata.player_seq.keys = {}
                    for b,v in pairs(bit_map) do
                        if bit.band(b, key_bits) > 0 then
                            table.insert(pdata.player_seq.keys, v)
                        end
                    end
                    table.sort(pdata.player_seq.keys)
                    table.sort(pdata.active.sequence[index].key)

                    if table.concat(pdata.player_seq.keys, " ") == table.concat(pdata.active.sequence[index].key, " ") then
                        mc_tutorial.completed_action(player, index)
                    end
                end
            end
        }

        if pdata.active.sequence[pdata.active.seq_index] then
            -- Check if an action group is active
            local action_checks = {[pdata.active.seq_index] = true}
            if pdata.active.sequence[pdata.active.seq_index].action == mc_tutorial.ACTION.GROUP then
                action_checks = pdata.active.sequence[pdata.active.seq_index].g_remaining
            end

            -- Perform checks for appropriate listeners
            if action_checks and next(action_checks) then
                for index,_ in pairs(action_checks) do
                    if listener_map[pdata.active.sequence[index].action] then
                        listener_map[pdata.active.sequence[index].action](index)
                    end
                end
            else
                -- Empty group, skip
                mc_tutorial.completed_action(player, pdata.active.seq_index)
            end
        end
        -- Continue listener cycle
        minetest.after(mc_tutorial.check_interval, mc_tutorial.tutorial_progress_listener, player)
    end
end

--- Handles action group setup, if applicable
function mc_tutorial.initialize_action_group(pdata)
    local seq_step = pdata.active.sequence[pdata.active.seq_index]
    if seq_step and seq_step.action == mc_tutorial.ACTION.GROUP then
        if seq_step.g_type == mc_tutorial.GROUP.START then
            -- iterate and map indices in group
            local length = 0
            pdata.active.sequence[pdata.active.seq_index].g_remaining = pdata.active.sequence[pdata.active.seq_index].g_remaining or {}

            local i = pdata.active.seq_index + 1
            while pdata.active.sequence[i].action ~= mc_tutorial.ACTION.GROUP or pdata.active.sequence[i].g_type ~= mc_tutorial.GROUP.END or pdata.active.sequence[i].g_id ~= seq_step.g_id do
                pdata.active.sequence[pdata.active.seq_index].g_remaining[i] = true
                length = length + 1
                i = i + 1
            end

            if length ~= 0 then
                -- group has actions, verify initialization
                pdata.active.sequence[pdata.active.seq_index].g_length = length
            else
                -- empty group, skip
                pdata.active.seq_index = pdata.active.seq_index + 1
                mc_tutorial.initialize_action_group(pdata)
            end
        else
            -- not the start of a group, skip
            pdata.active.seq_index = pdata.active.seq_index + 1
            mc_tutorial.initialize_action_group(pdata)
        end
    end
end

-- This function is used to update the search index on completion of an action and check if the tutorial is completed.
-- If tutorial is completed, then initiate the on_complettion callbacks: give tool, give item, grant priv.
function mc_tutorial.completed_action(player, g_index)
    local pname = player:get_player_name()
    local pmeta = player:get_meta()
    local pdata = minetest.deserialize(pmeta:get_string("mc_tutorial:tutorials"))

    local function handle_increment()
        pdata.active.seq_index = pdata.active.seq_index + 1
        mc_tutorial.initialize_action_group(pdata)
    end

    -- Action was successfully completed, so play a sound
    minetest.sound_play("bell", {gain = 1.0, pitch = 1.0, to_player = pname}, true)

    -- Update the sequence index or remaining action list
    if pdata.active.sequence[pdata.active.seq_index] then
        if pdata.active.sequence[pdata.active.seq_index].action == mc_tutorial.ACTION.GROUP and g_index then
            pdata.active.sequence[pdata.active.seq_index].g_remaining[g_index] = nil
            if not next(pdata.active.sequence[pdata.active.seq_index].g_remaining) then
                -- all group actions complete, jump out of group
                pdata.active.seq_index = pdata.active.seq_index + pdata.active.sequence[pdata.active.seq_index].g_length
                handle_increment()
            end
        else
            handle_increment()
        end
    end

    -- Check if tutorial is completed
    if pdata.active.seq_index > pdata.active.length then
        -- on_completion callbacks here
        minetest.chat_send_player(pname, "[Tutorial] "..pdata.active.on_completion.message)

        if not mc_helpers.tableHas(pdata.completed, mc_tutorial.active[pname]) then
            -- Give rewards for first-time completion
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

            table.insert(pdata.completed, mc_tutorial.active[pname])
        end

        pdata.listener.wield = false
        pdata.listener.key = false
        pdata.active = nil
        mc_tutorial.active[pname] = nil
    end

    -- set player metadata
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

        local action_checks = {[pdata.active.seq_index] = true}
        -- check if a group is active
        if pdata.active.sequence[pdata.active.seq_index].action == mc_tutorial.ACTION.GROUP and pdata.active.sequence[pdata.active.seq_index].g_type == mc_tutorial.GROUP.START then
            action_checks = pdata.active.sequence[pdata.active.seq_index].g_remaining
        end

        if action_checks and next(action_checks) then
            -- match the action first since this callback might not even be relevant
            for index,_ in pairs(action_checks) do
                if action == pdata.active.sequence[index].action then
                    -- match the node next
                    if data.node == pdata.active.sequence[index].node then
                        -- finally match the tool
                        if data.tool == pdata.active.sequence[index].tool then
                            mc_tutorial.completed_action(player, index)
                        end
                    end
                end
            end
        else
            -- Empty group, skip
            mc_tutorial.completed_action(player, pdata.active.seq_index)
        end
    end
end