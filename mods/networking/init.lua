networking = {}
networking.storage = minetest.get_mod_storage()
if not minetest.deserialize(networking.storage:get_string("ipv4_whitelist")) then
    -- Set a boolean for enabling the whitelist. Whitelist is disabled by default on startup to avoid players from automatically being kicked if not hosted locally.
    networking.storage:set_string("enabled", minetest.serialize(false))
    networking.storage:set_string("kick_message", "You are not authorized to join this server.")
    -- Initialize and set default whitelist ipv4 address 127.0.0.1 for singleplayer
    local ipv4_whitelist = {["127.0.0.1"] = true}
    networking.storage:set_string("ipv4_whitelist", minetest.serialize(ipv4_whitelist))
    networking.storage:set_int("ipv4_length", 1)
end
if not networking.storage:get("ipv4_length") then
    -- Calculate + save length of whitelist
    local whitelist = minetest.deserialize(networking.storage:get_string("ipv4_whitelist"))
    local count = 0
    for _ in pairs(whitelist) do
        count = count + 1
    end
    networking.storage:set_int("ipv4_length", count)
end

minetest.register_on_joinplayer(function(player) 
    local pname = player:get_player_name()
    local ipv4 = minetest.get_player_ip(pname)
    local ipv4_whitelist = minetest.deserialize(networking.storage:get_string("ipv4_whitelist"))
    local state = minetest.deserialize(networking.storage:get_string("enabled"))
    if not ipv4_whitelist[ipv4] and state then
        minetest.kick_player(pname, networking.storage:get_string("kick_message"))
    end
end)

local function escape_sep(sep)
    local magic = {"^", "$", "(", ")", "%", ".", "[", "]", "*", "+", "-", "?"}
    local output = sep
    for _,char in pairs(magic) do
        output = string.gsub(output, "%"..char, "%%%0")
    end
    return output
end

function networking.parse(s, sep)
    local values = {}
    local sep = sep or " "
    for match in string.gmatch(s..sep, "(.-)"..escape_sep(sep)) do
        table.insert(values, match);
    end
    return values
end

---Returns true if IP address a comes before IP address b
---This function can be used as a comparison function for table.sort
---If either input is not an IP address, sorts valid IP addresses before other inputs
function networking.ipv4_compare(a, b)
    if not a or not b then
        return not b
    end

    local ip_a = networking.parse(a, ".")
    local ip_b = networking.parse(b, ".")
    if #ip_a ~= 4 or #ip_b ~= 4 then
        return #ip_b ~= 4
    elseif tonumber(ip_a[1]) and tonumber(ip_b[1]) then
        if tonumber(ip_a[1]) ~= tonumber(ip_b[1]) then
            return tonumber(ip_a[1]) < tonumber(ip_b[1])
        elseif tonumber(ip_a[2]) and tonumber(ip_b[2]) then
            if tonumber(ip_a[2]) ~= tonumber(ip_b[2]) then
                return tonumber(ip_a[2]) < tonumber(ip_b[2])
            elseif tonumber(ip_a[3]) and tonumber(ip_b[3]) then
                if tonumber(ip_a[3]) ~= tonumber(ip_b[3]) then
                    return tonumber(ip_a[3]) < tonumber(ip_b[3])
                elseif tonumber(ip_a[4]) and tonumber(ip_b[4]) then
                    return tonumber(ip_a[4]) < tonumber(ip_b[4])
                end
            end
        end
    end
    return a < b
end

---Returns true if IP address a is identical to IP address b
---If either input is not an IP address, returns true if a and b are equal
function networking.ipv4_match(a, b)
    if not a or not b then
        return a == b
    end

    local ip_a = networking.parse(a, ".")
    local ip_b = networking.parse(b, ".")
    if #ip_a == 4 and #ip_b == 4 then
        return tonumber(ip_a[1]) == tonumber(ip_b[1]) and tonumber(ip_a[2]) == tonumber(ip_b[2]) and tonumber(ip_a[3]) == tonumber(ip_b[3]) and tonumber(ip_a[4]) == tonumber(ip_b[4]) 
    end
    
    return a == b
