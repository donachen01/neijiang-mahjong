#!/usr/bin/env python3
"""Generate rounded jade tile body assets used by the 2D table."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "res/art/ui_3d_cartoon"


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
	mask = Image.new("L", size, 0)
	draw = ImageDraw.Draw(mask)
	draw.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
	return mask


def vertical_gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
	image = Image.new("RGBA", size)
	pixels = image.load()
	height = max(1, size[1] - 1)
	for y in range(size[1]):
		t = y / height
		color = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
		for x in range(size[0]):
			pixels[x, y] = (*color, 255)
	return image


def draw_tile(size: tuple[int, int], back: bool) -> Image.Image:
	w, h = size
	scale = w / 110.0
	canvas = Image.new("RGBA", size, (0, 0, 0, 0))
	draw = ImageDraw.Draw(canvas)
	radius = int(round(14 * scale))
	body_rect = (
		int(round(7 * scale)),
		int(round(4 * scale)),
		w - int(round(8 * scale)),
		h - int(round(13 * scale)),
	)
	body_size = (body_rect[2] - body_rect[0] + 1, body_rect[3] - body_rect[1] + 1)
	mask = rounded_mask(body_size, radius)

	shadow = Image.new("RGBA", body_size, (0, 0, 0, 0))
	shadow.putalpha(mask.filter(ImageFilter.GaussianBlur(max(2, int(3.2 * scale)))).point(lambda value: int(value * 0.34)))
	canvas.alpha_composite(shadow, (body_rect[0] + int(6 * scale), body_rect[1] + int(9 * scale)))

	side_color = (45, 84, 38) if back else (128, 143, 92)
	side = Image.new("RGBA", body_size, (*side_color, 255))
	side.putalpha(mask)
	canvas.alpha_composite(side, (body_rect[0] + int(5 * scale), body_rect[1] + int(7 * scale)))

	top_color = (98, 181, 34) if back else (255, 248, 220)
	bottom_color = (45, 129, 28) if back else (232, 214, 154)
	face = vertical_gradient(body_size, top_color, bottom_color)
	face.putalpha(mask)
	canvas.alpha_composite(face, (body_rect[0], body_rect[1]))

	d = ImageDraw.Draw(canvas)
	inner = (
		body_rect[0] + int(4 * scale),
		body_rect[1] + int(4 * scale),
		body_rect[2] - int(4 * scale),
		body_rect[3] - int(4 * scale),
	)
	d.rounded_rectangle(inner, radius=max(4, radius - int(4 * scale)), outline=(255, 255, 235, 78), width=max(1, int(1.2 * scale)))
	d.arc(
		(inner[0] + int(7 * scale), inner[1] + int(4 * scale), inner[2] - int(7 * scale), inner[1] + int(42 * scale)),
		188,
		352,
		fill=(255, 255, 235, 96),
		width=max(1, int(2.2 * scale)),
	)
	d.line(
		(body_rect[2] - int(6 * scale), body_rect[1] + int(18 * scale), body_rect[2] - int(6 * scale), body_rect[3] - int(18 * scale)),
		fill=(20, 42, 24, 72) if back else (92, 92, 62, 72),
		width=max(1, int(2 * scale)),
	)
	d.rounded_rectangle(
		(body_rect[0] + int(18 * scale), body_rect[3] - int(8 * scale), body_rect[2] - int(16 * scale), body_rect[3] - int(4 * scale)),
		radius=max(1, int(2 * scale)),
		fill=(17, 50, 23, 76) if back else (96, 88, 53, 62),
	)
	if back:
		d.rounded_rectangle(
			(body_rect[0] + int(28 * scale), body_rect[1] + int(58 * scale), body_rect[2] - int(28 * scale), body_rect[1] + int(64 * scale)),
			radius=max(1, int(3 * scale)),
			fill=(148, 210, 74, 95),
		)
	return canvas


def main() -> None:
	OUT_DIR.mkdir(parents=True, exist_ok=True)
	draw_tile((154, 226), False).save(OUT_DIR / "tile_face_large.png")
	draw_tile((110, 162), False).save(OUT_DIR / "tile_face_table.png")
	draw_tile((110, 162), True).save(OUT_DIR / "tile_back_table.png")
	print(f"generated tile bodies in {OUT_DIR}")


if __name__ == "__main__":
	main()
