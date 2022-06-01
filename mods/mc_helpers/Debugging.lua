Debug = {}

function Debug.log(message)
    minetest.debug(message)
end

function Debug.logCoords(coords, name)
    name = name or "unknown coords"
    Debug.log(name .. ": " .. "X: " .. coords.x .. " Y: " .. coords.y .. " Z: " .. coords.z)
end