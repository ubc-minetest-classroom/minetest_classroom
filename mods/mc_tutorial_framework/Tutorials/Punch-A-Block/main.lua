dofile(mc_tutorialFramework.path .. "/Tutorials/Punch-A-Block/blocks.lua")

tutorial = { hud = mhud.init() }

local tutorialStage = 0

function tutorial.blockDestroyed(pos, oldnode, oldmetadata, digger, nodeName)
    local pmeta = digger:get_meta()
    local key = "Break:" .. nodeName

    local oldBTBValue = pmeta:get_int(key) or 0
    pmeta:set_int(key, oldBTBValue + 1)

    tutorial.Progress(digger)
end

function tutorial.startTutorial(player)
    local pmeta = player:get_meta()
    minetest.debug("Started tutorial...")

    --Reset player block break counter
    pmeta:set_int("breakTutorialBlock", 0)

    tutorial.CreateHUD(player)
end

function tutorial.Progress(player)
    local pmeta = player:get_meta()

    local key = "Break:" .. ""
    local oldBTBValue = pmeta:get_int(key) or 0

    tutorial.updateHud(player, key, 5, " blocks")


end

function tutorial.CreateHUD(player, statKey, Goal, HelpText)

    statKey = statKey or "breakTutorialBlock"
    Goal = Goal or 5
    HelpText = HelpText or " Blocks"

    local meta = player:get_meta()
    local blocksBroken_text = "Broke: " .. meta:get_int(statKey) .. "/" .. Goal .. HelpText

    tutorial.hud:add(player, "pab:title", {
        hud_elem_type = "text",
        position = { x = 1, y = 0 },
        offset = { x = -6, y = 0 },
        alignment = { x = "left", y = "down" },
        text = "Punch-A-Block Tutorial",
        color = 0x00FF00,
    })

    tutorial.hud:add(player, "pab:stat", {
        hud_elem_type = "text",
        position = { x = 1, y = 0 },
        offset = { x = -6, y = 18 },
        alignment = { x = "left", y = "down" },
        text = blocksBroken_text,
        color = 0x00FF00,
    })


end

function tutorial.updateHud(player, statKey, Goal, HelpText)
    statKey = statKey or "breakTutorialBlock"
    Goal = Goal or 5
    HelpText = HelpText or " Blocks"

    local meta = player:get_meta()
    local blocksBroken_text = "Broke: " .. meta:get_int(statKey) .. "/" .. Goal .. HelpText

    tutorial.hud:change(player, "pab:stat", {
        hud_elem_type = "text",
        position = { x = 1, y = 0 },
        offset = { x = -6, y = 18 },
        alignment = { x = "left", y = "down" },
        text = blocksBroken_text,
        color = 0x00FF00,
    })


end

minetest.register_on_joinplayer(function(player)

    tutorial.startTutorial(player)
    return true
end)



