local _groups = {}
local _action_by_name = {}
local _actions = {}

-- Load data from MetaDataRef
function minetest_classroom.load_from(meta)
	local groups_str = meta:get("groups")
	if not groups_str then
		return
	end

	_groups = minetest.deserialize(groups_str)
end

-- Save data to MetaDataRef
function minetest_classroom.save_to(meta)
	meta:set_string("groups", minetest.serialize(_groups))
end

function minetest_classroom.save()
	-- Overridden in init.lua
end

function minetest_classroom.get_students()
	local students = {}
	for _, player in pairs(minetest_classroom.get_connected_players()) do
		if not minetest_classroom.check_player_privs(player, { teacher = true }) then
			students[#students + 1] = player:get_player_name()
		end
	end

	return students
end

function minetest_classroom.get_group_students(name)
	local group = minetest_classroom.get_group(name)
	if not group then
		return nil
	end

	local students = {}
	for _, student in pairs(group.students) do
		if minetest_classroom.get_player_by_name(student) then
			students[#students + 1] = student
		end
	end

	return students
end

function minetest_classroom.get_students_except(students)
	local student_by_name = {}
	for _, name in pairs(students) do
		student_by_name[name] = true
	end

	local retval = {}
	for _, player in pairs(minetest_classroom.get_connected_players()) do
		if not student_by_name[player:get_player_name()] and
				not minetest_classroom.check_player_privs(player, { teacher = true }) then
			retval[#retval + 1] = player:get_player_name()
		end
	end

	return retval
end

function minetest_classroom.get_all_groups()
	return _groups
end

function minetest_classroom.get_group(name)
	return _groups[name]
end

function minetest_classroom.create_group(name)
	if _groups[name] or #name == 0 then
		return nil
	end

	local group = {
		name = name,
		students = {},
	}

	_groups[name] = group

	minetest_classroom.save()

	return group
end

function minetest_classroom.remove_group(name)
	_groups[name].students = nil
	_groups[name].name = nil
	_groups[name] = nil

	minetest_classroom.save()
end


function minetest_classroom.add_student_to_group(name, student)
	local group = minetest_classroom.get_group(name)
	if group then
		for i=1, #group.students do
			if group.students[i] == student then
				return
			end
		end

		group.students[#group.students + 1] = student

		minetest_classroom.save()
	end
end

function minetest_classroom.remove_student_from_group(name, student)
	local group = minetest_classroom.get_group(name)
	if group then
		for i=1, #group.students do
			if group.students[i] == student then
				table.remove(group.students, i)

				minetest_classroom.save()
			end
		end
	end
end

function minetest_classroom.register_action(name, def)
	def.name = name
	_action_by_name[name] = def
	table.insert(_actions, def)
end

function minetest_classroom.get_actions()
	return _actions
end

function minetest_classroom.get_students_by_selector(selector)
	if selector == "*" then
		return minetest_classroom.get_students()
	elseif selector:sub(1, 6) == "group:" then
		return minetest_classroom.get_group_students(selector:sub(7))
	elseif selector:sub(1, 5) == "user:" then
		local pname = selector:sub(6)
		if minetest_classroom.get_player_by_name(pname) then
			return { pname }
		else
			return {}
		end
	else
		return {}
	end
end

function minetest_classroom.run_action(aname, runner, selector, params)
	local action   = _action_by_name[aname]
	local students = minetest_classroom.get_students_by_selector(selector)
	if #students > 0 then
		action.func(runner, students)
	end
end
