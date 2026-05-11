#!/usr/bin/env python3
"""Generate softened Mahjong symbols for the 3D cartoon table.

The source tile marks are still the most readable symbols in the project.
This tool keeps their silhouettes, then applies softer alpha, warm glow,
and contact shadow so they sit better on the new thick jade tile bodies.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "res/art/tiles"
OUT_DIR = ROOT / "res/art/ui_3d_cartoon/tile_symbols"
CONTACT_SHEET = ROOT / "docs/ui_baseline/mockups/tile_symbols_v1_contact_sheet.png"
SYMBOL_SIZE = (196, 288)
SUITS = ("tiao", "tong", "wan")


def soften_symbol(source_path: Path) -> Image.Image:
	source = Image.open(source_path).convert("RGBA").resize(SYMBOL_SIZE, Image.Resampling.LANCZOS)
	r, g, b, alpha = source.split()

	soft_alpha = alpha.filter(ImageFilter.GaussianBlur(0.35)).point(lambda value: min(255, int(value * 1.12)))
	symbol = Image.merge("RGBA", (r, g, b, soft_alpha))
	symbol = ImageEnhance.Color(symbol).enhance(0.92)
	symbol = ImageEnhance.Contrast(symbol).enhance(0.96)

	glow = Image.new("RGBA", SYMBOL_SIZE, (255, 235, 190, 0))
	glow.putalpha(soft_alpha.filter(ImageFilter.GaussianBlur(1.4)).point(lambda value: int(value * 0.26)))

	shadow = Image.new("RGBA", SYMBOL_SIZE, (30, 25, 15, 0))
	shadow.putalpha(soft_alpha.filter(ImageFilter.GaussianBlur(1.2)).point(lambda value: int(value * 0.32)))

	composed = Image.new("RGBA", SYMBOL_SIZE, (0, 0, 0, 0))
	composed.alpha_composite(shadow, (2, 3))
	composed.alpha_composite(glow, (-1, -1))
	composed.alpha_composite(symbol)
	return composed


def build_contact_sheet() -> None:
	cell_w, cell_h = 114, 168
	sheet = Image.new("RGBA", (cell_w * 9, cell_h * 3), (26, 88, 58, 255))
	for row, suit in enumerate(SUITS):
		for rank in range(1, 10):
			image = Image.open(OUT_DIR / f"{suit}_{rank}.png").convert("RGBA")
			image = image.resize((92, 135), Image.Resampling.LANCZOS)
			x = (rank - 1) * cell_w + (cell_w - image.width) // 2
			y = row * cell_h + (cell_h - image.height) // 2
			sheet.alpha_composite(image, (x, y))
	CONTACT_SHEET.parent.mkdir(parents=True, exist_ok=True)
	sheet.save(CONTACT_SHEET)


def main() -> None:
	OUT_DIR.mkdir(parents=True, exist_ok=True)
	for suit in SUITS:
		for rank in range(1, 10):
			soften_symbol(SOURCE_DIR / f"{suit}_{rank}.png").save(OUT_DIR / f"{suit}_{rank}.png")
	build_contact_sheet()
	print(f"generated {OUT_DIR}")
	print(f"contact_sheet {CONTACT_SHEET}")


if __name__ == "__main__":
	main()
