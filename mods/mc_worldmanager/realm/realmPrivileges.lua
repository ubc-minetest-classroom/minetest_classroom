Realm.whitelistedPrivs = {}
local worldRealmPrivWhitelist = minetest.get_worldpath() .. "\\realmPrivilegeWhitelist.conf"
local modRealmPrivWhitelist = mc_worldManager.path .. "\\realmPrivilegeWhitelist.conf"

function Realm.SetPrivWhitelist(file)
    local settings = Settings(file)

    for k, v in pairs(Realm.whitelistedPrivs) do
        settings:set_bool(tostring(k), v)
    end

    local success = settings:write()
    return success
end

function Realm.GetPrivWhitelist(file)
    local settings = Settings(file)
    local names = settings:get_names()

    for index, key in pairs(names) do
        local value = settings:get_bool(key)

        if (value == true) then
            Realm.whitelistedPrivs[key] = true
        end
    end
end

function Realm.LoadPrivModDefaults()
    Realm.GetPrivWhitelist(modRealmPrivWhitelist)
    Realm.SetPrivWhitelist(worldRealmPrivWhitelist)
end

function Realm:UpdateRealmPrivilege(privilegeTable)
    local invalidPrivs = {}

    if (self.Permissions == nil) then
        self.Permissions = {}
    end

    for k, v in pairs(privilegeTable) do
        if (v == true or v == "true") then
            if (Realm.whitelistedPrivs[k] ~= true) then
                table.insert(invalidPrivs, k)
                Debug.log(tostring(k))
            else
                self.Permissions[k] = true
            end
        else
            self.Permissions[k] = nil
        end
    end

    if (#invalidPrivs > 0) then
        return false, invalidPrivs
    end

    return true, invalidPrivs
end

if (mc_helpers.fileExists(worldRealmPrivWhitelist)) then
    Realm.GetPrivWhitelist(worldRealmPrivWhitelist)
else
    Debug.log("No realm permissions whitelist found, load mod defaults...")
    Realm.LoadPrivModDefaults()
end

Debug.logTable("whitelisted Privs", Realm.whitelistedPrivs)

