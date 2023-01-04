colorbrewer = {}
colorbrewer.palettes = {
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

minetest.register_chatcommand("palettes", {
	params = "",
    description = "returns all registered colorbrewer palettes",
    func = function(name, params)
		minetest.chat_send_player(name, "==========================")
		minetest.chat_send_player(name, "Valid colorbrewer palettes")
		minetest.chat_send_player(name, "==========================")
		for i in ipairs(colorbrewer.palettes) do
			minetest.chat_send_player(name,colorbrewer.palettes[i][1])
		end
	end
})

for i in ipairs(colorbrewer.palettes) do
    
    minetest.register_node("colorbrewer:" .. colorbrewer.palettes[i][1], {
        inventory_image = colorbrewer.palettes[i][1] .. "_palette.png",
	    wield_image = colorbrewer.palettes[i][1] .. "_palette.png",
		groups = {oddly_breakable_by_hand = 1, ud_param2_colorable=1},
        tiles = {"colorbrewer_template.png"},
		paramtype2 = "color",
        palette = colorbrewer.palettes[i][1] .. "_palette.png",
    })

end
