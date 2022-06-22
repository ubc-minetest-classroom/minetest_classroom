Realm.onCreateRealmCallbackTable = {}
Realm.onDeleteRealmCallbackTable = {}
Realm.onJoinRealmCallbackTable = {}
Realm.onLeaveRealmCallbackTable = {}

function Realm.RegisterOnCreateCallback(func)
    table.insert(Realm.onCreateRealmCallbackTable, func)
end

function Realm.RegisterOnDeleteRealmCallback(func)
    table.insert(Realm.onDeleteRealmCallbackTable, func)
end

function Realm.RegisterOnJoinCallback(func)
    table.insert(Realm.onJoinRealmCallbackTable, func)
end

function Realm.RegisterOnLeaveCallback(func)
    table.insert(Realm.onLeaveRealmCallbackTable, func)
end

function Realm:CallOnCreateCallbacks()
    for _, func in ipairs(Realm.onCreateRealmCallbackTable) do
        func(self)
    end
end

function Realm:CallOnDeleteCallbacks()
    for _, func in ipairs(Realm.onDeleteRealmCallbackTable) do
        func(self)
    end
end

function Realm:CallOnJoinCallbacks()
    for _, func in ipairs(Realm.onJoinRealmCallbackTable) do
        func(self, player)
    end
end

function Realm:CallOnLeaveCallbacks()
    for _, func in ipairs(Realm.onLeaveRealmCallbackTable) do
        func(self, player)
    end
end

