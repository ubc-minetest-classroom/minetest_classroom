imageloader = {}
local types = {}
local bmp_meta = {}

function imageloader.register_type(def)
	types[#types + 1] = def
end

local function find_loader(filename)
	for _,def in ipairs(types) do
		local r = def.check(filename)
		if r then
			return def
		end
	end
	return nil, "imageloader: unknown file type"
end

function imageloader.load(filename)
	local def, e = find_loader(filename)
	if not def then return nil, e end
	if e then print(e) end
	local r, e = def.load(filename)
	if r then
		r = setmetatable(r, bmp_meta)
	end
	return r, e
end

function imageloader.type(filename)
	local def, e = find_loader(filename)
	if not def then return nil, e end
	return def.description
end