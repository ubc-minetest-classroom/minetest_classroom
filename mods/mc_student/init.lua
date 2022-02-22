-- Global variables
minetest_classroom.reports = minetest.get_mod_storage()
minetest_classroom.mc_students = {teachers = {}}

-- Check for shout priv
local function check_perm(player)
	return minetest.check_player_privs(player:get_player_name(), { shout = true })
end

-- Define an initial formspec that will redirect to different formspecs depending on what the teacher wants to do
local mc_student_menu =
		"formspec_version[5]"..
		"size[7,12]"..
		"label[1.7,0.7;What do you want to do?]"..
		"button[2,1.6;3,1.3;report;Report]"..
		"button[2,3.3;3,1.3;coordinates;Store Coordinates]"..
		"button[2,5;3,1.3;notes;Make a Note]"..
		"button[2,6.7;3,1.3;marker;Place a Marker]"..
		"button_exit[2,10.2;3,1.3;exit;Exit]"

local function show_student_menu(player)
	if check_perm(player) then
		local pname = player:get_player_name()
		minetest.show_formspec(pname, "mc_student:menu", mc_student_menu)
		return true
	end
end

minetest.register_on_joinplayer(function(player)
	if minetest.check_player_privs(player, { teacher = true }) then
		minetest_classroom.mc_students.teachers[player:get_player_name()] = true
	end
end)

minetest.register_on_leaveplayer(function(player)
	minetest_classroom.mc_students.teachers[player:get_player_name()] = nil
end)

-- Define the Report formspec
local mc_student_report = 
		"formspec_version[5]"..
		"size[7,7]"..
		"label[1.8,0.8;What are you reporting?]"..
		"button[0.7,5.2;2,0.8;back;Back]"..
		"button_exit[2.9,5.2;2,0.8;submit;Submit]"..
		"textarea[0.7,1.5;5.6,3.1;report;; ]"

local function show_report(player)
	local pname = player:get_player_name()
	minetest.show_formspec(pname, "mc_student:report", mc_student_report)
	return true
end

-- Define the Coordinates formspec
local function show_coordinates(player)
	local pname = player:get_player_name()
	mc_student_coordinates = 
		"formspec_version[5]"..
		"size[15,10]"..
		"label[6.3,0.5;Coordinates Stored]"
		
	-- Get the stored coordinates for the player
	local pmeta = player:get_meta()
	pdata = minetest.deserialize(pmeta:get_string("coordinates"))
	if pdata == nil then
		-- No coordinates stored, so return an empty list element
		mc_student_coordinates = 
		mc_student_coordinates.. 
		"textlist[0.3,1;14.4,7.5;;No Coordinates Stored;1;false]"
	else
		mc_student_coordinates = mc_student_coordinates .. "textlist[0.3,1;14.4,7.5;;"
		-- Some coordinates were found, so iterate the list
		pxyz = pdata.coords
		pnotes = pdata.notes
		for i in pairs(pxyz) do
			mc_student_coordinates = mc_student_coordinates .. pxyz[i] .. " " .. pnotes[i] .. ","
		end
		mc_student_coordinates = mc_student_coordinates .. ";1;false]"
	end

	mc_student_coordinates = mc_student_coordinates..
		"button[0.3,9.1;2,0.8;back;Back]"..
		"button[2.5,9.1;2.5,0.8;deleteall;Delete All]"..
		"button[5.2,9.1;2,0.8;record;Record]"..
		"field[7.4,9.1;7.3,0.8;message;Note;Add a note to record at your current location]"
	minetest.show_formspec(pname, "mc_student:coordinates", mc_student_coordinates)
	return true
end

local function record_coordinates(player,message)
	if check_perm(player) then
		local pname = player:get_player_name()
		local pmeta = player:get_meta()
		local pos = player:get_pos()
		temp = minetest.deserialize(pmeta:get_string("coordinates"))
		if temp == nil then
			datanew = {
				coords = {"x="..math.floor(pos.x).." z="..math.floor(pos.y).." y="..math.floor(pos.z), }, 
				notes = { message, }, 
			}
		else
			table.insert(temp.coords, "x="..math.floor(pos.x).." z="..math.floor(pos.y).." y="..math.floor(pos.z))
			table.insert(temp.notes, message)
			datanew = {coords = temp.coords, notes = temp.notes, }
		end
		pmeta:set_string("coordinates", minetest.serialize(datanew))
		temp = nil
		minetest.chat_send_player(pname,pname..": Your position was recorded in your notebook.")
		-- Update the formspec
		show_coordinates(player)
	end
