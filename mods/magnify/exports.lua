-- EXPORTED MAGNIFY FUNCTIONS
local magnify = {}

-- node registration function
function magnify.register_plant(def_table, blocks)
    local ref = minetest_classroom.bc_plants:get_int("count")
    local serial_table = minetest.serialize(def_table)
    minetest_classroom.bc_plants:set_string("ref_"..ref, serial_table)
    for k,v in pairs(blocks) do
        minetest_classroom.bc_plants:set_string("node_"..v, "ref_"..ref)
    end
    minetest_classroom.bc_plants:set_int("count", ref + 1)
end

return magnify