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
            minetest.chat_send_all("Finished deleting realm!")
        end

        local pos1 = { x = blockpos.x * 16, y = blockpos.y * 16, z = blockpos.z * 16 }
        local pos2 = { x = blockpos.x * 16 + 15, y = blockpos.y * 16 + 15, z = blockpos.z * 16 + 15 }

        context.realm:SetNodes(pos1, pos2, "air")
    end

    local context = {} -- persist data between callback calls
    context.realm = self
    minetest.emerge_area(self.StartPos, self.EndPos, emerge_callback, context)

    minetest.chat_send_all("[INFO] Started cleaning up a realm, block placement might act unresponsive for a moment.")
end

---@public
---Creates a ground plane between the realms start and end positions.
---@return void
function Realm:CreateGround(nodeType)
    nodeType = nodeType or "mc_worldmanager:temp"
    local pos1 = { x = self.StartPos.x, y = (self.StartPos.y + self.EndPos.y) / 2, z = self.StartPos.z }
    local pos2 = { x = self.EndPos.x, y = (self.StartPos.y + self.EndPos.y) / 2, z = self.EndPos.z }

    self:SetNodes(pos1, pos2, nodeType)
end

---@public
---Creates invisible walls around the realm.
---@return void
function Realm:CreateBarriers()
    local pos1 = { x = self.StartPos.x, y = self.StartPos.y, z = self.StartPos.z }
    local pos2 = { x = self.StartPos.x, y = self.EndPos.y, z = self.EndPos.z }
    self:SetNodes(pos1, pos2, "unbreakable_map_barrier:barrier")

    local pos1 = { x = self.EndPos.x, y = self.StartPos.y, z = self.StartPos.z }
    local pos2 = { x = self.EndPos.x, y = self.EndPos.y, z = self.EndPos.z }
    self:SetNodes(pos1, pos2, "unbreakable_map_barrier:barrier")

    local pos1 = { x = self.StartPos.x, y = self.StartPos.y, z = self.StartPos.z }
    local pos2 = { x = self.EndPos.x, y = self.StartPos.y, z = self.EndPos.z }
    self:SetNodes(pos1, pos2, "unbreakable_map_barrier:barrier")

    local pos1 = { x = self.StartPos.x, y = self.EndPos.y, z = self.StartPos.z }
    local pos2 = { x = self.EndPos.x, y = self.EndPos.y, z = self.EndPos.z }
    self:SetNodes(pos1, pos2, "unbreakable_map_barrier:barrier")

    local pos1 = { x = self.StartPos.x, y = self.StartPos.y, z = self.StartPos.z }
    local pos2 = { x = self.EndPos.x, y = self.EndPos.y, z = self.StartPos.z }
    self:SetNodes(pos1, pos2, "unbreakable_map_barrier:barrier")

    local pos1 = { x = self.StartPos.x, y = self.StartPos.y, z = self.EndPos.z }
    local pos2 = { x = self.EndPos.x, y = self.EndPos.y, z = self.EndPos.z }
    self:SetNodes(pos1, pos2, "unbreakable_map_barrier:barrier")
end

---Helper function to set cubic areas of nodes based on world coordinates and node type
---@param pos1 table coordinates
---@param pos2 table coordinates
---@param pos2 string nodeType name
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