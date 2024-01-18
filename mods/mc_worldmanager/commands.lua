local commands = {}

minetest.register_chatcommand("localPos", {
    privs = {
        teacher = true,
    },
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        local requestedRealm = Realm.GetRealmFromPlayer(player)

        if (requestedRealm == nil) then
            return false, "Player is not listed in a classroom OR current classroom has been deleted; Try teleporting to a different classroom and then back..."
        end

        local position = requestedRealm:WorldToLocalSpace(player:get_pos())
        return true, "Your position in the local space of classroom " .. param .. " is x: " .. position.x .. " y: " .. position.y .. " z: " .. position.z
    end,
    help = "Get your local position in the current classroom",
})

commands["new"] = {
    func = function(name, params)
        local realmName = tostring(params[1])
        if (realmName == "" or realmName == "nil") then
            realmName = "Unnamed classroom"
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
        if (sizeZ == nil or sizeZ == 0) then
            sizeZ = 40
        end
        local newRealm = Realm:New(realmName, { x = sizeX, y = sizeY, z = sizeZ })
        newRealm:CreateGround()
        newRealm:CreateBarriersFast()
        newRealm:AddOwner(name)

        return true, "created new classroom with ID: " .. newRealm.ID
    end,
    help = "classroom new [name] ([<sizeX>] [<sizeY>] [<sizeZ>]) - Create a new classroom", }

commands["delete"] = {
    func = function(name, params)
        local realmID = params[1]

        if (realmID == nil) then
            return false, "No classroom ID specified"
        end

        if (realmID == mc_worldManager.spawnRealmID) then
            return false, "Cannot delete the spawn realm."
        end

        local requestedRealm = Realm.GetRealm(tonumber(realmID))
        if (requestedRealm == nil) then
            return false, "Requested classroom of ID: " .. tostring(realmID) .. " does not exist."
        end
        requestedRealm:Delete()
    end,
    help = "classroom delete <classroomID> - Delete a classroom", }

commands["list"] = {
    func = function(name, params)
        minetest.chat_send_player(name, "classroom Name : classroom ID")
        for i, t in pairs(Realm.realmDict) do
            minetest.chat_send_player(name, t.Name .. " : " .. t.ID)
        end

        return true
    end,
    help = "classroom list - List all classrooms", }

commands["info"] = {
    func = function(name, params)
        local realmID = params[1]
        local requestedRealm = Realm.GetRealm(tonumber(realmID))
        if (requestedRealm == nil) then
            return false, "Requested classroom does not exist."
        end

        local spawn = requestedRealm.SpawnPoint
        local startPos = requestedRealm.StartPos
        local endPos = requestedRealm.EndPos

        return true, "classroom ID " .. realmID .. " has a spawn point of "
                .. "x:" .. tostring(spawn.x) .. " y:" .. tostring(spawn.y) .. " z:" .. tostring(spawn.z)
                .. "; startPos of "
                .. "x:" .. tostring(startPos.x) .. " y:" .. tostring(startPos.y) .. " z:" .. tostring(startPos.z)
                .. "; endPos of "
                .. "x:" .. tostring(endPos.x) .. " y:" .. tostring(endPos.y) .. " z:" .. tostring(endPos.z)
    end,
    help = "classroom info <classroomID> - Get info about a classroom", }

commands["tp"] = {
    privs = { teleport = true },
    func = function(name, params)
        local realmID = params[1]
        local requestedRealm = Realm.GetRealm(tonumber(realmID))

        if (not minetest.player_exists(name)) then
            return false, "Player: " .. tostring(name) .. " could not be found"
        end

        if (requestedRealm == nil) then
            return false, "Requested classroom ID: " .. tostring(realmID) .. " does not exist."
        end

        local player = minetest.get_player_by_name(name)
        local success, reason = requestedRealm:TeleportPlayer(player)

        return success, reason
    end,
    help = "reaclassroomlm tp <classroomID> - Teleport to a classroom.", }

commands["walls"] = {
    func = function(name, params)
        local realmID = params[1]
        local requestedRealm = Realm.GetRealm(tonumber(realmID))
        if (requestedRealm == nil) then
            return false, "Requested classroom ID: " .. tostring(realmID) .. " does not exist."
        end

        if (params[2] ~= nil and params[2] == "fast") then
            requestedRealm:CreateBarriersFast()
        else
            requestedRealm:CreateBarriers()
        end

        return true, "created walls in classroom: " .. tostring(realmID)
    end,
    help = "classroom walls <classroomID> [<fast>] - Create walls in a classroom", }

