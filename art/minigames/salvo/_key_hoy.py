# Magenta chroma → alpha for HOY beam (green spell cannot use #00FF00).
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent
OUT = ROOT.parent / "salvo_play"
MAGENTA = np.array([255.0, 0.0, 255.0], dtype=np.float32)
TH = 95.0
JOBS = [
	(ROOT / "candidates" / "hoy_beam.png", OUT / "hoy_beam.png"),
	(ROOT / "candidates" / "shot.png", OUT / "shot.png"),
]


def key_magenta(im: Image.Image) -> Image.Image:
	arr = np.asarray(im.convert("RGBA")).astype(np.float32)
	rgb = arr[:, :, 0:3]
	dist = np.linalg.norm(rgb - MAGENTA, axis=2)
	r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
	# Magenta / hot pink / rose studio (not only #FF00FF). Keep green (G dominant).
	hot = (r > 150.0) & (g < 120.0) & (r > g + 40.0)
	chroma = (dist < TH) | hot | ((r > 160.0) & (b > 160.0) & (g < 90.0))
	alpha = np.where(chroma, 0.0, 255.0)
	out = arr.copy()
	# Magenta fringe on the ink edge: pull R/B down toward G.
	edge = ~chroma
	fringe = edge & (r > 50.0) & (b > 50.0) & (g + 18.0 < r) & (g + 18.0 < b)
	out[fringe, 0] = np.minimum(out[fringe, 0], out[fringe, 1] * 0.85)
	out[fringe, 2] = np.minimum(out[fringe, 2], out[fringe, 1] * 0.55)
	out[:, :, 3] = alpha
	out[chroma, 0:3] = 0.0
	return Image.fromarray(out.astype(np.uint8), "RGBA")


def crop_opaque(im: Image.Image, pad: int = 12) -> Image.Image:
	arr = np.asarray(im)
	a = arr[:, :, 3]
	ys, xs = np.where(a > 12)
	if ys.size == 0:
		return im
	y0 = max(0, int(ys.min()) - pad)
	y1 = min(arr.shape[0], int(ys.max()) + 1 + pad)
	x0 = max(0, int(xs.min()) - pad)
	x1 = min(arr.shape[1], int(xs.max()) + 1 + pad)
	return Image.fromarray(arr[y0:y1, x0:x1], "RGBA")


def main() -> None:
	OUT.mkdir(parents=True, exist_ok=True)
	for src, dst in JOBS:
		if not src.exists():
			print("skip", src.name)
			continue
		im = Image.open(src)
		out = key_magenta(im)
		if dst.name == "shot.png":
			out = crop_opaque(out)
		out.save(dst)
		a = np.asarray(out)[:, :, 3]
		print(f"{dst.name}: {out.size} solid={(a > 250).sum()} cut={(a == 0).sum()}")


if __name__ == "__main__":
	main()
