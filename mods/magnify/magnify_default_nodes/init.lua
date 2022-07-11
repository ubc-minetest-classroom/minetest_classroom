--[[
local template = {
    sci_name = "",        -- Scientific name of species
    com_name = "",        -- Common name of species
    fam_name = "",        -- Family name of species
    cons_status = "",     -- Conservation status of species
    status_col = "",      -- Hex colour of status box ("#000000")
    height = "",          -- Plant height
    bloom = "",           -- The way the plant blooms
    region = "",          -- Native region/range of plant (displayed as "Found in [region]")
    texture = {""},       -- Images of plant (in `mod/textures`) - can be a string if only one image
    model_obj = "",       -- Model file (in `mod/models`)
    model_rot_x = 0,      -- Initial rotation of model about x-axis (in degrees; defaults to 0)
    model_rot_y = 0,      -- Initial rotation of model about y-axis (in degrees; defaults to 180)
    more_info = "",       -- Description of plant
    external_link = "",   -- Link to page with more plant information
    img_copyright = "",   -- Copyright owner of plant image (displayed as "Image (c) [img_copyright]")
    img_credit = ""       -- Author of plant image (displayed as "Image courtesy of [img_credit]")
}
-- Plant registration call
magnify.register_plant(template, {"mod:node", "mod:another_node", "other_mod:other_node"})
]]

-- TASK: finish tables
local aspen = {
    sci_name = "Populus tremuloides",
    com_name = "Trembling Aspen",
    fam_name = "Salicaceae (Willow family)",
    cons_status = "S5 - Demonstrably widespread, abundant, and secure",
    status_col = "#666ae3", -- S5
    height = "Grows up to 25 meters tall",
    bloom = "Has smooth, round to triangular-shaped leaves with a flattened stalk",
    region = "most of North America",
    texture = "magnify_default_populus_tremuloides.jpg",
    model_obj = "magnify_default_populus_tremuloides.obj",
    more_info = "Smooth-barked, randomly-branching tree. Also known as the golden aspen, due to the golden colour its leaves turn in the fall.",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Populus%20tremuloides",
    img_copyright = "Tewy, licensed under CC BY-SA 3.0"
}
magnify.register_plant(aspen, {"default:aspen_tree", "default:aspen_wood", "default:aspen_leaves", "default:aspen_sapling"})

local pine = {
    sci_name = "Pinus contorta var. latifolia",
    com_name = "Lodgepole Pine",
    fam_name = "Pinaceae (Pine family)",
    cons_status = "S5 - Demonstrably widespread, abundant, and secure",
    status_col = "#666ae3", -- S5
    height = "21 to 24 meters tall",
    bloom = "Produces yellowish pollen from May to July, depending on the elevation",
    region = "BC, Western Alberta, Southern Yukon and Western USA",
    texture = "magnify_default_pinus_contorta_var_latifolia.jpg",
    model_obj = "magnify_default_pinus_contorta_var_latifolia.obj",
    more_info = "Large, straight trunked, column-like tree with a narrow, open crown",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Pinus%20contorta", 
    img_copyright = "Walter Siegmund, licensed under CC BY-SA 3.0"
}
magnify.register_plant(pine, {"default:pine_tree", "default:pine_wood", "default:pine_needles", "default:pine_sapling"})

local AppleTree = {
    sci_name = "Malus fusca",
    com_name = "Pacific crab apple (Oregon crabapple)",
    fam_name = "Rosaceae (Rose family)",
    cons_status = "S5 - Demonstrably widespread, abundant, and secure",
    status_col = "#666ae3", -- S5
    height = "2 to 12 meters tall",
    bloom = "Has bright, fragrant clusters of 5-12 white/pink flowers on its branch ends",
    region = "BC, Alaska, Washington, Oregon and California",
    texture = "magnify_default_malus_fusca.jpg",
    model_obj = "magnify_default_malus_fusca.obj",
    more_info = "Bears very crisp, medium-sized, semi-sweet fruit with a thin, red-striped skin that is very aromatic",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Malus%20fusca",
    img_copyright = "Ross Mounce, licensed under CC BY 4.0"
}
magnify.register_plant(AppleTree, {"default:tree", "default:apple", "default:apple_mark", "default:leaves", "default:sapling", "default:wood"})

