-- All the functionality from these commands will added to a realm book.
-- These commands are currently just for testing


local commands = {}

minetest.register_chatcommand("localPos", {
    privs = {
        teacher = true,
    },
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        local requestedRealm = Realm.GetRealmFromPlayer(player)

        if (requestedRealm == nil) then
            return false, "Player is not listed in a realm OR current realm has been deleted; Try teleporting to a different realm and then back..."
        end

        local position = requestedRealm:WorldToLocalPosition(player:get_pos())
        return true, "Your position in the local space of realm " .. param .. " is x: " .. position.x .. " y: " .. position.y .. " z: " .. position.z
    end,
})

commands["new"] = {
    func = function(name, params)
        local realmName = tostring(params[1])
        if (realmName == "" or realmName == "nil") then
            realmName = "Unnamed Realm"
        end
        local sizeX = tonumber(params[2])
        if (sizeX == nil or sizeX == 0) then
            sizeX = 40
        end
        local sizeY = tonumber(params[3])
        if (sizeY == nil or sizeY == 0) then
            sizeY = 40
        end
        local sizeZ = tonumber(params[4]) or 40
        if (SizeZ == nil or SizeZ == 0) then
            SizeZ = 40
        end
        local newRealm = Realm:New(realmName, { x = sizeX, y = sizeY, z = sizeZ })
        newRealm:CreateGround()
        newRealm:CreateBarriersFast()

        return true, "created new realm with ID: " .. newRealm.ID
    end }

commands["delete"] = {
    func = function(name, params)
        local realmID = params[1]

        if (realmID == nil) then
            return false, "No realm ID specified"
        end

        if (realmID == mc_worldManager.spawnRealmID) then
            return false, "Cannot delete the spawn realm."
        end

        local requestedRealm = Realm.GetRealm(tonumber(realmID))
        if (requestedRealm == nil) then
            return false, "Requested realm of ID:" .. realmID .. " does not exist."
        end
        requestedRealm:Delete()
    end }

commands["list"] = {
    func = function(name, params)
        minetest.chat_send_player(name, "Realm Name : Realm ID")
        for i, t in pairs(Realm.realmDict) do
            minetest.chat_send_player(name, t.Name .. " : " .. t.ID)
        end

        return true
    end }

commands["info"] = {
    func = function(name, params)
        local realmID = params[1]
        local requestedRealm = Realm.GetRealm(tonumber(realmID))
        if (requestedRealm == nil) then
            return false, "Requested realm does not exist."
        end

        local spawn = requestedRealm.SpawnPoint
        local startPos = requestedRealm.StartPos
        local endPos = requestedRealm.EndPos

        return true, "Realm " .. realmID .. " has a spawn point of "
                .. "x:" .. tostring(spawn.x) .. " y:" .. tostring(spawn.y) .. " z:" .. tostring(spawn.z)
                .. "; startPos of "
                .. "x:" .. tostring(startPos.x) .. " y:" .. tostring(startPos.y) .. " z:" .. tostring(startPos.z)
                .. "; endPos of "
                .. "x:" .. tostring(endPos.x) .. " y:" .. tostring(endPos.y) .. " z:" .. tostring(endPos.z)
    end }

commands["tp"] = {
    privs = { teleport = true },
    func = function(name, params)
        local realmID = params[1]
        local requestedRealm = Realm.GetRealm(tonumber(realmID))

        if (not minetest.player_exists(name)) then
            return false, "Player: " .. tostring(name) .. " could not be found"
        end

        if (requestedRealm == nil) then
            return false, "Requested realm of ID:" .. realmID .. " does not exist."
        end

        local player = minetest.get_player_by_name(name)
        requestedRealm:TeleportPlayer(player)

        return true, "teleported to realm: " .. tostring(realmID)
    end }

commands["walls"] = {
    func = function(name, params)
        local realmID = params[1]
        local requestedRealm = Realm.GetRealm(tonumber(realmID))
        if (requestedRealm == nil) then
            return false, "Requested realm of ID:" .. realmID .. " does not exist."
        end

        if (params[2] ~= nil and params[2] == "fast") then
            requestedRealm:CreateBarriersFast()
        else
            requestedRealm:CreateBarriers()
        end

        return true, "created walls in realm: " .. tostring(realmID)
    end }

