--[[
local template = {
    sci_name = "",        -- Scientific name of species
    com_name = "",        -- Common name of species
    fam_name = "",        -- Family name of species
    cons_status = "",     -- Conservation status of species
    status_col = "",      -- Hex colour of status box ("#000000")
    height = "",          -- Plant height (information row 3)
    bloom = "",           -- The way the plant blooms
    region = "",          -- Native region of plant (displayed as "Native to [region]")
    texture = "",         -- Image of plant (in `mod/textures`)
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
    texture = "Populus_tremuloides_02.jpg",
    model_obj = "aspen_tree.obj",
	model_spec = "default_aspen_tree.png,default_aspen_tree_top.png,default_aspen_leaves.png,default_dirt.png",
    more_info = "Smooth-barked, randomly-branching tree. Also known as the golden aspen, due to the golden colour its leaves turn in the fall.",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Populus%20tremuloides",
    img_copyright = "Tewy, licensed under CC BY-SA 3.0"
}
magnify.register_plant(aspen, {"default:aspen_tree", "default:aspen_wood", "default:aspen_leaves", "default:aspen_sapling"})

local pine = {
    sci_name = "Pinus contorta",
    com_name = "Lodgepole Pine",
    fam_name = "Pinaceae (Pine family)",
    cons_status = "S5 - Demonstrably widespread, abundant, and secure",
    status_col = "#666ae3", -- S5
    height = "21 to 24 meters tall",
    bloom = "Produces yellowish pollen from May to July, depending on the elevation",
    region = "BC, Western Alberta, Southern Yukon and Western USA",
    texture = "Pinus_contorta_28266.jpg",
    model_obj = "pine_tree.obj",
    model_spec = "default_pine_needles.png,default_pine_tree_top.png,default_pine_tree.png,default_dirt.png",
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
    texture = "Malus_fusca.jpg",
    model_obj = "apple_tree.obj",
    model_spec = "default_tree_top.png,default_leaves.png,default_tree.png,default_apple.png,default_dirt.png",
    more_info = "Bears very crisp, medium-sized, semi-sweet fruit with a thin, red-striped skin that is very aromatic",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Malus%20fusca",
    img_copyright = "Ross Mounce, licensed under CC BY 4.0"
}
magnify.register_plant(AppleTree, {"default:tree", "default:apple", "default:apple_mark", "default:leaves", "default:sapling"})

local JungleTree = {
    sci_name = "Alnus rubra",
    com_name = "Red alder",
    fam_name = "Betulaceae (Birch family)", 
    cons_status = "S5 - Demonstrably widespread, abundant, and secure",
    status_col = "#666ae3", -- S5
    height = "Grows up to 24 meters tall",
    bloom = "Produces male flowers in long, droopy, reddish catkins or female flowers in short, woody, brown cones",
    region = "Coastal BC, Washington, Oregon, California and Southeast Alaska",
    texture = "jungle_tree.jpg",
    model_obj = "jungle_tree.obj",
    model_spec = "default_jungleleaves.png,default_jungletree_top.png,default_jungletree.png,default_dirt.png",
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
    texture = "kelp.jpg",
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
    texture = "Vacciniumovatum.jpg", 
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
    texture = "Physocarpus_capitatus_18343.jpg",
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
    texture = "acacia.png", 
    model_obj = "tree_test.obj",
    model_spec = "default_acacia_tree_top.png,default_dry_grass_2.png,default_dry_dirt.png^default_dry_grass_side.png,default_acacia_leaves.png,default_acacia_tree.png,default_dry_grass_1.png,default_dry_grass_3.png,default_dry_grass_4.png,default_dry_grass.png",
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
    texture = "4691167139_41c8a71b20_o.jpg", 
    more_info = "Perennial herb from a fibrous root; mat-forming; stems prostrate, succulent, subglobose to rounded, fleshy,",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Opuntia%20fragilis",
    img_copyright = "Alexandre Dell'Olivo, licensed under CC BY-NC-SA 2.0"
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
	texture = "horsetail.jpeg", 
	more_info = "An evergreen perennial. It has vertical green stems with horizontal bands similar to bamboo",
	external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Equisetum%20telmateia"--,
  	--img_copyright or img_credit = ""
}
magnify.register_plant(Papyrus, {"default:papyrus"})

--[[
local wild_cotton = { -- part of farming mod so hold on for now 
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
    img_credit = ""
}
magnify.register.. ]]

local Fern = {
    sci_name = "Struthiopteris spicant",       
    com_name = "Deer Fern",        
    fam_name = "Blechnaceae (Chain Fern family)",        
    cons_status = "S5 - Demonstrably widespread, abundant, and secure",     
    status_col = "#666ae3", -- S5    
    height = "Grows to 20 inches tall at maturity",         
    bloom = "No bloom pattern",           
    region = "Coastal BC, infrequent in Southeast BC",         
    texture = "struthiopteris-spicant-1.jpg",        
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
    texture = "arbutus.jpg",
    more_info = "A broadleaf, shrublike tree with peeling brownish-red bark. Typically found in dry open forests and shallow-soiled rocky slopes",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Arbutus%20menziesii"--,
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
    texture = "1290859805_c0f741fe00_o.jpg",
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
    texture = "marram_grass.png",
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
    texture = "savanna.png",
    more_info = "Can be used for native hay production and will make nutritious feed, but is bettersuited to grazing use",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Pseudoroegneria%20spicata",
    img_credit = ""       
}
magnify.register_plant(Savanna_Grass, {"default:dry_grass", "default:dirt_with_dry_grass","default:dry_dirt","default:dry_dirt_with_dry_grass", "default:dry_grass_1", "default:dry_grass_2", "default:dry_grass_3", "default:dry_grass_4", "default:dry_grass_5"})

local PineBushNeedles_Stem = {
    sci_name = "Taxus brevifolia",   
    com_name = "Pacific Yew",  
    fam_name = "Taxaceae",
    cons_status = "S5 - Demonstrably widespread, abundant, and secure",
    status_col = "#666ae3", -- S5
    height = "2 to 15 meters tall",
    bloom = "Flowers bloom ranging from May to June",
    region = "Coastal and Southeast BC, and West Coast USA", 
    texture = "pinebush.png",
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
    texture = "grass.png",
    more_info = "Perennial, tufted grass that rarely flowers in shaded areas",
    external_link = "https://linnet.geog.ubc.ca/Atlas/Atlas.aspx?sciname=Calamagrostis%20rubescens",
    img_copyright = "",
}
magnify.register_plant(Grass, {"default:grass_1", "default:grass_2", "default:grass_3", "default:grass_4", "default:grass_5", "default:dirt_with_grass", "default:dirt_with_grass_footsteps"})