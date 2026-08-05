local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)

function get_gui_label(x, y, text) -- Function which utilises a font system more compatible with Minecraft texture packs.

	local counter = 0 -- Counts up to 16, which should be more than enough in any language for this.

	local l = {} -- Letter

	local w = {} -- Width
	local h = {} -- Height

	local k1 = {} -- Kerning 1
	local k2 = {} -- Kerning 2

	repeat
		for line in io.lines(modpath .. DIR_DELIM .. "label_characters.tsv") do
			local tsvletter = line:split("\t")[1]
			local newtext = text:sub(counter+1)
			local newtextletter = newtext:match('(.)')
			local newkern = line:split("\t")[5]
			if tsvletter == newtextletter then
				l[counter] = line:split("\t")[2].."^[colorize:#404040"
				w[counter] = line:split("\t")[3]
				h[counter] = line:split("\t")[4]
				k1[counter] = line:split("\t")[5]+(k1[counter-1] or 0)
				k2[counter] = line:split("\t")[5]
				core.log(tsvletter)
				break
			else
				l[counter] = "ascii.png^[sheet:16x16:15,15"
				w[counter] = 0
				h[counter] = 0
				k1[counter] = 0
				k2[counter] = 0
			end
		end
		counter = counter + 1
	until counter == 16

	return "image["..(LSM*(x)*MCS)                  ..","..(LSM*y*MCS)..";"..(LSM*w[0]*MCS) ..","..(LSM*h[0]*MCS) ..";"..l[0] .."]".. -- 1st letter of the label.
		   "image["..(LSM*(x+8-  k1[1] +k2[1])*MCS) ..","..(LSM*y*MCS)..";"..(LSM*w[1]*MCS) ..","..(LSM*h[1]*MCS) ..";"..l[1] .."]".. -- 2nd letter of the label.
		   "image["..(LSM*(x+16- k1[2] +k2[2])*MCS) ..","..(LSM*y*MCS)..";"..(LSM*w[2]*MCS) ..","..(LSM*h[2]*MCS) ..";"..l[2] .."]".. -- 3rd letter of the label.
		   "image["..(LSM*(x+24- k1[3] +k2[3])*MCS) ..","..(LSM*y*MCS)..";"..(LSM*w[3]*MCS) ..","..(LSM*h[3]*MCS) ..";"..l[3] .."]".. -- 4th letter of the label.
		   "image["..(LSM*(x+32- k1[4] +k2[4])*MCS) ..","..(LSM*y*MCS)..";"..(LSM*w[4]*MCS) ..","..(LSM*h[4]*MCS) ..";"..l[4] .."]".. -- 5th letter of the label.
		   "image["..(LSM*(x+40- k1[5] +k2[5])*MCS) ..","..(LSM*y*MCS)..";"..(LSM*w[5]*MCS) ..","..(LSM*h[5]*MCS) ..";"..l[5] .."]".. -- 6th letter of the label.
		   "image["..(LSM*(x+48- k1[6] +k2[6])*MCS) ..","..(LSM*y*MCS)..";"..(LSM*w[6]*MCS) ..","..(LSM*h[6]*MCS) ..";"..l[6] .."]".. -- 7th letter of the label.
		   "image["..(LSM*(x+56- k1[7] +k2[7])*MCS) ..","..(LSM*y*MCS)..";"..(LSM*w[7]*MCS) ..","..(LSM*h[7]*MCS) ..";"..l[7] .."]".. -- 8th letter of the label.
		   "image["..(LSM*(x+64- k1[8] +k2[8])*MCS) ..","..(LSM*y*MCS)..";"..(LSM*w[8]*MCS) ..","..(LSM*h[8]*MCS) ..";"..l[8] .."]".. -- 9th letter of the label.
		   "image["..(LSM*(x+72- k1[9] +k2[9])*MCS) ..","..(LSM*y*MCS)..";"..(LSM*w[9]*MCS) ..","..(LSM*h[9]*MCS) ..";"..l[9] .."]".. -- 10th letter of the label.
		   "image["..(LSM*(x+80- k1[10]+k2[10])*MCS)..","..(LSM*y*MCS)..";"..(LSM*w[10]*MCS)..","..(LSM*h[10]*MCS)..";"..l[10].."]".. -- 11th letter of the label.
		   "image["..(LSM*(x+88- k1[11]+k2[11])*MCS)..","..(LSM*y*MCS)..";"..(LSM*w[11]*MCS)..","..(LSM*h[11]*MCS)..";"..l[11].."]".. -- 12th letter of the label.
		   "image["..(LSM*(x+96- k1[12]+k2[12])*MCS)..","..(LSM*y*MCS)..";"..(LSM*w[12]*MCS)..","..(LSM*h[12]*MCS)..";"..l[12].."]".. -- 13th letter of the label.
		   "image["..(LSM*(x+104-k1[13]+k2[13])*MCS)..","..(LSM*y*MCS)..";"..(LSM*w[13]*MCS)..","..(LSM*h[13]*MCS)..";"..l[13].."]".. -- 14th letter of the label.
		   "image["..(LSM*(x+112-k1[14]+k2[14])*MCS)..","..(LSM*y*MCS)..";"..(LSM*w[14]*MCS)..","..(LSM*h[14]*MCS)..";"..l[14].."]".. -- 15th letter of the label.
		   "image["..(LSM*(x+120-k1[15]+k2[15])*MCS)..","..(LSM*y*MCS)..";"..(LSM*w[15]*MCS)..","..(LSM*h[15]*MCS)..";"..l[15].."]"   -- 16th letter of the label.

end