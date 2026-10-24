-- Stride: running/walking watchface. Day view: time, steps with goal bar,
-- distance (km and metres), active time, live pace. Walk session: start,
-- pause, resume, end; shows walk time, distance, steps, average pace, cadence.
-- Tap the tiles to flip pages: activity, body (heart, calories, SpO2,
-- stress), rest (sleep, stand, goals).
-- Art and number glyphs come from gen_assets.py.

local lvgl = require("lvgl")
local dataman = require("dataman")

local W, H = lvgl.HOR_RES(), lvgl.VER_RES()
local DIR = SCRIPT_PATH or "/"
local SAVE = "/data/stride.txt"
local HIDDEN = lvgl.FLAG.HIDDEN

-- tuning: the band gives no distance/active time to faces, so both come from steps
local STRIDE_M = 0.74        -- metres per step; your height in cm * 0.42 / 100
local ACTIVE_SPM = 105       -- average steps per active minute
local RUN_SPM, WALK_SPM = 140, 60
local PACE_WINDOW = 90       -- seconds of step history for the live pace
local MAX_SPM = 250          -- faster than any human: a batch of synced steps, not pace

-- layout (must match gen_assets.py)
local TIME_Y, HERO_LBL_Y, HERO_Y, BAR_Y = 52, 122, 142, 200
local TILES = { { 20, 222 }, { 174, 222 }, { 20, 312 }, { 174, 312 } }
local VAL_DY, DOTS_Y, BTN_Y = 40, 401, 412

-- GLYPHS (written by gen_assets.py)
local GW = {
    h = { ["0"] = 42, ["1"] = 42, ["2"] = 42, ["3"] = 42, ["4"] = 42, ["5"] = 42, ["6"] = 42, ["7"] = 42, ["8"] = 42, ["9"] = 42, _h = 57 },
    n = { ["0"] = 42, ["1"] = 42, ["2"] = 42, ["3"] = 42, ["4"] = 42, ["5"] = 42, ["6"] = 42, ["7"] = 42, ["8"] = 42, ["9"] = 42, _h = 57 },
    s = { ["0"] = 36, ["1"] = 36, ["2"] = 36, ["3"] = 36, ["4"] = 36, ["5"] = 36, ["6"] = 36, ["7"] = 36, ["8"] = 36, ["9"] = 36, [","] = 13, [":"] = 12, _h = 50 },
    p = { ["0"] = 14, ["1"] = 14, ["2"] = 14, ["3"] = 14, ["4"] = 14, ["5"] = 14, ["6"] = 14, ["7"] = 14, ["8"] = 14, ["9"] = 14, ["%"] = 19, _h = 21 },
    g = { ["0"] = 11, ["1"] = 11, ["2"] = 11, ["3"] = 11, ["4"] = 11, ["5"] = 11, ["6"] = 11, ["7"] = 11, ["8"] = 11, ["9"] = 11, [","] = 4, ["%"] = 14, _h = 16 },
    d = { ["0"] = 22, ["1"] = 22, ["2"] = 22, ["3"] = 22, ["4"] = 22, ["5"] = 22, ["6"] = 22, ["7"] = 22, ["8"] = 22, ["9"] = 22, ["."] = 8, [","] = 8, ["k"] = 11, ["m"] = 16, ["'"] = 8, ["/"] = 10, ["-"] = 14, ["%"] = 29, ["b"] = 12, ["p"] = 12, _h = 31 },
    a = { ["0"] = 22, ["1"] = 22, ["2"] = 22, ["3"] = 22, ["4"] = 22, ["5"] = 22, ["6"] = 22, ["7"] = 22, ["8"] = 22, ["9"] = 22, ["h"] = 12, ["m"] = 16, [" "] = 6, [","] = 8, ["k"] = 11, ["c"] = 11, ["a"] = 12, ["l"] = 6, ["-"] = 14, ["%"] = 29, _h = 31 },
    c = { ["0"] = 22, ["1"] = 22, ["2"] = 22, ["3"] = 22, ["4"] = 22, ["5"] = 22, ["6"] = 22, ["7"] = 22, ["8"] = 22, ["9"] = 22, ["s"] = 11, ["p"] = 12, ["m"] = 16, ["b"] = 12, ["-"] = 14, ["%"] = 29, _h = 31 },
    e = { ["0"] = 22, ["1"] = 22, ["2"] = 22, ["3"] = 22, ["4"] = 22, ["5"] = 22, ["6"] = 22, ["7"] = 22, ["8"] = 22, ["9"] = 22, ["-"] = 14, ["%"] = 29, ["b"] = 12, ["p"] = 12, ["m"] = 16, _h = 31 },
    v = { ["0"] = 22, ["1"] = 22, ["2"] = 22, ["3"] = 22, ["4"] = 22, ["5"] = 22, ["6"] = 22, ["7"] = 22, ["8"] = 22, ["9"] = 22, ["-"] = 14, ["%"] = 29, ["."] = 8, ["k"] = 11, ["m"] = 16, ["/"] = 10, ["h"] = 12, _h = 31 },
    colon = { _h = 16 },
}
-- /GLYPHS

