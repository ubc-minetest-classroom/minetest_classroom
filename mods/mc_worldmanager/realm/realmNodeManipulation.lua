---@public
---Sets all nodes in a realm to air.
---This function dispatches additional asynchronous function calls to prevent crashing the server.
---@return void
function Realm:ClearNodes()
    local function emerge_callback(blockpos, action,
                                   num_calls_remaining, context)
        -- On first call, record number of blocks
        if not context.total_blocks then
            context.total_blocks = num_calls_remaining + 1
            context.loaded_blocks = 0
        end

        -- Increment number of blocks loaded
        context.loaded_blocks = context.loaded_blocks + 1

        -- Send progress message
        -- Send progress message
        if context.total_blocks == context.loaded_blocks then
            minetest.chat_send_all(minetest.colorize(mc_core.col.log, "[Minetest Classroom] Finished deleting the classroom."))
        end

        local pos1 = { x = blockpos.x * 16, y = blockpos.y * 16, z = blockpos.z * 16 }
        local pos2 = { x = blockpos.x * 16 + 15, y = blockpos.y * 16 + 15, z = blockpos.z * 16 + 15 }
        
        -- Chunk the VM
        local chunks = Realm:Create_VM_Chunks(pos1, pos2, mc_core.VM_CHUNK_SIZE)
        for _, chunk in pairs(chunks) do
            context.realm:SetNodes(chunk.pos1, chunk.pos2, "air")
        end
    end

    local context = {} -- persist data between callback calls
    context.realm = self

    local startPos = { x = self.StartPos.x - 40, y = self.StartPos.y - 40, z = self.StartPos.z - 40 }
    local endPos = { x = self.EndPos.x + 40, y = self.EndPos.y + 40, z = self.EndPos.z + 40 }

    minetest.emerge_area(startPos, endPos, emerge_callback, context)
    minetest.chat_send_all(minetest.colorize(mc_core.col.log, "[Minetest Classroom] Started cleaning up a classroom, block placement might act unresponsive for a moment."))
end

---@public
---Creates a ground plane between the realms start and end positions.
---@return void
function Realm:CreateGround(nodeType, height)
    nodeType = nodeType or "mc_worldmanager:temp"
    local pos1 = { x = self.StartPos.x, y = self.StartPos.y + (height or 1), z = self.StartPos.z }
    local pos2 = { x = self.EndPos.x, y = self.StartPos.y + (height or 1), z = self.EndPos.z }

    -- Chunk the VM
    local chunks = Realm:Create_VM_Chunks(pos1, pos2, mc_core.VM_CHUNK_SIZE)
    for _, chunk in pairs(chunks) do
        self:SetNodes(chunk.pos1, chunk.pos2, nodeType)
    end
end

---@public
---Fills below ground plane between the realms start and end positions.
---@return void
function Realm:FillBelowGround(nodeType, fill_depth)
    nodeType = nodeType or "mc_worldmanager:temp"
    local pos1 = { x = self.StartPos.x, y = self.StartPos.y + 1, z = self.StartPos.z }
    local pos2 = { x = self.EndPos.x, y = self.StartPos.y + fill_depth, z = self.EndPos.z }

    -- Chunk the VM
    local chunks = Realm:Create_VM_Chunks(pos1, pos2, mc_core.VM_CHUNK_SIZE)
    for _, chunk in pairs(chunks) do
        self:SetNodes(chunk.pos1, chunk.pos2, nodeType)
    end
end

