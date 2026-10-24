# Prepares a GitHub release from the built faces in faces/<device>/:
#   dist/               every .face (flat) + one <device>.zip each -> upload as release assets
#   docs/catalog.json   what the download page offers, with file sizes
#   docs/previews/      each face as it looks on each device
# Usage: python release.py
import json
import shutil
import sys
import zipfile
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).parent
sys.path.insert(0, str(ROOT / "port"))
from port import DEVICES, on_screen  # noqa: E402

NAMES = {
    "band10pro": "Mi Band 10 Pro", "band9pro": "Mi Band 9 Pro", "band8pro": "Mi Band 8 Pro",
    "band10": "Mi Band 10", "band9": "Mi Band 9", "redmiwatch4": "Redmi Watch 4",
    "redmiwatch6": "Redmi Watch 6", "watchs3": "Xiaomi Watch S3", "watchs4": "Xiaomi Watch S4",
}
# id, name, kind, one line, screenshot in docs/
FACES = [
    ("stride", "Stride", "Watchface", "Running and walking: steps, km, pace, heart rate, walk sessions", "stride_day"),
    ("flappy", "Flappy Bird", "Game", "Tap to flap. Original sprites, best score saved", "flappy"),
    ("tictactoe", "Tic Tac Toe", "Game", "Beat the CPU (Easy / Hard) or play a friend", "tictactoe"),
    ("calculator", "Calculator", "Tool", "Phone-style calculator with percent and repeat equals", "calculator"),
    ("expenses", "Expenses", "Tool", "Log spending; today, week, month and history", "expenses"),
]
# native app installers (Band 10 Pro only): id, name, file, screenshot
APPS = [
    ("flappy", "Flappy Bird app", "native_flappy.face", "flappy"),
    ("tictactoe", "Tic Tac Toe app", "native_ttt.face", "tictactoe"),
    ("calculator", "Calculator app", "native_calc.face", "calculator"),
]


def main():
    dist, prev_root = ROOT / "dist", ROOT / "docs" / "previews"
    shutil.rmtree(dist, ignore_errors=True)
    shutil.rmtree(prev_root, ignore_errors=True)
    dist.mkdir()
    shots = {f: Image.open(ROOT / "docs" / f"{f}.png") for *_, f in FACES}
    devices, files = [], {}
    for dev, (_, w, h, r) in DEVICES.items():
        folder = ROOT / "faces" / dev
        if not folder.is_dir():
            print("skip", dev, "(not built)")
            continue
        files[dev] = {}
        (prev_root / dev).mkdir(parents=True)
        zpath = dist / f"{dev}.zip"
        with zipfile.ZipFile(zpath, "w", zipfile.ZIP_DEFLATED) as z:
            for fid, *_, shot in FACES:
                name = f"lua_{fid}.face" if dev == "band10pro" else f"lua_{fid}_{dev}.face"
                src = folder / name
                assert src.exists(), src
                shutil.copy2(src, dist / name)
                z.write(src, name)
                files[dev][fid] = {"file": name, "size": src.stat().st_size}
                on_screen(shots[shot], dev).convert("RGB").save(prev_root / dev / f"{fid}.webp", quality=85)
            if dev == "band10pro":
                for aid, _, name, _ in APPS:
                    src = folder / "apps" / name
                    shutil.copy2(src, dist / name)
                    z.write(src, "apps/" + name)
                    files[dev]["app_" + aid] = {"file": name, "size": src.stat().st_size}
        devices.append({"id": dev, "name": NAMES[dev], "w": w, "h": h, "r": r,
                        "zip": zpath.name, "zipSize": zpath.stat().st_size})
    catalog = {
        "devices": devices,
        "faces": [{"id": i, "name": n, "kind": k, "about": a} for i, n, k, a, _ in FACES],
        "apps": [{"id": "app_" + i, "name": n, "preview": i} for i, n, _, _ in APPS],
        "files": files,
    }
    (ROOT / "docs" / "catalog.json").write_text(json.dumps(catalog, indent=1), encoding="utf-8")
    n = len(list(dist.iterdir()))
    print(f"{n} release assets in dist/, catalog for {len(devices)} devices")
    assert len(devices) == len(DEVICES) and all(len(files[d]) >= len(FACES) for d in files)


if __name__ == "__main__":
    main()
