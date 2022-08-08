--[[
local template = {
    sci_name = "",        -- Scientific name of species
    com_name = "",        -- Common name of species
    fam_name = "",        -- Family name of species

    cons_status = {       -- Conservation statuses of species
        ns_global = "",       -- NatureServe global status
        ns_bc = "",           -- NatureServe BC status
        bc_list = ""          -- BC List (Red Blue List) status
    },
    region = "",          -- Native region/range of species (displayed as "Found in [region]")
    height = "",          -- Species height
    more_info = "",       -- Extended description of species
    bloom = "",           -- The way the species blooms

    texture = {""},       -- Images of species (in `mod/textures`) - can be a string if only one image
    model_obj = "",       -- Model file (in `mod/models`)
    model_rot_x = 0,      -- Initial rotation of model about x-axis (in degrees; defaults to 0)
    model_rot_y = 0,      -- Initial rotation of model about y-axis (in degrees; defaults to 180)

    external_link = "",   -- Link to page with more species information
    img_copyright = "",   -- Copyright owner of species image (displayed as "Image (c) [img_copyright]")
    img_credit = ""       -- Author of species image (displayed as "Image courtesy of [img_credit]")
}
-- Species registration call
magnify.register_species(template, {"mod:node", "mod:another_node", "other_mod:other_node"})
]]

-- TASK: finish tables
local black_lily = {
    sci_name = "Fritillaria affinis",
    com_name = "Chocolate Lily",
    fam_name = "Liliaceae",
    cons_status = {ns_bc = "S5"},
    height = "20 to 80 centimeters tall",
    bloom = "Blooms with a single bell-like flower or with 2-5 flowers in a cluster",
    region = "Southern BC, Washington, Oregon and California",
    texture = "magnify_flowers_fritillaria_affinis.jpg",
    model_obj = "magnify_flowers_fritillaria_affinis.obj",
    more_info = "A small, thin, bell-like perennial herb. Also known as the checkered lily, due to the greenish-yellow patterns that appear on its purple flowers. Typically found in grassy bluffs, meadows, and open forests.",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Fritillaria%20affinis",
    img_copyright = "Walter Siegmund, licensed under CC BY-SA 3.0"
}
magnify.register_species(black_lily, {"flowers:tulip_black"})

local camas = {
    sci_name = "Camassia leichtlinii",
    com_name = "Great Camas",
    fam_name = "Asparagaceae",
    cons_status = {ns_bc = "S4"},
    height = "20 to 100 centimeters tall",
    bloom = "Blooms in groups of 5 or more flowers, ranging from pale to deep blue",
    region = "Southern BC, Washington, Oregon and California",
    texture = "magnify_flowers_camassia_leichtlinii.jpg",
    model_obj = "magnify_flowers_camassia_leichtlinii.obj",
    more_info = "A small perennial with stalked flowers and long, thin leaves at its stem. Typically found in vernally moist, meadowed areas.",
    external_link = "http://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Camassia%20leichtlinii",
    img_credit = "Gentry George, U.S. Fish and Wildlife Service"
}
magnify.register_species(camas, {"flowers:geranium"})

local clover = {
    sci_name = "Trifolium cyathiferum",
    com_name = "Cup Clover",
    fam_name = "Fabaceae",
    cons_status = {ns_bc = "S3"},
    height = "10 to 50 centimeters tall",
    bloom = "Blooms with a hemispherical, axillary head of 5 to 30 green pea-like flowers",
    region = "Southern BC and Western USA",
    texture = "magnify_flowers_trifolium_cyathiferum.jpg", 
    model_obj = "magnify_flowers_trifolium_cyathiferum.obj",
    more_info = "A small, upright annual herb with leaves resembling three-leaf clovers, often with white, pink, or cream-coloured flowers.",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Trifolium%20cyathiferum",
    img_credit = "Mary Winter, via Wikimedia Commons"
}
magnify.register_species(clover, {"flowers:chrysanthemum_green"})

local rose = {
    sci_name = "Castilleja miniata",
    com_name = "Scarlet Paintbrush",
    fam_name = "Orobanchaceae",
    cons_status = {ns_bc = "S5"},
    height = "20 to 80 centimeters tall",
    bloom = "Blooms with a bracted terminal spike, with red, scarlet, or orange bracts",
    region = "BC and Western USA",
    texture = "magnify_flowers_castilleja_miniata_var_miniata.jpg",
    model_obj = "magnify_flowers_castilleja_miniata.obj",
    more_info = "A stout, hairy perennial herb with a woody, scaly base. Typically found in areas such as meadows, grassy slopes, clearings, roadsides, and open forests.",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Castilleja%20miniata%20var.%20miniata",
    img_copyright = "Thayne Tuason, licensed under CC BY-SA 4.0"
}
magnify.register_species(rose, {"flowers:rose"})

local poppy = {
    sci_name = "Eschscholzia californica",
    com_name = "California poppy",
    fam_name = "Papaveraceae",
    cons_status = {ns_bc = "Exotic"},
    height = "10 to 50 centimeters tall",
    bloom = "Blooms with orange-yellow saucer-shaped flowers, either axillary or terminal",
    region = "USA and Mexico, found worldwide",
    texture = "magnify_flowers_eschscholzia_californica.jpg",
    model_obj = "magnify_flowers_eschscholzia_californica.obj",
    more_info = "A short-lived, upright perennial herb originating from a deep taproot. Typically found in dry areas such as roadsides, rock outcrops, and wastelands.",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Eschscholzia%20californica",
    img_credit = "the UBC Botanical Garden"
}
magnify.register_species(poppy, {"flowers:tulip"})

