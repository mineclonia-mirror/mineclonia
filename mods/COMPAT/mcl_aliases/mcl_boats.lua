core.register_alias("mcl_boats:boat","mcl_boats:boat_oak")
core.register_alias("mcl_boats:boat_cherry","mcl_boats:boat_cherry_blossom")
core.register_alias("mcl_boats:boat_obsidian","mcl_boats:boat_oak")

local woods = {"oak", "acacia", "birch", "cherry_blossom", "dark_oak", "jungle", "mangrove", "spruce"}
for _, wood in ipairs(woods) do
	local oldwood = (wood == "oak") and "" or (wood == "cherry_blossom") and "_cherry" or "_"..wood
	core.register_alias("mcl_boats:chest_boat"..oldwood,"mcl_boats:boat_"..wood.."_chest")
end
