minetest_classroom = {}

local infos = {
	{
		title = "Mute?",
		type = "priv",
		privs = { shout = true },
	},
	{
		title = "Fly?",
		type = "priv",
		privs = { fly = true },
	},
	{
		title = "Freeze?",
		type = "priv",
		privs = { fast = true },
	},
	{
		title = "Dig?",
		type = "priv",
		privs = { interact = true },
	},
}

-- Check for teacher priv
local function check_perm(player)
	return minetest.check_player_privs(player:get_player_name(), { teacher = true })
end

-- Label the teacher in red
minetest.register_on_joinplayer(function(player)
    if check_perm(player) then
        player:set_nametag_attributes({color = {r = 255, g = 0,   b = 0}})
    end
end)

-- Define an initial formspec that will redirect to different formspecs depending on what the teacher wants to do
local mc_teacher_menu =
		"formspec_version[5]"..
		"size[7,12]"..
		"label[1.7,0.7;What do you want to do?]"..
		"button_exit[2,10.2;3,1.3;exit;Exit]"..
		"button[2,1.6;3,1.3;tasks;Manage Tasks]"..
		"button[2,3.3;3,1.3;lessons;Manage Lessons]"..
		"button[2,5;3,1.3;players;Manage Players]"..
		"button[2,6.7;3,1.3;maps;Manage Maps]"..
		"button[2,8.4;3,1.3;mail;Teacher Mail]"

local function show_teacher_menu(player)
	if check_perm(player) then
		local pname = player:get_player_name()
		minetest.show_formspec(pname, "mc_teacher:menu", mc_teacher_menu)
		return true
	end
	
end

-- Define the Manage Tasks formspec
local mc_teacher_tasks = 
		"formspec_version[5]"..
        "size[10,13]"..
        "field[0.375,0.75;9.25,0.8;task;Enter task below;]"..
        "textarea[0.375,2.5;9.25,7;instructions;Enter instructions below;]"..
        "field[0.375,10.5;9.25,0.8;timer;Enter timer for task in seconds (0 or blank = no timer);]"..
        "button_exit[3.5,11.5;3,0.8;ok;OK]"

local function show_tasks(player)
	if check_perm(player) then
		local pname = player:get_player_name()
		minetest.show_formspec(pname, "mc_teacher:tasks", mc_teacher_tasks)
		return true
	end
end

-- Define the Manage Players formspec
local mc_teacher_players = 
		"formspec_version[5]"..
		""

