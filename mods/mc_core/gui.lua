--- Creates a notebook formspec with a content area of the given width and height
--- The created formspec will exceed the bounds of the content area
--- --- General bounds are (0.5 units left, 0.75 units right, 1.1 units above, 0.4 units below)
--- --- Upper page edge starts at (0, -0.25), content area starts at (0, 0)
---@param width Content area width
---@param height Content area height
---@param options Formspec options
---@see README.md > GUI Templates
---@return formspec string
function mc_core.draw_book_fs(width, height, options)
    options = options or {}
    -- book border: L=0.25, R=0.5, T=1.1, B=0.4, LX=0.5, RX=0.75
    local book_bg = {
        "formspec_version[6]",
        "size[", width, ",", height, "]",
        "style_type[image;noclip=true]",
        "image[-0.5,-0.85;0.4,", height + 1, ";mc_pixel.png^[multiply:", options.bg or "#325140", "]",
        "image[", width + 0.4, ",-0.85;0.35,", height + 1, ";mc_pixel.png^[multiply:", options.shadow or "#23392d", "]", -- #302e3f
        "image[-0.25,-1.1;", width + 0.75, ",", height + 1.5, ";mc_pixel.png^[multiply:", options.bg or "#325140", "]",
        "image[", width/2 - 0.125, ",-1.1;0.25,", height + 1.5, ";mc_pixel.png^[multiply:", options.binding or "#164326", "]",
        "image[-0.15,0;0.2,", height, ";mc_pixel.png^[multiply:#d9d9d9]",
        "image[", width - 0.05, ",0;0.2,", height, ";mc_pixel.png^[multiply:#d9d9d9]",
        "image[0,-0.25;", width, ",0.3;mc_pixel.png^[multiply:#d9d9d9]",
        "style_type[image;noclip=false]",
        "image[0,0;", width, ",", height, ";mc_pixel.png^[multiply:#f5f5f5]",
    }

    local y = 0.85
    while (y + 0.035) < height do
        table.insert(book_bg, table.concat({"image[0,", y, ";", width, ",0.035;mc_pixel.png^[multiply:#cbecf7]"}, ""))
        y = y + 0.65
    end
    for _,x in pairs(options.margin_lines or {1, width/2 + 1}) do
        table.insert(book_bg, table.concat({"image[", x, ",0;0.035,", height, ";mc_pixel.png^[multiply:#f6e3e3]"}, ""))
    end

    if options.divider then
        table.insert(book_bg, table.concat({"image[", width/2 - 0.025, ",0;0.05,", height, ";mc_pixel.png^[multiply:", options.divider, "]"}))
    end

    return table.concat(book_bg, "")
end

--- Creates a sticky note formspec with a content area of the given width and height
--- The created formspec will contain the no_prepend[] element
---@param width Content area width
---@param height Content area height
---@param options Formspec options
---@see README.md > GUI Templates
---@return formspec string
function mc_core.draw_note_fs(width, height, options)
    options = options or {}
    local raw_corner = math.min(width/4, 0.5)
    local corner_size = mc_core.round(raw_corner, 1)

    local note_bg = {
        "formspec_version[6]",
        "size[", width, ",", height, "]",
        "no_prepend[]",
        "bgcolor[#00000000;true;]",
        "style_type[image;noclip=true]",
        "image[0,0;", width - corner_size, ",", height, ";mc_pixel.png^[multiply:", options.bg or "#faf596", "]",
        "image[0,0;", width, ",", height - corner_size, ";mc_pixel.png^[multiply:", options.bg or "#faf596", "]",
        "image[", width - corner_size, ",", height - corner_size, ";", corner_size, ",", corner_size, ";mc_triangle.png^[multiply:", options.accent or "#fcf5c2", "]",
        "style_type[image;noclip=false]",
    }
    return table.concat(note_bg, "")
end

