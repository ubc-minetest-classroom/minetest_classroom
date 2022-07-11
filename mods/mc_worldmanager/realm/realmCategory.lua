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

Realm.RegisterCategory({
    key = "default",
    visible = function(realm, player)
        return false, "this realm is not visible."
    end,
    joinable = function(realm, player)
        return false, "this realm is not joinable."
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

--TODO: integrate into the mc_teachers mod.
Realm.RegisterCategory({
    key = "classroom",
    visible = function(realm, player)
        return true
    end,
    joinable = function(realm, player)
        return true
    end
})

Realm.RegisterCategory({
    key = "instanced",
    visible = function(realm, player)
        if (realm:get_data("owner")[player:get_player_name()] ~= nil) then
            return true
        end

        return false
    end,
    joinable = function(realm, player)
        if (realm:get_data("owner")[player:get_player_name()] ~= nil) then
            return true
        end
        return false
    end
})
