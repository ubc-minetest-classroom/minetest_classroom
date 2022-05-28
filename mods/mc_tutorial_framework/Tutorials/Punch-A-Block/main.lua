dofile(mc_tutorialFramework.path .. "/Tutorials/Punch-A-Block/blocks.lua")

tutorial = { hud = mhud.init() }

tutorial.tutorialStage = {}

function tutorial.blockDestroyed(pos, oldnode, oldmetadata, player)
    local pmeta = player:get_meta()

    -- Make sure we're in the tutorial before wasting resources
    if (pmeta:get_string("startedPunchABlock") ~= "true") then
        return
    end

    local key = "Break:" .. oldnode.name

    minetest.debug(key)

    local oldValue = pmeta:get_int(key) or 0
    local newValue = oldValue + 1
    pmeta:set_int(key, newValue)

    tutorial.progress(player)
end

function tutorial.progress(player)
    local pmeta = player:get_meta()

    local levels = {}
    levels[0] = { key = "Break:mc_tf:handBreakable", goal = 4,
                  welcomeText = "Welcome! Use your hand to break the purple blocks!",
                  helpText = "Hand Breakable Blocks",
                  reward = ItemStack("default:shovel_steel") }

    levels[1] = { key = "Break:mc_tf:shovelBreakable", goal = 4,
                  welcomeText = "Level up! Use your new shovel to break the ____ blocks!",
                  helpText = "Shovel Breakable Blocks",
                  reward = ItemStack("default:pick_steel") }

    levels[2] = { key = "Break:mc_tf:pickBreakable", goal = 4,
                  helpText = "Pickaxe Breakable Blocks",
                  welcomeText = "Level up! Use your new pickaxe to break the ____ blocks!",
                  reward = ItemStack("default:axe_steel") }

    levels[3] = { key = "Break:mc_tf:axeBreakable", goal = 4,
                  helpText = "Axe Breakable Blocks",
                  welcomeText = "Level Up! You're now a lumberjack! Go cut some wood",
                  reward = ItemStack("default:diamond") }

    local level = levels[tutorial.tutorialStage[player]]
    local key = level.key
    local goal = level.goal
    local value = pmeta:get_int(key)

    if (value > goal) then
        if (level.reward ~= nil) then
            player:get_inventory():add_item("main", level.reward)
        end

        tutorial.tutorialStage[player] = tutorial.tutorialStage[player] + 1
        level = levels[tutorial.tutorialStage[player]]

        if (level == nil) then
            minetest.debug("Congratulations! You finished the tutorial")
        else
            if (level.welcomeText ~= nil) then
                minetest.debug(level.welcomeText)
            end
        end

    end

    tutorial.updateHud(player, key, 5, " " .. level.helpText)
end

function tutorial.startTutorial(player)
    local pmeta = player:get_meta()

    minetest.debug("Started tutorial...")

    tutorial.CreateHUD(player)

    --Reset all our values
    tutorial.tutorialStage[player] = 0
    pmeta:set_int("Break:mc_tf:handBreakable", 0)
    pmeta:set_int("Break:mc_tf:shovelBreakable", 0)
    pmeta:set_int("Break:mc_tf:spadeBreakable", 0)
    pmeta:set_int("Break:mc_tf:axeBreakable", 0)

    -- Set that we're in a tutorial
    pmeta:set_string("startedPunchABlock", "true")
end

function tutorial.endTutorial(player)
    local pmeta = player:get_meta()

    -- Clear that we're in a tutorial
    pmeta:set_string("startedPunchABlock", nil)

    --Clear all our meta values
    tutorial.tutorialStage[player] = nil
    pmeta:set_int("Break:mc_tf:handBreakable", nil)
    pmeta:set_int("Break:mc_tf:shovelBreakable", nil)
    pmeta:set_int("Break:mc_tf:spadeBreakable", nil)
    pmeta:set_int("Break:mc_tf:axeBreakable", nil)

    tutorial.removeHUD(player)
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

function tutorial.removeHUD(player)
    tutorial.hud:remove(player)
end

minetest.register_on_joinplayer(function(player)

    tutorial.startTutorial(player)
    return true
end)



