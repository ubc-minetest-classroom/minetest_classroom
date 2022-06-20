function mc_worldManager.grantUniversalPriv(player, privs)
    local pmeta = player:get_meta()

    local playerPrivileges = minetest.deserialize(pmeta:get_string("universalPrivs"))

    for index, privilege in pairs(privs) do
        if (privilege == "all") then
            for k, v in pairs(minetest.registered_privileges) do
                playerPrivileges[k] = true
            end
            break
        else
            if (minetest.registered_privileges[privilege] ~= nil) then
                playerPrivileges[privilege] = true
            end
        end
    end

    pmeta:set_string("universalPrivs", minetest.serialize(playerPrivileges))
end


function mc_worldManager.revokeUniversalPriv(player, privs)
    local pmeta = player:get_meta()

    local playerPrivileges = minetest.deserialize(pmeta:get_string("universalPrivs"))

    for index, privilege in pairs(privs) do
        if (privilege == "all") then
            playerPrivileges = {}
            break
        else
            playerPrivileges[privilege] = nil
        end
    end

    pmeta:set_string("universalPrivs", minetest.serialize(playerPrivileges))
end