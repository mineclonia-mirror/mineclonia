function get_gui_label(x, y, text)
-- WARNING: This isn't the best way to do this, but I just wanted to show that
-- it's indeed possible to support multiple languages with this new GUI system.
-- I could probably get some inspiration from the way that mcl_signs works, in order to streamline this...
	if text == "Crafting" then
		if core.settings:get("language") == "en" then -- English
			return "image["..(LSN*(x)*MCS)   ..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:3,4" .."]".. -- C
				   "image["..(LSN*(x+6)*MCS) ..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:2,7" .."]".. -- r
				   "image["..(LSN*(x+12)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:1,6" .."]".. -- a
				   "image["..(LSN*(x+18)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:6,6" .."]".. -- f
				   "image["..(LSN*(x+23)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:4,7" .."]".. -- t
				   "image["..(LSN*(x+27)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:9,6" .."]".. -- i
				   "image["..(LSN*(x+29)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:14,6".."]".. -- n
				   "image["..(LSN*(x+35)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:7,6" .."]"   -- g
		elseif core.settings:get("language") == "es" then -- Spanish
			return "image["..(LSN*(x)*MCS)   ..","..(LSN*y*MCS)    ..";"..(LSN*8*MCS)..","..(LSN*8*MCS) ..";".."ascii.png"   .."^[colorize:#404040^[sheet:16x16:6,4"  .."]".. -- F
				   "image["..(LSN*(x+6)*MCS) ..","..(LSN*y*MCS)    ..";"..(LSN*8*MCS)..","..(LSN*8*MCS) ..";".."ascii.png"   .."^[colorize:#404040^[sheet:16x16:1,6"  .."]".. -- a
				   "image["..(LSN*(x+12)*MCS)..","..(LSN*y*MCS)    ..";"..(LSN*8*MCS)..","..(LSN*8*MCS) ..";".."ascii.png"   .."^[colorize:#404040^[sheet:16x16:2,6"  .."]".. -- b
				   "image["..(LSN*(x+18)*MCS)..","..(LSN*y*MCS)    ..";"..(LSN*8*MCS)..","..(LSN*8*MCS) ..";".."ascii.png"   .."^[colorize:#404040^[sheet:16x16:2,7"  .."]".. -- r
				   "image["..(LSN*(x+24)*MCS)..","..(LSN*y*MCS)    ..";"..(LSN*8*MCS)..","..(LSN*8*MCS) ..";".."ascii.png"   .."^[colorize:#404040^[sheet:16x16:9,6"  .."]".. -- i
				   "image["..(LSN*(x+26)*MCS)..","..(LSN*y*MCS)    ..";"..(LSN*8*MCS)..","..(LSN*8*MCS) ..";".."ascii.png"   .."^[colorize:#404040^[sheet:16x16:3,6"  .."]".. -- c
				   "image["..(LSN*(x+32)*MCS)..","..(LSN*y*MCS)    ..";"..(LSN*8*MCS)..","..(LSN*8*MCS) ..";".."ascii.png"   .."^[colorize:#404040^[sheet:16x16:1,6"  .."]".. -- a
				   "image["..(LSN*(x+38)*MCS)..","..(LSN*y*MCS)    ..";"..(LSN*8*MCS)..","..(LSN*8*MCS) ..";".."ascii.png"   .."^[colorize:#404040^[sheet:16x16:3,6"  .."]".. -- c
				   "image["..(LSN*(x+44)*MCS)..","..(LSN*y*MCS)    ..";"..(LSN*8*MCS)..","..(LSN*8*MCS) ..";".."ascii.png"   .."^[colorize:#404040^[sheet:16x16:9,6"  .."]".. -- i
				   "image["..(LSN*(x+46)*MCS)..","..(LSN*(y-3)*MCS)..";"..(LSN*9*MCS)..","..(LSN*12*MCS)..";".."accented.png".."^[colorize:#404040^[sheet:16x75:10,12".."]".. -- ó
				   "image["..(LSN*(x+52)*MCS)..","..(LSN*y*MCS)    ..";"..(LSN*8*MCS)..","..(LSN*8*MCS) ..";".."ascii.png"   .."^[colorize:#404040^[sheet:16x16:14,6" .."]"   -- n
		else -- Fallback to English.
			core.log("error", "Language unknown or not yet supported! Using English as a fallback language.")
			return "image["..(LSN*(x)*MCS)   ..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:3,4" .."]".. -- C
				   "image["..(LSN*(x+6)*MCS) ..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:2,7" .."]".. -- r
				   "image["..(LSN*(x+12)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:1,6" .."]".. -- a
				   "image["..(LSN*(x+18)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:6,6" .."]".. -- f
				   "image["..(LSN*(x+23)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:4,7" .."]".. -- t
				   "image["..(LSN*(x+27)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:9,6" .."]".. -- i
				   "image["..(LSN*(x+29)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:14,6".."]".. -- n
				   "image["..(LSN*(x+35)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:7,6" .."]"   -- g
		end
	elseif text == "Inventory" then
		if core.settings:get("language") == "en" then -- English
			return "image["..(LSN*(x)*MCS)   ..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:9,4" .."]".. -- I
				   "image["..(LSN*(x+4)*MCS) ..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:14,6".."]".. -- n
				   "image["..(LSN*(x+10)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:6,7" .."]".. -- v
				   "image["..(LSN*(x+16)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:5,6" .."]".. -- e
				   "image["..(LSN*(x+22)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:14,6".."]".. -- n
				   "image["..(LSN*(x+28)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:4,7" .."]".. -- t
				   "image["..(LSN*(x+32)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:15,6".."]".. -- o
				   "image["..(LSN*(x+38)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:2,7" .."]".. -- r
				   "image["..(LSN*(x+44)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:9,7" .."]"   -- y
		elseif core.settings:get("language") == "es" then -- Spanish
			return "image["..(LSN*(x)*MCS)   ..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:9,4" .."]".. -- I
				   "image["..(LSN*(x+4)*MCS) ..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:14,6".."]".. -- n
				   "image["..(LSN*(x+10)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:6,7" .."]".. -- v
				   "image["..(LSN*(x+16)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:5,6" .."]".. -- e
				   "image["..(LSN*(x+22)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:14,6".."]".. -- n
				   "image["..(LSN*(x+28)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:4,7" .."]".. -- t
				   "image["..(LSN*(x+32)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:1,6" .."]".. -- a
				   "image["..(LSN*(x+38)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:2,7" .."]".. -- r
				   "image["..(LSN*(x+44)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:9,6" .."]".. -- i
				   "image["..(LSN*(x+46)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:15,6".."]"   -- o
		else -- Fallback to English.
			core.log("error", "Language unknown or not yet supported! Using English as a fallback language.")
			return "image["..(LSN*(x)*MCS)   ..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:9,4" .."]".. -- I
				   "image["..(LSN*(x+4)*MCS) ..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:14,6".."]".. -- n
				   "image["..(LSN*(x+10)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:6,7" .."]".. -- v
				   "image["..(LSN*(x+16)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:5,6" .."]".. -- e
				   "image["..(LSN*(x+22)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:14,6".."]".. -- n
				   "image["..(LSN*(x+28)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:4,7" .."]".. -- t
				   "image["..(LSN*(x+32)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:15,6".."]".. -- o
				   "image["..(LSN*(x+38)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:2,7" .."]".. -- r
				   "image["..(LSN*(x+44)*MCS)..","..(LSN*y*MCS)..";"..(LSN*8*MCS)..","..(LSN*8*MCS)..";".."ascii.png^[colorize:#404040^[sheet:16x16:9,7" .."]"   -- y
		end
	end
end