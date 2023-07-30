--- Returns a list containing the names of the given player's saved coordinates
local function get_saved_coords(player)
    local pmeta = player:get_meta()
    local realm = Realm.GetRealmFromPlayer(player)
    local pdata = minetest.deserialize(pmeta:get_string("coordinates"))
    local context = mc_teacher.get_fs_context(player)
    local coord_list = {}

    if pdata == nil or pdata == {} then
        context.coord_i_to_note = {}
        return coord_list
    elseif pdata.realms then
        local new_note_map, new_coords, new_realms = {}, {}, {}
        context.coord_i_to_note = {}

        for note,i in pairs(pdata.note_map) do
            local coordrealm = Realm.GetRealm(pdata.realms[i])
            if coordrealm then
                -- Do not include coordinates saved in other realms in output
                if realm and coordrealm.ID == realm.ID and note ~= "" then
                    table.insert(coord_list, note)
                    context.coord_i_to_note[#coord_list] = note
                end
                -- Remove coordinates saved in realms that no longer exist from database
                table.insert(new_coords, pdata.coords[i])
                table.insert(new_realms, pdata.realms[i])
                new_note_map[note] = #new_coords
            end
        end

        pmeta:set_string("coordinates", minetest.serialize({note_map = new_note_map, coords = new_coords, realms = new_realms, format = 2}))
        return coord_list
    end
end

local function get_options_height(context)
    if (not context.realm_gen or context.realm_gen == mc_teacher.R.GEN.NONE) then
        return 2.6
    elseif context.realm_dec == mc_teacher.R.DEC.BIOME then
        return 5.2
    else
        return 3.9
    end
end

local function get_privs(player)
    local pmeta = player:get_meta()
    local privs = minetest.get_player_privs(player:get_player_name())
    local universal_privs = minetest.deserialize(pmeta:get_string("universalPrivs")) or {}

    for k, v in pairs(universal_privs) do
        if v == false then
            privs[k] = (privs[k] and "overridden") or false
        end
    end
    if mc_teacher.is_frozen(player) then
        privs["fast"] = "alt_deny"
    end
    return privs
end

local function role_to_fs_elem(role_string, caller_has_server_privs)
    local map = {
        [mc_teacher.ROLES.NONE] = {[true] = "p_role_none", [false] = "p_role_none"},
        [mc_teacher.ROLES.STUDENT] = {[true] = "p_role_student", [false] = "p_role_student"},
        [mc_teacher.ROLES.TEACHER] = {[true] = "p_role_teacher", [false] = "blocked_role_teacher"},
        [mc_teacher.ROLES.ADMIN] = {[true] = "p_role_admin", [false] = "blocked_role_admin"},
    }
    return role_string and map[role_string] and map[role_string][caller_has_server_privs] or ""
end

local function generate_player_table(p_list, p_priv_list)
    local privs_to_check = {"shout", "interact", "fast", "fly", "noclip", "give"}
    local combined_list = {}
    for i, player in ipairs(p_list) do
        for j, priv in ipairs(privs_to_check) do
            if p_priv_list[i][priv] == true then
                table.insert(combined_list, 1)
            elseif p_priv_list[i][priv] == false then
                table.insert(combined_list, 2)
            elseif p_priv_list[i][priv] == "overridden" then
                table.insert(combined_list, 3)
            elseif p_priv_list[i][priv] == "alt_deny" then
                table.insert(combined_list, 4)
            else
                table.insert(combined_list, 0)
            end
        end
        table.insert(combined_list, player)
    end
    return table.concat(combined_list, ",")
end

local function get_priv_button_states(p_list, p_priv_list)
    local states = {}
    local privs_to_check = {shout = true, interact = true}
    for _,table in pairs(p_priv_list) do
        for priv,_ in pairs(privs_to_check) do
            if table[priv] == "overridden" or table[priv] == false then
                states[priv] = (states[priv] == true and "mixed") or false
            else
                states[priv] = (states[priv] == false and "mixed") or true
            end
            if states[priv] == "mixed" then
                privs_to_check[priv] = nil
            end
        end
    end
    for _,player in pairs(p_list) do
        local p_obj = minetest.get_player_by_name(player)
        -- freeze
        if states["frozen"] ~= "mixed" and p_obj then
            if mc_teacher.is_frozen(p_obj) then
                states["frozen"] = (states[priv] == true and "mixed") or false
            else
                states["frozen"] = (states[priv] == false and "mixed") or true
            end
        end
    end
    return states
end

local function create_state_button(x, y, width, height, state_names, state_labels, state)
    if state == "mixed" then
        local button_width = (width - 0.3)/2
        return table.concat({
            "style[", state_names[true], ";bgimg=blank.png]",
            "style[", state_names[false], ";bgimg=blank.png]",

            "image[", x, ",", y, ";", width, ",", height, ";mc_pixel.png^[multiply:", mc_core.col.b.default, "]",
            "image[", x + 0.1, ",", y + 0.1, ";", button_width, ",", height - 0.2, ";mc_pixel.png^[multiply:", mc_core.col.b.red, "]",
            "image[", x + button_width + 0.2, ",", y + 0.1, ";", button_width, ",", height - 0.2, ";mc_pixel.png^[multiply:", mc_core.col.b.selected, "]",
            "hypertext[", x, ",", y + 0.05, ";", width, ",", height - 0.05, ";;<global valign=middle halign=center font=mono><b>", state_labels.default, "</b>]",
            "button[", x + 0.1, ",", y + 0.1, ";", button_width, ",", height - 0.2, ";", state_names[true], ";]",
            "button[", x + button_width + 0.2, ",", y + 0.1, ";", button_width, ",", height - 0.2, ";", state_names[false], ";]",
        })
    elseif state == false then
        return table.concat({"button[", x, ",", y, ";", width, ",", height, ";", state_names[false], ";", state_labels[false], "]"})
    else
        return table.concat({"button[", x, ",", y, ";", width, ",", height, ";", state_names[true], ";", state_labels[true], "]"})
    end
end

function mc_teacher.show_confirm_popup(player, fs_name, action, size)
    local spacer = mc_teacher.fs_spacer
    local text_spacer = mc_teacher.fs_t_spacer
    local width = math.max(size and size.x or 7.5, 1.5)
    local height = math.max(size and size.y or 3.4, 2.1)
    local button_width = (width - 2*spacer - 0.1)/2

    local pname = player:get_player_name()
    
    local fs = {
        mc_core.draw_note_fs(width, height, {bg = "#f2aeec", accent = "#f9c8fa"}),
        "style_type[textarea;font=mono,bold;textcolor=#000000]",
        "style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:", mc_core.col.b.default, "]",
        "textarea[", text_spacer, ",0.5;", width - 2*text_spacer, ",", height - 2, ";;;", action and action.action or "Are you sure you want to perform this action?",
        action.irreversible and "\nThis action is irreversible." or "", "]",
        "button[", spacer, ",", height - 1.4, ";", button_width, ",0.8;confirm;", action and action.button or "Confirm", "]",
        "button[", spacer + 0.1 + button_width, ",", height - 1.4, ";", button_width, ",0.8;cancel;Cancel]",
    }
    minetest.show_formspec(pname, "mc_teacher:"..fs_name, table.concat(fs, ""))
end

function mc_teacher.show_whitelist_popup(player)
    local spacer = mc_teacher.fs_spacer
    local text_spacer = mc_teacher.fs_t_spacer
    local width = 12.2
    local height = 7.4
    local content_width = 5.3
    local text_width = content_width + 2*(spacer - text_spacer)
    local button_width = (content_width - 0.1)/2

    local pname = player:get_player_name()
    local context = mc_teacher.get_fs_context(player)

    local whitelist_state = networking.get_whitelist_enabled()
    local ipv4_whitelist = networking.get_whitelist()
    context.ip_whitelist = {}
    for ipv4,_ in pairs(ipv4_whitelist) do
        table.insert(context.ip_whitelist, ipv4)
    end
    table.sort(context.ip_whitelist, networking.ipv4_compare)

    local fs = {
        mc_core.draw_note_fs(width, height, {bg = "#baf5a2", accent = "#e0fccf"}),
        "style_type[textarea;font=mono,bold;textcolor=#000000]",
        "style_type[textlist,field;font=mono]",
        "style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:", mc_core.col.b.default, "]",

        "textarea[", text_spacer, ",0.5;", text_width, ",1;;;Whitelisted IPv4 Addresses]",
    }

    if context.show_whitelist then
        table.insert(fs, table.concat({
            "textlist[", spacer, ",0.9;", content_width, ",5.9;whitelist;", table.concat(context.ip_whitelist, ","), ";", context.selected_ip_range or 1, ";false]",
        }))
    else
        local length = networking.get_whitelist_length()
        table.insert(fs, table.concat({
            "style_type[textarea;font=mono]",
            "textarea[", text_spacer, ",0.9;", text_width, ",5;;;", length, " IPv4 address", length == 1 and "" or "es", " in whitelist (including 127.0.0.1)\n\n",
            "Whitelisted IP addresses are hidden by default for performance, since loading large whitelists can cause lag when opening this popup.]",
            "style_type[textarea;font=mono,bold]",
            "button[", spacer, ",6;", content_width, ",0.8;whitelist_show;Show IP addresses]",
        }))
    end

    table.insert(fs, table.concat({
        "style[blocked_remove;bgimg=mc_pixel.png^[multiply:", mc_core.col.b.blocked, "]",
        "button[", content_width + spacer + 0.4, ",4.2;", content_width, ",0.8;toggle;", whitelist_state and "DISABLE" or "ENABLE", " whitelist]",
        "button[", content_width + spacer + 0.4, ",5.1;", content_width, ",0.8;", context.show_whitelist and "" or "blocked_", "remove;Delete selected]",
        "textarea[", content_width + text_spacer + 0.4, ",0.5;", text_width, ",1;;;Start IPv4]",
        "textarea[", content_width + text_spacer + 0.4, ",1.7;", text_width, ",1;;;End IPv4 (optional)]",
        "field[", content_width + spacer + 0.4, ",0.9;", content_width, ",0.8;ip_start;;", context.start_ip or "0.0.0.0", "]",
        "field[", content_width + spacer + 0.4, ",2.1;", content_width, ",0.8;ip_end;;", context.end_ip or "", "]",
        "button[", content_width + spacer + 0.4, ",3;", button_width, ",0.8;ip_add;Add range]",
        "button[", content_width + spacer + 3.1, ",3;", button_width, ",0.8;ip_remove;Remove range]",
        "button[", content_width + spacer + 0.4, ",6;", content_width, ",0.8;exit;Return]",

        "tooltip[ip_start;First IPv4 address in the desired range;", mc_core.col.b.default, ";#ffffff]",
        "tooltip[ip_end;Last IPv4 address in the desired range (optional);", mc_core.col.b.default, ";#ffffff]",
        "tooltip[whitelist_remove;Removes the selected IP range from the whitelist;", mc_core.col.b.default, ";#ffffff]",
        "tooltip[ip_add;Adds the typed range of IPs to the whitelist;", mc_core.col.b.default, ";#ffffff]",
        "tooltip[ip_remove;Removes the typed range of IPs from the whitelist;", mc_core.col.b.default, ";#ffffff]",
        "tooltip[toggle;Whitelist is currently ", whitelist_state and "ENABLED" or "DISABLED", ";", mc_core.col.b.default, ";#ffffff]",
    }))
    minetest.show_formspec(pname, "mc_teacher:whitelist", table.concat(fs, ""))
end

--[[ WHITELIST POPUP (LIST SHOWN)
formspec_version[6]
size[12.2,7.4]
textarea[0.55,0.5;5.4,1;;;Whitelisted IPv4 Addresses]
textlist[0.6,0.9;5.3,5.9;whitelist;;1;false]
button[6.3,4.2;5.3,0.8;toggle;ENABLE whitelist]
button[6.3,5.1;5.3,0.8;remove;Delete selected]
textarea[6.25,0.5;5.4,1;;;Start IPv4]
textarea[6.25,1.7;5.4,1;;;End IPv4 (optional)]
field[6.3,0.9;5.3,0.8;ip_start;;0.0.0.0]
field[6.3,2.1;5.3,0.8;ip_end;;]
button[6.3,3;2.6,0.8;ip_add;Add range]
button[9,3;2.6,0.8;ip_remove;Remove range]
button[6.3,6;5.3,0.8;exit;Return]

-- (LIST HIDDEN)
formspec_version[6]
size[12.2,7.4]
textarea[0.55,0.5;5.4,1;;;Whitelisted IPv4 Addresses]
textarea[0.55,0.9;5.4,5;;;X IPv4 addresses in whitelist (including 127.0.0.1) - Whitelisted IP addresses are hidden by default to prevent lag when opening the whitelist popup when the whitelist is very large ]
button[0.6,6;5.3,0.8;show_list;Show IP addresses]
]]

function mc_teacher.show_edit_popup(player, realmID)
    local spacer = mc_teacher.fs_spacer
    local text_spacer = mc_teacher.fs_t_spacer
    local width = 8.3
    local height = 9.5
    local button_width = (width - 2*spacer - 0.1)/2

    local pname = player:get_player_name()
    local context = mc_teacher.get_fs_context(player)
    local realm = Realm.GetRealm(realmID)

    if not realmID or not realm then
        return minetest.show_formspec(pname, "mc_teacher:edit_realm", table.concat({
            mc_core.draw_note_fs(6, 2.5),
            "style_type[textarea;font=mono;textcolor=#000000]",
            "textarea[0.55,0.5;4.9,1;;;Classroom not found!]",
            "button[0.6,1.1;4.8,0.8;cancel;Return]",
        }, ""))
    end

    if not context.edit_realm then
        local cat = realm:getCategory()
        context.edit_realm = {
            name = realm.Name or "",
            type = cat and Realm.CAT_RMAP[cat.key] or Realm.CAT_KEY.DEFAULT,
            privs = {interact = "nil", shout = "nil", fast = "nil", fly = "nil", noclip = "nil", give = "nil"},
            id = realmID,
        }
        for priv,v in pairs(realm.Permissions or {interact = true, shout = true, fast = true}) do
            if context.edit_realm.privs[priv] ~= nil then
                context.edit_realm.privs[priv] = v
            end
        end
    end

    local fs = {
        mc_core.draw_note_fs(width, height),
        "style_type[textarea;font=mono,bold;textcolor=#000000]",
        "style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:", mc_core.col.b.default, "]",
        "style_type[field;font=mono;textcolor=#ffffff]",
        "textarea[", text_spacer, ",0.5;", width - 2*text_spacer, ",1;;;Name]",
        "field[", spacer, " ,0.9;", width - 2*spacer, ",0.8;erealm_name;;", minetest.formspec_escape(context.edit_realm.name), "]",
        "field_close_on_enter[erealm_name;false]",
        "textarea[", text_spacer, ",1.8;", button_width + 0.1, ",1;;;Type]",
        "dropdown[", spacer, " ,2.2;", button_width, ",0.8;erealm_cat;Default,Spawn,Classroom,Private;", context.edit_realm.type, ";true]",
        "hypertext[", text_spacer + button_width + 0.1, ",1.82;", button_width + 0.1, ",1;;<global font=mono halign=center color=#000000><b>Internal ID</b>]",
        "hypertext[", text_spacer + button_width + 0.1, ",2.22;", button_width + 0.1, ",2;;<global font=mono halign=center color=#000000><b><bigger>#", realmID, "</bigger></b>]",

        "textarea[", text_spacer, ",3.1;", width - 2*text_spacer, ",1;;;Default Privileges]",
        "style_type[textarea;font=mono]",
        "textarea[", text_spacer + 1.3, ",3.9;2.3,1;;;interact]",
        "textarea[", text_spacer + 1.3, ",4.3;2.3,1;;;shout]",
        "textarea[", text_spacer + 1.3, ",4.7;2.3,1;;;fast]",
        "textarea[", text_spacer + button_width + 1.4, ",3.9;2.3,1;;;fly]",
        "textarea[", text_spacer + button_width + 1.4, ",4.3;2.3,1;;;noclip]",
        "textarea[", text_spacer + button_width + 1.4, ",4.7;2.3,1;;;give]",
        "style_type[textarea;font=mono,bold]",

        "image[", text_spacer, ",3.5;0.4,0.4;mc_teacher_check.png]",
        "image[", text_spacer + 0.4, ",3.5;0.4,0.4;mc_teacher_ignore.png]",
        "image[", text_spacer + 0.8, ",3.5;0.4,0.4;mc_teacher_delete.png]",
        "image[", text_spacer + button_width + 0.1, ",3.5;0.4,0.4;mc_teacher_check.png]",
        "image[", text_spacer + button_width + 0.5, ",3.5;0.4,0.4;mc_teacher_ignore.png]",
        "image[", text_spacer + button_width + 0.9, ",3.5;0.4,0.4;mc_teacher_delete.png]",
        "tooltip[", text_spacer, ",3.5;0.4,0.4;ALLOW: Privilege will be granted\n(does NOT override universal privileges);#404040;#ffffff]",
        "tooltip[", text_spacer + 0.4, ",3.5;0.4,0.4;IGNORE: Privilege will be unaffected;#404040;#ffffff]",
        "tooltip[", text_spacer + 0.8, ",3.5;0.4,0.4;DENY: Privilege will not be granted\n(overrides universal privileges);#404040;#ffffff]",
        "tooltip[", text_spacer + 3.6, ",3.5;0.4,0.4;ALLOW: Privilege will be granted\n(does NOT override universal privileges);#404040;#ffffff]",
        "tooltip[", text_spacer + 4.0, ",3.5;0.4,0.4;IGNORE: Privilege will be unaffected;#404040;#ffffff]",
        "tooltip[", text_spacer + 4.4, ",3.5;0.4,0.4;DENY: Privilege will not be granted\n(overrides universal privileges);#404040;#ffffff]",

        "checkbox[", spacer, ",4.1;allowpriv_interact;;",        tostring(context.edit_realm.privs.interact == true), "]",
        "checkbox[", spacer, ",4.5;allowpriv_shout;;",           tostring(context.edit_realm.privs.shout    == true), "]",
        "checkbox[", spacer, ",4.9;allowpriv_fast;;",            tostring(context.edit_realm.privs.fast     == true), "]",
        "checkbox[", spacer + 0.4, ",4.1;ignorepriv_interact;;", tostring(context.edit_realm.privs.interact == "nil"), "]",
        "checkbox[", spacer + 0.4, ",4.5;ignorepriv_shout;;",    tostring(context.edit_realm.privs.shout    == "nil"), "]",
        "checkbox[", spacer + 0.4, ",4.9;ignorepriv_fast;;",     tostring(context.edit_realm.privs.fast     == "nil"), "]",
        "checkbox[", spacer + 0.8, ",4.1;denypriv_interact;;",   tostring(context.edit_realm.privs.interact == false), "]",
        "checkbox[", spacer + 0.8, ",4.5;denypriv_shout;;",      tostring(context.edit_realm.privs.shout    == false), "]",
        "checkbox[", spacer + 0.8, ",4.9;denypriv_fast;;",       tostring(context.edit_realm.privs.fast     == false), "]",
        "checkbox[", spacer + button_width + 0.1, ",4.1;allowpriv_fly;;",     tostring(context.edit_realm.privs.fly    == true), "]",
        "checkbox[", spacer + button_width + 0.1, ",4.5;allowpriv_noclip;;",  tostring(context.edit_realm.privs.noclip == true), "]",
        "checkbox[", spacer + button_width + 0.1, ",4.9;allowpriv_give;;",    tostring(context.edit_realm.privs.give   == true), "]",
        "checkbox[", spacer + button_width + 0.5, ",4.1;ignorepriv_fly;;",    tostring(context.edit_realm.privs.fly    == "nil"), "]",
        "checkbox[", spacer + button_width + 0.5, ",4.5;ignorepriv_noclip;;", tostring(context.edit_realm.privs.noclip == "nil"), "]",
        "checkbox[", spacer + button_width + 0.5, ",4.9;ignorepriv_give;;",   tostring(context.edit_realm.privs.give   == "nil"), "]",
        "checkbox[", spacer + button_width + 0.9, ",4.1;denypriv_fly;;",      tostring(context.edit_realm.privs.fly    == false), "]",
        "checkbox[", spacer + button_width + 0.9, ",4.5;denypriv_noclip;;",   tostring(context.edit_realm.privs.noclip == false), "]",
        "checkbox[", spacer + button_width + 0.9, ",4.9;denypriv_give;;",     tostring(context.edit_realm.privs.give   == false), "]",
        
        "textarea[", text_spacer, ",5.2;", width - 2*text_spacer, ",1;;;Background Music]",
        "dropdown[", spacer, " ,5.6;", width - 2*spacer, ",0.8;erealm_bgmusic;;1;true]",
        "textarea[", text_spacer, ",6.5;", width - 2*text_spacer, ",1;;;Skybox]",
        "dropdown[", spacer, ",6.9;", width - 2*spacer, ",0.8;erealm_skybox;;1;true]",
        "button[", spacer, " ,8.1;", button_width, ",0.8;save_realm;Save changes]",
        "button[4.2,8.1;", button_width, ",0.8;cancel;Cancel]",
    }
    minetest.show_formspec(pname, "mc_teacher:edit_realm", table.concat(fs, ""))
end

--[[ EDIT POPUP
formspec_version[6]
size[8.3,9.5]
textarea[0.55,0.5;7.2,1;;;Name]
field[0.6,0.9;7.1,0.8;realmname;;]
textarea[0.55,1.8;3.6,1;;;Type]
dropdown[0.6,2.2;3.5,0.8;realmcategory;Default,Spawn,Classroom,Private;1;true]
textarea[4.15,1.8;3.6,1;;;Internal ID]
textarea[0.55,3.1;7.2,1;;;Default Privileges]
textarea[1.85,3.9;2.3,1;;;interact]
textarea[1.85,4.3;2.3,1;;;shout]
textarea[1.85,4.7;2.3,1;;;fast]
textarea[5.45,3.9;2.3,1;;;fly]
textarea[5.45,4.3;2.3,1;;;noclip]
textarea[5.45,4.7;2.3,1;;;give]
image[0.6,3.5;0.4,0.4;mc_teacher_check.png]
image[1,3.5;0.4,0.4;mc_teacher_ignore.png]
image[1.4,3.5;0.4,0.4;mc_teacher_delete.png]
image[4.2,3.5;0.4,0.4;mc_teacher_check.png]
image[4.6,3.5;0.4,0.4;mc_teacher_ignore.png]
image[5,3.5;0.4,0.4;mc_teacher_delete.png]
checkbox[0.6,4.1;allowpriv_interact;;true]
checkbox[0.6,4.5;allowpriv_shout;;true]
checkbox[0.6,4.9;allowpriv_fast;;true]
checkbox[1,4.1;ignorepriv_interact;;false]
checkbox[1,4.5;ignorepriv_shout;;false]
checkbox[1,4.9;ignorepriv_fast;;false]
checkbox[1.4,4.1;denypriv_interact;;false]
checkbox[1.4,4.5;denypriv_shout;;false]
checkbox[1.4,4.9;denypriv_fast;;false]
checkbox[4.2,4.1;allowpriv_fly;;false]
checkbox[4.2,4.5;allowpriv_noclip;;false]
checkbox[4.2,4.9;allowpriv_give;;false]
checkbox[4.6,4.1;ignorepriv_fly;;true]
checkbox[4.6,4.5;ignorepriv_noclip;;true]
checkbox[4.6,4.9;ignorepriv_give;;true]
checkbox[5,4.1;denypriv_fly;;false]
checkbox[5,4.5;denypriv_noclip;;false]
checkbox[5,4.9;denypriv_give;;false]
textarea[0.55,5.2;7.2,1;;;Background Music]
dropdown[0.6,5.6;7.1,0.8;bgmusic;;1;true]
textarea[0.55,6.5;7.2,1;;;Skybox]
dropdown[0.6,6.9;7.1,0.8;;;1;true]
button[0.6,8.1;3.5,0.8;save_realm;Save changes]
button[4.2,8.1;3.5,0.8;cancel;Cancel]
]]

function mc_teacher.show_controller_fs(player, tab)
    local controller_width = 16.6
    local controller_height = 10.4
    local panel_width = controller_width/2
    local spacer = mc_teacher.fs_spacer
    local text_spacer = mc_teacher.fs_t_spacer

    local pname = player:get_player_name()
    local pmeta = player:get_meta()
    local context = mc_teacher.get_fs_context(player)

    if mc_core.checkPrivs(player) then
        local has_server_privs = mc_core.checkPrivs(player, {server = true})
        local tab_map = {
            [mc_teacher.TABS.OVERVIEW] = function()
                local button_width = 1.7
                local button_height = 1.6
                local rules = mc_rules.meta:get_string("rules")
                if not rules or rules == "" then
                    rules = "Rules have not yet been set for this server."
                end

                local Y_SIZE, FACTOR = controller_height - 0.5, 0.05
                local fs = {
                    "image[0,0;", controller_width, ",0.5;mc_pixel.png^[multiply:#737373]",
                    "image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
                    "tooltip[exit;Exit;#404040;#ffffff]",
                    "hypertext[", text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Overview</b></center></style>]",
                    "hypertext[", panel_width + text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Dashboard</b></center></style>]",

                    "style_type[textarea;font=mono,bold;textcolor=#000000]",
                    "style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:", mc_core.col.b.default, "]",
                    "textarea[", text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Welcome to Minetest Classroom!]",
                    "textarea[", text_spacer, ",4.6;", panel_width - 2*text_spacer, ",1;;;Server Rules]",
                    "style_type[textarea;font=mono]",
                    "textarea[", text_spacer, ",1.4;", panel_width - 2*text_spacer, ",3;;;", minetest.formspec_escape("This is the Teacher Controller, your tool for managing classrooms, player privileges, and server settings."),
                    "\n", minetest.formspec_escape("You cannot drop this tool, so you will never lose it. However, you can move it out of your hotbar and into your inventory or the toolbox."), "]",
                    "textarea[", text_spacer, ",5.0;", panel_width - 2*text_spacer, ",", has_server_privs and 3.9 or 4.8, ";;;", minetest.formspec_escape(rules), "]",
                    has_server_privs and "button[0.6,9;7,0.8;server_edit_rules;Edit server rules]" or "",

                    "scrollbaroptions[min=0;max=", (11.6 + (has_server_privs and 1.7 or 0) - Y_SIZE)/FACTOR, ";smallstep=", 0.8/FACTOR, ";largestep=", 4.8/FACTOR, ";thumbsize=", 1/FACTOR, "]",
                    "scrollbar[", controller_width - 0.3, ",0.5;0.3,", Y_SIZE, ";vertical;overviewscroll;", context.overviewscroll or 0, "]",
                    "scroll_container[", panel_width, ",0.5;", panel_width - 0.3, ",", Y_SIZE, ";overviewscroll;vertical;", FACTOR, "]",

                    "hypertext[", spacer + 1.8, ",0.4;5.35,1.8;;<global valign=middle color=#000000 font=mono><b>Classrooms</b>\n", minetest.formspec_escape("Create and manage classrooms"), "]",
                    "image_button[", spacer, ",0.5;", button_width, ",", button_height, ";mc_teacher_classrooms.png;classrooms;;false;false]",
                    "hypertext[", spacer + 1.8, ",2.2;5.35,1.8;;<global valign=middle color=#000000 font=mono><b>Map</b>\n", minetest.formspec_escape("Record and share locations"), "]",
                    "image_button[", spacer, ",2.3;", button_width, ",", button_height, ";mc_teacher_map.png;map;;false;false]",
                    "hypertext[", spacer + 1.8, ",4.0;5.35,1.8;;<global valign=middle color=#000000 font=mono><b>Players</b>\n", minetest.formspec_escape("Manage player privileges"), "]",
                    "image_button[", spacer, ",4.1;", button_width, ",", button_height, ";mc_teacher_players.png;players;;false;false]",
                    "hypertext[", spacer + 1.8, ",5.8;5.35,1.8;;<global valign=middle color=#000000 font=mono><b>Moderation</b>\n", minetest.formspec_escape("View player chat logs"), "]",
                    "image_button[", spacer, ",5.9;", button_width, ",", button_height, ";mc_teacher_isometric_crop.png;moderation;;false;false]",
                    "hypertext[", spacer + 1.8, ",7.6;5.35,1.8;;<global valign=middle color=#000000 font=mono><b>Reports</b>\n", minetest.formspec_escape("View player reports"), "]",
                    "image_button[", spacer, ",7.7;", button_width, ",", button_height, ";mc_teacher_isometric_crop.png;reports;;false;false]",
                    "hypertext[", spacer + 1.8, ",9.4;5.35,1.8;;<global valign=middle color=#000000 font=mono><b>Help</b>\n", minetest.formspec_escape("View guides and report issues"), "</style>]",
                    "image_button[", spacer, ",9.5;", button_width, ",", button_height, ";mc_teacher_help.png;help;;false;false]",
                }

                if has_server_privs then
                    table.insert(fs, table.concat({
                        "hypertext[", spacer + 1.8, ",11.2;5.35,1.8;;<global valign=middle color=#000000 font=mono><b>Server</b>\n", minetest.formspec_escape("Manage server settings"), "]",
                        "image_button[", spacer, ",11.3;", button_width, ",", button_height, ";mc_teacher_isometric_crop.png;server;;false;false]",
                    }))
                end
                table.insert(fs, "scroll_container_end[]")

                return fs
            end,
            [mc_teacher.TABS.CLASSROOMS] = function()
                local classroom_list = {}
                local options_height = (context.selected_mode == mc_teacher.MODES.EMPTY and get_options_height(context)) or 1.3
                local FACTOR = 0.1
                context.realm_i_to_id = {}
                context.selected_c_tab = context.selected_c_tab or mc_teacher.CTAB.PUBLIC

                Realm.ScanForPlayerRealms()
                for id, realm in pairs(Realm.realmDict or {}) do
                    if not realm:isDeleted() then
                        local playerCount = tonumber(realm:GetPlayerCount())
                        local cat = realm:getCategory().key

                        if (realm:isHidden() and context.selected_c_tab == mc_teacher.CTAB.HIDDEN) or (not realm:isHidden() and
                        ((context.selected_c_tab == mc_teacher.CTAB.PUBLIC and cat ~= Realm.CAT_MAP[Realm.CAT_KEY.INSTANCED]) or (context.selected_c_tab == mc_teacher.CTAB.PRIVATE and cat == Realm.CAT_MAP[Realm.CAT_KEY.INSTANCED]))) then
                            table.insert(classroom_list, table.concat({minetest.formspec_escape(realm.Name or ""), " (", playerCount, " player", playerCount == 1 and "" or "s", ")"}))
                            table.insert(context.realm_i_to_id, id)
                        end
                    end
                end

                local fs = {
                    "image[0,0;", controller_width, ",0.5;mc_pixel.png^[multiply:#737373]",
                    "image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
                    "tooltip[exit;Exit;#404040;#ffffff]",
                    "hypertext[", text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Classrooms</b></center></style>]",
                    "hypertext[", panel_width + text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Build a Classroom</b></center></style>]",
                    
                    "style_type[textarea;font=mono,bold;textcolor=#000000]",
                    "style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:", mc_core.col.b.default, "]",
                    "button[", panel_width + spacer, ",9;", panel_width - 2*spacer, ",0.8;c_newrealm;Generate classroom]",
                    "tabheader[", spacer, ",1.4;", panel_width - 2*spacer, ",0.5;c_list_header;Public,Private,Hidden;", context.selected_c_tab, ";false;true]",
                }
                
                if #classroom_list == 0 then
                    table.insert(fs, "style[c_teleport,c_edit,c_hide,c_hidden_restore,c_hidden_delete,c_hidden_deleteall;bgimg=mc_pixel.png^[multiply:"..mc_core.col.b.blocked.."]")
                end

                if context.selected_c_tab == mc_teacher.CTAB.HIDDEN then
                    table.insert(fs, table.concat({
                        "textlist[", spacer, ",1.4;", panel_width - 2*spacer, ",", has_server_privs and 6.2 or 7.5, ";classroomlist;", table.concat(classroom_list, ","), ";", context.selected_realm or 1, ";false]",
                        "button[", spacer, ",", has_server_privs and 7.7 or 9, ";3.5,0.8;c_teleport;Teleport]",
                        "button[", spacer + 3.6, ",", has_server_privs and 7.7 or 9, ";3.5,0.8;c_hidden_restore;Restore]",
                    }))
                    if has_server_privs then
                        table.insert(fs, table.concat({
                            "textarea[", text_spacer, ",8.6;", panel_width - 2*text_spacer, ",1;;;Classroom Cleanup]",
                            "button[", spacer, ",9;3.5,0.8;c_hidden_delete;Delete selected]",
                            "button[", spacer + 3.6, ",9;3.5,0.8;c_hidden_deleteall;Delete all]",
                        }))
                    end
                else
                    table.insert(fs, table.concat({
                        "textlist[", spacer, ",1.4;", panel_width - 2*spacer, ",7.5;classroomlist;", table.concat(classroom_list, ","), ";", context.selected_realm or 1, ";false]",
                        "button[", spacer, ",9;2.3,0.8;c_teleport;Teleport]",
                        "button[", spacer + 2.4, ",9;2.3,0.8;c_edit;Edit]",
                        "button[", spacer + 4.8, ",9;2.3,0.8;c_hide;Hide]",
                    }))   
                end
                
                table.insert(fs, table.concat({
                    "style_type[field;font=mono;textcolor=#ffffff]",
                    "scrollbaroptions[min=0;max=", (options_height - 0.7)/FACTOR, ";smallstep=", 0.6/FACTOR, ";largestep=", 3.6/FACTOR, ";thumbsize=", 0.6/FACTOR, "]",
                    "scrollbar[", controller_width - 0.3, ",1;0.3,", controller_height - 2.5, ";vertical;class_opt_scroll;", context.class_opt_scroll or 0, "]",
                    "scroll_container[", panel_width, ",1;", panel_width - 0.3, ",", controller_height - 2.5, ";class_opt_scroll;vertical;", FACTOR, "]",

                    "textarea[", text_spacer, ",0;", panel_width - 2*text_spacer, ",1;;;Name]",
                    "field[", spacer, ",0.4;7.1,0.8;realmname;;", context.realmname or "", "]",
                    "field_close_on_enter[realmname;false]",
                    "textarea[", text_spacer, ",1.25;3.6,1;;;Type]",
                    "dropdown[", spacer, ",1.7;3.5,0.8;realmcategory;Default,Spawn,Classroom,Private" or "", ";", context.selected_realm_type or 1, ";true]",
                    "textarea[", text_spacer + 3.6, ",1.25;3.6,1;;;Generation]",
                    "dropdown[", spacer + 3.6, ",1.7;3.5,0.8;mode;Empty World,Schematic,Digital Twin" or "", ";", context.selected_mode or 1, ";true]",
                }))

                if context.selected_mode == mc_teacher.MODES.EMPTY then
                    table.insert(fs, table.concat({
                        "textarea[", text_spacer, ",2.6;", panel_width - 2*text_spacer, ",1;;;Classroom Size]",
                        "textarea[", text_spacer, ",3.2;1,1;;;X =]",
                        "textarea[", text_spacer + 2.4, ",3.2;1,1;;;Y =]",
                        "textarea[", text_spacer + 4.8, ",3.2;1,1;;;Z =]",
                        "field[", spacer + 0.9, ",3;1.3,0.8;realm_x_size;;", context.realm_x or 80, "]",
                        "field[", spacer + 3.3, ",3;1.3,0.8;realm_y_size;;", context.realm_y or 80, "]",
                        "field[", spacer + 5.7, ",3;1.3,0.8;realm_z_size;;", context.realm_z or 80, "]",
                        "textarea[", text_spacer, ",3.9;3.6,1;;;Terrain]",
                        "textarea[", text_spacer + 3.6, ",3.9;3.6,1;;;Foliage]",
                        "dropdown[", spacer, ",4.3;3.5,0.8;realm_generator;None,Version 1,Version 2,DNR;", context.realm_gen or 1, ";true]",
                        "dropdown[", spacer + 3.6, ",4.3;3.5,0.8;realm_decorator;None,Version 1,Version 2,Biomegen;", context.realm_dec or 1, ";true]",
                    
                        "field_close_on_enter[realm_x_size;false]",
                        "field_close_on_enter[realm_y_size;false]",
                        "field_close_on_enter[realm_z_size;false]",
                    }))

                    if options_height >= 3.9 then
                        table.insert(fs, table.concat({
                            "textarea[", text_spacer, ",5.2;3.6,1;;;Seed]",
                            "textarea[", text_spacer + 3.6, ",5.2;3.6,1;;;Sea Level]",
                            "field[", spacer, ",5.6;3.5,0.8;realm_seed;;", minetest.formspec_escape(context.realm_seed) or "", "]",
                            "field[", spacer + 3.6, ",5.6;3.5,0.8;realm_sealevel;;", minetest.formspec_escape(context.realm_sealevel) or "", "]",

                            "field_close_on_enter[realm_seed;false]",
                            "field_close_on_enter[realm_sealevel;false]",
                        }))
                    end
                    if options_height >= 5.2 then
                        local raw_biomes = biomegen.get_biomes()
                        context.i_to_biome = {}
                        for biome,_ in pairs(raw_biomes) do
                            table.insert(context.i_to_biome, biome)
                        end
                        table.sort(context.i_to_biome)
                        context.realm_biome = context.realm_biome or 1

                        table.insert(fs, table.concat({
                            "textarea[", text_spacer, ",6.5;3.6,1;;;Biome]",
                            "textarea[", text_spacer + 3.6, ",6.5;3.6,1;;;Chill Coefficient]",
                            "dropdown[", spacer, ",6.9;3.5,0.8;realm_biome;", table.concat(context.i_to_biome, ","), ";", context.realm_biome, ";true]",
                            "field[", spacer + 3.6, ",6.9;3.5,0.8;realm_chill;;", minetest.formspec_escape(context.realm_chill) or "", "]",

                            "field_close_on_enter[realm_chill;false]",
                        }))
                    end
                elseif context.selected_mode == mc_teacher.MODES.SCHEMATIC then
                    local schematics = {}
                    local name_to_i = {}
                    local ctr = 1
                    for name, path in pairs(schematicManager.schematics) do
                        if ctr == 1 and not context.selected_schematic then
                            context.selected_schematic = name
                        end
                        table.insert(schematics, name)
                        name_to_i[name] = ctr
                        ctr = ctr + 1
                    end
                    context.name_to_i = name_to_i

                    table.insert(fs, table.concat({
                        "textarea[", text_spacer, ",2.6;", panel_width - 2*text_spacer, ",1;;;Schematic]",
                        "dropdown[", spacer, ",3;", panel_width - 2*spacer, ",0.8;schematic;", table.concat(schematics, ","), ";", context.name_to_i[context.selected_schematic] or 1, ";false]",
                    }))
                elseif context.selected_mode == mc_teacher.MODES.TWIN then
                    local twins = {}
                    local name_to_i = {}
                    local ctr = 1
                    for name, path in pairs(realterrainManager.dems) do
                        if ctr == 1 and not context.selected_dem then
                            context.selected_dem = name
                        end
                        table.insert(twins, name)
                        name_to_i[name] = ctr
                        ctr = ctr + 1
                    end
                    context.name_to_i = name_to_i

                    table.insert(fs, table.concat({
                        "textarea[", text_spacer, ",2.6;", panel_width - 2*text_spacer, ",1;;;Digital Twin World]",
                        "dropdown[", spacer, ",3;", panel_width - 2*spacer, ",0.8;realterrain;", table.concat(twins, ","), ";", context.name_to_i[context.selected_dem] or 1, ";false]",
                    }))
                else
                    table.insert(fs, table.concat({
                        "textarea[", text_spacer, ",2.6;", panel_width - 2*text_spacer, ",1.2;;;Select a generation mode for more options!]",
                    }))
                end

                table.insert(fs, table.concat({
                    "container[0,", 2.6 + options_height, "]",
                    "textarea[", text_spacer, ",0;", panel_width - 2*text_spacer, ",1;;;Default Privileges]",
                    "style_type[textarea;font=mono]",
                    "textarea[", text_spacer + 1.3, ",0.8;1.9,1;;;interact]",
                    "textarea[", text_spacer + 1.3, ",1.2;1.9,1;;;shout]",
                    "textarea[", text_spacer + 1.3, ",1.6;1.9,1;;;fast]",
                    "textarea[", text_spacer + 4.9, ",0.8;1.9,1;;;fly]",
                    "textarea[", text_spacer + 4.9, ",1.2;1.9,1;;;noclip]",
                    "textarea[", text_spacer + 4.9, ",1.6;1.9,1;;;give]",
                    "image[", text_spacer, ",0.4;0.4,0.4;mc_teacher_check.png]",
                    "image[", text_spacer + 0.4, ",0.4;0.4,0.4;mc_teacher_ignore.png]",
                    "image[", text_spacer + 0.8, ",0.4;0.4,0.4;mc_teacher_delete.png]",
                    "image[", text_spacer + 3.6, ",0.4;0.4,0.4;mc_teacher_check.png]",
                    "image[", text_spacer + 4.0, ",0.4;0.4,0.4;mc_teacher_ignore.png]",
                    "image[", text_spacer + 4.4, ",0.4;0.4,0.4;mc_teacher_delete.png]",
                    "tooltip[", text_spacer, ",0.4;0.4,0.4;ALLOW: Privilege will be granted\n(does NOT override universal privileges);#404040;#ffffff]",
                    "tooltip[", text_spacer + 0.4, ",0.4;0.4,0.4;IGNORE: Privilege will be unaffected;#404040;#ffffff]",
                    "tooltip[", text_spacer + 0.8, ",0.4;0.4,0.4;DENY: Privilege will not be granted\n(overrides universal privileges);#404040;#ffffff]",
                    "tooltip[", text_spacer + 3.6, ",0.4;0.4,0.4;ALLOW: Privilege will be granted\n(does NOT override universal privileges);#404040;#ffffff]",
                    "tooltip[", text_spacer + 4.0, ",0.4;0.4,0.4;IGNORE: Privilege will be unaffected;#404040;#ffffff]",
                    "tooltip[", text_spacer + 4.4, ",0.4;0.4,0.4;DENY: Privilege will not be granted\n(overrides universal privileges);#404040;#ffffff]",

                    "checkbox[", spacer, ",1.0;allowpriv_interact;;",        tostring(context.selected_privs.interact == true), "]",
                    "checkbox[", spacer, ",1.4;allowpriv_shout;;",           tostring(context.selected_privs.shout    == true), "]",
                    "checkbox[", spacer, ",1.8;allowpriv_fast;;",            tostring(context.selected_privs.fast     == true), "]",
                    "checkbox[", spacer + 0.4, ",1.0;ignorepriv_interact;;", tostring(context.selected_privs.interact == "nil"), "]",
                    "checkbox[", spacer + 0.4, ",1.4;ignorepriv_shout;;",    tostring(context.selected_privs.shout    == "nil"), "]",
                    "checkbox[", spacer + 0.4, ",1.8;ignorepriv_fast;;",     tostring(context.selected_privs.fast     == "nil"), "]",
                    "checkbox[", spacer + 0.8, ",1.0;denypriv_interact;;",   tostring(context.selected_privs.interact == false), "]",
                    "checkbox[", spacer + 0.8, ",1.4;denypriv_shout;;",      tostring(context.selected_privs.shout    == false), "]",
                    "checkbox[", spacer + 0.8, ",1.8;denypriv_fast;;",       tostring(context.selected_privs.fast     == false), "]",
                    "checkbox[", spacer + 3.6, ",1.0;allowpriv_fly;;",       tostring(context.selected_privs.fly      == true), "]",
                    "checkbox[", spacer + 3.6, ",1.4;allowpriv_noclip;;",    tostring(context.selected_privs.noclip   == true), "]",
                    "checkbox[", spacer + 3.6, ",1.8;allowpriv_give;;",      tostring(context.selected_privs.give     == true), "]",
                    "checkbox[", spacer + 4.0, ",1.0;ignorepriv_fly;;",      tostring(context.selected_privs.fly      == "nil"), "]",
                    "checkbox[", spacer + 4.0, ",1.4;ignorepriv_noclip;;",   tostring(context.selected_privs.noclip   == "nil"), "]",
                    "checkbox[", spacer + 4.0, ",1.8;ignorepriv_give;;",     tostring(context.selected_privs.give     == "nil"), "]",
                    "checkbox[", spacer + 4.4, ",1.0;denypriv_fly;;",        tostring(context.selected_privs.fly      == false), "]",
                    "checkbox[", spacer + 4.4, ",1.4;denypriv_noclip;;",     tostring(context.selected_privs.noclip   == false), "]",
                    "checkbox[", spacer + 4.4, ",1.8;denypriv_give;;",       tostring(context.selected_privs.give     == false), "]",
                    "container_end[]",

                    "style_type[textarea;font=mono,bold]",
                    "textarea[", text_spacer, ",", 4.7 + options_height, ";", panel_width - 2*text_spacer, ",1;;;Background Music]",
                    "dropdown[", spacer, ",", 5.1 + options_height, ";", panel_width - 2*spacer, ",0.8;bgmusic;None;1;false]",
                    "textarea[", text_spacer, ",", 6 + options_height, ";", panel_width - 2*text_spacer, ",1;;;Skybox]",
                    "dropdown[", spacer, ",", 6.4 + options_height, ";", panel_width - 2*spacer, ",0.8;skybox;Default;1;false]",
                    "scroll_container_end[]",
                }))

                return fs
                -- TODO: Background Music and skyboxes
                -- method: local backgroundSound = realm:get_data("background_sound")]]
            end,
            [mc_teacher.TABS.MAP] = function()
                local map_x = spacer + 0.025
                local map_y = 1.425
                local fs = {
                    "image[0,0;", controller_width, ",0.5;mc_pixel.png^[multiply:#737373]",
                    "image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
                    "tooltip[exit;Exit;#404040;#ffffff]",
                    "hypertext[", text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Map</b></center></style>]",
                    "hypertext[", panel_width + text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Coordinates</b></center></style>]",
                    "style_type[textarea;font=mono,bold;textcolor=#000000]",
                    "textarea[", text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Surrounding Area]",
                    "image[", map_x - 0.025, ",", map_y - 0.025, ";7.1,7.1;mc_pixel.png^[multiply:#000000]",
                    "image[", map_x, ",", map_y, ";7.05,7.05;mc_pixel.png^[multiply:#808080]",
                }
                
                local bounds = {xmin = -24, xmax = 24, zmin = -24, zmax = 24}
                local mapar = mc_mapper.map_handler(player, bounds)
                for i = 1, bounds.xmax - bounds.xmin - 1, 1 do
                    for j = 1, bounds.zmax - bounds.zmin - 1, 1 do
                        if mapar[i][j].im ~= nil then
                            -- The following for colorbrewer integration
                            if mapar[i][j].pa then
                                local y_im = math.ceil(mapar[i][j].p2/16)
                                local x_im = mapar[i][j].p2-((y_im-1)*16)
                                mapar[i][j].im = mapar[i][j].pa.."_palette.png\\^[sheet\\:16x16:"..tostring(x_im).."\\,"..tostring(y_im) -- double backslash required to first escape lua and then escape the API
                            end
                            if mapar[i][j].y ~= mapar[i][j+1].y then mapar[i][j].im = mapar[i][j].im .. "^(mc_mapper_blockb.png^[transformR180)" end
                            if mapar[i][j].y ~= mapar[i][j-1].y then mapar[i][j].im = mapar[i][j].im .. "^(mc_mapper_blockb.png)" end
                            if mapar[i][j].y ~= mapar[i-1][j].y then mapar[i][j].im = mapar[i][j].im .. "^(mc_mapper_blockb.png^[transformR270)" end
                            if mapar[i][j].y ~= mapar[i+1][j].y then mapar[i][j].im = mapar[i][j].im .. "^(mc_mapper_blockb.png^[transformR90)" end
                            table.insert(fs, table.concat({
                                "image[", map_x + 0.15*(i - 1), ",", map_y + 0.15*(bounds.zmax - bounds.zmin - j - 1),
                                ";0.15,0.15;", mapar[i][j].im, "]";
                            }))
                        end
                    end
                end

                local yaw = player:get_look_yaw()
                local rotate = 0
                if yaw ~= nil then
                    -- Find rotation and texture based on yaw.
                    yaw = math.fmod(mc_mapper.round_to_texture_multiple(math.deg(yaw)), 360)
                    if yaw < 90 then
                        rotate = 90
                    elseif yaw < 180 then
                        rotate = 180
                    elseif yaw < 270 then
                        rotate = 270
                    else
                        rotate = 0
                    end
                    yaw = math.fmod(yaw, 90)
                end
                local pos = player:get_pos()
                local round_px, round_pz = math.round(pos.x), math.round(pos.z)

                table.insert(fs, table.concat({
                    "image[", 3.95 + (pos.x - round_px)*0.15, ",", 4.75 - (pos.z - round_pz)*0.15,
                    ";0.4,0.4;mc_mapper_d", yaw, ".png^[transformFY", rotate ~= 0 and ("R"..rotate) or "", "]",
                    "textarea[", text_spacer, ",8.6;", panel_width - 2*text_spacer, ",1;;;Coordinate and Elevation Display]",
                    "style_type[button,image_button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:", mc_core.col.b.default, "]",
                    "button[", spacer, ",9;1.7,0.8;utmcoords;UTM]",
                    "button[", spacer + 1.8, ",9;1.7,0.8;latloncoords;Lat/Lon]",
                    "button[", spacer + 3.6, ",9;1.7,0.8;classroomcoords;Local]",
                    "button[", spacer + 5.4, ",9;1.7,0.8;coordsoff;Off]",
                    "textarea[", panel_width + text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Saved Coordinates]",
                }))

                local coord_list = get_saved_coords(player)
                table.insert(fs, table.concat({
                    "textlist[", panel_width + spacer, ",1.4;", panel_width - 2*spacer, ",4.8;coordlist;", coord_list and #coord_list > 0 and table.concat(coord_list, ",") or "No coordinates saved!", ";", context.selected_coord or 1, ";false]",
                    coord_list and #coord_list > 0 and "" or "style_type[image_button;bgimg=mc_pixel.png^[multiply:", mc_core.col.b.blocked, "]",
                    "image_button[", panel_width + spacer, ",6.3;1.1,1.1;mc_teacher_teleport.png;", coord_list and #coord_list > 0 and "go" or "blocked", ";;false;false]",
                    "image_button[", panel_width + spacer + 1.2, ",6.3;1.1,1.1;mc_teacher_teleport_all.png;", coord_list and #coord_list > 0 and "go_all" or "blocked", ";;false;false]",
                    "image_button[", panel_width + spacer + 2.4, ",6.3;1.1,1.1;mc_teacher_share.png;", coord_list and #coord_list > 0 and "share" or "blocked", ";;false;false]",
                    "image_button[", panel_width + spacer + 3.6, ",6.3;1.1,1.1;mc_teacher_mark.png;", coord_list and #coord_list > 0 and "mark" or "blocked", ";;false;false]",
                    "image_button[", panel_width + spacer + 4.8, ",6.3;1.1,1.1;mc_teacher_delete.png;", coord_list and #coord_list > 0 and "delete" or "blocked", ";;false;false]",
                    "image_button[", panel_width + spacer + 6.0, ",6.3;1.1,1.1;mc_teacher_clear.png;", coord_list and #coord_list > 0 and "clear" or "blocked", ";;false;false]",
                    
                    coord_list and #coord_list > 0 and "" or "style_type[button;bgimg=mc_pixel.png^[multiply:", mc_core.col.b.default, "]",
                    "textarea[", panel_width + text_spacer, ",8.5;", panel_width - 2*text_spacer, ",1;;;Save current coordinates]",
                    "style_type[textarea;font=mono]",
                    "textarea[", panel_width + text_spacer, ",7.6;", panel_width - 2*text_spacer, ",1;;;SELECTED\nLocal: (X, Y, Z)]",
                    "textarea[", panel_width + spacer, ",8.9;6.2,0.9;note;;]",
                    "style_type[image_button;bgimg=mc_pixel.png^[multiply:", mc_core.col.b.default, "]",
                    "image_button[15.1,8.9;0.9,0.9;blank.png;record;Save;false;false]", --mc_teacher_save.png
                    
                    "tooltip[utmcoords;Displays real-world UTM coordinates;#404040;#ffffff]",
                    "tooltip[latloncoords;Displays real-world latitude and longitude;#404040;#ffffff]",
                    "tooltip[classroomcoords;Displays in-game coordinates, relative to the classroom;#404040;#ffffff]",
                    "tooltip[coordsoff;Disables coordinate display;#404040;#ffffff]",
                    "tooltip[go;Teleport to location;#404040;#ffffff]",
                    "tooltip[go_all;Teleport all players to location;#404040;#ffffff]",
                    "tooltip[share;Share location in chat;#404040;#ffffff]",
                    "tooltip[mark;Place marker in world;#404040;#ffffff]",
                    "tooltip[delete;Delete location;#404040;#ffffff]",
                    "tooltip[clear;Clear all saved locations;#404040;#ffffff]",
                    "tooltip[note;Add a note here!;#404040;#ffffff]",
                    "style_type[image_button;bgimg=blank.png]",
                }))

                return fs
            end,
            [mc_teacher.TABS.PLAYERS] = function()
                context.selected_p_tab = context.selected_p_tab or "1"
                context.selected_p_player = context.selected_p_player or 1
                context.selected_p_mode = context.selected_p_mode or mc_teacher.PMODE.SELECTED

                if not context.p_list then
                    context.p_list = {}
                    if context.selected_p_tab == "1" then
                        for student,_ in pairs(mc_teacher.students) do
                            table.insert(context.p_list, student)
                        end
                    elseif context.selected_p_tab == "2" then
                        for teacher,_ in pairs(mc_teacher.teachers) do
                            table.insert(context.p_list, teacher)
                        end
                    elseif context.selected_p_tab == "3" then
                        local this_realm = Realm.GetRealmFromPlayer(player)
                        if this_realm then
                            for _,p in pairs(this_realm:GetPlayersAsArray() or {}) do
                                local p_obj = minetest.get_player_by_name(p)
                                if p_obj and p_obj:is_player() then
                                    table.insert(context.p_list, p)
                                end
                            end
                        end
                    end
                end
                local p_priv_list = {}
                for _,p in ipairs(context.p_list) do
                    local p_obj = minetest.get_player_by_name(p)
                    table.insert(p_priv_list, p_obj and get_privs(p_obj) or {})
                end
                local selected_player = context.p_list[context.selected_p_player]

                local player_privs = {interact = true, shout = true, fast = true, fly = true, noclip = true, give = true}
                if selected_player then
                    local _,missing = minetest.check_player_privs(selected_player, player_privs)
                    if type(missing) == "string" then missing = {missing} end

                    for _,priv in pairs(missing or {}) do
                        player_privs[priv] = false
                    end
                else
                    player_privs = {}
                end
                local priv_b_state = get_priv_button_states(context.p_list, p_priv_list)

                local img = {
                    shout = "mc_teacher_shout",
                    interact = "mc_teacher_interact",
                    fast = "mc_teacher_fast",
                    fly = "mc_teacher_fly",
                    noclip = "mc_teacher_noclip",
                    give = "mc_teacher_give",
                    slash = "mc_teacher_slash",
                    e = ".png",
                    r = "^[resize:25x25",
                    o = "^[opacity:31",
                }
                local fs = {
                    "image[0,0;", controller_width, ",0.5;mc_pixel.png^[multiply:#737373]",
                    "image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
                    "tooltip[exit;Exit;#404040;#ffffff]",
                    "hypertext[", text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Players</b></center></style>]",
                    "hypertext[", panel_width + text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Manage Players</b></center></style>]",
                    "style_type[textarea;font=mono,bold;textcolor=#000000]",
                    "style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:", mc_core.col.b.default, "]",
                    -- TODO: re-implement groups
                    "style[p_group_new,p_group_edit,p_group_delete;bgimg=mc_pixel.png^[multiply:", mc_core.col.b.blocked, "]",
                    -- TODO: re-impelment remaining actions
                    "style[p_audience,p_timeout;bgimg=mc_pixel.png^[multiply:", mc_core.col.b.blocked, "]",
                    "style[p_mode_", context.selected_p_mode == mc_teacher.PMODE.ALL and "all" or context.selected_p_mode == mc_teacher.PMODE.TAB and "tab" or "selected", ";bgimg=mc_pixel.png^[multiply:", mc_core.col.b.selected, "]",
                    context.selected_p_mode ~= mc_teacher.PMODE.SELECTED and "style[p_teleport;bgimg=mc_pixel.png^[multiply:"..mc_core.col.b.orange.."]" or "",
                    
                    "tabheader[", spacer, ",1.4;", panel_width - 2*spacer - 0.35, ",0.5;p_list_header;Students,Teachers,Classroom;", context.selected_p_tab, ";false;true]",
                    "tablecolumns[image,align=center,padding=0.1,tooltip=shout,",    "0=", img.shout,    img.e, img.r, img.o, ",1=", img.shout,    img.e, img.r, ",2=", img.shout,    img.e, img.r, img.o, "^(", img.slash, img.e, img.r, "),3=", img.shout,    "_o", img.e, img.r, ";",
                                 "image,align=center,padding=0.1,tooltip=interact,", "0=", img.interact, img.e, img.r, img.o, ",1=", img.interact, img.e, img.r, ",2=", img.interact, img.e, img.r, img.o, "^(", img.slash, img.e, img.r, "),3=", img.interact, "_o", img.e, img.r, ";",
                                 "image,align=center,padding=0.1,tooltip=fast,",     "0=", img.fast,     img.e, img.r, img.o, ",1=", img.fast,     img.e, img.r, ",2=", img.fast,     img.e, img.r, img.o, "^(", img.slash, img.e, img.r, "),3=", img.fast,     "_o", img.e, img.r, ",4=mc_teacher_freeze", img.e, img.r, ";",
                                 "image,align=center,padding=0.1,tooltip=fly,",      "0=", img.fly,      img.e, img.r, img.o, ",1=", img.fly,      img.e, img.r, ",2=", img.fly,      img.e, img.r, img.o, "^(", img.slash, img.e, img.r, "),3=", img.fly,      "_o", img.e, img.r, ";",
                                 "image,align=center,padding=0.1,tooltip=noclip,",   "0=", img.noclip,   img.e, img.r, img.o, ",1=", img.noclip,   img.e, img.r, ",2=", img.noclip,   img.e, img.r, img.o, "^(", img.slash, img.e, img.r, "),3=", img.noclip,   "_o", img.e, img.r, ";",
                                 "image,align=center,padding=0.1,tooltip=give,",     "0=", img.give,     img.e, img.r, img.o, ",1=", img.give,     img.e, img.r, ",2=", img.give,     img.e, img.r, img.o, "^(", img.slash, img.e, img.r, "),3=", img.give,     "_o", img.e, img.r, ";",
                                 "text]",
                    "table[", spacer, ",1.4;", panel_width - 2*spacer, ",7.5;p_list;", generate_player_table(context.p_list, p_priv_list), ";", context.selected_p_player, "]",
                    
                    "button[", panel_width - spacer - 0.45, ",0.95;0.45,0.45;p_group_new;+]",
                    "button[", spacer, ",9;3.5,0.8;p_group_edit;Edit group]",
                    "button[", spacer + 3.6, ",9;3.5,0.8;p_group_delete;Delete group]",

                    "textarea[", panel_width + text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Action Mode]",
                    "button[", panel_width + spacer, ",1.4;2.3,0.8;p_mode_selected;Selected]",
                    "button[", panel_width + spacer + 2.4, ",1.4;2.3,0.8;p_mode_tab;Tab]",
                    "button[", panel_width + spacer + 4.8, ",1.4;2.3,0.8;p_mode_all;All]",

                    "textarea[", panel_width + text_spacer, ",2.3;", panel_width - 2*text_spacer, ",1;;;Privileges in this Classroom]",
                    "style_type[textarea;font=mono]",
                    "textarea[", panel_width + text_spacer + 1.3, ",3.1;2.3,1;;;interact]",
                    "textarea[", panel_width + text_spacer + 1.3, ",3.5;2.3,1;;;shout]",
                    "textarea[", panel_width + text_spacer + 1.3, ",3.9;2.3,1;;;fast]",
                    "textarea[", panel_width + text_spacer + 4.9, ",3.1;2.3,1;;;fly]",
                    "textarea[", panel_width + text_spacer + 4.9, ",3.5;2.3,1;;;noclip]",
                    "textarea[", panel_width + text_spacer + 4.9, ",3.9;2.3,1;;;give]",
                    "style_type[textarea;font=mono,bold]",
                    "image[", panel_width + text_spacer, ",2.7;0.4,0.4;mc_teacher_check.png]",
                    "image[", panel_width + text_spacer + 0.4, ",2.7;0.4,0.4;mc_teacher_ignore.png]",
                    "image[", panel_width + text_spacer + 0.8, ",2.7;0.4,0.4;mc_teacher_delete.png]",
                    "image[", panel_width + text_spacer + 3.6, ",2.7;0.4,0.4;mc_teacher_check.png]",
                    "image[", panel_width + text_spacer + 4.0, ",2.7;0.4,0.4;mc_teacher_ignore.png]",
                    "image[", panel_width + text_spacer + 4.4, ",2.7;0.4,0.4;mc_teacher_delete.png]",
                }

                -- TODO: reimplement images behind checkboxes
                --[[if player_privs.interact then
                    table.insert(fs, table.concat({"image[", panel_width + spacer - 0.05, ",2.85;0.4,0.4;mc_pixel.png^[multiply:#59a63a]"}))
                end
                if player_privs.shout then
                    table.insert(fs, table.concat({"image[", panel_width + spacer - 0.05, ",3.25;0.4,0.4;mc_pixel.png^[multiply:#59a63a]"}))
                end
                if player_privs.fast then
                    table.insert(fs, table.concat({"image[", panel_width + spacer + 2.35, ",2.85;0.4,0.4;mc_pixel.png^[multiply:#59a63a]"}))
                end
                if player_privs.fly then
                    table.insert(fs, table.concat({"image[", panel_width + spacer + 2.35, ",3.25;0.4,0.4;mc_pixel.png^[multiply:#59a63a]"}))
                end
                if player_privs.noclip then
                    table.insert(fs, table.concat({"image[", panel_width + spacer + 4.75, ",2.85;0.4,0.4;mc_pixel.png^[multiply:#59a63a]"}))
                end
                if player_privs.give then
                    table.insert(fs, table.concat({"image[", panel_width + spacer + 4.75, ",3.25;0.4,0.4;mc_pixel.png^[multiply:#59a63a]"}))
                end]]
                
                table.insert(fs, table.concat({
                    "checkbox[", panel_width + spacer, ",3.3;allowpriv_interact;;", tostring(context.selected_privs.interact == true), "]",
                    "checkbox[", panel_width + spacer, ",3.7;allowpriv_shout;;", tostring(context.selected_privs.shout == true), "]",
                    "checkbox[", panel_width + spacer, ",4.1;allowpriv_fast;;", tostring(context.selected_privs.fast == true), "]",
                    "checkbox[", panel_width + spacer + 0.4, ",3.3;ignorepriv_interact;;", tostring(context.selected_privs.interact == "nil"), "]",
                    "checkbox[", panel_width + spacer + 0.4, ",3.7;ignorepriv_shout;;", tostring(context.selected_privs.shout == "nil"), "]",
                    "checkbox[", panel_width + spacer + 0.4, ",4.1;ignorepriv_fast;;", tostring(context.selected_privs.fast == "nil"), "]",
                    "checkbox[", panel_width + spacer + 0.8, ",3.3;denypriv_interact;;", tostring(context.selected_privs.interact == false), "]",
                    "checkbox[", panel_width + spacer + 0.8, ",3.7;denypriv_shout;;", tostring(context.selected_privs.shout == false), "]",
                    "checkbox[", panel_width + spacer + 0.8, ",4.1;denypriv_fast;;", tostring(context.selected_privs.fast == false), "]",
                    "checkbox[", panel_width + spacer + 3.6, ",3.3;allowpriv_fly;;", tostring(context.selected_privs.fly == true), "]",
                    "checkbox[", panel_width + spacer + 3.6, ",3.7;allowpriv_noclip;;", tostring(context.selected_privs.noclip == true), "]",
                    "checkbox[", panel_width + spacer + 3.6, ",4.1;allowpriv_give;;", tostring(context.selected_privs.give == true), "]",
                    "checkbox[", panel_width + spacer + 4.0, ",3.3;ignorepriv_fly;;", tostring(context.selected_privs.fly == "nil"), "]",
                    "checkbox[", panel_width + spacer + 4.0, ",3.7;ignorepriv_noclip;;", tostring(context.selected_privs.noclip == "nil"), "]",
                    "checkbox[", panel_width + spacer + 4.0, ",4.1;ignorepriv_give;;", tostring(context.selected_privs.give == "nil"), "]",
                    "checkbox[", panel_width + spacer + 4.4, ",3.3;denypriv_fly;;", tostring(context.selected_privs.fly == false), "]",
                    "checkbox[", panel_width + spacer + 4.4, ",3.7;denypriv_noclip;;", tostring(context.selected_privs.noclip == false), "]",
                    "checkbox[", panel_width + spacer + 4.4, ",4.1;denypriv_give;;", tostring(context.selected_privs.give == false), "]",
                    "button[", panel_width + spacer, ",4.4;3.5,0.8;p_priv_update;Update privs]",
                    "button[", panel_width + spacer + 3.6, ",4.4;3.5,0.8;p_priv_reset;Reset privs]",

                    "textarea[", panel_width + text_spacer, ",5.3;", panel_width - 2*text_spacer, ",1;;;Actions]",
                    "button[", panel_width + spacer, ",5.7;2.3,0.8;p_teleport;Teleport]",
                    "button[", panel_width + spacer + 2.4, ",5.7;2.3,0.8;p_bring;Bring]",
                    "button[", panel_width + spacer + 4.8, ",5.7;2.3,0.8;p_audience;Audience]",
                    "button[", panel_width + spacer + 2.4, ",7.5;2.3,0.8;p_kick;Kick]",
                    "button[", panel_width + spacer + 4.8, ",7.5;2.3,0.8;p_ban;Ban]",
                    create_state_button(panel_width + spacer, 6.6, 2.3, 0.8, {[true] = "p_mute", [false] = "p_unmute"},
                    {[true] = "Mute", [false] = "Unmute", default = "Mute"}, priv_b_state.shout),
                    create_state_button(panel_width + spacer + 2.4, 6.6, 2.3, 0.8, {[true] = "p_deactivate", [false] = "p_reactivate"},
                    {[true] = "Deactivate", [false] = "Reactivate", default = "Activate"}, priv_b_state.interact),
                    create_state_button(panel_width + spacer + 4.8, 6.6, 2.3, 0.8, {[true] = "p_freeze", [false] = "p_unfreeze"},
                    {[true] = "Freeze", [false] = "Unfreeze", default = "Freeze"}, priv_b_state.frozen),
                    "button[", panel_width + spacer, ",7.5;2.3,0.8;p_timeout;Timeout]",
                    
                    "textarea[", panel_width + text_spacer, ",8.4;", panel_width - 2*text_spacer, ",1;;;Server Role]",
                }))

                if not has_server_privs then
                    table.insert(fs, "style[blocked_role_teacher,blocked_role_admin;bgimg=mc_pixel.png^[multiply:"..mc_core.col.b.blocked.."]")
                end
                if selected_player then
                    table.insert(fs, "style["..role_to_fs_elem(mc_teacher.get_server_role(selected_player), has_server_privs)..";bgimg=mc_pixel.png^[multiply:"..mc_core.col.b.selected.."]")
                end
                table.insert(fs, table.concat({
                    "image[", panel_width + spacer, ",8.8;3.5,1;mc_pixel.png^[multiply:#acabff]",
                    "image[", panel_width + spacer + 3.6, ",8.8;3.5,1;mc_pixel.png^[multiply:#f5c987]", --#ffd699
                    "button[", panel_width + spacer + 0.1, ",8.9;1.6,0.8;p_role_none;None]",
                    "button[", panel_width + spacer + 1.8, ",8.9;1.6,0.8;p_role_student;Student]",
                    "button[", panel_width + spacer + 3.7, ",8.9;1.6,0.8;", has_server_privs and "p_role_teacher" or "blocked_role_teacher", ";Teacher]",
                    "button[", panel_width + spacer + 5.4, ",8.9;1.6,0.8;", has_server_privs and "p_role_admin" or "blocked_role_admin", ";Admin]",
                    
                    "tooltip[p_mode_selected;The selected player;#404040;#ffffff]",
                    "tooltip[p_mode_tab;All players in the selected tab;#404040;#ffffff]",
                    "tooltip[p_mode_all;All online players;#404040;#ffffff]",
                    "tooltip[p_role_none;No privileges\nListed as a student\nCan not use classroom tools;#404040;#ffffff]",
                    "tooltip[p_role_student;Privileges: student\nListed as a student\nCan use student tools;#404040;#ffffff]",
                    "tooltip[", has_server_privs and "p_role_teacher" or "blocked_role_teacher", ";Privileges: student, teacher\nListed as a teacher\nCan use student and teacher tools;#404040;#ffffff]",
                    "tooltip[", has_server_privs and "p_role_admin" or "blocked_role_admin", ";Privileges: student, teacher, server\nListed as a teacher\nCan use student, teacher, and administrator tools;#404040;#ffffff]",
                    
                    "tooltip[", panel_width + text_spacer, ",2.7;0.4,0.4;ALLOW: Privilege will be granted\n(overrides universal privileges);#404040;#ffffff]",
                    "tooltip[", panel_width + text_spacer + 0.4, ",2.7;0.4,0.4;IGNORE: Privilege will be unaffected;#404040;#ffffff]",
                    "tooltip[", panel_width + text_spacer + 0.8, ",2.7;0.4,0.4;DENY: Privilege will not be granted\n(overrides universal privileges);#404040;#ffffff]",
                    "tooltip[", panel_width + text_spacer + 3.6, ",2.7;0.4,0.4;ALLOW: Privilege will be granted\n(overrides universal privileges);#404040;#ffffff]",
                    "tooltip[", panel_width + text_spacer + 4.0, ",2.7;0.4,0.4;IGNORE: Privilege will be unaffected;#404040;#ffffff]",
                    "tooltip[", panel_width + text_spacer + 4.4, ",2.7;0.4,0.4;DENY: Privilege will not be granted\n(overrides universal privileges);#404040;#ffffff]",
                    "tooltip[p_mute;Revokes the shout privilege globally;#404040;#ffffff]",
                    "tooltip[p_unmute;Re-grants the shout privilege globally;#404040;#ffffff]",
                    "tooltip[p_deactivate;Revokes the interact privilege globally;#404040;#ffffff]",
                    "tooltip[p_reactivate;Re-grants the interact privilege globally;#404040;#ffffff]",
                    "tooltip[p_freeze;Disables player movement;#404040;#ffffff]",
                    "tooltip[p_unfreeze;Re-enables player movement;#404040;#ffffff]",
                    "tooltip[p_teleport;Teleports you to the selected player;#404040;#ffffff]",
                    "tooltip[p_bring;Teleports players to your position;#404040;#ffffff]",
                    "tooltip[p_audience;Teleports players to you, standing in a semicircle facing you;#404040;#ffffff]",
                    "tooltip[p_timeout;Teleports players to spawn and\nprevents them from joining classrooms;#404040;#ffffff]",
                    "tooltip[p_untimeout;Allows players to join classrooms again;#404040;#ffffff]",
                }))

                return fs
            end,
            [mc_teacher.TABS.MODERATION] = function()
                local fs = {
                    "image[0,0;", controller_width, ",0.5;mc_pixel.png^[multiply:#737373]",
                    "image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
                    "tooltip[exit;Exit;#404040;#ffffff]",
                    "hypertext[", text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Moderation</b></center></style>]",
                    "hypertext[", panel_width + text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Message Log</b></center></style>]",
                    "style_type[textarea;font=mono,bold;textcolor=#000000]",
                    "style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:", mc_core.col.b.default, "]",
                }

                local chat_msg = minetest.deserialize(mc_teacher.meta:get_string("chat_log"))
                local direct_msg = minetest.deserialize(mc_teacher.meta:get_string("dm_log"))
                local server_msg = minetest.deserialize(mc_teacher.meta:get_string("server_log"))
                local add_server = false
                context.indexed_chat_players = {}

                for uname,_ in pairs(chat_msg or {}) do
                    if not mc_core.tableHas(context.indexed_chat_players, uname) then
                        table.insert(context.indexed_chat_players, uname)
                    end
                end
                for uname,_ in pairs(direct_msg or {}) do
                    if not mc_core.tableHas(context.indexed_chat_players, uname) then
                        table.insert(context.indexed_chat_players, uname)
                    end
                end
                for uname, msg_list in pairs(server_msg or {}) do
                    if has_server_privs then
                        if not mc_core.tableHas(context.indexed_chat_players, uname) then
                            table.insert(context.indexed_chat_players, uname)
                        end
                    else
                        local add_player = false
                        for _,msg_table in pairs(msg_list) do
                            if msg_table.recipient ~= mc_teacher.M.RECIP.ADMIN then
                                if not msg_table.anonymous then
                                    add_player = true
                                else
                                    add_server = true
                                end
                            end
                            if add_player and add_server then
                                break
                            end
                        end
                        if not mc_core.tableHas(context.indexed_chat_players, uname) and add_player then
                            table.insert(context.indexed_chat_players, uname)
                        end
                    end
                end

                if add_server then
                    table.insert(context.indexed_chat_players, mc_core.SERVER_USER)
                    local server_messages = {}
                    for _, msg_list in pairs(server_msg or {}) do
                        for _,msg_table in pairs(msg_list) do
                            if msg_table.anonymous and msg_table.recipient ~= mc_teacher.M.RECIP.ADMIN then
                                table.insert(server_messages, msg_table)
                            end
                        end
                    end
                    server_msg[mc_core.SERVER_USER] = server_messages
                end

                if #context.indexed_chat_players > 0 then
                    if not context.player_chat_index or not context.indexed_chat_players[context.player_chat_index] then
                        context.player_chat_index = 1
                    end
                    local selected = context.indexed_chat_players[context.player_chat_index]
                    local stamps = {}
                    local stamp_to_key = {}

                    if chat_msg and chat_msg[selected] then
                        for i, msg_table in ipairs(chat_msg[selected]) do
                            table.insert(stamps, msg_table.timestamp)
                            stamp_to_key[msg_table.timestamp] = "chat:"..i
                        end
                    end
                    if direct_msg and direct_msg[selected] then
                        for i, msg_table in ipairs(direct_msg[selected]) do
                            table.insert(stamps, msg_table.timestamp)
                            stamp_to_key[msg_table.timestamp] = "dm:"..i
                        end
                    end
                    if server_msg and server_msg[selected] then
                        for i, msg_table in ipairs(server_msg[selected]) do
                            if has_server_privs or (msg_table.recipient ~= mc_teacher.M.RECIP.ADMIN and msg_table.anonymous == (selected == mc_core.SERVER_USER)) then
                                table.insert(stamps, msg_table.timestamp)
                                stamp_to_key[msg_table.timestamp] = "serv:"..i
                            end
                        end
                    end
                    table.sort(stamps)

                    context.log_i_to_key = {}
                    local player_log = {}
                    -- build main message list
                    for i, stamp in ipairs(stamps) do
                        local key = stamp_to_key[stamp] or "null:0"
                        local split_key = mc_core.split(key, ":")
                        local index = tonumber(split_key[2] or "0")
                        if split_key[1] == "chat" and index ~= 0 then
                            local msg_table = chat_msg[selected][index]
                            table.insert(player_log, "#CCFFFF"..minetest.formspec_escape(table.concat({"[", stamp, "] ", mc_core.trim(string.gsub(msg_table.message, "\n+", " "))}))) 
                        elseif split_key[1] == "dm" and index ~= 0 then
                            local msg_table = direct_msg[selected][index]
                            table.insert(player_log, "#FFFFCC"..minetest.formspec_escape(table.concat({"[", stamp, "] DM to ", msg_table.recipient, ": ", mc_core.trim(string.gsub(msg_table.message, "\n+", " "))})))
                        elseif split_key[1] == "serv" and index ~= 0 then
                            local msg_table = server_msg[selected][index]
                            table.insert(player_log, "#FFCCFF"..minetest.formspec_escape(table.concat({"[", stamp, "] ", mc_core.SERVER_USER, " to ", msg_table.recipient, ": ", mc_core.trim(string.gsub(msg_table.message, "\n+", " "))})))
                        end
                        table.insert(context.log_i_to_key, key)
                    end

                    if not context.message_chat_index or not context.log_i_to_key[context.message_chat_index] then
                        context.message_chat_index = 1
                    end
                    local selected_key = context.log_i_to_key[context.message_chat_index]
                    local sel_split_key = mc_core.split(selected_key, ":")
                    local sel_index = tonumber(sel_split_key[2] or "0")
                    local display_message = {}

                    if sel_split_key[1] == "chat" and chat_msg[selected][sel_index] then
                        display_message.header = "Global chat message"
                        display_message.message = chat_msg[selected][sel_index].message
                    elseif sel_split_key[1] == "dm" and direct_msg[selected][sel_index] then
                        display_message.header = "Direct message to "..direct_msg[selected][sel_index].recipient
                        display_message.message = direct_msg[selected][sel_index].message
                    elseif sel_split_key[1] == "serv" and server_msg[selected][sel_index] then
                        display_message.header = "Server message to "..server_msg[selected][sel_index].recipient
                        display_message.message = server_msg[selected][sel_index].message
                    end

                    table.insert(fs, table.concat({
                        "textarea[", text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Message Logs]",
                        "textlist[", spacer, ",1.4;", panel_width - 2*spacer, ",5.5;mod_log_players;", table.concat(context.indexed_chat_players, ","), ";", context.player_chat_index, ";false]",
                    }))

                    if selected == mc_core.SERVER_USER then
                        table.insert(fs, table.concat({
                            "textarea[", text_spacer, ",7.1;", panel_width - 2*text_spacer, ",1;;;Who is ", mc_core.SERVER_USER, "?]",
                            "style_type[textarea;font=mono]",
                            "textarea[", text_spacer, ",7.5;", panel_width - 2*text_spacer, ",2.3;;;", mc_core.SERVER_USER, " is not a player. It is a reserved name used to represent something done by the Minetest Classroom server or a server administrator.\nThe messages logged here are server messages sent by server administrators.]",
                            "style_type[textarea;font=mono,bold]",
                        }))
                    elseif not minetest.get_player_by_name(selected) then
                        table.insert(fs, table.concat({
                            "style[blocked;bgimg=mc_pixel.png^[multiply:", mc_core.col.b.blocked, "]",
                            "button[", spacer, ",7;3.5,0.8;blocked;Mute player]",
                            "button[", spacer + 3.6, ",7;3.5,0.8;mod_clearlog;Delete log]",
                            "textarea[", text_spacer, ",8;", panel_width - 2*text_spacer, ",1;;;Message ", selected or "player", "]",
                            "style_type[textarea;font=mono]",
                            "textarea[", spacer, ",8.4;", panel_width - 2*spacer, ",1.4;;;This player is currently not online and thus can not be messaged.]",
                            "style_type[textarea;font=mono,bold]",
                        }))
                    else
                        local sel_obj = minetest.get_player_by_name(selected)
                        local sel_meta = sel_obj:get_meta()
                        local sel_privs = minetest.deserialize(sel_meta:get_string("universalPrivs")) or {}
                        table.insert(fs, table.concat({
                            "button[", spacer, ",7;3.5,0.8;", sel_privs and sel_privs.shout == false and "mod_unmute;Unmute player" or "mod_mute;Mute player", "]",
                            "button[", spacer + 3.6, ",7;3.5,0.8;mod_clearlog;Delete log]",
                            "textarea[", text_spacer, ",8;", panel_width - 2*text_spacer, ",1;;;Message ", selected or "player", "]",
                            "style_type[textarea;font=mono]",
                            "textarea[", spacer, ",8.4;", panel_width - 2*spacer - 0.8, ",1.4;mod_message;;", context.mod_message or "", "]",
                            "style_type[textarea;font=mono,bold]",
                            "button[", panel_width - spacer - 0.8, ",8.4;0.8,1.4;mod_send_message;Send]",
                        }))
                    end

                    table.insert(fs, table.concat({
                        "textarea[", panel_width + text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Sent Messages]",
                        "textlist[", panel_width + spacer, ",1.4;", panel_width - 2*spacer, ",6.4;mod_log_messages;", table.concat(player_log, ","), ";", context.message_chat_index, ";false]",
                        "textarea[", panel_width + text_spacer, ",8;", panel_width - 2*text_spacer, ",1;;;", display_message and display_message.header or "Unknown", "]",
                        "style_type[textarea;font=mono]",
                        "textarea[", panel_width + text_spacer, ",8.4;", panel_width - 2*text_spacer, ",1.4;;;", display_message and display_message.message or "", "]",
                        "tooltip[mod_clearlog;Removes all messages sent by the selected player from the log;#404040;#ffffff]",
                    }))
                else
                    -- fallback formspec
                    table.insert(fs, table.concat({
                        "textarea[", text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;No messages logged!]",
                        "style_type[textarea;font=mono]",
                        "textarea[", text_spacer, ",1.5;", panel_width - 2*text_spacer, ",8.3;;;When players send chat messages or direct messages to other players, they will be logged here!]",
                    }))
                end

                return fs
            end,
            [mc_teacher.TABS.REPORTS] = function()
                local fs = {
                    "image[0,0;", controller_width, ",0.5;mc_pixel.png^[multiply:#737373]",
                    "image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
                    "tooltip[exit;Exit;#404040;#ffffff]",
                    "hypertext[", text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Reports</b></center></style>]",
                    "hypertext[", panel_width + text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Report Info</b></center></style>]",
                    "style_type[textarea;font=mono,bold;textcolor=#000000]",
                    "style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:", mc_core.col.b.default, "]",
                    "style[blocked;bgimg=mc_pixel.png^[multiply:", mc_core.col.b.blocked, "]",
                }

                context.report_i_to_idx = {}
                local report_log = minetest.deserialize(mc_teacher.meta:get_string("report_log")) or {}
                local report_strings = {}
                local report_idx_to_key = {}

                for idx, report in pairs(report_log) do
                    local report_string = minetest.formspec_escape("["..report.timestamp.."] "..report.type.." by "..report.player)
                    table.insert(report_strings, report_string)
                    report_idx_to_key[report_string] = idx
                end
                table.sort(report_strings)
                for i,string in ipairs(report_strings) do
                    context.report_i_to_idx[i] = report_idx_to_key[string]
                end

                context.selected_report = context.selected_report or 1
                if context.selected_report > #report_strings then
                    context.selected_report = math.max(#report_strings, 1)
                end
                local selected = report_log[context.report_i_to_idx[context.selected_report]]

                table.insert(fs, table.concat({
                    "textarea[", text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Report Log]",
                    "textlist[", spacer, ",1.4;", panel_width - 2*spacer, ",7.5;report_log;", table.concat(report_strings, ","), ";", context.selected_report, ";false]",
                    "button[", spacer, ",9;3.5,0.8;", selected and "report_delete" or "blocked", ";Delete report]",
                    "button[", spacer + 3.6, ",9;3.5,0.8;", selected and "report_clearlog" or "blocked", ";Clear report log]",
                }))

                if selected then
                    local realm = Realm.GetRealm(selected.realm) or {Name = "Unknown", StartPos = {x=0, y=0, z=0}}
                    local loc = selected.pos and {
                        x = tostring(math.round(selected.pos.x - realm.StartPos.x)),
                        y = tostring(math.round(selected.pos.y - realm.StartPos.y)),
                        z = tostring(math.round(selected.pos.z - realm.StartPos.z)),
                    }
                    table.insert(fs, table.concat({
                        "textarea[", panel_width + text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;", string.upper(selected.type or "Other"), "]",
                        "textarea[", panel_width + text_spacer, ",8;7.2,1;;;Message ", selected.player or "reporter", "]",
                        "style_type[textarea;font=mono]",
                        "textarea[", panel_width + text_spacer, ",1.4;", panel_width - 2*text_spacer, ",6.5;;;",
                        selected.message or "", "\n\n", "Reported on ", selected.timestamp or "an unknown date", " by ", selected.player or "an unknown player", "\n",
                        selected.realm and "Realm #"..selected.realm.." ("..realm.Name..")" or "Unknown realm", " at ", selected.pos and "position (x="..loc.x..", y="..loc.y..", z="..loc.z..")" or "an unknown position", "]",
                        "textarea[", panel_width + spacer, ",8.4;", panel_width - 2*spacer - 0.8, ",1.4;report_message;;", context.report_message or "", "]",
                        "style_type[textarea;font=mono,bold]",
                        "button[", controller_width - spacer - 0.8, ",8.4;0.8,1.4;report_send_message;Send]",
                    }))
                else
                    table.insert(fs, table.concat({
                        "textarea[", panel_width + text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;No reports found!]",
                        "style_type[textarea;font=mono]",
                        "textarea[", panel_width + text_spacer, ",1.4;", panel_width - 2*text_spacer, ",6.5;;;When a player submits a report, it will appear here!]",
                    }))
                end

                return fs
            end,
            [mc_teacher.TABS.HELP] = function()
                local fs = {
                    "image[0,0;", controller_width, ",0.5;mc_pixel.png^[multiply:#737373]",
                    "image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
                    "tooltip[exit;Exit;#404040;#ffffff]",
                    "hypertext[", text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Help</b></center></style>]",
                    "hypertext[", panel_width + text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Submit a Report</b></center></style>]",
                    "style_type[textarea;font=mono,bold;textcolor=#000000]",
                    "textarea[", text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Game controls]",
                    "textarea[", panel_width + text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Need to report an issue?]",
                    "textarea[", panel_width + text_spacer, ",5.6;", panel_width - 2*text_spacer, ",1;;;Report type]",
                    "textarea[", panel_width + text_spacer, ",6.9;", panel_width - 2*text_spacer, ",1;;;Report message]",
                    "style_type[textarea;font=mono]",
                    "style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:", mc_core.col.b.default, "]",

                    "textarea[", text_spacer, ",1.4;", panel_width - 2*text_spacer, ",8.4;;;", mc_core.get_controls_info(true), "]",
                    "textarea[", panel_width + text_spacer, ",1.4;", panel_width - 2*text_spacer, ",4.1;;;", minetest.formspec_escape("If you need to report a server issue or player, you can write a message in the box below."), "\n\n",
					minetest.formspec_escape("Your report message will be logged in the report log and be visible to all teachers, so don't include any personal information in it. The server will also automatically log the current date and time, your classroom, and your world position in the report, so you don't need to include that information in your report message."), "]",
                    "dropdown[", panel_width + spacer, ",6.0;", panel_width - 2*spacer, ",0.8;report_type;Server Issue,Misbehaving Player,Question,Suggestion,Other;1;false]",
                    "textarea[", panel_width + spacer, ",7.3;", panel_width - 2*spacer, ",1.6;report_body;;]",
                    "button[", panel_width + spacer, ",9;", panel_width - 2*spacer, ",0.8;submit_report;Submit report]",
                }

                return fs
            end,
            [mc_teacher.TABS.SERVER] = function()
                local time_options = {}
                for t, t_table in pairs(mc_teacher.T_INDEX) do
                    time_options[t_table.i] = t
                end
                local version = minetest.get_version()
                local uptime = minetest.get_server_uptime()
                context.selected_s_tab = context.selected_s_tab or mc_teacher.STAB.BANNED

                local fs = {
                    "image[0,0;", controller_width, ",0.5;mc_pixel.png^[multiply:#737373]",
                    "image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]",
                    "tooltip[exit;Exit;#404040;#ffffff]",
                    "hypertext[", text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Server Management</b></center></style>]",
                    "hypertext[", panel_width + text_spacer, ",0.1;", panel_width - 2*text_spacer, ",1;;<style font=mono><center><b>Server Information</b></center></style>]",
                    "style_type[textarea;font=mono,bold;textcolor=#000000]",
                    "style_type[button;border=false;font=mono,bold;bgimg=mc_pixel.png^[multiply:", mc_core.col.b.default, "]",

                    "textarea[", text_spacer, ",1;", panel_width - 2*text_spacer, ",1;;;Global Messenger]",
                    "style_type[textarea,field;font=mono]",
                    "textarea[", spacer, ",1.4;", panel_width - 2*spacer, ",2.3;server_message;;", context.server_message or "", "]",
                    "style_type[textarea;font=mono,bold]",
                    "textarea[", text_spacer, ",3.7;", panel_width - 2*text_spacer, ",1;;;Send as:]",
                    "dropdown[", spacer, ",4.1;", panel_width - 2*spacer, ",0.8;server_message_type;General server message,Server message from yourself,Chat message from yourself;", context.server_message_type or mc_teacher.M.MODE.SERVER_ANON, ";true]",
                    "textarea[", text_spacer, ",4.9;", panel_width - 2*text_spacer, ",1;;;Send to:]",
                    "button[", spacer, ",5.3;1.7,0.8;server_send_teachers;Teachers]",
                    "button[", spacer + 1.8, ",5.3;1.7,0.8;server_send_students;Students]",
                    "button[", spacer + 3.6, ",5.3;1.7,0.8;server_send_admins;Admins]",
                    "button[", spacer + 5.4, ",5.3;1.7,0.8;server_send_all;Everyone]",

                    "textarea[", text_spacer, ",6.3;", panel_width - 2*text_spacer, ",1;;;Schedule Server Shutdown]",
                    "dropdown[", spacer, ",6.7;", panel_width - 2*spacer, ",0.8;server_shutdown_timer;", table.concat(time_options, ","), ";", context.time_index or 1, ";false]",
                    "button[", spacer, ",7.6;3.5,0.8;server_shutdown_", mc_teacher.restart_scheduled.timer and "cancel" or "schedule", ";", mc_teacher.restart_scheduled.timer and "Cancel shutdown" or "Schedule", "]",
                    "button[", spacer + 3.6, ",7.6;3.5,0.8;server_shutdown_now;Shutdown now]",

                    "textarea[", text_spacer, ",8.6;", panel_width - 2*text_spacer, ",1;;;Server Actions]",
                    "button[", spacer, ",9;3.5,0.8;server_edit_rules;Server rules]",
                    "button[", spacer + 3.6, ",9;3.5,0.8;server_whitelist;Whitelist]",

                    "textarea[", text_spacer + panel_width, ",1;", panel_width - 2*text_spacer, ",1;;;Game Information]",
                    "style_type[textarea;font=mono]",
                    "textarea[", text_spacer + panel_width, ",1.4;", panel_width - 2*text_spacer, ",1.2;;;",
                    version.project or "Minetest", " version", version.string and ": "..version.string or " unknown", "\nServer uptime: ", mc_core.expand_time(uptime or 0), "]",
                    "style_type[textarea;font=mono,bold]",

                    "tabheader[", spacer + panel_width, ",3.2;", panel_width - 2*spacer, ",0.5;server_dyn_header;Banned,Online,Installed Mods;1;false;true]",
                }

                if context.selected_s_tab == mc_teacher.STAB.ONLINE then
                    context.server_dyn_list = {}
                    for _, p in pairs(minetest.get_connected_players()) do
                        if p and p:is_player() then
                            table.insert(context.server_dyn_list, p:get_player_name())
                        end
                    end

                    table.insert(fs, table.concat({
                        "textlist[", spacer + panel_width, ",3.2;", panel_width - 2*spacer, ",6.8;server_dyn;", table.concat(context.server_dyn_list, ""), ";", context.selected_s_dyn or 1, ";false]",
                        -- TODO: add kick/ban buttons?
                        --"button[", spacer + panel_width, ",9;", panel_width - 2*spacer, ",0.8;server_unban;Unban]"
                    }))
                elseif context.selected_s_tab == mc_teacher.STAB.MODS then
                    context.server_dyn_list = minetest.get_modnames() or {}
                    table.insert(fs, table.concat({
                        "textlist[", spacer + panel_width, ",3.2;", panel_width - 2*spacer, ",6.8;server_dyn;", table.concat(context.server_dyn_list, ""), ";", context.selected_s_dyn or 1, ";false]",
                    }))
                else
                    context.server_dyn_list = minetest.get_ban_list() or ""
                    table.insert(fs, table.concat({
                        "textlist[", spacer + panel_width, ",3.2;", panel_width - 2*spacer, ",5.7;server_dyn;", context.server_dyn_list, ";", context.selected_s_dyn or 1, ";false]",
                        "button[", spacer + panel_width, ",9;", panel_width - 2*spacer, ",0.8;server_unban;Unban]",
                    }))
                end

                table.insert(fs, table.concat({
                    "tooltip[server_message;Type your message here!;#404040;#ffffff]",
                    "tooltip[server_ban_manager;View and manage banned players;#404040;#ffffff]",
                    "tooltip[server_edit_rules;Edit server rules;#404040;#ffffff]",
                    "tooltip[server_whitelist;Manage server whitelist;#404040;#ffffff]",
                }))

                return fs
            end,
        }

        -- Remove unauthorized tabs
        if not has_server_privs then
            tab_map[mc_teacher.TABS.SERVER] = nil
        end

        local bookmarked_tab = pmeta:get_string("default_teacher_tab")
        if not tab_map[bookmarked_tab] then
            bookmarked_tab = nil
            pmeta:set_string("default_teacher_tab", nil)
        end
        local selected_tab = (tab_map[tab] and tab) or (tab_map[context.tab] and context.tab) or bookmarked_tab or "1"
        context.tab = selected_tab
        mc_teacher.check_selected_priv_mode(context)

        local teacher_formtable = {
            "formspec_version[6]",
            "size[", controller_width, ",", controller_height, "]",
            mc_core.draw_book_fs(controller_width, controller_height, {bg = "#404040", shadow = "#303030", binding = "#333333", divider = "#969696"}),
            "style[tabheader;noclip=true]",
            "tabheader[0,-0.25;", controller_width, ",0.55;record_nav;Overview,Classrooms,Map,Players,Moderation,Reports,Help",
            has_server_privs and ",Server" or "", ";", selected_tab, ";true;false]",
            table.concat(tab_map[selected_tab](), "")
        }

        if bookmarked_tab == selected_tab then
            table.insert(teacher_formtable, table.concat({
                "style_type[image;noclip=true]",
                "image[", controller_width - 0.6, ",-0.25;0.5,0.7;mc_teacher_bookmark_filled.png]",
                "tooltip[", controller_width - 0.6, ",-0.25;0.5,0.8;This tab is currently bookmarked;#404040;#ffffff]",
            }))
        else
            table.insert(teacher_formtable, table.concat({
                "image_button[", controller_width - 0.6, ",-0.25;0.5,0.5;mc_teacher_bookmark_hollow.png^[colorize:#FFFFFF:127;default_tab;;true;false]",
                "tooltip[default_tab;Bookmark this tab?;#404040;#ffffff]",
            }))
        end

        minetest.show_formspec(pname, "mc_teacher:controller_fs", table.concat(teacher_formtable, ""))
        return true
    end
