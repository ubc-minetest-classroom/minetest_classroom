mc_rules = {}
mc_rules.meta = minetest.get_mod_storage()
mc_rules.data = mc_rules.meta:get_string("rules")
local priv_table = { server = true }

function mc_rules.show_rules_formspec(accepted)
    -- Check if the rules are set?
    if mc_rules.meta:get_string("rules") ~= "" then
        local fs = {}
        fs[#fs+1] = "formspec_version[6]"
        fs[#fs+1] = "size[10,13]"
        fs[#fs+1] = "no_prepend[]"
        fs[#fs+1] = "bgcolor[#00000000]"
        fs[#fs+1] = "image[0,0;10,13;background.png]"
        fs[#fs+1] = "image[0.2,0;9.6,3.84;header.png]"
        fs[#fs+1] = "style_type[label;font=bold]"
        fs[#fs+1] = "label[1,3;"..minetest.colorize("#FFF", "MINETEST CLASSROOM").."]"
        fs[#fs+1] = "style_type[label;font_size=*2.5;font=bold]"
        fs[#fs+1] = "label[1,3.5;"..minetest.colorize("#FFF", "Server Rules").."]"
        fs[#fs+1] = "textarea[1,4;8,4;message;;"
        fs[#fs+1] = mc_rules.meta:get_string("rules")
        fs[#fs+1] = "]"
        if accepted then
            fs[#fs+1] = "image_button_exit[3.15,8.5;3.7,0.74;ok_button.png;ok;"..minetest.colorize("#000", "Okay")..";false;false]"
        else
            fs[#fs+1] = "image_button_exit[1.25,8.5;3.7,0.74;yes_button.png;accept;"..minetest.colorize("#000", "Yes\\, game on!")..";false;false]"
            fs[#fs+1] = "image_button_exit[5.05,8.5;3.7,0.74;no_button.png;reject;"..minetest.colorize("#000", "No thanks\\, bye!")..";false;false]"
        end
        fs[#fs+1] = "image[3.3,9.74;3.4,0.28;divider.png]"
        fs[#fs+1] = "style_type[textarea;font_size=*0.75]"
        fs[#fs+1] = "textarea[1,10.52;8,0.7;;The Minetest Classroom project was created on the traditional\\, ancestral\\, and unceded territory of the Musqueam People.;]"
        fs[#fs+1] = "image[1.25,11.24;7.5,1.55;logo.png]"
        return table.concat(fs, "")
    else
        return ""
    end
end

function mc_rules.show_edit_formspec(message)
    local fs = {}
    fs[#fs+1] = "formspec_version[6]"
    fs[#fs+1] = "size[10,13]"
    fs[#fs+1] = "no_prepend[]"
    fs[#fs+1] = "bgcolor[#00000000]"
    fs[#fs+1] = "image[0,0;10,13;background.png]"
    fs[#fs+1] = "image[0.5,0;9,3.6;header.png]"
    fs[#fs+1] = "style_type[label;font=bold]"
    fs[#fs+1] = "label[1,3;"..minetest.colorize("#FFF", "MINETEST CLASSROOM").."]"
    fs[#fs+1] = "style_type[label;font_size=*2.5;font=bold]"
    fs[#fs+1] = "label[1,3.5;"..minetest.colorize("#FFF", "Server Rules").."]"
    if message then
        fs[#fs+1] = "textarea[1,4;8,4;message;;"
        fs[#fs+1] = tostring(message)
        fs[#fs+1] = "]"
    elseif mc_rules.meta:get_string("rules") ~= "" then
        fs[#fs+1] = "textarea[1,4;8,4;message;;"
        fs[#fs+1] = mc_rules.meta:get_string("rules")
        fs[#fs+1] = "]"
    else
        fs[#fs+1] = "textarea[1,4;8,4;message;;Welcome to your new Minetest Classroom server! This is the default rules message that all players must accept before being allowed to play. You can change this message now by typing your new rules and then pressing the Save Rules button below or you can dismiss this message and change the rules later by typing /rules in the chat. This default message is only visible to the player with the Server privilege.]"
    end
    fs[#fs+1] = "image_button_exit[1.25,8.5;3.7,0.74;ok_button.png;dismiss;"..minetest.colorize("#000", "Dismiss")..";false;false]"
    fs[#fs+1] = "image_button_exit[5.05,8.5;3.7,0.74;save_button.png;save;"..minetest.colorize("#000", "Save Rules")..";false;false]"
    fs[#fs+1] = "image[3.3,9.74;3.4,0.28;divider.png]"
    fs[#fs+1] = "style_type[textarea;font_size=*0.75]"
    fs[#fs+1] = "textarea[1,10.52;8,0.7;;The Minetest Classroom project was created on the traditional\\, ancestral\\, and unceded territory of the Musqueam People.;]"
    fs[#fs+1] = "image[1.25,11.24;7.5,1.55;logo.png]"
    return table.concat(fs, "")
end

minetest.register_chatcommand("rules", {
	params = "",
	description = "Server rules",
	func = function(name, param)
	minetest.after((0.1), function()
        if mc_core.checkPrivs(minetest.get_player_by_name(name), priv_table) then
            return minetest.show_formspec(name, "mc_rules:edit", mc_rules.show_edit_formspec(nil))
        else
            local pmeta = minetest.get_player_by_name(name):get_meta()
            local pdata = pmeta:get_int("mc_rules")
            if pdata == nil or pdata == 0 then
                return minetest.show_formspec(name, "mc_rules:rules", mc_rules.show_rules_formspec(false))
            else
                return minetest.show_formspec(name, "mc_rules:rules", mc_rules.show_rules_formspec(true))
            end
        end
	end)
end})

minetest.register_on_joinplayer(function(player)
    -- Check if they have already accepted the rules
    local pmeta = player:get_meta()
    local pdata = pmeta:get_int("mc_rules")
    if pdata ~= nil and pdata == 0 then
        if mc_core.checkPrivs(player, priv_table) then
            minetest.show_formspec(player:get_player_name(), "mc_rules:rules", mc_rules.show_edit_formspec(nil))
        else
            minetest.show_formspec(player:get_player_name(), "mc_rules:rules", mc_rules.show_rules_formspec(false))
        end
    end
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if string.sub(formname, 1, 8) ~= "mc_rules" then
        return false
    end

    local wait = os.clock()
    while os.clock() - wait < 0.05 do
    end

    -- Menu
    if formname == "mc_rules:rules" then
        if fields.accept then
            local pmeta = player:get_meta()
            pmeta:set_int("mc_rules", 1)
            minetest.show_formspec(player:get_player_name(), "mc_rules:rules", mc_rules.show_rules_formspec(true))
        elseif fields.reject then
            minetest.kick_player(player:get_player_name(), "You must agree to the rules in order to play on this server.")
        elseif fields.ok then
            return true
        else
            -- Unhandled exit, check if already agreed, otherwise treat as rejected
            local pmeta = player:get_meta()
            local pdata = pmeta:get_int("mc_rules")
            if pdata and pdata == 1 then
                return true
            else
                if not mc_core.checkPrivs(player, priv_table) then
                    minetest.kick_player(player:get_player_name(), "You must agree to the rules in order to play on this server.")
                end
            end
        end
    end

    if formname == "mc_rules:edit" then
        if fields.dismiss then
            return true
        elseif fields.save then
            if mc_core.checkPrivs(player, priv_table) then
                mc_rules.meta:set_string("rules",fields.message)
                mc_rules.show_edit_formspec(fields.message)
            end
        else
            -- Unhandled exit, treat as dismiss
            return true
        end
    end
end)