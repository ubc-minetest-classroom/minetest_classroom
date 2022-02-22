local S = minetest_classroom.S
local FS = minetest_classroom.FS
local infos = {
	{
		title = S"Mute?",
		type = "priv",
		privs = { shout = true },
	},
	{
		title = S"Fly?",
		type = "priv",
		privs = { fly = true },
	},
	{
		title = S"Freeze?",
		type = "priv",
		privs = { fast = true },
	},
	{
		title = S"Dig?",
		type = "priv",
		privs = { interact = true },
	},
}

local function get_group(context)
	if context and context.groupname then
		return minetest_classroom.get_group_students(context.groupname)
	else
		return minetest_classroom.get_students()
	end
end

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
		"button[0.375,11.5;2,0.8;back;Back]"..
        "button_exit[2.575,11.5;2,0.8;submit;Submit]"

local function show_tasks(player)
	if check_perm(player) then
		local pname = player:get_player_name()
		minetest.show_formspec(pname, "mc_teacher:tasks", mc_teacher_tasks)
		return true
	end
end

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

-- Define the Manage Players formspec
local DASHBOARD_HEADER = "formspec_version[5]size[13,11]"

local function get_player_list_formspec(player, context)
	if not check_perm(player) then
		return "label[0,0;" .. FS"Access denied" .. "]"
	end
	
	if context.selected_student and not minetest.get_player_by_name(context.selected_student) then
		context.selected_student = nil
	end

	local function button(def)
		local x = assert(def.x)
		local y = assert(def.y)
		local w = assert(def.w)
		local h = assert(def.h)
		local name = assert(def.name)
		local text = assert(def.text)
		local state = def.state
		local tooltip = def.tooltip
		local bgcolor = "#222"

		-- Map different state values
		if state == true or state == nil then
			state = "active"
		elseif state == false then
			state = "disabled"
		elseif state == "selected" then
			state = "disabled"
			bgcolor = "#53ac56"
		end

		-- Generate FS code
		local fs
		if state == "active" then
			fs = {
				("button[%f,%f;%f,%f;%s;%s]"):format(x, y, w, h, name, text)
			}
		elseif state == "disabled" then
			name = "disabled_" .. name

			fs = {
				"container[", tostring(x), ",", tostring(y), "]",

				"box[0,0;", tostring(w), ",", tostring(h), ";", bgcolor, "]",

				"style[", name, ";border=false]",
				"button[0,0;", tostring(w), ",", tostring(h), ";", name, ";", text, "]",

				"container_end[]",
			}
		else
			error("Unknown state: " .. state)
		end

		if tooltip then
			fs[#fs + 1] = ("tooltip[%s;%s]"):format(name, tooltip)
		end

		return table.concat(fs, "")
	end

	local fs = {
		"container[0.3,0.3]",
		"tablecolumns[color;text",
	}

	context.select_toggle = context.select_toggle or "all"

	for i, col in pairs(infos) do
		fs[#fs + 1] = ";color;text,align=center"
		if i == 1 then
			fs[#fs + 1] = ",padding=2"
		end
	end
	fs[#fs + 1] = "]"

	do
		fs[#fs + 1] = "tabheader[0,0;6.7,0.8;group;"
		fs[#fs + 1] = FS"All"
		local selected_group_idx = 1
		local i = 2
		for name, group in pairs(minetest_classroom.get_all_groups()) do
			fs[#fs + 1] = ","
			fs[#fs + 1] = minetest.formspec_escape(name)
			if context.groupname and name == context.groupname then
				selected_group_idx = i
			end
			i = i + 1
		end
		fs[#fs + 1] = ";"
		fs[#fs + 1] = tostring(selected_group_idx)
		fs[#fs + 1] = ";false;true]"
	end
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
				value = has_priv and FS"Yes" or FS"No"
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
	
	-- New Group button
	do
		local btn = {
			x = 7.3, y = 0.3,
			w = 2.5, h = 0.8,
			name = "new_group",
			text = FS"New Group",
		}

		fs[#fs + 1] = button(btn)
	end

	-- Edit Group button
	do
		local btn = {
			x = 10, y = 0.3,
			w = 2.5, h = 0.8,
			name = "edit_group",
			text = FS"Edit Group",
			state = context.groupname ~= nil,
			tooltip = not context.groupname and FS"Please select a group first",
		}

		fs[#fs + 1] = button(btn)
	end
	
	-- Apply action to:
	fs[#fs + 1] = "label[7.3,1.6;"
	fs[#fs + 1] = FS"Apply action to:"
	fs[#fs + 1] = "]"
	
	-- Select All button
	do
		local btn = {
			x = 7.3, y = 2,
			w = 1, h = 0.8,
			name = "select_all",
			text = FS"All",
			state = context.select_toggle == "all" and "selected" or "active",
		}

		fs[#fs + 1] = button(btn)
	end

	-- Select Group button
	do
		local btn = {
			x = 8.5, y = 2,
			w = 1.4, h = 0.8,
			name = "select_group",
			text = FS"Group",
		}

		if not context.groupname then
			btn.state = "disabled"
			btn.tooltip = FS"Please select a group first"
		elseif context.select_toggle == "group" then
			btn.state = "selected"
		else
			btn.state = "active"
		end

		fs[#fs + 1] = button(btn)
	end

	-- Select Selected button
	do
		local btn = {
			x = 10, y = 2,
			w = 1.8, h = 0.8,
			name = "select_selected",
			text = FS"Selected",
		}

		if not context.selected_student then
			btn.state = "disabled"
			btn.tooltip = FS"Please select a student first"
		elseif context.select_toggle == "selected" then
			btn.state = "selected"
		else
			btn.state = "active"
		end

		fs[#fs + 1] = button(btn)
	end
	
	fs[#fs + 1] = "label[7.3,3.5;"
	fs[#fs + 1] = FS"Actions:"
	fs[#fs + 1] = "]"
	
	-- Action buttons
	fs[#fs + 1] = "button[7.3,4;2.5,0.8;look;Look]"
	fs[#fs + 1] = "button[10,4;2.5,0.8;bring;Bring]"
	fs[#fs + 1] = "button[7.3,5;2.5,0.8;freeze;Freeze]"
	fs[#fs + 1] = "button[10,5;2.5,0.8;unfreeze;Unfreeze]"
	fs[#fs + 1] = "button[7.3,6;2.5,0.8;dig;Dig]"
	fs[#fs + 1] = "button[10,6;2.5,0.8;nodig;No Dig]"
	fs[#fs + 1] = "button[7.3,7;2.5,0.8;mute;Mute]"
	fs[#fs + 1] = "button[10,7;2.5,0.8;unmute;Unmute]"
	fs[#fs + 1] = "button[7.3,8;2.5,0.8;fly;Fly]"
	fs[#fs + 1] = "button[10,8;2.5,0.8;nofly;No Fly]"
	fs[#fs + 1] = "button[7.3,9;2.5,0.8;kick;Kick]"
	fs[#fs + 1] = "button[10,9;2.5,0.8;ban;Ban]"
	fs[#fs + 1] = "button[7.3,10;2.5,0.8;mesage;Message]"
	fs[#fs + 1] = "button[10,10;2.5,0.8;managebans;Manage Bans]"
	
	return table.concat(fs, "")
end

local function handle_results(player, context, fields)
	if not check_perm(player) then
		return false
	end

	if fields.students then
		local evt = minetest.explode_table_event(fields.students)
		local i = (evt.row or 0) - 1
		if evt.type == "CHG" and i >= 1  and i <= #context.students then
			context.selected_student = context.students[i]
			return true
		end
	end

	if fields.group then
		if fields.group == "1" then
			context.groupname = nil
		else
			local i = 2
			for name, _ in pairs(minetest_classroom.get_all_groups()) do
				if i == tonumber(fields.group) then
					context.groupname = name
					break
				end
				i = i + 1
			end
		end
		return true
	end

	if fields.select_all then
		context.select_toggle = "all"
		return true
	elseif fields.select_group then
		context.select_toggle = "group"
		return true
	elseif fields.select_selected then
		context.select_toggle = "selected"
		return true
	end

	if fields.teleport and context.selected_student then
		local student = minetest.get_player_by_name(context.selected_student)
		if student then
			player:set_pos(student:get_pos())
			return false
		else
			context.selected_student = nil
			return true
		end
	end

	if fields.new_group then
		minetest_classroom.show_new_group(player)
		return false
	end

	if fields.edit_group and context.groupname then
		minetest_classroom.show_edit_group(player, context.groupname)
		return false
	end

	for _, action in pairs(minetest_classroom.get_actions()) do
		if fields["action_" .. action.name] then
			local selector
			if context.select_toggle == "all" then
				selector = "*"
			elseif context.select_toggle == "group" then
				selector = "group:" .. context.groupname
			elseif context.select_toggle == "selected" then
				selector = "user:" .. context.selected_student
			else
				error("Unknown selector")
			end

			minetest_classroom.run_action(action.name, player, selector)
			return true
		end
	end

end

local _contexts = {}
local function show_players(player)
	if check_perm(player) then
		local pname = player:get_player_name()
		local context = _contexts[pname] or {}
		_contexts[pname] = context
		minetest.show_formspec(pname, "mc_teacher:players", DASHBOARD_HEADER .. get_player_list_formspec(player, context))
		return true
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
local function get_reports_formspec(reports)
	local mc_teacher_mail = 
			"formspec_version[5]"..
			"size[15,10]"..
			"label[6.3,0.5;Reports Received]"..
			"textlist[0.3,1;14.4,8;;"
	-- Add the reports
	local reports_table = minetest_classroom.reports:to_table()["fields"]
	for k, v in pairs(reports_table) do
		mc_teacher_mail = mc_teacher_mail .. k .. " " .. v .. ","
	end
	local mc_teacher_mail = mc_teacher_mail..
			";1;false]"..
			"button[0.3,9.1;2,0.8;back;Back]"..
			"button[2.5,9.1;2.5,0.8;deleteall;Delete All]"
	
	return mc_teacher_mail
end

local function show_mail(player)
	if check_perm(player) then
		local pname = player:get_player_name()
		minetest.show_formspec(pname, "mc_teacher:mail", get_reports_formspec(minetest_classroom.reports))
		return true
	end
end

-- TODO: add Change Server Rules to the menu

-- Processing the form from the menu
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if string.sub(formname, 1, 10) ~= "mc_teacher" or not check_perm(player) then
		return false
	end
	
	local wait = os.clock()
	while os.clock() - wait < 0.05 do end --popups don't work without this
	
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
	
	if formname == "mc_teacher:players" then
		local context = _contexts[player:get_player_name()]
		if not context then
			return false
		end

		local ret = handle_results(player, context, fields)
		if ret then
			show_players(player)
		end
		return ret
	end
	
	if formname == "mc_teacher:tasks" then
		if fields.back then
			show_teacher_menu(player)
		elseif fields.task and fields.instructions then
			-- Build the formspec
			task =
					"formspec_version[5]"..
					"size[10,12]"..
					"style_type[label;font_size=*1.5]"..
					"label[0.375,0.75;"..fields.task.."]"..
					"style[textarea;textcolor=black]"..
					"textarea[0.375,1.5;9.25,8;instructs;;"..fields.instructions.."]"..
					"style_type[label;font_size=*1]"..
					"label[0.375,9.75;Type /task in chat to see these instructions again.]"..
					"button_exit[3.5,10.5;3,0.8;ok;OK]"
			-- Send the task to everyone
			for _, player in pairs(minetest.get_connected_players()) do
				minetest.show_formspec(player:get_player_name(), "task:instructions", task)
			end
			-- Kill any existing task timer
			task_timer.finish()
			if fields.timer ~= "" then
				if tonumber(fields.timer) > 0 then timer = minetest.after(1, timer_func, tonumber(fields.timer)) end
			end
		else
			minetest.chat_send_player(player:get_player_name(),minetest.colorize("#FF0000","Error: Did not receive complete task or instructions. The task was not sent to players."))
		end
	end
	
	if formname == "mc_teacher:mail" then
		if fields.deleteall then
			local reports_table = minetest_classroom.reports:to_table()["fields"]
			for k, v in pairs(reports_table) do
				minetest_classroom.reports:set_string(k, "")
			end
			show_mail(player)
		end
		
		if fields.back then
			show_teacher_menu(player)
		end
	end
end)

-- The controller for accessing the teacher actions
minetest.register_tool("mc_teacher:controller" , {
	description = "Controller for teachers",
	inventory_image = "controller.png",
	-- Left-click the tool activates the teacher menu
	on_use = function (itemstack, user, pointed_thing)
        local pname = user:get_player_name()
		-- Check for teacher privileges
		if check_perm(user) then
			show_teacher_menu(user)
		end
	end,
	-- Destroy the controller on_drop so that students cannot pick it up (i.e, disallow dropping without first revoking teacher)
	on_drop = function (itemstack, dropper, pos)
		minetest.set_node(pos, {name="air"})
	end,
})

-- Give the controller to any player who joins with teacher privileges or take away the controller if they are not teacher
minetest.register_on_joinplayer(function(player)
	local inv = player:get_inventory()
	if inv:contains_item("main", ItemStack("mc_teacher:controller")) then
		-- Player has the controller
		if check_perm(player) then
			-- The player should have the controller
			return
		else
			-- The player should not have the controller
			player:get_inventory():remove_item('main', 'mc_teacher:controller')
		end
	else
		-- Player does not have the controller
		if check_perm(player) then
			-- The player should have the controller
			player:get_inventory():add_item('main', 'mc_teacher:controller')
		else
			-- The player should not have the controller
			return
		end
	end
end)