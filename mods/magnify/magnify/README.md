# magnify

Adds a magnifying glass tool and inventory plant compenium for viewing information about various plant species in the MineTest world

*Release version: n/a*  
*Dependencies: [`sfinv`](https://github.com/rubenwardy/sfinv)*

## API

### Registration

#### `magnify.register_species(def_table, nodes)  -->  string`

Registers a species in the `magnify` species database  
Should only be called on mod load-in

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

#### `magnify.register_plant(def_table, nodes)  -->  string`

Identical to `magnify.register_species`  
**Deprecated**: use `magnify.register_species` instead

#### `magnify.clear_nodes(nodes)`

Clears the nodes in `nodes` from the `magnify` species database, then clears any species that are no longer associated with any nodes as a result of clearing the nodes in `nodes`

- Parameters:
  - `nodes` (*`table`*): Table of stringified nodes (`mod_name:node_name`) to clear

#### `magnify.clear_ref(ref)`

Clears a species and all its associated nodes from the `magnify` species database

- Parameters:
  - `ref` (*`string`*): Reference key of the species to clear

### General

#### `magnify.get_ref(node)  -->  string`

Returns the reference key associated with `node` in the `magnify` species database

- Parameters:
  - `node` (*`string`*): Stringified node (`mod_name:node_name`)
- Returns:
  - *`string`*: Reference key of the node  
  *OR*
  - `nil` if `node` is invalid or not registered in the `magnify` species database

#### `magnify.get_species_from_ref(ref)  -->  table, table`

Returns the species definition table of the species indexed at `ref` in the `magnify` species database, and a list of nodes the species is associated with

- Parameters:
  - `ref` (*`string`*): Reference key of the species
- Returns:
  - *`table`*: Species definition table
  - *`table`*: Table of all nodes associated with the species  
  *OR*
  - `nil` if `ref` is invalid

#### `magnify.get_all_registered_species()  -->  table, table`

Returns a human-readable list of all species registered in the `magnify` species database, and a list of reference keys corresponding to them  
Each species and its corresponding reference key will be at the same index in both lists

- Returns:
  - *`table`*: Names of all registered species, formatted as "Common name (Scientific name)"
  - *`table`*: Reference keys for all registered species, in the same order as the list of names

#### `magnify.build_formspec_from_ref(ref, is_exit, is_inv)  -->  string, string`

Builds the general species information formspec for the species indexed at `ref` in the `magnify` species database  

- Parameters:
  - `ref` (*`string`*): Reference key of the species
  - `is_exit` (*`boolean`*): `true` if clicking the "Back" button should exit the formspec, `false` otherwise
  - `is_inv` (*`boolean`*): `true` if the formspec is being used in the player inventory, `false` otherwise
- Returns:
  - *`string`*: Full formspec
  - *`string`*: Formspec `size[]` element  
  *OR*
  - `nil` if `ref` is invalid

### Utility

#### `magnify.table_has(table, val)  -->  boolean`

Returns `true` if any of the keys or values in `table` match `val`, `false` otherwise

- Parameters:
  - `table` (*`table`*): The table to check
  - `val` (*`any`*): The key/value to check for
- Returns:
  - *`boolean`*: Whether `val` exists in `table` or not

#### `magnify.table_has_pairs(table)  -->  boolean`

Returns `true` if `table` has at least one defined key-value pair, `false` if not, `nil` if `table` is not a table

- Parameters:
  - `table` (*`table`*): The table to check
- Returns:
  - *`boolean`*: Whether `table` contains any defined key-value pairs or not
  *OR*
  - `nil` if `table` is not a table
