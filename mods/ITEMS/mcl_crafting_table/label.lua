local LSM = (1.5/core.settings:get("gui_scaling"))/96 -- Luanti Scaling Minimiser (Minimises Luanti's GUI scaling, but this isn't yet perfect.)
local MCS = math.round(core.settings:get("gui_scaling")/0.375) -- Minecraft Scaling (For MClike scaling.)

local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)

function get_gui_label(x, y, text) -- Function which utilises a special font system, one that's more compatible with Minecraft texture packs.

	local counter = 0 -- Counts up to 16, which should be more than enough in any language for this.

	local c = {} -- Character

	local w = {} -- Width
	local h = {} -- Height

	local pk = {} -- Previous Kerning (We need to remember how much the previous character was moved by its kerning!)
	local k = {} -- Kerning

	repeat
		for line in io.lines(modpath .. DIR_DELIM .. "label_characters.tsv") do
			local tsvchar = line:split("\t")[1] -- Whichever character is at the "line"th line and the "[1]"th column of "label_characters.tsv".
			local textchar = text:sub(counter+1):match('(.)') -- Whatever the first character of "text:sub(counter+1)" is.
			if tsvchar == textchar then
				c[counter] = line:split("\t")[2].."^[colorize:#404040"
				w[counter] = line:split("\t")[3]
				h[counter] = line:split("\t")[4]
				pk[counter] = line:split("\t")[5]+(pk[counter-1] or 0)
				k[counter] = pk[counter]-line:split("\t")[5]
				break -- Since we got what we were looking for, we break the "for" loop and reenter the "repeat" loop.
			else -- Otherwise, set the below values in order to avoid "nil" errors, and compare the next "line" of "label_characters.tsv".
				c[counter] = "ascii.png^[sheet:16x16:15,15"
				w[counter] = 0
				h[counter] = 0
				k[counter] = 0
			end
		end
		counter = counter + 1
	until counter == 16

	return "image["..(LSM*(x    -k[0]) *MCS)..","..(LSM*y*MCS)..";"..(LSM*w[0] *MCS)..","..(LSM*h[0] *MCS)..";"..c[0] .."]".. -- 1st character of the label.
		   "image["..(LSM*(x+8  -k[1]) *MCS)..","..(LSM*y*MCS)..";"..(LSM*w[1] *MCS)..","..(LSM*h[1] *MCS)..";"..c[1] .."]".. -- 2nd character of the label.
		   "image["..(LSM*(x+16 -k[2]) *MCS)..","..(LSM*y*MCS)..";"..(LSM*w[2] *MCS)..","..(LSM*h[2] *MCS)..";"..c[2] .."]".. -- 3rd character of the label.
		   "image["..(LSM*(x+24 -k[3]) *MCS)..","..(LSM*y*MCS)..";"..(LSM*w[3] *MCS)..","..(LSM*h[3] *MCS)..";"..c[3] .."]".. -- 4th character of the label.
		   "image["..(LSM*(x+32 -k[4]) *MCS)..","..(LSM*y*MCS)..";"..(LSM*w[4] *MCS)..","..(LSM*h[4] *MCS)..";"..c[4] .."]".. -- 5th character of the label.
		   "image["..(LSM*(x+40 -k[5]) *MCS)..","..(LSM*y*MCS)..";"..(LSM*w[5] *MCS)..","..(LSM*h[5] *MCS)..";"..c[5] .."]".. -- 6th character of the label.
		   "image["..(LSM*(x+48 -k[6]) *MCS)..","..(LSM*y*MCS)..";"..(LSM*w[6] *MCS)..","..(LSM*h[6] *MCS)..";"..c[6] .."]".. -- 7th character of the label.
		   "image["..(LSM*(x+56 -k[7]) *MCS)..","..(LSM*y*MCS)..";"..(LSM*w[7] *MCS)..","..(LSM*h[7] *MCS)..";"..c[7] .."]".. -- 8th character of the label.
		   "image["..(LSM*(x+64 -k[8]) *MCS)..","..(LSM*y*MCS)..";"..(LSM*w[8] *MCS)..","..(LSM*h[8] *MCS)..";"..c[8] .."]".. -- 9th character of the label.
		   "image["..(LSM*(x+72 -k[9]) *MCS)..","..(LSM*y*MCS)..";"..(LSM*w[9] *MCS)..","..(LSM*h[9] *MCS)..";"..c[9] .."]".. -- 10th character of the label.
		   "image["..(LSM*(x+80 -k[10])*MCS)..","..(LSM*y*MCS)..";"..(LSM*w[10]*MCS)..","..(LSM*h[10]*MCS)..";"..c[10].."]".. -- 11th character of the label.
		   "image["..(LSM*(x+88 -k[11])*MCS)..","..(LSM*y*MCS)..";"..(LSM*w[11]*MCS)..","..(LSM*h[11]*MCS)..";"..c[11].."]".. -- 12th character of the label.
		   "image["..(LSM*(x+96 -k[12])*MCS)..","..(LSM*y*MCS)..";"..(LSM*w[12]*MCS)..","..(LSM*h[12]*MCS)..";"..c[12].."]".. -- 13th character of the label.
		   "image["..(LSM*(x+104-k[13])*MCS)..","..(LSM*y*MCS)..";"..(LSM*w[13]*MCS)..","..(LSM*h[13]*MCS)..";"..c[13].."]".. -- 14th character of the label.
		   "image["..(LSM*(x+112-k[14])*MCS)..","..(LSM*y*MCS)..";"..(LSM*w[14]*MCS)..","..(LSM*h[14]*MCS)..";"..c[14].."]".. -- 15th character of the label.
		   "image["..(LSM*(x+120-k[15])*MCS)..","..(LSM*y*MCS)..";"..(LSM*w[15]*MCS)..","..(LSM*h[15]*MCS)..";"..c[15].."]"   -- 16th character of the label.

end