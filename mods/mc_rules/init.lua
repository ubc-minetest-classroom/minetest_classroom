server_rules = {}

function server_rules.get_formspec(name)
    local Header = "Server Rules"
    local Rule_1 = "1. The University of British Columbia student Code of Conduct applies."
    local Rule_2 = "2. No harassing: spamming chat, blocking other player's view, entrapping other players."
    local Rule_3 = "3. No destroying the world or other player's creations."
    local Rule_4 = "4. Follow the instructions of your professor and teaching assistant at all times."
    local serveruse = "Your continued use of this server consitutes your agreement with the rules above."
    local disclaimer = "Server maintained for research and educational purposes by UBC Faculty of Forestry."
    local admini = "Administered by Prof. Paul Pickell (paul.pickell@ubc.ca) aka 'Prof_Pickell'."
    local rulescmd = "Type /rules in chat to see these rules again."

    local formspec = {
        "formspec_version[4]",
        "size[13,10]",
        "image[0.375,0.5;6.5,2.04;ubc_forestry_logo.png]",
        "label[0.375,3;", minetest.formspec_escape(Header), "]",
        "label[0.375,3.75;", minetest.formspec_escape(Rule_1), "]",
        "label[0.375,4.5;", minetest.formspec_escape(Rule_2), "]",
        "label[0.375,5.25;", minetest.formspec_escape(Rule_3), "]",
        "label[0.375,6;", minetest.formspec_escape(Rule_4), "]",
        "label[0.375,6.75;", minetest.formspec_escape(disclaimer), "]",
        "label[0.375,7.5;", minetest.formspec_escape(admini), "]",
        "label[0.375,8.25;", minetest.formspec_escape(rulescmd), "]",
        "button_exit[0.375,9;2,0.8;agree;Agree]"
    }

    return table.concat(formspec, "")
end

minetest.register_chatcommand("rules", {
	params = "",
	description = "Server rules",
	func = function(name, param)
	minetest.after((0.1), function()
		return minetest.show_formspec(name, "server_rules:rules", server_rules.get_formspec())
	end)
end})

minetest.register_on_joinplayer(function(player)
	minetest.show_formspec(player:get_player_name(), "server_rules:rules", server_rules.get_formspec())
end)