Debug = {}

function Debug.log(message)
    minetest.debug(message)
end

function Debug.logCoords(coords, name)
    name = name or "unknown coords"

    Debug.log(name .. ": " .. "X: " .. tostring(coords.x) .. " Y: " .. tostring(coords.y) .. " Z: " .. tostring(coords.z))
end