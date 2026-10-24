-- Tic Tac Toe watchface: vs CPU (Easy / Hard) or 2 players, scores saved.
-- Switchable: root lets touches through, cells use SHORT_CLICKED and bubble,
-- so a long-press anywhere (even on a cell) still reaches the band.

local lvgl = require("lvgl")

local W, H = lvgl.HOR_RES(), lvgl.VER_RES() -- 336 x 480
local DIR = SCRIPT_PATH or "/"
local SAVE = "/data/tictactoe.txt"

local X_COL, O_COL = 0x38BDF8, 0xF472B6
local CELL, CELL_X_WIN, CELL_O_WIN = 0x16181D, 0x0F3446, 0x45173A
local MODES = { "vs CPU · Easy", "vs CPU · Hard", "2 Players" }
local LINES = { {1,2,3}, {4,5,6}, {7,8,9}, {1,4,7}, {2,5,8}, {3,6,9}, {1,5,9}, {3,5,7} }

local fonts = {}
local function font(size)
    if not fonts[size] then
        local ok, f = pcall(lvgl.Font, "MiSans-Demibold", size, "normal")
        fonts[size] = (ok and f) or lvgl.Font("MiSans-Demibold", 28, "normal")
    end
    return fonts[size]
end

-- ------------------------------------------------------------------ state
local board, turn, starter, over, win_line = {}, "x", "x", false, nil
local mode, score = 1, { x = 0, o = 0, d = 0 }

local function load()
    pcall(function()
        local f = io.open(SAVE, "r"); if not f then return end
        local m, x, o, d = f:read("*l"):match("(%d+) (%d+) (%d+) (%d+)"); f:close()
        if m then mode, score = math.min(3, tonumber(m)), { x = tonumber(x), o = tonumber(o), d = tonumber(d) } end
    end)
end
local function save()
    pcall(function()
        local f = io.open(SAVE, "w")
        f:write(string.format("%d %d %d %d", mode, score.x, score.o, score.d)); f:close()
    end)
end
load()

local function vs_cpu() return mode < 3 end

local function winner(b)
    for _, l in ipairs(LINES) do
        local v = b[l[1]]
        if v and v == b[l[2]] and v == b[l[3]] then return v, l end
    end
    for i = 1, 9 do if not b[i] then return nil end end
    return "d"
end

-- perfect play; score from O's (the CPU's) point of view, quicker wins better
local function minimax(b, who, depth)
    local w = winner(b)
    if w == "o" then return 10 - depth elseif w == "x" then return depth - 10 elseif w == "d" then return 0 end
    local best = who == "o" and -99 or 99
    for i = 1, 9 do
        if not b[i] then
            b[i] = who
            local s = minimax(b, who == "o" and "x" or "o", depth + 1)
            b[i] = nil
            if who == "o" then best = math.max(best, s) else best = math.min(best, s) end
        end
    end
    return best
end

