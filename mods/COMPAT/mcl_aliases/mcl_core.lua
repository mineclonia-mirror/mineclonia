-- legacy: for some reason glass was the only place where grey was spelled with an a
core.register_alias("mcl_core:glass_gray","mcl_core:glass_grey")

-- very obscure legacy API
-- need to prevent mcl_core from accidentally undefining it if this mod loads first
local function f()
	function mcl_core.strip_tree(...)
		mcl_util.log_deprecated_call("warning", "Please read mcl_trees/API.md")
		mcl_trees.strip_tree(...)
	end
end

core.register_on_mods_loaded(f)
