minetest.register_entity("openstreetmap:highlight", {
    visual = "cube",
    visual_size = {x=1.01, y=1.01}, 
    collisionbox = {0,0,0, 0,0,0}, -- No collision
    physical = false,
    textures = {"highlight.png", "highlight.png", "highlight.png", "highlight.png", "highlight.png", "highlight.png"},
    on_activate = function(self, staticdata, dtime_s)
        if staticdata == "remove" then
            self.object:remove()
        end
    end,
})
