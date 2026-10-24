-- Flappy Bird watchface: pure Lua + lvgl, firmware-independent (no native
-- module). Original Flappy Bird sprites, built by gen_assets.py.
-- Screens: menu -> board (scores) | ready -> play -> dying -> over.

local lvgl = require("lvgl")

local W, H = lvgl.HOR_RES(), lvgl.VER_RES()
local DIR = SCRIPT_PATH or "/"
local SAVE = "/data/flappy.txt"

-- tuning, per 1/60 s frame (FlapPyBird values halved for 60 fps)
local GRAVITY, FLAP, MAX_FALL = 0.25, -4.5, 5
local SPEED = 2
local GAP, SPACING, NPIPES = 105, 180, 3
local BASE_Y = 400                   -- ground top; world is 400 tall like the original
local BIRD_X, HIT_W, HIT_H = 80, 14, 9 -- bird centre x, half hitbox
local ANGLES = { 20, 0, -20, -45, -70, -90 } -- must match gen_assets.py
local WING = { 0, 1, 2, 1 }
local MEDALS = { 10, 20, 30, 40 }    -- bronze, silver, gold, platinum
local COLORS = { "y", "b", "r" }

local HIDDEN = lvgl.FLAG.HIDDEN

-- persisted: best score, theme, bird colour
local cfg = { best = 0, night = false, color = 1 }
pcall(function()
    local f = io.open(SAVE, "r"); if not f then return end
    local b, n, c = f:read("*l"):match("(%d+) (%d) (%d)"); f:close()
    cfg.best, cfg.night, cfg.color = tonumber(b), n == "1", math.max(1, math.min(3, tonumber(c)))
end)
local function save()
    pcall(function()
        local f = io.open(SAVE, "w")
        f:write(string.format("%d %d %d", cfg.best, cfg.night and 1 or 0, cfg.color)); f:close()
    end)
end

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

local function layer(parent, w, h)
    local o = lvgl.Object(parent, {
        w = w, h = h, bg_opa = lvgl.OPA(0), border_width = 0, pad_all = 0, radius = 0,
    })
    o:clear_flag(lvgl.FLAG.SCROLLABLE)
    o:clear_flag(lvgl.FLAG.CLICKABLE)
    o:add_flag(lvgl.FLAG.EVENT_BUBBLE)
    at(o, 0, 0)
    return o
end

local function img(parent, file, x, y)
    local o = parent:Image { src = DIR .. file }
    srcs[o] = file
    o:add_flag(lvgl.FLAG.EVENT_BUBBLE)
    at(o, x or 0, y or 0)
    return o
end

-- original-style button: sinks 2px while held
local function button(parent, file, x, y, fn)
    local b = img(parent, file, x, y)
    b:add_flag(lvgl.FLAG.CLICKABLE)
    b:onevent(lvgl.EVENT.ALL, function(_, code)
        if code == lvgl.EVENT.PRESSED then at(b, x, y + 2)
        elseif code == lvgl.EVENT.RELEASED or code == lvgl.EVENT.PRESS_LOST then at(b, x, y)
        elseif code == lvgl.EVENT.CLICKED then fn() end
    end)
    return b
end

-- sprite number; big digits are 24 wide except "1" (16)
local function number(parent, prefix, digits, big)
    local n = { prefix = prefix, objs = {}, big = big }
    for i = 1, digits do n.objs[i] = img(parent, prefix .. "0.png"); show(n.objs[i], false) end
    return n
