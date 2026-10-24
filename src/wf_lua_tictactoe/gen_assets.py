# Renders the pieces and every piece of text (Poppins, from fonts/) into app/lua.
# Text is pre-rendered so it looks the same on any firmware. Run: python gen_assets.py
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).parent
OUT = HERE / "app" / "lua"
FONTS = HERE.parent.parent / "fonts"
X_COL, O_COL = (56, 189, 248), (244, 114, 182)
GREY, LIGHT, WHITE = (142, 142, 147), (209, 209, 214), (245, 245, 247)
SS = 4  # supersample

for old in OUT.glob("*.png"):
    old.unlink()


def piece(kind, size, stroke):
    s = size * SS
    shape = Image.new("L", (s, s), 0)
    d = ImageDraw.Draw(shape)
    m, w = int(s * (0.2 if kind == "x" else 0.16)), stroke * SS
    if kind == "x":
        for a, b in (((m, m), (s - m, s - m)), ((s - m, m), (m, s - m))):
            d.line([a, b], fill=255, width=w)
            for p in (a, b):  # round caps
                d.ellipse([p[0] - w / 2, p[1] - w / 2, p[0] + w / 2, p[1] + w / 2], fill=255)
    else:
        d.ellipse([m, m, s - m, s - m], outline=255, width=w)
    shape = shape.resize((size, size), Image.LANCZOS)
    col = X_COL if kind == "x" else O_COL
    img = Image.new("RGBA", (size, size), col + (0,))
    img.putalpha(shape.filter(ImageFilter.GaussianBlur(size * 0.07)).point(lambda v: int(v * 0.55)))
    core = Image.new("RGBA", (size, size), col + (0,))
    core.putalpha(shape)
    return Image.alpha_composite(img, core)


def text(s, weight, size, color, track=0.0, ref="Hg", width=None):
    """Text image cropped to the style's ref glyphs vertically, so same-style images line up."""
    f = ImageFont.truetype(str(FONTS / f"Poppins-{weight}.ttf"), size * SS)
    top = f.getbbox(ref)[1]
    bottom = f.getbbox(ref)[3]
    adv = [f.getlength(c) + track * size * SS for c in s]
    w = int(sum(adv) - track * size * SS) + 2 * SS
    if width:
        w = max(w, width * SS)
    img = Image.new("L", (w, bottom - top + 2 * SS), 0)
    d = ImageDraw.Draw(img)
    x = (w - (sum(adv) - track * size * SS)) / 2
    for c, a in zip(s, adv):
        d.text((x, SS - top), c, font=f, fill=255)
        x += a
    img = img.resize((max(1, w // SS), max(1, img.height // SS)), Image.LANCZOS)
    out = Image.new("RGBA", img.size, color + (0,))
    out.putalpha(img)
    return out


def save(img, name):
    img.save(OUT / f"{name}.png")


piece("x", 72, 9).save(OUT / "x.png")
piece("o", 72, 9).save(OUT / "o.png")

# score digits, fixed width so numbers don't wobble
for key, col in (("x", X_COL), ("d", LIGHT), ("o", O_COL)):
    for n in range(10):
        save(text(str(n), "SemiBold", 40, col, ref="0123456789", width=26), f"n{key}{n}")

for name, s in (("you", "YOU"), ("cpu", "CPU"), ("draw", "DRAW"), ("px", "PLAYER X"), ("po", "PLAYER O")):
    save(text(s, "Medium", 12, GREY, track=0.14, ref="H"), f"l_{name}")

for i, s in enumerate(("vs CPU · Easy", "vs CPU · Hard", "2 Players"), 1):
    save(text(s, "Medium", 17, LIGHT), f"mode{i}")

for name, s, col in (
    ("you_turn", "Your turn", X_COL), ("cpu_turn", "CPU is thinking", O_COL),
    ("x_turn", "X to play", X_COL), ("o_turn", "O to play", O_COL),
    ("you_win", "You win!", X_COL), ("cpu_win", "CPU wins", O_COL),
    ("x_win", "X wins!", X_COL), ("o_win", "O wins!", O_COL), ("draw", "It's a draw", WHITE),
):
    save(text(s, "SemiBold", 22, col), f"s_{name}")
save(text("TAP TO PLAY AGAIN", "Medium", 11, GREY, track=0.14, ref="H"), "s_again")
print("ok", len(list(OUT.glob("*.png"))), "images")
