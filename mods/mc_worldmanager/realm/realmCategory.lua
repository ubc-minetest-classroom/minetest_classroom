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
        self:set_data("category", "open")
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
        category = "open"
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
---GetOwners
---Gets owners of a realm.
---@return table
function Realm:GetOwners()
    local owners = self:get_data("owner")
    if type(owners) == "string" then
        owners = {[owners] = true}
        self:set_data("owner", owners)
    end
    return owners
end

---@public
---AddOwner
---Adds a new owner to a realm.
---@param owner string @The owner to add.
function Realm:AddOwner(ownerName)
    local owners = self:GetOwners()
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
    local owners = self:GetOwners()
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
    key = "open",
    visible = function(realm, player)
        return true, "Open classrooms are visible to all players."
    end,
    joinable = function(realm, player)
        return true, "Open classrooms are joinable by all players."
    end
})

Realm.RegisterCategory({
    key = "spawn",
    visible = function(realm, player)
        return true, "The spawn classroom is always visible to all players."
    end,
    joinable = function(realm, player)
        return true, "The spawn classroom is always joinable by all players."
    end
})

Realm.RegisterCategory({
    key = "restricted",
    visible = function(realm, player)

        if (realm:get_data("students") == nil) then
            realm:set_data("students", {})
        end

        if (realm:GetOwners() == nil) then
            realm:set_data("owner", {})
        end

        if (realm:get_data("students")[player:get_player_name()] ~= nil) then
            return true, "You are a student in this classroom."
        elseif (realm:GetOwners()[player:get_player_name()] ~= nil) then
            return true, "You are an owner of this classroom."
        else
            return false, "You are not a student in this classroom."
        end
    end,
    joinable = function(realm, player)

        if (realm:get_data("students") == nil) then
            realm:set_data("students", {})
        end

        if (realm:GetOwners() == nil) then
            realm:set_data("owner", {})
        end

        if (realm:get_data("students")[player:get_player_name()] ~= nil) then
            return true, "You are a student in this classroom."
        elseif (realm:GetOwners()[player:get_player_name()] ~= nil) then
            return true, "You are an owner of this classroom."
        elseif (minetest.check_player_privs(player, { teacher = true })) then
            return true, "All restricted classrooms are always joinable by teachers."
        else
            return false, "You are not a student in this classroom."
        end
    end
})

Realm.RegisterCategory({
    key = "private",
    visible = function(realm, player)

        if (realm:GetOwners() == nil) then
            realm:set_data("owner", {})
        end

        if (realm:GetOwners()[player:get_player_name()] ~= nil) then
            return true, "You are an owner of this classroom."
        end

        return false
    end,
    joinable = function(realm, player)

        if (realm:GetOwners() == nil) then
            realm:set_data("owner", {})
        end

        if (realm:GetOwners()[player:get_player_name()] ~= nil) then
            return true, "You are an owner of this classroom."
        elseif (minetest.check_player_privs(player, { teacher = true })) then
            return true, "All classrooms are always joinable by teachers."
        end
        return false
    end
})
