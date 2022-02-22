local hud = {
	huds = {}
}

local function get_playerobj(player)
	local type = type(player)

	if type == "string" then
		return minetest.get_player_by_name(player)
	elseif type == "userdata" and player:is_player() then
		return player
	end
end

local function get_playername(player)
	local type = type(player)

	if type == "string" then
		return player
	elseif type == "userdata" and player:is_player() then
		return player:get_player_name()
	end
end

local function convert_def(def, type)
	def = table.copy(def)
	if type == "text" then
		def.number = def.number or      def.color
		def.color = nil

		def.size   = def.size   or (def.text_scale and {x = def.text_scale})
		def.text_scale = nil
	elseif type == "image" then
		def.text  = def.text  or  def.texture
		def.texture = nil

		def.scale = def.scale or (def.image_scale and {x = def.image_scale, y = def.image_scale})
		def.image_scale = nil
	elseif type == "statbar" then
		if def.textures then
			def.text  = def.textures[1]
			def.text2 = def.textures[2]
			def.textures = nil
		else
			def.text = def.text or def.texture
			def.texture = nil
		end

		if def.lengths then
			def.number = def.lengths[1]
			def.item   = def.lengths[2]
			def.lengths = nil
		else
			def.number = def.number or def.length
			def.length = nil
		end

		def.size = def.size or def.force_image_size
		def.force_image_size = nil
	elseif type == "inventory" then
		def.text   = def.text   or def.listname
		def.listname = nil

		def.number = def.number or def.size
		def.size = nil

		def.item   = def.item   or def.selected
		def.selected = nil
	elseif type == "waypoint" then
		def.name   = def.name   or def.waypoint_text
		def.waypoint_text = nil

		def.text   = def.text   or def.suffix
		def.suffix = nil

		def.number = def.number or def.color
		def.color = nil
	elseif type == "image_waypoint" then
		def.text  = def.text  or      def.texture
		def.texture = nil

		def.scale = def.scale or (def.image_scale and {x = def.image_scale})
		def.image_scale = nil
	else
		minetest.log("error", "[MHUD] Hud type wasn't specified or is not supported")
	end

	if def.alignment then
		for axis, val in pairs(def.alignment) do
			if val == "left" or val == "up" then
				def.alignment[axis] = -1
			elseif val == "center" then
				def.alignment[axis] = 0
			elseif val == "right" or val == "down" then
				def.alignment[axis] = 1
			end
		end
	end

	if def.direction then
		for axis, val in pairs(def.alignment) do
			if val == "right" then
				def.direction[axis] = 0
			elseif val == "left" then
				def.direction[axis] = 1
			elseif val == "down" then
				def.direction[axis] = 2
			elseif val == "up" then
				def.direction[axis] = 3
			end
		end
	end

	return def
end

function hud.add(self, player, name, def)
	local pobj = get_playerobj(player)
	assert(pobj, "Attempt to add hud to offline player!")

	local pname = get_playername(player)

	if not def then
		def, name = name, false
	end

	if not self.huds[pname] then
		self.huds[pname] = {}
	end

	def = convert_def(def, def.hud_elem_type)

	local id = pobj:hud_add(def)

	if name then
		assert(not self.huds[pname][name], "Attempt to overwrite an existing hud!")

		self.huds[pname][name] = {id = id, def = def}
	else
		self.huds[pname][id] = {id = id, def = def}
	end

	return id
end

function hud.get(self, player, name)
	local pname = get_playername(player)

	if pname and self.huds[pname] then
		return self.huds[pname][name]
	end
end
hud.exists = hud.get

function hud.change(self, player, name, def)
	local pobj = get_playerobj(player)
	assert(pobj, "Attempt to change hud for offline player!")

	local pname = get_playername(player)
	assert(self.huds[pname] and self.huds[pname][name], "Attempt to change hud that doesn't exist!")

	def = convert_def(def, def.hud_elem_type or self.huds[pname][name].def.hud_elem_type)

	for stat, val in pairs(def) do
		pobj:hud_change(self.huds[pname][name].id, stat, val)
		self.huds[pname][name].def[stat] = val
	end
end

function hud.remove(self, player, name)
	local pobj = get_playerobj(player)
	assert(pobj, "Attempt to remove hud from offline player!")

	local pname = get_playername(player)

	if name then
		assert(self.huds[pname] and self.huds[pname][name], "Attempt to remove hud that doesn't exist!")

		pobj:hud_remove(self.huds[pname][name].id)

		self.huds[pname][name] = nil
	elseif self.huds[pname] then
		if player then
			for _, def in pairs(self.huds[pname]) do
				pobj:hud_remove(def.id)
			end
		end

		self.huds[pname] = nil
	end
end
hud.clear = hud.remove

function hud.remove_all(self)
	for player in pairs(self.huds) do
		self:clear(player)
	end
end
hud.clear_all = hud.remove_all

minetest.register_on_mods_loaded(function()
	minetest.register_on_leaveplayer(function(player)
		hud:remove(player)
	end)
end)

return hud
