minetest_classroom.bc_plants = minetest.get_mod_storage()

-- test table
local testTable = {
	sci_name = "Scientic Name",
	com_name = "Common Name",
	region = "Region",
	texture = "test.png", 
	status = "Endangered",
	more_info = "lorem ipsum dolor, sit amet. foobar.",
	external_link = "https://unsplash.com/s/photos/plant"
}
local anotherTestTable = {
	sci_name = "Glass but scientific",
	com_name = "Magnifying Glass",
	region = "The world",
	texture = "magnifying_tool.png", 
	status = "Common",
	more_info = "This isn't a plant, it's a magnifying glass!",
	external_link = "TBA"
}

-- adding test plants
minetest_classroom.bc_plants:set_string("node_default:dirt_with_grass", "ref_0")
minetest_classroom.bc_plants:set_string("ref_0", minetest.serialize(testTable))
minetest_classroom.bc_plants:set_string("node_default:dirt", "ref_1")
minetest_classroom.bc_plants:set_string("node_default:pine_tree", "ref_1")
minetest_classroom.bc_plants:set_string("ref_1", minetest.serialize(anotherTestTable))
-- temporary
minetest_classroom.bc_plants:set_int("count", 2)

-- Check for shout priv (from mc_student)
local function check_perm(player)
	return minetest.check_player_privs(player:get_player_name(), { shout = true })
end

local function build_formspec(node_name)
	-- local minetest.registered_nodes[node_name]
	-- local file_path = minetest.get_modpath("...") .. "/bc_plants/" .. node_name .. ".lua"
  
  local ref_key = minetest_classroom.bc_plants:get("node_" .. node_name)
  local info = minetest.deserialize(minetest_classroom.bc_plants:get(ref_key))
  
  local identify_formtable = {
		"formspec_version[5]",
		"size[14.8,5.8]",
		"box[0.4,0.4;8.6,1.1;#008000]",
		"label[0.5,0.7;", info.sci_name, "]",
		"label[0.5,1.2;Common name: ", info.com_name, "]",
		"label[0.7,2.1;Native to ", info.region, "]",
		"image[9.4,0.4;5,5;", info.texture, "]",
		"label[0.7,2.6;", info.status, "]",
		"label[0.4,2.1;-]", -- these are bullet points
		"label[0.4,2.6;-]",
		"label[0.4,3.1;-]",
		"label[0.7,3.1;", info.more_info, "]",
		"button[0.4,4.6;4.2,0.8;more_info;More info (info.external_link)]",
  		"button_exit[4.8,4.6;4.2,0.8;exit;Back]"
	}

	return table.concat(identify_formtable, "")
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
				-- good: open formspec
				minetest.show_formspec(username, "magnifying_tool:identify", build_formspec(node_name))
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

--[[ TODO:
- Add files with node information custom and existing 
- Determine directory for saving files + save format - pull information to build formspec 
  - use require("...") to get files
- Create formspec definition
- utilize lookup table retrieve data from mod storage  -- CURRENT approach 
make a table with names (reference) and data underneath, based on table name formspec will show 
variable 
-- test values into storage table 

-- FORMSPEC OUTLINE:

--lua table retrives lua file using require to get all info 

-- Scientific name 
-- Common Name 
-- Native Region
-- Image 
-- External Link
]]

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