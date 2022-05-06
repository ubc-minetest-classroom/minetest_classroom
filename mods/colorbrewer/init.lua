local palettes = {
	{"BrBG"},
	{"PiYG"},
	{"PRGn"},
	{"PuOr"},
	{"RdBu"},
	{"RdGy"},
	{"RdYlBu"},
	{"RdYlGn"},
	{"Spectral"},
	{"Blues"},
	{"BuGn"},
	{"BuPu"},
	{"GnBu"},
	{"Greens"},
	{"Greys"},
	{"Oranges"},
	{"OrRd"},
	{"PuBu"},
	{"PuBuGn"},
	{"PuRd"},
	{"Purples"},
	{"RdPu"},
	{"Reds"},
	{"YlGn"},
	{"YlGnBu"},
	{"YlOrBr"},
	{"YlOrRd"},
}

for i in ipairs(palettes) do
    
    minetest.register_node("colorbrewer:" .. palettes[i][1], {
        inventory_image = palettes[i][1] .. "_palette.png",
	    wield_image = palettes[i][1] .. "_palette.png",
		groups = {oddly_breakable_by_hand = 1, ud_param2_colorable=1},
        tiles = {"colorbrewer_template.png"},
		paramtype2 = "color",
        palette = palettes[i][1] .. "_palette.png",
    })

end