end

--[[
NEW FORMSPEC CLEAN COPIES

TAB GROUPING:
[1] OVERVIEW + RULES
[2] CLASSROOM MANAGEMENT
[3] MAP + COORDINATES
[4] PLAYER MANAGEMENT
[5] MODERATION
[6] HELP
[7] REPORT LOG
[8] SERVER MANAGEMENT (extra)

OVERVIEW + RULES:
formspec_version[6]
size[16.6,10.4]
box[0,0;16.6,0.5;#737373]
box[8.275,0;0.05,10.4;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.2,1;;;Overview]
textarea[8.85,0.1;7.2,1;;;Dashboard]
textarea[0.55,1;7.2,1;;;Welcome to Minetest Classroom!]
textarea[0.55,1.4;7.2,3;;;This is the teacher controller!]
textarea[0.55,4.6;7.2,1;;;Server Rules]
textarea[0.55,5;7.2,3.9;;;These are the server rules!]
button[0.6,9;7.1,0.8;modifyrules;Edit Server Rules]
textarea[10.7,0.9;5.4,1.8;;;Classrooms Find classrooms or players]
image_button[8.9,1;1.7,1.6;mc_teacher_classrooms.png;classrooms;;false;false]
textarea[10.7,2.7;5.4,1.8;;;Map Record and share locations]
image_button[8.9,2.8;1.7,1.6;mc_teacher_map.png;map;;false;false]
textarea[10.7,4.5;5.4,1.8;;;Players Manage player privileges]
image_button[8.9,4.6;1.7,1.6;mc_teacher_players.png;players;;false;false]
textarea[10.7,6.3;5.4,1.8;;;Moderation View player chat logs]
image_button[8.9,6.4;1.7,1.6;mc_teacher_isometric.png;help;;false;false]
textarea[10.7,8.1;5.4,1.8;;;Reports View player reports]
image_button[8.9,8.2;1.7,1.6;mc_teacher_isometric.png;help;;false;false]
image[16,-0.25;0.5,0.8;mc_teacher_bookmark.png]

CLASSROOMS:
formspec_version[6]
size[16.6,10.4]
box[0,0;16.6,0.5;#737373]
box[8.275,0;0.05,10.4;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.2,1;;;Classrooms]
textarea[8.85,0.1;7.2,1;;;Build a Classroom]
textarea[0.55,1;7.2,1;;;Available Classrooms]
textlist[0.6,1.4;7.1,7.5;classroomlist;;1;false]
button[0.6,9;2.3,0.8;teleportrealm;Teleport]
button[3,9;2.3,0.8;editrealm;Edit]
button[5.4,9;2.3,0.8;deleterealm;Delete]
textarea[8.85,1;7.2,1;;;Name]
field[8.9,1.4;7.1,0.8;realmname;;]
textarea[8.85,2.3;3.6,1;;;Type]
dropdown[8.9,2.7;3.5,0.8;realmcategory;Default,Spawn,Classroom,Private;1;true]
textarea[12.45,2.3;3.6,1;;;Generation]
dropdown[12.5,2.7;3.5,0.8;mode;Empty World,Schematic,Digital Twin;1;true]
textarea[8.85,3.6;7.2,1;;;OPTIONS]
box[8.9,4;7.1,0.8;#808080]
textarea[8.85,4.9;7.2,1;;;Default Privileges]
textarea[10.15,5.7;2.3,1;;;interact]
textarea[10.15,6.1;2.3,1;;;shout]
textarea[10.15,6.5;2.3,1;;;fast]
textarea[13.75,5.7;2.3,1;;;fly]
textarea[13.75,6.1;2.3,1;;;noclip]
textarea[13.75,6.5;2.3,1;;;give]
image[8.9,5.3;0.4,0.4;mc_teacher_check.png]
image[9.3,5.3;0.4,0.4;mc_teacher_ignore.png]
image[9.7,5.3;0.4,0.4;mc_teacher_delete.png]
image[12.5,5.3;0.4,0.4;mc_teacher_check.png]
image[12.9,5.3;0.4,0.4;mc_teacher_ignore.png]
image[13.3,5.3;0.4,0.4;mc_teacher_delete.png]
checkbox[8.9,5.9;allowpriv_interact;;true]
checkbox[8.9,6.3;allowpriv_shout;;true]
checkbox[8.9,6.7;allowpriv_fast;;true]
checkbox[9.3,5.9;ignorepriv_interact;;false]
checkbox[9.3,6.3;ignorepriv_shout;;false]
checkbox[9.3,6.7;ignorepriv_fast;;false]
checkbox[9.7,5.9;denypriv_interact;;false]
checkbox[9.7,6.3;denypriv_shout;;false]
checkbox[9.7,6.7;denypriv_fast;;false]
checkbox[12.5,5.9;allowpriv_fly;;false]
checkbox[12.5,6.3;allowpriv_noclip;;false]
checkbox[12.5,6.7;allowpriv_give;;false]
checkbox[12.9,5.9;ignorepriv_fly;;true]
checkbox[12.9,6.3;ignorepriv_noclip;;true]
checkbox[12.9,6.7;ignorepriv_give;;true]
checkbox[13.3,5.9;denypriv_fly;;false]
checkbox[13.3,6.3;denypriv_noclip;;false]
checkbox[13.3,6.7;denypriv_give;;false]
textarea[8.85,7;7.2,1;;;Background Music]
dropdown[8.9,7.4;7.1,0.8;bgmusic;;1;true]
textarea[8.85,8.3;7.2,1;;;Skybox]
dropdown[8.9,8.7;7.1,0.8;;;1;true]
button[8.9,9;7.1,0.8;requestrealm;Generate classroom]

MAP + COORDINATES:
formspec_version[6]
size[16.6,10.4]
box[0,0;16.6,0.5;#737373]
box[8.275,0;0.05,10.4;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.1,1;;;Map]
textarea[8.85,0.1;7.1,1;;;Coordinates]
textarea[0.55,1;7.1,1;;;Surrounding Area]
box[0.6,1.4;7.1,7.1;#000000]
box[0.625,1.425;7.05,7.05;#808080]
image[4,4.8;0.3,0.3;]
textarea[0.55,8.6;7.1,1;;;Coordinate and Elevation Display]
button[0.6,9;1.7,0.8;utmcoords;UTM]
button[2.4,9;1.7,0.8;latloncoords;Lat/Long]
button[4.2,9;1.7,0.8;classroomcoords;Local]
button[6,9;1.7,0.8;coordsoff;Off]
textarea[8.85,1;7.1,1;;;Saved Coordinates]
textlist[8.9,1.4;7.1,4.4;coordlist;;8;false]
textarea[8.85,8.5;7.1,1;;;Save current coordinates]
image_button[15.1,8.9;0.9,0.9;blank.png;;Save;false;true]
textarea[8.9,8.9;6.2,0.9;note;;]
textarea[8.85,7.2;7.2,1.1;;;(coordinate name) (coords) (realm)]
image_button[8.9,5.9;1.1,1.1;blank.png;go;TP;false;true]
image_button[10.1,5.9;1.1,1.1;blank.png;go_all;TP_A;false;true]
image_button[12.5,5.9;1.1,1.1;blank.png;mark;MK;false;true]
image_button[11.3,5.9;1.1,1.1;blank.png;share;SH;false;true]
image_button[13.7,5.9;1.1,1.1;blank.png;delete;DL;false;true]
image_button[14.9,5.9;1.1,1.1;blank.png;clear;DL_A;false;true]

PLAYERS:
formspec_version[6]
size[16.6,10.4]
box[0,0;16.6,0.5;#737373]
box[8.275,0;0.05,10.4;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.2,1;;;Online Players]
textarea[8.85,0.1;7.2,1;;;Manage Players]
textarea[0.55,1;6.7,1;;;Students]
textlist[0.6,1.4;7.1,7.5;student_list;;1;false]
button[7.25,0.95;0.45,0.45;p_group_new;+]
button[0.6,9;3.5,0.8;p_group_edit;Edit group]
button[4.2,9;3.5,0.8;p_group_delete;Delete group]
image[4.25,1.45;0.4,0.4;]
image[4.75,1.45;0.4,0.4;]
image[5.25,1.45;0.4,0.4;]
image[5.75,1.45;0.4,0.4;]
image[6.25,1.45;0.4,0.4;]
image[6.75,1.45;0.4,0.4;]
image[7.25,1.45;0.4,0.4;]
textarea[8.85,1;7.2,1;;;Action Mode]
button[8.9,1.4;2.3,0.8;;Selected]
button[11.3,1.4;2.3,0.8;;Group]
button[13.7,1.4;2.3,0.8;;All]
textarea[8.85,2.3;7.2,1;;;Privileges in this Classroom]
textarea[10.15,3.1;2.3,1;;;interact]
textarea[10.15,3.5;1.8,1;;;shout]
textarea[10.15,3.9;1.8,1;;;fast]
textarea[13.75,3.1;1.8,1;;;fly]
textarea[13.75,3.5;1.8,1;;;noclip]
textarea[13.75,3.9;1.8,1;;;give]
image[8.9,2.7;0.4,0.4;mc_teacher_check.png]
image[9.3,2.7;0.4,0.4;mc_teacher_ignore.png]
image[9.7,2.7;0.4,0.4;mc_teacher_delete.png]
image[12.5,2.7;0.4,0.4;mc_teacher_check.png]
image[12.9,2.7;0.4,0.4;mc_teacher_ignore.png]
image[13.3,2.7;0.4,0.4;mc_teacher_delete.png]
checkbox[8.9,3.3;allowpriv_interact;;false]
checkbox[8.9,3.7;allowpriv_shout;;false]
checkbox[8.9,4.1;allowpriv_fast;;false]
checkbox[9.3,3.3;ignorepriv_interact;;true]
checkbox[9.3,3.7;ignorepriv_shout;;true]
checkbox[9.3,4.1;ignorepriv_fast;;true]
checkbox[9.7,3.3;denypriv_interact;;false]
checkbox[9.7,3.7;denypriv_shout;;false]
checkbox[9.7,4.1;denypriv_fast;;false]
checkbox[12.5,3.3;allowpriv_fly;;false]
checkbox[12.5,3.7;allowpriv_noclip;;false]
checkbox[12.5,4.1;allowpriv_give;;false]
checkbox[12.9,3.3;ignorepriv_fly;;true]
checkbox[12.9,3.7;ignorepriv_noclip;;true]
checkbox[12.9,4.1;ignorepriv_give;;true]
checkbox[13.3,3.3;denypriv_fly;;false]
checkbox[13.3,3.7;denypriv_noclip;;false]
checkbox[13.3,4.1;denypriv_give;;false]
button[8.9,4.4;3.5,0.8;p_priv_update;Update privs]
button[12.5,4.4;3.5,0.8;p_priv_reset;Reset privs]
textarea[8.85,5.3;7.2,1;;;Actions]
button[8.9,5.7;2.3,0.8;p_teleport;Teleport]
button[11.3,5.7;2.3,0.8;p_bring;Bring]
button[13.7,5.7;2.3,0.8;p_audience;Audience]
button[8.9,6.6;2.3,0.8;p_mute;Mute]
button[11.3,6.6;2.3,0.8;p_deactivate;Deactivate]
button[13.7,6.6;2.3,0.8;p_freeze;Freeze]
button[8.9,7.5;2.3,0.8;p_timeout;Timeout]
button[11.3,7.5;2.3,0.8;p_kick;Kick]
button[13.7,7.5;2.3,0.8;p_ban;Ban]
textarea[8.9,8.4;7.2,1;;;Server Role]
box[12.5,8.8;3.5,1;#FFCC00]
box[8.9,8.8;3.5,1;#00FF00]
button[9,8.9;1.6,0.8;p_role_none;None]
button[10.7,8.9;1.6,0.8;p_role_student;Student]
button[12.6,8.9;1.6,0.8;p_role_teacher;Teacher]
button[14.3,8.9;1.6,0.8;p_role_admin;Admin]

MODERATION:
formspec_version[6]
size[16.6,10.4]
box[0,0;16.6,0.5;#737373]
box[8.275,0;0.05,10.4;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.1,1;;;Moderation]
textarea[8.85,0.1;7.1,1;;;Message Log]
textarea[0.55,1;7.2,1;;;Message Logs]
textlist[0.6,1.4;7.1,5.5;mod_log_players;;1;false]
button[0.6,7;3.5,0.8;mod_mute;Mute player]
button[4.2,7;3.5,0.8;mod_clearlog;Clear player's log]
textarea[0.55,8;7.2,1;;;Message player]
textarea[0.6,8.4;6.3,1.4;mod_message;;]
button[6.9,8.4;0.8,1.4;mod_send_message;Send]
textarea[8.85,1;7.2,1;;;Sent Messages]
textlist[8.9,1.4;7.1,6.4;mod_log_messages;;1;false]
textarea[8.85,8;7.2,1;;;(message type)]
textarea[8.85,8.4;7.2,1.4;;;add message text here!]

REPORTS:
formspec_version[6]
size[16.6,10.4]
box[0,0;16.6,0.5;#737373]
box[8.275,0;0.05,10.4;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.1,1;;;Reports]
textarea[8.85,0.1;7.1,1;;;Report Info]
textarea[0.55,1;7.2,1;;;Report Log]
textlist[0.6,1.4;7.1,7.5;report_log;;1;false]
button[0.6,9;3.5,0.8;report_delete;Delete report]
button[4.2,9;3.5,0.8;report_clearlog;Clear report log]
textarea[8.85,1;7.2,1;;;(TYPE)]
textarea[8.85,1.4;7.2,6.5;;;Report info]
textarea[8.85,8;7.2,1;;;Message player]
textarea[8.9,8.4;6.3,1.4;report_message;;]
button[15.2,8.4;0.8,1.4;report_send_message;Send]

HELP:
formspec_version[6]
size[16.6,10.4]
box[0,0;16.6,0.5;#737373]
box[8.275,0;0.05,10.4;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.1,1;;;Help]
textarea[8.85,0.1;7.1,1;;;Submit a Report]
textarea[0.55,1;7.2,1;;;Controls]
textarea[0.55,1.4;7.2,8.4;;;Add controls here!]
textarea[8.85,1;7.2,1;;;Need to report an issue?]
textarea[8.85,1.4;7.2,4.1;;;Add info about reporting here!]
textarea[8.85,5.6;7.2,1;;;Report type]
dropdown[8.9,6;7.1,0.8;report_type;Server Issue,Misbehaving Player,Question,Suggestion,Other;1;false]
textarea[8.85,6.9;7.2,1;;;Report message]
textarea[8.9,7.3;7.1,1.6;report_body;;]
button[8.9,9;7.1,0.8;submit_report;Submit report]

SERVER:
formspec_version[6]
size[16.6,10.4]
box[0,0;16.6,0.5;#737373]
box[8.275,0;0.05,10.4;#000000]
image_button_exit[0.2,0.05;0.4,0.4;mc_x.png;exit;;false;false]
textarea[0.55,0.1;7.1,1;;;Server Management]
textarea[8.85,0.1;7.1,1;;;Server Information]
textarea[0.55,1;7.2,1;;;Global Messenger]
textarea[0.6,1.4;7.1,2.3;server_message;;]
textarea[0.6,3.7;7.2,1;;;Send as:]
dropdown[0.6,4.1;7.1,0.8;server_message_type;Anonymous server message,Server message from yourself,Chat message from yourself;1;true]
textarea[0.6,4.9;7.2,1;;;Send to:]
button[2.4,5.3;1.7,0.8;server_send_teachers;Teachers]
button[0.6,5.3;1.7,0.8;server_send_students;Students]
button[4.2,5.3;1.7,0.8;server_send_admins;Admins]
button[6,5.3;1.7,0.8;server_send_all;Everyone]
textarea[0.6,6.3;7.2,1;;;Schedule Server Shutdown]
dropdown[0.6,6.7;7.1,0.8;server_shutdown_timer;;1;false]
button[0.6,7.6;3.5,0.8;server_shutdown_schedule;Schedule]
button[4.2,7.6;3.5,0.8;server_shutdown_now;Shutdown now]
textarea[0.55,8.6;7.2,1;;;Server Actions]
button[0.6,9;3.5,0.8;server_edit_rules;Server rules]
button[4.2,9;3.5,0.8;server_whitelist;Whitelist]
textarea[8.85,1;7.2,1;;;Game Information]
textarea[8.85,1.4;7.2,1.4;;;Minetest version: x.x.x -- Server uptime: time]
textarea[8.85,2.5;7.2,1;;;Online/Banned/Mods]
textlist[8.9,2.9;7.1,6;server_dynamic;;1;false]
button[8.9,9;7.1,0.8;;Unban]
]]
