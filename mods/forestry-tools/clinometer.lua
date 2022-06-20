-- IN-PROGRESS: show yaw (horizontal angle) and pitch (vertical viewing angle) in degrees.

local clin_hud = {}
clin_hud.playerhuds = {}
clin_hud.settings = {}
clin_hud.settings.hud_pos = { x = 0.5, y = 0 }
clin_hud.settings.hud_offset = { x = 0, y = 15 }
clin_hud.settings.hud_alignment = { x = 0, y = 0 }

local set = tonumber(minetest.settings:get("clin_hud_pos_x"))
if set then clin_hud.settings.hud_pos.x = set end
set = tonumber(minetest.settings:get("clin_hud_pos_y"))
if set then clin_hud.settings.hud_pos.y = set end
set = tonumber(minetest.settings:get("clin_hud_offset_x"))
if set then clin_hud.settings.hud_offset.x = set end
set = tonumber(minetest.settings:get("clin_hud_offset_y"))
if set then clin_hud.settings.hud_offset.y = set end
set = minetest.settings:get("clin_hud_alignment")
if set == "left" then
	clin_hud.settings.hud_alignment.x = 1
elseif set == "center" then
	clin_hud.settings.hud_alignment.x = 0
elseif set == "right" then
	clin_hud.settings.hud_alignment.x = -1
end

local lines = 4 -- # of HUD Lines

local S = forestry_tools.S

-- DIsplay player horizontal and vertical It shows you your pitch (vertical viewing angle) in degrees.


minetest.register_tool("forestry_tools:clinometer", {
	description = S("Yaw (horizontal) and Sextant (vertical)"),
	_tt_help = S("Shows your pitch"),
	_doc_items_longdesc = S("It shows your pitch (vertical viewing angle) in degrees. and your sextant (horizontal viewing angle) in degrees"),
	_doc_items_usagehelp = use,
	wield_image = "clinometer.png",
	inventory_image = "clinometer.png",
	groups = { disable_repair = 1 },
	_mc_tool_privs = forestry_tools.priv_table,

    -- Destroy the item on_drop to keep things tidy
	on_drop = function (itemstack, dropper, pos)
	end
})



minetest.register_alias("clinometer", "forestry_tools:clinometer")
clinometer = minetest.registered_aliases[clinometer] or clinometer





--[[

local yaw = 360 - player:get_look_horizontal()*toDegrees
local pitch = player:get_look_vertical()*toDegrees

if (clinometer) then 
    str_angles = S("Yaw: @1°, pitch: @2°", string.format("%.1f", yaw), string.format("%.1f", pitch))
]]