commands["gen"] = {
    func = function(name, params)
        local realmID = params[1]
        local requestedRealm = Realm.realmDict[tonumber(realmID)]
        if (requestedRealm == nil) then
            return false, "Requested realm of ID:" .. realmID .. " does not exist."
        end

        local seaLevel = math.floor((requestedRealm.EndPos.y - requestedRealm.StartPos.y) * 0.4) + requestedRealm.StartPos.y
        Debug.log("Sea level:" .. seaLevel)

        local heightGen = params[2]
        local decGen = params[3]

        local seed = tonumber(params[4])
        if (seed == nil) then
            seed = math.random(1, 1000)
        end

        local seaLevel = requestedRealm.StartPos.y
        if (params[5] == "" or params[5] == nil) then
            seaLevel = seaLevel + 30
        else
            seaLevel = seaLevel + tonumber(params[5])
        end

        requestedRealm:GenerateTerrain(seed, seaLevel, heightGen, decGen)

        Debug.log("Creating barrier...")
        requestedRealm:CreateBarriersFast()

        return true
    end }

commands["regen"] = {
    func = function(name, params)
        local realmID = params[1]
        local requestedRealm = Realm.realmDict[tonumber(realmID)]
        if (requestedRealm == nil) then
            return false, "Requested realm of ID:" .. realmID .. " does not exist."
        end

        local seaLevel = math.floor((requestedRealm.EndPos.y - requestedRealm.StartPos.y) * 0.4) + requestedRealm.StartPos.y
        Debug.log("Sea level:" .. seaLevel)

        local seed = requestedRealm:get_data("worldSeed")
        local seaLevel = requestedRealm:get_data("worldSeaLevel")
        local heightGen = requestedRealm:get_data("worldMapGenerator")
        local decGen = requestedRealm:get_data("worldDecoratorName")

        if (seed == nil) then
            return false, "Realm does not have any saved seed information."
        end

        if (heightGen == nil) then
            return false, "Realm does not have any saved height generator information. Please try to manually regenerate world with gen command and seed " .. tostring(seed)
        end

        if (decGen == nil) then
            return false, "Realm does not have any saved decorator information. Please try to manually regenerate world with gen command, seed " .. tostring(seed) .. " and height generator name " .. tostring(heightGen)
        end

        requestedRealm:GenerateTerrain(seed, seaLevel, heightGen, decGen)

        Debug.log("Creating barrier...")
        requestedRealm:CreateBarriersFast()

        return true
    end }

commands["seed"] = { func = function(name, params)
    local realmID = params[1]
    local requestedRealm = Realm.GetRealm(tonumber(realmID))
    if (requestedRealm == nil) then
        return false, "Requested realm of ID:" .. realmID .. " does not exist."
    end

    local seed = requestedRealm:get_data("worldSeed")

    return true, "World Seed for Realm: " .. tostring(seed)
end }

commands["schematic"] = {
    func = function(name, params)
        if (params[1] == "list") then
            table.remove(params, 1)

            minetest.chat_send_player(name, "Key : Filepath")
            for i, t in pairs(schematicManager.schematics) do
                minetest.chat_send_player(name, i .. " : " .. t)
            end
            return true
        elseif (params[1] == "save") then
            table.remove(params, 1)
            local realmID = params[1]
            local requestedRealm = Realm.GetRealm(tonumber(realmID))

            if (requestedRealm == nil) then
                return false, "Requested realm of ID:" .. realmID .. " does not exist."
            end

            local subparam = params[2]

            if (subparam == "" or subparam == nil) then
                subparam = "old"
            end

            local path = requestedRealm:Save_Schematic(name, subparam)
            return true, "Saved realm with ID " .. realmID .. " at path: " .. path
        elseif (params[1] == "load") then
            table.remove(params, 1)
            local realmName = params[1]
            if (realmName == "" or realmName == nil) then
                realmName = "Unnamed Realm"
            end

            local key = params[1]
            if (key == nil) then
                key = ""
            end

            local schematic, config = schematicManager.getSchematic(key)

            if (config == nil) then
                return false, "schematic key: " .. tostring(key) .. " config file has not been registered with the system."
            end

            local newRealm = Realm:NewFromSchematic(realmName, key)
            return true, "creat[ing][ed] new realm with name: " .. newRealm.Name .. "and ID: " .. newRealm.ID .. " from schematic with key " .. key
        else
            return false, "unknown subcommand. Try realm schematic list | realm schematic save | realm schematic load"
        end
    end }

