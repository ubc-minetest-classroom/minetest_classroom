-- SECTIONS BORROWED FROM:
-- https://github.com/minetest-mods/nether/blob/master/portal_api.lua

local S
if minetest.get_translator ~= nil then
    S = minetest.get_translator("portals")
else
    -- mock the translator function for MT 0.4
    S = function(str, ...)
        local args = { ... }
        return str:gsub(
                "@%d+",
                function(match)
                    return args[tonumber(match:sub(2))]
                end
        )
    end
end

portals = {}
portals.modname = minetest.get_current_modname()
portals.path = minetest.get_modpath(portals.modname)
portals.get_translator = S

-- Load files
dofile(portals.path .. "/portals_api.lua")

portals.register_wormhole_node("portals:portal", {
    description = S("Portal"),
    post_effect_color = {
        -- hopefully blue enough to work with blue portals, and green enough to
        -- work with cyan portals.
        a = 120, r = 0, g = 128, b = 188
    }
})

minetest.register_tool("portals:portalwand", {
    description = "Portal Wand",
    inventory_image = "portalWand.png",
    tool_capabilities = {
        groupcaps = {
            choppy = {
                maxlevel = 4,
                uses = 0,
                times = { [1] = 1.60, [2] = 1.20, [3] = 0.80 }
            },
        },
    },
})

minetest.register_alias("portalwand", "portals:portalwand")
portalwand = minetest.registered_aliases[portalwand] or portalwand

-- Portals are ignited by right-clicking with a portalwand
portals.register_portal_ignition_item("portals:portalwand")





