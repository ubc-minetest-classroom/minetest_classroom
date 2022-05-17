local magnify = dofile(minetest.get_modpath("magnify").."/exports.lua")

-- TASK: finish tables
local aspen = {
	sci_name = "Populus tremuloides",
	com_name = "Quaking Aspen",
	region = "most of North America",
	texture = "test.png", 
	status = "Common",
	more_info = "Smooth-barked, randomly-branching tree. Also known as the golden aspen, due to the golden colour its leaves turn in the fall.",
	external_link = "https://www.britannica.com/plant/aspen-plant"
}
magnify.register_plant(aspen, {"default:aspen_tree", "default:aspen_wood", "default:aspen_leaves", "default:aspen_sapling"})

local pine = {
	sci_name = "Pinus ponderosa",
	com_name = "Ponderosa Pine",
	region = "the Northern Hemisphere",
	texture = "pine_tree.jpg",
	status = "Common",
	more_info = "Large, straight trunked tree with a wide, open, irregularly cylindrical crown",
	external_link = "https://www.britannica.com/plant/pine"
}
magnify.register_plant(pine, {"default:pine_tree", "default:pine_wood","default:pine_needles", "default:pine_sapling"})

local AppleTree = {
	sci_name = "Malus domestica 'Gala",
	com_name = "Semi-dwarf Apple Tree",
	region = "the BC Interior, Southern Ontario & Quebec",
	texture = "apple_tree.jpg",
	status = "Common",
	more_info = "Bears very crisp, medium-sized, semi-sweet fruit with a thin, red-striped skin that is very aromatic",
	external_link = "https://www.arborday.org/trees/treeguide/TreeDetail.cfm?ItemID=2513"
}
magnify.register_plant(AppleTree, {"default:tree", "default:apple", "default:apple_mark", "default:leaves", "default:sapling"})

local JungleTree = {
	sci_name = "Ceiba pentandra",
	com_name = "Kapok Tree",
	region = "Mexico, Central America and the Caribbean",
	texture = "jungle_tree.jpg",
	status = "Common",
	more_info = "The kapok is deciduous, dropping its foliage after seasonal rainy periods.",
	external_link = "https://www.britannica.com/topic/kapok"
}
magnify.register_plant(JungleTree,{"default:jungletree","default:junglewood","default:jungleleaves","default:junglesapling","default:emergent_jungle_sapling"})

local Kelp = {
	sci_name = "Phaeophyceae",
	com_name = "Brown Algae" ,
	region = "the Waters of the Northern Hemisphere",
	texture = "kelp.jpg",
	status = "Common",
	more_info = "Brown algae are the major seaweeds of the temperate and polar regions",
	external_link = "https://www.britannica.com/science/brown-algae"
}
magnify.register_plant(Kelp,{"default:sand_with_kelp"})

local blueberry = {
	sci_name = "Vaccinium corymbosum",
	com_name = "Highbush Blueberry",
	region = "Eastern Canada & Eastern USA",
	texture = "test.png", 
	status = "Common",
	more_info = "One of many species of blueberries, cultivated in North America, South America, and Central Europe",
	external_link = ""
}
magnify.register_plant(blueberry, {"default:blueberry_bush_leaves", "default:blueberry_bush_leaves_with_berries", "default:blueberries"})