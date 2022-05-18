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

    local schematic_size_x = tonumber(settings:get("schematic_size_x")) or 80
    local schematic_size_y = tonumber(settings:get("schematic_size_y")) or 80
    local schematic_size_z = tonumber(settings:get("schematic_size_z")) or 80

    local _spawnPoint = { x = spawn_pos_x, y = spawn_pos_y, z = spawn_pos_z }
    local _schematicSize = { x = schematic_size_x, y = schematic_size_y, z = schematic_size_z }

    local config = { Author = _author, Name = _name, spawnPoint = _spawnPoint, size = _schematicSize }
    return schematic, config
end