-- ---------------------------------------------------------------- helpers
-- every set is cached: lvgl only gets told about real changes
local pos, srcs, vis = {}, {}, {}
local function at(o, x, y)
    x, y = math.floor(x), math.floor(y)
    local p = pos[o]
    if not p then p = {}; pos[o] = p end
    if p.x ~= x or p.y ~= y then o:set { x = x, y = y }; p.x, p.y = x, y end
end
local function src(o, file)
    if srcs[o] ~= file then o:set { src = DIR .. file }; srcs[o] = file end
end
local function show(o, on)
    if vis[o] == on then return end
    vis[o] = on
    if on then o:clear_flag(HIDDEN) else o:add_flag(HIDDEN) end
end

local root = lvgl.Object(nil, {
    w = W, h = H, bg_color = 0x000000, bg_opa = lvgl.OPA(100), border_width = 0, pad_all = 0,
})
root:clear_flag(lvgl.FLAG.SCROLLABLE)
root:add_flag(lvgl.FLAG.EVENT_BUBBLE) -- keep: lets long-press/swipe reach the system
root:clear_flag(lvgl.FLAG.CLICKABLE)  -- only the buttons take taps

local function img(file, x, y)
    local o = root:Image { src = DIR .. file }
    srcs[o] = file
    o:add_flag(lvgl.FLAG.EVENT_BUBBLE)
    at(o, x or 0, y or 0)
    return o
end
local function box(color, x, y, w, h, r)
    local o = lvgl.Object(root, {
        w = w, h = h, bg_color = color, bg_opa = lvgl.OPA(100), radius = r, border_width = 0, pad_all = 0,
    })
    o:clear_flag(lvgl.FLAG.SCROLLABLE)
    o:clear_flag(lvgl.FLAG.CLICKABLE)
    o:add_flag(lvgl.FLAG.EVENT_BUBBLE)
    at(o, x, y)
    return o
end
-- image button: sinks 2px while held, acts on click
local function button(file, x, y, fn)
    local b = img(file, x, y)
    b:add_flag(lvgl.FLAG.CLICKABLE)
    b:onevent(lvgl.EVENT.ALL, function(_, code)
        if code == lvgl.EVENT.PRESSED then at(b, x, y + 2)
        elseif code == lvgl.EVENT.RELEASED or code == lvgl.EVENT.PRESS_LOST then at(b, x, y)
        elseif code == lvgl.EVENT.CLICKED then pcall(fn) end
    end)
    return b
end

-- sprite text in one glyph style; glyph files are <style><byte>.png
local function text(style, n)
    local t = { style = style, objs = {} }
    for i = 1, n do t.objs[i] = img(style .. "48.png"); show(t.objs[i], false) end
    return t
