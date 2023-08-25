minetest.register_tool("mc_student:notebook" , {
    description = "Notebook for students",
    inventory_image = "mc_student_notebook.png",
    on_use = function(itemstack, player, pointed_thing)
        local pmeta = player:get_meta()
        if pmeta:get_string("default_student_tab") ~= "" then
            mc_student.show_notebook_fs(player,pmeta:get_string("default_student_tab"))
        else
            mc_student.show_notebook_fs(player, mc_student.TABS.OVERVIEW)
        end
    end,
    on_drop = function(itemstack, dropper, pos)
    end,
})

if minetest.get_modpath("mc_toolhandler") then
    mc_toolhandler.register_tool_manager("mc_student:notebook", {privs = {}, inv_override = "main"})
end