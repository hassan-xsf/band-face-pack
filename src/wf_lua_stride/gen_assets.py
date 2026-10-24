# Renders Stride's art into app/lua: two opaque backgrounds (day view and walk
# session), number glyphs per style, date words, pills, buttons, preview.
# Also writes the glyph widths into main.lua (between the GLYPHS markers).
# Run: python gen_assets.py
import re
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).parent
OUT = HERE / "app" / "lua"
FONTS = HERE.parent.parent / "fonts"
W, H, SS = 336, 480, 4

LIME, CYAN, ORANGE, PINK = (198, 244, 50), (56, 214, 245), (255, 159, 10), (255, 55, 95)
PURPLE = (175, 130, 255)
WHITE, GREY, DIM = (245, 245, 247), (142, 142, 147), (99, 99, 104)
TILE, EDGE, TRACK = (18, 20, 23), (32, 35, 41), (34, 40, 22)

# layout, shared with main.lua
HERO_LBL_Y, BAR_Y = 122, 200
TILES = [(20, 222), (174, 222), (20, 312), (174, 312)]
TILE_W, TILE_H = 142, 82
BTN_Y, BTN_H = 412, 54

for old in OUT.glob("*.png"):
    old.unlink()


def font(name, size):
    return ImageFont.truetype(str(FONTS / f"{name}.ttf"), size)


