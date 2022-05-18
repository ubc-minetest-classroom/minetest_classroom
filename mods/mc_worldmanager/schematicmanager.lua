schematicManager = {}

schematicManager.schematics = {}

function schematicManager.registerSchematicPath(key, path)
    schematicManager.schematics[key] = path
end

function schematicManager.getSchematicPath(key)
    local schematic = schematicManager.schematics[key]
    return schematic
end