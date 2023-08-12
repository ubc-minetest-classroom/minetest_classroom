# mc_core

Core utilities for Minetest Classroom

## Global Objects

### `minetest_classroom` (*`table`*)

Global table used by various mods to store Minetest Classroom data

## Bundled Utilities

- `bit.numberlua` ([`numberlua.lua`](numberlua.lua)): bitwise operators in Lua
  - Copyright (c) 2008-2011 David Manura, licensed under the MIT license
  - Source: [https://github.com/davidm/lua-bit-numberlua](https://github.com/davidm/lua-bit-numberlua)

## General Helpers ([`init.lua`](init.lua))

### `mc_core.call_priv_grant_callbacks(name, granter, priv)`

Calls `on_priv_grant` callbacks as if `granter` had granted `priv` to `name`

- Parameters:
  - `name` (*`string`*): Name of player privileges were granted to
  - `granter` (*`string`*):  Name of player who granted privileges
  - `priv` (*`string`*): Privilege granted

### `mc_core.call_priv_revoke_callbacks(name, revoker, priv)`

Calls `on_priv_rekove` callbacks as if `revoker` had revoked `priv` from `name`

- Parameters:
  - `name` (*`string`*): Name of player privileges were revoked from
  - `revoker` (*`string`*):  Name of player who revoked privileges
  - `priv` (*`string`*): Privilege revoked

### `mc_core.checkPrivs(player, privs_table)  -->  boolean, table`

Checks if a player has specific privileges

- Parameters:
  - `privs_table` (*`table`*): Table of privileges to check (defaults to `{teacher = true}`)
  - `player` (*`ObjectRef`*) Minetest player object
- Returns:
  - *`boolean`*: `true` if `player` has all privileges provided in `privs_table`, `false` if not
  - *`table`*:  All privileges in `privs_table` that `player` does not have

### `mc_core.clean_key(key)  -->  string`

Removes `KEY_` from the front of key names

- Parameters:
  - `key` (*`string`*): Key to clean
- Returns:
  - *`string`*: Cleaned key string

### `mc_core.deepCopy(table)  -->  table`

Creates a deep copy of the provided table

- Parameters:
  - `table` (*`table`*): Table to copy
- Returns:
  - *`table`*: Deep copy of original table

### `mc_core.shallowCopy(table)  -->  table`

Creates a shallow copy of the provided table

- Parameters:
  - `table` (*`table`*): Table to copy
- Returns:
  - *`table`*: Shallow copy of original table

### `mc_core.expand_time(t)  -->  string, table`

Converts a time in seconds to a human-readable time

- Parameters:
  - `t` (*`number`*): Time in seconds
- Returns:
  - *`string`*: Time string
  - *`table`*: Time in days, hours, minutes, and seconds
    ```lua
    {
        s = 0,  -- seconds
        m = 0,  -- minutes
        h = 0,  -- hours
        d = 0,  -- days
    }
    ```

### `mc_core.fileExists(path)  -->  boolean`

Checks whether or not a file exists

- Parameters:
  - `path` (*`string`*): Path to file
- Returns:
  - *`boolean`*: `true` if a file at `path` exists, `false` if not

### `mc_core.getInventoryItemLocation(inv, itemstack)  -->  string`

Finds the first inventory list that contains the given item, returning its name if found

- Parameters:
  - `inv` (*`InvRef`*): Inventory to search
  - `itemstack` (*`ItemStack`*): Item to look for
- Returns:
  - *`string`*: Name of inventory list containing `itemstack`  
  *OR*
  - `nil` if `itemstack` was not found

### `mc_core.hex_string_to_num(hex)  -->  number`

Returns a hexadecimal string as a number

- Parameters:
  - `hex` (*`string`*): Hexadecimal string
- Returns:
  - *`number`*: `hex` as an number

### `mc_core.isNumber(str)  -->  boolean`

Determines if a string is actually a number stored as a string

- Parameters:
  - `str` (*`string`*): String to check
- Returns:
  - *`boolean`*: `true` if `str` is a number stored as a string, `false` if not

### `mc_core.pairsByKeys(t, f)  -->  function`

First sorts the keys into an array, and then iterates on the array  
At each step, it returns the key and value from the original table  
*Adapted from [https://www.lua.org/pil/19.3.html](https://www.lua.org/pil/19.3.html)*

- Parameters:
  - `t` (*`table`*): Table to iterate over
  - `f` (*`function`*): Optional sorting function
- Returns:
  - *`function`*: Iterator over `t`

### `mc_core.round(x, n)  -->  number`

Rounds a number to a given number of decimal places

- Parameters:
  - `x` (*`number`*): Number to round
  - `n` (*`number`*): Number of decimal places to round to
- Returns:
  - *`number`*: `x` rounded to `n` decimal places

### `mc_core.split(s, delimiter)  -->  table`

Splits a string at each instance of the provided delimiter, then returns a table containing the split parts of the string

- Parameters:
  - `s` (*`string`*): String to split
  - `delimiter` (*`string`*): Delimeter to split `s` at
- Returns:
  - *`table`*: Split string

### `mc_core.starts(string, start)  -->  boolean`

Determines if a string starts with another string

- Parameters:
  - `string` (*`string`*): String to check
  - `start` (*`string`*): Start of string to check for
- Returns:
  - *`boolean`*: `true` if `string` starts with `start`, `false` if not

### `mc_core.stringToColor(name)  -->  table`

Returns a random color based on input seed  
This function is not guaranteed to be the same on all systems

- Parameters:
  - `name` (*`string`*): Seed string
- Returns:
  - *`table`*: Randomly generated colour
    ```lua
    {
        a = 255,    -- alpha channel of colour
        r = 255,    -- red channel of colour
        g = 255,    -- green channel of colour
        b = 255,    -- blue channel of colour
    }
    ```

### `mc_core.stringToNumber(name)  -->  number`

Returns a number based input seed  
This function is not guaranteed to be the same on all systems

- Parameters:
  - `name` (*`string`*): Seed string
- Returns:
  - *`number`*: Corresponding numerical seed

### `mc_core.tableHas(table, val)  -->  boolean`

Checks if any of the keys or values in the given table match the value provided

- Parameters:
  - `table` (*`table`*): Table to check
  - `val` (*`any`*): Value to check for
- Returns:
  - *`boolean`*: `true` if `val` exists in `table`, `false` if not

### `mc_core.trim(s)  -->  string`

Trims whitespace characters from the beginning and end of a string

- Parameters:
  - `s` (*`string`*): String to trim
- Returns:
  - *`string`*: Trimmed string

## GUI Templates ([`gui.lua`](gui.lua))

### `mc_core.draw_book_fs(width, height, options)  -->  formspec string`

Creates a notebook formspec with a content area of the given width and height  
The created formspec will exceed the bounds of the content area (0.5 units left, 0.75 units right, 1.1 units above, 0.4 units below; upper page edge starts at (0, -0.25))

- Parameters:
  - `width` (*`number`*): Content area width
  - `height` (*`number`*): Content area height
  - `options` (*`table`*): Formspec options
    ```lua
    {
        bg = "#325140",                   -- primary notebook colour
        shadow = "#23392d",               -- notebook shadow colour
        binding = "#164326",              -- notebook binding colour
        divider = nil,                    -- notebook divider colour, or nil to exclude
        margin_lines = {1, width/2 + 1}   -- locations of vertical page margins
    }
    ```
- Returns:
  - *`formspec string`*: Blank notebook formspec template

### `mc_core.draw_note_fs(width, height, options)  -->  formspec string`

Creates a sticky note formspec with a content area of the given width and height  
The created formspec will contain the `no_prepend[]` element

- Parameters:
  - `width` (*`number`*): Content area width
  - `height` (*`number`*): Content area height
  - `options` (*`table`*): Formspec options
    ```lua
    {
        bg = "#325140",       -- primary sticky note colour
        accent = "#164326"    -- secondary sticky note colour
    }
    ```
- Returns:
  - *`formspec string`*: Blank sticky note formspec template

## Player Freezing ([`freeze.lua`](freeze.lua))

*Adapted from `freeze.lua` in rubenwardy's `classroom` mod*  
*Copyright (c) 2018-2022 rubenwardy, licensed under the MIT license*  
*Source: [https://gitlab.com/rubenwardy/classroom/-/blob/master/freeze.lua](https://gitlab.com/rubenwardy/classroom/-/blob/master/freeze.lua)*

### `mc_core.freeze(player)`

Freezes a player, preventing them from moving on their own

- Parameters:
  - `player` (*`ObjectRef`*): Player to freeze

### `mc_core.unfreeze(player)`

Unfreezes a player, allowing them to move on their own

- Parameters:
  - `player` (*`ObjectRef`*): Player to unfreeze

### `mc_core.is_frozen(player)  -->  boolean`

Returns `true` if the player is frozen, `false` otherwise

- Parameters:
  - `player` (*`ObjectRef`*): Player to check
- Returns:
  - *`boolean`*: `true` if `player` is frozen, `false` otherwise

### `mc_core.temp_unfreeze_and_run(player, func, ...)`

Temporarily unfreezes `player` if they are frozen, runs `func`, then refreezes `player` if they should be frozen
This should be used when applying forced movement to a player, since frozen players can not be teleported normally
Optional arguments after `func` will be passed into `func` when it runs (similarly to how `minetest.after` passes arguments)

- Parameters:
  - `player` (*`ObjectRef`*): Player to treat as unfrozen
  - `func` (*`function`*): Function to run
  - `...` (*`vararg`*): Optional comma-separated arguments for `func`
- Returns:
  - *`vararg`*: Returns from `func`

## Compression ([`lualzw.lua`](lualzw.lua))

*Copyright (c) 2016 Rochet2, licensed under the MIT license*  
*Source: [https://github.com/Rochet2/lualzw](https://github.com/Rochet2/lualzw)*

### `mc_core.compress(input)  -->  string`

Compresses a string using LZW compression

- Parameters:
  - `input` (*`string`*): String to compress
- Returns:
  - *`string`*: Compressed string

### `mc_core.decompress(input)  -->  string`

Decompresses a string compressed using LZW compression

- Parameters:
  - `input` (*`string`*): String to decompress
- Returns:
  - *`string`*: Decompressed string

## Point Tables ([`PointTable.lua`](PointTable.lua))

### `ptable.store(table, coords, value)`

Stores a value in a 3D table  
*For the 2D equivalent, see [`ptable.store2D`](#ptablestore2dtable-coords-value)*

- Parameters:
  - `table` (*`table`*): 3D table
  - `coords` (*`table`*): 3D coordinate key to store data in
  - `value` (*`any`*): Value to store

### `ptable.get(table, coords)  -->  any`

Gets a value from a 3D table  
*For the 2D equivalent, see [`ptable.get2D`](#ptableget2dtable-coords------any)*

- Parameters:
  - `table` (*`table`*): 3D table
  - `coords` (*`table`*): 3D coordinate key to get data from
- Returns:
  - *`any`*: Value stored at `coords`

### `ptable.delete(table, coords)`

Deletes a value from a 3D table  
*For the 2D equivalent, see [`ptable.delete2Ds`](#ptabledelete2dstable-coords)*

- Parameters:
  - `table` (*`table`*): 3D table
  - `coords` (*`table`*): 3D coordinate key to remove

### `ptable.store2D(table, coords, value)`

Stores a value in a 2D table  
*For the 3D equivalent, see [`ptable.store`](#ptablestoretable-coords-value)*

- Parameters:
  - `table` (*`table`*): 2D table
  - `coords` (*`table`*): 2D coordinate key to store data in
  - `value` (*`any`*): Value to store

### `ptable.get2D(table, coords)  -->  any`

Gets a value from a 2D table  
*For the 3D equivalent, see [`ptable.get`](#ptablegettable-coords------any)*

- Parameters:
  - `table` (*`table`*): 2D table
  - `coords` (*`table`*): 2D coordinate key to get data from
- Returns:
  - *`any`*: Value stored at `coords`

### `ptable.delete2Ds(table, coords)`

Deletes a value from a 2D table  
*For the 3D equivalent, see [`ptable.delete`](#ptabledeletetable-coords)*

- Parameters:
  - `table` (*`table`*): 2D table
  - `coords` (*`table`*): 2D coordinate key to remove

## Debugging Helpers ([`Debugging.lua`](Debugging.lua))

### `Debug.log(message)`

Logs a message in the debug log

- Parameters:
  - `message` (*`string`*): Message to log

### `Debug.logTable(title, table)`

Logs a table's contents in the debug log

- Parameters:
  - `title` (*`string`*): Title of table
  - `table` (*`table`*): Table to log

### `Debug.logCoords(coords, name)`

Logs world coordinates in the debug log

- Parameters:
  - `coords` (*`table`*): World coordinates to log
  - `name` (*`string`*): Label for coordinates