local viola = {
    sci_name = "Plectritis congesta",
    com_name = "Shortspur Seablush",
    fam_name = "Caprifoliaceae",
    cons_status = {ns_bc = "S5"},
    height = "10 to 60 centimeters tall",
    bloom = "Blooms with a round cluster of small white or pink flowers",
    region = "Southern BC, Washington, Oregon and California",
    texture = "magnify_flowers_plectritis_congesta.jpg",
    model_obj = "magnify_flowers_plectritis_congesta.obj",
    more_info = "An solitary, upright, annual herb originating from a taproot. Typically found in mesic and vernally moist meadows, and in dry rocky areas.",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Plectritis%20congesta",
    img_copyright = "Walter Siegmund, licensed under CC BY-SA 3.0"
}
magnify.register_species(viola, {"flowers:viola"})

local pearl = {
    sci_name = "Anaphalis margaritacea",
    com_name = "Pearly Everlasting",
    fam_name = "Asteraceae",
    cons_status = {ns_bc = "S5"},
    height = "20 to 90 centimeters tall",
    bloom = "Blooms with a dense cluster of disc-like flowers, forming a flat top",
    region = "various countries, including Canada, the USA, Mexico, and Japan",
    texture = "magnify_flowers_anaphalis_margaritacea.jpg",
    model_obj = "magnify_flowers_anaphalis_margaritacea.obj",
    more_info = "A single-stemmed perennial herb with alternating leaves and white flowers. Typically found in meadows, open forests, fields, and along roadsides.",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Anaphalis%20margaritacea",
    img_credit = "Wikimedia Commons"
}
magnify.register_species(pearl, {"flowers:dandelion_white"})

local susan = {
    sci_name = "Gaillardia aristata",
    com_name = "Brown Eyed Susan",
    fam_name = "Asteraceae",
    cons_status = {ns_bc = "S5"},
    height = "20 to 70 centimeters tall",
    bloom = "Blooms with solitary or few ray and disk flowers, all with purplish bases",
    region = "BC, Alberta, Saskatchewan, Manitoba, and Northwest USA",
    texture = "magnify_flowers_gaillardia_aristata.jpg",
    model_obj = "magnify_flowers_gaillardia_aristata.obj",
    more_info = "A hairy, long-stalked perennial originating from a taproot, with coarse-toothed or pinnately-cut base leaves and yellow flowers. Typically found in dry grasslands, shrublands, and moist sand bars.",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Gaillardia%20aristata",
    img_credit = "David Whelan, via Wikimedia Commons"
}
magnify.register_species(susan, {"flowers:dandelion_yellow"})

local brown_mushroom = {
    sci_name = "Boletus edulis",
    com_name = "King bolete",
    fam_name = "Boletaceae",
    cons_status = {ns_bc = "NR"},
    height = "8 to 25 centimeters tall",
    bloom = "The caps might have a white bloom on them - a dusty white powdered substance that easily brushes off",         
    region = "the Pacific Northwest, often in hemlock (Tsuga heterophylla), spruce (Picea sitchensis), pine (Pinus spp.) and fir (Abies spp.) forests",        
    texture = "magnify_flowers_boletus_edulis.jpg",
    model_obj = "magnify_flowers_boletus_edulis.obj",
    more_info = "The fungus grows in deciduous and coniferous forests and tree plantations, forming symbiotic ectomycorrhizal associations with living trees by enveloping the tree's underground roots with sheaths of fungal tissue",
    external_link = "https://www.zoology.ubc.ca/~biodiv/mushroom/B_edulis.html",  
    img_copyright = "Holger Krisp, licensed under CC BY 3.0"  
}
magnify.register_species(brown_mushroom, {"flowers:mushroom_brown"})

local waterlily = {
    sci_name = "Nuphar polysepala",
    com_name = "Rocky Mountain pond-lily",
    fam_name = "Nymphaeaceae",
    cons_status = {ns_bc = "S5"},
    height = "1 to 2 meters long",
    bloom = "Blooms with solitary, waxy, floating yellow flowers stemming from a rhizome",
    region = "BC, Yukon, Northwest USA and Alaska",
    texture = "magnify_flowers_nuphar_polysepala.jpg",
    model_obj = "magnify_flowers_nuphar_polysepala.obj",
    model_rot_x = -35,
    more_info = "An aquatic perennial with long-stalked, leathery leaves. Found in ponds and slow-moving streams in lowland, steppe, and montane areas",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Nuphar%20polysepala",
    img_copyright = "Marshal Hedin, licensed under CC BY 2.0"
}
magnify.register_species(waterlily, {"flowers:waterlily", "flowers:waterlily_waving"})

local agaric = {
    sci_name = "Amanita muscaria",
    com_name = "Fly agaric",
    fam_name = "Amanitaceae",
    cons_status = {ns_bc = "Unlisted"},
    height = "7 to 20 centimeters tall",
    bloom = "Produces smooth, white, ellipsoid, inamyloid spores",
    region = "various areas in the Northern Hemisphere, including California",
    texture = "magnify_flowers_amanita_muscaria.jpg",
    model_obj = "magnify_flowers_amanita_muscaria.obj",
    more_info = "A bright red-capped fungus with white warts. Often found on the ground scattered, in dense patches, or in large fairy rings under Pinus (pine), Picea (spruce), and Betula (birch) trees",
    external_link = "https://www.zoology.ubc.ca/~biodiv/mushroom/A_muscaria.html",
    img_copyright = "Dr. Hans-Günter Wagner, licensed under CC BY-SA 2.0"
}
magnify.register_species(agaric, {"flowers:mushroom_red"})