commands["setspawn"] = {
    func = function(name, params)
        local player = minetest.get_player_by_name(name)

        local requestedRealm = Realm.GetRealmFromPlayer(player)

        local position = requestedRealm:WorldToLocalPosition(player:get_pos())

        requestedRealm:UpdateSpawn(position)

        return true, "Updated spawnpoint for realm with ID: " .. requestedRealm.ID
    end }

commands["setspawnrealm"] = {
    func = function(name, params)
        local realmID = params[1]
        local requestedRealm = Realm.GetRealm(tonumber(realmID))
        if (requestedRealm == nil) then
            return false, "Requested realm of ID:" .. realmID .. " does not exist."
        end

        local success = mc_worldManager.SetSpawnRealm(requestedRealm)

        if (success) then
            return true, "Updated the spawn realm to realm with ID: " .. realmID
        else
            return false, "something went wrong... could not update the spawn realm."
        end
    end }

commands["consolidate"] = {
    func = function(name, params)
        Realm.consolidateEmptySpace()
        Realm.SaveDataToStorage()
        return true, "consolidated realms"
    end }

commands["help"] = {
    func = function(name, params)
        local helpString = ""
        for k, v in pairs(commands) do
            helpString = helpString .. k .. " | "
        end
        return true, helpString
    end }

commands["define"] = {
    func = function(name, params)
        -- this is really hacky, we should come up with a better way to do this...

        local name = tostring(params[1])
        local pos1X = tonumber(params[2])
        local pos1Y = tonumber(params[3])
        local pos1Z = tonumber(params[4])
        local pos2X = tonumber(params[5])
        local pos2Y = tonumber(params[6])
        local pos2Z = tonumber(params[7])

        if (name == nil or pos1X == nil or pos1Y == nil or pos1Z == nil or pos2X == nil or pos2Y == nil or pos2Z == nil) then
            return false, "missing command parameters"
        end

        local pos1 = { x = pos1X, y = pos1Y, z = pos1Z }
        local pos2 = { x = pos2X, y = pos2Y, z = pos2Z }
        local spawnPos = { x = (pos1.x + pos2.x) / 2, y = pos2.y - 5, z = (pos1.z + pos2.z) / 2 }

        local newRealm = {
            Name = name,
            ID = Realm.realmCount + 1,
            StartPos = pos1,
            EndPos = pos2,
            SpawnPoint = spawnPos,
            PlayerJoinTable = nil,
            PlayerLeaveTable = nil,
            RealmDeleteTable = nil,
            MetaStorage = { }
        }

        Realm.realmCount = newRealm.ID
        Realm:Restore(newRealm)
    end }

