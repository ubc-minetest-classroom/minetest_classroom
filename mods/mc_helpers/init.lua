dofile(minetest.get_modpath("mc_helpers") .. "/Debugging.lua")

mc_helpers = {}

---@public
---checkPrivs
---Checks for specific privileges and defaults to 'teacher'.
---Returns a boolean for all privileges and a list of 
---@param privs_table A table of privileges to check (defaults to {teacher = true})
---@param player Minetest player object
---@return boolean Whether the player has all privileges provided in privs_table.
---@return table All privileges provided in privs_table that are false.
function mc_helpers.checkPrivs(player,privs_table)
    privs_table = privs_table or {teacher = true}
    name = player:get_player_name()
    return minetest.check_player_privs(name, privs_table)
end

---@public
---stringToColor
---Returns a random color based on input seed.
---Note that this function is not guaranteed to be the same on all systems.
---@param name string
---@return table containing alpha, red, green, and blue data
function mc_helpers.stringToColor(name)
    local seed = mc_helpers.stringToNumber(name)

    math.randomseed(seed)

    local alpha = 255
    local red = math.random(255)
    local green = math.random(255)
    local blue = math.random(255)

    return { a = alpha, r = red, g = green, b = blue }
end

---@public
---stringToNumber
---Returns a number based input seed.
---Note that this function is not guaranteed to be the same on all systems.
---@param name string
---@return number
function mc_helpers.stringToNumber(name)
    local seed = 0
    for c in name:gmatch(".") do
        seed = seed + string.byte(c)
    end

    return seed
end

---@public
---Check whether or not a file exists.
---@param path string
---@return boolean whether or not the file at path exists.
function mc_helpers.fileExists(path)
    local f = io.open(path, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
    local f=io.open(path,"r")
    if f~=nil then io.close(f) return true else return false end
end

---@public
---Sorting comparison function for strings with numerals within them
---Returns true if the first detected numeral in a is less than the first detected numeral in b
---Fallbacks:
---If only one string contains a numeral, returns true if a contains the numeral, false if b contains the numeral
---If neither string has a numeral, returns the result of a < b (default sort)
---@param a The first string to be sorted
---@param b The second string to be sorted
---@return boolean
function mc_helpers.numSubstringCompare(a, b)
    local pattern = "^%D-(%d+)"
    local a_num = string.match(a, pattern)
    local b_num = string.match(b, pattern)

    if a_num and b_num then
        return tonumber(a_num) < tonumber(b_num)
    elseif not b_num and not a_num then
        return a < b
    else
        return a_num or false
    end
end

---@public
---Returns true if any of the values in the given table is equal to the value provided
---@param table The table to check
---@param val The value to check for
---@return boolean whether the value exists in the table
function mc_helpers.tableHas(table, val)
    if not table or not val then return false end
    for k,v in pairs(table) do
        if v == val or k == val then return true end
    end
    return false
end