---@public
---Creates invisible walls around the realm.
---@return void
function Realm:CreateBarriers()
    local pos1 = { x = self.StartPos.x, y = self.StartPos.y, z = self.StartPos.z }
    local pos2 = { x = self.StartPos.x, y = self.EndPos.y, z = self.EndPos.z }
    -- Chunk the VM
    local chunks = Realm:Create_VM_Chunks(pos1, pos2, mc_core.VM_CHUNK_SIZE)
    for _, chunk in pairs(chunks) do
        self:SetNodes(chunk.pos1, chunk.pos2, "unbreakable_map_barrier:barrierAir")
    end

    local pos1 = { x = self.EndPos.x, y = self.StartPos.y, z = self.StartPos.z }
    local pos2 = { x = self.EndPos.x, y = self.EndPos.y, z = self.EndPos.z }
    local chunks = Realm:Create_VM_Chunks(pos1, pos2, mc_core.VM_CHUNK_SIZE)
    for _, chunk in pairs(chunks) do
        self:SetNodes(chunk.pos1, chunk.pos2, "unbreakable_map_barrier:barrierAir")
    end

    local pos1 = { x = self.StartPos.x, y = self.StartPos.y, z = self.StartPos.z }
    local pos2 = { x = self.EndPos.x, y = self.StartPos.y, z = self.EndPos.z }
    local chunks = Realm:Create_VM_Chunks(pos1, pos2, mc_core.VM_CHUNK_SIZE)
    for _, chunk in pairs(chunks) do
        self:SetNodes(chunk.pos1, chunk.pos2, "unbreakable_map_barrier:barrierAir")
    end

    local pos1 = { x = self.StartPos.x, y = self.EndPos.y, z = self.StartPos.z }
    local pos2 = { x = self.EndPos.x, y = self.EndPos.y, z = self.EndPos.z }
    local chunks = Realm:Create_VM_Chunks(pos1, pos2, mc_core.VM_CHUNK_SIZE)
    for _, chunk in pairs(chunks) do
        self:SetNodes(chunk.pos1, chunk.pos2, "unbreakable_map_barrier:barrierAir")
    end

    local pos1 = { x = self.StartPos.x, y = self.StartPos.y, z = self.StartPos.z }
    local pos2 = { x = self.EndPos.x, y = self.EndPos.y, z = self.StartPos.z }
    local chunks = Realm:Create_VM_Chunks(pos1, pos2, mc_core.VM_CHUNK_SIZE)
    for _, chunk in pairs(chunks) do
        self:SetNodes(chunk.pos1, chunk.pos2, "unbreakable_map_barrier:barrierAir")
    end

    local pos1 = { x = self.StartPos.x, y = self.StartPos.y, z = self.EndPos.z }
    local pos2 = { x = self.EndPos.x, y = self.EndPos.y, z = self.EndPos.z }
    local chunks = Realm:Create_VM_Chunks(pos1, pos2, mc_core.VM_CHUNK_SIZE)
    for _, chunk in pairs(chunks) do
        self:SetNodes(chunk.pos1, chunk.pos2, "unbreakable_map_barrier:barrierAir")
    end
end

---Helper function to split the voxel manipulator space into chunks and return a list of chunks
---@param pos1 table coordinates
---@param pos2 table coordinates
---@param chunk_size integer chunk size limit in x, y, and z dimensions
function Realm:Create_VM_Chunks(pos1, pos2, chunk_size)
    local chunks = {}
    
    local num_chunks_x = math.ceil((pos2.x - pos1.x + 1) / chunk_size)
    local num_chunks_y = math.ceil((pos2.y - pos1.y + 1) / chunk_size)
    local num_chunks_z = math.ceil((pos2.z - pos1.z + 1) / chunk_size)
    
    for chunk_z = 0, num_chunks_z - 1 do
        for chunk_y = 0, num_chunks_y - 1 do
            for chunk_x = 0, num_chunks_x - 1 do
                local chunk_pos1 = {
                    x = pos1.x + chunk_x * chunk_size,
                    y = pos1.y + chunk_y * chunk_size,
                    z = pos1.z + chunk_z * chunk_size
                }
                local chunk_pos2 = {
                    x = math.min(chunk_pos1.x + chunk_size - 1, pos2.x),
                    y = math.min(chunk_pos1.y + chunk_size - 1, pos2.y),
                    z = math.min(chunk_pos1.z + chunk_size - 1, pos2.z)
                }
                table.insert(chunks, {pos1 = chunk_pos1, pos2 = chunk_pos2})
            end
        end
    end
    
    return chunks
end

---Helper function to set cubic areas of nodes based on world coordinates and node type
---@param pos1 table coordinates
---@param pos2 table coordinates
---@param node string nodeType name
function Realm:SetNodes(pos1, pos2, node)
    local node_id = minetest.get_content_id(node)

    -- Read data into LVM
    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(pos1, pos2)
    local a = VoxelArea:new {
        MinEdge = emin,
        MaxEdge = emax
    }
    local data = vm:get_data()

    -- Modify data
    for z = pos1.z, pos2.z do
        for y = pos1.y, pos2.y do
            for x = pos1.x, pos2.x do
                local vi = a:index(x, y, z)
                data[vi] = node_id
            end
        end
    end

    -- Write data to world
    vm:set_data(data)
    vm:write_to_map(true)
end

