minetest.register_tool("mc_student:notebook" , {
	description = "Notebook for students",
	inventory_image = "notebook.png",
	_mc_tool_privs = {interact = true},
	on_use = function (itemstack, player, pointed_thing)
        local pname = player:get_player_name()
		local pmeta = player:get_meta()
		if mc_core.checkPrivs(player,{interact = true}) then
			mc_student.show_notebook_fs(player,pmeta:get_string("default_student_tab"))
		end
	end,
	on_drop = function(itemstack, dropper, pos)
	end,
})

if minetest.get_modpath("mc_toolhandler") then
	mc_toolhandler.register_tool_manager("mc_student:notebook", {privs = {interact = true}, inv_override = "main"})
end