## Chat Log for Minetest

---
### Description:

A [Minetest][] mod that logs player conversations to the world directory.

Originally forked from [JBR's chatlog mod](https://forum.minetest.net/viewtopic.php?t=6220).

---
### Usage:

Available configuration settings:

- `chatlog.format`
	- String representing timestamp format (see: https://www.lua.org/pil/22.1.html).
	- default: `%m/%d/%Y %H:%M:%S`
- `chatlog.single_file`
	- Output to a single file (chatlog.txt) instead of separating by date (chatlog/YYYY_MM_DD.txt).
	- default: `false`
- `chatlog.disable`
	- Disables logging.
	- default: `false`

---
### Licensing:

[MIT](LICENSE.txt)

---
### Links:

- [![ContentDB](https://content.minetest.net/packages/AntumDeluge/chatlog/shields/title/)](https://content.minetest.net/packages/AntumDeluge/chatlog/)
- [Forum](https://forum.minetest.net/viewtopic.php?t=18287)
- [Git repo](https://github.com/AntumMT/mod-chatlog)
- [Changelog](changelog.txt)
- [TODO](TODO.txt)


[Minetest]: http://www.minetest.net/
