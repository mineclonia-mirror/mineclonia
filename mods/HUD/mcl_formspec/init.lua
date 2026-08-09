local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)

local C = core.colorize

mcl_formspec = {}

-- UTF-8 library from modlib
local utf8 = mcl_util.utf8

mcl_formspec.LSM = (1.5/core.settings:get("gui_scaling"))/96 -- Luanti Scaling Minimiser (Minimises Luanti's GUI scaling, but this isn't yet perfect.)
mcl_formspec.MCS = math.round(core.settings:get("gui_scaling")/0.375) -- Minecraft Scaling (For Minecraft-like scaling.)
local LSM = mcl_formspec.LSM -- We do this to prevent "mcl_formspec.set_gui_label" from appearing too messy.
local MCS = mcl_formspec.MCS -- Same thing here as well.

mcl_formspec.label_color = "#313131"

---Get the background of inventory slots (formspec version = 1)
function mcl_formspec.get_itemslot_bg(x, y, w, h)
	local out = ""
	for i = 0, w - 1, 1 do
		for j = 0, h - 1, 1 do
			out = out .. "image[" .. x + i .. "," .. y + j .. ";1,1;mcl_formspec_itemslot.png]"
		end
	end
	return out
end

---This function will replace mcl_formspec.get_itemslot_bg then every formspec will be upgrade to version 4
local function get_slot(x, y, size, texture)
	local t = "image[" .. x - size .. "," .. y - size .. ";" .. 1 + (size * 2) ..
		"," .. 1 + (size * 2) .. ";" .. (texture and texture or "mcl_formspec_itemslot.png") .. "]"
	return t
end

mcl_formspec.itemslot_border_size = 0.05

---Get the background of inventory slots (formspec version > 1)
function mcl_formspec.get_itemslot_bg_v4(x, y, w, h, size, texture)
	if not size then
		size = mcl_formspec.itemslot_border_size
	end
	local out = ""
	for i = 0, w - 1, 1 do
		for j = 0, h - 1, 1 do
			out = out .. get_slot(x + i + (i * 0.25), y + j + (j * 0.25), size, texture)
		end
	end
	return out
end


function mcl_formspec.set_gui_label(x, y, lang, text) -- Function which sets a special kind of label, which is more compatible with Minecraft texture packs.

-- NOTE: The following languages use the regular label system instead of the special one:
--
-- Arabic, Persian, Hindi, Japanese, Kannada, Korean, Lao, Literary Chinese,
-- Tamil, Thai, Simplified Chinese (China), Traditional Chinese (Hong Kong), Traditional Chinese (Taiwan), Malay
--
-- Luanti doesn't support all of them yet, so the below "if" statement only includes those who are.

	if lang == "ja" or lang == "ko" or lang == "zh_CN" or lang == "zh_TW" then -- Use the regular label system if one of these languages is used.
		return "label["..(LSM*x*MCS)..","..(LSM*(y+4.25)*MCS)..";"..C("#404040", text).."]"
	end

