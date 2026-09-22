local walls = {
	"mcl_walls:andesite",
	"mcl_walls:brick",
	"mcl_walls:cobble",
	"mcl_walls:diorite",
	"mcl_walls:endbricks",
	"mcl_walls:granite",
	"mcl_walls:mossycobble",
	"mcl_walls:mudbrick",
	"mcl_walls:netherbrick",
	"mcl_walls:prismarine",
	"mcl_walls:rednetherbrick",
	"mcl_walls:redsandstone",
	"mcl_walls:sandstone",
	"mcl_walls:stonebrick",
	"mcl_walls:stonebrickmossy",
	"mcl_pale_oak:resinbrick",
	"mcl_blackstone:wall",
	"mcl_blackstone:polishedwall",
	"mcl_blackstone:polishedbrickwall",
	"mcl_deepslate:deepslatebrickswall",
	"mcl_deepslate:deepslatecobbledwall",
	"mcl_deepslate:deepslatepolishedwall",
	"mcl_deepslate:deepslatetileswall",
	"mcl_deepslate:tuffwall",
	"mcl_deepslate:tuffbrickswall",
	"mcl_deepslate:tuffpolishedwall",
}

for _, name in ipairs(walls) do
	for i = 0, 16 do
		core.register_alias(name.."_"..tostring(i), name.."_short_pillar")
	end
	core.register_alias(name.."_21", name.."_short_pillar")
	core.register_alias(name, name.."_short_pillar")
end
