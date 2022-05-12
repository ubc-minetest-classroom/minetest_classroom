-- NONE OF THIS IS DONE OR NECESSARILY CORRECT JUST STARTING TO PUT IN RELEVANT STUFF FROM HERE: 
-- https://github.com/minetest-mods/nether/blob/master/portal_api.lua

-- setting DEBUG_IGNORE_MODSTORAGE true prevents portals from knowing where other
-- portals are, forcing find_realm_anchorpos() etc. to be executed every time.
local DEBUG_IGNORE_MODSTORAGE = false

mc_portal.registered_portals = {}
mc_portal.registered_portals_count = 0

-- Exposes a list of node names that are used as frame nodes by registered portals
mc_portal.is_frame_node = {}


-- gives the colour values in portals_palette.png that are used by the wormhole colorfacedir
-- hardware colouring.
mc_portal.portals_palette = {
	[0] = {r = 128, g =   0, b = 128, asString = "#800080"}, -- magenta
	[1] = {r =   0, g =   0, b =   0, asString = "#000000"}, -- black
	[2] = {r =  19, g =  19, b = 255, asString = "#1313FF"}, -- blue
	[3] = {r =  55, g = 168, b =   0, asString = "#37A800"}, -- green
	[4] = {r = 141, g = 237, b = 255, asString = "#8DEDFF"}, -- cyan
	[5] = {r = 221, g =   0, b =   0, asString = "#DD0000"}, -- red
	[6] = {r = 255, g = 240, b =   0, asString = "#FFF000"}, -- yellow
	[7] = {r = 255, g = 255, b = 255, asString = "#FFFFFF"}  -- white
}


if minetest.get_mod_storage == nil then
	error(nether.modname .. " does not support Minetest versions earlier than 0.4.16", 0)
end

local S = mc_portal.get_translator
mc_portal.portal_destination_not_found_message =
	S("Mysterious forces prevented you from opening that portal. Please try another location")

