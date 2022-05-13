local magnify = dofile(minetest.get_modpath("magnify").."/exports.lua")

local aspen = {
	sci_name = "Populus tremuloides",
	com_name = "Quaking Aspen",
	region = "most of North America",
	status = "Common",
	more_info = "Smooth-barked, randomly-branching tree, with leaves that turn golden in the fall",
	external_link = "https://www.britannica.com/plant/aspen-plant"
}
magnify.register_plant(aspen, {"default:aspen_tree", "default:aspen_wood", "default:aspen_leaves", "default:aspen_sapling"})

local pine = {
  sci_name = "Pinus ponderosa",
  com_name = "Ponderosa Pine",
  region = "Northern Hemisphere",
  texture = "pine_tree.png",
  status = "Common",
  more_info = "Large, straight trunked tree with a wide, open, irregularly cylindrical crown",
  external_link = "https://www.britannica.com/plant/pine"
}
magnify.register_plant(pine, {"default:pine_tree", "default:pine_wood","default:pine_needles", "default:pine_sapling"})

local AppleTree = {
  sci_name = "Malus domestica 'Gala",
  com_name = "Semi-dwarf Apple Tree",
  region = "Interior of BC, Southern Ontario & Quebec",
  texture = "apple_tree.png",
  status = "Common",
  more_info = "Very crisp, medium-sized, semi-sweet fruit with a thin, red-striped skin that is very aromatic",
  external_link = "https://www.arborday.org/trees/treeguide/TreeDetail.cfm?ItemID=2513"
}
magnify.register_plant(AppleTree, {"default:tree", "default:apple", "default:apple_mark", "default:leaves", "default:sapling"})

--[[
local JungleTree = {
  sci_name = 
  com_name = 
  region = 
  texture = 
  
  	
  
  
}
magnify.register_plant(JungleTree, {"default:jungletree", "default:jungleleaves", "default:junglesapling", "default:emergent_jungle_sapling"})
]]

local blueberry = {
  sci_name = "Vaccinium corymbosum",
  com_name = "Highbush Blueberry",
  region = "Eastern Canada & Eastern USA",
	status = "Common",
	more_info = "One of many species of blueberries, cultivated in North America, South America, and Central Europe",
}
magnify.register_plant(blueberry, {"default:blueberry_bush_leaves", "default:blueberry_bush_leaves_with_berries", "default:blueberries"})