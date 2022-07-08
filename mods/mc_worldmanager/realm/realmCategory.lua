Realm.categories = {}

function Realm.RegisterCategory(categoryDefinition)
    Realm.categories[string.lower(categoryDefinition.key)] = categoryDefinition
end

function Realm:setCategoryKey(category)
    self:set_data("category", category)
end

function Realm:getCategoryKey()
    local category = self:get_data("category")

    if (category == nil or category == "") then
        category = "default"
    end
end

function Realm.getCategoryFromKey(key)
    return Realm.categories[key]
end

function Realm:getCategory()
    return Realm.getCategoryFromKey(self:getCategoryKey())
end

Realm.RegisterCategory({
    key = "default",
    visible = function(realm, player)
        return true
    end,
    joinable = function(realm, player)
        return true
    end
})


Realm.RegisterCategory({
    key = "spawn",
    visible = function(realm, player)
        return true
    end,
    joinable = function(realm, player)
        return true
    end
})

Realm.RegisterCategory({
    key = "world",
    visible = function(realm, player)
        return true
    end,
    joinable = function(realm, player)
        return true
    end
})

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
        return true
    end,
    joinable = function(realm, player)
        return true
    end
})