--- Creates a string containing the primary controls for Minetest, intended for use in a formspec
---@param show_technical Boolean indicating whether to show controls for viewing Minetest debug info
---@return string
function mc_core.get_controls_info(show_technical)
    local set = minetest.settings
    local controls = {
        "Move forwards: ", mc_core.clean_key(set:get("keymap_forward") or "KEY_KEY_W"), "\n",
        "Move backwards: ", mc_core.clean_key(set:get("keymap_backward") or "KEY_KEY_S"), "\n",
        "Move left: ", mc_core.clean_key(set:get("keymap_left") or "KEY_KEY_A"), "\n",
        "Move right: ", mc_core.clean_key(set:get("keymap_right") or "KEY_KEY_D"), "\n",
        "Jump/climb up: ", mc_core.clean_key(set:get("keymap_jump") or "KEY_SPACE"), "\n",
        "Sneak", set:get("aux1_descends") == "true" and "" or "/climb down", ": ", mc_core.clean_key(set:get("keymap_sneak") or "KEY_LSHIFT"), "\n",
        "Sprint", set:get("aux1_descends") == "true" and "/climb down" or "", ": ", mc_core.clean_key(set:get("keymap_aux1") or "KEY_KEY_E"), "\n",
        "Zoom: ", mc_core.clean_key(set:get("keymap_zoom") or "KEY_KEY_Z"), "\n",
        "\n",
        "Dig block/use tool: ", set:get("keymap_dig") and mc_core.clean_key(set:get("keymap_dig") or "KEY_LBUTTON"), "\n",
        "Place block: ", set:get("keymap_place") and mc_core.clean_key(set:get("keymap_place") or "KEY_RBUTTON"), "\n",
        "Select hotbar item: SCROLL WHEEL or SLOT NUMBER (1-8)\n",
        "Select next hotbar item: ", mc_core.clean_key(set:get("keymap_hotbar_next") or "KEY_KEY_N"), "\n",
        "Select previous hotbar item: ", mc_core.clean_key(set:get("keymap_hotbar_previous") or "KEY_KEY_B"), "\n",
        "Drop item: ", mc_core.clean_key(set:get("keymap_drop") or "KEY_KEY_Q"), "\n",
        "\n",
        "Open inventory: ", mc_core.clean_key(set:get("keymap_inventory") or "KEY_KEY_I"), "\n",
        "Open chat: ", mc_core.clean_key(set:get("keymap_chat") or "KEY_KEY_T"), "\n",
        "View minimap: ", mc_core.clean_key(set:get("keymap_minimap") or "KEY_KEY_V"), "\n",
        "Take a screenshot: ", mc_core.clean_key(set:get("keymap_screenshot") or "KEY_F12"), "\n",
        "Change camera perspective: ", mc_core.clean_key(set:get("keymap_camera_mode") or "KEY_KEY_C"), "\n",
        "Mute/unmute game sound: ", mc_core.clean_key(set:get("keymap_mute") or "KEY_KEY_M"), "\n",
        "\n",
        "Enable/disable sprint: ", mc_core.clean_key(set:get("keymap_fastmove") or "KEY_KEY_J"), "\n",
        "Enable/disable fly mode: ", mc_core.clean_key(set:get("keymap_freemove") or "KEY_KEY_K"), "\n",
        "Enable/disable noclip mode: ", mc_core.clean_key(set:get("keymap_noclip") or "KEY_KEY_H"), "\n",
        "Show/hide HUD (display): ", mc_core.clean_key(set:get("keymap_toggle_hud") or "KEY_F1"), "\n",
        "Show/hide chat: ", mc_core.clean_key(set:get("keymap_toggle_chat") or "KEY_F2"), "\n",
        "Show/hide world fog: ", mc_core.clean_key(set:get("keymap_toggle_force_fog_off") or "KEY_F3"), "\n",
        "Expand/shrink chat window: ", mc_core.clean_key(set:get("keymap_console") or "KEY_F10"),
    }
    if show_technical then
        table.insert(controls, table.concat({
            "\n\n", minetest.formspec_escape("[MINETEST TECHNICAL INFO]"), "\n",
            "Show/hide debug log: ", mc_core.clean_key(set:get("keymap_toggle_debug") or "KEY_F5"), "\n",
            "Show/hide profiler: ", mc_core.clean_key(set:get("keymap_toggle_profiler") or "KEY_F6"),
        }))
    end

    return table.concat(controls)
end
