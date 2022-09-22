# Real Terrain (v.0.2.1)
A Minetest mod that brings real world terrain into the game (using freely available DEM tiles). Any image can actually be used which allows for WorldPainter-style map creation using any paint program. This is a lightweight version of [bobombolo's realterrain](https://github.com/bobombolo/realterrain) mod, focusing on map generation from bitmap raster images only. 

![island-demo](https://user-images.githubusercontent.com/7158003/99186052-9b54e600-2788-11eb-8a8d-07e635942855.jpg)

### Dependencies:
- this mod works out of the box with no libraries when using color BMP rasters
- mod security needs to be disabled (close Minetest and add **secure.enable_security = false** to minetest.config)

### Mod Instructions
- download the zip file and copy the realterrain folder to /minetest/mods/ (remove **-master** suffix)
- edit the mod settings.lua file to suit your tastes (not required, default settings should work)
- launch Minetest, create a new world, enable mod and launch game to load the demo
- optionally use chat command **/generate** in game to generate all nodes defined by the DEM raster
- once map is generated from raster images, disable mod and the Minetest engine will generate the rest

### Custom Map Instructions
- use any image editing software to "paint" a custom world on two BMP files (dem.bmp and biomes.bmp)
- using gray tones is recommended, but image should be saved as RGB with 24-bit depth and Windows headers
- ensure that dem and biomes images are the same dimensions (however only dem image is required)
- dem.bmp is converted to an 8-bit heightmap with elevation range from 0 (black) to 255 (white)
- biomes.bmp is likewise read as 8-bit with pixel values rounded to one of 17 biome definitions.

![heightmap-figure](https://user-images.githubusercontent.com/7158003/95472234-5b465a80-09b5-11eb-8bbe-d0ea1f79dc14.png)
 
### Biome Definitions

Biomes are defined in settings.lua and are represented by one of 17 values between 0 and 255, and 3 extra values for hard-coded biome definitions. Using the following color values in biomes.bmp will result in the corresponding biome:

8-Bit Value | Hex Color | Biome
| ------    | ------    | ------
| 0         | #000000   | Lake / Pond
| 16        | #101010   | Beach
| 32        | #202020   | Grassland
| 48        | #303030   | Bushland
| 64        | #404040   | New Deciduous Forest
| 80        | #505050   | Old Deciduous Forest
| 96        | #606060   | New Coniferous Forest
| 112       | #707070   | Old Coniferous Forest
| 128       | #808080   | Savannah
| 144       | #909090   | Desert
| 160       | #A0A0A0   | Marsh
| 176       | #B0B0B0   | Tropical Rainforest
| 192       | #C0C0C0   | Snowy Grassland
| 208       | #D0D0D0   | Tundra
| 224       | #E0E0E0   | Boreal Forest / Tiaga
| 240       | #F0F0F0   | River / Stream
| 255       | #FFFFFF   | Cobblestone Road
| 256       | N/A       | Ocean
| 257       | N/A       | Alpine
| 258       | N/A       | Sub-alpine

![biomes-figure](https://user-images.githubusercontent.com/7158003/98916253-e612fb80-2505-11eb-985a-0ae59e677134.jpg)

Information about DEM files can be found on the repo this was forked from.

Changelog

0.2
- Added Minetest Game 5.4.0 biomes to the schems folder, moved old ones to old_schems folder
- Set up new biomes to work

0.1
- Changed settings.lua and init.lua to remove errors
- Added two maps of my own
