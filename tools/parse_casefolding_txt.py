#!/usr/bin/env python3

# cd tools/
# curl -O https://www.unicode.org/Public/17.0.0/ucd/CaseFolding.txt  # edit ver
# ./parse_casefolding_txt.py CaseFolding.txt  # writes to mcl_util automatically

import argparse
from pathlib import Path


CaseFoldingEntry = tuple[int, str, list[int]]  # src, status, mapped


def parse_casefolding(path: Path, include_turkic: bool) -> tuple[list[CaseFoldingEntry], str]:
    wanted = {"C", "F"}
    if include_turkic:
        wanted.add("T")

    entries = []
    with path.open("r", encoding="utf-8", newline="") as f:
        for line_no, raw in enumerate(f, start=1):
            if line_no == 1:  # should contain the Unicode version origin
                version = raw.split("-")[1].strip().removesuffix(".txt")
                continue
            content = raw.split("#", 1)[0].strip()
            if not content:
                continue
            parts = [p.strip() for p in content.split(";")]
            code_str, status, mapping_str = parts[:3]
            if status not in wanted:
                continue
            src = int(code_str, 16)
            mapped = [int(x, 16) for x in mapping_str.split()] if mapping_str else []
            entries.append((src, status, mapped))

    return (entries, version)


LUA_ESCAPE_MAP = {
    ord("\\"): "\\\\",
    ord('"'): '\\"',
    ord("\n"): "\\n",
    ord("\r"): "\\r",
    ord("\t"): "\\t"
}

def to_lua_string(s: str) -> str:
    return '"' + s.translate(LUA_ESCAPE_MAP) + '"'


def display_code(code: int) -> str:
    char = chr(code)
    if char.isprintable() and not char.isspace():
        return char
    return f"U+{code:04X}"


def render_to_lua(entries: list[CaseFoldingEntry], version: str, include_turkic: bool) -> str:
    multi = []  # multi-codepoint mappings (F status)
    single = []  # single-codepoint mappings (C status)
    for src, status, mapped in entries:
        (multi if len(mapped) > 1 else single).append((src, status, mapped))

    multi.sort(key=lambda x: x[0])
    single.sort(key=lambda x: x[0])

    lines = []
    lines.append(f"-- Generated from <https://www.unicode.org/Public/{version}/ucd/CaseFolding.txt>")
    lines.append("return {")

    lines.append('\t-- C status (single-codepoint) entries')
    for src, _, mapped in single:
        dst = mapped[0]
        left = display_code(src)
        right = display_code(dst)
        lines.append(f'\t[0x{src:04X}] = 0x{dst:04X}, -- {left} → {right}')
    lines.append("")

    lines.append('\t-- F status (multi-codepoint) entries (raw strings)')
    for src, _, mapped in multi:
        left = display_code(src)
        right = "".join(chr(code) for code in mapped)
        lines.append(f'\t[0x{src:04X}] = {to_lua_string(right)}, -- {left} → {right}')

    lines.append("}")
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(
        description="convert Unicode CaseFolding.txt into casefold_data.lua for mcl_util"
    )
    parser.add_argument(
        "input",
        type=Path,
        help="path to CaseFolding.txt fetched from the Unicode website"
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("..") / "mods" / "CORE" / "mcl_util" / "casefold_data.lua",
        help="write casefold_data.lua (default: mods/CORE/mcl_util/casefold_data.lua)"
    )
    parser.add_argument(
        "--include-turkic",
        action="store_true",
        help="include T-status entries (warning: overwrites the 0x0049 table key)",
    )

    args = parser.parse_args()

    entries, version = parse_casefolding(args.input, args.include_turkic)
    lua = render_to_lua(entries, version, args.include_turkic)

    args.output.write_text(lua, encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
