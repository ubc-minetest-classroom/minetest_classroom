----------------------------------
--    TUTORIAL BOOK FUNCTIONS   --
----------------------------------

-- Define a formspec that will describe tutorials and give the option to teleport to selected tutorial realm
local mc_student_tutorial_menu =
	"formspec_version[5]" .. 
	"size[13,10]" ..
	"button[0.2,0.2;4.6,0.8;intro;Introduction]" ..
	"box[0.2,8.4;10.2,1.4;#505050]" ..
	"button[0.2,1.2;4.6,0.8;mov;Movement]" ..
	"button[0.2,2.2;4.6,0.8;punch;Punch A Block]" ..
	"textarea[5,0.2;7.8,8;text;;Welcome to Minetest Classroom! To access tutorials, select the topic you would like to learn about on the left. Tutorials can also be accessed via portals that will teleport you to the tutorial relevant to the area you are in. To use a portal, stand in the wormhole until it transports you to a new area. Once you are in the tutorial realm, you can use the portal again to return to the area you were previously in.]" ..
	"button[0.4,8.7;9.8,0.8;teleport;Teleport to Tutorial]" ..
	"box[10.7,8.4;2.1,1.4;#C0C0C0]" ..
	"button_exit[11,8.65;1.5,0.9;exit;Exit]"

local function show_tutorial_menu(player)
	if check_perm(player) then
		local pname = player:get_player_name()
		minetest.show_formspec(pname, "mc_student:tutorial_menu", mc_student_tutorial_menu)
		return true
	end
end

-- The tutorial book for accessing tutorials
minetest.register_tool("mc_student:tutorialbook" , {
	description = "Tutorial book",
	inventory_image = "tutorial_book.png",
	-- Left-click the tool activates the tutorial menu
	on_use = function (itemstack, user, pointed_thing)
        local pname = user:get_player_name()
		-- Check for shout privileges
		if check_perm(user) then
			show_tutorial_menu(user)
		end
	end,
	-- Destroy the book on_drop to keep things tidy
	on_drop = function (itemstack, dropper, pos)
		minetest.set_node(pos, {name="air"})
	end,
})

minetest.register_alias("tutorialbook", "mc_student:tutorialbook")
tutorialbook = minetest.registered_aliases[tutorialbook] or tutorialbook

minetest.register_on_joinplayer(function(player)
	local inv = player:get_inventory()
	if inv:contains_item("main", ItemStack("mc_student:tutorialbook")) then
		if check_perm(player) then
			return
		else
			player:get_inventory():remove_item('main', 'mc_student:tutorialbook')
		end
	else
		if check_perm(player) then
			player:get_inventory():add_item('main', 'mc_student:tutorialbook')
		else
			return
		end
	end
end)

mc_student_mov =
	"formspec_version[5]" .. 
	"size[13,10]" ..
	"button[0.2,0.2;4.6,0.8;intro;Introduction]" ..
	"box[0.2,8.4;10.2,1.4;#505050]" ..
	"button[0.2,1.2;4.6,0.8;mov;Movement]" ..
	"button[0.2,2.2;4.6,0.8;punch;Punch A Block]" ..
	"textarea[5,0.2;7.8,8;text;;This tutorial explains how to walk in different directions, jump, and fly. To enter the tutorial, press the 'Teleport to Tutorial' button below. Once you are in the tutorial realm, you can use the portal again to return to the area you were previously in. If you need a reminder on how to use portals, go to 'Introduction'.]" ..
	"button[0.4,8.7;9.8,0.8;teleport;Teleport to Tutorial]" ..
	"box[10.7,8.4;2.1,1.4;#C0C0C0]" ..
	"button_exit[11,8.65;1.5,0.9;exit;Exit]"

local function show_mov(player) 
	if check_perm(player) then
		local pname = player:get_player_name()
		minetest.show_formspec(pname, "mc_student:mov", mc_student_mov)
		return true
	end
end

mc_student_punch =
        "formspec_version[5]" .. 
        "size[13,10]" ..
        "button[0.2,0.2;4.6,0.8;intro;Introduction]" ..
        "box[0.2,8.4;10.2,1.4;#505050]" ..
        "button[0.2,1.2;4.6,0.8;mov;Movement]" ..
		"button[0.2,2.2;4.6,0.8;punch;Punch A Block]" ..
        "textarea[5,0.2;7.8,8;text;;This tutorial explains how to punch and place blocks, which will allow you to add materials to your inventory and build. To enter the tutorial, press the 'Teleport to Tutorial' button below. Once you are in the tutorial realm, you can use the portal again to return to the area you were previously in. If you need a reminder on how to use portals, go to 'Introduction'.]" ..
        "button[0.4,8.7;9.8,0.8;teleport;Teleport to Tutorial]" ..
		"box[10.7,8.4;2.1,1.4;#C0C0C0]" ..
		"button_exit[11,8.65;1.5,0.9;exit;Exit]"

local function show_punch(player) 
	if check_perm(player) then
		local pname = player:get_player_name()
		minetest.show_formspec(pname, "mc_student:punch", mc_student_punch)
		return true
	end
end

--    END TUTORIAL FUNCTIONS    --
----------------------------------