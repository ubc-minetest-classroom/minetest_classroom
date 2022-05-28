mc_tutorialFramework = { path = minetest.get_modpath("mc_tf")}

Tutorials = {}


dofile(mc_tutorialFramework.path .. "/Tutorials/Punch-A-Block/main.lua")


schematicManager.registerSchematicPath("testSchematic", mc_tutorialFramework.path .. "/realmTemplates/TestSchematic")

mc_realmportals.newPortal("mc_tf","tf_testRealm", false, "testSchematic")

pap.createBreakableBlock(nil,"Tutorial")
pap.createBreakableBlock(nil,"Test")