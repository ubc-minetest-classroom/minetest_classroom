mc_tutorialFramework = { path = minetest.get_modpath("mc_tf")}


schematicManager.registerSchematicPath("testSchematic", mc_tutorialFramework.path .. "/realmTemplates/TestSchematic")

mc_realmportals.newPortal("mc_tf","tf_testRealm", false, "testSchematic")