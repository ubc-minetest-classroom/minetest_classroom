local magnify = dofile(minetest.get_modpath("magnify") .. "/exports.lua")

-- TASK: finish tables
local black_lily = {
	sci_name = "Fritillaria affinis",
	com_name = "Chocolate Lily",
	region = "Southern BC and West Coast USA",
	texture = "fritillaria-affinis.jpg",
	cons_status = "S5 - Demonstrably widespread, abundant, and secure",
	status_col = "#666ae3",
	more_info = "A small, purple, bell-like flower with green and yellow spots throughout. Also known as the checkered lily.",
  	external_link = "https://botanyphoto.botanicalgarden.ubc.ca/2008/05/fritillaria-affinis/",
	img_credit = "Jackie Chambers"
}
magnify.register_plant(black_lily, {"flowers:tulip_black"})

local Bush = {
  	sci_name = "Physocarpus capitatus",
	com_name = "Pacific ninebark",
	region = "Southern BC and California",
	texture = "bush.jpeg",
	cons_status = "S5 - Demonstrably widespread, abundant, and secure",
	status_col = "#666ae3",
	more_info = "Has showy white flower clusters. Attracts native bees and butterflies, and gives great cover for birds and small mammals.",
	external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Physocarpus%20capitatus"
}
magnify.register_plant(Bush, {"default:bush_leaves", "default:bush_stem", "default:bush_sapling"})
