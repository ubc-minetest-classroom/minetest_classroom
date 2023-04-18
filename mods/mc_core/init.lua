-- initialize minetest_classroom global object + mod table
minetest_classroom = {}
mc_core = {path = minetest.get_modpath("mc_core")}
-- for compatibility with older mods
mc_helpers = mc_core

dofile(mc_core.path.."/Debugging.lua")
dofile(mc_core.path.."/lualzw.lua")
dofile(mc_core.path.."/PointTable.lua")
dofile(mc_core.path.."/Hooks.lua")
dofile(mc_core.path.."/gui.lua")

---@public
---checkPrivs
---Checks for specific privileges and defaults to 'teacher'.
---Returns a boolean for all privileges and a list of 
---@param privs_table A table of privileges to check (defaults to {teacher = true})
---@param player Minetest player object
---@return boolean Whether the player has all privileges provided in privs_table.
---@return table All privileges provided in privs_table that are false.
function mc_core.checkPrivs(player, privs_table)
    privs_table = privs_table or { teacher = true }
    local name = player:get_player_name()
    return minetest.check_player_privs(name, privs_table)
end

---@public
---stringToColor
---Returns a random color based on input seed.
---Note that this function is not guaranteed to be the same on all systems.
---@param name string
---@return table containing alpha, red, green, and blue data
function mc_core.stringToColor(name)
    local seed = mc_core.stringToNumber(name)

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
function mc_core.stringToNumber(name)
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
function mc_core.fileExists(path)
    local f = io.open(path, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
    local f = io.open(path, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

---@public
---Returns true if any of the values in the given table is equal to the value provided
---@param table The table to check
---@param val The value to check for
---@return boolean whether the value exists in the table
function mc_core.tableHas(table, val)
    if not table or not val then
        return false
    end
    for k, v in pairs(table) do
        if v == val or k == val then
            return true
        end
    end
    return false
end

---@public
---Returns a table where s has been split into multiple parts according to param delimiter
---@param string s string to split
---@param string delimiter the character(s) to split s by
---@return table with split entries
function mc_core.split(s, delimiter)
    local result = {};
    for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match);
    end
    return result;
end

---@public
---First sorts the keys into an array, and then iterates on the array. At each step, it returns the key and value from the original table
---https://www.lua.org/pil/19.3.html
---@param t table
---@param f Optional order
---@return function iterator
function mc_core.pairsByKeys (t, f)
    local a = {}
    for n in pairs(t) do
        table.insert(a, n)
    end
    table.sort(a, f)
    local i = 0      -- iterator variable
    local iter = function()
        -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

function mc_core.isNumber(str)
    if (str == nil) then
        return false
    end
    return not (str == "" or str:match("%D"))
end
function mc_core.trim(s)
    return s:match( "^%s*(.-)%s*$" )
end

function mc_core.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end


function mc_core.shallowCopy(table)
    local copy = {}
    for k, v in pairs(table) do
        copy[k] = v
    end
    return copy
end

function mc_core.deepCopy(table)
    local copy = {}
    for k, v in pairs(table) do
        if type(v) == "table" then
            copy[k] = mc_core.deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

---@public
---Returns the name of the first inventory list that contains the given item, nil if the item was not found
---@param inv inventory to check
---@param itemstack Item to search for
---@return string
function mc_core.getInventoryItemLocation(inv, itemstack)
    for list,_ in pairs(inv:get_lists()) do
        if inv:contains_item(list, itemstack) then
            return list
        end
    end
    return nil
end

function mc_core.round(x, n)
    return tonumber(string.format("%." .. n .. "f", x))
end