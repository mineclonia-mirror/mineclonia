# Contributing to Mineclonia

So you want to contribute to Mineclonia? Wow, thank you! :-)

Mineclonia is maintained by ryvnf and cora. You can contact them via our Discord or Matrix (see "Useful links" section in the [README](README.md)).

If you wish to report a bug or suggest a feature, use [our Codeberg repo](https://codeberg.org/mineclonia/mineclonia) for this by opening an issue. If you're unfamiliar with the process, you can read the following Wiki articles for help:

* [Reporting bugs](https://mineclonia.codeberg.page/wiki/guides/reporting-bugs.html)
* [Suggesting features](https://mineclonia.codeberg.page/wiki/guides/suggesting-features.html)

You can translate Mineclonia into your language by using [our Weblate](https://translate.codeberg.org/engage/mineclonia/).

The rest of this document describes how to contribute as a programmer or an artist.

## Inclusion Criteria

**By submitting any code changes to the game, you acknowledge that they are made available under the [GNU GPLv3](LICENSE.txt), a free/libre software license.** See also: [`LEGAL.md`](LEGAL.md).

The project goals are listed under the project description in the README. Contributions that do not align with the project goals will not be accepted. The main goal of Mineclonia is to be a stable and performant clone of Minecraft. We suggest using the [Minecraft Wiki](https://minecraft.wiki/w/Minecraft_Wiki) as a reference when implementing new features.

While Mineclonia primarily aims to replicate Minecraft gameplay, contributions with minor deviations may still be accepted. These deviations should be motivated by either Luanti engine limitations or other technical difficulties in replicating Minecraft behaviour. The addition of bonus features not found in Minecraft will generally not be accepted. In most cases, we will suggest implementing such features as a separate mod, since Mineclonia supports modding.

Contributions that fix bugs or complete unfinished features are always welcome. Contributions implementing Minecraft features that are not yet present in Mineclonia are also welcome, but they should be complete before being merged.

Assets such as sounds and textures must come from sources that permit their use (i.e. under free licenses like CC0, CC BY, CC BY-SA). We generally prefer to use textures from [Pixel Perfection](https://www.minecraftforum.net/forums/mapping-and-modding-java-edition/resource-packs/1242533-pixel-perfection-now-with-polar-bears-1-11) when available. Textures from [Pixel Perfection Legacy](https://modrinth.com/resourcepack/pixel-perfection-legacy) are generally welcome, but they have to be checked beforehand because some of them are derived from Minecraft's textures, making them unusable.

The main repository focuses on code changes, which means that replacing textures that already look good is a low priority. Mineclonia has an official texture pack called [Pixel ImPerfection](https://codeberg.org/mineclonia/pixel_imperfection) which aims to provide textures more similar to Minecraft. We generally ask people who want to contribute textures to do so there instead. Sometimes we will cherry-pick textures from there to the main repo if they are big improvements over the current ones. Pixel ImPerfection is maintained by bramaudi.

Mineclonia has a minimum supported Luanti version, defined in [`game.conf`](game.conf). When making contributions, avoid relying on engine features which are not available in this version. If you believe compatibility should be dropped in order to use newer engine features, open an issue first so it can be discussed.

## Review Guidelines

* Legitimate review questions must be answered by the author. "Just read the code" is not an acceptable answer.
* Reviewers are expected to ask questions respectfully.
* It is also on the author and anyone participating not to react in a disrespectful manner; all participants are responsible for an escalating spiral. Remember that respect is conveyed primarily through what is said, not just how it is said.
* Before escalating an already heated discussion, bring the issue to a maintainer who will then try to isolate the factual points.
* There is no guarantee that any PR will be merged. If a PR introduces technical decisions that have not been discussed or agreed upon, the author must expect and be ready to change them if another approach is preferred. It is much better to discuss these in an issue before committing to any particular solution.

## Git Guidelines

* Create one branch and one pull request (PR) for each change or related set of changes.
* Name your branches in kebab-case using up to four words (fewer is better), e.g. `fix-endermen-eat-sand`. Common abbreviations are fine, e.g. `fix-fn-calls` ("fn" for *function*).
* Whether you're working from a fork or in the main repo, always push your work to a separate branch. Rebase that branch onto `mineclonia:main`, and target `mineclonia:main` when opening your PR.
* If a commit contains changes that are only loosely related, split them into separate commits. Each commit should contain one logical change.
* Keep commit and PR titles between 50 and 70 characters where practical. Put additional details in the commit message or PR description.
* Use technical language in commit messages and the PR description, but keep the PR title natural and user-facing. For example, describe the user-visible problem in the PR title ("Fix endermen eating sand"), and describe the implementation in the commit message ("Exclude sand from endermen's digestibles list").

## Code Guidelines

Derived from [Luanti's Lua code style guidelines](https://docs.luanti.org/for-engine-devs/lua-code-style-guidelines/) and (for one point under "Spaces, lines, and indentation") [VoxeLibre's Code Guidelines](https://git.minetest.land/VoxeLibre/VoxeLibre/src/branch/master/CONTRIBUTING.md#code-guidelines).

### Mods

* Mod names use `snake_case`, and newly added mods start with `mcl_`, e.g. `mcl_core`, `mcl_farming`, `mcl_monster_eggs`.

* Each mod must provide a [`mod.conf`](https://api.luanti.org/mods/#modconf).

* If a mod exposes an API for other mods, include an `API.md` documenting it. A `README.md` is also welcome, but optional.

* Unless the mod includes its own `LICENSE` file or specifies different licensing terms in its README, the mod has the same licensing as the overall project: GNU GPLv3 for code and CC BY-SA 4.0 for media.

* A mod may declare hard dependencies (`depends` field in `mod.conf`) when it requires another Mineclonia mod's API or registered content. Otherwise, prefer soft dependencies (`optional_depends`) for modularity.

* Mods must not depend, optionally or otherwise, on other mods external to Mineclonia. If you want your external mod to get integrated with a Mineclonia mod, use or add an API for that. [rubenwardy's "Intro to Clean Architectures"](https://rubenwardy.com/minetest_modding_book/en/quality/clean_arch.html) provides useful guidance on designing good mod APIs!

### General

* Function and variable names are snake_case, e.g. `my_function` rather than `MyFunction`.

* Use the modern Luanti API, e.g. no usage of `minetest.env`. Prefer `core` over `minetest`, except in files that already use the older global name.

* Avoid globals whenever possible. Declare everything `local` unless it is intended to be part of the public API. To export functions and variables, store them inside a global table named like the mod, e.g.

```lua
mcl_example = {}
mcl_example.some_variable = 5
function mcl_example.do_something()
end
```

* Do not use semicolons to separate statements, and do not put multiple statements on the same line.

### Spaces, lines, and indentation

* Use hard tabs for indentation and spaces for alignment, e.g.

```lua
for i = 1, 10 do
	if i % 3 == 0 then
		print(i)
	end
end

some_table = {
	{"a string",                   5},
	{"a very much longer string", 10},
}
```

* Use double indentation when splitting long conditions across multiple lines. When breaking around a binary operator you should break after the operator. Don't put  `then`  on its own line. Example:

```lua
if some_very_long_variable_name and some_very_long_function_name(x) or
		another_very_long_function_name(x) then
	do_something()
end
```

* Short conditionals and loops may be written on one line, e.g.

```lua
-- bad
if foo then return foo elseif bar then return bar end

-- good
if     foo then return foo
elseif bar then return bar
end

-- also good
if foo then
	return foo
elseif bar then
	return bar
end
```

* Don't compare values explicitly to `true`,  `false`, or `nil`, unless doing so is necessary, e.g.

```lua
local f, err = io.open(filename, "r")

-- bad
if f == nil then return err end

-- good
if not f then return err end

-- reasonable
local could_be_nil_or_false = false
if could_be_nil_or_false == nil then end
```

* Don't use parentheses unless they improve readability, e.g.
    
```lua
-- bad
if (not x) then end

-- good
if (x and y or z) or (a and b or c) then end
```

* Spaces are not used around parentheses, brackets, or curly braces, and do not appear at line endings. Empty lines do not come after conditional, looping, or function opening statements, and do not contain white-space. Example:

```lua
-- bad
local function do_something()
						
	if x then 
		
		bar ( )
	end 
end

-- good
local function do_something()
	if x then
		bar()
	end
end
```

### Functions

* Define exported module functions using `.` rather than `:`. Reserve the `:` syntax for APIs that receive a `self` parameter, such as entity callbacks. Example:

```lua
-- bad
function mcl_example:do_something()
end

-- good
function mcl_example.do_something()
end

-- reasonable
function an_entity_def_table:on_step(...) -- Luanti will call this with `self`
end
```

* Don't assign anonymous functions to variables unless the function is selected conditionally, e.g.

```lua
-- bad
local some_local_func = function()
end

my_mod.some_func = function()
end

-- good
local function some_local_func()
end

function my_mod.some_func()
end

-- reasonable
local some_local_func
if core.features.foo_bar then
	some_local_func = function() end
else
	some_local_func = function() end
end

mymod.some_func = core.features.foo_bar and function()
	-- ... (used if core.features.foo_bar is truthy)
end or function()
	-- ... (used otherwise)
end
```

### Tables

* Do not mix list-style tables (indexed by integer) and dictionary-style tables (indexed by anything else, but normally strings), e.g.

```lua
-- bad
local tbl = {"banana", "apple", vegetable = "potato"}

-- good
local fruits = {"banana", "apple"} 
```

* Small tables may be placed on one line. Large tables should place one entry per line, with the opening and closing braces on lines without items, and with a comma after the last item, e.g.

```lua
local foo = {bar = true}
foo = {
	bar = 0,
	biz = 1,
	baz = 2,
}
```

* In list-style tables where each element is short, multiple elements are placed on each line. Example:

```lua
local first_eight_letters = {
	"a", "b", "c", "d",
	"e", "f", "g", "h",
}
```

* Use `ipairs` to iterate list-style tables, and use `pairs` to iterate dictionary-style tables.

* Use `table.insert` to append and `table.remove` to remove items from list-style tables.

* Use syntactic sugar where possible. Write `{name = value}` instead of `{["name"] = value}`. Write `t.name` instead of `t["name"]`.

### Strings

* Use double-quoted strings (`"..."`) by default. You may use single-quoted strings (`'...'`) to save some escapes.

* Use "method"-style to call  `string.*` functions except `string.char` and `string.format`, e.g. `s:find("creeper")` instead of `string.find(s, "creeper")`.

* Use  `#s`  (instead of  `s:len()`) to get the length of a string.

* Use `"number: " .. num` and `table.concat({"number: ", num})` when combining strings and numbers without applying `tostring` to numbers beforehand.

* When strings don't fit into the line, add the string (changes) to the next line(s) indented by one tab, e.g.

```lua
very_long_variable_name = very_long_variable_name ..
	"an even longer and longer and longer and longer string"
```

* When building long strings (e.g. formspecs), prefer `table.concat` over string concatenation for aesthetics and a nanoscopic performance benefit. Example:

```lua
-- bad
local s = a .. b .. c .. d ..
	"hello" .. e .. "world" ..
	"foo" .. bar .. "quux"

-- good
local s = table.concat({
	a, b, c, d,
	"hello", e, "world",
	"foo", bar, "quux",
})
```

### Comments

* Use comments to clarify things that may be confusing. Don't write comments that describe things that are obvious from the code. Example:

```lua
-- bad
width = width - 2 -- decrement width by two

-- good
width = width - 2 -- adjust for 1px border on each side
```

* When describing what a variable or a function is, put the comment(s) above the declaration so that LSPs can catch them, e.g.

```lua
-- bad

local some_tbl = {foo = true, bar = false}
-- ^ The table that makes you happy.
--   Indexed by thing, the value is a boolean.

function mcl_example.do_something() -- Does something, returns something else.
end

-- good

-- The table that makes you happy.
-- Indexed by thing, the value is a boolean.
local some_tbl = {foo = true, bar = false}

-- Does something, returns something else.
function mcl_example.do_something()
end
```
