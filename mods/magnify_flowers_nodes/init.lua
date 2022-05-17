local magnify = dofile(minetest.get_modpath("magnify") .. "/exports.lua")

-- TASK: finish tables
local black_lily = {
	sci_name = "Fritillaria affinis",
	com_name = "Chocolate Lily",
	region = "Southern BC and California",
	texture = "chocolate_lily.png",
	status = "Threatened",
	more_info = "A small, purple, bell-like flower with green and yellow spots throughout",
	external_link = "https://botanyphoto.botanicalgarden.ubc.ca/2008/05/fritillaria-affinis/"
}
magnify.register_plant(black_lily, {"flowers:tulip_black"})