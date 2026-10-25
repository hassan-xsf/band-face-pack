# Installing watchfaces on a Xiaomi band or watch

This uses **Gadgetbridge**: free and open source, with no modded Mi Fitness
and no cracked apps.

You need:
- an Android phone with Gadgetbridge from [F-Droid](https://f-droid.org/packages/nodomain.freeyourgadget.gadgetbridge/)
- the band's **auth key** (one-time, below)
- a `.face` file for your watch from the [download page](https://hassan-xsf.github.io/band-face-pack/)

---

## One-time: pair the band with Gadgetbridge

1. **Pair with Mi Fitness once.** Install the official Mi Fitness app, log in
   and pair the band normally. This registers the band to your Xiaomi account
   and creates its auth key.
2. **Get the auth key on the PC.** Use the
   [Xiaomi Cloud Tokens Extractor](https://github.com/PiotrMachowski/Xiaomi-cloud-tokens-extractor):
   download `token_extractor.exe` from its releases and run it. Log in with
   the same Xiaomi account. When it asks for a server, pick yours (`in`, `de`,
   `sg`, `cn`, … or leave it blank to try all).
   Find your band (for example `Xiaomi Smart Band 10 Pro`, model `miwear.watch.p67gl`).
   **`TOKEN` is the auth key**: 32 hex characters.
   > Keep the key private: anyone with it can talk to your band. It changes
   > every time you re-pair with Mi Fitness.
3. **Free the band from Mi Fitness.** On the phone, open Settings → Apps → Mi
   Fitness → **Force stop**. Uninstalling it is safest. Only one app can be
   connected at a time.
4. **Add the band in Gadgetbridge:**
   1. Open Gadgetbridge, tap **+**, and allow the Bluetooth and location permissions.
   2. When the band shows up in the scan, **long-press it**.
   3. Paste the key into **Auth Key** and go back.
   4. Tap the band to pair. If the band asks you to confirm, accept.
5. In Gadgetbridge, open the band's settings (gear icon) and turn on whatever you want to
   mirror: notifications, weather and so on.

If pairing fails, see [Troubleshooting](#troubleshooting).

---

## Installing a .face

1. **Copy the file to the phone** by USB, Google Drive, Telegram "Saved
   messages", email or anything else.
2. **Open it with Gadgetbridge**:
   - In a file manager, tap the `.face` file, choose **Open with → Gadgetbridge**,
     then tap **Install**. *Or:*
   - In Gadgetbridge, tap the band → **Watchfaces** (the watchface manager) → **+**,
     then pick the file.
3. Wait for the progress bar. It takes a few seconds for small faces and about
   20 s for image-heavy ones like Flappy Bird.
4. **Select it**: in Gadgetbridge's watchface manager, tap it → **Set**. Or on
   the band, long-press the watchface → swipe to the new one → tap it.

### Updating
Newer versions keep the same ID, so installing again **replaces** the old one.

### Removing
Gadgetbridge → watchface manager → the face → **Delete**. You can't delete
the watchface that is currently active, so switch to another one first.

### Try before you install
Open the `.face` in [Band Face Viewer](https://hassan-xsf.github.io/band-face-viewer/) on your PC or phone.
It runs the face in the browser, so you see exactly what you'll get.

---

## Native apps (Mi Band 10 Pro)

`native_flappy.face`, `native_ttt.face` and `native_calc.face` install Flappy Bird, Tic Tac Toe and Calculator as
**apps** in the band's app list, so you keep your normal watchface.

1. **Check your firmware** on the band: Settings → About. It must be **3.201.026** (Global, tested),
   **3.201.016** (Global) or **3.101.043** (China).
2. **Install the `.face`** with Gadgetbridge, exactly like a watchface (see above).
3. **Switch to it on the band.** It shows the app's name and an **Install** button.
4. **Tap Install.** It shows "Installing...", the app adds itself to the app list, and the installer
   face removes itself within a second.
5. **Turn it on, once:** Settings → **Manage apps** → switch the app **On**.
6. Open it from the app list like any other app.

**After the band restarts, the apps are gone.** They are loaded into memory, not installed into the
firmware. Install the `.face` again and tap Install to get them back.

| Installer says | What it means |
|---|---|
| "Firmware x.y.z is not supported yet" | Your firmware isn't one of the three above. Use the watchface versions instead, and [tell us](#need-help) your version. |
| "Not added to apps" with a log | The app loaded but didn't register. Restart the band and try again; if it repeats, send us the text on screen. |
| "Couldn't load ..." or "Copy failed" | Restart the band and install again. If it repeats, send us the text on screen. |

---

## Getting off a broken watchface

If a face takes all touches, shows a blank screen or crashes:

1. In Gadgetbridge, open the **watchface manager**.
2. Tap any other watchface → **Set**. The band switches immediately.
3. Delete the broken one.

This always works because it doesn't need the band's screen at all. Before
installing your own faces, check them in [Band Face Viewer](https://hassan-xsf.github.io/band-face-viewer/):
the Switch check must be green.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Pairing fails or it says "authentication failed" | The key is wrong or old. Re-run the extractor after the **last** Mi Fitness pairing. Check that Mi Fitness is force-stopped or uninstalled. |
| Band not found in the scan | Turn the phone's Bluetooth off and on. On the band, unpair it from the phone's Bluetooth settings if it's listed there. Keep the band close. |
| "Open with" doesn't list Gadgetbridge | Use Gadgetbridge → watchface manager → **+** instead. |
| Install starts, then fails | Reconnect (Gadgetbridge → the band → Connect) and try again. Very large faces (several MB) can time out; shrink the PNGs. |
| A native app installer says **"not supported yet"** | The native apps (Band 10 Pro) support firmware 3.201.026, 3.201.016 and 3.101.043 (CN). On anything else use the watchface versions, and tell us your firmware version. |
| A native app vanished from the app list | The band restarted. Install the `.face` again and tap Install. |
| Blank or black face | It's a Lua error at startup. Open the same `.face` in the viewer and read the Console tab. |
| Can't swipe or long-press away | See [Getting off a broken watchface](#getting-off-a-broken-watchface). |
| Two copies of the same face | They were built with different IDs (renamed folder). Delete the old one. |

---

## Need help?

Open an issue on [GitHub](https://github.com/hassan-xsf/band-face-pack/issues/new/choose), or email
**[hassandev45@gmail.com](mailto:hassandev45@gmail.com)**. Tell us your watch, its firmware version and what you see
on screen.
