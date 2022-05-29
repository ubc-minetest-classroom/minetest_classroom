mc_helpers = {}


---@public
---stringToColor
---Returns a random color based on input seed.
---Note that this function is not guaranteed to be the same on all systems.
---@param name string
---@return table containing alpha, red, green, and blue data
function mc_helpers.stringToColor(name)
    local seed = 0
    for c in name:gmatch(".") do
        seed = seed + string.byte(c)
    end

    math.randomseed(seed)

    local alpha = 255
    local red = math.random(255)
    local green = math.random(255)
    local blue = math.random(255)

    return { a = alpha, r = red, g = green, b = blue }
end

---@public
---Check whether or not a file exists.
---@param path string
---@return boolean whether or not the file at path exists.
function mc_helpers.fileExists(path)
    local f=io.open(path,"r")
    if f~=nil then io.close(f) return true else return false end
end