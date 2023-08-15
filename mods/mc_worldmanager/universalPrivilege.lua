-- Grants a universal privilege to a player
function mc_worldManager.grantUniversalPriv(player, privs)
    local pmeta = player:get_meta()
    local playerPrivileges = minetest.deserialize(pmeta:get_string("universalPrivs")) or {}

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

-- Revokes a universal privilege from a player
-- If overwrite_denied_privs is true, denied privs will be overwritten
function mc_worldManager.revokeUniversalPriv(player, privs, overwrite_denied_privs)
    local pmeta = player:get_meta()
    local playerPrivileges = minetest.deserialize(pmeta:get_string("universalPrivs")) or {}

    for index, privilege in pairs(privs) do
        if (privilege == "all") then
            if overwrite_denied_privs then
                playerPrivileges = {}
            else
                for k, v in pairs(playerPrivileges) do
                    if playerPrivileges[k] ~= false then
                        playerPrivileges[k] = nil
                    end
                end
            end
            break
        else
            if playerPrivileges[privilege] ~= false or overwrite_denied_privs then
                playerPrivileges[privilege] = nil
            end
        end
    end

    pmeta:set_string("universalPrivs", minetest.serialize(playerPrivileges))
end

-- Revokes a universal privilege from a player, and restricts it from being given as a realm privilege
function mc_worldManager.denyUniversalPriv(player, privs)
    local pmeta = player:get_meta()
    local playerPrivileges = minetest.deserialize(pmeta:get_string("universalPrivs")) or {}

    for index, privilege in pairs(privs) do
        if (privilege == "all") then
            for k, v in pairs(minetest.registered_privileges) do
                playerPrivileges[k] = false
            end
            break
        else
            if (minetest.registered_privileges[privilege] ~= nil) then
                playerPrivileges[privilege] = false
            end
        end
    end

    pmeta:set_string("universalPrivs", minetest.serialize(playerPrivileges))
end