end
local function set_number(n, v, x, y, align)
    local s = tostring(math.floor(v)):sub(-#n.objs)
    local function dw(d) return (n.big and d == "1") and 16 or (n.big and 24 or 16) end
    local wid = 0
    for i = 1, #s do wid = wid + dw(s:sub(i, i)) end
    local cx = align == "right" and x - wid or align == "center" and x - wid // 2 or x
    for i, o in ipairs(n.objs) do
        local d = s:sub(i, i)
        if d ~= "" then
            src(o, n.prefix .. d .. ".png"); at(o, cx, y); show(o, true); cx = cx + dw(d)
        else
            show(o, false)
        end
    end
end

-- ------------------------------------------------------------------ scene
local root = lvgl.Object(nil, {
    w = W, h = H, bg_color = 0x000000, bg_opa = lvgl.OPA(100), border_width = 0, pad_all = 0,
})
root:clear_flag(lvgl.FLAG.SCROLLABLE)
root:add_flag(lvgl.FLAG.EVENT_BUBBLE) -- keep: lets long-press/swipe reach the system
-- the background only takes taps while playing. On menu / game over it lets
-- them through, so long-press on empty sky still switches watchface.
local function grab(on)
    if on then root:add_flag(lvgl.FLAG.CLICKABLE) else root:clear_flag(lvgl.FLAG.CLICKABLE) end
end

local bg = img(root, "bg_day.png")
local pipes = {}
for i = 1, NPIPES do
    pipes[i] = { top = img(root, "pipe_g_top.png", W, 0), bot = img(root, "pipe_g_bot.png", W, 0) }
end
local ground = img(root, "base.png", 0, BASE_Y)
local bird = img(root, "bird_y00.png")
local score_num = number(root, "n", 4, true)

local flash = lvgl.Object(root, {
    w = W, h = H, bg_color = 0xFFFFFF, bg_opa = lvgl.OPA(0), border_width = 0, radius = 0,
})
flash:clear_flag(lvgl.FLAG.CLICKABLE); flash:add_flag(lvgl.FLAG.EVENT_BUBBLE)
at(flash, 0, 0); show(flash, false)

-- forward-declared screen switches (buttons call them)
local enter_menu, enter_ready, enter_board

-- menu
local menu = layer(root, W, H)
local title = img(menu, "title.png", 57, 100)
local best_lbl = img(menu, "best.png")
local best_num = number(menu, "s", 4)
local theme_pill, bird_pill
local function apply_theme()
    local c = cfg.night and "r" or "g"
    src(bg, cfg.night and "bg_night.png" or "bg_day.png")
    for _, p in ipairs(pipes) do src(p.top, "pipe_" .. c .. "_top.png"); src(p.bot, "pipe_" .. c .. "_bot.png") end
    src(theme_pill, cfg.night and "pill_night.png" or "pill_day.png")
    src(bird_pill, "pill_bird_" .. COLORS[cfg.color] .. ".png")
end
theme_pill = button(menu, "pill_day.png", 86, 216, function()
    cfg.night = not cfg.night; apply_theme(); save()
end)
bird_pill = button(menu, "pill_bird_y.png", 176, 216, function()
    cfg.color = cfg.color % 3 + 1; apply_theme(); save()
end)
button(menu, "btn_play.png", 44, 290, function() enter_ready() end)
button(menu, "btn_score.png", 176, 290, function() enter_board() end)

-- get ready
local ready = layer(root, W, H)
img(ready, "ready.png", 70, 110)
img(ready, "tutorial.png", 111, 200)

-- score panel (game over + board)
local panel = layer(root, 238, 126)
img(panel, "panel.png")
local medal = img(panel, "medal0.png", 32, 44)
local new_tag = img(panel, "new.png", 128, 79)
local panel_score = number(panel, "s", 4)
local panel_best = number(panel, "s", 4)

-- game over
local over = layer(root, W, H)
local over_text = img(over, "gameover.png", 66, 90)
local over_btns = {
    button(over, "btn_play.png", 44, 310, function() enter_ready() end),
    button(over, "btn_menu.png", 176, 310, function() enter_menu() end),
}

-- ------------------------------------------------------------------ state
local g = { state = "menu", t = 0, by = 0, vy = 0, rot = 0, score = 0, shown = 0,
            ground_x = 0, wing = 0, flash = 0, new_best = false }

local function fill_panel(score, best, new_best, final)
    set_number(panel_score, score, 214, 32, "right")
    set_number(panel_best, best, 214, 76, "right")
    local m = 0
    for i, th in ipairs(MEDALS) do if final >= th then m = i end end
    show(medal, m > 0)
    if m > 0 then src(medal, "medal" .. (m - 1) .. ".png") end
    show(new_tag, new_best)
end

local function draw_bird(angle)
    local best_i, best_d = 1, 999
    for i, a in ipairs(ANGLES) do
        local d = math.abs(a - angle)
        if d < best_d then best_i, best_d = i, d end
    end
    src(bird, string.format("bird_%s%d%d.png", COLORS[cfg.color], WING[g.wing % 4 + 1], best_i - 1))
    at(bird, BIRD_X - 22, g.by - 22)
end

local function place_pipe(p, x)
    p.x, p.passed = x, false
    p.gap_y = math.random(0, math.floor(BASE_Y * 0.6 - GAP)) + math.floor(BASE_Y * 0.2)
    at(p.top, x, p.gap_y - 320)
    at(p.bot, x, p.gap_y + GAP)
end

local function only(screen)
    show(menu, screen == menu); show(ready, screen == ready)
    show(over, screen == over); show(panel, false)
end

function enter_menu()
    g.state, g.t = "menu", 0
    grab(false)
    only(menu)
    for _, s in ipairs(score_num.objs) do show(s, false) end
    for i, p in ipairs(pipes) do place_pipe(p, W + 60 + (i - 1) * SPACING) end
    -- "BEST 12" centred under the title
    local digits = #tostring(cfg.best) * 16
    local x = (W - (44 + 8 + digits)) // 2
    at(best_lbl, x, 176)
    set_number(best_num, cfg.best, x + 52, 171, "left")
end

function enter_board()
    g.state = "board"
    grab(true)
    show(menu, false)
    fill_panel(g.score, cfg.best, false, cfg.best)
    at(panel, 49, 160); show(panel, true)
end

function enter_ready()
    g.state, g.t, g.by, g.vy, g.rot, g.score = "ready", 0, 240, 0, 0, 0
    grab(true)
    only(ready)
    for i, p in ipairs(pipes) do place_pipe(p, W + 60 + (i - 1) * SPACING) end
    set_number(score_num, 0, W // 2, 40, "center")
    draw_bird(0)
end

local function flap()
    g.vy, g.rot = FLAP, 45
end

local function enter_over()
    g.state, g.t = "over", 0
    grab(false)
    g.new_best = g.score > cfg.best
    if g.new_best then cfg.best = g.score; save() end
    for _, s in ipairs(score_num.objs) do show(s, false) end
    only(over)
    for _, b in ipairs(over_btns) do show(b, false) end
    g.shown = 0
    fill_panel(0, g.new_best and 0 or cfg.best, false, 0)
    at(panel, 49, H); show(panel, true)
end

local function die()
    g.state, g.flash = "dying", 1
    show(flash, true)
end

local function hit(p)
    if BIRD_X + HIT_W <= p.x or BIRD_X - HIT_W >= p.x + 52 then return false end
    return g.by - HIT_H < p.gap_y or g.by + HIT_H > p.gap_y + GAP
end

local function ease(t) t = math.max(0, math.min(1, t)); return 1 - (1 - t) ^ 3 end

-- one frame; k = how many 1/60 s frames passed (1 at 60 fps, 2 at 30 fps)
local function step(k)
    g.t = g.t + k
    local s = g.state
    local moving = s == "menu" or s == "ready" or s == "play"
    if moving then
        g.ground_x = (g.ground_x + SPEED * k) % 24
        at(ground, -g.ground_x, BASE_Y)
    end
    if s ~= "dying" and s ~= "over" then g.wing = math.floor(g.t / 6) end

    if s == "menu" or s == "board" then
        local bob = math.sin(g.t * 0.08) * 5
        at(title, 57, 100 + bob)
        g.by = 124 + bob
        src(bird, string.format("bird_%s%d1.png", COLORS[cfg.color], WING[g.wing % 4 + 1]))
        at(bird, 262 - 22, g.by - 22)
        return
    elseif s == "ready" then
        g.by = 240 + math.sin(g.t * 0.08) * 5
        return draw_bird(0)
    end

    if g.flash > 0 then
        g.flash = g.flash - 0.12 * k
        if g.flash <= 0 then show(flash, false) else flash:set { bg_opa = lvgl.OPA(math.floor(g.flash * 100)) } end
    end

    if s == "play" or s == "dying" then
        g.vy = math.min(g.vy + GRAVITY * k, MAX_FALL * (s == "dying" and 2 or 1))
        g.by = math.max(-20, g.by + g.vy * k)
        g.rot = math.max(-90, g.rot - (s == "dying" and 6 or 1.5) * k)
        if g.by + HIT_H >= BASE_Y then
            g.by = BASE_Y - HIT_H
            draw_bird(-90)
            if s == "play" then die() end
            return enter_over()
        end
        draw_bird(math.min(g.rot, 20))
    end

    if s == "play" then
        local far = -1e9
        for _, p in ipairs(pipes) do p.x = p.x - SPEED * k; far = math.max(far, p.x) end
        for _, p in ipairs(pipes) do
            if p.x < -52 then
                place_pipe(p, far + SPACING); far = p.x
            else
                at(p.top, p.x, p.gap_y - 320); at(p.bot, p.x, p.gap_y + GAP)
            end
            if not p.passed and p.x + 26 < BIRD_X then
                p.passed, g.score = true, g.score + 1
                set_number(score_num, g.score, W // 2, 40, "center")
            end
            if hit(p) then return die() end
        end
    elseif s == "over" then
        local t = g.t
        at(over_text, 66, 70 + 20 * ease(t / 12))
        at(panel, 49, H - (H - 160) * ease((t - 12) / 24))
        if t >= 36 and g.shown < g.score then
            g.shown = math.min(g.score, g.shown + math.max(1, g.score // 30))
            fill_panel(g.shown, g.new_best and g.shown or cfg.best, false, 0)
        elseif t >= 36 and not vis[over_btns[1]] then
            fill_panel(g.score, cfg.best, g.new_best, g.score)
            for _, b in ipairs(over_btns) do show(b, true) end
        end
    end
end

root:onevent(lvgl.EVENT.ALL, function(_, code)
    if code ~= lvgl.EVENT.PRESSED then return end
    if g.state == "ready" then g.state = "play"; show(ready, false); flap()
    elseif g.state == "play" then flap()
    elseif g.state == "board" then enter_menu() end
end)

-- frame pacing: measure real callback rate each second, scale physics so
-- game speed is the same whether lvgl delivers 60 or 30 fps
local frames, sec, k = 0, os.time(), 1
local function tick()
    frames = frames + 1
    local now = os.time()
    if now ~= sec then
        if now - sec == 1 and frames > 5 then k = math.max(1, math.min(3, 60 / frames)) end
        sec, frames = now, 0
    end
    step(k)
end

math.randomseed(os.time())
apply_theme()
enter_menu()

local timer = lvgl.Timer { period = 16, cb = tick }
pageOnPause = function() timer:pause() end
pageOnResume = function() sec, frames = os.time(), 0; timer:resume() end

-- desktop test hook (FLAPPY_TEST is only set by flappy_test.lua)
if FLAPPY_TEST then
    FLAPPY_TEST.api = { g = g, cfg = cfg, step = step, pipes = pipes, GAP = GAP, BIRD_X = BIRD_X,
                        BASE_Y = BASE_Y, root = root, srcs = srcs, vis = vis, panel = panel,
                        over_btns = over_btns, menu = menu }
end
