---Adapted from freeze.lua in rubenwardy's classroom mod
---@see https://gitlab.com/rubenwardy/classroom/-/blob/master/freeze.lua
---@license MIT: https://gitlab.com/rubenwardy/classroom/-/blob/1e7b11f824c03c882d74d5079d8275f3e297adea/LICENSE.txt

-- Frozen players
minetest.register_entity("mc_core:frozen_player", {
	-- This entity needs to be visible otherwise the frozen player won't be visible.
	initial_properties = {
		visual = "sprite",
		visual_size = { x = 0, y = 0 },
		textures = {"blank.png"},
		physical = false, -- Disable collision
		pointable = false, -- Disable selection box
		makes_footstep_sound = false,
	},

	on_step = function(self, dtime)
		local player = self.pname and minetest.get_player_by_name(self.pname)
		if not player or not mc_core.is_frozen(player) then
			self.object:remove()
			return
		end
	end,

	set_frozen_player = function(self, player)
		self.pname = player:get_player_name()
		player:set_attach(self.object, "", {x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 0 })
	end,
})

local function freeze_player(player)
    local parent = player:get_attach()
    if parent and parent:get_luaentity() and parent:get_luaentity().set_frozen_player then
        return
    end
    local obj = minetest.add_entity(player:get_pos(), "mc_core:frozen_player")
    obj:get_luaentity():set_frozen_player(player)
end

local function unfreeze_player(player)
    local pname = player:get_player_name()
    local objects = minetest.get_objects_inside_radius(player:get_pos(), 2)
    for _,obj in pairs(objects) do
        local entity = obj:get_luaentity()
        if entity and entity.set_frozen_player and entity.pname == pname then
            obj:remove()
        end
    end
end

---@public
---Freezes a player, preventing them from moving on their own
---@param player ObjectRef to freeze
function mc_core.freeze(player)
    local pmeta = player and player:is_player() and player:get_meta()
    if pmeta then
        freeze_player(player)
	    pmeta:set_string("mc_core:frozen", minetest.serialize(true))
    end
end

---@public
---Unfreezes a player, allowing them to move on their own
---@param player ObjectRef to unfreeze
function mc_core.unfreeze(player)
    local pmeta = player and player:is_player() and player:get_meta()
    if pmeta then
        unfreeze_player(player)
	    pmeta:set_string("mc_core:frozen", "")
    end
end

---@public
---Returns true if the player is frozen, false otherwise
---@param player ObjectRef to check
---@return boolean
function mc_core.is_frozen(player)
    local pmeta = player and player:is_player() and player:get_meta()
	return pmeta and minetest.deserialize(pmeta:get("mc_core:frozen")) or false
end

---@public
---Temporarily unfreezes player if they are frozen, runs func, then refreezes player if they should be frozen
---This should be used when applying forced movement to a player, since frozen players can not be teleported normally
---Optional arguments after func will be passed into func when it runs (similarly to how minetest.after passes arguments)
---@param player ObjectRef to treat as unfrozen
---@param func Function to run
---@return returns from func
function mc_core.temp_unfreeze_and_run(player, func, ...)
    local frozen = mc_core.is_frozen(player)
    if frozen then unfreeze_player(player) end
    -- store func's returns
    local res = {func(...)}
    if frozen then freeze_player(player) end
    -- return func's returns
    if table.unpack then return table.unpack(res) else return unpack(res) end
end