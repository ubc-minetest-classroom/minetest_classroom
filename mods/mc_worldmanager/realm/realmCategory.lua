Realm.categories = {}

function Realm.RegisterCategory(categoryDefinition)
    Realm.categories[string.lower(categoryDefinition.key)] = categoryDefinition
end

function Realm:setCategoryKey(category)
    self:set_data("category", category)
end

function Realm:getCategory()
    local category = self:get_data("category")
    if (category == nil or category == "") then
        category = "default"
    end

    local categoryObject = Realm.categories[string.lower(category)]

    return categoryObject
end

function Realm.getRegisteredCategories()
    local categories = {}
    for key, value in pairs(Realm.categories) do
        table.insert(categories, key)
    end

    return categories
end

function Realm:AddOwner(ownerName)
    local owners = self:get_data("owner")
    if (owners == nil) then
        owners = {}
    end

    owners[ownerName] = true
    self:set_data("owner", owners)

    if (areas ~= nil) then
        self:AddPlayerAreaByName(ownerName)
    end
end

function Realm:RemoveOwner(ownerName)
    local owners = self:get_data("owner")
    if (owners == nil) then
        owners = {}
    end

    owners[ownerName] = nil
    self:set_data("owner", owners)

    if (areas ~= nil) then
        self:RemovePlayerAreaByName(ownerName)
    end
end

Realm.RegisterCategory({
    key = "default",
    visible = function(realm, player)
        return true, "Default realms are visible to all players."
    end,
    joinable = function(realm, player)
        return true, "Default realms are joinable by all players."
    end
})

Realm.RegisterCategory({
    key = "spawn",
    visible = function(realm, player)
        return true, "Spawn realms are visible to all players."
    end,
    joinable = function(realm, player)
        return true, "Spawn realms are joinable by all players."
    end
})

Realm.RegisterCategory({
    key = "classroom",
    visible = function(realm, player)

        if (realm:get_data("students") == nil) then
            realm:set_data("students", {})
        end

        if (realm:get_data("owner") == nil) then
            realm:set_data("owner", {})
        end

        if (realm:get_data("students")[player:get_player_name()] ~= nil) then
            return true, "You are a student in this realm."
        elseif (realm:get_data("owner")[player:get_player_name()] ~= nil) then
            return true, "You are an owner of this realm."
        else
            return false, "You are not a student in this realm."
        end
    end,
    joinable = function(realm, player)

        if (realm:get_data("students") == nil) then
            realm:set_data("students", {})
        end

        if (realm:get_data("owner") == nil) then
            realm:set_data("owner", {})
        end

        if (realm:get_data("students")[player:get_player_name()] ~= nil) then
            return true, "You are a student in this realm."
        elseif (realm:get_data("owner")[player:get_player_name()] ~= nil) then
            return true, "You are an owner of this realm."
        else
            return false, "You are not a student in this realm."
        end
    end
})

Realm.RegisterCategory({
    key = "instanced",
    visible = function(realm, player)

        if (realm:get_data("owner") == nil) then
            realm:set_data("owner", {})
        end

        if (realm:get_data("owner")[player:get_player_name()] ~= nil) then
            return true, "You are an owner of this realm."
        end

        return false
    end,
    joinable = function(realm, player)

        if (realm:get_data("owner") == nil) then
            realm:set_data("owner", {})
        end

        if (realm:get_data("owner")[player:get_player_name()] ~= nil) then
            return true, "You are an owner of this realm."
        end
        return false
    end
})