commands["privs"] = {
    func = function(name, params)
        local operation = tostring(params[1])
        local realmID = tonumber(params[2])
        local privilege = tostring(params[3])

        if (operation == "nil" or operation == "") then
            return false, "Incorrect parameter... Missing realm privilege operation. Usage: realm privs [<grant> | <revoke>] <realmID> <privilege>"
        end

        if (operation == "help") then
            return true, "Usage: 'realm privs [grant | list | revoke] <realmID> <privilege>'; 'realm privs help' for help."
        end

        if (realmID == nil or realmID == "") then
            return false, "Incorrect parameter... Missing realm ID. Usage: realm privs [grant | list | revoke] <realmID> <privilege>"
        end

        local requestedRealm = Realm.realmDict[realmID]
        if (requestedRealm == nil) then
            return false, "Requested realm of ID:" .. tostring(realmID) .. " does not exist."
        end

        if (operation == "list") then

            if (requestedRealm.Permissions ~= nil) then
                for i, t in pairs(requestedRealm.Permissions) do
                    minetest.chat_send_player(name, "- " .. i)
                end
            else
                minetest.chat_send_player(name, "No realm privileges have been set.")
            end

            return true, "command executed succesfully"
        end

        if (privilege == "nil" or privilege == "") then
            return false, "Incorrect parameter... Missing realm privilege to add or revoke. Usage: realm privs [grant | list | revoke] <realmID> <privilege>"
        end

        if (operation == "grant") then

            if (minetest.check_player_privs(name, privilege) == false) then
                return false, "Unable to add privilege: " .. privilege .. " to realm" .. tostring(realmID) .. " as you do not hold this privilege."
            end
            local privsTable = {}
            privsTable[privilege] = true

            local success, invalidPrivs = requestedRealm:UpdateRealmPrivilege(privsTable)

            if (not success) then
                return false, "Unable to add privilege: " .. privilege .. " to realm" .. tostring(realmID) .. " as it has not been whitelisted."
            end

            return true, "Added permission: " .. privilege .. " to realm " .. tostring(realmID)
        elseif (operation == "revoke") then

            local privsTable = {}
            privsTable[privilege] = false

            requestedRealm:UpdateRealmPrivilege()
            return true, "Removed permission: " .. privilege .. " from realm " .. tostring(realmID)
        end
    end
}

commands["players"] = {
    func = function(name, params)


        if (params[1] == "list") then
            local realmID = params[2]
            local requestedRealm = Realm.GetRealm(tonumber(realmID))
            if (requestedRealm == nil) then
                return false, "Requested realm of ID:" .. realmID .. " does not exist."
            end

            local realmPlayerList = requestedRealm:get_tmpData("Inhabitants")

            if (realmPlayerList == nil) then
                return false, "no players found in realm player list."
            end

            Debug.log(minetest.serialize(realmPlayerList))

            for k, v in pairs(realmPlayerList) do
                minetest.chat_send_player(name, k)
            end

            return true, "listed all players in realm."
        elseif (params[1] == "scan") then
            Realm.ScanForPlayerRealms()
            return true, "re-associated players with realms."

        end

        return false, "unknown sub-command."
    end
}

minetest.register_chatcommand("realm", {
    params = "Subcommand Realm ID Option",
    func = function(name, param)
        local params = mc_helpers.split(param, " ")
        local subcommand = params[1]
        table.remove(params, 1)

        if (commands[subcommand] ~= nil) then
            if (commands[subcommand].privs == nil) then
                commands[subcommand].privs = { teacher = true }
            end
            local has, missing = minetest.check_player_privs(name, commands[subcommand].privs)
            if not has then
                local missingPermsString = ""
                for k, v in pairs(missing) do
                    missingPermsString = missingPermsString .. v .. ", "
                end

                return false, "You do not have permission to use this command. Missing command(s): " .. missingPermsString
            end

            return commands[subcommand].func(name, params)
        else
            return false, "Unknown subcommand. Use 'realm help' for a list of sub-commands."
        end
    end,
})

