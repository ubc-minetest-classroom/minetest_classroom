schematicManager = {}

schematicManager.schematics = {}

function schematicManager.registerSchematicPath(key, path)
    schematicManager.schematics[key] = path

end

function schematicManager.getSchematic(key)
    local rootPath = schematicManager.schematics[key]

    local schematic = rootPath .. ".mts"

    local settings = Settings(rootPath .. ".conf")

    local _author = tostring(settings:get("author")) or "unknown"
    local _name = tostring(settings:get("name")) or "unknown"

    local spawn_pos_x = tonumber(settings:get("spawn_pos_x")) or 0
    local spawn_pos_y = tonumber(settings:get("spawn_pos_y")) or 0
    local spawn_pos_z = tonumber(settings:get("spawn_pos_z")) or 0

    local _spawnPoint = { x = spawn_pos_x, y = spawn_pos_y, z = spawn_pos_z }

    local config = { Author = _author, Name = _name, spawnPoint = _spawnPoint }
    return schematic, config
end