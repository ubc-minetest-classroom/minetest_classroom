minetest.register_chatcommand("set_kick_message", {
	description = "Changes the networking kick message displayed on a failed attempt to join the server from a whitelisted IPv4 address.",
	privs = {server = true},
    params = "<message>",
	func = function(pname, message)
        minetest.chat_send_player(pname, "[Networking] Success: Kick message updated to read '"..message.."'")
        networking.storage:set_string("kick_message", minetest.serialize(message))
	end
})

minetest.register_chatcommand("get_kick_message", {
	description = "Prints the networking kick message to player chat.",
	privs = {server = true},
	func = function(pname, message)
        local message = minetest.deserialize(networking.storage:get_string("kick_message"))
        minetest.chat_send_player(pname, "[Networking] Kick message currently reads '"..message.."'")
	end
})

minetest.register_chatcommand("add_ipv4", {
	description = "Adds a single IPv4 address or a comma-separated list of IPv4 addresses to the whitelist.",
	privs = {server = true},
    params = "<ipv4_addresses>",
	func = function(pname, ipv4)
        -- Validate entry
        local addresses = networking.parse(ipv4, ",")
        if #addresses == 0 then
            return minetest.chat_send_player(pname, "[Networking] ERROR: Empty input. Add an IPv4 address of the format '0.0.0.0' after the chat command and try again.")
        end

        local player = minetest.get_player_by_name(pname)
        local ctr = 0
        local ctr_success = 0
        for _,address in pairs(addresses) do
            ctr = ctr + 1
            local success = networking.modify_ipv4(player, address, nil, true)
            ctr_success = ctr_success + (success and 1 or 0)
        end
        minetest.chat_send_player(pname, "[Networking] Successfully added "..ctr_success.." out of "..ctr.." IP addresses to the whitelist.")
	end
})

minetest.register_chatcommand("add_ipv4_range", {
	description = "Adds a range of IPv4 addresses to the whitelist.",
	privs = {server = true},
    params = "<ipv4_address_start> <ipv4_address_end>",
	func = function(pname, input)
        -- Validate entry
        local addresses = networking.parse(input," ")
        if #addresses == 0 then
            return minetest.chat_send_player(pname, "[Networking] ERROR: Start of IP address range missing. Add an IPv4 address range of the format \'0.0.0.0 1.1.1.1\' after the chat command and try again.")
        elseif #addresses == 1 then
            return minetest.chat_send_player(pname, "[Networking] ERROR: End of IP address range missing. Add an IPv4 address range of the format \'0.0.0.0 1.1.1.1\' after the chat command and try again.")
        end

        local player = minetest.get_player_by_name(pname)
        local startRange = addresses[1]
        local endRange = addresses[2]
        networking.modify_ipv4(player, startRange, endRange, true)
	end
})

minetest.register_chatcommand("remove_ipv4", {
	description = "Removes a single IPv4 address or a comma-separated list of IPv4 addresses from the whitelist.",
	privs = {server = true},
    params = "<ipv4_addresses>",
	func = function(pname, ipv4)
        -- Validate entry
        local addresses = networking.parse(ipv4, ",")
        if #addresses == 0 then
            return minetest.chat_send_player(pname, "[Networking] ERROR: Empty input. Add an IPv4 address of the format \'0.0.0.0\' after the chat command and try again.")
        end

        local player = minetest.get_player_by_name(pname)
        local ctr = 0
        local ctr_success = 0
        for _,address in pairs(addresses) do
            ctr = ctr + 1
            local success = networking.modify_ipv4(player, address, nil, nil)
            ctr_success = ctr_success + (success and 1 or 0)
        end
        minetest.chat_send_player(pname, "[Networking] Successfully removed "..ctr_success.." out of "..ctr.." IP addresses from the whitelist.")
	end
})

minetest.register_chatcommand("remove_ipv4_range", {
	description = "Removes a range of IPv4 addresses from the whitelist.",
	privs = {server = true},
    params = "<ipv4_address_start> <ipv4_address_end>",
	func = function(pname, input)
        -- Validate entry
        local addresses = networking.parse(input," ")
        if #addresses == 0 then
            -- Empty entry
            return minetest.chat_send_player(pname, "[Networking] ERROR: Start of IP address range missing. Add an IPv4 address range of the format \'0.0.0.0 1.1.1.1\' after the chat command and try again.")
        elseif #addresses == 1 then
            -- Missing entry
            return minetest.chat_send_player(pname, "[Networking] ERROR: End of IP address range missing. Add an IPv4 address range of the format \'0.0.0.0 1.1.1.1\' after the chat command and try again.")
        end

        local player = minetest.get_player_by_name(pname)
        local startRange = addresses[1]
        local endRange = addresses[2]
        networking.modify_ipv4(player, startRange, endRange, nil)
	end
})

minetest.register_chatcommand("clear_whitelist", {
	description = "Removes all IPv4 addresses from the whitelist except the default address \'127.0.0.1\' for singleplayer.",
	privs = {server = true},
	func = function(pname, _)
        local ipv4_whitelist = {["127.0.0.1"] = true}
        networking.storage:set_string("ipv4_whitelist", minetest.serialize(ipv4_whitelist))
        networking.storage:set_int("ipv4_length", 1)
        minetest.chat_send_player(pname, "[Networking] SUCCESS: Removed all IPv4 addresses from the whitelist.")
	end
})

minetest.register_chatcommand("dump_whitelist", {
	description = "Dumps all whitelisted IPv4 addresses into chat.",
	privs = {server = true},
	func = function(pname, _)
        local whitelist = minetest.deserialize(networking.storage:get_string("ipv4_whitelist"))
        minetest.chat_send_player(pname, "[Networking] Whitelisted IPv4 addresses:")
        for ipv4,_ in pairs(whitelist) do
            minetest.chat_send_player(pname, "[Networking] "..ipv4)
        end
	end
})

minetest.register_chatcommand("whitelist", {
	description = "Toggles the state of the whitelist between enabled and disabled.",
	privs = {server = true},
	func = function(pname, _)
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
})
