ptable = {}

function ptable.store(table, coords, value)
    local tx = table[coords.x]
    if not tx then
        tx = {}
        table[coords.x] = tx
    end
    local ty = tx[coords.y]
    if not ty then
        ty = {}
        tx[coords.y] = ty
    end
    ty[coords.z] = value
end
function ptable.get(table, coords)
    return table[coords.x] and table[coords.x][coords.y] and table[coords.x][coords.y][coords.z]
end
function ptable.delete(table, coords)
    if ptable.get(coords.x, coords.y, coords.z) == nil then
        return
    end
    local tx = table[coords.x]
    tx[coords.y][coords.z] = nil
    if not next(tx[coords.y]) then
        tx[coords.y] = nil
        if not next(tx) then
            table[coords.x] = nil
        end
    end
end