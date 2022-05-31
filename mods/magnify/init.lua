magnify_plants = minetest.get_mod_storage()
dofile(minetest.get_modpath("magnify") .. "/api.lua")

local tool_name = "magnify:magnifying_tool"
local priv_table = {"interact"}

-- Checks for adequate privileges
local function check_perm_name(name)
    return minetest.check_player_privs(name, {interact = true})
end
local function check_perm(player)
    return check_perm_name(player:get_player_name())
end

-- Clears the plant database
local function clear_table()
    local storage_data = magnify_plants:to_table()
    for k,v in pairs(storage_data.fields) do
        magnify_plants:set_string(k, "")
    end
end

-- reset: ensure count is initialized at 1
-- clear_table() -- find an alternative for this so that only species that have not been registered get removed
magnify_plants:set_int("count", 1)

-- Builds the magnifying glass info formspec for the node with the given name
local function build_formspec(node_name)
  local ref_key = magnify_plants:get("node_" .. node_name)
  return magnify.build_formspec_from_ref(ref_key, true)
end

-- Registers the magnifying glass tool
minetest.register_tool(tool_name, {
    description = "Magnifying Glass",
    _doc_items_longdesc = "This tool can be used to quickly learn more about about one's closer environment. It identifies and analyzes plant-type blocks and it shows extensive information about the thing on which it is used.",
    _doc_items_usagehelp = "Punch any block resembling a plant you wish to learn more about. This will open up the appropriate help entry.",
    _doc_items_hidden = false,
    tool_capabilities = {},
    range = 10,
    groups = { disable_repair = 1 }, 
    wield_image = "magnifying_tool.png",
    inventory_image = "magnifying_tool.png",
    liquids_pointable = false,
    on_use = function(itemstack, user, pointed_thing)
        if not check_perm(user) or pointed_thing.type ~= "node" then
            return nil
        else
            local username = user:get_player_name()
            local node_name = minetest.get_node(pointed_thing.under).name
            local has_node = magnify_plants:get("node_" .. node_name)
    
            if has_node ~= nil then
                -- try to build formspec
                local species_formspec = build_formspec(node_name)
                if species_formspec ~= nil then
                    -- good: open formspec
                    minetest.show_formspec(username, "magnifying_tool:identify", species_formspec)
                else
                    -- bad: display corrupted node message in chat
                    minetest.chat_send_player(username, "An entry for this item exists, but could not be found in the plant database.\nPlease contact an administrator and ask them to check your server's plant database files to ensure all plants were registered properly.")
                end
            else
                -- bad: display failure message in chat
                minetest.chat_send_player(username, "No entry for this item could be found.")
            end
            return nil
        end
    end,
    -- makes the tool undroppable
    on_drop = function (itemstack, dropper, pos)
        minetest.set_node(pos, {name="air"})
    end
})

--- Return the reference key of the species at the given index in the species list
--- @param index The position in the species list to get the reference key for
--- @return string
--- @see magnify.get_all_registered_species()
local function get_species_ref(index)
  	local list = magnify.get_all_registered_species()
	local elem = list[tonumber(index)]
	local ref_num_split = string.split(elem, ":") -- "###num:rest"
  	local ref_str = ref_num_split[1]
	local ref_num = string.sub(ref_str, 4) -- removes "###" from "###num"
	return "ref_"..ref_num
end

--- Return the technical formspec for a species
--- @return formspec string
local function get_expanded_species_formspec(info, nodes, ref)
	local formtable = {    
    	"formspec_version[5]",
		"size[14,8.2]",
		"box[0.4,0.4;13.2,1;#9192a3]",
		"label[5.4,0.9;Technical Information]",
		"label[0.4,1.9;", info.com_name or info.sci_name or "Unknown", " (", ref, ")]",
		"image[8.8,1.7;4.8,4.8;", info.texture or "test.png", "]",
		"textlist[0.4,2.8;8.1,3.7;associated_blocks;", table.concat(nodes, ","), ";1;false]",
		"label[0.4,2.5;Associated nodes:]",
		"button_exit[4.8,6.8;4.4,1;back;Back]"
	}
	return table.concat(formtable, "")
end

