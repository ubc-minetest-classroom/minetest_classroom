local magnify = dofile(minetest.get_modpath("magnify").."/exports.lua")

-- TASK: finish tables
local aspen = {
	sci_name = "Populus tremuloides",
	com_name = "Trembling Aspen",
  	fam_name = "Salicaceae (Willow family)", -- NEW
  	cons_status = "S5 - Demonstrably widespread, abundant, and secure", -- NEW
  	status_col = "#666ae3", -- NEW 
  	height = "25 meters tall", -- NEW
  	bloom = "Has smooth, round to triangular-shaped leaves with a flattened stalk", -- NEW 
	region = "most of North America",
	texture = "test.png", 
	more_info = "Smooth-barked, randomly-branching tree. Also known as the golden aspen, due to the golden colour its leaves turn in the fall.",
	external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Populus%20tremuloides"
}
magnify.register_plant(aspen, {"default:aspen_tree", "default:aspen_wood", "default:aspen_leaves", "default:aspen_sapling"})

local pine = {
	sci_name = "Pinus contorta",
	com_name = "Lodgepole Pine",
  	fam_name = "Pinaceae (Pine family)",
  	cons_status = "S5 - Demonstrably widespread, abundant, and secure",
  	status_col = "#666ae3",
    height = "21 to 24 meters tall",
    bloom = "Produces yellowish pollen from May to July, depending on the elevation",
	region = "the Northern Hemisphere",
	texture = "pine_tree.jpg",
	more_info = "Large, straight trunked, column-like tree with a narrow, open crown", -- update
	external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Pinus%20contorta"
}
magnify.register_plant(pine, {"default:pine_tree", "default:pine_wood","default:pine_needles", "default:pine_sapling"})

local AppleTree = {
	sci_name = "Malus fusca",
	com_name = "Pacific crab apple (Oregon crabapple)",
    fam_name = "Rosaceae (Rose family)",
    cons_status = "S5 - Demonstrably widespread, abundant, and secure",
  	status_col = "#666ae3",
  	height = "2 to 12 meters tall",
    bloom = "Has bright, fragrant clusters of 5-12 white/pink flowers on its branch ends",
	region = "the BC Interior, Southern Ontario & Quebec",
	texture = "apple_tree.jpg",
	more_info = "Bears very crisp, medium-sized, semi-sweet fruit with a thin, red-striped skin that is very aromatic",
	external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Malus%20fusca"
}
magnify.register_plant(AppleTree, {"default:tree", "default:apple", "default:apple_mark", "default:leaves", "default:sapling"})

local JungleTree = {
	sci_name = "Alnus rubra",
	com_name = "Red alder",
  	fam_name = "Betulaceae (Birch family)", 
  	cons_status = "S5 - Demonstrably widespread, abundant, and secure",
  	status_col = "#666ae3",
  	height = "Grows up to 24 meters tall",
  	bloom = "Flowers in long, droopy, reddish catkins (male) or short, woody cones (female)",
	region = "",
	texture = "jungle_tree.jpg",
	more_info = "",
	external_link = ""
}
magnify.register_plant(JungleTree,{"default:jungletree","default:junglewood","default:jungleleaves","default:junglesapling","default:emergent_jungle_sapling"})

local Kelp = {
  	sci_name = "Desmarestia ligulata (Lightfoot)",
	com_name = "Flattened acid kelp" ,
  	fam_name = "Desmarestiaceae (Brown algae family)",
  	cons_status = "Unlisted", -- new colour (use default gray?)
  	height = "40 to 80 centimeters tall",
  	bloom = "Blooms are caused by excess silicate in a body of water", -- where a type of algae called “diatoms” thrive
	region = "the waters of the Northern Hemisphere", -- bodies of water across the globe
	texture = "kelp.jpg",
	more_info = "",
	external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Desmarestia%20ligulata"
}
magnify.register_plant(Kelp,{"default:sand_with_kelp"})

local blueberry = {
	sci_name = "Vaccinium ovatum",
	com_name = "Evergreen Huckleberry",
  	fam_name = "Ericaceae (Crowberry family)",
  	cons_status = "S5 - Demonstrably widespread, abundant, and secure",
  	bloom = "pinkish red that blooms from April to May",
	region = "BC",
	texture = "blueberry.png", 
	more_info = "Can tolerate a wide range of light conditions and is very attractive to birds. Foliage is glossy and green with new red growth",
	external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Vaccinium%20ovatum"
}
magnify.register_plant(blueberry, {"default:blueberry_bush_leaves", "default:blueberry_bush_leaves_with_berries", "default:blueberries"})