"""Recolor Material's SVGs while retaining shapes, masks, and transparency."""

import json
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET


PAINTS = {"fill", "stroke", "color", "stop-color", "flood-color", "lighting-color"}
STYLE_PAINT = re.compile(
    r"(?P<property>\b(?:fill|stroke|color|stop-color|flood-color|lighting-color))"
    r"\s*:\s*(?P<value>[^;}]+)"
)


def recolor(value, color):
    # Keep holes and gradient/mask references intact.
    if value.strip().lower() in {"none", "transparent", "inherit"}:
        return value
    if value.strip().startswith("url("):
        return value
    return color


def main():
    root, color = Path(sys.argv[1]), sys.argv[2]
    if not re.fullmatch(r"#[0-9a-fA-F]{6}", color):
        raise ValueError("Expected a six-digit hex color")
    ET.register_namespace("", "http://www.w3.org/2000/svg")
    ET.register_namespace("xlink", "http://www.w3.org/1999/xlink")
    original = root / "icons"
    output = original / "monochrome"
    count = 0
    for path in sorted(original.rglob("*.svg")):
        if output in path.parents:
            continue
        tree = ET.parse(path)
        tree.getroot().set("fill", color)
        for node in tree.iter():
            for key, value in list(node.attrib.items()):
                if key in PAINTS:
                    node.set(key, recolor(value, color))
                elif key == "style":
                    node.set(
                        key,
                        STYLE_PAINT.sub(
                            lambda match: (
                                match["property"] + ":" + recolor(match["value"], color)
                            ),
                            value,
                        ),
                    )
            if node.tag.endswith("}style") and node.text:
                node.text = STYLE_PAINT.sub(
                    lambda match: (
                        match["property"] + ":" + recolor(match["value"], color)
                    ),
                    node.text,
                )
        target = output / path.relative_to(original)
        target.parent.mkdir(parents=True, exist_ok=True)
        tree.write(target, encoding="unicode")
        count += 1

    def rewrite(value):
        if isinstance(value, dict):
            return {key: rewrite(item) for key, item in value.items()}
        if isinstance(value, list):
            return [rewrite(item) for item in value]
        if isinstance(value, str) and value.startswith("./icons/"):
            return value.replace("./icons/", "./icons/monochrome/", 1)
        return value

    for path in (root / "icon_themes").glob("*.json"):
        path.write_text(json.dumps(rewrite(json.loads(path.read_text()))) + "\n")
    print(f"Recolored {count} file and folder icons to {color}")


if __name__ == "__main__":
    main()
