function Realm:ClearEntities()
    local entities = minetest.get_objects_in_area(self.StartPos, self.EndPos)
    for _, entity in ipairs(entities) do
        if (entity:get_luaentity() ~= nil) then
            entity:remove()
        end
    end
end