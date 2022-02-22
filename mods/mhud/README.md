# [M]inetest [HUD]
A wrapper for more easily managing Minetest HUDs

# API
You can add this mod as a dependency in your mod.conf, or you can copy the `mhud.lua` file into your mod and use it that way

Example usage:
```lua
local hud = mhud.init()
hud:add(player, "test_hud", {
  hud_elem_type = "text",
  position = {x = 1, y = 0},
  offset = {x = -6, y = 6},
  alignment = {x = "left", y = "down"},
  text = "Hello there",
  color = 0x00FF00,
})
```

## Mod-Specific Functions

* `mhud.init()`
  Returns a hud wrapper you can use in your mod

## Hud Wrapper Functions

Hud names are per-player, so you can use the same hud name for two different players

* `wrapper:add(<player>, [hud name], <def>)` -> `hud id`
  * *player*: ObjectRef or PlayerName
  * *hud name*: Name of hud. Useful if you plan on changing the hud later
  * *def*: [Hud Definition]

* `wrapper:[get | exists](<player>, <name>)` -> `{id = hud id, def = [Hud Definition]}` or `nil` if nonexistent
  * *player*: ObjectRef or PlayerName
  * *name*: Name (or id!) of the hud you want to get

* `wrapper:change(<player>, <name>, <def>)`
  * *player*: ObjectRef or PlayerName
  * *name*: Name (or id!) of the hud you want to change
  * *def*: [Hud Definition]

* `wrapper:[remove|clear](<player>, [name])`
  * *player*: ObjectRef or PlayerName
  * *name*: Name (or id!) of the hud you want to remove. Leave out to remove all player's huds

* `wrapper:[remove_all | clear_all]()`
  * Removes all huds registered with `wrapper`

## [Hud Definition]
MHud definitions are pretty much exactly the same as Minetest's. With some added aliases:

### **Element Aliases**
### text
  * `color` -> `number`
  * `text_scale` -> `def.size {x = def.text_scale}`
### image
  * `texture` -> `text`
  * `image_scale` -> `def.size {x = def.image_scale, y = def.image_scale}`
### statbar
  * `texture` -> `text`
  * `textures {t1, t2}` -> `text`, `text2`
  * `length` -> `number`
  * `lengths {l1, l2}` -> `number`, `item`
  * `force_image_size` -> `size`
### inventory
  * `listname` -> `text`
  * `size` -> `number`
  * `selected` -> `item`
### waypoint
  * `waypoint_text` -> `name`
  * `suffix` -> `text`
  * `color` -> `number`
### image_waypoint
  * `texture` -> `text`
  * `image_scale` -> `def.size {x = def.image_scale}`

### **Misc**

* for `alignment` and `direction` you can use up/left/right/down/center instead of the numbers used by the Minetest API
