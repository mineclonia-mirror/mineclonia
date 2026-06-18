local byte = string.byte

local bor = bit.bor
local band = bit.band
local lshift = bit.lshift
local rshift = bit.rshift

------------------------------------------------------------------------
-- TGA data decoder.
--
-- mcl_maps has only ever created images in run-length encoded and
-- plain B8G8R8 or A1R5G5B5 formats without interleaving, and as such
-- these are the only formats implemented in this module.
------------------------------------------------------------------------

local function ushort (data, offset)
	return bor (byte (data, offset),
		    lshift (byte (data, offset + 1), 8))
end

local function rgb (data, offset)
	return bor (0xff000000,
		    lshift (byte (data, offset + 2), 16),
		    lshift (byte (data, offset + 1), 8),
		    byte (data, offset))
end

local function get_pixels_fmt_10 (pixels, width, height, data, offset)
	local i = 1

	while i <= width * height do
		local header = byte (data, offset)
		offset = offset + 1
		if rshift (header, 7) == 1 then -- Run length packet.
			local repetitions = band (header, 127)
			local pixel = rgb (data, offset)
			offset = offset + 3
			for k = 0, repetitions do
				pixels[i] = pixel
				i = i + 1
			end
		else -- Raw packet.
			local pixel_cnt = band (header, 127)
			for k = 0, pixel_cnt do
				pixels[i] = rgb (data, offset)
				offset = offset + 3
				i = i + 1
			end
		end
	end

	if i ~= width * height + 1 then
		error ("Image data was truncated or too long: " .. i)
	end
end

local function get_pixels_fmt_2 (pixels, width, height, data, offset)
	if #data - offset + 1 < width * height then
		error ("Image data truncated")
	end
	for i = 1, width * height do
		pixels[i] = rgb (data, offset)
		offset = offset + 3
	end
end

local function expand5 (x)
	x = band (x, 0x1f)
	return bor (lshift (x, 3), rshift (x, 2))
end

local function convert (pixel)
	local r = lshift (expand5 (rshift (pixel, 10)), 16)
	local g = lshift (expand5 (rshift (pixel, 5)), 8)
	local b = expand5 (pixel)
	local a = band (-rshift (pixel, 15), 0xff000000)
	return bor (a, r, g, b)
end

local function get_pixels_fmt_10_16 (pixels, width, height, data, offset)
	local i = 1

	while i <= width * height do
		local header = byte (data, offset)
		offset = offset + 1
		if rshift (header, 7) == 1 then -- Run length packet.
			local repetitions = band (header, 127)
			local raw = ushort (data, offset)
			local pixel = convert (raw)
			offset = offset + 2
			for k = 0, repetitions do
				pixels[i] = pixel
				i = i + 1
			end
		else -- Raw packet.
			local pixel_cnt = band (header, 127)
			for k = 0, pixel_cnt do
				local pixel = ushort (data, offset)
				pixels[i] = convert (pixel)
				offset = offset + 2
				i = i + 1
			end
		end
	end

	if i ~= width * height + 1 then
		error ("Image data was truncated or too long: " .. i)
	end
end

local function get_pixels_fmt_2_16 (pixels, width, height, data, offset)
	if #data - offset + 1 < width * height then
		error ("Image data truncated")
	end
	for i = 1, width * height do
		pixels[i] = convert (ushort (data, offset))
		offset = offset + 2
	end
end

-- No validation of DATA is conducted by this function, which must
-- therefore be protected by `pcall' if it may be provided with
-- invalid data.

function mcl_maps.get_targa_pixels (data)
	local offset = 1

	offset = offset + 1 -- image_id
	local colormap_type = byte (data, offset)
	offset = offset + 1
	local image_type = byte (data, offset)
	offset = offset + 1

	if (image_type ~= 10 and image_type ~= 2)
		or colormap_type ~= 0 then
		error ("Unsupported image type: "
		       .. image_type .. ", " .. colormap_type)
	end

	offset = offset + 2 -- first_entry_index
	offset = offset + 2 -- number_of_entries
	offset = offset + 1 -- bit_per_pixel
	offset = offset + 2 -- x_origin
	offset = offset + 2 -- y_origin

	local width = ushort (data, offset)
	offset = offset + 2
	local height = ushort (data, offset)
	offset = offset + 2
	local pixel_depth = byte (data, offset)
	offset = offset + 1
	offset = offset + 1 -- image_descriptor

	if pixel_depth ~= 24 and pixel_depth ~= 16 then
		error ("Unsupported pixel depth: " .. tostring (pixel_depth))
	end

	local pixels = {}
	for i = 1, width * height do
		pixels[i] = 0
	end
	if pixel_depth == 24 then
		if image_type == 10 then
			get_pixels_fmt_10 (pixels, width, height, data, offset)
			return width, height, pixels
		elseif image_type == 2 then
			get_pixels_fmt_2 (pixels, width, height, data, offset)
			return width, height, pixels
		end
	elseif pixel_depth == 16 then
		if image_type == 10 then
			get_pixels_fmt_10_16 (pixels, width, height, data, offset)
			return width, height, pixels
		elseif image_type == 2 then
			get_pixels_fmt_2_16 (pixels, width, height, data, offset)
			return width, height, pixels
		end
	end
	assert (false)
end
