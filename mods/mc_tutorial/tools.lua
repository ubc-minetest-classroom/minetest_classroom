-- The tutorial book for accessing tutorials
minetest.register_tool("mc_tutorial:tutorialbook" , {
	description = "Tutorial book",
	inventory_image = "mc_tutorial_tutorialbook.png",
	-- Left-click the tool activates the tutorial menu
	on_use = function(itemstack, player, pointed_thing)
        local pname = player:get_player_name()
		-- Check for privileges
		if mc_tutorial.check_privs(player, mc_tutorial.player_priv_table) then
			mc_tutorial.show_tutorials(player)
		end
	end,
	-- Destroy the book on_drop to keep things tidy
	on_drop = function(itemstack, dropper, pos)
        return
	end,
})
minetest.register_alias("tutorialbook", "mc_tutorial:tutorialbook")

if minetest.get_modpath("mc_toolhandler") then
	mc_toolhandler.register_tool_manager("mc_tutorial:tutorialbook", {privs = mc_tutorial.player_priv_table, inv_override = "main"})
end

local function open_recording_menu(itemstack, player, pointed_thing)
    local pname = player:get_player_name()
    if not mc_tutorial.check_privs(player,mc_tutorial.recorder_priv_table) then
        minetest.chat_send_player(pname, "[Tutorial] You do not have privileges to use this tool.")
        return nil
    else
        if mc_tutorial.record.active[pname] == "record" then
            mc_tutorial.show_record_options_fs(player)
        else
            minetest.chat_send_player(pname, "[Tutorial] You need to start an active recording first by left-clicking with the tool.")
            return nil
        end
    end
end

function mc_tutorial.stop_recording(player)
    local pname = player:get_player_name()
    -- stop the recording and save to mod storage
    mc_tutorial.record.listener.wield[pname] = nil
    mc_tutorial.record.listener.key[pname] = nil
    if mc_tutorial.record.temp[pname] then
        mc_tutorial.record.active[pname] = "save"
        mc_tutorial.show_record_fs(player)
        minetest.chat_send_player(pname, "[Tutorial] Recording has ended!")
    else
        mc_tutorial.record.active[pname] = nil
        minetest.chat_send_player(pname, "[Tutorial] No actions were recorded.")
    end
end

-- The tutorial recording tool
minetest.register_tool("mc_tutorial:recording_tool", {
    description = "Tutorial Recording Tool",
    _doc_items_longdesc = "This tool can be used to record a sequence of action callbacks (punch, dig, place, position, look directions, and key strikes) that are stored in a tutorial table.",
    _doc_items_usagehelp = "Using the tool (left-click) to start the recording, perform some actions, and use it again to stop the recording sequence. While a recording is active, right-click the tool to access additional recording options.",
    _doc_items_hidden = false,
    tool_capabilities = {},
    range = 100,
    groups = { disable_repair = 1 }, 
    wield_image = "mc_tutorial_recording_tool.png",
    inventory_image = "mc_tutorial_recording_tool.png",
    liquids_pointable = false,
    on_use = function(itemstack, player, pointed_thing)
        local pname = player:get_player_name()
        if not mc_tutorial.check_privs(player, mc_tutorial.recorder_priv_table) then
            minetest.chat_send_player(pname, "[Tutorial] You do not have privileges to use this tool.")
            return nil
        else
            if not mc_tutorial.record.active[pname] then
                -- start the recording
                mc_tutorial.record.active[pname] = "record"
                minetest.chat_send_player(pname, "[Tutorial] Recording has started! Any actions will now be recorded. Right-click to see more recording options.")
            else
                mc_tutorial.stop_recording(player)
            end
        end
    end,

    on_secondary_use = open_recording_menu,
    on_place = open_recording_menu,

    -- makes the tool undroppable
    on_drop = function(itemstack, dropper, pos)
        return
    end,
})
minetest.register_alias("recording_tool", "mc_tutorial:recording_tool")

if minetest.get_modpath("mc_toolhandler") then
	mc_toolhandler.register_tool_manager("mc_tutorial:recording_tool", {privs = mc_tutorial.recorder_priv_table})
end