end

function networking.modify_ipv4(player, startRange, endRange, add)
    local pname = player:get_player_name()
    if not mc_core.checkPrivs(player, {server = true}) then
        minetest.chat_send_player(pname, "[Networking] ERROR: You do not have the server privilege, which is required to run this function.")
        return false
    end

    -- Validate start octets
    if not startRange or startRange == "" then
        minetest.chat_send_player(pname, "[Networking] ERROR: Input was empty. Add an IPv4 address in the format \'0.0.0.0\' and try again.")
        return false
    end
    local startOctets = networking.parse(startRange, ".")
    if #startOctets ~= 4 or not tonumber(startOctets[1]) or not tonumber(startOctets[2]) or not tonumber(startOctets[3]) or not tonumber(startOctets[4]) then
        minetest.chat_send_player(pname, "[Networking] ERROR: Expected start range to be four octets of format \'0.0.0.0\'. Check input \'"..startRange.."\' and try again.")
        return false
    end
    for i, octet in ipairs(startOctets) do
        if #octet > 3 then
            minetest.chat_send_player(pname, "[Networking] ERROR: Octet "..i.." of the start address had more characters than expected. Check that the start address is no larger than the format \'000.000.000.000\' and try again.")
            return false
        elseif #octet < 1 then
            minetest.chat_send_player(pname, "[Networking] ERROR: Octet "..i.." of the start address had fewer characters than expected. Check that the start address is no smaller than the format \'0.0.0.0\' and try again.")
            return false
        end
    end

    -- Check if endRange was specified, otherwise treat as a single entry
    if endRange then
        -- Validate end octets, if specified
        local endOctets = networking.parse(endRange, ".")
        if #endOctets ~= 4 or not tonumber(endOctets[1]) or not tonumber(endOctets[2]) or not tonumber(endOctets[3]) or not tonumber(endOctets[4]) then
            minetest.chat_send_player(pname, "[Networking] ERROR: Expected end range to be four octets of format \'0.0.0.0\'. Check input \'"..endRange.."\' and try again.")
            return false
        end
        for i, octet in ipairs(endOctets) do
            if #octet > 3 then
                minetest.chat_send_player(pname, "[Networking] ERROR: Octet "..i.." of the end address had more characters than expected. Check that the end address is no larger than the format \'000.000.000.000\' and try again.")
                return false
            elseif #octet < 1 then
                minetest.chat_send_player(pname, "[Networking] ERROR: Octet "..i.." of the end address had fewer characters than expected. Check that the end address is no smaller than the format \'0.0.0.0\' and try again.")
                return false
            end
        end

        if not networking.ipv4_compare(startRange, endRange) and not networking.ipv4_match(startRange, endRange) then
            minetest.chat_send_player(pname, "[Networking] ERROR: The start of the range comes after the end of the range. Check your input and try again.")
            return false
        end

        minetest.chat_send_player(pname, "[Networking] Starting to process specified range of IPv4 addresses, this may take a moment. Please wait for the success message.")
        local ipv4_whitelist = minetest.deserialize(networking.storage:get_string("ipv4_whitelist"))
        local total, counter = 0, 0

        for oct1 = tonumber(startOctets[1]), tonumber(endOctets[1]), 1 do
            local lastOct2 = oct1 == tonumber(endOctets[1])
            for oct2 = tonumber(startOctets[2]), (lastOct2 and tonumber(endOctets[2]) or 255), 1 do
                local lastOct3 = lastOct2 and oct2 == tonumber(endOctets[2])
                for oct3 = tonumber(startOctets[3]), (lastOct3 and tonumber(endOctets[3]) or 255), 1 do
                    local lastOct4 = lastOct3 and oct3 == tonumber(endOctets[3])
                    for oct4 = tonumber(startOctets[4]), (lastOct4 and tonumber(endOctets[4]) or 255), 1 do
                        local address = tostring(oct1).."."..tostring(oct2).."."..tostring(oct3).."."..tostring(oct4)
                        total = total + 1
                        if address == "127.0.0.1" and not add then
                            minetest.chat_send_player(pname, "[Networking] IP address \'127.0.0.1\' can not be removed from the whitelist.")
                        elseif ipv4_whitelist[address] ~= add then
                            ipv4_whitelist[address] = add
                            counter = counter + 1
                        end
                    end
                end
            end
        end

        networking.storage:set_string("ipv4_whitelist", minetest.serialize(ipv4_whitelist))
        networking.storage:set_int("ipv4_length", networking.storage:get_int("ipv4_length") + (add and 1 or -1)*count)
        if counter > 0 then
            minetest.chat_send_player(pname, "[Networking] SUCCESS: "..tostring(counter).." out of "..tostring(total).." IP addresses in the range \'"..startRange.."\' to \'"..endRange.."\' were "..(add and "added to" or "removed from").." the whitelist.")
            return true
        else
            minetest.chat_send_player(pname, "[Networking] No IP addresses were "..(add and "added to" or "removed from").." the whitelist.")
            return false
        end
    else
        local ipv4_whitelist = minetest.deserialize(networking.storage:get_string("ipv4_whitelist"))
        local address = tostring(tonumber(startOctets[1])).."."..tostring(tonumber(startOctets[2])).."."..tostring(tonumber(startOctets[3])).."."..tostring(tonumber(startOctets[4]))
        if address == "127.0.0.1" and not add then
            minetest.chat_send_player(pname, "[Networking] IP address \'127.0.0.1\' can not be removed from the whitelist.")
            return false
        elseif ipv4_whitelist[address] ~= add then
            ipv4_whitelist[address] = add
            networking.storage:set_string("ipv4_whitelist", minetest.serialize(ipv4_whitelist))
            networking.storage:set_int("ipv4_length", networking.storage:get_int("ipv4_length") + (add and 1 or -1))
            minetest.chat_send_player(pname, "[Networking] SUCCESS: IP address \'"..startRange.."\' was "..(add and "added to" or "removed from").." the whitelist.")
            return true
        else
            minetest.chat_send_player(pname, "[Networking] IP address \'"..startRange.."\' is "..(add and "already" or "not").." in the whitelist.")
            return false
        end
    end
