# Ports a 336x480 Lua face project to another Xiaomi device: scales every PNG,
# injects prelude.lua (scales the face's lvgl calls at runtime) and sets the
# device type. Prints the ported project folder for build_face.ps1 to compile.
# Usage: python port/port.py <project dir> <device> <out root>
import math
import re
import shutil
import sys
from pathlib import Path
from PIL import Image

# EasyFace DeviceInfo.db: type, width, height, corner radius (round = width / 2)
DEVICES = {
    "band10pro":   (567, 336, 480, 28),
    "band9pro":    (367, 336, 480, 28),
    "band8pro":    (11, 336, 480, 28),
    "band10":      (466, 212, 520, 106),
    "band9":       (366, 192, 490, 90),
    "redmiwatch4": (365, 390, 450, 80),
    "redmiwatch6": (565, 432, 514, 80),
    "watchs3":     (362, 466, 466, 233),
    "watchs4":     (462, 466, 466, 233),
}
# preview sizes the compiler insists on (it rejects the full 466x466 for the round watches)
PREVIEW = {"watchs3": (326, 326), "watchs4": (326, 326)}
FW, FH, FR = 336, 480, 40  # design screen and the corner radius the faces leave clear


def fits(s, w, h, r):
    """Does the face's rounded rectangle, scaled by s and centred, sit inside the screen?"""
    cw, ch, cr = FW * s, FH * s, FR * s
    if cw > w or ch > h:
        return False
    # the face's corner arc (centre p, radius cr) must lie inside the screen:
    # signed distance from p to the screen's rounded-rectangle edge
    dx = (cw / 2 - cr) - (w / 2 - r)
    dy = (ch / 2 - cr) - (h / 2 - r)
    sd = math.hypot(max(dx, 0), max(dy, 0)) + min(max(dx, dy), 0) - r
    return -sd >= cr - 1e-9


def fit(w, h, r):
    s = min(w / FW, h / FH)
    while not fits(s, w, h, r):
        s -= 0.002
    return math.floor(s * 1000) / 1000  # round down so it still fits


def port(proj, device, out_root):
    typ, w, h, r = DEVICES[device]
    out = Path(out_root) / device / proj.name  # same folder name -> same face id
    shutil.rmtree(out, ignore_errors=True)
    shutil.copytree(proj, out, ignore=shutil.ignore_patterns("output", "__pycache__", "*.fprj.*"))
    (out / "output").mkdir()  # the compiler writes its .info here
    fprj = next(out.glob("*.fprj"))
    fprj.write_text(re.sub(r'DeviceType="\d+"', f'DeviceType="{typ}"', fprj.read_text()))
    if (w, h) == (FW, FH):
        return out  # same screen: nothing to scale

    s = fit(w, h, r)
    ox, oy = round((w - FW * s) / 2), round((h - FH * s) / 2)
    for png in (out / "app" / "lua").rglob("*.png"):
        im = Image.open(png).convert("RGBA")
        im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.LANCZOS).save(png)
    prev = out / "images" / "preview.png"
    if prev.exists():
        im = Image.open(prev).convert("RGBA")
        im = im.resize((round(FW * s), round(FH * s)), Image.LANCZOS)
        canvas = Image.new("RGBA", (w, h), (0, 0, 0, 255))
        canvas.paste(im, (ox, oy), im)
        canvas.resize(PREVIEW.get(device, (w, h)), Image.LANCZOS).save(prev)

    prelude = (Path(__file__).parent / "prelude.lua").read_text(encoding="utf-8")
    for k, v in {"S": s, "OX": ox, "OY": oy, "SW": w, "SH": h}.items():
        prelude = prelude.replace(f"__{k}__", str(v))
    main = out / "app" / "lua" / "main.lua"
    main.write_text(prelude + "\n" + main.read_text(encoding="utf-8"), encoding="utf-8")
    return out


if __name__ == "__main__":
    if sys.argv[1:2] == ["--check"]:  # self-check: every device's fit lands inside its screen
        for d, (_, w, h, r) in DEVICES.items():
            s = fit(w, h, r)
            assert fits(s, w, h, r) and 0.4 < s <= 1.2, d
            print(f"{d:12} {w}x{h} r{r}: scale {s}, face {round(FW * s)}x{round(FH * s)}")
        assert fit(336, 480, 28) == 1.0 and fit(466, 466, 233) < 0.9
    else:
        print(port(Path(sys.argv[1]).resolve(), sys.argv[2], sys.argv[3]))
