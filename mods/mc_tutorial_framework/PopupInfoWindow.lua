mc_tutorialFramework.infoWindow = {}

function mc_tutorialFramework.infoWindow.get_formspec(name, message)
    message = message or ""

    local formspec = {
        "formspec_version[5]",
        "size[8,10]",
        "button_exit[2.5,9.1;2.9,0.7;Close;Close Window]",
        "textarea[1,1;6,8;Message;Message;", minetest.formspec_escape(message), "]",
    }

    -- table.concat is faster than string concatenation - `..`
    return table.concat(formspec, "")
end

function mc_tutorialFramework.infoWindow.show_to(player, message)
    minetest.show_formspec(player:get_player_name(), "mc_tutorialFramework:infoWindow", mc_tutorialFramework.infoWindow.get_formspec(name, message))
end