end

-- Processing the form from the menu
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if string.sub(formname, 1, 10) ~= "mc_student" then
		return false
	end
	
	local wait = os.clock()
	while os.clock() - wait < 0.05 do end --popups don't work without this

	-- Menu
	if formname == "mc_student:menu" then 
		if fields.report then
			show_report(player)
		elseif fields.coordinates then
			show_coordinates(player)
		elseif fields.notes then
			show_notes(player) -- TODO
		elseif fields.marker then
			place_marker(player) -- No formspec to redirect, simply execute the marker and then exit the student menu
			return true
		end
	end

	if formname == "mc_student:report" then
		if fields.back then
			show_student_menu(player)
		elseif fields.report ~= " " then
			local pname = player:get_player_name()
			
			-- Count the number of words, by counting for replaced spaces
			-- Number of spaces = Number of words - 1
			local _, count = string.gsub(fields.report, " ", "")
			if count == 0 then
				return false, "If you're reporting a player, you should" ..
					" also include a reason why."
			end

			local msg = pname .. " reported: " .. fields.report

			-- Append list of teachers in-game
			local teachers = ""
			for teacher in pairs(minetest_classroom.mc_students.teachers) do
				teachers = teachers .. teacher .. ", "
			end

			if teachers ~= "" then
				msg = '[REPORT] ' .. msg .. " (teachers online: " .. teachers:sub(1, -3) .. ")"
			end

			-- Send report to any teacher currently connected
			for teacher in pairs(minetest_classroom.mc_students.teachers) do
				minetest.chat_send_player(teacher, minetest.colorize("#FF00FF", msg))
			end
			
			-- Archive the report in mod storage
			local key = pname.." "..tostring(os.date("%d-%m-%Y %H:%M:%S"))
			minetest_classroom.reports:set_string(key, minetest.write_json(fields.report))
		else
			minetest.chat_send_player(player:get_player_name(),minetest.colorize("#FF0000","Error: Please add a message to your report."))
		end
	end
	
	if formname == "mc_student:coordinates" then
		if fields.back then
			show_student_menu(player)
		elseif fields.record then
			record_coordinates(player,fields.message)
		elseif fields.deleteall then
			local pmeta = player:get_meta()
			pmeta:set_string("coordinates", nil)
			show_coordinates(player)
		end
	end
end)

-- The student notebook for accessing the student actions
minetest.register_tool("mc_student:notebook" , {
	description = "Notebook for students",
	inventory_image = "notebook.png",
	-- Left-click the tool activates the teacher menu
	on_use = function (itemstack, user, pointed_thing)
        local pname = user:get_player_name()
		-- Check for shout privileges
		if check_perm(user) then
			show_student_menu(user)
		end
	end,
	-- Destroy the controller on_drop to keep things tidy
	on_drop = function (itemstack, dropper, pos)
		minetest.set_node(pos, {name="air"})
	end,
})

-- Give the notebook to any player who joins with shout privileges or take away the controller if they do not have shout
minetest.register_on_joinplayer(function(player)
	local inv = player:get_inventory()
	if inv:contains_item("main", ItemStack("mc_student:notebook")) then
		-- Player has the notebook
		if check_perm(player) then
			-- The player should have the notebook
			return
		else
			-- The player should not have the notebook
			player:get_inventory():remove_item('main', 'mc_student:notebook')
		end
	else
		-- Player does not have the notebook
		if check_perm(player) then
			-- The player should have the notebook
			player:get_inventory():add_item('main', 'mc_student:notebook')
		else
			-- The player should not have the notebook
			return
		end
	end
end)

-- Functions and variables for placing markers
hud = mhud.init()
markers = {}
local MARKER_LIFETIME = 30
local MARKER_RANGE = 150

