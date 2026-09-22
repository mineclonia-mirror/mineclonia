-- Aliases for mcl_supplemental
for _, n in ipairs({
	"red_nether_brick_fence",
	"nether_brick_fence_gate",
	"nether_brick_fence_gate_open",
	"red_nether_brick_fence_gate",
	"red_nether_brick_fence_gate_open"
}) do
	core.register_alias("mcl_supplemental:"..n, "mclx_fences:"..n)
end
