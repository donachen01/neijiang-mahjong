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
CONTACT_SHEET = ROOT / "docs/ui_baseline/mockups/tile_symbols_v1_0_21_contact_sheet.png"
SYMBOL_SIZE = (196, 288)
SUITS = ("tiao", "tong", "wan")
SUIT_PARAMS = {
	"tiao": {
		"thicken": 5,
		"alpha": 1.30,
		"color": 1.12,
		"contrast": 1.12,
		"glow": 0.18,
		"shadow": 0.40,
		"highlight": 0.24,
		"rim": (22, 118, 48, 0),
		"core": (22, 138, 58, 0),
		"outline_tint": (22, 60, 42),
		"outline_strength": 0.42,
	},
	"tong": {
		"thicken": 4,
		"alpha": 1.25,
		"color": 1.13,
		"contrast": 1.13,
		"glow": 0.17,
		"shadow": 0.38,
		"highlight": 0.22,
		"rim": (26, 74, 138, 0),
		"core": (20, 116, 72, 0),
		"outline_tint": (18, 48, 92),
		"outline_strength": 0.34,
	},
	"wan": {
		"thicken": 5,
		"alpha": 1.30,
		"color": 1.08,
		"contrast": 1.12,
		"glow": 0.13,
		"shadow": 0.32,
		"highlight": 0.18,
		"rim": (138, 26, 42, 0),
		"core": (26, 92, 138, 0),
		"outline_tint": (92, 36, 58),
		"outline_strength": 0.66,
	},
}
TILE_PARAM_OVERRIDES = {
	("tiao", 1): {
		"thicken": 3,
		"alpha": 1.18,
		"color": 1.08,
		"contrast": 1.06,
		"glow": 0.12,
		"shadow": 0.24,
		"highlight": 0.16,
		"pressed": 0.10,
		"rim_alpha": 0.16,
		"core_alpha": 0.10,
		"edge_alpha": 0.10,
		"outline_tint": (44, 74, 52),
		"outline_strength": 0.76,
	},
}


def _mask(alpha: Image.Image, multiplier: float, blur: float = 0.0) -> Image.Image:
	mask = alpha.filter(ImageFilter.GaussianBlur(blur)) if blur > 0.0 else alpha
	return mask.point(lambda value: min(255, int(value * multiplier)))


def _odd_filter_size(value: int) -> int:
	size = max(3, int(value))
	return size if size % 2 == 1 else size + 1


def _soften_dark_ink(image: Image.Image, tint: tuple[int, int, int], strength: float) -> Image.Image:
	pixels = image.load()
	width, height = image.size
	for y in range(height):
		for x in range(width):
			r, g, b, a = pixels[x, y]
			if a == 0:
				continue
			luma = int(r * 0.299 + g * 0.587 + b * 0.114)
			if luma >= 62:
				continue
			weight = strength * (1.0 - float(luma) / 62.0)
			pixels[x, y] = (
				int(r * (1.0 - weight) + tint[0] * weight),
				int(g * (1.0 - weight) + tint[1] * weight),
				int(b * (1.0 - weight) + tint[2] * weight),
				a,
			)
	return image


def soften_symbol(source_path: Path, suit: str, rank: int) -> Image.Image:
	params = SUIT_PARAMS[suit].copy()
	params.update(TILE_PARAM_OVERRIDES.get((suit, rank), {}))
	source = Image.open(source_path).convert("RGBA").resize(SYMBOL_SIZE, Image.Resampling.LANCZOS)
	r, g, b, alpha = source.split()

	expanded_alpha = alpha.filter(ImageFilter.MaxFilter(_odd_filter_size(int(params["thicken"]))))
	soft_alpha = expanded_alpha.filter(ImageFilter.GaussianBlur(0.25)).point(
		lambda value: min(255, int(value * float(params["alpha"])))
	)
	symbol = Image.merge("RGBA", (r, g, b, soft_alpha))
	symbol = ImageEnhance.Color(symbol).enhance(float(params["color"]))
	symbol = ImageEnhance.Contrast(symbol).enhance(float(params["contrast"]))
	symbol = _soften_dark_ink(
		symbol,
		tuple(params["outline_tint"]),
		float(params["outline_strength"]),
	)

	glow = Image.new("RGBA", SYMBOL_SIZE, (255, 235, 190, 0))
	glow.putalpha(_mask(soft_alpha, float(params["glow"]), 1.8))

	contact_shadow = Image.new("RGBA", SYMBOL_SIZE, (28, 24, 16, 0))
	contact_shadow.putalpha(_mask(soft_alpha, float(params["shadow"]), 1.35))

	pressed_shadow = Image.new("RGBA", SYMBOL_SIZE, (52, 42, 24, 0))
	pressed_shadow.putalpha(_mask(expanded_alpha, float(params.get("pressed", 0.18)), 0.55))

	rim = Image.new("RGBA", SYMBOL_SIZE, tuple(params["rim"]))
	rim.putalpha(_mask(expanded_alpha, float(params.get("rim_alpha", 0.24)), 0.20))

	core_rim = Image.new("RGBA", SYMBOL_SIZE, tuple(params["core"]))
	core_rim.putalpha(_mask(alpha, float(params.get("core_alpha", 0.14)), 0.10))

	highlight = Image.new("RGBA", SYMBOL_SIZE, (255, 250, 210, 0))
	highlight.putalpha(_mask(alpha, float(params["highlight"]), 0.28))

	edge_light = Image.new("RGBA", SYMBOL_SIZE, (255, 246, 204, 0))
	edge_light.putalpha(_mask(expanded_alpha, float(params.get("edge_alpha", 0.16)), 0.70))

	composed = Image.new("RGBA", SYMBOL_SIZE, (0, 0, 0, 0))
	composed.alpha_composite(contact_shadow, (3, 4))
	composed.alpha_composite(pressed_shadow, (1, 2))
	composed.alpha_composite(glow, (-1, -1))
	composed.alpha_composite(rim, (1, 1))
	composed.alpha_composite(core_rim, (0, 0))
	composed.alpha_composite(edge_light, (-1, -2))
	composed.alpha_composite(highlight, (-1, -2))
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
			soften_symbol(SOURCE_DIR / f"{suit}_{rank}.png", suit, rank).save(OUT_DIR / f"{suit}_{rank}.png")
	build_contact_sheet()
	print(f"generated {OUT_DIR}")
	print(f"contact_sheet {CONTACT_SHEET}")


if __name__ == "__main__":
	main()
