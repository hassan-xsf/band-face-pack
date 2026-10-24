-- Calculator watchface: plain AMOLED-dark, pure Lua (works on any firmware).
-- Keys: AC/C, backspace, %, ÷ × - +, =, ., ±. Chains left to right; = repeats.

local lvgl = require("lvgl")

local W, H = lvgl.HOR_RES(), lvgl.VER_RES() -- 336 x 480

local BG      = 0x000000
local DIGIT   = 0x1C1C1E
local FUNC    = 0x3A3A3C
local ACCENT  = 0xFF9F0A
local GREY    = 0x8E8E93

local fonts = {}
local function font(size)
    if not fonts[size] then
        local ok, f = pcall(lvgl.Font, "MiSans-Demibold", size, "normal")
        fonts[size] = (ok and f) or lvgl.Font("MiSans-Demibold", 28, "normal")
    end
    return fonts[size]
end

local root = lvgl.Object(nil, {
    w = W, h = H, bg_color = BG, bg_opa = lvgl.OPA(100), border_width = 0, pad_all = 0,
})
root:clear_flag(lvgl.FLAG.SCROLLABLE)
root:add_flag(lvgl.FLAG.EVENT_BUBBLE)
root:clear_flag(lvgl.FLAG.CLICKABLE) -- empty space must reach the band (long-press = switch watchface)

-- ------------------------------------------------------------------ display
local clock = lvgl.Label(root, {
    text = "", text_color = GREY, text_font = font(20),
    align = { type = lvgl.ALIGN.TOP_MID, x_ofs = 0, y_ofs = 14 },
})
local expr_label = lvgl.Label(root, {
    text = "", text_color = GREY, text_font = font(22),
    align = { type = lvgl.ALIGN.TOP_RIGHT, x_ofs = -26, y_ofs = 44 },
})
local display = lvgl.Label(root, {
    text = "0", text_color = 0xFFFFFF, text_font = font(60),
    align = { type = lvgl.ALIGN.TOP_RIGHT, x_ofs = -24, y_ofs = 62 },
})

-- ------------------------------------------------------------------ logic
-- acc <op> cur ; fresh = next digit starts a new number
local acc, op, cur, fresh = nil, nil, "0", true
local last_op, last_b = nil, nil -- for repeated =
local SYM = { ["/"] = "÷", ["x"] = "×", ["-"] = "-", ["+"] = "+" }

local function fmt(v)
    if v ~= v or v == math.huge or v == -math.huge then return "Error" end
    if v == 0 then return "0" end -- also turns -0 into 0
    local s = string.format("%.10g", v)
    if #s > 12 then s = string.format("%.6g", v) end
    return s
end

local function apply(a, o, b)
    if o == "+" then return a + b end
    if o == "-" then return a - b end
    if o == "x" then return a * b end
    if o == "/" then return b == 0 and 0 / 0 or a / b end
    return b
end

-- "1234567.5" -> "1,234,567.5" (plain digits only; leaves "1e+20" alone)
local function pretty(s)
    local sign, int, rest = s:match("^(%-?)(%d+)(.*)$")
    if not int or rest:find("e") then return s end
    int = int:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return sign .. int .. rest
end

local shown_size
local function refresh()
    local text = pretty(cur)
    local n = #text
    local size = n <= 7 and 60 or n <= 9 and 50 or n <= 11 and 42 or 34
    if size ~= shown_size then
        shown_size = size
        -- keep the number's baseline at the same place whatever the size
        display:set { text_font = font(size),
            align = { type = lvgl.ALIGN.TOP_RIGHT, x_ofs = -24, y_ofs = 62 + (60 - size) } }
    end
    display:set { text = text }
end

local set_expr, update_keys -- defined below / after the keys exist

local function press(k)
    if cur == "Error" and k ~= "AC" then return end
    if k:match("^%d$") then
        if fresh or cur == "0" then cur = k
        elseif #cur:gsub("[^%d]", "") < 12 then cur = cur .. k end
        if fresh and not op then set_expr("") end
        fresh = false
    elseif k == "." then
        if fresh then cur = "0." elseif not cur:find(".", 1, true) then cur = cur .. "." end
        if fresh and not op then set_expr("") end
        fresh = false
    elseif k == "AC" then
        if not fresh and cur ~= "0" then cur, fresh = "0", true -- C: clear entry only
        else acc, op, cur, fresh, last_op = nil, nil, "0", true, nil; set_expr("") end
    elseif k == "<" then
        if not fresh then
            cur = cur:sub(1, -2)
            if cur == "" or cur == "-" then cur, fresh = "0", true end
        end
    elseif k == "+/-" then
        if cur ~= "0" then cur = cur:sub(1, 1) == "-" and cur:sub(2) or "-" .. cur end
    elseif k == "%" then
        local v = tonumber(cur)
        -- 200 + 10% = 220 ; 50 x 10% = 5
        cur = fmt((acc and (op == "+" or op == "-")) and acc * v / 100 or v / 100)
        fresh = true
    elseif k == "=" then
        local a, o, b
        if op then a, o, b = acc, op, tonumber(cur)
        elseif last_op then a, o, b = tonumber(cur), last_op, last_b
        else return update_keys() end
        cur = fmt(apply(a, o, b))
        set_expr(pretty(fmt(a)) .. " " .. SYM[o] .. " " .. pretty(fmt(b)) .. " =")
        acc, op, fresh, last_op, last_b = nil, nil, true, o, b
    else -- operator
        if op and not fresh then
            cur = fmt(apply(acc, op, tonumber(cur)))
            if cur == "Error" then acc, op = nil, nil; set_expr(""); refresh(); return update_keys() end
        end
        acc, op, fresh, last_op = tonumber(cur), k, true, nil
        set_expr(pretty(cur) .. " " .. SYM[k])
    end
    refresh()
    update_keys()