local JungleTree = {
    sci_name = "Alnus rubra",
    com_name = "Red alder",
    fam_name = "Betulaceae (Birch family)", 
    cons_status = "S5 - Demonstrably widespread, abundant, and secure",
    status_col = "#666ae3", -- S5
    height = "Grows up to 24 meters tall",
    bloom = "Produces male flowers in long, droopy, reddish catkins or female flowers in short, woody, brown cones",
    region = "Coastal BC, Washington, Oregon, California and Southeast Alaska",
    texture = {"magnify_alnus_rubra_01.jpg", "magnify_alnus_rubra_02.jpg"},
    model_obj = "magnify_default_alnus_rubra.obj",
    more_info = "Trees growing in the forest develop a slightly tapered trunk extending up to a narrow, rounded crown.",
    external_link = "https://www.for.gov.bc.ca/hfd/library/documents/treebook/redalder.htm"--,
    --img_copyright or img_credit = ""
}
magnify.register_plant(JungleTree, {"default:jungletree","default:junglewood","default:jungleleaves","default:junglesapling","default:emergent_jungle_sapling"})

local Kelp = {
    sci_name = "Desmarestia ligulata",
    com_name = "Flattened acid kelp" ,
    fam_name = "Desmarestiaceae (Brown algae family)",
    cons_status = "Unlisted", -- new colour (use default gray?)
    status_col = "#808080", -- default gray 
    height = "40 to 80 centimeters tall",
    bloom = "Blooms are caused by excess silicate in a body of water, where a type of algae called “diatoms” thrive", 
    region = "the waters of the Northern Hemisphere", -- bodies of water across the globe
    texture = "magnify_default_desmarestia_ligulata.jpg",
    model_obj = "magnify_default_desmarestia_ligulata.obj",
    more_info = "",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Desmarestia%20ligulata"--,
    --img_copyright or img_credit = ""
}
magnify.register_plant(Kelp, {"default:sand_with_kelp"})

local blueberry = {
    sci_name = "Vaccinium ovatum",
    com_name = "Evergreen Huckleberry",
    fam_name = "Ericaceae (Crowberry family)",
    cons_status = "S5 - Demonstrably widespread, abundant, and secure",
    status_col = "#666ae3", -- S5
    bloom = "Blooms with pinkish red flowers from April to May",
    region = "Southwest BC and West Coast USA",
    texture = "magnify_default_vaccinium_ovatum.jpg",
    model_obj = "magnify_default_vaccinium_ovatum.obj",
    more_info = "Can tolerate a wide range of light conditions and is very attractive to birds. Foliage is glossy and green with new red growth",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Vaccinium%20ovatum",
    img_credit = "Gordon Leppig & Andrea J. Pickart"
}
magnify.register_plant(blueberry, {"default:blueberry_bush_leaves", "default:blueberry_bush_leaves_with_berries", "default:blueberries"})

local Bush = {
    sci_name = "Physocarpus capitatus",
    com_name = "Pacific ninebark",
    fam_name = "Rosaceae (Rose family)",
    cons_status = "S5 - Demonstrably widespread, abundant, and secure",
    status_col = "#666ae3", -- S5
    height = "1 to 4 meters tall",
    bloom = "Blooms with half-rounded clusters of showy, white saucer-shaped flowers",
    region = "Southern BC and California",
    texture = "magnify_default_physocarpus_capitatus.jpg",
    model_obj = "magnify_default_physocarpus_capitatus.obj",
    more_info = "A shrub which attracts native bees and butterflies, and gives great cover for birds and small mammals.",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Physocarpus%20capitatus",
    img_copyright = "Walter Siegmund, licensed under CC BY 2.5"
}
magnify.register_plant(Bush, {"default:bush_leaves", "default:bush_stem", "default:bush_sapling"})

local Acacia = {
    sci_name = "Quercus garryana",
    com_name = "Garry Oak",
    fam_name = "Fagaceae (Beech family)",
    cons_status = "S5 - Demonstrably widespread, abundant, and secure",
    status_col = "#666ae3", -- S5
    height = "Grows up to 25 metres tall",
    bloom = "Female flowers clustered on same tree, male flowers numerous in catkins",
    region = "Southeastern Vancouver Island and Gulf Islands",
    texture = {"magnify_quercus_garryana_01.jpg", "magnify_quercus_garryana_02.jpg"}, 
    model_obj = "magnify_default_quercus_garryana.obj",
    more_info = "Deciduous tree with heavy, craggy branches, up to 25 m tall but often small, shrubby and as short as 1 m in dry, rocky habitats",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Quercus%20garryana"
    --img_copyright or img_credit = ""
}
magnify.register_plant(Acacia, {"default:acacia_tree", "default:acacia_wood", "default:acacia_leaves", "default:acacia_sapling", "default:dry_shrub"})

