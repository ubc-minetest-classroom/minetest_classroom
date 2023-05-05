--- Creates a notebook formspec with a content area of the given width and height
--- The created formspec will exceed the bounds of the content area
--- --- General bounds are (0.5 units left, 0.75 units right, 1.1 units above, 0.4 units below)
--- --- Upper page edge starts at (0, -0.25), content area starts at (0, 0)
--- @param width Content area width
--- @param height Content area height
--- @param options Formspec options
--- @see README.md > GUI Templates
--- @return formspec string
function mc_core.draw_book_fs(width, height, options)
    options = options or {}
    -- book border: L=0.25, R=0.5, T=1.1, B=0.4, LX=0.5, RX=0.75
    local book_bg = {
        "formspec_version[6]",
        "size[", width, ",", height, "]",
        "style_type[image;noclip=true]",
        "image[-0.5,-0.85;0.4,", height + 1, ";mc_tutorial_pixel.png^[multiply:", options.bg or "#325140", "]",
        "image[", width + 0.4, ",-0.85;0.35,", height + 1, ";mc_tutorial_pixel.png^[multiply:", options.shadow or "#23392d", "]", -- #302e3f
        "image[-0.25,-1.1;", width + 0.75, ",", height + 1.5, ";mc_tutorial_pixel.png^[multiply:", options.bg or "#325140", "]",
        "image[", width/2 - 0.125, ",-1.1;0.25,", height + 1.5, ";mc_tutorial_pixel.png^[multiply:", options.binding or "#164326", "]",
        "image[-0.15,0;0.2,", height, ";mc_tutorial_pixel.png^[multiply:#d9d9d9]",
        "image[", width - 0.05, ",0;0.2,", height, ";mc_tutorial_pixel.png^[multiply:#d9d9d9]",
        "image[0,-0.25;", width, ",0.3;mc_tutorial_pixel.png^[multiply:#d9d9d9]",
        "style_type[image;noclip=false]",
        "image[0,0;", width, ",", height, ";mc_tutorial_pixel.png^[multiply:#f5f5f5]",
    }

    local y = 0.85
    while (y + 0.035) < height do
        table.insert(book_bg, table.concat({"image[0,", y, ";", width, ",0.035;mc_tutorial_pixel.png^[multiply:#cbecf7]"}, ""))
        y = y + 0.65
    end
    for _,x in pairs(options.margin_lines or {1, width/2 + 1}) do
        table.insert(book_bg, table.concat({"image[", x, ",0;0.035,", height, ";mc_tutorial_pixel.png^[multiply:#f6e3e3]"}, ""))
    end

    if options.divider then
        table.insert(book_bg, table.concat({"image[", width/2 - 0.025, ",0;0.05,", height, ";mc_tutorial_pixel.png^[multiply:", options.divider, "]"}))
    end

    return table.concat(book_bg, "")
end