def text(s, name, size, color, track=0.0):
    """Supersampled text, cropped to cap height (ref 'H0'), so same-style images line up."""
    f = font(name, size * SS)
    top, bottom = f.getbbox("H0")[1], f.getbbox("H0")[3]
    adv = [f.getlength(c) + track * size * SS for c in s]
    w = int(sum(adv) - track * size * SS) + 2 * SS
    img = Image.new("L", (w, bottom - top + 2 * SS), 0)
    d = ImageDraw.Draw(img)
    x = SS
    for c, a in zip(s, adv):
        d.text((x, SS - top), c, font=f, fill=255)
        x += a
    img = img.resize((max(1, w // SS), max(1, img.height // SS)), Image.LANCZOS)
    out = Image.new("RGBA", img.size, color + (0,))
    out.putalpha(img)
    return out


ICONS = {"steps": 0xF6DA, "route": 0xEACD, "straighten": 0xE41C, "timer": 0xE425, "sprint": 0xF81F,
         "speed": 0xE9E4, "play": 0xE037, "pause": 0xE034, "stop": 0xE047, "heart": 0xE87E,
         "fire": 0xEF55, "spo2": 0xF6DB, "stress": 0xF6D9, "sleep": 0xF159, "stand": 0xE92C, "flag": 0xF0C6,
         "monitor": 0xEAA2, "cardio": 0xF4B9, "walk": 0xE536, "avgpace": 0xF6BB}


def icon(name, size, color):
    f = font("MaterialSymbolsSharp", size * SS)
    img = Image.new("L", (size * SS, size * SS), 0)
    ImageDraw.Draw(img).text((size * SS / 2, size * SS / 2), chr(ICONS[name]), font=f, fill=255, anchor="mm")
    img = img.resize((size, size), Image.LANCZOS)
    out = Image.new("RGBA", img.size, color + (0,))
    out.putalpha(img)
    return out


def rrect(img, box, r, fill, outline=None):
    """Anti-aliased rounded rectangle pasted onto img."""
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    m = Image.new("L", (w * SS, h * SS), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, w * SS - 1, h * SS - 1], r * SS, fill=255)
    m = m.resize((w, h), Image.LANCZOS)
    if outline:
        img.paste(Image.new("RGB", (w, h), outline), (x0, y0), m)
        inner = Image.new("L", (w * SS, h * SS), 0)
        ImageDraw.Draw(inner).rounded_rectangle([SS, SS, w * SS - 1 - SS, h * SS - 1 - SS], (r - 1) * SS, fill=255)
        m = inner.resize((w, h), Image.LANCZOS)
    img.paste(Image.new("RGB", (w, h), fill), (x0, y0), m)


def pill(word, w, h, bg, fg, ic=None):
    """Rounded pill with optional icon + word, centred."""
    img = Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))
    ImageDraw.Draw(img).rounded_rectangle([0, 0, w * SS - 1, h * SS - 1], h * SS // 2, fill=bg + (255,))
    img = img.resize((w, h), Image.LANCZOS)
    t = text(word, "ChakraPetch-SemiBold", max(12, h // 3), fg, 0.12)
    i = icon(ic, h // 2 + 2, fg) if ic else None
    tw = t.width + (i.width + 4 if i else 0)
    x = (w - tw) // 2
    if i:
        img.alpha_composite(i, (x, (h - i.height) // 2)); x += i.width + 4
    img.alpha_composite(t, (x, (h - t.height) // 2))
    return img


# --------------------------------------------------------------- glyph styles
# name: font, size, colour, small (size, colour), chars; digits are tabular,
# letters and "/" use the small size, all sit on one baseline
STYLES = {
    "h": ("ChakraPetch-Bold", 64, WHITE, None, "0123456789"),         # time hours
    "n": ("ChakraPetch-Bold", 64, LIME, None, "0123456789"),          # time minutes
    "s": ("ChakraPetch-SemiBold", 56, WHITE, None, "0123456789,:"),   # steps / session time
    "p": ("ChakraPetch-SemiBold", 22, LIME, None, "0123456789%"),     # step percent
    "g": ("ChakraPetch-SemiBold", 17, GREY, None, "0123456789,%"),    # goal, battery, date day
    # tile values, one style per colour
    "d": ("ChakraPetch-SemiBold", 34, CYAN, (17, GREY), "0123456789.,km'/-%bp"),
    "a": ("ChakraPetch-SemiBold", 34, ORANGE, (17, GREY), "0123456789hm ,kcal-%"),
    "c": ("ChakraPetch-SemiBold", 34, PINK, (17, GREY), "0123456789spmb-%"),
    "e": ("ChakraPetch-SemiBold", 34, LIME, (17, GREY), "0123456789-%bpm"),
    "v": ("ChakraPetch-SemiBold", 34, PURPLE, (17, GREY), "0123456789-%.km/h"),
}
widths = {}
for key, (fname, size, col, small, chars) in STYLES.items():
    f = font(fname, size * SS)
    top, base = f.getbbox("0")[1], f.getbbox("0")[3]
    cell = max(f.getlength(c) for c in "0123456789")
    sf = small and font(fname, small[0] * SS)
    hgt = base - top + 2 * SS + size * SS // 6  # room for the comma tail
    widths[key] = {}
    for c in chars:
        letter = c.isalpha() or c in " /"
        ff = sf if letter else f
        adv = cell if c.isdigit() else ff.getlength(c) + (2 * SS if letter else 0)
        g = Image.new("L", (int(adv) + SS, hgt), 0)
        x = (adv - ff.getlength(c)) / 2 if c.isdigit() else (SS if letter else 0)
        ImageDraw.Draw(g).text((x, SS + base - top), c, font=ff, fill=255, anchor="ls")
        g = g.resize((max(1, round(adv / SS)), max(1, hgt // SS)), Image.LANCZOS)
        img = Image.new("RGBA", g.size, (small[1] if letter else col) + (0,))
        img.putalpha(g)
        img.save(OUT / f"{key}{ord(c)}.png")
        widths[key][c] = g.width
    widths[key]["_h"] = hgt // SS

# time colon
colon = text(":", "ChakraPetch-Bold", 64, DIM)
colon.save(OUT / "colon.png")
widths["colon"] = {"_h": colon.width}

# date words (weekday lime, month grey)
for w in ("MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"):
    text(w, "ChakraPetch-SemiBold", 17, LIME, 0.08).save(OUT / f"wk_{w}.png")
for i, m in enumerate("JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC".split(), 1):
    text(m, "ChakraPetch-SemiBold", 17, GREY, 0.08).save(OUT / f"mo{i}.png")
text("OF", "ChakraPetch-SemiBold", 17, DIM, 0.08).save(OUT / "of.png")

# movement pills, session status pills
for name, word, bgc, fg in (("run", "RUN", PINK, (0, 0, 0)), ("walk", "WALK", ORANGE, (0, 0, 0)),
                            ("idle", "IDLE", (58, 58, 62), WHITE)):
    t = text(word, "ChakraPetch-SemiBold", 12, fg, 0.1)
    pill(word, t.width + 14, 18, bgc, fg).save(OUT / f"pill_{name}.png")
st = pill("  REC", 66, 22, (58, 14, 24), PINK)
ImageDraw.Draw(st).ellipse([13, 8, 19, 14], fill=PINK + (255,))  # red dot instead of an icon
st.save(OUT / "st_rec.png")
pill("PAUSED", 80, 22, (58, 40, 6), ORANGE, "pause").save(OUT / "st_paused.png")

# buttons (normal; pressed is the same image sunk 2 px in main.lua)
pill("START WALK", W - 48, BTN_H, LIME, (0, 0, 0), "play").save(OUT / "btn_start.png")
pill("PAUSE", W - 48, BTN_H, ORANGE, (0, 0, 0), "pause").save(OUT / "btn_pause.png")
pill("RESUME", 140, BTN_H, LIME, (0, 0, 0), "play").save(OUT / "btn_resume.png")
pill("END", 140, BTN_H, (44, 44, 46), PINK, "stop").save(OUT / "btn_end.png")


# --------------------------------------------------------------- tile labels
for key, ic, name, col in (
    ("distance", "route", "DISTANCE", CYAN), ("active", "timer", "ACTIVE", ORANGE),
    ("metres", "straighten", "METRES", CYAN), ("pace", "sprint", "PACE", PINK),
    ("steps", "steps", "STEPS", ORANGE), ("avgpace", "avgpace", "AVG PACE", CYAN),
    ("cadence", "sprint", "CADENCE", PINK), ("heart", "heart", "HEART", PINK),
    ("cal", "fire", "CALORIES", ORANGE), ("spo2", "spo2", "SPO2", CYAN), ("stress", "stress", "STRESS", LIME),
    ("sleep", "sleep", "SLEEP", PURPLE), ("stand", "stand", "STAND", ORANGE),
    ("calgoal", "flag", "CAL GOAL", LIME), ("standgoal", "stand", "STAND GOAL", PINK),
    ("avghr", "monitor", "AVG HR", CYAN), ("maxhr", "cardio", "MAX HR", LIME),
    ("avgcad", "walk", "AVG CADENCE", PINK), ("speed", "speed", "AVG SPEED", PURPLE)):
    t = text(name, "ChakraPetch-SemiBold", 12, GREY, 0.14)
    i = icon(ic, 18, col)
    lbl = Image.new("RGBA", (23 + t.width, 18), (0, 0, 0, 0))
    lbl.alpha_composite(i, (0, 0))
    lbl.alpha_composite(t, (23, 4))
    lbl.save(OUT / f"lbl_{key}.png")


# --------------------------------------------------------------- backgrounds
def background(hero_icon, hero, bar):
    bg = Image.new("RGB", (W, H), (0, 0, 0))
    i = icon(hero_icon, 20, LIME)
    bg.paste(i, (24, HERO_LBL_Y - 4), i)
    lbl = text(hero, "ChakraPetch-SemiBold", 14, GREY, 0.14)
    bg.paste(lbl, (48, HERO_LBL_Y + 1), lbl)
    if bar:
        rrect(bg, (24, BAR_Y, W - 24, BAR_Y + 10), 5, TRACK)
    for x, y in TILES:
        rrect(bg, (x, y, x + TILE_W, y + TILE_H), 22, TILE, EDGE)
    d = ImageDraw.Draw(bg)  # battery outline (fill is a live box)
    d.rounded_rectangle([W - 52, 25, W - 28, 37], 3, outline=DIM, width=2)
    d.rectangle([W - 27, 29, W - 26, 33], fill=DIM)
    return bg


background("steps", "STEPS", True).save(OUT / "bg_day.png")
background("timer", "WALK TIME", False).save(OUT / "bg_walk.png")

# --------------------------------------------------------------- widths into main.lua
main = OUT / "main.lua"
lines = ["-- GLYPHS (written by gen_assets.py)", "local GW = {"]
for key, m in widths.items():
    items = ", ".join(f'["{c}"] = {w}' if c != "_h" else f"_h = {w}" for c, w in m.items())
    lines.append(f"    {key} = {{ {items} }},")
lines.append("}")
lines.append("-- /GLYPHS")
src = main.read_text(encoding="utf-8")
src = re.sub(r"-- GLYPHS.*?-- /GLYPHS", "\n".join(lines).replace("\\", "\\\\"), src, flags=re.S)
main.write_text(src, encoding="utf-8", newline="\n")
print("ok", {k: v["_h"] for k, v in widths.items()})
