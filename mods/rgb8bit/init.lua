---This mod provides support for 8-bit RGB color mapping using hardware coloring.
---In order to achieve 8-bit RGB color space, 3-bits are used for Red and Green and 2-bits are used for Blue.
---This is known as a 3-3-2 bit RGB palette.
---The rgb8bit:rgb8bit node that is registered contains ordered positions of all 256 unique colors.
---A unique color is retrieved from the palette by supplying an 8-bit integer index via param2.

rgb8bit = {}

minetest.register_node("rgb8bit:rgb8bit", {
    inventory_image = "rgb8bit_palette.png",
    wield_image = "rgb8bit_palette.png",
    groups = {oddly_breakable_by_hand = 1, ud_param2_colorable=1},
    tiles = {"rgb8bit_template.png"},
    paramtype2 = "color",
    palette = "rgb8bit_palette.png",
})

---This function is used to convert any integer into a 3-bit integer
---Use this function to rescale values for the Red and Green color channels
---@param value Integer value to convert
---@param min_value The minimum value of the integer range
---@param max_value The maximum value of the integer range
---@return value scaled to 3-bits
function rgb8bit.map_value_to_3_bits(value, min_value, max_value)
    value = math.max(min_value, math.min(max_value, value))
    local range = max_value - min_value
    local scaled_value = math.floor((value - min_value) / range * 7.999)
    return scaled_value
end

---This function is used to convert any integer into a 2-bit integer 
---Use this function to rescale values for the Blue color channel only
---@param value Integer value to convert
---@param min_value The minimum value of the integer range
---@param max_value The maximum value of the integer range
---@return value scaled to 2-bits
function rgb8bit.map_value_to_2_bits(value, min_value, max_value)
    value = math.max(min_value, math.min(max_value, value))
    local range = max_value - min_value
    local scaled_value = math.floor((value - min_value) / range * 3.999)
    return scaled_value
end

---This function is used to get the index position of a 3-3-2 bit RGB color in the rgb8bit palette
---Use this function to assign the index as the param2 value for a rgb8bit node
---@param red The 3-bit red value
---@param green The 3-bit green value
---@param blue The 2-bit blue value
---@return index or param2 value for the rgb8bit palette
function rgb8bit.get_palette_index_from_rgb(red, green, blue)
    return red + (green * 8) + (blue * 64)
end