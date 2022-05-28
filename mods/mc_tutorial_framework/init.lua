mc_tutorialFramework = { path = minetest.get_modpath("mc_tf") }

Tutorials = {}

dofile(mc_tutorialFramework.path .. "/Tutorials/Punch-A-Block/main.lua")

schematicManager.registerSchematicPath("testSchematic", mc_tutorialFramework.path .. "/realmTemplates/TestSchematic")

mc_realmportals.newPortal("mc_tf", "tf_testRealm", false, "testSchematic")

pab.CreateBlockFromGroups({ oddly_breakable_by_hand = 3 }, tutorial.blockDestroyed)
pab.CreateBlockFromGroups({ choppy = 1 }, tutorial.blockDestroyed)
pab.CreateBlockFromGroups({ cracky = 1 }, tutorial.blockDestroyed)
pab.CreateBlockFromGroups({ crumbly = 1 }, tutorial.blockDestroyed)
pab.CreateBlockFromGroups({ fleshy = 1 }, tutorial.blockDestroyed)