commands["gen"] = {
    func = function(name, params)

        if (not mc_core.isNumber(params[1])) then
            if (params[1] ~= nil and params[1] == "list") then


                minetest.chat_send_player(name, "Generator Key")

                local heightmapGen = Realm.WorldGen.GetHeightmapGenerators()
                for k, v in pairs(heightmapGen) do
                    minetest.chat_send_player(name, v)
                end

                minetest.chat_send_player(name, "==============================")

                minetest.chat_send_player(name, "Decorator Key")

                local terrainDecorator = Realm.WorldGen.GetTerrainDecorator()
                for k, v in pairs(terrainDecorator) do
                    minetest.chat_send_player(name, v)
                end

                return true, "Listed all terrain generators and decorators."
            end
        end

        local realmID = params[1]
        local requestedRealm = Realm.realmDict[tonumber(realmID)]
        if (requestedRealm == nil) then
            return false, "Requested classroom of ID: " .. tostring(realmID) .. " does not exist."
        end

        local seaLevel = math.floor((requestedRealm.EndPos.y - requestedRealm.StartPos.y) * 0.4) + requestedRealm.StartPos.y
        Debug.log("Sea level:" .. seaLevel)

        local heightGen = params[2]
        local decGen = params[3]

        if (tonumber(params[4]) == nil and params[4] ~= nil and (params[4] ~= "default")) then
            return false, "Invalid seaLevel: " .. tostring(params[4]).. " - must be a number or default"
        end

        if (tonumber(params[5]) == nil and params[5] ~= nil and (params[5] ~= "random")) then
            return false, "Invalid seed: " .. tostring(params[5]).. " - must be a number or random"
        end


        local seaLevel = requestedRealm.StartPos.y
        if (tonumber(params[4]) == nil) then
            seaLevel = seaLevel + 30
        else
            seaLevel = seaLevel + tonumber(params[4])
        end

        if (heightGen == "" or heightGen == nil) then
            heightGen = "default"
        end

        local seed = tonumber(params[5])
        if (seed == nil) then
            seed = math.random(1, 999999999)
        end

        local extraGenParams = {}
        if (params[5] ~= nil) then
            for i = 6, #params do
                table.insert(extraGenParams, params[i])
            end
        end

        if (requestedRealm:GenerateTerrain(seed, seaLevel, heightGen, decGen, extraGenParams) == false) then
            return false, "Failed to generate terrain"
        end

        Debug.log("Creating barrier...")
        requestedRealm:CreateBarriersFast()

        return true, "Generated terrain in classroom: " .. tostring(realmID) .. " using seed " .. tostring(seed)
    end,
    help = "classroom gen <list> | (<classroomID> <heightGenKey> [<terrainDecKey>] ([<seaLevel>] [<seed>] [(optional param1), (optional param2) ...]) - Generate a classroom", }

commands["regen"] = {
    func = function(name, params)
        local realmID = params[1]
        local requestedRealm = Realm.realmDict[tonumber(realmID)]
        if (requestedRealm == nil) then
            return false, "Requested classroom ID: " .. tostring(realmID) .. " does not exist."
        end

        local seaLevel = math.floor((requestedRealm.EndPos.y - requestedRealm.StartPos.y) * 0.4) + requestedRealm.StartPos.y
        Debug.log("Sea level:" .. seaLevel)

        local seed = requestedRealm:get_data("worldSeed")
        local seaLevel = requestedRealm:get_data("seaLevel")
        local heightGen = requestedRealm:get_data("worldMapGenerator")
        local decGen = requestedRealm:get_data("worldDecoratorName")
        local extraGenParams = requestedRealm:get_data("worldExtraGenParams")


        if (seed == nil or seed == "nil") then
            return false, "Classroom does not have any saved seed information."
        end

        if (heightGen == nil or heightGen == "") then
            return false, "Classroom does not have any saved height generator information. Please try to manually regenerate world with gen command and seed " .. tostring(seed)
        end

        if (decGen == nil or decGen == "") then
            return false, "Classroom does not have any saved decorator information. Please try to manually regenerate world with gen command, seed " .. tostring(seed) .. " and height generator name " .. tostring(heightGen)
        end

        requestedRealm:GenerateTerrain(seed, seaLevel, heightGen, decGen, extraGenParams)

        Debug.log("Creating barrier...")
        requestedRealm:CreateBarriersFast()

        return true
    end,
    help = "classroom regen <classroomID> - Regenerates the terrain of a classroom.", }

