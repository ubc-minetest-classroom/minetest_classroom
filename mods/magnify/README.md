# `magnify` modpack

*Release version: n/a*  
*Dependencies: [`sfinv`](https://github.com/rubenwardy/sfinv)*

## About the modpack

The `magnify` modpack includes 3 mods: `magnify`, `magnify_default_nodes` and `magnify_flowers_nodes`.

The `magnify` mod adds a magnifying glass tool and plant compendium inventory tab to the game, allowing players to view information about real-life equivalents to the plant species present in Minetest. It also provides an API for registering and accessing information about these species.  
The `magnify_default_nodes` and `magnify_flowers_nodes` mods contain information about the real-life equivalents to the plant species present in the `default` and `flowers` mods, respectively. Information about these species is registered with the `magnify` API, allowing it to be displayed in-game.

### Screenshots

<img src = "screenshots/magnify_modpack_standard_viewer.png" alt = "Species viewer" width = "480" height = "250">
<img src = "screenshots/magnify_modpack_technical_viewer.png" alt = "Technical viewer" width = "480" height = "250">
<img src = "screenshots/magnify_modpack_technical_locator.png" alt = "Species locator" width = "480" height = "250">

## Registering plant species using the `magnify` API

Detailed instructions coming soon!

<!--
Registers a species in the `magnify` species database  
**Should only be called on mod load-in**

- Parameters:
  - `def_table` (*`table`*): Species definition table

    ```lua
    local def_table = {
        sci_name = "",        -- Scientific name of species
        com_name = "",        -- Common name of species
        fam_name = "",        -- Family name of species
        cons_status = {       -- Conservation statuses of species
            ns_global = "",       -- NatureServe global status
            ns_bc = "",           -- NatureServe BC status
            bc_list = ""          -- BC List (Red Blue List) status
        },
        height = "",          -- Species height
        bloom = "",           -- The way the species blooms
        region = "",          -- Native region/range of species (displayed as "Found in [region]")
        texture = {""},       -- Images of species (in `mod/textures`) - can be a string if only one image
        model_obj = "",       -- Model file (in `mod/models`)
        model_rot_x = 0,      -- Initial rotation of model about x-axis (in degrees; defaults to 0)
        model_rot_y = 0,      -- Initial rotation of model about y-axis (in degrees; defaults to 180)
        more_info = "",       -- Extended description of species
        external_link = "",   -- Link to page with more species information
        img_copyright = "",   -- Copyright owner of species image (displayed as "Image (c) [img_copyright]")
        img_credit = ""       -- Author of species image (displayed as "Image courtesy of [img_credit]")
    }
    ```

  - `nodes` (*`table`*): Table of stringified nodes (`mod_name:node_name`) the species corresponds to in the MineTest world
- Returns:
  - *`string`*: Reference key of the species registered  
  *OR*
  - `nil` if the species was not registered
- Usage:

  ```lua
  magnify.register_species(def_table, {"mod:node", "mod:another_node", "other_mod:other_node"})
  ```

- Additional notes:
  - The following properties will automatically be added to the species definiton table when `magnify.register_species` is called during mod load-in:

    ```lua
    {
        origin = ""           -- Name of mod which registered the plant species
    }
    ```
-->