local Cactus = {
    sci_name = "Opuntia fragilis",
    com_name = "Brittle Prickly-pear Cactus",
    fam_name = "Cactaceae (Cactus family)",
    cons_status = "S5 - Demonstrably widespread, abundant, and secure",
    status_col = "#666ae3", -- S5
    height = "5 to 20 centimeters tall",
    bloom = "Blooms with paper-thin petals, yelllow, 3-5 centimeters across with reddish stalks",
    region = "BC to Southwest Ontario and Northern to Midwestern USA",
    texture = "magnify_default_opuntia_fragilis.jpg",
    model_obj = "magnify_default_opuntia_fragilis.obj",
    more_info = "Perennial herb from a fibrous root; mat-forming; stems prostrate, succulent, subglobose to rounded, fleshy,",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Opuntia%20fragilis"--,
    --img_copyright = ""
}
magnify.register_plant(Cactus, {"default:cactus", "default:large_cactus_seedling"})

local Papyrus = {
    sci_name = "Equisetum telmateia",
	com_name = "Giant Horsetail",
  	fam_name = "Equisetaceae (Horsetail family)",
  	cons_status = "S5 - Demonstrably widespread, abundant, and secure",
    status_col = "#666ae3", -- S5
  	height = "15-150 cm tall",
  	bloom = "Non-flowering",
	region = "Coastal BC, rare east of the Coast-Cascade Mountains",
	texture = "magnify_default_equisetum_telmatei.jpeg",
    model_obj = "magnify_default_equisetum_telmatei.obj",
	more_info = "An evergreen perennial. It has vertical green stems with horizontal bands similar to bamboo",
	external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Equisetum%20telmateia"--,
  	--img_copyright or img_credit = ""
}
magnify.register_plant(Papyrus, {"default:papyrus"})

local Fern = {
    sci_name = "Struthiopteris spicant",
    com_name = "Deer Fern",
    fam_name = "Blechnaceae (Chain Fern family)",
    cons_status = "S5 - Demonstrably widespread, abundant, and secure", 
    status_col = "#666ae3", -- S5
    height = "Grows to 20 inches tall at maturity",
    bloom = "No bloom pattern",
    region = "Coastal BC, infrequent in Southeast BC",
    texture = "magnify_default_struthiopteris_spicant.jpg",
    model_obj = "magnify_default_struthiopteris_spicant.obj",
    more_info = "This fern is particularly distinctive because of its two different types of fronds",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Blechnum%20spicant",
    img_copyright = "Daniel Mosquin, licensed under CC BY-NC-SA 4.0"
}
magnify.register_plant(Fern, {"default:fern_1", "default:fern_2", "default:fern_3"})

local arbutus = {
    sci_name = "Arbutus menziesii",
    com_name = "Arbutus",
    fam_name = "Ericaceae (Crowberry family)",
    cons_status = "S5 - Demonstrably widespread, abundant, and secure",
    status_col = "#666ae3", -- S5
    height = "6 to 30 meters tall",
    bloom = "Blooms with large clusters of drooping, urn-shaped white or pink corollas",
    region = "Southwest BC and West Coast USA",
    texture = {"magnify_arbutus_menziesii_01.jpg", "magnify_arbutus_menziesii_02.jpg", "magnify_arbutus_menziesii_03.jpg", "magnify_arbutus_menziesii_04.jpg"},
    model_obj = "magnify_default_arbutus_menziesii.obj",
    more_info = "A broadleaf, shrublike tree with peeling brownish-red bark. Typically found in dry open forests and shallow-soiled rocky slopes",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Arbutus%20menziesii",
    img_copyright = ""
}
magnify.register_plant(arbutus, {"default:acacia_bush_stem", "default:acacia_bush_leaves", "default:acacia_bush_sapling"})

local mannagrass = {
    sci_name = "Glyceria striata",
    com_name = "Fowl Mannagrass",
    fam_name = "Poaceae (Grass family)",
    cons_status = "S5 - Demonstrably widespread, abundant, and secure",
    status_col = "#666ae3", -- S5
    height = "30 to 80 centimeters tall",
    bloom = "Blooms with slender green panicles of egg-shaped flowers in the early summer",
    region = "various parts of Canada and the USA, including BC",
    texture = "magnify_default_glyceria_striata.jpg",
    model_obj = "magnify_default_glyceria_striata.obj",
    more_info = "A perennial with upright, hollow tufts of grass stemming from rhizomes. Typically found in bogs, lakeshores, and moist to wet meadows in lowland and subalpine zones.",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Glyceria%20striata",
    img_copyright = "Jason Hollinger, licensed under CC BY 2.0" 
}
magnify.register_plant(mannagrass, {"default:junglegrass"})