commands["biomes"] = { func = function(name, params)
    minetest.chat_send_player(name, "Biome Key")
    local biomes = biomegen.get_biomes()
    local count = 0
    for k, v in pairs(biomes) do
        count = count + 1
        minetest.chat_send_player(name, v.name)
    end
    return true, "Listed all " .. tostring(count) .. " biomes."
end,
help = "classroom biomes - Lists all biomes.", }

commands["seed"] = { func = function(name, params)
    local realmID = params[1]
    local requestedRealm = Realm.GetRealm(tonumber(realmID))
    if (requestedRealm == nil) then
        return false, "Requested classroom ID: " .. tostring(realmID) .. " does not exist."
    end

    local seed = requestedRealm:get_data("worldSeed")

    return true, "World Seed for classroom: " .. tostring(seed)
end,
help = "classroom seed <classroomID> - Get the seed of a classroom.", }

commands["players"] = { func = function(name, params)
    minetest.chat_send_player(name, "======================")
    minetest.chat_send_player(name, "All Registered Players")
    minetest.chat_send_player(name, "======================")
    for pname, value in minetest.get_auth_handler().iterate() do
        minetest.chat_send_player(name, pname)
    end
end,
help = "classroom players - Lists all the registered player names that have every connected to the server.", }

commands["save"] = { func = function(name, params)
    local classroomName = params[1]

    local realmID
    for _, realm in pairs(Realm.realmDict) do 
        if realm.Name == classroomName then 
            realmID = realm.ID
        end 
    end
    if not realmID then
        return false, "Requested classroom name: " .. tostring(classroomName) .. " does not exist."
    end
    local realm = Realm.GetRealm(tonumber(realmID))
    local temp_data = {
        Name = classroomName,
        StartPos = realm.StartPos,
        EndPos = realm.EndPos,
        SpawnPoint = realm.SpawnPoint,
        PlayerJoinTable = realm.PlayerJoinTable,
        PlayerLeaveTable = realm.PlayerLeaveTable,
        RealmDeleteTable = realm.RealmDeleteTable,
        Permissions = realm.Permissions,
        PermissionsOverride = realm.PermissionsOverride,
        MetaStorage = realm.MetaStorage,
        data_chunks = {},
        light_chunks = {},
        param2_chunks = {},
    }

    -- Avoid table overflow with chunking
    local xsize = realm.EndPos.x - realm.StartPos.x
    local ysize = realm.EndPos.y - realm.StartPos.y
    local zsize = realm.EndPos.z - realm.StartPos.z
    local chunks = Realm:Create_VM_Chunks(realm.StartPos, realm.EndPos, mc_core.VM_CHUNK_SIZE)
    for index, chunk in pairs(chunks) do
        -- Get the data for the chunk
        local vm = VoxelManip(chunk.pos1, chunk.pos2)
        local data = vm:get_data()
        local light = vm:get_light_data()
        local param2 = vm:get_param2_data()
        
        -- Index and write the data
        temp_data.data_chunk = data
        temp_data.light_chunk = light
        temp_data.param2_chunk = param2
        
        -- Send classroom metadata in the first chunk
        if index == 1 then
            temp_data.Name = classroomName
            temp_data.StartPos = realm.StartPos
            temp_data.EndPos = realm.EndPos
            temp_data.SpawnPoint = realm.SpawnPoint
            temp_data.PlayerJoinTable = realm.PlayerJoinTable
            temp_data.PlayerLeaveTable = realm.PlayerLeaveTable
            temp_data.RealmDeleteTable = realm.RealmDeleteTable
            temp_data.Permissions = realm.Permissions
            temp_data.PermissionsOverride = realm.PermissionsOverride
            temp_data.MetaStorage = realm.MetaStorage
        end

        lasfile.meta:set_string("classroom_"..classroomName.."_data_chunk_"..index, minetest.serialize(temp_data))
        minetest.chat_send_player(name, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Saved classroom content for chunk "..index.." of "..#chunks.." total chunks."))

        -- Clean up
        vm, data, light, param2 = nil, nil, nil, nil, nil
        
    end
    return true, minetest.chat_send_player(name, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Successfully copied classroom content. You can load this content into a new classroom using the original classroom name with `classroom load "..classroomName.."`."))
end,
help = "classroom save <classroomName> - Store a copy of classroom content to mod storage, including node content IDs, param2 data, and lighting data. Existing data will be overwritten for the given classroom name.", }

commands["load"] = { func = function(name, params)
    local classroomName = params[1]

    -- Read the first chunk to get the necessary metadata
    local temp_data = minetest.deserialize(lasfile.meta:get_string("classroom_"..classroomName.."_data_chunk_1"))
    if not temp_data then
        return false, "Requested classroom name " .. tostring(classroomName) .. " does not exist or is not chunked in memory. If you expected this classroom to be saved, then try `classroom save "..tostring(classroomName).."`."
    end

    -- Create the new classroom
    local newRealm = Realm:New(classroomName, { x = (temp_data.EndPos.x - temp_data.StartPos.x), y = (temp_data.EndPos.y - temp_data.StartPos.y), z = (temp_data.EndPos.z - temp_data.StartPos.z) }, false)
    newRealm:set_data("owner", name)
    newRealm:CreateBarriersFast()
    newRealm:CallOnCreateCallbacks()

    -- Fill the content
    local chunks = Realm:Create_VM_Chunks(newRealm.StartPos, newRealm.EndPos, mc_core.VM_CHUNK_SIZE)
    for index, chunk in pairs(chunks) do
        -- Read the serialized data for the current chunk
        local temp_data = minetest.deserialize(lasfile.meta:get_string("classroom_"..classroomName.."_data_chunk_"..index))
        local vm = VoxelManip(chunk.pos1, chunk.pos2)
        local data = temp_data.data_chunk
        local light = temp_data.light_chunk
        local param2 = temp_data.param2_chunk

        -- Write the chunk data to the map
        if data then vm:set_data(data) end
        if param2 then vm:set_param2_data(param2)  end
        if light then vm:set_lighting(light)  end
        vm:write_to_map(true)
        
        -- Clean up
        vm, data, light, param2 = nil, nil, nil, nil, nil

        minetest.chat_send_player(name, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Loaded classroom content for chunk "..index.." of "..#chunks.." total chunks."))
    end

    -- Emerge classroom
    newRealm:EmergeRealm()

    return true, minetest.chat_send_player(name, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Successfully loaded classroom content into a new classroom with ID "..newRealm.ID.."."))
end,
help = "classroom load <classroomName> - Load a stored copy of classroom content (node content IDs, param2 data, and lighting) into a new classroom ID.", }

commands["delete_chunks"] = { func = function(name, params)
    local classroomName = params[1]

    -- Read the first chunk to get the necessary metadata
    local temp_data = minetest.deserialize(lasfile.meta:get_string("classroom_"..classroomName.."_data_chunk_1"))
    if not temp_data then
        return false, "Requested classroom name " .. tostring(classroomName) .. " does not exist or is not chunked in memory."
    end

    -- Delete chunks from mod storage
    local chunks = Realm:Create_VM_Chunks(newRealm.StartPos, newRealm.EndPos, mc_core.VM_CHUNK_SIZE)
    for index, chunk in pairs(chunks) do
        lasfile.meta:set_string("classroom_"..classroomName.."_data_chunk_"..index, minetest.serialize(nil))
        minetest.chat_send_player(name, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Deleted classroom content for chunk "..index.." of "..#chunks.." total chunks."))
    end

    -- Emerge classroom
    newRealm:EmergeRealm()

    return true, minetest.chat_send_player(name, minetest.colorize(mc_core.col.log, "[Minetest Classroom] Successfully loaded classroom content into a new classroom with ID "..newRealm.ID.."."))
end,
help = "classroom delete_chunks <classroomName> - Delete a stored copy of classroom content (node content IDs, param2 data, and lighting) from mod storage.", }


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
                return false, "Requested classroom ID: " .. tostring(realmID) .. " does not exist."
            end

            local schemName = tostring(params[2])
            Debug.log(schemName)

            local subparam = tostring(params[3])

            if (subparam == "" or subparam == "nil") then
                subparam = "old"
            end

            local path = requestedRealm:Save_Schematic(schemName, name, subparam)
            return true, "Saved classroom ID " .. realmID .. " at path: " .. path
        elseif (params[1] == "load") then
            table.remove(params, 1)
            local realmName = params[1]
            if (realmName == "" or realmName == nil) then
                realmName = "Unnamed classroom"
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
            return true, "creat[ing][ed] new classroom with name: " .. newRealm.Name .. "and ID: " .. newRealm.ID .. " from schematic with key " .. key
        elseif (params[1] == "register") then
            local schematic_path = minetest.get_worldpath() .. "\\realmSchematics\\"
            local files = minetest.get_dir_list(minetest.get_worldpath() .. "\\realmSchematics\\", false)
            local count = 0
            for k, fileName in pairs(files) do
                local filePath = minetest.get_worldpath() .. "\\realmSchematics\\" .. fileName
                local ext = string.sub(filePath, -5)
                if (ext == ".conf") then
                    local path = string.sub(filePath, 1, -6)
                    local key = string.sub(fileName, 1, -6)
                    schematicManager.registerSchematicPath(key, path)
                    count = count + 1
                end
            end
            return true, "Registered "..count.." schematics"
        else
            return false, "unknown subcommand. Try classroom schematic list | classroom schematic save | classroom schematic load"
        end
    end,
    help = "classroom schematic [save | load | register] - Save a classroom ID to a Minetest schematic (.mts), load a Minetest schematic file basename into a new classroom, or force register Minetest schematics stored in the world/realmSchematics folder.", }

commands["setspawn"] = {
    func = function(name, params)
        local player = minetest.get_player_by_name(name)

        local requestedRealm = Realm.GetRealmFromPlayer(player)

        local playerPosition = player:get_pos()

        if (not requestedRealm:ContainsCoordinate(playerPosition)) then
            return false, "You are not physically located in classroom" .. tostring(requestedRealm.ID) .. " Please re-enter classroom boundaries and try again."
        end

        local position = requestedRealm:WorldToLocalSpace(playerPosition)
        requestedRealm:UpdateSpawn(position)

        return true, "Updated spawnpoint for classroom ID: " .. requestedRealm.ID
    end,
    help = "classroom setspawn - Set the spawnpoint for the classroom that you are currently located in.", }

commands["setspawnclassroom"] = {
    func = function(name, params)
        local realmID = params[1]
        local requestedRealm = Realm.GetRealm(tonumber(realmID))
        if (requestedRealm == nil) then
            return false, "Requested classroom ID: " .. tostring(realmID) .. " does not exist."
        end

        local success = mc_worldManager.SetSpawnRealm(requestedRealm)

        if (success) then
            return true, "Updated the spawn classroom to classroom ID: " .. realmID
        else
            return false, "something went wrong... could not update the spawn classroom."
        end
    end,
    help = "classroom setspawnclassroom <classroomID> - Sets the spawn classroom to the classroom with the given ID." }

commands["category"] = {
    func = function(name, params)
        local subcommand = tostring(params[1])

        if (string.lower(subcommand) == "set") then
            local realmID = tonumber(params[2])
            local requestedRealm = Realm.GetRealm(tonumber(realmID))
            if (requestedRealm == nil) then
                return false, "Requested classroom of ID:" .. tostring(realmID) .. " does not exist."
            end

            local category = string.lower(tostring(params[3]))

            if (category == "nil") then
                category = "default"
            end

            if (Realm.getRegisteredCategories()[category] == nil) then
                return false, "Category: " .. category .. " is not registered. Try classroom category list to see all registered categories."
            end

            requestedRealm:setCategoryKey(category)
            return true, "Updated category for classroom with ID: " .. realmID .. " to " .. category
        elseif (string.lower(subcommand) == "list") then

            minetest.chat_send_player(name, "==========================")
            minetest.chat_send_player(name, "Valid Classroom Categories")
            minetest.chat_send_player(name, "==========================")
            local categories = Realm.getRegisteredCategories()
            for key, value in pairs(categories) do
                minetest.chat_send_player(name, key)
            end
            minetest.chat_send_player(name, "=======================")
            return true, "Listed all valid classroom categories."
        else
            return false, "unknown subcommand. Try classroom category set <category>"
        end


    end,
    help = "classroom category (set <classroomID> <category>) | (list) - Set the category of a classroom or list all valid categories.",
}

commands["consolidate"] = {
    func = function(name, params)
        Realm.consolidateEmptySpace()
        Realm.SaveDataToStorage()
        return true, "consolidated classrooms"
    end,
    help = "consolidate classroom placement information." }

commands["entity"] = {
    func = function(name, params)
        local subcommand = tostring(params[1])
        if (subcommand == "clear") then
            local realmID = tonumber(params[2])
            local requestedRealm = Realm.GetRealm(tonumber(realmID))
            if (requestedRealm == nil) then
                return false, "Requested classroom ID:" .. tostring(realmID) .. " does not exist."
            end
            requestedRealm:ClearEntities()
            return true, "Cleared items for classroom ID: " .. realmID
        end
        return false, "unknown subcommand. Try 'classroom entity clear <classroomID>'."
    end
}

commands["help"] = {
    func = function(name, params)

        local subcommand = params[1]

        if (subcommand ~= nil and subcommand ~= "") then

            local helpString
            if (commands[subcommand].help == "" or commands[subcommand].help == nil) then
                helpString = "No help available for this command."
            else
                helpString = commands[subcommand].help
            end
            return true, helpString
        end

        local helpString = ""
        for k, v in pairs(commands) do
            helpString = helpString .. k .. " | "
        end
        return true, helpString
    end,
    help = "help [command] - displays help for a command. If no command is specified, displays a list of commands."
}

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
            return false, "Incorrect parameter... Missing classroom privilege operation. Try 'classroom help privs' for help."
        end

        if (operation == "help") then
            return true, "execute 'classroom help privs' for help."
        end

        if (realmID == nil or realmID == "") then
            return false, "Incorrect parameter... Missing classroom ID. Try 'classroom help privs' for help."
        end

        local requestedRealm = Realm.realmDict[realmID]
        if (requestedRealm == nil) then
            return false, "Requested classroom ID: " .. tostring(realmID) .. " does not exist."
        end

        if (operation == "list") then

            if (requestedRealm.Permissions ~= nil) then
                for i, t in pairs(requestedRealm.Permissions) do
                    minetest.chat_send_player(name, "- " .. i)
                end
            else
                minetest.chat_send_player(name, "No classroom privileges have been set.")
            end

            return true, "command executed succesfully"
        end

        if (privilege == "nil" or privilege == "") then
            return false, "Incorrect parameter... Missing classroom privilege to add or revoke. Try 'classroom help privs' for help."
        end

        if (operation == "grant") then

            if (minetest.check_player_privs(name, privilege) == false) then
                return false, "Unable to add privilege: " .. privilege .. " to classroom" .. tostring(realmID) .. " as you do not hold this privilege."
            end
            local privsTable = {}
            privsTable[privilege] = true

            local success, invalidPrivs = requestedRealm:UpdateRealmPrivilege(privsTable)

            if (not success) then
                return false, "Unable to add privilege: " .. privilege .. " to classroom" .. tostring(realmID) .. " as it has not been whitelisted."
            end

            return true, "Added permission: " .. privilege .. " to classroom " .. tostring(realmID)
        elseif (operation == "revoke") then

            local privsTable = {}
            privsTable[privilege] = false

            requestedRealm:UpdateRealmPrivilege(privsTable)
            return true, "Removed permission: " .. privilege .. " from classroom " .. tostring(realmID)
        end
    end,
    help = "classroom privs (grant | list | revoke) <classroomID> <privilege>"
}

commands["players"] = {
    func = function(name, params)


        if (params[1] == "list") then
            local realmID = params[2]
            local requestedRealm = Realm.GetRealm(tonumber(realmID))
            if (requestedRealm == nil) then
                return false, "Requested classroom ID: " .. tostring(realmID) .. " does not exist."
            end

            local realmPlayerList = requestedRealm:get_tmpData("Inhabitants")

            if (realmPlayerList == nil) then
                return false, "no players found in classroom player list."
            end

            Debug.log(minetest.serialize(realmPlayerList))

            for k, v in pairs(realmPlayerList) do
                minetest.chat_send_player(name, k)
            end

            return true, "listed all players in classroom."
        elseif (params[1] == "scan") then
            Realm.ScanForPlayerRealms()
            return true, "re-associated players with classrooms."

        end

        return false, "unknown sub-command."
    end,
    help = "players <list | scan> - lists all players in a classroom. 'players scan' will re-associate players with classrooms."
}

commands["blocks"] = {
    func = function(name, params)
        if (params[1] == "teleporter") then
            local instanced = false
            local temp = false
            local realmID = 0

            local realmName = nil
            local schematic = nil

            local count = params[2]

            if (mc_core.isNumber(tostring(params[3]))) then
                realmID = tonumber(params[3])
            elseif (string.lower(tostring(params[3])) == "true") then
                instanced = true
            end

            if (string.lower(tostring(params[4])) == "true") then
                temp = true
            end

            realmName = tostring(params[5])
            schematic = tostring(params[6])

            if (schematic == "" or schematic == "nil") then
                schematic = nil
            elseif (schematicManager.getSchematic(schematic) == nil) then
                return false, "schematic " .. tostring(schematic) .. " does not exist."
            end

            local is = mc_worldManager.GetTeleporterItemStack(count, instanced, temp, realmID, realmName, schematic)

            local player = minetest.get_player_by_name(name)

            player:get_inventory():add_item("main", is)
            return true, "added teleporter to inventory."
        end

        return false, "For help, try 'classroom help blocks'."
    end,
    help = "classroom blocks <block> <count> (<instanced: true | false> | <classroomID>) <temporary: true | false> <classroomName> <schematic>"

}

commands["clean"] = {
    func = function(name, params)
        local realmID = tonumber(params[1])
        local requestedRealm = Realm.GetRealm(realmID)
        if (requestedRealm == nil) then
            return false, "Requested realm of ID: " .. tostring(realmID) .. " does not exist."
        end

        requestedRealm:Clean()
        return true, "cleaned classroom " .. tostring(realmID)
    end,
    help = "classroom clean <classroomID> -- replaces any unknown block with air."
}

commands["coordinates"] = {
    privs = { interact = true },
    func = function(name, params)
        local operation = tostring(params[1])
        local format = tostring(params[2])

        local playerRealm = Realm.GetRealmFromPlayer(minetest.get_player_by_name(name))

        if (operation == "set") then
            local hasPrivs, missing = minetest.check_player_privs(name, { teacher = true })

            if (not hasPrivs) then
                return false, "You do not have permission to set classroom coordinates. Missing: " .. tostring(missing)
            end

            if (format == "utm") then
                local utmInfo
                if (utmInfo == nil) then
                    utmInfo = { easting = tonumber(params[3]), northing = tonumber(params[4]), zone = tonumber(params[5]), utm_is_north = tostring(params[6]) }
                end
                playerRealm:set_data("UTMInfo", utmInfo)
                return true
            end
            return false, "invalid format."

        elseif (operation == "get") then
            local rawPos = minetest.get_player_by_name(name):getpos()
            local pos

            if (format == "world") then
                pos = rawPos
            elseif (format == "local" or format == "nil") then
                pos = playerRealm.WorldToLocalSpace(rawPos)
            elseif (format == "grid") then
                pos = Realm.worldToGridSpace(rawPos)
            elseif (format == "utm") then
                pos = playerRealm:WorldToUTMSpace(rawPos)
            elseif (format == "latlong") then
                pos = playerRealm:WorldToLatLongSpace(rawPos)
            else
                return false, "unknown format: " .. tostring(format)
            end

            minetest.chat_send_player(name, "Format: X: " .. tostring(pos.x) .. " Y: " .. tostring(pos.y) .. " Z: " .. tostring(pos.z))
            return true, "command executed succesfully"

        elseif (operation == "hud") then
            local player = minetest.get_player_by_name(name)
            local pmeta = player:get_meta()
            if (mc_worldManager.positionTextFunctions[format] ~= nil) then
                pmeta:set_string("positionHudMode", format)
                return true, "enabled position hud element for format " .. format .. "."
            elseif (format == "nil" or format == "none") then
                pmeta:set_string("positionHudMode", "")
                mc_worldManager.RemoveHud(player)
                return true, "disabled position hud element."
            end
            return false, "invalid format."
        end

        return false, "unknown command parameters."
    end,
    help = "classroom coordinates <set | get | hud> <format (world, grid, local, utm, latlong)>"
}

commands["data"] = {
    func = function(name, params)
        local realmID = tonumber(params[2])
        local operation = tostring(params[1])

        local realm = Realm.GetRealm(realmID)
        if (realm == nil) then
            return false, "classroom " .. tostring(realmID) .. " does not exist."
        end
        if (operation == "get") then
            local data = realm:get_data(tostring(params[3]))
            if (data == nil) then
                return false, "data " .. tostring(params[3]) .. " does not exist."
            end
            minetest.chat_send_player(name, "Data: " .. tostring(data))
            return true, "command executed succesfully"
        elseif (operation == "set") then
            realm:set_data(tostring(params[3]), tostring(params[4]))
            return true, "command executed succesfully"
        elseif (operation == "dump") then
            local data = realm.MetaStorage
            minetest.chat_send_player(name, "Data: " .. tostring(minetest.serialize(data)))
            return true, "command executed succesfully"
        end
        return false, "unknown sub-command."
    end,
    help = "classroom data <get | set | dump> <classroomID> <dataName> <dataValue>"
}

minetest.register_chatcommand("classroom", {
    params = "Subcommand classroom ID Option",
    func = function(name, param)
        local params = mc_core.split(param, " ")
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
            return false, "Unknown subcommand. Use 'classroom help' for a list of sub-commands."
        end
    end,
})

-- Gets called when a command is called, before it is handled by the engine / lua runtime.
minetest.register_on_chatcommand(function(name, command, params)

    if (command == "grantme") then
        local privTable = mc_core.split(params, ", ")
        mc_worldManager.grantUniversalPriv(minetest.get_player_by_name(name), privTable)
        return false -- we must return false so that the regular grant command proceeds.
    elseif (command == "revokeme") then
        local privTable = mc_core.split(params, ", ")
        mc_worldManager.revokeUniversalPriv(minetest.get_player_by_name(name), privTable)
        return false -- we must return false so that the regular grant command proceeds.
    end

    -- Gets called when grant / revoke is called. We're using this to add permissions that are granted onto the universalPrivs table.

    if (command == "grant" or command == "revoke") then
        local privsTable = mc_core.split(params, ", ")
        local tmpTable = mc_core.split(table.remove(privsTable, 1), " ")

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
    description = "Teleport yourself or a specified player to a classroom or another player.",
    params = "<classroom ID> | <target player> | (<player name> <classroom ID>) | (<player name> <target player name>) | (<classroom ID> <local x pos> <local y pos> <local z pos>)",
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
                return false, "Player " .. tostring(othername) .. " is not listed in a classroom OR current classroom has been deleted; Try teleporting to a different classroom and then back..."
            end

            requestedRealm:TeleportPlayer(player)
            local pos = otherPlayer:get_pos()
            player:set_pos(pos)
            return true, "Teleported to " .. tostring(othername) .. " in classroom " .. tostring(realmID)
        end

        local paramTable = mc_core.split(param, " ")
        if (paramTable == nil) then
            paramTable = { param }
        end

        if (mc_core.isNumber(paramTable[1]) and mc_core.isNumber(paramTable[2]) and mc_core.isNumber(paramTable[3]) and mc_core.isNumber(paramTable[4])) then
            local realmID = paramTable[1]
            local requestedRealm = Realm.realmDict[tonumber(realmID)]

            if (not minetest.player_exists(name)) then
                return false, "Player: " .. tostring(name) .. " could not be found"
            end

            if (requestedRealm == nil) then
                return false, "Requested classroom ID: " .. tostring(realmID) .. " does not exist."
            end

            local player = minetest.get_player_by_name(name)

            local position = { x = paramTable[2], y = paramTable[3], z = paramTable[4] }
            local worldPosition = requestedRealm:LocalToWorldSpace(position)

            if (not requestedRealm:ContainsCoordinate(worldPosition)) then
                return false, "requested position does not exist in classroom " .. tostring(realmID)
            end

            requestedRealm:TeleportPlayer(player)
            player:set_pos(worldPosition)
        elseif (mc_core.isNumber(paramTable[1]) and paramTable[2] == nil) then
            return commands["tp"].func(name, paramTable)
        elseif (paramTable[1] ~= nil and paramTable[2] == nil) then
            return teleport(name, paramTable[1])
        elseif (paramTable[1] ~= nil and mc_core.isNumber(paramTable[2])) then
            return commands["tp"].func(paramTable[1], { paramTable[2] })
        elseif (paramTable[1] ~= nil and paramTable[2] ~= nil) then
            return teleport(paramTable[1], paramTable[2])
        end

        return false, "unable to parse parameters: " .. tostring(param)
    end,
})
