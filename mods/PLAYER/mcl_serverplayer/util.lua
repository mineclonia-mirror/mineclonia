------------------------------------------------------------------------
-- Server-client communication utilities.
------------------------------------------------------------------------

local string_byte = string.byte
local string_char = string.char

local function byte (s, n)
	local b = string_byte (s, n)
	if b then
		return b - 1
	end
	return nil
end

local function char (c)
	return string_char (c + 1)
end

local rshift = bit.rshift
local band = bit.band

local insert = table.insert
local concat = table.concat

local floor = math.floor

local R = 1.0 / 255

local function divrem (dst, v)
	local rem = 0
	local ok = 0
	for i = #dst, 1, -1 do
		local d = dst[i] + rem * 0x100000000
		dst[i] = floor (d * R)
		rem = d - dst[i] * 255
		ok = ok + dst[i]
	end
	return rem, ok == 0
end

local function to_byte_array (dst, list, n)
	local base = #dst
	for i = 1, rshift (n, 2) do
		local value = list[i]
		local b0 = band (value, 0xff)
		local b1 = rshift (band (value, 0xff00), 8)
		local b2 = rshift (band (value, 0xff0000), 16)
		local b3 = rshift (band (value, 0xff000000), 24)
		dst[base + i * 4 - 3] = string_char (b0)
		dst[base + i * 4 - 2] = string_char (b1)
		dst[base + i * 4 - 1] = string_char (b2)
		dst[base + i * 4] = string_char (b3)
	end

	local value = list[rshift (n + 3, 2)]
	local base_1 = band (n, -4)
	for i = base_1, n - 1 do
		local value = band (rshift (value, (i - base_1) * 8),
				    0xff)
		dst[base + i + 1] = string_char (value)
	end
end

function mcl_serverplayer.encode_base255 (str)
	local output, bytes = {}, {}
	local len = #str

	for b = 1, len, 32 do
		-- Encode a full length sequence of 32 bytes into 33.
		if len - b >= 31 then
			for i = 0, 31, 4 do
				local b1 = string_byte (str, b + i)
				local b2 = string_byte (str, b + i + 1)
				local b3 = string_byte (str, b + i + 2)
				local b4 = string_byte (str, b + i + 3)
				local i1 = ((b4 * 256 + b3) * 256 + b2) * 256 + b1
				bytes[rshift (i, 2) + 1] = i1
			end
			local rem, _
			for i = 1, 33 do
				rem, _ = divrem (bytes)
				insert (output, char (rem))
			end
		else
			-- Record the number of bytes remaining to be
			-- encoded and write only as many digits as
			-- are necessary.  A 31-byte sequence may be
			-- represented with no more than 32 digits,
			-- and as the last digit is always 1 or 0 the
			-- number of bytes in this sequence can simply
			-- be recorded there.
			local rem_bytes = len - b + 1

			for i = 0, rem_bytes - 1, 4 do
				local b1 = string_byte (str, b + i)
				local b2 = string_byte (str, b + i + 1) or 0
				local b3 = string_byte (str, b + i + 2) or 0
				local b4 = string_byte (str, b + i + 3) or 0
				local i1 = ((b4 * 256 + b3) * 256 + b2) * 256 + b1
				bytes[rshift (i, 2) + 1] = i1
			end

			for i = rshift (rem_bytes + 3, 2) + 1, 16 do
				bytes[i] = nil
			end

			local rem, ok
			local digits = 0
			repeat
				rem, ok = divrem (bytes)
				insert (output, char (rem))
				digits = digits + 1
			until ok

			-- Whether the last byte contributes to the
			-- value is indicated by whether the first bit
			-- is unset.
			if digits == 32 then
				rem = rem_bytes * 2 + 1
				output[#output] = char (rem)
			else
				insert (output, char (rem_bytes * 2))
			end
		end
	end
	return concat (output)
end

local function mul (dst, v)
	local carry = 0
	for i = 1, #dst do
		local m = dst[i] * v + carry
		carry = floor (m / 0x100000000)
		dst[i] = m % 0x100000000
	end
end

local function add (dst, v)
	local carry = v
	local i = 1
	while carry > 0 do
		local m = dst[i] + carry
		carry = floor (m / 0x100000000)
		dst[i] = m % 0x100000000
		i = i + 1
	end
end

-- Decode STR into the string from which it was produced.  Do not
-- perform any validation on the format of STR itself, so that if STR
-- should be invalid, the string returned will simply be corrupt.
-- This function will signal an error if STR should contain NULL
-- bytes.

function mcl_serverplayer.decode_base255 (str)
	local output, bytes = {}, {}
	local len = #str

	for b = 1, len, 33 do
		-- First, decode 33 digit segments.
		local rem = len - b
		for i = 0, 16 do
			output[i] = 0
		end
		if rem > 31 then
			for i = 32, 1, -4 do
				local b1 = byte (str, b + i - 3)
				local b2 = byte (str, b + i - 2)
				local b3 = byte (str, b + i - 1)
				local b4 = byte (str, b + i)
				local i1 = ((b4 * 255 + b3) * 255 + b2) * 255 + b1
				mul (output, 255 * 255)
				mul (output, 255 * 255)
				add (output, i1)
			end
			mul (output, 255)
			add (output, byte (str, b))
			to_byte_array (bytes, output, 32)
		else
			-- Proceed to decode the last sequence of
			-- digits, which may be 32 bytes in length.
			-- The number of bytes in the sequence is
			-- recorded in the last digit, the second bit
			-- in which indicates whether the first bit is
			-- also a component of the data.
			--
			-- If last_byte_not_data should be invalid
			-- (e.g., where the remaining length of the
			-- data is 0), this loop will simply be
			-- nugatory.

			local last_byte = byte (str, len)
			local last_byte_is_data	= band (last_byte, 1)
			local data_max = len - 1
			local data_len = band (rshift (last_byte, 1), 0x1f)

			if last_byte_is_data ~= 0 then
				output[1] = 1
			end
			for i = data_max, b, -1 do
				mul (output, 255)
				add (output, byte (str, i))
			end

			-- Append the output to the list of bytes.
			to_byte_array (bytes, output, data_len)
		end
	end

	return concat (bytes)
end