end

function networking.toggle_whitelist(player)
    local pname = player:get_player_name()
    local state = minetest.deserialize(networking.storage:get_string("enabled"))
    if state then
		networking.storage:set_string("enabled", minetest.serialize(false))
		minetest.chat_send_player(pname, "[Networking] Whitelist is now disabled.")
    else
		-- Quick check to ensure current admin player is connected from a whitelisted IP to avoid unintentional lock-out
		local ipv4 = minetest.get_player_ip(pname)
		local ipv4_whitelist = minetest.deserialize(networking.storage:get_string("ipv4_whitelist"))
		if not ipv4_whitelist[ipv4] then
			minetest.chat_send_player(pname, "[Networking] WARNING: You need to join from a whitelisted IP address before you can enable the whitelist otherwise you will be locked out of the server.")
		else
			networking.storage:set_string("enabled", minetest.serialize(true))
			minetest.chat_send_player(pname, "[Networking] Whitelist is now enabled.")
		end
    end
end

function networking.get_whitelist()
    return minetest.deserialize(networking.storage:get_string("ipv4_whitelist"))
end

function networking.get_whitelist_length()
    return networking.storage:get_int("ipv4_length")
end

function networking.get_whitelist_enabled()
    return minetest.deserialize(networking.storage:get_string("enabled"))
end

-- Register chat commands
dofile(minetest.get_modpath("networking") .. "/commands.lua")
