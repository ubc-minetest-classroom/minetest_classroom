Realm.categories = {}

---@public
---RegisterCategory
---Registers a new realm category.
---@param categoryDefinition table @The category definition.
function Realm.RegisterCategory(categoryDefinition)
    Realm.categories[string.lower(categoryDefinition.key)] = categoryDefinition
end

---@public
---setCategoryKey
---Sets the category of a realm using the categories corresponding key.
---@param categoryKey string the category key to apply to the realm.
function Realm:setCategoryKey(categoryKey)
    if (categoryKey == nil or categoryKey == "nil" or categoryKey == "") then
        self:set_data("category", "default")
    else
        self:set_data("category", categoryKey)
    end
end

---@public
---getCategoryKey
---Returns the category key assigned to a realm.
---@return string @The category key.
function Realm:getCategory()
    local category = self:get_data("category")
    if (category == nil or category == "") then
        category = "default"
    end

    local categoryObject = Realm.categories[string.lower(category)]

    return categoryObject
end

---@public
---getRegisteredCategories
---Returns a list of all registered realm categories.
---@return table @The list of realm categories.
function Realm.getRegisteredCategories()
    return Realm.categories
end

---@public
---AddOwner
---Adds a new owner to a realm.
---@param owner string @The owner to add.
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

---@public
---RemoveOwner
---Removes an owner from a realm.
---@param owner string @The owner to remove.
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
        elseif (minetest.check_player_privs(player, { teacher = true })) then
            return true, "All realms are joinable by teachers."
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
        elseif (minetest.check_player_privs(player, { teacher = true })) then
            return true, "All realms are joinable by teachers."
        end
        return false
    end
})
