for name, _ in pairs({table.merge(mcl_dyes.colors, {["bar"] = 1, ["natural"] = 1}) }) do
	local pane = name == "bar" and "" or "pane_"
	local oldname = name == "grey" and "gray" or name
	core.register_alias("xpanes:"..pane..oldname, "mcl_panes:"..pane..name)
	core.register_alias("xpanes:"..pane..oldname.."_flat", "mcl_panes:"..pane..name.."_flat")
end