-- Registers the plant compendium as an inventory tab
sfinv.register_page("magnify:compendium", {
	title = "Plant Compendium", -- add translations
	get = function(self, player, context)
		-- refactor implementation from mc_teacher
      	local species = table.concat(magnify.get_all_registered_species(), ",")
        local formtable = {
			"bgcolor[#00FF00;true]", -- #172e1b
            "textlist[0,0;7.8,3.75;species_list;", species, ";", context.species_selected or 1, ";false]",
            "button[0,4.05;4,0.6;standard_view;View Species]",
            "button[4,4.05;4,0.6;technical_view;View Technical Info]"
        }
        return sfinv.make_formspec(player, context, table.concat(formtable, ""), true)
	end,
	on_enter = function(self, player, context)
		if not context.species_selected then
			context.species_selected = 1
		end
	end,
on_player_receive_fields = function(self, player, context, fields)
    if fields.species_list then
        local event = minetest.explode_textlist_event(fields.species_list)
        if event.type == "CHG" then
        	context.species_selected = event.index
        	end
		elseif fields.standard_view or fields.technical_view then
			if context.species_selected then
      		    local ref = get_species_ref(context.species_selected)
          		local full_info = magnify.get_species_from_ref(ref)
				local pname = player:get_player_name()
				if full_info ~= nil then
          			if fields.standard_view then -- standard
						minetest.show_formspec(pname, "magnify:species_standard", magnify.build_formspec_from_ref(ref, true))
            		else -- technical
            			minetest.show_formspec(pname, "magnify:species_technical", get_expanded_species_formspec(full_info.data, full_info.nodes, ref))
            		end
				else
					minetest.chat_send_player(pname, "An entry for this species exists, but could not be found in the plant database.\nPlease contact an administrator and ask them to check your server's plant database files to ensure all plants were registered properly.")
				end	
        	end
		end
	end,
	is_in_nav = function(self, player, context)
		-- only shows the compendium to players with adequate privileges
		return check_perm(player)
	end
})

-- Tool handling functions:
    -- Give the magnifying tool to any player who joins with adequate privileges or take it away if they do not have them
    -- Give the magnifying tool to any player who is granted adequate privileges
    -- Take the magnifying tool away from anyone who is revoked privileges and no longer has adequate ones

-- Give the magnifying tool to any player who joins with adequate privileges or take it away if they do not have them
minetest.register_on_joinplayer(function(player)
    local inv = player:get_inventory()
    if inv:contains_item("main", ItemStack(tool_name)) then
        -- Player has the magnifying glass 
        if check_perm(player) then
            -- The player should have the magnifying glass
            return
        else
            -- The player should not have the magnifying glass
            player:get_inventory():remove_item('main', tool_name)
        end
    else
        -- Player does not have the magnifying glass
        if check_perm(player) then
            -- The player should have the magnifying glass
            player:get_inventory():add_item('main', tool_name)
        else
            -- The player should not have the magnifying glass
            return
        end
    end
end)

-- Give the magnifying tool to any player who is granted adequate privileges
minetest.register_on_priv_grant(function(name, granter, priv)
    -- Check if priv has an effect on the privileges needed for the tool
    if name == nil or not table.has(priv_table, priv) or not minetest.get_player_by_name(name) then
        return true -- skip this callback, continue to next callback
    end

    local player = minetest.get_player_by_name(name)
    local inv = player:get_inventory()
    
    if not inv:contains_item("main", ItemStack(tool_name)) and check_perm_name(name) then
        player:get_inventory():add_item('main', tool_name)
    end

    return true -- continue to next callback
end)

-- Take the magnifying tool away from anyone who is revoked privileges and no longer has adequate ones
minetest.register_on_priv_revoke(function(name, revoker, priv)
    -- Check if priv has an effect on the privileges needed for the tool
    if name == nil or not table.has(priv_table, priv) or not minetest.get_player_by_name(name) then
        return true -- skip this callback, continue to next callback
    end

    local player = minetest.get_player_by_name(name)
    local inv = player:get_inventory()

    if inv:contains_item("main", ItemStack(tool_name)) and not check_perm_name(name) then
        player:get_inventory():remove_item('main', tool_name)
    end

    return true -- continue to next callback
end)