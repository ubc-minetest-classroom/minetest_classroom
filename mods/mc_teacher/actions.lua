local S = minetest_classroom.S

minetest_classroom.register_action("mc_teacher:bring", {
	title = S"Bring",
	description = S"Teleport players to your location",
	online_required = true,
	func = function(runner, players)
		local pos = runner:get_pos()

		for _, name in pairs(players) do
			local player = minetest.get_player_by_name(name)
			player:set_pos(pos)
		end
	end,
})

local function look_at(player, target)
	local pos = player:get_pos()
	local delta = vector.subtract(target, pos)
	player:set_look_horizontal(math.atan2(delta.z, delta.x) - math.pi / 2)
end

minetest_classroom.register_action("mc_teacher:look", {
	title = S"Look",
	description = S"Make players look at you",
	online_required = true,
	func = function(runner, players)
		local pos = runner:get_pos()

		for _, name in pairs(players) do
			local player = minetest.get_player_by_name(name)
			look_at(player, pos)
		end
	end,
})

minetest_classroom.register_action("mc_teacher:mute", {
	title = S"Mute",
	description = S"Revoke shout from players",
	online_required = false,
	func = function(runner, players)
		for _, name in pairs(players) do
			local privs = minetest.get_player_privs(name)
			privs.shout = nil
			minetest.set_player_privs(name, privs)
		end
	end,
})

minetest_classroom.register_action("mc_teacher:unmute", {
	title = S"Unmute",
	description = S"Grant shout to players",
	online_required = false,
	func = function(runner, players)
		for _, name in pairs(players) do
			local privs = minetest.get_player_privs(name)
			privs.shout = true
			minetest.set_player_privs(name, privs)
		end
	end,
})

minetest_classroom.register_action("mc_teacher:dig", {
	title = S"Dig",
	description = S"Grant interact to players",
	online_required = false,
	func = function(runner, players)
		for _, name in pairs(players) do
			local privs = minetest.get_player_privs(name)
			privs.interact = true
			minetest.set_player_privs(name, privs)
		end
	end,
})

minetest_classroom.register_action("mc_teacher:nodig", {
	title = S"No Dig",
	description = S"Revoke interact from players",
	online_required = false,
	func = function(runner, players)
		for _, name in pairs(players) do
			local privs = minetest.get_player_privs(name)
			privs.interact = nil
			minetest.set_player_privs(name, privs)
		end
	end,
})

minetest_classroom.register_action("mc_teacher:fly", {
	title = S"Fly",
	description = S"Grant fly to players",
	online_required = false,
	func = function(runner, players)
		for _, name in pairs(players) do
			local privs = minetest.get_player_privs(name)
			privs.fly = true
			minetest.set_player_privs(name, privs)
		end
	end,
})

minetest_classroom.register_action("mc_teacher:nofly", {
	title = S"No Fly",
	description = S"Revoke fly from players",
	online_required = false,
	func = function(runner, players)
		for _, name in pairs(players) do
			local privs = minetest.get_player_privs(name)
			privs.fly = nil
			minetest.set_player_privs(name, privs)
		end
	end,
})

minetest_classroom.register_action("mc_teacher:kick", {
	title = S"Kick",
	description = S"Remove from the server",
	online_required = false,
	params = {
		message = "Kick Message",
	},
	func = function(runner, players, message)
		message = message or S("Kicked by @1", runner:get_player_name())
		for _, name in pairs(players) do
			minetest.kick_player(name, message)
		end
	end,
})

minetest_classroom.register_action("mc_teacher:ban", {
	title = S"Ban",
	description = S"Permanently from the server",
	online_required = false,
	params = {
		message = "Ban Message",
	},
	func = function(runner, players, message)
		message = message or S("Banned by @1", runner:get_player_name())
		for _, name in pairs(players) do
			minetest.ban_player(name, message)
		end
	end,
})

local function find_center_position(start, direction)
	local endp = vector.add(start, vector.multiply(direction, 10))
	local rc = minetest.raycast(start, endp, false, true)
	local first = rc:next()
	if first then
		return vector.subtract(first.under, direction)
	else
		return endp
	end
end

local function place_player_if_ok(player, pos, teacher_pos)
	-- Move down to ground
	local rc = minetest.raycast(pos, vector.add(pos, { x = 0, y = -20, z = 0 }), false, true)
	local first = rc:next()
	if first then
		pos = vector.add(first.under, { x = 0, y = 1, z = 0 })
	end

	-- TODO: handle players already being in that location

	-- Check teacher is visible
	if not minetest.line_of_sight(pos, teacher_pos) then
		return false
	end

	player:set_pos(pos)
	look_at(player, teacher_pos)
	return true
end

local function place_all_players(players, teacher_pos, direction)
	local center = find_center_position(teacher_pos, direction)
	local direction_perp = vector.normalize(vector.new(direction.z, direction.y, -direction.x))

	for unmapped_column=0, 100 do
		for row=0, 1 do
			local next_player = players[#players]
			assert(next_player)

			local column = math.floor(unmapped_column / 2) * ((unmapped_column % 2) * 2 - 1) + unmapped_column % 2

			local delta = vector.add(vector.multiply(direction, row), vector.multiply(direction_perp, column))
			local pos = vector.add(center, delta)
			if place_player_if_ok(next_player, pos, teacher_pos) then
				table.remove(players, #players)
			end

			if #players == 0 then
				return
			end
		end
	end
end

minetest_classroom.register_action("mc_teacher:audience", {
	title = S"Audience",
	description = S"Move to the crosshair location, spread out and facing you",
	online_required = true,
	func = function(runner, players, message)
		local playerrefs = {}
		for i=1, #players do
			playerrefs[i] = minetest.get_player_by_name(players[i])
		end

		local eye_height = runner:get_properties().eye_height
		local teacher_pos = vector.add(runner:get_pos(), { x = 0, y = eye_height, z = 0})
		place_all_players(playerrefs, teacher_pos, runner:get_look_dir())
	end,
})

minetest_classroom.register_action("mc_teacher:freeze", {
	title = S"Freeze",
	description = S"Prevent movement",
	online_required = true,
	func = function(runner, players, message)
		for i=1, #players do
			local player = minetest.get_player_by_name(players[i])
			minetest_classroom.freeze(player)
		end
	end,
})

minetest_classroom.register_action("mc_teacher:thaw", {
	title = S"Unfreeze",
	description = S"Allow movement",
	online_required = true,
	func = function(runner, players, message)
		for i=1, #players do
			local player = minetest.get_player_by_name(players[i])
			minetest_classroom.unfreeze(player)
		end
	end,
})