-- Gets called when a command is called, before it is handled by the engine / lua runtime.
minetest.register_on_chatcommand(function(name, command, params)


    if (command == "grantme") then
        local privTable = mc_helpers.split(params, ", ")
        mc_worldManager.grantUniversalPriv(minetest.get_player_by_name(name), privTable)
        return false -- we must return false so that the regular grant command proceeds.
    elseif (command == "revokeme") then
        local privTable = mc_helpers.split(params, ", ")
        mc_worldManager.revokeUniversalPriv(minetest.get_player_by_name(name), privTable)
        return false -- we must return false so that the regular grant command proceeds.
    end


    -- Gets called when grant / revoke is called. We're using this to add permissions that are granted onto the universalPrivs table.

    if (command == "grant" or command == "revoke") then
        local privsTable = mc_helpers.split(params, ", ")
        local tmpTable = mc_helpers.split(table.remove(privsTable, 1), " ")

        local name = tmpTable[1]
        table.insert(privsTable, tmpTable[2])
        tmpTable = nil

        if (not minetest.player_exists(name)) then
            return false -- we must return false so that the regular grant command proceeds. Error text is handled there.
        end

        if (name == nil or name == "" or privsTable == nil) then
            return false -- we must return false so that the regular grant command proceeds. Error text is handled there.
        end

        if (command == "grant") then
            mc_worldManager.grantUniversalPriv(minetest.get_player_by_name(name), privsTable)
        else
            mc_worldManager.revokeUniversalPriv(minetest.get_player_by_name(name), privsTable)
        end
    end

    return false
end)


-- We could have also done minetest.override_chatcommand; but I want complete control
minetest.unregister_chatcommand("teleport")

minetest.register_chatcommand("teleport", {
    privs = {
        teleport = true,
    },
    description = "Teleport yourself or a specified player to a realm or another player.",
    params = "<realm ID> | <target player> | (<player name> <realm ID>) | (<player name> <target player name>) | (<realm ID> <local x pos> <local y pos> <local z pos>)",
    func = function(name, param)

        local function teleport(name, othername)

            if (not minetest.player_exists(name)) then
                return false, "Player " .. tostring(name) .. " could not be found..."
            end

            if (not minetest.player_exists(othername)) then
                return false, "Player " .. tostring(othername) .. " could not be found..."
            end

            local player = minetest.get_player_by_name(name)
            local otherPlayer = minetest.get_player_by_name(othername)
            local pmeta = otherPlayer:get_meta()
            local realmID = pmeta:get_int("realm")

            local requestedRealm = Realm.realmDict[realmID]

            if (requestedRealm == nil) then
                return false, "Player " .. tostring(othername) .. " is not listed in a realm OR current realm has been deleted; Try teleporting to a different realm and then back..."
            end

            requestedRealm:TeleportPlayer(player)
            local pos = otherPlayer:get_pos()
            player:set_pos(pos)
            return true, "Teleported to " .. tostring(othername) .. " in realm " .. tostring(realmID)
        end

        local paramTable = mc_helpers.split(param, " ")
        if (paramTable == nil) then
            paramTable = { param }
        end

        if (mc_helpers.isNumber(paramTable[1]) and mc_helpers.isNumber(paramTable[2]) and mc_helpers.isNumber(paramTable[3]) and mc_helpers.isNumber(paramTable[4])) then
            local realmID = paramTable[1]
            local requestedRealm = Realm.realmDict[tonumber(realmID)]

            if (not minetest.player_exists(name)) then
                return false, "Player: " .. tostring(name) .. " could not be found"
            end

            if (requestedRealm == nil) then
                return false, "Requested realm of ID:" .. realmID .. " does not exist."
            end

            local player = minetest.get_player_by_name(name)

            local position = { x = paramTable[2], y = paramTable[3], z = paramTable[4] }
            local worldPosition = requestedRealm:LocalToWorldPosition(position)

            if (not requestedRealm:ContainsCoordinate(worldPosition)) then
                return false, "requested position does not exist in realm " .. tostring(realmID)
            end

            requestedRealm:TeleportPlayer(player)
            player:set_pos(worldPosition)
        elseif (mc_helpers.isNumber(paramTable[1]) and paramTable[2] == nil) then
            return commands["tp"].func(name, paramTable)
        elseif (paramTable[1] ~= nil and paramTable[2] == nil) then
            return teleport(name, paramTable[1])
        elseif (paramTable[1] ~= nil and mc_helpers.isNumber(paramTable[2])) then
            return commands["tp"].func(paramTable[1], { paramTable[2] })
        elseif (paramTable[1] ~= nil and paramTable[2] ~= nil) then
            return teleport(paramTable[1], paramTable[2])
        end

        return false, "unable to parse parameters: " .. tostring(param)
    end,
})