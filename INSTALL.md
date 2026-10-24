# Installing watchfaces on the Mi Band 10 Pro

This uses **Gadgetbridge**: free and open source, with no modded Mi Fitness
and no cracked apps.

You need:
- an Android phone with Gadgetbridge from [F-Droid](https://f-droid.org/packages/nodomain.freeyourgadget.gadgetbridge/)
- the band's **auth key** (one-time, below)
- a `.face` file from `faces/`, for example `faces/lua_stride.face`

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
   Find the band (`Xiaomi Smart Band 10 Pro`, model `miwear.watch.p67gl`).
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
5. In Gadgetbridge → the band's ⚙ settings, turn on whatever you want to
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

---

## Getting off a broken watchface

If a face takes all touches, shows a blank screen or crashes:

1. In Gadgetbridge, open the **watchface manager**.
2. Tap any other watchface → **Set**. The band switches immediately.
3. Delete the broken one.

This always works because it doesn't need the band's screen at all. Before
installing your own faces, check them in the Band Viewer: the Switch check must be
green.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Pairing fails or it says "authentication failed" | The key is wrong or old. Re-run the extractor after the **last** Mi Fitness pairing. Check that Mi Fitness is force-stopped or uninstalled. |
| Band not found in the scan | Turn the phone's Bluetooth off and on. On the band, unpair it from the phone's Bluetooth settings if it's listed there. Keep the band close. |
| "Open with" doesn't list Gadgetbridge | Use Gadgetbridge → watchface manager → **+** instead. |
| Install starts, then fails | Reconnect (Gadgetbridge → the band → Connect) and try again. Very large faces (several MB) can time out; shrink the PNGs. |
| The face shows **"unsupported firmware"** | The native apps (`faces/apps/`) are built for firmware 3.201.026 only. Use the Lua faces on other firmware. |
| Blank or black face | It's a Lua error at startup. Open the same `.face` in the viewer and read the Console tab. |
| Can't swipe or long-press away | See [Getting off a broken watchface](#getting-off-a-broken-watchface). |
| Two copies of the same face | They were built with different IDs (renamed folder). Delete the old one. |
