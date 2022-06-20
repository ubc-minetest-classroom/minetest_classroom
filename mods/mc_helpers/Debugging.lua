Debug = {}

function Debug.log(message)
    minetest.debug(message)
end

function Debug.logTable(title, table)

    Debug.log("============")
    Debug.log(tostring(title))
    Debug.log("Key :: Value")
    Debug.log("============")
    for k, v in pairs(table) do
        Debug.log(tostring(k) .. " :: " .. tostring(v))
    end
end

function Debug.logCoords(coords, name)
    name = name or "unknown coords"
    Debug.log(name .. ": " .. "X: " .. coords.x .. " Y: " .. coords.y .. " Z: " .. coords.z)
end