local function cpu_move()
    local free = {}
    for i = 1, 9 do if not board[i] then free[#free + 1] = i end end
    if #free == 9 then return ({ 1, 3, 5, 7, 9 })[math.random(5)] end -- skip the 550k-node search
    if mode == 1 and math.random() < 0.45 then return free[math.random(#free)] end -- Easy slips up
    local best, moves = -99, {}
    for _, i in ipairs(free) do
        board[i] = "o"
        local s = minimax(board, "x", 1)
        board[i] = nil
        if s > best then best, moves = s, { i } elseif s == best then moves[#moves + 1] = i end
    end
    return moves[math.random(#moves)] -- random among equals so it doesn't feel scripted
end

-- ------------------------------------------------------------------ screen
local root = lvgl.Object(nil, {
    w = W, h = H, bg_color = 0x000000, bg_opa = lvgl.OPA(100), border_width = 0, pad_all = 0,
})
root:clear_flag(lvgl.FLAG.SCROLLABLE)
root:add_flag(lvgl.FLAG.EVENT_BUBBLE)
root:clear_flag(lvgl.FLAG.CLICKABLE) -- empty space must reach the band (long-press = switch watchface)

-- all text is pre-rendered Poppins (gen_assets.py), so it looks the same on any firmware
local shown_src = {}
local function src(o, file)
    if shown_src[o] ~= file then shown_src[o] = file; o:set { src = DIR .. file .. ".png" } end
end
local function img(parent, file, align, x, y)
    local o = parent:Image { src = DIR .. file .. ".png", align = { type = align, x_ofs = x or 0, y_ofs = y or 0 } }
    shown_src[o] = file
    return o
end
local function show(o, on) if on then o:clear_flag(lvgl.FLAG.HIDDEN) else o:add_flag(lvgl.FLAG.HIDDEN) end end

-- shown only if something throws
local err_label = lvgl.Label(root, {
    text = "", text_color = 0xFF6B6B, text_font = font(16), w = 300,
    align = { type = lvgl.ALIGN.BOTTOM_MID, x_ofs = 0, y_ofs = -8 },
})
local function report(err) err_label:set { text = tostring(err) } end

-- mode pill (tap to cycle; resets scores)
local pill = lvgl.Object(root, {
    w = 178, h = 40, radius = 20, bg_color = 0x1C1C1E, bg_opa = lvgl.OPA(100), border_width = 0, pad_all = 0,
    align = { type = lvgl.ALIGN.TOP_MID, x_ofs = 0, y_ofs = 14 },
})
pill:clear_flag(lvgl.FLAG.SCROLLABLE)
pill:add_flag(lvgl.FLAG.EVENT_BUBBLE)
pill:add_flag(lvgl.FLAG.CLICKABLE)
local pill_text = img(pill, "mode1", lvgl.ALIGN.CENTER)

-- score row: X | draws | O, numbers built from fixed-width digit images
local DW, NUM_Y = 24, 64
local function number(cx, key)
    local d = {}
    for k = 1, 3 do d[k] = img(root, "n" .. key .. "0", lvgl.ALIGN.TOP_MID, cx, NUM_Y) end
    return { cx = cx, key = key, d = d }
end
local function set_number(num, v)
    if num.v == v then return end
    num.v = v
    local s = tostring(math.min(v, 999))
    for k = 1, 3 do
        local o, ch = num.d[k], s:sub(k, k)
        show(o, ch ~= "")
        if ch ~= "" then
            src(o, "n" .. num.key .. ch)
            o:set { align = { type = lvgl.ALIGN.TOP_MID, x_ofs = num.cx + math.floor((k - (#s + 1) / 2) * DW), y_ofs = NUM_Y } }
        end
    end
end
local sx, sd, so = number(-104, "x"), number(0, "d"), number(104, "o")
local tx = img(root, "l_you", lvgl.ALIGN.TOP_MID, -104, 104)
img(root, "l_draw", lvgl.ALIGN.TOP_MID, 0, 104)
local to = img(root, "l_cpu", lvgl.ALIGN.TOP_MID, 104, 104)
-- little bar under whoever's turn it is
local turn_bar = lvgl.Object(root, {
    w = 22, h = 4, radius = 2, bg_color = X_COL, bg_opa = lvgl.OPA(100), border_width = 0,
    align = { type = lvgl.ALIGN.TOP_MID, x_ofs = -104, y_ofs = 120 },
})
turn_bar:clear_flag(lvgl.FLAG.CLICKABLE)

local status = img(root, "s_you_turn", lvgl.ALIGN.TOP_MID, 0, 424)
local again = img(root, "s_again", lvgl.ALIGN.TOP_MID, 0, 456)
show(again, false)

-- 3 x 3 cells, 88 px, 8 px gaps, board from y = 132 to 412
local SIZE, GAP, X0, Y0 = 88, 8, 28, 132
local cells = {}
local new_game, play -- forward

for i = 1, 9 do
    local c, r = (i - 1) % 3, (i - 1) // 3
    local cell = lvgl.Object(root, {
        w = SIZE, h = SIZE, radius = 20, bg_color = CELL, bg_opa = lvgl.OPA(100), border_width = 0, pad_all = 0,
        align = { type = lvgl.ALIGN.TOP_LEFT, x_ofs = X0 + c * (SIZE + GAP), y_ofs = Y0 + r * (SIZE + GAP) },
    })
    cell:clear_flag(lvgl.FLAG.SCROLLABLE)
    cell:add_flag(lvgl.FLAG.EVENT_BUBBLE)
    cell:add_flag(lvgl.FLAG.CLICKABLE)
    local piece = cell:Image { src = DIR .. "x.png", align = lvgl.ALIGN.CENTER }
    piece:add_flag(lvgl.FLAG.HIDDEN)
    cells[i] = { obj = cell, piece = piece, bg = CELL, src = nil, opa = 255, zoom = 256 }
    cell:onevent(lvgl.EVENT.ALL, function(_, code)
        if code == lvgl.EVENT.PRESSED and not over and not board[i] then
            cell:set { bg_color = 0x23262D }
        elseif code == lvgl.EVENT.RELEASED or code == lvgl.EVENT.PRESS_LOST then
            cell:set { bg_color = cells[i].bg }
        elseif code == lvgl.EVENT.SHORT_CLICKED then -- not after a long-press, so switching never places a mark
            local ok, err = pcall(function()
                if over then new_game()
                elseif not board[i] and not (vs_cpu() and turn == "o") then play(i) end
            end)
            if not ok then report(err) end
        end
    end)
end

-- cached setters: only talk to lvgl when something changed
local function cell_bg(c, bg) if c.bg ~= bg then c.bg = bg; c.obj:set { bg_color = bg } end end
local function piece_src(c, who)
    if c.src == who then return end
    c.src = who
    if who then c.piece:set { src = DIR .. who .. ".png" } end
    show(c.piece, who ~= nil)
end
local function piece_opa(c, v) if c.opa ~= v then c.opa = v; c.piece:set { img_opa = v } end end
local function piece_zoom(c, z) if c.zoom ~= z then c.zoom = z; pcall(c.piece.set, c.piece, { zoom = z }) end end

local function refresh_scores()
    set_number(sx, score.x); set_number(sd, score.d); set_number(so, score.o)
    src(tx, vs_cpu() and "l_you" or "l_px"); src(to, vs_cpu() and "l_cpu" or "l_po")
    src(pill_text, "mode" .. mode)
end

local function set_status()
    local s
    if over then
        local w = winner(board)
        if w == "d" then s = "draw"
        elseif vs_cpu() then s = w == "x" and "you_win" or "cpu_win"
        else s = w .. "_win" end
    elseif vs_cpu() then s = turn == "x" and "you_turn" or "cpu_turn"
    else s = turn .. "_turn" end
    src(status, "s_" .. s)
    show(again, over)
    show(turn_bar, not over)
    if not over then
        turn_bar:set { bg_color = turn == "x" and X_COL or O_COL,
            align = { type = lvgl.ALIGN.TOP_MID, x_ofs = turn == "x" and -104 or 104, y_ofs = 120 } }
    end
end

-- ------------------------------------------------------------------ animation
-- one 16 ms timer, only running while something moves: piece pop-in and the CPU delay
local pops, cpu_wait = {}, 0
local timer
local function tick()
    local busy = false
    for i, f in pairs(pops) do
        f = f + 1
        local t = math.min(1, f / 8)
        local u = t - 1
        local z = math.floor(256 * (0.4 + 0.6 * (1 + 2.70158 * u * u * u + 1.70158 * u * u))) -- ease-out-back pop
        if t >= 1 then z = 256; pops[i] = nil else pops[i] = f; busy = true end
        piece_zoom(cells[i], z)
    end
    if cpu_wait > 0 then
        cpu_wait = cpu_wait - 1
        if cpu_wait == 0 then play(cpu_move()) end
        busy = true
    end
    if not busy then timer:pause() end
end
timer = lvgl.Timer { period = 16, cb = function() local ok, err = pcall(tick)
    if not ok then report(err); timer:pause() end end }
timer:pause()
local function animate() timer:resume() end

-- ------------------------------------------------------------------ flow
function play(i)
    board[i] = turn
    piece_src(cells[i], turn)
    piece_zoom(cells[i], 100)
    pops[i] = 0
    local w, line = winner(board)
    if w then
        over = true
        if w == "d" then score.d = score.d + 1 else score[w] = score[w] + 1 end
        save()
        for j = 1, 9 do piece_opa(cells[j], (w == "d") and 140 or 70) end
        if line then
            for _, j in ipairs(line) do
                cell_bg(cells[j], w == "x" and CELL_X_WIN or CELL_O_WIN)
                piece_opa(cells[j], 255)
            end
        end
        refresh_scores()
    else
        turn = turn == "x" and "o" or "x"
        if vs_cpu() and turn == "o" then cpu_wait = 26 end -- ~0.4 s "thinking"
    end
    set_status()
    animate()
end

function new_game()
    board, over, cpu_wait = {}, false, 0
    starter = starter == "x" and "o" or "x" -- alternate who goes first
    turn = starter
    for i = 1, 9 do
        local c = cells[i]
        piece_src(c, nil); piece_opa(c, 255); piece_zoom(c, 256); cell_bg(c, CELL)
    end
    pops = {}
    set_status()
    if vs_cpu() and turn == "o" then cpu_wait = 26; animate() end
end

pill:onevent(lvgl.EVENT.ALL, function(_, code)
    if code == lvgl.EVENT.PRESSED then pill:set { bg_color = 0x2C2C2E }
    elseif code == lvgl.EVENT.RELEASED or code == lvgl.EVENT.PRESS_LOST then pill:set { bg_color = 0x1C1C1E }
    elseif code == lvgl.EVENT.SHORT_CLICKED then
        mode = mode % #MODES + 1
        score = { x = 0, o = 0, d = 0 }
        save()
        refresh_scores()
        starter = "o" -- so new_game() hands the first move to X
        new_game()
    end
end)

math.randomseed(os.time())
refresh_scores()
starter = "o"
new_game()

pageOnPause = function() timer:pause() end
pageOnResume = function() if next(pops) or cpu_wait > 0 then timer:resume() end end

if TTT_TEST then TTT_TEST.api = { play = play, new_game = new_game, board = function() return board end,
    state = function() return turn, over, score, mode end, cpu_move = cpu_move, winner = winner,
    tick = tick, cells = cells, set_mode = function(m) mode = m end } end
