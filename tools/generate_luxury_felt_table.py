#!/usr/bin/env python3
"""Generate the shared luxury felt table base for the main match scene."""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "res/art/ui_3d_cartoon/felt_table_luxury.png"
SIZE = (2560, 1440)


def lerp(a: float, b: float, t: float) -> float:
	return a * (1.0 - t) + b * t


def main() -> None:
	random.seed(20260511)
	w, h = SIZE
	img = Image.new("RGBA", SIZE, (0, 0, 0, 255))
	pixels = img.load()
	center = (w * 0.50, h * 0.43)
	warm_spot = (w * 0.43, h * 0.58)
	for y in range(h):
		for x in range(w):
			nx = (x - center[0]) / (w * 0.62)
			ny = (y - center[1]) / (h * 0.70)
			r = math.sqrt(nx * nx + ny * ny)
			spot = max(0.0, 1.0 - r)
			wx = (x - warm_spot[0]) / (w * 0.38)
			wy = (y - warm_spot[1]) / (h * 0.42)
			warm = max(0.0, 1.0 - math.sqrt(wx * wx + wy * wy))
			vignette = min(1.0, r * 0.86)
			weave = math.sin(x * 0.055) * 2.4 + math.cos(y * 0.075) * 2.0
			fiber = random.randint(-4, 4)
			base = (
				int(lerp(12, 34, spot) + warm * 10 - vignette * 9 + weave + fiber),
				int(lerp(94, 142, spot) + warm * 18 - vignette * 24 + weave * 0.5 + fiber),
				int(lerp(65, 92, spot) + warm * 10 - vignette * 15 + fiber),
			)
			pixels[x, y] = (max(0, min(255, base[0])), max(0, min(255, base[1])), max(0, min(255, base[2])), 255)

	img = img.filter(ImageFilter.GaussianBlur(0.35))
	d = ImageDraw.Draw(img, "RGBA")

	for i in range(42):
		y = random.randrange(h)
		x = random.randrange(w)
		length = random.randrange(36, 128)
		alpha = random.randrange(1, 3)
		color = (110, 190, 122, alpha) if random.random() > 0.45 else (0, 40, 24, alpha)
		d.line((x, y, min(w, x + length), y + random.randrange(-2, 3)), fill=color, width=1)

	for i in range(18):
		x = random.randrange(w)
		y = random.randrange(h)
		length = random.randrange(24, 96)
		alpha = 1
		d.line((x, y, x + random.randrange(-2, 3), min(h, y + length)), fill=(12, 56, 35, alpha), width=1)

	light = Image.new("RGBA", SIZE, (0, 0, 0, 0))
	ld = ImageDraw.Draw(light, "RGBA")
	for radius, alpha in [(780, 14), (580, 16), (400, 14), (240, 10)]:
		bbox = (center[0] - radius, center[1] - radius * 0.52, center[0] + radius, center[1] + radius * 0.52)
		ld.ellipse(bbox, fill=(128, 210, 128, alpha))
	light = light.filter(ImageFilter.GaussianBlur(42))
	img.alpha_composite(light)

	for radius, alpha in [(1550, 52), (1260, 34), (980, 22)]:
		layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
		ld = ImageDraw.Draw(layer, "RGBA")
		ld.ellipse((center[0] - radius, center[1] - radius * 0.68, center[0] + radius, center[1] + radius * 0.68), outline=(0, 38, 25, alpha), width=90)
		layer = layer.filter(ImageFilter.GaussianBlur(35))
		img.alpha_composite(layer)

	edge = Image.new("RGBA", SIZE, (0, 0, 0, 0))
	ed = ImageDraw.Draw(edge, "RGBA")
	ed.rounded_rectangle((18, 18, w - 18, h - 18), radius=54, outline=(202, 225, 140, 28), width=3)
	ed.rounded_rectangle((30, 30, w - 30, h - 30), radius=42, outline=(0, 42, 26, 58), width=8)
	edge = edge.filter(ImageFilter.GaussianBlur(0.8))
	img.alpha_composite(edge)
	img = img.filter(ImageFilter.GaussianBlur(0.25))

	OUT.parent.mkdir(parents=True, exist_ok=True)
	img.save(OUT)
	print(OUT)


if __name__ == "__main__":
	main()
