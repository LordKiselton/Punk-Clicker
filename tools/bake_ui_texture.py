#!/usr/bin/env python3
"""Bake gen UI PNGs for Godot 9-slice: alpha outside frame, boost contrast, resize."""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageEnhance

CENTER_PANEL = (0x24, 0x1A, 0x2C, 255)
CENTER_BTN_PRI = (0x2A, 0x1F, 0x12, 255)
CENTER_BTN_SEC = (0x24, 0x1A, 0x2C, 255)


def _is_void(r: int, g: int, b: int, a: int, thresh: int) -> bool:
    if a < 16:
        return True
    if r >= 240 and g >= 240 and b >= 240:   # белая «бумажная» кайма gen → прозрачность
        return True
    return r <= thresh and g <= thresh and b <= thresh


def bake(
    src: Path,
    dst: Path,
    size: tuple[int, int],
    slice_px: int,
    center_rgba: tuple[int, int, int, int],
    *,
    sat: float = 1.22,
    contrast: float = 1.12,
    black_thresh: int = 30,
    transparent_center: bool = False,
) -> None:
    im = Image.open(src).convert("RGBA")
    if im.size != size:
        im = im.resize(size, Image.Resampling.LANCZOS)
    im = ImageEnhance.Color(im).enhance(sat)
    im = ImageEnhance.Contrast(im).enhance(contrast)
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if _is_void(r, g, b, a, black_thresh):
                px[x, y] = (0, 0, 0, 0)
            else:
                px[x, y] = (r, g, b, 255)
    # Центр: opaque fill для кнопок; для panel — прозрачный (фон = ColorRect в сцене)
    if not transparent_center:
        m = slice_px
        for y in range(m, h - m):
            for x in range(m, w - m):
                px[x, y] = center_rgba
    dst.parent.mkdir(parents=True, exist_ok=True)
    im.save(dst, optimize=True)
    print(f"baked {src.name} -> {dst} {im.size} RGBA slice={slice_px}")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("src")
    p.add_argument("dst")
    p.add_argument("--w", type=int, required=True)
    p.add_argument("--h", type=int, required=True)
    p.add_argument("--slice", type=int, default=56)
    p.add_argument(
        "--center",
        default="241a2c",
        help="RRGGBB for inner fill (skip with --transparent-center)",
    )
    p.add_argument(
        "--transparent-center",
        action="store_true",
        help="Leave inner area alpha 0 — frame only; fill via ColorRect in scene",
    )
    args = p.parse_args()
    c = args.center
    center = (int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16), 255)
    bake(
        Path(args.src),
        Path(args.dst),
        (args.w, args.h),
        args.slice,
        center,
        transparent_center=args.transparent_center,
    )


if __name__ == "__main__":
    main()