local Marram_Grass = {
    sci_name = "Achnatherum hymenoides",
    com_name = "Sand Ricegrass",
    fam_name = "Poaceae (Grass family)",
    cons_status = "S5 - Demonstrably widespread, abundant, and secure",
    status_col = "#666ae3", -- S5
    height = "25 to 70 centimeters tall",
    bloom = "Yellow/Green colour that arrives from June-September",
    region = "Western North America, east of the Cascades, from Southern BC to Northern Mexico",
    texture = "magnify_default_achnatherum_hymenoides.jpg",
    model_obj = "magnify_default_achnatherum_hymenoides.obj",
    more_info = "This tough grass is known for its ability to reseed and establish itself on sites damaged by fire or overgrazing.",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Achnatherum%20hymenoides",
    img_credit = ""      
}
magnify.register_plant(Marram_Grass, {"default:marram_grass_1"; "default:marram_grass_2", "default:marram_grass_3"})

local Savanna_Grass = {
    sci_name = "Pseudoroegneria spicata",
    com_name = "Bluebunch Wheatgrass",
    fam_name = "Poaceae (Grass family)",
    cons_status = "S5 - Demonstrably widespread, abundant, and secure",
    status_col = "#666ae3", -- S5
    height = "60 to 100 centimeters tall, with up to 100 centimeters of spread",
    bloom = "3 to 4 inch long, fluffy plumes of ruby pink flowers, slowly fading to creamy white",
    region = "SC and Southeast BC, rare elsewhere in BC",
    texture = "magnify_default_pseudoroegneria_spicata.jpg",
    model_obj = "magnify_default_pseudoroegneria_spicata.obj",
    more_info = "Can be used for native hay production and will make nutritious feed, but is bettersuited to grazing use",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Pseudoroegneria%20spicata",
    img_credit = ""       
}
magnify.register_plant(Savanna_Grass, {"default:dirt_with_dry_grass", "default:dry_dirt","default:dry_dirt_with_dry_grass", "default:dry_grass_1", "default:dry_grass_2", "default:dry_grass_3", "default:dry_grass_4", "default:dry_grass_5"})

local PineBushNeedles_Stem = {
    sci_name = "Taxus brevifolia",   
    com_name = "Pacific Yew",  
    fam_name = "Taxaceae",
    cons_status = "S5 - Demonstrably widespread, abundant, and secure",
    status_col = "#666ae3", -- S5
    height = "2 to 15 meters tall",
    bloom = "Flowers bloom ranging from May to June",
    region = "Coastal and Southeast BC, and West Coast USA", 
    texture = {"magnify_taxus_brevifolia_01.jpg", "magnify_taxus_brevifolia_02.jpg", "magnify_taxus_brevifolia_03.jpg"},
    model_obj = "magnify_default_taxus_brevifolia.obj",
    more_info = "A small tree, usually found as an understory tree in moist old growth forests growing beneath other larger trees",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Taxus%20brevifolia",
    img_credit = ""
}
magnify.register_plant(PineBushNeedles_Stem, {"default:pine_bush_stem", "default:pine_bush_needles", "default:pine_bush_sapling"})

local Grass = {
    sci_name = "Calamagrostis rubescens",
    com_name = "Pinegrass",
    fam_name = "Poaceae (Grass family)",
    cons_status = "S5 - Demonstrably widespread, abundant, and secure",
    status_col = "#666ae3", -- S5
    height = "60 to 100 centimeters tall",
    bloom = "Blooms with yellow flower clusters in late spring",
    region = "Southern BC, east of the Coast-Cascade Mountains",    
    texture = "magnify_default_calamagrostis_rubescens.jpg",
    model_obj = "magnify_default_calamagrostis_rubescens.obj",
    more_info = "Perennial, tufted grass that rarely flowers in shaded areas",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Calamagrostis%20rubescens",
    img_copyright = "",
}
magnify.register_plant(Grass, {"default:grass_1", "default:grass_2", "default:grass_3", "default:grass_4", "default:grass_5", "default:dirt_with_grass", "default:dirt_with_grass_footsteps"})
