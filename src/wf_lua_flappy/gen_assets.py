# Builds the watch sprites from the original Flappy Bird art into app/lua/.
# Sources (downloaded into SRC, not committed):
#   https://github.com/samuelcust/flappy-bird-assets  (sprites/)
#   https://github.com/mrspeaker/wafty-man  App/res/flappyAtlas/atlas.png + atlas.txt (UI: buttons, panel, medals)
# Usage: python gen_assets.py <dir containing flappy-bird-assets-master/ and atlas.png/atlas.txt>
import sys
from pathlib import Path
from PIL import Image

SRC = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
SPR = SRC / "flappy-bird-assets-master" / "sprites"
OUT = Path(__file__).parent / "app" / "lua"
W, H, BASE_Y = 336, 480, 400
ANGLES = (20, 0, -20, -45, -70, -90)  # nose-up positive; index used by main.lua
NAVY = (16, 35, 76, 255)

for f in OUT.glob("*.png"):
    f.unlink()


def spr(name):
    return Image.open(SPR / name).convert("RGBA")


def save(img, name):
    img.save(OUT / name, optimize=True)


atlas = Image.open(SRC / "atlas.png").convert("RGBA")
A = {}
for line in open(SRC / "atlas.txt"):
    n, w, h, x, y, *_ = line.split()
    x, y = round(float(x) * 1024), round(float(y) * 1024)
    A[n] = atlas.crop((x, y, x + int(w), y + int(h)))

# --- world -------------------------------------------------------------
for theme in ("day", "night"):
    bg = spr(f"background-{theme}.png")
    img = Image.new("RGB", (W, H))
    img.paste(bg, (0, 0))
    img.paste(bg.crop((0, 0, W - 288, 512)), (288, 0))
    save(img, f"bg_{theme}.png")

base = spr("base.png").convert("RGB")  # pattern repeats every 24 px
ground = Image.new("RGB", (W + 24, H - BASE_Y))
ground.paste(base, (0, 0))
ground.paste(base.crop((0, 0, 24, H - BASE_Y)), (W, 0))
save(ground, "base.png")

for c, name in (("g", "pipe-green.png"), ("r", "pipe-red.png")):
    p = spr(name)
    save(p, f"pipe_{c}_bot.png")
    save(p.transpose(Image.FLIP_TOP_BOTTOM), f"pipe_{c}_top.png")

# --- birds: 3 colours x 3 frames x 6 tilt angles on a 44x44 canvas -------
for c, col in (("y", "yellow"), ("b", "blue"), ("r", "red")):
    for f, flap in enumerate(("upflap", "midflap", "downflap")):
        b = spr(f"{col}bird-{flap}.png")
        canvas = Image.new("RGBA", (44, 44))
        canvas.paste(b, (5, 10))
        for a, ang in enumerate(ANGLES):
            save(canvas.rotate(ang, Image.NEAREST), f"bird_{c}{f}{a}.png")

# --- numbers -----------------------------------------------------------
for d in range(10):
    save(spr(f"{d}.png"), f"n{d}.png")
    save(A[f"number_score_0{d}"], f"s{d}.png")

# --- text / ui ---------------------------------------------------------
msg = spr("message.png")
save(msg.crop((3, 0, 181, 48)), "title.png")
save(A["text_ready"], "ready.png")
save(msg.crop((35, 169, 149, 267)), "tutorial.png")
save(A["text_game_over"], "gameover.png")
save(A["score_panel"], "panel.png")
save(A["new"], "new.png")
for i, n in enumerate((3, 2, 1, 0)):  # bronze, silver, gold, platinum
    save(A[f"medals_{n}"], f"medal{i}.png")
save(A["button_play"], "btn_play.png")
save(A["button_score"], "btn_score.png")
best = A["score_panel"].crop((166, 62, 210, 72))  # the red "BEST" word, panel removed
best.putdata([c if c[:3] == (220, 74, 51) else (0, 0, 0, 0) for c in best.getdata()])
save(best, "best.png")


def blank(img, ink):
    """Erase pixels of colour `ink` using the fill colour of the same row."""
    img = img.copy()
    px = img.load()
    for y in range(img.height):
        fill = px[10, y]
        for x in range(img.width):
            if px[x, y][:3] == ink:
                px[x, y] = fill
    return img


def art(rows, pal):
    img = Image.new("RGBA", (len(rows[0]), len(rows)))
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch != ".":
                img.putpixel((x, y), pal[ch])
    return img


def centered(bg, fg, dy=0):
    bg = bg.copy()
    bg.alpha_composite(fg, ((bg.width - fg.width) // 2, (bg.height - fg.height) // 2 + dy))
    return bg


HOME = [
    "......kk......",
    ".....kook.....",
    "....koooook...",
    "...koooooook..",
    "..koooooooook.",
    ".kooooooooook.",
    "kkoooooooookk.",
    "..koowwwook...",
    "..koowkkwok...",
    "..koowkkwok...",
    "..koowkkwok...",
    "..kkkkkkkkk...",
]
SUN = [
    "....k...k....",
    ".k..k...k..k.",
    "..k.......k..",
    ".....kkk.....",
    "....kyyyk....",
    "kk.kyyyyyk.kk",
    "...kyyyyyk...",
    "kk.kyyyyyk.kk",
    "....kyyyk....",
    ".....kkk.....",
    "..k.......k..",
    ".k..k...k..k.",
    "....k...k....",
]
MOON = [
    "....kkkk....",
    "..kkyyyk....",
    ".kyyyyk.....",
    ".kyyyk......",
    "kyyyyk......",
    "kyyyyk......",
    "kyyyyk......",
    "kyyyyyk.....",
    ".kyyyyyk..k.",
    ".kyyyyyykkk.",
    "..kkyyyyyk..",
    "....kkkkk...",
]
PAL = {"k": NAVY, "o": (232, 97, 1, 255), "w": (250, 250, 250, 255), "y": (252, 186, 0, 255)}

play_blank = blank(A["button_play"], (0, 170, 67))
save(centered(play_blank, art(HOME, PAL).resize((28, 24), Image.NEAREST), -2), "btn_menu.png")
pill = blank(A["button_rate"], (252, 186, 0))
save(centered(pill, art(SUN, PAL).resize((26, 26), Image.NEAREST), -2), "pill_day.png")
save(centered(pill, art(MOON, PAL).resize((24, 24), Image.NEAREST), -2), "pill_night.png")
for c, col in (("y", "yellow"), ("b", "blue"), ("r", "red")):
    save(centered(pill, spr(f"{col}bird-midflap.png"), -2), f"pill_bird_{c}.png")

print(len(list(OUT.glob("*.png"))), "sprites ->", OUT)