local function get_player_list_formspec(player, context)

	if context.selected_student and not minetest.get_player_by_name(context.selected_student) then
		context.selected_student = nil
	end

	local fs = {
		"container[0.3,0.3]",
		"tablecolumns[color;text",
	}

	context.select_toggle = context.select_toggle or "all"

	for i, col in pairs(infos) do
		fs[#fs + 1] = ";color;text,align=center"
		if i == 1 then
			fs[#fs + 1] = ",	=2"
		end
	end
	fs[#fs + 1] = "]"

	-- do
		-- fs[#fs + 1] = "tabheader[0,0;6.7,0.8;group;"
		-- fs[#fs + 1] = "All"
		-- local selected_group_idx = 1
		-- local i = 2
		-- for name, group in pairs(minetest_classroom.get_all_groups()) do
			-- fs[#fs + 1] = ","
			-- fs[#fs + 1] = minetest.formspec_escape(name)
			-- if context.groupname and name == context.groupname then
				-- selected_group_idx = i
			-- end
			-- i = i + 1
		-- end
		-- fs[#fs + 1] = ";"
		-- fs[#fs + 1] = tostring(selected_group_idx)
		-- fs[#fs + 1] = ";false;true]"
	-- end
	fs[#fs + 1] = "table[0,0;6.7,10.5;students;,Name"
	for _, col in pairs(infos) do
		fs[#fs + 1] = ",," .. col.title
	end

	local students = get_group(context)
	local selection_id = ""
	context.students = table.copy(students)
	for i, student in pairs(students) do
		fs[#fs + 1] = ",,"
		fs[#fs + 1] = minetest.formspec_escape(student)

		if student == context.selected_student then
			selection_id = tostring(i + 1)
		end

		for _, col in pairs(infos) do
			local color, value
			if col.type == "priv" then
				local has_priv = minetest.check_player_privs(student, col.privs)
				color = has_priv and "green" or "red"
				value = has_priv and "Yes" or "No"
			end

			fs[#fs + 1] = ","
			fs[#fs + 1] = color
			fs[#fs + 1] = ","
			fs[#fs + 1] = minetest.formspec_escape(value)
		end
	end

	fs[#fs + 1] = ";"
	fs[#fs + 1] = selection_id
	fs[#fs + 1] = "]"
	fs[#fs + 1] = "container_end[]"
	
	return table.concat(fs, "")
end

local function get_group(context)
	if context and context.groupname then
		return minetest_classroom.get_group_students(context.groupname)
	else
		return minetest_classroom.get_students()
	end
end

local function show_players(player)
	if check_perm(player) then
		-- Show dashboard
		local pname = player:get_player_name()
		local _contexts = {}
		local context = _contexts[pname] or {}
		_contexts[pname] = context
		minetest.show_formspec(player, "minetest_classroom:dashboard",
					DASHBOARD .. get_player_list_formspec(player, context))
		minetest.register_on_player_receive_fields(function(player, formname, fields)
			if formname ~= "minetest_classroom:dashboard" or not check_perm(pname) then
				return false
			end

			local context = _contexts[pname]
			if not context then
				return false
			end

			local ret = handle_results(player, context, fields)
			if ret then
				minetest_classroom.show_dashboard_formspec(player)
			end
			return ret
		end)
	end
end

-- Define the Manage Lessons formspec
local mc_teacher_lessons = 
		"formspec_version[5]"..
		""

local function show_lessons(player)
	if check_perm(player) then
		local pname = player:get_player_name()
		minetest.show_formspec(pname, "mc_teacher:lessons", mc_teacher_lessons)
		return true
	end
end

-- Define the Manage Maps formspec
local mc_teacher_maps = 
		"formspec_version[5]"..
		""

local function show_maps(player)
	if check_perm(player) then
		local pname = player:get_player_name()
		minetest.show_formspec(pname, "mc_teacher:maps", mc_teacher_maps)
		return true
	end
end

-- Define the Teacher Mail formspec
local mc_teacher_mail = 
		"formspec_version[5]"..
		""

local function show_mail(player)
	if check_perm(player) then
		local pname = player:get_player_name()
		minetest.show_formspec(pname, "mc_teacher:mail", mc_teacher_mail)
		return true
	end
end

-- TODO: add Change Server Rules to the menu

-- Processing the form from the menu
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if string.sub(formname, 1, 11) == "mc_teacher:" then
		local wait = os.clock()
		while os.clock() - wait < 0.05 do end --popups don't work without this
		local pname = player:get_player_name()
		
		-- Menu
		if formname == "mc_teacher:menu" then 
			if fields.tasks then
				show_tasks(player)
			elseif fields.lessons then
				show_lessons(player)
			elseif fields.maps then
				show_maps(player)
			elseif fields.players then
				show_players(player)
			elseif fields.mail then
				show_mail(player)
			end
		end
		
		if formname == "mc_teacher:tasks" then
			if fields.task and fields.instructions then
				-- Build the formspec
				task =
						"formspec_version[4]"..
						"size[10,12]"..
						"style_type[label;font_size=*1.5]"..
						"label[0.375,0.75;"..fields.task.."]"..
						"style[textarea;textcolor=black]"..
						"textarea[0.375,1.5;9.25,8;instructs;;"..fields.instructions.."]"..
						"style_type[label;font_size=*1]"..
						"label[0.375,9.75;Type /task in chat to see these instructions again.]"..
						"button_exit[3.5,10.5;3,0.8;ok;OK]"
				-- Send the task to everyone
				minetest.show_formspec(player:get_player_name(), "task:instructions", task)
				-- Kill any existing task timer
				task_timer.finish()
				if fields.timer ~= "" then
					if tonumber(fields.timer) > 0 then timer = minetest.after(1, timer_func, tonumber(fields.timer)) end
				end
			else
				minetest.chat_send_player(player:get_player_name(),"Error: Did not receive the task or instructions.")
			end
		end
		return true
	end
end)

-- The controller for accessing the teacher actions
minetest.register_tool("mc_teacher:controller" , {
	description = "Controller for teachers",
	inventory_image = "controller.png",
	--left-clicking the tool
	on_use = function (itemstack, user, pointed_thing)
        local pname = user:get_player_name()
		-- Check for teacher privileges
		if check_perm(user) then
			show_teacher_menu(user)
		end
	end,
	-- Destroy the controller on drop so that students cannot pick it up
	on_drop = function(itemstack, dropper, pos)
	end,
})

-- Give the controller to any player who joins with teacher privileges
minetest.register_on_joinplayer(function(player)
	if check_perm(player) then
		local inv = player:get_inventory()
		if inv:contains_item("main", ItemStack("mc_teacher:controller")) then
			return
		else
			player:get_inventory():add_item('main', 'mc_teacher:controller')
		end
	end
end)

-- If a player joins during an assigned task, ensure they see the current task instructions
minetest.register_on_joinplayer(function(player,map_legend_name)
    if task == nil then
        return true
    elseif task ~= nil then
        minetest.show_formspec(player:get_player_name(), "task:instructions", task)
    end
end)

-- Create chat command for anyone to see the current instructions
minetest.register_chatcommand("task", {
	params = "",
	description = "Get task instructions",
	func = function(name, param)
    	if task == nil then
            -- No task has been set
            return true, "There is currently no task set. Ask your instructor if you were expecting instructions for a task."
        elseif task ~= nil then
	    	minetest.show_formspec(name, "task:instructions", task)
        end
    end,
})

-- Set up a task timer
local hud = mhud.init()
local timer = nil
task_timer = {}
function timer_func(time_left)
	if time_left == 0 then
		task_timer.finish()
		return
    elseif time_left == 11 then
        minetest.sound_play("timer_bell", {
            gain = 1.0,
            pitch = 1.0,
        }, true)
    end
	for _, player in pairs(minetest.get_connected_players()) do
		local time_str = string.format("%dm %ds remaining for the current task", math.floor(time_left / 60), math.floor(time_left % 60))
		if not hud:exists(player, "task_timer") then
			hud:add(player, "task_timer", {
				hud_elem_type = "text",
				position = {x = 0.5, y = 0.95},
				offset = {x = 0, y = -42},
				text = time_str,
				color = 0xFFFFFF,
			})
		else
			hud:change(player, "task_timer", {
				text = time_str
			})
		end
	end
	timer = minetest.after(1, timer_func, time_left - 1)
end

function task_timer.finish()
	if timer == nil then return end
	timer:cancel()
	timer = nil
	hud:remove_all()
end