---@public
---Sets all nodes in a realm to air.
---This function dispatches additional asynchronous function calls to prevent crashing the server.
---@return void
function Realm:CreateBarriersFast()
    local function emerge_callback(blockpos, action,
                                   num_calls_remaining, context)
        -- On first call, record number of blocks
        if not context.total_blocks then
            context.total_blocks = num_calls_remaining + 1
            context.loaded_blocks = 0
        end

        -- Increment number of blocks loaded
        context.loaded_blocks = context.loaded_blocks + 1

        -- Send finished message
        if context.total_blocks == context.loaded_blocks then
            minetest.chat_send_all(minetest.colorize(mc_core.col.log, "[Minetest Classroom] Finished walling the classroom."))
        end

        local pos1 = { x = blockpos.x * 16, y = blockpos.y * 16, z = blockpos.z * 16 }
        local pos2 = { x = blockpos.x * 16 + 15, y = blockpos.y * 16 + 15, z = blockpos.z * 16 + 15 }

        -- If we are in the middle of a realm, we can return as we don't need to place any barriers here.
        if (pos1.x > context.startPos.x + 15 and pos1.x < context.endPos.x - 15 and pos1.y > context.startPos.y + 15 and pos1.y < context.endPos.y - 15 and pos1.z > context.startPos.z + 15 and pos1.z < context.endPos.z - 15) then
            return
        end

        local barrierNodeAir = minetest.get_content_id("unbreakable_map_barrier:barrierAir")
        local barrierNodeSolid = minetest.get_content_id("unbreakable_map_barrier:barrierSolid")
        local barrierNodeVoid = minetest.get_content_id("unbreakable_map_barrier:barrierGround")
        local airNode = minetest.get_content_id("air")

        -- Read data into LVM
        local vm = minetest.get_voxel_manip()
        local emin, emax = vm:read_from_map(pos1, pos2)
        local a = VoxelArea:new {
            MinEdge = emin,
            MaxEdge = emax
        }
        local data = vm:get_data()

        -- Modify data
        for z = pos1.z, pos2.z do
            for y = pos1.y, pos2.y do
                for x = pos1.x, pos2.x do
                    -- Check if we are in the realm. If we are, we place barrier. If not, we clean up the boundary area.
                    -- This can probably be optimized but it's fast enough for now.
                    if (x >= context.startPos.x and x <= context.endPos.x) and (y >= context.startPos.y and y <= context.endPos.y) and (z >= context.startPos.z and z <= context.endPos.z) then
                        if (x == context.startPos.x or x == context.endPos.x) or (y == context.startPos.y or y == context.endPos.y) or (z == context.startPos.z or z == context.endPos.z) then
                            local index = a:index(x, y, z)
                            if (y == context.startPos.y) then
                                data[index] = barrierNodeVoid
                            elseif (data[index] ~= airNode) then
                                data[index] = barrierNodeSolid
                            else
                                data[index] = barrierNodeAir
                            end
                        end
                    else
                        local index = a:index(x, y, z)
                        data[index] = airNode
                    end
                end
            end
        end

        -- Write data to world
        vm:set_data(data)
        vm:write_to_map(true)

    end

    local context = {} -- persist data between callback calls
    context.realm = self
    context.startPos = self.StartPos
    context.endPos = self.EndPos

    local realmStartPos = { x = self.StartPos.x - 16, y = self.StartPos.y - 16, z = self.StartPos.z - 16 }
    local realmEndPos = { x = self.EndPos.x + 16, y = self.EndPos.y + 16, z = self.EndPos.z + 16 }

    minetest.emerge_area(realmStartPos, realmEndPos, emerge_callback, context)
    minetest.chat_send_all(minetest.colorize(mc_core.col.log, "[Minetest Classroom] Started creating the classroom, block placement might act unresponsive for a moment."))
end

---@public
---Forces emerge of realm nodes.
---This function dispatches additional asynchronous function calls to prevent crashing the server.
---@return void
function Realm:EmergeRealm()
    local function emerge_callback(blockpos, action,
                                   num_calls_remaining, context)
        -- On first call, record number of blocks
        if not context.total_blocks then
            context.total_blocks = num_calls_remaining + 1
            context.loaded_blocks = 0
        end

        -- Increment number of blocks loaded
        context.loaded_blocks = context.loaded_blocks + 1

        -- Send finished message
        if context.total_blocks == context.loaded_blocks then
            minetest.chat_send_all(minetest.colorize(mc_core.col.log, "[Minetest Classroom] Finished emerging the classroom."))
        end
    end

    local context = {} -- persist data between callback calls
    context.realm = self
    context.startPos = self.StartPos
    context.endPos = self.EndPos

    minetest.emerge_area(context.startPos, context.endPos, emerge_callback, context)
end

function Realm:CleanNodes()
    local count = 0
    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(self.StartPos, self.EndPos)
    local a = VoxelArea:new {
        MinEdge = emin,
        MaxEdge = emax
    }
    local data = vm:get_data()

    -- Modify data
    for i in a:iterp(self.StartPos, self.EndPos) do
        local currentNode = minetest.get_name_from_content_id(data[i])
        if not minetest.registered_nodes[currentNode] then
            data[i] = minetest.get_content_id("air") -- replace unknown with air
            count = count + 1
        end
    end

    -- write changes to map
    vm:set_data(data)
    vm:write_to_map()
    return count
end