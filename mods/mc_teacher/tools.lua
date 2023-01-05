-- The controller for accessing the teacher actions
minetest.register_tool("mc_teacher:controller", {
    description = "Controller for teachers",
    inventory_image = "controller.png",
    _mc_tool_privs = {teacher = true},
    -- Left-click the tool activates the teacher menu
    on_use = function(itemstack, player, pointed_thing)
        local pname = player:get_player_name()
        local pmeta = player:get_meta()
        if mc_helpers.checkPrivs(player) then
            mc_teacher.show_controller_fs(player,pmeta:get_string("default_student_tab"))
        end
    end,
    on_drop = function(itemstack, dropper, pos)
    end,
})

if minetest.get_modpath("mc_toolhandler") then
	mc_toolhandler.register_tool_manager("mc_teacher:controller", {privs = priv_table, inv_override = "main"})
end