end
-- align: "left" | "right"; returns the drawn width
local function put(t, s, x, y, align, style)
    style = style or t.style
    local gw = GW[style]
    local w = 0
    for i = 1, #s do w = w + (gw[s:sub(i, i)] or 0) end
    local cx = align == "right" and x - w or x
    for i, o in ipairs(t.objs) do
        local c = s:sub(i, i)
        if c ~= "" and c ~= " " then
            src(o, style .. c:byte() .. ".png"); at(o, cx, y); show(o, true)
        else
            show(o, false)
        end
        cx = cx + (gw[c] or 0)
    end
    return w
end
local function hide(t) for _, o in ipairs(t.objs) do show(o, false) end end

local function commas(n)
    local s = tostring(math.floor(n))
    return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end
local function clock(sec) -- 12:34 or 1:02:03
    local h, m, s = sec // 3600, sec // 60 % 60, sec % 60
    return h > 0 and string.format("%d:%02d:%02d", h, m, s) or string.format("%d:%02d", m, s)
end

-- ---------------------------------------------------------------- session
-- state 0 idle, 1 walking, 2 paused. Steps and calories are the band's day
-- totals, so the walk keeps a baseline (-1 = not seen yet) and what passed
-- while paused; carry keeps steps going past the midnight reset. Heart rate,
-- SpO2 and stress only count readings that arrive during the walk (-1 = none).
local FIELDS = { "state", "start", "paused", "pause_at", "acc", "since", "carry",
                 "cal0", "cal_paused", "cal_pause_at", "hr_sum", "hr_n", "hr_max", "spo2", "stress" }
local sess = {}
local function reset_sess()
    for _, k in ipairs(FIELDS) do sess[k] = 0 end
    sess.start, sess.cal0, sess.spo2, sess.stress = -1, -1, -1, -1
