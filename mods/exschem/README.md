# ExSchem
[Minetest](https://www.minetest.net/ "Link to minetest.net") mod adding lag free saving, loading and emerging of schematics by seperating them in little part schematics asynchronous

## Dependencies
* [WorldEdit](https://forum.minetest.net/viewtopic.php?t=572 "Link to WorldEdit mod in the minetest forum") (Optional, [Newer than 15.June.2019](https://github.com/TalkLounge/exschem/blob/master/init.lua#L132 "Link to explanation"))

## Manual
#### For players
Use chatcommand `/exschem` or `/help exschem` to see help. You need the privilege: privs  
Or view [video](https://www.youtube.com/watch?v=2aXFCvwbCTE "Link to YouTube video")/[update video](https://www.youtube.com/watch?v=7ddLBhSGVSE "Link to YouTube update video") on YouTube

**Minetest schematic: Saving**
1. /exschem pos1 or /exschem pos1 X Y Z
2. /exschem pos2 or /exschem pos2 X Y Z
3. /exschem save FILENAME

**Minetest schematic: Loading**
1. /exschem pos1 or /exschem pos1 X Y Z
2. (Optional) /exschem here
3. /exschem load FILENAME

**WorldEdit schematic: Saving**
1. /exschem pos1 or /exschem pos1 X Y Z
2. /exschem pos2 or /exschem pos2 X Y Z
3. /exschem save FILENAME true

**WorldEdit schematic: Loading**
1. /exschem pos1 or /exschem pos1 X Y Z
2. (Optional) /exschem here
3. /exschem load FILENAME

**Emerge**
1. /exschem pos1 or /exschem pos1 X Y Z
2. /exschem pos2 or /exschem pos2 X Y Z
3. /exschem emerge

#### For programmers
Use api functions [exschem.load](https://github.com/TalkLounge/exschem/blob/master/init.lua#L144 "Link to exschem.load function"), [exschem.save](https://github.com/TalkLounge/exschem/blob/master/init.lua#L78 "Link to exschem.save"), [exschem.kill](https://github.com/TalkLounge/exschem/blob/master/init.lua#L182 "Link to exschem.kill"), [exschem.emerge](https://github.com/TalkLounge/exschem/blob/master/init.lua#L212 "Link to exschem.emerge")

## Version
2.0

## License
CC BY-NC 3.0 | See [LICENSE](https://github.com/TalkLounge/exschem/blob/master/LICENSE.md "Link to LICENSE.md")

## Credits
**TalkLounge**  
E-Mail: talklounge@yahoo.de  
GitHub: [TalkLounge](https://github.com/TalkLounge/ "Link to TalkLounge's GitHub account")  
Minetest: [TalkLounge](https://forum.minetest.net/memberlist.php?mode=viewprofile&u=20862 "Link to TalkLounge's Minetest Forum account")

**Other contributors**  
See: [Other contributors](https://github.com/TalkLounge/exschem/graphs/contributors "Link to other contributors")

## Minetest forum post
View [exschem](https://forum.minetest.net/viewtopic.php?f=9&t=22794 "Link to exschem post in the minetest forum")

## ToDo
* Add rotate support for whole schematic
