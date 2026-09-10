from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "play"
OUT.mkdir(exist_ok=True)

CHROMA = [
    (ROOT / "chosen" / "jester_catch_idle.png", "jester_idle.png"),
    (ROOT / "chosen" / "jester_catch_ul.png", "jester_ul.png"),
    (ROOT / "chosen" / "jester_catch_dl.png", "jester_dl.png"),
    (ROOT / "chosen" / "jester_catch_ur.png", "jester_ur.png"),
    (ROOT / "chosen" / "jester_catch_dr.png", "jester_dr.png"),
    (Path(r"C:\Users\adkop\.cursor\projects\c-mobile-clicker\assets\catch_bomb.png"), "catch_bomb.png"),
    (ROOT / "blast_1.png", "blast_1.png"),
    (ROOT / "blast_2.png", "blast_2.png"),
    (ROOT / "blast_3.png", "blast_3.png"),
]


def key_rgba(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    arr = np.asarray(im).astype(np.float32)
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    green = (g > 90) & (g > r * 1.25) & (g > b * 1.25) & ((g - np.maximum(r, b)) > 35)
    green |= (g > 180) & (r < 120) & (b < 120)
    alpha = np.where(green, 0.0, 255.0)
    edge = ~green
    near = np.zeros_like(green)
    near[1:] |= green[:-1]
    near[:-1] |= green[1:]
    near[:, 1:] |= green[:, :-1]
    near[:, :-1] |= green[:, 1:]
    fringe = edge & near
    g2 = g.copy()
    g2[fringe] = np.minimum(g[fringe], np.maximum(r[fringe], b[fringe]) * 0.95)
    out = arr.copy()
    out[:, :, 1] = g2
    out[:, :, 3] = alpha
    mask = alpha == 0
    out[mask, 0:3] = 0
    return Image.fromarray(out.astype(np.uint8), "RGBA")


for src, name in CHROMA:
    im = Image.open(src)
    out = key_rgba(im)
    dest = OUT / name
    out.save(dest)
    a = np.asarray(out)[:, :, 3]
    print(f"{name}: {im.size} solid={(a > 250).sum()} soft={((a > 10) & (a <= 250)).sum()}")

side_src = Path(r"C:\Users\adkop\.cursor\projects\c-mobile-clicker\assets\catch_side.png")
side_dest = Path(r"C:\mobile-clicker\art\ui\side\catch.png")
Image.open(side_src).convert("RGBA").save(side_dest)
print("side", side_dest)
print("DONE", OUT)
