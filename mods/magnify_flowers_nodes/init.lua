local magnify = dofile(minetest.get_modpath("magnify") .. "/exports.lua")

--[[
local template = {
	sci_name = "",
	com_name = "",
	fam_name = "",
	cons_status = "",
	status_col = "", 
	height = "",
	bloom = "",
	region = "",
	texture = "", 
	more_info = "",
	external_link = "",
	img_copyright or img_credit = "" -- one, not both
}
]]

-- TASK: finish tables
local black_lily = {
	sci_name = "Fritillaria affinis",
	com_name = "Chocolate Lily",
	fam_name = "Liliaceae (Lily Family)",
	cons_status = "S5 - Demonstrably widespread, abundant, and secure",
	status_col = "#666ae3", -- S5
	height = "20 to 80 centimeters tall",
	bloom = "Blooms with a single bell-like flower or with 2-5 flowers in a cluster",
	region = "Southern BC, Washington, Oregon and California",
	texture = "fritillaria-affinis.jpg",
	more_info = "A small, thin, bell-like perennial herb. Also known as the checkered lily, due to the greenish-yellow patterns that appear on its purple flowers. Typically found in grassy bluffs, meadows, and open forests.",
	external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Fritillaria%20affinis",
	img_copyright = "Jackie Chambers, licensed under CC BY-NC-SA 4.0" -- cropped, https://botanyphoto.botanicalgarden.ubc.ca/2008/05/fritillaria-affinis/
}
magnify.register_plant(black_lily, {"flowers:tulip_black"})

local camas = {
	sci_name = "Camassia leichtlinii",
	com_name = "Great Camas",
	fam_name = "Asparagaceae (Asparagus Family)",
	cons_status = "S4 - Apparently secure",
	status_col = "#4fbdf0", -- S4
	height = "20 to 100 centimeters tall",
	bloom = "Blooms in groups of 5 or more flowers, ranging from pale to deep blue",
	region = "Southern BC, Washington, Oregon and California",
	--texture = "", 
	more_info = "A small perennial with stalked flowers and long, thin leaves at its stem. Typically found in vernally moist, meadowed areas.",
	external_link = "http://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Camassia%20leichtlinii"
	--img_copyright or img_credit = ""
}
magnify.register_plant(camas, {"flowers:geranium"})

local clover = {
	sci_name = "Trifolium cyathiferum",
	com_name = "Cup Clover",
	fam_name = "Fabaceae (Pea family)",
	cons_status = "S3 - Special concern, vulnerable to extirpation or extinction",
	status_col = "#e0dd10", -- S3
	height = "10 to 50 centimeters tall",
	bloom = "Blooms with a hemispherical, axillary head of 5 to 30 green pea-like flowers",
	region = "Southern BC and Western USA",
	texture = "Trifolium_cyathiferum.jpg", 
	more_info = "A small, upright annual herb with leaves resembling three-leaf clovers, often with white, pink, or cream-coloured flowers.",
	external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Trifolium%20cyathiferum",
	img_credit = "Mary Winter, via Wikimedia Commons"
}
magnify.register_plant(clover, {"flowers:chrysanthemum_green"})

local rose = {
	sci_name = "Castilleja miniata",
	com_name = "Scarlet Paintbrush",
	fam_name = "Orobanchaceae (Broom-rape family)",
	cons_status = "S5 - Demonstrably widespread, abundant, and secure",
	status_col = "#666ae3", -- S5
	height = "20 to 80 centimeters tall",
	bloom = "Blooms with a bracted terminal spike, with red, scarlet, or orange bracts",
	region = "BC and Western USA",
	texture = "Castilleja_miniata_var._miniata.jpg", 
	more_info = "A stout, hairy perennial herb with a woody, scaly base. Typically found in areas such as meadows, grassy slopes, clearings, roadsides, and open forests.",
	external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Castilleja%20miniata%20var.%20miniata",
	img_copyright = "Thayne Tuason, licensed under CC BY-SA 4.0" -- cropped, https://commons.wikimedia.org/wiki/File:Castilleja_miniata_var._miniata.jpg
}
magnify.register_plant(rose, {"flowers:rose"})

local poppy = {
	sci_name = "Eschscholzia californica",
	com_name = "California poppy",
	fam_name = "Papaveraceae (Fumitory family)",
	cons_status = "Exotic - Conservation status not applicable",
	status_col = "#f772e9", -- Exotic
	height = "10 to 50 centimeters tall",
	bloom = "Blooms with orange-yellow saucer-shaped flowers, either axillary or terminal",
	region = "USA and Mexico, found worldwide",
	texture = "Eschscholzia.jpg", 
	more_info = "A short-lived, upright perennial herb originating from a deep taproot. Typically found in dry areas such as roadsides, rock outcrops, and wastelands.",
	external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Eschscholzia%20californica",
	img_credit = "the UBC Botanical Garden"
}
magnify.register_plant(poppy, {"flowers:tulip"})

local viola = {
	sci_name = "Plectritis congesta",
	com_name = "Shortspur Seablush",
	fam_name = "Caprifoliaceae (Valerian family)",
	cons_status = "S5 - Demonstrably widespread, abundant, and secure",
	status_col = "#666ae3", -- S5
	height = "10 to 60 centimeters tall",
	bloom = "Blooms with a round cluster of small white or pink flowers",
	region = "Southern BC, Washington, Oregon and California",
	--texture = "", 
	more_info = "An solitary, upright, annual herb originating from a taproot. Typically found in mesic and vernally moist meadows, and in dry rocky areas.",
	external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Plectritis%20congesta"--,
	--img_copyright or img_credit = ""
}
magnify.register_plant(viola, {"flowers:viola"})

local pearl = {
	sci_name = "Anaphalis margaritacea",
	com_name = "Pearly Everlasting",
	fam_name = "Asteraceae (Aster Family)",
	cons_status = "S5 - Demonstrably widespread, abundant, and secure",
	status_col = "#666ae3", -- S5
	height = "20 to 90 centimeters tall",
	bloom = "Blooms with a dense cluster of disc-like flowers, forming a flat top",
	region = "various countries, including Canada, the USA, Mexico, and Japan",
	texture = "Anapahlis_margaritacea.jpg", 
	more_info = "A single-stemmed perennial herb with alternating leaves and white flowers. Typically found in meadows, open forests, fields, and along roadsides.",
	external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Anaphalis%20margaritacea",
	img_credit = "Wikimedia Commons" -- one, not both
}
magnify.register_plant(pearl, {"flowers:dandelion_white"})

local susan = {
	sci_name = "Gaillardia aristata",
	com_name = "Brown Eyed Susan",
	fam_name = "Asteraceae (Aster Family)",
	cons_status = "S5 - Demonstrably widespread, abundant, and secure",
	status_col = "#666ae3", -- S5
	height = "20 to 70 centimeters tall",
	bloom = "Blooms with solitary or few ray and disk flowers, all with purplish bases",
	region = "BC, Alberta, Saskatchewan, Manitoba, and Northwest USA",
	--texture = "", 
	more_info = "A hairy, long-stalked perennial originating from a taproot, with coarse-toothed or pinnately-cut base leaves and yellow flowers. Typically found in dry grasslands, shrublands, and moist sand bars.",
	external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Gaillardia%20aristata"--,
	--img_copyright or img_credit = "" -- one, not both
}
magnify.register_plant(susan, {"flowers:dandelion_yellow"})
