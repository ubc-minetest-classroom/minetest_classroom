--- Sends the player an error message starting that they have not inputted a valud operation.
local function send_sc_op_error(name, err_msg, op_type, op_table)
    if not name or not op_table then return nil end

    local op_list = {}
    for op,_ in pairs(op_table) do
        table.insert(op_list, op)
    end
    minetest.chat_send_player(name, table.concat({err_msg or "Unrecognized operation.", "\nRecognized ", op_type or "commands", ": ", table.concat(op_list, ", ")}, ""))
end

-- subcommand table
local subcommands = {
    ["list"] = {
        desc = "List titles of all stored tutorials.",
        privs = mc_tutorial.player_priv_table,
        func = function(name, params)
            if mc_tutorial.tutorials_exist() then
                minetest.chat_send_player(name, "Recorded tutorials:")
                local tutorial_keys = mc_tutorial.get_storage_keys()
                for i,k in ipairs(tutorial_keys) do
                    if tonumber(k) then
                        local tutorial = minetest.deserialize(mc_tutorial.tutorials:get(tostring(k)))
                        minetest.chat_send_player(name, "- ["..k.."] "..tutorial.title)
                    end
                end
            else
                minetest.chat_send_player(name, "No tutorials have been recorded.")
            end
        end
    },
    ["player"] = {
        desc = "Handles player metadata saved by mc_tutorial.",
        params = "clear|dump",
        privs = mc_tutorial.recorder_priv_table,
        func = function(name, params)
            local op_table = {
                ["clear"] = function(name, params)
                    local player = minetest.get_player_by_name(name)
                    local pmeta = player:get_meta()
                    local pdata = minetest.deserialize(pmeta:get_string("mc_tutorial:tutorials"))
                    pdata.completed = {}
                    pmeta:set_string("mc_tutorial:tutorials", minetest.serialize(pdata))
                    minetest.chat_send_player(name, "[Tutorial] Your list of completed tutorials has been cleared.")
                end,
                ["dump"] = function(name, params)
                    local player = minetest.get_player_by_name(name)
                    local pmeta = player:get_meta()
                    local pdata = minetest.deserialize(pmeta:get_string("mc_tutorial:tutorials"))
                    minetest.chat_send_player(name, tostring(_G.dump(pdata)))
                end,
            }
            if #params >= 1 then
                local op = params[1]
                table.remove(params, 1)

                if op_table[op] then
                    op_table[op](name, params)
                else
                    return send_sc_op_error(name, nil, "operations", op_table)
                end
            else
                return send_sc_op_error(name, "No operation specified.", "operations", op_table)
            end
        end,
        
    },
    ["database"] = {
        desc = "Handles data within the mc_tutorial tutorial database.",
        params = "clear|dump",
        privs = mc_tutorial.recorder_priv_table,
        func = function(name, params)
            local op_table = {
                ["clear"] = function(name, params)
                    mc_tutorial.tutorials:from_table(nil)
                    minetest.chat_send_all("[Tutorial] All tutorials have been cleared from memory.")
                end,
                ["dump"] = function(name, params)
                    local tutorials = mc_tutorial.tutorials:to_table()
                    minetest.chat_send_player(name, tostring(_G.dump(tutorials)))
                end,
            }
            if #params >= 1 then
                local op = params[1]
                table.remove(params, 1)

                if op_table[op] then
                    op_table[op](name, params)
                else
                    return send_sc_op_error(name, nil, "operations", op_table)
                end
            else
                return send_sc_op_error(name, "No operation specified.", "operations", op_table)
            end
        end,
    }
}

-- tutorial command registration table
local tutorial_cmd = {
	description = "Performs tutorial functions.",
    params = "<subcommand> [<params>]",
	privs = mc_tutorial.recorder_priv_table,
	func = function(name, param)
        local params = mc_helpers.split(param, " ")
        if #params >= 1 then
            local action = params[1]
            table.remove(params, 1)

            if subcommands[action] then
                local priv_table = subcommands[action].privs or mc_tutorial.recorder_priv_table
                if mc_tutorial.check_privs(name, priv_table) then
                    subcommands[action].func(name, params)
                else
                    return minetest.chat_send_player(name, "You do not have permission to use this command.\nRequired privileges: "..table.concat(priv_table, ", "))
                end
            else
                return send_sc_op_error(name, "Unknown subcommand.", "subcommands", subcommands)
            end
        else
            return send_sc_op_error(name, "No subcommand specified", "subcommands", subcommands)
        end
	end
}

-- register commands
minetest.register_chatcommand("mc_tutorial", tutorial_cmd)
if not minetest.registered_chatcommands["tutorial"] then
    -- only register under "tutorial" if no other "tutorial" command exists
    minetest.register_chatcommand("tutorial", tutorial_cmd)
end