function add_marker(pname, message, pos, owner)
	if not hud:get(pname, "marker_" .. owner) then
		hud:add(pname, "marker_" .. owner, {
			hud_elem_type = "waypoint",
			world_pos = pos,
			precision = 1,
			color = 0xFF0000, -- red
			text = message
		})
	else
		hud:change(pname, "marker_" .. owner, {
			world_pos = pos,
			text = message
		})
	end
end
	
function markers.add(pname, msg, pos)

	if markers[pname] then
		markers[pname].timer:cancel()
	end

	markers[pname] = {
		msg = msg, pos = pos,
		timer = minetest.after(MARKER_LIFETIME, markers.remove, pname),
	}

	for _, player in pairs(minetest.get_connected_players()) do
		add_marker(player, msg, pos, pname)
	end
end

function markers.remove(pname)
	if markers[pname] then
		markers[pname].timer:cancel()

		for _, player in pairs(minetest.get_connected_players()) do
			hud:remove(player, "marker_" .. pname)
		end

		markers[pname] = nil
	end
end

minetest.register_chatcommand("m", {
	description = "Place a marker in your look direction",
	privs = {interact = true, shout = true},
	func = function(name, param)

		local player = minetest.get_player_by_name(name)
		local pos1 = vector.offset(player:get_pos(), 0, player:get_properties().eye_height, 0)

		if param == "" then
			param = "Look here!"
		end

		local ray = minetest.raycast(
			pos1, vector.add(pos1, vector.multiply(player:get_look_dir(), MARKER_RANGE),
			true, false
		))
		local pointed = ray:next()

		if pointed and pointed.type == "object" and pointed.ref == player then
			pointed = ray:next()
		end

		if not pointed then
			return false, "Can't find anything to mark, too far away!"
		end

		local message = string.format("m [%s]: %s", name, param)
		local pos

		if pointed.type == "object" then
			local concat
			local obj = pointed.ref
			local entity = obj:get_luaentity()

			-- If object is a player, append player name to display text
			-- Else if obj is item entity, append item description and count to str.
			if obj:is_player() then
				concat = obj:get_player_name()
			elseif entity then
				if entity.name == "__builtin:item" then
					local stack = ItemStack(entity.itemstring)
					local itemdef = minetest.registered_items[stack:get_name()]

					-- Fallback to itemstring if description doesn't exist
					concat = itemdef.description or entity.itemstring
					concat = concat .. " " .. stack:get_count()
				end
			end

			pos = obj:get_pos()
			if concat then
				message = message .. " <" .. concat .. ">"
			end
		else
			pos = pointed.under
		end

		markers.add(name, message, pos)

		return true, "Marker is placed!"
	end
})

function place_marker(player)
	local pname = player:get_player_name()
	local pos1 = vector.offset(player:get_pos(), 0, player:get_properties().eye_height, 0)

	local ray = minetest.raycast(
		pos1, vector.add(pos1, vector.multiply(player:get_look_dir(), MARKER_RANGE),
		true, false
	))
	local pointed = ray:next()

	if pointed and pointed.type == "object" and pointed.ref == player then
		pointed = ray:next()
	end

	if not pointed then
		return false, "Can't find anything to mark, too far away!"
	end

	local message = string.format("m [%s]: %s", pname, "")
	local pos

	if pointed.type == "object" then
		local concat
		local obj = pointed.ref
		local entity = obj:get_luaentity()

		-- If object is a player, append player name to display text
		-- Else if obj is item entity, append item description and count to str.
		if obj:is_player() then
			concat = obj:get_player_name()
		elseif entity then
			if entity.name == "__builtin:item" then
				local stack = ItemStack(entity.itemstring)
				local itemdef = minetest.registered_items[stack:get_name()]

				-- Fallback to itemstring if description doesn't exist
				concat = itemdef.description or entity.itemstring
				concat = concat .. " " .. stack:get_count()
			end
		end

		pos = obj:get_pos()
		if concat then
			message = message .. " <" .. concat .. ">"
		end
	else
		pos = pointed.under
	end

	markers.add(pname, message, pos)

	return true, "Marker is placed!"
end