function minetest_classroom.is_frozen(player)
	return minetest.is_yes(player:get_meta():get_string("mc_teacher:frozen"))
end

minetest.register_entity("mc_teacher:freeze", {
	-- This entity needs to be visible otherwise the frozen player won't be visible.
	initial_properties = {
		visual = "sprite",
		visual_size = { x = 0, y = 0 },
		textures = { "blank.png" },
		physical = false, -- Disable collision
		pointable = false, -- Disable selection box
		makes_footstep_sound = false,
	},

	on_step = function(self, dtime)
		local player = self.pname and minetest.get_player_by_name(self.pname)
		if not player or not minetest_classroom.is_frozen(player) then
			self.object:remove()
			return
		end
	end,

	set_frozen_player = function(self, player)
		self.pname = player:get_player_name()
		player:set_attach(self.object, "", {x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 0 })
	end,
})

function minetest_classroom.freeze(player)
	player:get_meta():set_string("mc_teacher:frozen", "true")

	local parent = player:get_attach()
	if parent and parent:get_luaentity() and
			parent:get_luaentity().set_frozen_player then
		-- Already attached
		return
	end

	local obj = minetest.add_entity(player:get_pos(), "mc_teacher:freeze")
	obj:get_luaentity():set_frozen_player(player)
end

function minetest_classroom.unfreeze(player)
	player:get_meta():set_string("mc_teacher:frozen", "")

	local pname = player:get_player_name()
	local objects = minetest.get_objects_inside_radius(player:get_pos(), 2)
	for i=1, #objects do
		local entity = objects[i]:get_luaentity()
		if entity and entity.set_frozen_player and entity.pname == pname then
			objects[i]:remove()
		end
	end
end

minetest.register_on_joinplayer(function(player)
	if minetest_classroom.is_frozen(player) then
		minetest_classroom.freeze(player)
	end
end)
