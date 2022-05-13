-- SECTIONS BORROWED FROM:
-- https://github.com/minetest-mods/nether/blob/master/portal_api.lua

local S
if minetest.get_translator ~= nil then
	S = minetest.get_translator("mc_portal")
else
	-- mock the translator function for MT 0.4
	S = function(str, ...)
		local args={...}
		return str:gsub(
			"@%d+",
			function(match) return args[tonumber(match:sub(2))]	end
		)
	end
end

-- Load files
local portal_path = minetest.get_modpath("mc_portal")
dofile(nether.path .. "/portal_api.lua")
dofile(nether.path .. "/surface_portal_test.lua")

--TODO: change this
-- Portals are ignited by right-clicking with a mese crystal fragment
nether.register_portal_ignition_item(
	"default:mese_crystal_fragment",
	{name = "nether_portal_ignition_failure", gain = 0.3}
)



