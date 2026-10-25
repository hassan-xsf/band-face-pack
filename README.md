<div align="center">

<img src="docs/banner.png" alt="Band Face Pack: faces, games and tools for Xiaomi bands and watches" width="100%">

# Band Face Pack

**A running watchface, Flappy Bird, Tic Tac Toe, a calculator and an expense tracker for 9 Xiaomi bands and watches.**<br>
Plus real native apps for the Mi Band 10 Pro. Free and open source. Install with Gadgetbridge: no root, no modded apps.

[![Download](https://img.shields.io/badge/Get_faces_for_your_watch-c6f432?style=for-the-badge)](https://hassan-xsf.github.io/band-face-pack/)
[![Try in browser](https://img.shields.io/badge/Try_them_in_your_browser-1d2026?style=for-the-badge)](https://hassan-xsf.github.io/band-face-viewer/)

[![Devices](https://img.shields.io/badge/devices-9%20Xiaomi%20bands%20%26%20watches-c6f432?style=flat-square)](#which-watches)
[![Firmware](https://img.shields.io/badge/firmware-3.201.026%20%C2%B7%203.201.016%20%C2%B7%20CN%203.101.043-38d6f5?style=flat-square)](#which-watches)
[![Install](https://img.shields.io/badge/install-Gadgetbridge-ff9f0a?style=flat-square)](INSTALL.md)
[![License](https://img.shields.io/badge/license-MIT-af82ff?style=flat-square)](LICENSE)

[Download page](https://hassan-xsf.github.io/band-face-pack/) · [Install guide](INSTALL.md) · [Native apps](#native-apps-mi-band-10-pro) · [FAQ](#faq) · [Contact](#help-and-contact)

</div>

---

## Get started in 3 steps

1. **Pick and download.** Open the **[download page](https://hassan-xsf.github.io/band-face-pack/)**, choose your watch,
   tick what you want and press Download. Or grab a whole zip from **[Releases](../../releases/latest)**.
2. **Install.** Open the `.face` file on your Android phone with **[Gadgetbridge](https://gadgetbridge.org/)** and tap
   **Install**. First time? The **[install guide](INSTALL.md)** walks you through pairing.
3. **Use it.** On the band, long-press the watchface, swipe to the new one and tap it.

Not sure yet? Every face runs in **[Band Face Viewer](https://hassan-xsf.github.io/band-face-viewer/)**, right in your
browser, before you install anything.

## What's inside

### Stride: running and walking

The home screen for people who move. You get the time, steps against your goal, distance, active time and a live pace,
with heart rate, calories, SpO₂, stress, sleep and stand on the next pages. Tap the tiles to flip between them.

Press **Start Walk** to begin a session. It counts walk time, distance, steps, average pace and cadence. You can pause,
resume and end it. During a session every health value is a **fresh reading taken after you pressed Start**, not the
day's leftovers: calories burned, average and max heart rate, SpO₂, stress, average cadence and speed.

<p align="center">
  <img src="docs/stride_day.png" width="200" alt="Stride day view">
  <img src="docs/stride_walk.png" width="200" alt="Stride walk session">
  <img src="docs/stride_walk2.png" width="200" alt="Stride walk heart and calories">
  <img src="docs/stride_walk3.png" width="200" alt="Stride walk SpO2 and speed">
</p>

### Games and tools

| | |
|---|---|
| **Flappy Bird** | The real thing, with the original sprites. Tap to flap. Your best score, day or night theme and bird colour are saved. |
| **Tic Tac Toe** | Play the CPU on Easy or Hard (Hard never loses), or play a friend. Scores are kept. |
| **Calculator** | A clean, phone-style calculator with percent, sign toggle and repeat equals. |
| **Expenses** | Track spending from your wrist: amount, category, note. Shows today, this week as a bar chart, this month against last month, and every past month by category. Currency is Rs. |

<p align="center">
  <img src="docs/flappy.png" width="200" alt="Flappy Bird">
  <img src="docs/tictactoe.png" width="200" alt="Tic Tac Toe">
  <img src="docs/calculator.png" width="200" alt="Calculator">
  <img src="docs/expenses.png" width="200" alt="Expenses">
</p>

All five are watchfaces, so they work on every supported watch. Long-press and swipe always work, so you can switch
away at any time.

## Native apps (Mi Band 10 Pro)

Flappy Bird, Tic Tac Toe and Calculator also come as **real apps**. They sit in the band's app list next to the stock
apps, so you keep your normal watchface and open the game when you want it.

| File | App |
|---|---|
| `native_flappy.face` | Flappy Bird |
| `native_ttt.face` | Tic Tac Toe |
| `native_calc.face` | Calculator |

**How to install one:**

1. Download the file from the [download page](https://hassan-xsf.github.io/band-face-pack/?watch=band10pro) (section
   *Or as real apps*), or from `band10pro.zip` in [Releases](../../releases/latest).
2. Install it with Gadgetbridge like any `.face`. It arrives as an installer watchface.
3. On the band, switch to that watchface and tap **Install**. The app copies itself into the app list and the installer
   face removes itself.
4. The first time, go to **Settings → Manage apps** on the band and switch the app **On**.

**Good to know:**

- The apps live in the band's memory, so **after the band restarts they are gone**. Install the `.face` again to get them back.
- They need firmware **3.201.026** (Global, tested), **3.201.016** (Global) or **3.101.043** (China). The last two are
  built but not yet tested on a real band. On any other firmware the installer shows "not supported yet" and has no Install button.
- They are built on [m0tral](https://github.com/m0tral)'s native app platform. See the [install guide](INSTALL.md#native-apps-mi-band-10-pro) for troubleshooting.

## Which watches

<p align="center"><img src="docs/devices.png" alt="The faces running on Watch S3, Redmi Watch 4 and 6, Band 9 and Band 10" width="100%"></p>

| Device | Screen | Status | Zip |
|---|---|---|---|
| **Mi Band 10 Pro**, Global 3.201.026 | 336 × 480 | **Tested** on the band, faces and native apps | [`band10pro.zip`](../../releases/latest/download/band10pro.zip) |
| Mi Band 9 Pro | 336 × 480 | Beta: same screen, faces unchanged | [`band9pro.zip`](../../releases/latest/download/band9pro.zip) |
| Mi Band 8 Pro | 336 × 480 | Beta: same screen, faces unchanged | [`band8pro.zip`](../../releases/latest/download/band8pro.zip) |
| Redmi Watch 4 | 390 × 450 | Beta: scaled to 94% | [`redmiwatch4.zip`](../../releases/latest/download/redmiwatch4.zip) |
| Redmi Watch 6 | 432 × 514 | Beta: scaled to 107% | [`redmiwatch6.zip`](../../releases/latest/download/redmiwatch6.zip) |
| Xiaomi Watch S3 | 466 round | Beta: scaled to fit the round screen | [`watchs3.zip`](../../releases/latest/download/watchs3.zip) |
| Xiaomi Watch S4 | 466 round | Beta: scaled to fit the round screen | [`watchs4.zip`](../../releases/latest/download/watchs4.zip) |
| Mi Band 10 | 212 × 520 | Beta: scaled to 63%, small text is small | [`band10.zip`](../../releases/latest/download/band10.zip) |
| Mi Band 9 | 192 × 490 | Beta: scaled to 57%, small text is small | [`band9.zip`](../../releases/latest/download/band9.zip) |

**Beta** means the face was checked at the real screen size in [Band Face Viewer](https://github.com/hassan-xsf/band-face-viewer)
but nobody has tried it on that watch yet. Tried one? **[Tell us how it went](../../issues/new/choose)**. Even "works fine" helps.

Each zip has the same five faces: `lua_stride`, `lua_flappy`, `lua_tictactoe`, `lua_calculator` and `lua_expenses`, with
a `_<device>` suffix on every device except the Band 10 Pro. You need an Android phone with
[Gadgetbridge](https://gadgetbridge.org/gadgets/) support for your watch. The official Mi Fitness app can't install custom
faces. Non-Xiaomi watches (Amazfit, Wear OS, Huawei) use completely different systems.

## FAQ

<details>
<summary><b>Is it safe for my band?</b></summary>

Yes. Watchfaces are normal faces, the same kind as the ones in the official store, and none of them can trap you: you
can always long-press and swipe away, or switch faces from Gadgetbridge. The native apps are a little more adventurous
(they load code into the band), which is why they only run on firmware they were built for.
</details>

<details>
<summary><b>Is Stride's distance accurate?</b></summary>

It is estimated from steps × stride length (0.74 m by default), and active time comes from your step count. For a better
match, set `STRIDE_M` in [`src/wf_lua_stride/app/lua/main.lua`](src/wf_lua_stride/app/lua/main.lua) to your own stride
(roughly height × 0.415 for walking) and rebuild.
</details>

<details>
<summary><b>Why no blood pressure?</b></summary>

The Band 10 Pro has no blood pressure sensor. Stride shows everything the band actually measures.
</details>

<details>
<summary><b>The face shows "--" for SpO₂ or stress during a walk</b></summary>

That's on purpose. It waits for a reading taken *after* you pressed Start. Run a measurement on the band, or wait for
the next automatic one.
</details>

<details>
<summary><b>My native app disappeared</b></summary>

The band restarted. Native apps don't survive a restart: install the `.face` again and tap **Install**.
</details>

<details>
<summary><b>I'm stuck on a face and can't swipe away</b></summary>

In Gadgetbridge, open the watchface manager, tap any other face and choose **Set**. See
[INSTALL.md](INSTALL.md#getting-off-a-broken-watchface).
</details>

## Help and contact

- Something broken, or tried it on a new watch? **[Open an issue](../../issues/new/choose)**.
- Anything else, or you'd rather not use GitHub: email **[hassandev45@gmail.com](mailto:hassandev45@gmail.com)**.

## Related

**[Band Face Viewer](https://github.com/hassan-xsf/band-face-viewer)** runs Xiaomi Lua watchfaces in your browser. Try
any face from this pack before installing it, or use it to build your own: hot reload, fake health data, a Lua console
and 9 device screens. **[Open it online](https://hassan-xsf.github.io/band-face-viewer/)**.

## Build from source

You need Windows, the [EasyFace](https://github.com/m0tral/EasyFace) compiler v4.23, and Python 3 with Pillow.

```powershell
python src\wf_lua_stride\gen_assets.py                     # re-render art (only if you changed it)
.\build_face.ps1 src\wf_lua_stride -Compiler C:\path\to\Compiler.exe
# -> build\lua_stride.face
.\build_face.ps1 src\wf_lua_stride -Device redmiwatch4      # port to another device
# -> build\lua_stride_redmiwatch4.face
```

Devices: `band10pro` `band9pro` `band8pro` `band10` `band9` `redmiwatch4` `redmiwatch6` `watchs3` `watchs4`.
`python port\port.py --check` prints the scale used for each one.

**How the ports work:** every face is designed at 336 × 480. [`port/`](port) scales its art to the target screen and
adds a small Lua layer that scales every position, size and font the face asks for, then centres it. The face code
itself is unchanged, so a fix reaches every device at once.

```
src/wf_lua_<name>/
├── app/lua/main.lua     the face (Lua + lvgl)
├── app/lua/*.png        pre-rendered art and glyph fonts
├── gen_assets.py        renders that art from fonts/
├── *_test.lua           PC tests (lua <name>_test.lua)
└── module.fprj          EasyFace project
```

### Making a release

```powershell
python release.py     # dist/ (every .face + a zip per device), docs/catalog.json, docs/previews/
gh release create v1.0.0 dist/* --title "v1.0.0" --notes-file .github/release-notes.md
```

Built faces go in `faces/<device>/` (not in git). The download page (`docs/`, served by GitHub Pages) links to
`releases/latest`, so a new release updates it without touching the page.

Pull requests are welcome.

## Credits

This project stands on other people's work. Thank you:

- **[m0tral](https://github.com/m0tral)**: the [native app platform](https://github.com/m0tral/MiWatchNativeApps) and its
  firmware **3.201.026** support that the native apps are built on, the [EasyFace](https://github.com/m0tral/EasyFace)
  compiler, and the [Lua watchface examples](https://github.com/m0tral/MiWatchLuaWatchfaces) that documented the
  band's Lua API. Follow his work: [Telegram news](https://t.me/mi_watch_news) · [chat](https://t.me/mi_watch_int).
- **Flappy Bird**: the original game by Dong Nguyen (.GEARS). Sprites from
  [samuelcust/flappy-bird-assets](https://github.com/samuelcust/flappy-bird-assets), and the UI atlas (buttons, panel,
  medals) from [mrspeaker/wafty-man](https://github.com/mrspeaker/wafty-man).
- [Gadgetbridge](https://gadgetbridge.org/) for open-source installing, and
  [Xiaomi Cloud Tokens Extractor](https://github.com/PiotrMachowski/Xiaomi-cloud-tokens-extractor) for the auth key.
- Fonts: Chakra Petch, Poppins (SIL OFL) and Material Symbols (Apache 2.0). See [fonts/](fonts/README.md).

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for licenses.

## License

My code is under [MIT](LICENSE). Flappy Bird's name and art belong to their owners and are included for personal,
non-commercial use. If you're a rights holder and want them removed, email
[hassandev45@gmail.com](mailto:hassandev45@gmail.com) or open an issue.

<div align="center"><sub>Made by <a href="https://github.com/hassan-xsf">Hassan</a>. If a face made your band better, a star helps others find it.</sub></div>