-- TODO: Fix issues with specific characters, such as "אַ" and "�".

	local counter = 0 -- Counts up to 16, which should be plenty for almost any use case when it comes to GUI labels.
	local offset =  0 -- Counts up whenever a non-ASCII character is used.

	local c = {"","","","","","","","","","","","","","","",""} -- Characters

	local w = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- Widths
	local h = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- Heights

	local p = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- Previous Kernings (We need to remember how much the previous character was moved by its kerning!)
	local k = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- Kernings

	repeat
		for line in io.lines(modpath .. DIR_DELIM .. "label_characters.tsv") do
			local tsvchar = utf8.codepoint(line:split("\t")[1]) -- The character at the "line"th line and the "[1]"th column of "label_characters.tsv".
			local textchar = utf8.codepoint(text:sub(counter+1,counter+1)) -- The "counter+1"th letter of whatever was inputted for "text".
			local textchartwobyte = utf8.codepoint(text:sub(counter+1,counter+2)) -- Required for characters that are two bytes long.
			local textcharthreebyte = utf8.codepoint(text:sub(counter+1,counter+3)) -- Required for characters that are three bytes long.
			if tsvchar == textchar then
				c[counter-offset] = line:split("\t")[2].."^[colorize:#404040"
				w[counter-offset] = line:split("\t")[3]
				h[counter-offset] = line:split("\t")[4]
				p[counter-offset] = line:split("\t")[5]-(w[counter-offset]-8)+(p[counter-offset-1] or 0)
				k[counter-offset] = p[counter-offset]-line:split("\t")[5]+(w[counter-offset]-8)
				break -- Since we got what we were looking for, we break the "for" loop and reenter the "repeat" loop.
			elseif tsvchar == textchartwobyte then
				c[counter-offset] = line:split("\t")[2].."^[colorize:#404040"
				w[counter-offset] = line:split("\t")[3]
				h[counter-offset] = line:split("\t")[4]
				p[counter-offset] = line:split("\t")[5]-(w[counter-offset]-8)+(p[counter-offset-1] or 0)
				k[counter-offset] = p[counter-offset]-line:split("\t")[5]+(w[counter-offset]-8)
				offset = offset + 1 -- Because non-ASCII characters count as more than 1 character in Lua, we have to increase the offset.
				break -- Since we got what we were looking for, we break the "for" loop and reenter the "repeat" loop.
			elseif tsvchar == textcharthreebyte then
				c[counter-offset] = line:split("\t")[2].."^[colorize:#404040"
				w[counter-offset] = line:split("\t")[3]
				h[counter-offset] = line:split("\t")[4]
				p[counter-offset] = line:split("\t")[5]-(w[counter-offset]-8)+(p[counter-offset-1] or 0)
				k[counter-offset] = p[counter-offset]-line:split("\t")[5]+(w[counter-offset]-8)
				offset = offset + 2 -- Because non-ASCII characters count as more than 1 character in Lua, we have to increase the offset.
				break -- Since we got what we were looking for, we break the "for" loop and reenter the "repeat" loop.
			else end -- Do nothing, end this "if" loop, and go back to the "for" loop.
		end
		counter = counter + 1
	until counter == 16 + offset

	return "image["..(LSM*(x    -k[0]) *MCS)..","..(LSM*(y-(h[0] -w[0])) *MCS)..";"..(LSM*w[0] *MCS)..","..(LSM*h[0] *MCS)..";"..c[0] .."]".. -- 1st character of the label.
		   "image["..(LSM*(x+8  -k[1]) *MCS)..","..(LSM*(y-(h[1] -w[1])) *MCS)..";"..(LSM*w[1] *MCS)..","..(LSM*h[1] *MCS)..";"..c[1] .."]".. -- 2nd character of the label.
		   "image["..(LSM*(x+16 -k[2]) *MCS)..","..(LSM*(y-(h[2] -w[2])) *MCS)..";"..(LSM*w[2] *MCS)..","..(LSM*h[2] *MCS)..";"..c[2] .."]".. -- 3rd character of the label.
		   "image["..(LSM*(x+24 -k[3]) *MCS)..","..(LSM*(y-(h[3] -w[3])) *MCS)..";"..(LSM*w[3] *MCS)..","..(LSM*h[3] *MCS)..";"..c[3] .."]".. -- 4th character of the label.
		   "image["..(LSM*(x+32 -k[4]) *MCS)..","..(LSM*(y-(h[4] -w[4])) *MCS)..";"..(LSM*w[4] *MCS)..","..(LSM*h[4] *MCS)..";"..c[4] .."]".. -- 5th character of the label.
		   "image["..(LSM*(x+40 -k[5]) *MCS)..","..(LSM*(y-(h[5] -w[5])) *MCS)..";"..(LSM*w[5] *MCS)..","..(LSM*h[5] *MCS)..";"..c[5] .."]".. -- 6th character of the label.
		   "image["..(LSM*(x+48 -k[6]) *MCS)..","..(LSM*(y-(h[6] -w[6])) *MCS)..";"..(LSM*w[6] *MCS)..","..(LSM*h[6] *MCS)..";"..c[6] .."]".. -- 7th character of the label.
		   "image["..(LSM*(x+56 -k[7]) *MCS)..","..(LSM*(y-(h[7] -w[7])) *MCS)..";"..(LSM*w[7] *MCS)..","..(LSM*h[7] *MCS)..";"..c[7] .."]".. -- 8th character of the label.
		   "image["..(LSM*(x+64 -k[8]) *MCS)..","..(LSM*(y-(h[8] -w[8])) *MCS)..";"..(LSM*w[8] *MCS)..","..(LSM*h[8] *MCS)..";"..c[8] .."]".. -- 9th character of the label.
		   "image["..(LSM*(x+72 -k[9]) *MCS)..","..(LSM*(y-(h[9] -w[9])) *MCS)..";"..(LSM*w[9] *MCS)..","..(LSM*h[9] *MCS)..";"..c[9] .."]".. -- 10th character of the label.
		   "image["..(LSM*(x+80 -k[10])*MCS)..","..(LSM*(y-(h[10]-w[10]))*MCS)..";"..(LSM*w[10]*MCS)..","..(LSM*h[10]*MCS)..";"..c[10].."]".. -- 11th character of the label.
		   "image["..(LSM*(x+88 -k[11])*MCS)..","..(LSM*(y-(h[11]-w[11]))*MCS)..";"..(LSM*w[11]*MCS)..","..(LSM*h[11]*MCS)..";"..c[11].."]".. -- 12th character of the label.
		   "image["..(LSM*(x+96 -k[12])*MCS)..","..(LSM*(y-(h[12]-w[12]))*MCS)..";"..(LSM*w[12]*MCS)..","..(LSM*h[12]*MCS)..";"..c[12].."]".. -- 13th character of the label.
		   "image["..(LSM*(x+104-k[13])*MCS)..","..(LSM*(y-(h[13]-w[13]))*MCS)..";"..(LSM*w[13]*MCS)..","..(LSM*h[13]*MCS)..";"..c[13].."]".. -- 14th character of the label.
		   "image["..(LSM*(x+112-k[14])*MCS)..","..(LSM*(y-(h[14]-w[14]))*MCS)..";"..(LSM*w[14]*MCS)..","..(LSM*h[14]*MCS)..";"..c[14].."]".. -- 15th character of the label.
		   "image["..(LSM*(x+120-k[15])*MCS)..","..(LSM*(y-(h[15]-w[15]))*MCS)..";"..(LSM*w[15]*MCS)..","..(LSM*h[15]*MCS)..";"..c[15].."]"   -- 16th character of the label.

end