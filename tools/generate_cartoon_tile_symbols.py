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
CONTACT_SHEET = ROOT / "docs/ui_baseline/mockups/tile_symbols_v1_0_14_contact_sheet.png"
SYMBOL_SIZE = (196, 288)
SUITS = ("tiao", "tong", "wan")
SUIT_PARAMS = {
	"tiao": {
		"thicken": 3,
		"alpha": 1.18,
		"color": 1.08,
		"contrast": 1.05,
		"glow": 0.20,
		"shadow": 0.38,
		"highlight": 0.18,
		"rim": (32, 100, 42, 0),
	},
	"tong": {
		"thicken": 3,
		"alpha": 1.15,
		"color": 1.10,
		"contrast": 1.08,
		"glow": 0.18,
		"shadow": 0.36,
		"highlight": 0.16,
		"rim": (36, 78, 120, 0),
	},
	"wan": {
		"thicken": 5,
		"alpha": 1.22,
		"color": 1.06,
		"contrast": 1.10,
		"glow": 0.16,
		"shadow": 0.42,
		"highlight": 0.16,
		"rim": (110, 30, 44, 0),
	},
}


def _mask(alpha: Image.Image, multiplier: float, blur: float = 0.0) -> Image.Image:
	mask = alpha.filter(ImageFilter.GaussianBlur(blur)) if blur > 0.0 else alpha
	return mask.point(lambda value: min(255, int(value * multiplier)))


def soften_symbol(source_path: Path, suit: str) -> Image.Image:
	params = SUIT_PARAMS[suit]
	source = Image.open(source_path).convert("RGBA").resize(SYMBOL_SIZE, Image.Resampling.LANCZOS)
	r, g, b, alpha = source.split()

	expanded_alpha = alpha.filter(ImageFilter.MaxFilter(int(params["thicken"])))
	soft_alpha = expanded_alpha.filter(ImageFilter.GaussianBlur(0.25)).point(
		lambda value: min(255, int(value * float(params["alpha"])))
	)
	symbol = Image.merge("RGBA", (r, g, b, soft_alpha))
	symbol = ImageEnhance.Color(symbol).enhance(float(params["color"]))
	symbol = ImageEnhance.Contrast(symbol).enhance(float(params["contrast"]))

	glow = Image.new("RGBA", SYMBOL_SIZE, (255, 235, 190, 0))
	glow.putalpha(_mask(soft_alpha, float(params["glow"]), 1.8))

	contact_shadow = Image.new("RGBA", SYMBOL_SIZE, (28, 24, 16, 0))
	contact_shadow.putalpha(_mask(soft_alpha, float(params["shadow"]), 1.35))

	pressed_shadow = Image.new("RGBA", SYMBOL_SIZE, (52, 42, 24, 0))
	pressed_shadow.putalpha(_mask(expanded_alpha, 0.20, 0.45))

	rim = Image.new("RGBA", SYMBOL_SIZE, tuple(params["rim"]))
	rim.putalpha(_mask(expanded_alpha, 0.24, 0.15))

	highlight = Image.new("RGBA", SYMBOL_SIZE, (255, 250, 210, 0))
	highlight.putalpha(_mask(alpha, float(params["highlight"]), 0.35))

	composed = Image.new("RGBA", SYMBOL_SIZE, (0, 0, 0, 0))
	composed.alpha_composite(contact_shadow, (3, 4))
	composed.alpha_composite(pressed_shadow, (1, 2))
	composed.alpha_composite(glow, (-1, -1))
	composed.alpha_composite(highlight, (-1, -2))
	composed.alpha_composite(rim, (1, 1))
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
			soften_symbol(SOURCE_DIR / f"{suit}_{rank}.png", suit).save(OUT_DIR / f"{suit}_{rank}.png")
	build_contact_sheet()
	print(f"generated {OUT_DIR}")
	print(f"contact_sheet {CONTACT_SHEET}")


if __name__ == "__main__":
	main()
