# Flood-key dark studio bg → alpha for salvo_play sprites.
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
CAND = ROOT / "candidates"
OUT = ROOT.parent / "salvo_play"
TH = 22

JOBS = [
    (CAND / "d1_rear.png", OUT / "witch.png"),
    (CAND / "trollbat_a.png", OUT / "trollbat.png"),
    (CAND / "skelplane_a.png", OUT / "skelplane.png"),
    (CAND / "zombiglide_b.png", OUT / "zombiglide.png"),
]


def close(a, b) -> bool:
    return abs(a[0] - b[0]) + abs(a[1] - b[1]) + abs(a[2] - b[2]) < TH


def key(src: Path, dst: Path) -> None:
    im = Image.open(src).convert("RGBA")
    w, h = im.size
    px = im.load()
    ref = px[2, 2]
    seen = bytearray(w * h)
    q = deque([(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)])
    for x in range(0, w, 8):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(0, h, 8):
        q.append((0, y))
        q.append((w - 1, y))
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h:
            continue
        i = y * w + x
        if seen[i]:
            continue
        seen[i] = 1
        c = px[x, y]
        if not close(c, ref):
            continue
        px[x, y] = (0, 0, 0, 0)
        q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    dst.parent.mkdir(parents=True, exist_ok=True)
    im.save(dst)
    print("keyed", dst.name)


def main() -> None:
    for src, dst in JOBS:
        key(src, dst)


if __name__ == "__main__":
    main()
