-- initialize minetest_classroom global object + mod table
minetest_classroom = {} -- TODO: check if this table is obsolete
mc_core = {
    path = minetest.get_modpath("mc_core"),
    meta = minetest.get_mod_storage(),
    hud = mhud.init(),
    markers = {},
    col = {
        log = "#FFC9FF",
        marker = "#DFA4F5",
        b = {
            default = "#1E1E1E",
            blocked = "#ACACAC",
            selected = "#055C22",
            red = "#590C0C",
            orange = "#6E5205",
            green = "#055C22",
        },
        t = {
            selected = "#59A63A",
            red = "#F5627D",
            orange = "#F5C987",
            green = "#71EBA8",
            blue = "#ACABFF",
        },
    },
    SERVER_USER = "Server",
}
-- for compatibility with older versions of mods
mc_helpers = mc_core

-- Required MT version
assert(minetest.features.formspec_version_element, "Minetest 5.1 or later is required")

-- Internationalisaton
minetest_classroom.S = minetest.get_translator("minetest_classroom")
minetest_classroom.FS = function(...)
    return minetest.formspec_escape(minetest_classroom.S(...))
end

-- Hooks needed to make api.lua testable
minetest_classroom.get_connected_players = minetest.get_connected_players
minetest_classroom.get_player_by_name = minetest.get_player_by_name
minetest_classroom.check_player_privs = minetest.check_player_privs

--[[ minetest_classroom.load_from(mc_core.meta)

function minetest_classroom.save()
    minetest_classroom.save_to(mc_core.meta)
end

minetest.register_on_shutdown(minetest_classroom.save) ]]

dofile(mc_core.path.."/Debugging.lua")
dofile(mc_core.path.."/lualzw.lua")
dofile(mc_core.path.."/PointTable.lua")
dofile(mc_core.path.."/Hooks.lua")
dofile(mc_core.path.."/gui.lua")
dofile(mc_core.path.."/coordinates.lua")
dofile(mc_core.path.."/freeze.lua")

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

---@private
---Helper function which escapes magic characters used as delimiters by mc_core.split
local function escape_delimiter(delimiter)
    local magic = {"^", "$", "(", ")", "%", ".", "[", "]", "*", "+", "-", "?"}
    local output = delimiter
    for _,char in pairs(magic) do
        output = string.gsub(output, "%"..char, "%%%0")
    end
    return output
end

---@public
---Returns a table where s has been split into multiple parts according to param delimiter
---@param string s string to split
---@param string delimiter the character(s) to split s by
---@return table with split entries
function mc_core.split(s, delimiter)
    local result = {};
    for match in (s .. delimiter):gmatch("(.-)" .. escape_delimiter(delimiter)) do
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

---@public
---Returns true if str is a number stored as a string, false otherwise
---@param str String to check
---@return boolean
function mc_core.isNumber(str)
    if (str == nil) then
        return false
    end
    return not (str == "" or str:match("%D"))
end

---@public
---Trims whitespace characters from the beginning and end of a string
---@param s String to trim
---@return string
function mc_core.trim(s)
    return s:match( "^%s*(.-)%s*$" )
end

---@public
---Returns true if string starts with start, false otherwise
---@param string String to check
---@param start Start of string to check for
---@return boolean
function mc_core.starts(string, start)
    return string.sub(string, 1, string.len(start)) == start
end

---@public
---Creates a shallow copy of table
---@param table Table to copy
---@return table
function mc_core.shallowCopy(table)
    local copy = {}
    for k, v in pairs(table) do
        copy[k] = v
    end
    return copy
end

---@public
---Creates a deep copy of table
---@param table Table to copy
---@return table
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

---@public
---Rounds a number to a given number of decimal places
---@param x Number to round
---@param n Number of decimal places to round to
---@return number
function mc_core.round(x, n)
    return tonumber(string.format("%." .. n .. "f", x))
end

---@public
---Returns a hexadecimal string as a number
---@param hex Hexadecimal string
---@return number
function mc_core.hex_string_to_num(hex)
    if string.sub(hex, 1, 1) == "#" then
        return tonumber(string.sub(hex, 2), 16)
    else
        return tonumber(hex, 16)
    end
end

---@public
---Removes KEY_ from the front of key names
---@param key Key to clean
---@return string
function mc_core.clean_key(key)
	local match = string.match(tostring(key), "K?E?Y?_?KEY_(.-)$")
    return (match == "LBUTTON" and "LEFT CLICK") or (match == "RBUTTON" and "RIGHT CLICK") or match or key
end

---@public
---Converts a time in seconds to a human-readable time
---@param t Time in seconds
---@returns string, table
function mc_core.expand_time(t)
    if t <= 0 then
        return "0 seconds", {s = 0, m = 0, h = 0, d = 0}
    end

    local t_temp = mc_core.round(t, 0)
    local sec = math.fmod(t_temp, 60)
    t_temp = (t_temp - sec)/60
    local min = math.fmod(t_temp, 60)
    t_temp = (t_temp - min)/60
    local hour = math.fmod(t_temp, 24)
    local day = (t_temp - hour)/24

    local t_string = {}
    if day > 0 then table.insert(t_string, day.." day"..(day == 1 and "" or "s")) end
    if hour > 0 then table.insert(t_string, hour.." hour"..(hour == 1 and "" or "s")) end
    if min > 0 then table.insert(t_string, min.." minute"..(min == 1 and "" or "s")) end
    if sec > 0 then table.insert(t_string, sec.." second"..(sec == 1 and "" or "s")) end
    
    return table.concat(t_string, ", "), {s = sec, m = min, h = hour, d = day}
end

---@public
---Calls on_priv_grant callbacks as if granter had granted priv to name
---@param name Name of player privileges were granted to
---@param granter Name of player who granted privileges
---@param priv Privilege granted
function mc_core.call_priv_grant_callbacks(name, granter, priv)
    for _,func in ipairs(minetest.registered_on_priv_grant) do
        local res = func(name, granter, priv)
        if not res then break end
    end
end

---@public
---Calls on_priv_rekove callbacks as if revoker had revoked priv from name
---@param name Name of player privileges were revoked from
---@param revoker Name of player who revoked privileges
---@param priv Privilege revoked
function mc_core.call_priv_revoke_callbacks(name, revoker, priv)
    for _,func in ipairs(minetest.registered_on_priv_revoke) do
        local res = func(name, revoker, priv)
        if not res then break end
    end
end
