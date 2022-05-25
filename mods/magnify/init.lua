minetest_classroom.bc_plants = minetest.get_mod_storage()

local function clear_table()
	local storage_data = minetest_classroom.bc_plants:to_table()
	for k,v in pairs(storage_data.fields) do
		minetest_classroom.bc_plants:set_string(k, "")
	end
end

-- reset: ensure count is initialized at 1
-- clear_table() -- find an alternative for this so that only species that have not been registered get removed
minetest_classroom.bc_plants:set_int("count", 1)

-- Check for shout priv (from mc_student)
local function check_perm(player)
	return minetest.check_player_privs(player:get_player_name(), { shout = true })
end

local function build_formspec(node_name)
	local ref_key = minetest_classroom.bc_plants:get("node_" .. node_name)
	local info = minetest.deserialize(minetest_classroom.bc_plants:get(ref_key))

	if info ~= nil then
		-- entry good, return formspec
		local formtable = {  
    		"formspec_version[5]",
			"size[18.2,7.7]",
			"box[0.4,0.4;11.6,1.6;", minetest.formspec_escape(info.status_col or "#9192a3"), "]",
			"label[0.5,0.7;", minetest.formspec_escape(info.sci_name or "N/A"), "]",
			"label[0.5,1.2;", minetest.formspec_escape((info.com_name and "Common name: "..info.com_name) or "Common name unknown"), "]",
    		"label[0.5,1.7;", minetest.formspec_escape((info.fam_name and "Family: "..info.fam_name) or "Family unknown"), "]",
			--"image[12.4,0.4;5.4,5.4;", minetest.formspec_escape(info.texture or "test.png"), "]",
			"model[12.4,0.4;5.4,5.4;test_tree;tree_test.obj;default_acacia_tree_top.png,default_dry_grass_2.png,default_dry_dirt.png^default_dry_grass_side.png,default_acacia_leaves.png,default_acacia_tree.png,default_dry_grass_1.png,default_dry_grass_3.png,default_dry_grass_4.png,default_dry_grass.png;0,180;false;true;;]",
    
			"label[0.4,2.5;-]",
    		"label[0.4,3;-]",
			"label[0.4,3.5;-]",
    		"label[0.4,4;-]",
			"label[0.7,2.5;", minetest.formspec_escape(info.cons_status or "Conservation status unknown"), "]",
    		"label[0.7,3;", minetest.formspec_escape((info.region and "Native to "..info.region) or "Native region unknown"), "]",
			"label[0.7,3.5;", minetest.formspec_escape(info.height or "Height unknown"), "]",
			"label[0.7,4;", minetest.formspec_escape(info.bloom or "Bloom pattern unknown"), "]",
		
    		"textarea[0.35,4.45;11.5,1.3;;;", minetest.formspec_escape(info.more_info or ""), "]",
    		"label[0.4,6.25;", minetest.formspec_escape((info.img_copyright and "Image © "..info.img_copyright) or (info.img_credit and "Image courtesy of "..info.img_credit) or ""), "]",
			"label[0.4,6.75;", minetest.formspec_escape((info.external_link and "You can find more information at:") or ""), "]",
    		"textarea[0.35,6.9;11.6,0.6;;;", minetest.formspec_escape(info.external_link or ""), "]",
		
    		"button_exit[12.4,6.1;5.4,1.2;back;Back]"
    	}
		return table.concat(formtable, "")
	else
		-- entry bad, go to fallback
		return nil
	end
end

-- register tool
minetest.register_tool("magnify:magnifying_tool", {
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
		if pointed_thing.type ~= "node" then
			return nil
		else
			local username = user:get_player_name()
			local node_name = minetest.get_node(pointed_thing.under).name
			local has_node = minetest_classroom.bc_plants:get("node_" .. node_name)
	
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

-- register on-Join Player 
-- Give the magnifying glass to any player who joins with shout privileges or take away the magnifying glass if they do not have shout
minetest.register_on_joinplayer(function(player)
	local inv = player:get_inventory()
	if inv:contains_item("main", ItemStack("magnify:magnifying_tool")) then
		-- Player has the magnifying glass 
		if check_perm(player) then
			-- The player should have the magnifying glass
			return
		else
			-- The player should not have the magnifying glass
			player:get_inventory():remove_item('main', 'magnify:magnifying_tool')
		end
	else
		-- Player does not have the magnifying glass
		if check_perm(player) then
			-- The player should have the magnifying glass
			player:get_inventory():add_item('main', 'magnify:magnifying_tool')
		else
			-- The player should not have the magnifying glass
			return
		end
	end
end)
