-- RealmIDTable stores the name of portal realms as a key, and the ID of the associated realm as the value.

mc_realmportals = { storage = minetest.get_mod_storage() }

---We load our global realmPortal data from storage
function mc_realmportals.LoadDataFromStorage()
    mc_realmportals.RealmIDTable = minetest.deserialize(mc_realmportals.storage:get_string("realmIDLookup"))
    if mc_realmportals.RealmIDTable == nil then
        mc_realmportals.RealmIDTable = {}
    end
end

---We save our global realmPortal data to storage
function mc_realmportals.SaveDataToStorage ()
    mc_realmportals.storage:set_string("realmIDLookup", minetest.serialize(mc_realmportals.RealmIDTable))
end

dofile(minetest.get_modpath("mc_realmportals") .. "/portalhelper.lua")




mc_realmportals.LoadDataFromStorage()

-- Defining all our portal realms

mc_realmportals.newPortal("mc_realmportals","testRealm", true, "vancouver_osm")
mc_realmportals.newPortal("mc_realmportals","lukieRealm", false, "shack")
mc_realmportals.newPortal("mc_realmportals","realm1024", false)
mc_realmportals.newPortal("mc_realmportals","123", false)
mc_realmportals.newPortal("mc_realmportals","456", false)


