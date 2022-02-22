local FS = minetest_classroom.FS

function minetest_classroom.show_new_group(player)
	if not minetest.check_player_privs(player:get_player_name(), { teacher = true }) then
		return
	end

	minetest.show_formspec(player:get_player_name(), "mc_teacher:new_group", table.concat({
		"size[5,1.8]",
		"field[0.2,0.4;5,1;name;", FS"Name", ";]",
		"button[1.5,1;2,1;create;", FS"Create", "]",
	}, ""))
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "mc_teacher:new_group" or
			not minetest.check_player_privs(player:get_player_name(), { teacher = true }) or
			not fields.create then
		return false
	end

	local group = minetest_classroom.create_group(fields.name:trim())
	if group then
		sfinv.set_player_inventory_formspec(player)
		minetest_classroom.show_edit_group(player, group.name)
	else
		minetest_classroom.show_new_group(player, fields.name)
	end
end)

local _contexts = {}

function minetest_classroom.show_edit_group(player, groupname)
	local name = player:get_player_name()
	if not minetest.check_player_privs(name, { teacher = true }) then
		return
	end

	local context = _contexts[name] or {}
	_contexts[name] = context

	context.groupname = groupname or context.groupname
	context.index_l = context.index_l or 1
	context.index_r = context.index_r or 1

	local fs = {
		"size[5.55,6]",
		"label[0,-0.1;", FS"Other students", "]",
		"label[3.3,-0.1;",
		FS("Students in group @1", context.groupname),
		"]",
		"button[2.25,0.5;1,1;go_right;", minetest.formspec_escape(">"), "]",
		"button[2.25,1.5;1,1;go_left;", minetest.formspec_escape("<"), "]",
	}

	local members = minetest_classroom.get_group_students(groupname)
	if #members > 0 then
		if context.index_r > #members then
			context.index_r = #members
		end
		fs[#fs + 1] = "textlist[3.25,0.5;2,5.5;right;"
		for i, member in pairs(members) do
			if i > 1 then
				fs[#fs + 1] = ","
			end
			fs[#fs + 1] = minetest.formspec_escape(member)
		end

		fs[#fs + 1] = ";"
		fs[#fs + 1] = tostring(context.index_r)
		fs[#fs + 1] = "]"
	else
		fs[#fs + 1] = "label[3.5,0.7;"
		fs[#fs + 1] = FS("No students")
		fs[#fs + 1] = "]"
	end

	local not_members = minetest_classroom.get_students_except(members)
	if #not_members > 0 then
		if context.index_l > #not_members then
			context.index_l = #members
		end

		fs[#fs + 1] = "textlist[0,0.5;2,5.5;left;"

		for i, member in pairs(not_members) do
			if i > 1 then
				fs[#fs + 1] = ","
			end
			fs[#fs + 1] = minetest.formspec_escape(member)
		end

		fs[#fs + 1] = ";"
		fs[#fs + 1] = tostring(context.index_l)
		fs[#fs + 1] = "]"
	else
		fs[#fs + 1] = "label[0.4,0.7;"
		fs[#fs + 1] = FS("No students")
		fs[#fs + 1] = "]"
	end

	minetest.show_formspec(player:get_player_name(), "mc_teacher:edit_group", table.concat(fs, ""))
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "mc_teacher:edit_group" or
			not minetest.check_player_privs(player:get_player_name(), { teacher = true }) then
		return false
	end

	local context = _contexts[player:get_player_name()]
	if not context or not context.groupname then
		return false
	end

	if fields.left then
		local evt = minetest.explode_textlist_event(fields.left)
		if evt.type == "CHG" then
			context.index_l = evt.index
			return true
		end
	end

	if fields.right then
		local evt = minetest.explode_textlist_event(fields.right)
		if evt.type == "CHG" then
			context.index_r = evt.index
			return true
		end
	end

	if fields.quit then
		_contexts[player:get_player_name()] = nil
	end

	if fields.go_right and context.index_l then
		local students = minetest_classroom.get_group_students(context.groupname)
		local not_members = minetest_classroom.get_students_except(students)
		local student = not_members[context.index_l]
		if student then
			minetest_classroom.add_student_to_group(context.groupname, student)
			minetest_classroom.show_edit_group(player, context.groupname)
			sfinv.set_player_inventory_formspec(player)
			return true
		end
	end

	if fields.go_left and context.index_r then
		local students = minetest_classroom.get_group_students(context.groupname)
		local student = students[context.index_r]
		if student then
			minetest_classroom.remove_student_from_group(context.groupname, student)
			minetest_classroom.show_edit_group(player, context.groupname)
			sfinv.set_player_inventory_formspec(player)
			return true
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	_contexts[player:get_player_name()] = nil
end)