end
reset_sess()
pcall(function()
    local f = io.open(SAVE, "r"); if not f then return end
    local v = {}
    for n in (f:read("*l") or ""):gmatch("-?%d+") do v[#v + 1] = tonumber(n) end
    f:close()
    if #v == #FIELDS then for i, k in ipairs(FIELDS) do sess[k] = v[i] end end
end)
local function save()
    pcall(function()
        local v = {}
        for i, k in ipairs(FIELDS) do v[i] = string.format("%d", sess[k]) end
        local f = io.open(SAVE, "w")
        f:write(table.concat(v, " ")); f:close()
    end)
end

local st = { h = 0, m = 0, wk = "MON", day = 1, mon = 1, batt = 0, steps = 0, have_steps = false,
             goal = 10000, spm = 0 }
local health = {} -- hr, cal, spo2, stress, sleep, stand, calpct, standpct; missing = "--"
local function total() return st.steps + sess.carry end
local function sess_steps()
    if sess.start < 0 then return 0 end
    local upto = sess.state == 2 and sess.pause_at or total()
    return math.max(0, upto - sess.start - sess.paused)
end
local function sess_cal()
    if sess.cal0 < 0 or not health.cal then return nil end
    local upto = sess.state == 2 and sess.cal_pause_at or health.cal
    return math.max(0, upto - sess.cal0 - sess.cal_paused)
end
local function sess_secs()
    return sess.acc + (sess.state == 1 and math.max(0, os.time() - sess.since) or 0)
end

-- ------------------------------------------------------------------ scene
local bg = img("bg_day.png", 0, 0)

-- status row: date (day view) or REC/PAUSED (walk), battery right
local wk = img("wk_MON.png", 30, 24)
local day = text("g", 2)
local mon = img("mo1.png", 0, 24)
local status = img("st_rec.png", 24, 21)
local batt_txt = text("g", 4)
local batt_fill = box(0xF5F5F7, W - 50, 27, 20, 8, 1)

-- time
local hours = text("h", 2)
local colon = img("colon.png")
local mins = text("n", 2)

-- hero: steps (day) or walk time (session)
local hero = text("s", 8)
local pct_txt = text("p", 4)
local of_img = img("of.png")
local goal_txt = text("g", 7)
local bar = box(0xC6F432, 24, BAR_Y, 10, 10, 5)

-- tiles: label image + value per tile; tap the area to flip pages
local tiles = {}
for i, p in ipairs(TILES) do
    tiles[i] = { lbl = img("lbl_distance.png", p[1] + 14, p[2] + 12), val = text("d", 9) }
end
local pill = img("pill_idle.png")
local page = 1
local dots = {}
for i = 1, 3 do dots[i] = box(0x48484A, 0, DOTS_Y, 6, 6, 3) end

-- ------------------------------------------------------------------ drawing
local function draw_time()
    local cw = GW.h["0"]
    local colon_w = GW.colon._h + 4
    local x = (W - (cw * 4 + colon_w)) // 2
    put(hours, string.format("%02d", st.h), x, TIME_Y, "left")
    at(colon, x + cw * 2 + 2, TIME_Y)
    put(mins, string.format("%02d", st.m), x + cw * 2 + colon_w, TIME_Y, "left")
end

local function draw_status()
    local walk = sess.state > 0
    show(wk, not walk); show(mon, not walk); show(status, walk)
    if walk then
        hide(day)
        src(status, sess.state == 1 and "st_rec.png" or "st_paused.png")
    else
        src(wk, "wk_" .. st.wk .. ".png")
        local x = 30 + 40
        x = x + put(day, tostring(st.day), x, 24, "left") + 6
        src(mon, "mo" .. st.mon .. ".png"); at(mon, x, 24)
    end
end

local function draw_batt()
    put(batt_txt, st.batt .. "%", W - 58, 24, "right")
    batt_fill:set { w = math.max(2, st.batt * 20 // 100), bg_color = st.batt <= 20 and 0xFF375F or 0xF5F5F7 }
end

local function km(m) return string.format(m >= 100000 and "%.1f" or "%.2f", m / 1000) .. "km" end
local function num(v, unit) return v and (math.floor(v) .. unit) or "--" end

-- one page = 4 tiles of { label, glyph style, text }
local function tile_data()
    if sess.state > 0 and page > 1 then -- walk pages: only readings from this walk
        local secs, steps = sess_secs(), sess_steps()
        if page == 2 then
            return { { "heart", "c", num(health.hr ~= 0 and health.hr, "bpm") }, { "cal", "a", num(sess_cal(), "kcal") },
                     { "avghr", "d", num(sess.hr_n > 0 and sess.hr_sum / sess.hr_n, "bpm") },
                     { "maxhr", "e", num(sess.hr_max > 0 and sess.hr_max, "bpm") } }
        end
        local kmh = secs >= 30 and steps * STRIDE_M * 3.6 / secs or nil
        return { { "spo2", "d", num(sess.spo2 > 0 and sess.spo2, "%") }, { "stress", "e", num(sess.stress >= 0 and sess.stress, "") },
                 { "avgcad", "c", num(secs >= 30 and steps * 60 / secs, "spm") },
                 { "speed", "v", kmh and string.format("%.1fkm/h", kmh) or "--" } }
    elseif page == 2 then
        return { { "heart", "c", num(health.hr ~= 0 and health.hr, "bpm") }, { "cal", "a", num(health.cal, "kcal") },
                 { "spo2", "d", num(health.spo2 ~= 0 and health.spo2, "%") }, { "stress", "e", num(health.stress, "") } }
    elseif page == 3 then
        return { { "sleep", "v", num(health.sleep ~= 0 and health.sleep, "") }, { "stand", "a", num(health.stand, "h") },
                 { "calgoal", "e", num(health.calpct, "%") }, { "standgoal", "c", num(health.standpct, "%") } }
    elseif sess.state > 0 then
        local steps, secs = sess_steps(), sess_secs()
        local metres = steps * STRIDE_M
        local pace = "-'--/km"
        if metres >= 50 then -- average pace, min/km
            local p = math.min(5999, math.floor(secs * 1000 / metres + 0.5))
            pace = string.format("%d'%02d/km", p // 60, p % 60)
        end
        return { { "distance", "d", km(metres) }, { "steps", "a", commas(steps) },
                 { "avgpace", "d", pace }, { "cadence", "c", st.spm .. "spm" } }
    end
    local metres, am = st.steps * STRIDE_M, st.steps // ACTIVE_SPM
    return { { "distance", "d", km(metres) },
             { "active", "a", am < 60 and (am .. "m") or string.format("%dh %02dm", am // 60, am % 60) },
             { "metres", "d", commas(metres) .. "m" }, { "pace", "c", st.spm .. "spm" } }
end

local function draw_tiles()
    for i, d in ipairs(tile_data()) do
        local t, p = tiles[i], TILES[i]
        src(t.lbl, "lbl_" .. d[1] .. ".png")
        put(t.val, d[3], p[1] + 14, p[2] + VAL_DY, "left", d[2])
    end
    local mode = st.spm >= RUN_SPM and "run" or st.spm >= WALK_SPM and "walk" or "idle"
    src(pill, "pill_" .. mode .. ".png")
    if sess.state > 0 then at(pill, W - 76, HERO_LBL_Y - 2) else at(pill, TILES[4][1] + 84, TILES[4][2] + 12) end
    show(pill, sess.state > 0 or page == 1)
    local x = (W - (16 + 2 * 6 + 2 * 6)) // 2
    for i, d in ipairs(dots) do
        local on = i == page
        d:set { w = on and 16 or 6, bg_color = on and 0xC6F432 or 0x48484A }
        at(d, x, DOTS_Y); x = x + (on and 16 or 6) + 6
    end
end

local function draw_day()
    local s, goal = st.steps, math.max(1, st.goal)
    put(hero, commas(s), 24, HERO_Y, "left")
    put(pct_txt, math.min(999, s * 100 // goal) .. "%", W - 24, HERO_Y + 2, "right")
    local gw = put(goal_txt, commas(goal), W - 24, HERO_Y + 30, "right")
    at(of_img, W - 24 - gw - 30, HERO_Y + 30)
    local fill = math.min(W - 48, (W - 48) * s // goal)
    show(bar, fill > 0)
    if fill > 0 then bar:set { w = math.max(10, fill) } end
end

local function draw_walk()
    put(hero, clock(sess_secs()), 24, HERO_Y, "left")
    if page == 1 then draw_tiles() end
end

local function draw_main()
    local walk = sess.state > 0
    src(bg, walk and "bg_walk.png" or "bg_day.png")
    show(of_img, not walk); show(bar, not walk)
    if walk then hide(pct_txt); hide(goal_txt); draw_walk() else draw_day() end
    draw_tiles()
end

-- ------------------------------------------------------------------ buttons
local btn_main, btn_resume, btn_end
local function draw_buttons()
    show(btn_main, sess.state ~= 2)
    src(btn_main, sess.state == 1 and "btn_pause.png" or "btn_start.png")
    show(btn_resume, sess.state == 2); show(btn_end, sess.state == 2)
end
local function redraw() draw_status(); draw_main(); draw_buttons() end

-- invisible tap zone over the tiles: next page
local zone = box(0x000000, TILES[1][1], TILES[1][2], TILES[2][1] + 142 - TILES[1][1], TILES[3][2] + 82 - TILES[1][2], 0)
zone:set { bg_opa = 0 }
zone:add_flag(lvgl.FLAG.CLICKABLE)
zone:onClicked(function() page = page % 3 + 1; pcall(draw_tiles) end)

btn_main = button("btn_start.png", 24, BTN_Y, function()
    local now = os.time()
    if sess.state == 0 then -- start
        reset_sess()
        sess.state, sess.since = 1, now
        sess.start = st.have_steps and st.steps or -1 -- -1: set on the first push
        sess.cal0 = health.cal or -1
    else                    -- pause
        sess.state, sess.acc, sess.pause_at = 2, sess_secs(), total()
        sess.cal_pause_at = health.cal or 0
    end
    save(); redraw()
end)
btn_resume = button("btn_resume.png", 24, BTN_Y, function()
    sess.paused = sess.paused + math.max(0, total() - sess.pause_at)
    if health.cal then sess.cal_paused = sess.cal_paused + math.max(0, health.cal - sess.cal_pause_at) end
    sess.state, sess.since = 1, os.time()
    save(); redraw()
end)
btn_end = button("btn_end.png", W - 24 - 140, BTN_Y, function()
    reset_sess()
    save(); redraw()
end)

-- live pace: steps per minute over the last PACE_WINDOW seconds of step pushes
local samples = {}
local function update_pace()
    local now = os.time()
    while #samples > 1 and now - samples[2].t >= PACE_WINDOW do table.remove(samples, 1) end
    local first, spm = samples[1], 0
    if first and now - first.t >= 10 then
        spm = math.floor((total() - first.steps) * 60 / (now - first.t) + 0.5)
    end
    if spm > MAX_SPM then samples = { { t = now, steps = total() } }; spm = 0 end
    if spm ~= st.spm then st.spm = spm; draw_tiles() end
end

-- ------------------------------------------------------------------ data
local function sub(name, fn)
    pcall(dataman.subscribe, name, root, function(_, v) pcall(fn, v) end)
end
local WEEK = { [0] = "SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT" }

sub("timeHour", function(v) st.h = v // 256; draw_time() end)
sub("timeMinute", function(v) st.m = v // 256; draw_time() end)
sub("dateDay", function(v) st.day = v // 256; draw_status() end)
sub("dateMonth", function(v) st.mon = math.max(1, math.min(12, v // 256)); draw_status() end)
local wk_str = false -- the band's weekday string wins over the number (its base is unverified)
sub("dateWeek", function(v) if not wk_str then st.wk = WEEK[(v // 256) % 7]; draw_status() end end)
sub("dateWeekStringShortPascalEN", function(v)
    if type(v) == "string" and #v >= 3 then wk_str = true; st.wk = v:sub(1, 3):upper(); draw_status() end
end)
sub("systemStatusBattery", function(v) st.batt = math.max(0, math.min(100, v // 256)); draw_batt() end)
-- the first push of each value is the band's last reading, not a new one
local seen = {}
local function hsub(name, key)
    sub(name, function(v)
        v = v // 256
        local fresh = seen[key]
        seen[key], health[key] = true, v
        if sess.state > 0 then
            if key == "cal" and sess.cal0 < 0 then sess.cal0 = v; save()
            elseif key == "hr" and sess.state == 1 and v > 0 then
                sess.hr_sum, sess.hr_n, sess.hr_max = sess.hr_sum + v, sess.hr_n + 1, math.max(sess.hr_max, v); save()
            elseif (key == "spo2" or key == "stress") and fresh then sess[key] = v; save() end
        end
        if page > 1 then draw_tiles() end
    end)
end
hsub("healthHeartRate", "hr"); hsub("healthCalorie", "cal"); hsub("healthOxygenSpO2", "spo2")
hsub("healthStress", "stress"); hsub("healthSleepScore", "sleep"); hsub("healthStandCount", "stand")
hsub("healthCalorieProgress", "calpct"); hsub("healthStandProgress", "standpct")
sub("healthStepTarget", function(v) if v // 256 > 0 then st.goal = v // 256; draw_main() end end)
sub("healthStepCount", function(v)
    local s = v // 256
    if st.have_steps and s < st.steps then -- midnight reset
        sess.carry = sess.carry + st.steps; samples = {}; save()
    end
    st.steps, st.have_steps = s, true
    if sess.state > 0 and sess.start < 0 then sess.start = total(); save() end
    samples[#samples + 1] = { t = os.time(), steps = total() }
    draw_main()
    update_pace()
end)

draw_time(); draw_batt(); redraw()

-- 1 s: walk clock; every 5 s: live pace
local ticks = 0
local timer = lvgl.Timer { period = 1000, cb = function()
    ticks = ticks + 1
    if sess.state == 1 then pcall(draw_walk) end
    if ticks % 5 == 0 then pcall(update_pace) end
end }
pageOnPause = function() timer:pause() end
pageOnResume = function() timer:resume(); pcall(update_pace); pcall(draw_main) end
