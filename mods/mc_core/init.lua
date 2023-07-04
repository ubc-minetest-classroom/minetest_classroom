-- initialize minetest_classroom global object + mod table
minetest_classroom = {}
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
        }
    },
    SERVER_USER = "Server",
}
-- for compatibility with older mods
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
---Sort comparison function for IPv4 addresses
---@param a First IP address string to compare
---@param b Second IP address string to compare
function mc_core.ipv4_compare(a, b)
    local ip_a = mc_core.split(a, ".")
    local ip_b = mc_core.split(b, ".")

    if tonumber(ip_a[1]) ~= tonumber(ip_b[1]) then
        return tonumber(ip_a[1]) < tonumber(ip_b[1])
    elseif tonumber(ip_a[2]) ~= tonumber(ip_b[2]) then
        return tonumber(ip_a[2]) < tonumber(ip_b[2])
    elseif tonumber(ip_a[3]) ~= tonumber(ip_b[3]) then
        return tonumber(ip_a[3]) < tonumber(ip_b[3])
    elseif tonumber(ip_a[4]) ~= tonumber(ip_b[4]) then
        return tonumber(ip_a[4]) < tonumber(ip_b[4])
    elseif not a or not b then
        return not b
    else
        return a < b
    end
end