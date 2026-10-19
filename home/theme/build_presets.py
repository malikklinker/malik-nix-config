"""Build an offline Tinty repository and swatch catalog from pinned Base16 schemes."""

import json
from pathlib import Path
import re
import shutil
import sys

import yaml


source, output = map(Path, sys.argv[1:])
favorites = [
    "catppuccin-mocha",
    "catppuccin-latte",
    "catppuccin-frappe",
    "catppuccin-macchiato",
    "nord",
    "gruvbox-dark-hard",
    "tokyo-night-dark",
    "rose-pine",
    "everforest",
    "solarized-light",
]
roles = {
    "background": "base00",
    "surface": "base01",
    "overlay": "base02",
    "muted": "base03",
    "subtext": "base04",
    "text": "base05",
    "accent": "base0E",
    "secondary": "base0D",
    "red": "base08",
    "yellow": "base0A",
    "green": "base0B",
    "blue": "base0D",
    "cyan": "base0C",
}
schemes = output / "schemes/base16"
themes = output / "template/themes"
schemes.mkdir(parents=True)
themes.mkdir(parents=True)
catalog = []
for file in sorted(source.glob("*.yaml")):
    data = yaml.safe_load(file.read_text())
    if data.get("system") != "base16":
        continue
    palette = {key: str(value).lower() for key, value in data["palette"].items()}
    if not all(
        re.fullmatch(r"#[0-9a-f]{6}", palette.get(f"base{i:02X}", ""))
        for i in range(16)
    ):
        raise ValueError(f"Invalid palette: {file.name}")
    theme = {
        "id": f"base16-{file.stem}",
        "slug": file.stem,
        "name": data["name"],
        "variant": data.get("variant", "dark"),
        "palette": palette,
        "colors": {role: palette[key] for role, key in roles.items()},
        "swatches": [
            palette[key]
            for key in ["base00", "base05", "base08", "base0B", "base0D", "base0E"]
        ],
    }
    shutil.copyfile(file, schemes / file.name)
    (themes / f"{theme['id']}.json").write_text(json.dumps(theme) + "\n")
    catalog.append(theme)
catalog.sort(
    key=lambda theme: (
        favorites.index(theme["slug"])
        if theme["slug"] in favorites
        else len(favorites),
        theme["name"].casefold(),
    )
)
(output / "catalog.json").write_text(json.dumps(catalog) + "\n")
assert catalog[0]["slug"] == "catppuccin-mocha"