end

function set_expr(t) expr_label:set { text = t } end

-- ------------------------------------------------------------------ keys
local KEYS = {
    { "AC", "<", "%", "/" },
    { "7", "8", "9", "x" },
    { "4", "5", "6", "-" },
    { "1", "2", "3", "+" },
    { "+/-", "0", ".", "=" },
}
local LABEL = { ["/"] = "÷", ["x"] = "×", ["+/-"] = "±" }
-- 4 x 5 pills, 72 x 60, gaps 8: 312 wide (12 px sides), rows from y=134 to 466
local BW, BH, GX, GY, X0, Y0 = 72, 60, 8, 8, 12, 134

local function lighten(c)
    local r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
    r, g, b = math.min(255, r + 48), math.min(255, g + 48), math.min(255, b + 48)
    return (r << 16) | (g << 8) | b
end

local keys = {} -- k -> { obj, label, bg, fg }

local function paint(key, pressed)
    local bg = pressed and lighten(key.bg) or key.bg
    if key.shown ~= bg then key.obj:set { bg_color = bg }; key.shown = bg end
    if key.shown_fg ~= key.fg then key.label:set { text_color = key.fg }; key.shown_fg = key.fg end
end

for r, row in ipairs(KEYS) do
    for c, k in ipairs(row) do
        local is_op = SYM[k] ~= nil or k == "="
        local is_fn = k == "AC" or k == "<" or k == "%" or k == "+/-"
        local bg = is_op and ACCENT or is_fn and FUNC or DIGIT
        local obj = lvgl.Object(root, {
            w = BW, h = BH, radius = BH // 2, bg_color = bg, bg_opa = lvgl.OPA(100),
            border_width = 0, pad_all = 0,
            align = { type = lvgl.ALIGN.TOP_LEFT, x_ofs = X0 + (c - 1) * (BW + GX), y_ofs = Y0 + (r - 1) * (BH + GY) },
        })
        obj:clear_flag(lvgl.FLAG.SCROLLABLE)
        obj:add_flag(lvgl.FLAG.EVENT_BUBBLE)
        obj:add_flag(lvgl.FLAG.CLICKABLE)
        local label = lvgl.Label(obj, {
            text = LABEL[k] or k, text_color = 0xFFFFFF, align = lvgl.ALIGN.CENTER,
            text_font = font(is_op and 34 or (#k > 1 and 26 or 32)),
        })
        local key = { obj = obj, label = label, bg = bg, base_bg = bg, fg = 0xFFFFFF, shown = bg, shown_fg = 0xFFFFFF }
        keys[k] = key
        obj:onevent(lvgl.EVENT.ALL, function(_, code)
            if code == lvgl.EVENT.PRESSED then paint(key, true)
            elseif code == lvgl.EVENT.RELEASED or code == lvgl.EVENT.PRESS_LOST then paint(key, false)
            elseif code == lvgl.EVENT.CLICKED then
                local ok, err = pcall(press, k)
                if not ok then cur = "Error"; set_expr(tostring(err)); refresh() end
            end
        end)
    end
end

-- the chosen operator turns white (until the next number starts); AC shows "C" mid-entry
function update_keys()
    for k in pairs(SYM) do
        local key, on = keys[k], (op == k and fresh)
        key.bg, key.fg = on and 0xFFFFFF or key.base_bg, on and ACCENT or 0xFFFFFF
        paint(key, false)
    end
    local ac = (not fresh and cur ~= "0") and "C" or "AC"
    if keys.AC.text ~= ac then keys.AC.label:set { text = ac }; keys.AC.text = ac end
end

refresh()
update_keys()

-- ------------------------------------------------------------------ clock
local ok_dm, dataman = pcall(require, "dataman")
if ok_dm and dataman then
    local hh, mm = 0, 0
    local function show() clock:set { text = string.format("%02d:%02d", hh, mm) } end
    pcall(dataman.subscribe, "timeHour", clock, function(_, v) hh = v // 256; show() end)
    pcall(dataman.subscribe, "timeMinute", clock, function(_, v) mm = v // 256; show() end)
end

if CALC_TEST then CALC_TEST.press, CALC_TEST.display, CALC_TEST.expr, CALC_TEST.keys = press, display, expr_label, keys end
