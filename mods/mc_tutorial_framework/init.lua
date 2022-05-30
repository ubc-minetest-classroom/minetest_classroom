mc_tutorialFramework = { path = minetest.get_modpath("mc_tf") }

Tutorials = {}

dofile(mc_tutorialFramework.path .. "/Tutorials/Punch-A-Block/main.lua")

schematicManager.registerSchematicPath("testSchematic", mc_tutorialFramework.path .. "/realmTemplates/TestSchematic")
schematicManager.registerSchematicPath("punchABlockSchematic", mc_tutorialFramework.path .. "/realmTemplates/punchABlock")

mc_realmportals.newPortal("mc_tf", "tf_testRealm", false, "testSchematic")
mc_realmportals.newPortal("mc_tf", "tf_punchABlock", true, "punchABlockSchematic")

pab.CreateBlockFromGroups({ oddly_breakable_by_hand = 3 }, "mc_tf:handBreakable", punchABlock.blockDestroyed)
pab.CreateBlockFromGroups({ crumbly = 1 }, "mc_tf:shovelBreakable", punchABlock.blockDestroyed)
pab.CreateBlockFromGroups({ cracky = 1 }, "mc_tf:pickBreakable", punchABlock.blockDestroyed)
pab.CreateBlockFromGroups({ choppy = 1 }, "mc_tf:axeBreakable", punchABlock.blockDestroyed)

