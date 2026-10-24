-- Desktop check: stub lvgl, add/delete expenses, assert totals. Run: lua exp_test.lua
local function obj(p)
  local o = { props = p or {}, flags = {} }
  function o:clear_flag(f) self.flags[f] = nil end
  function o:add_flag(f) self.flags[f] = true end
  function o:set(q) for k, v in pairs(q) do self.props[k] = v end end
  function o:onevent(_, f) self.cb = f end
  function o:Image(q) return obj(q) end
  return o
end
package.preload.lvgl = function()
  return {
    HOR_RES = function() return 336 end, VER_RES = function() return 480 end,
    OPA = function(x) return x end, FLAG = { SCROLLABLE = 1, EVENT_BUBBLE = 2, CLICKABLE = 3, HIDDEN = 4 },
    EVENT = { ALL = 0, PRESSED = 1, PRESS_LOST = 3, SHORT_CLICKED = 4, CLICKED = 7, RELEASED = 8 },
    ALIGN = { CENTER = 0, TOP_MID = 1, TOP_LEFT = 3, TOP_RIGHT = 4, LEFT_MID = 5, RIGHT_MID = 6, BOTTOM_MID = 7 },
    Font = function() return {} end,
    Object = function(_, p) return obj(p) end,
    Label = function(_, p) return obj(p) end,
    Timer = function(p) local t = obj(p); function t:pause() end; function t:resume() end; return t end,
  }
end
SCRIPT_PATH = "app/lua/"
local disk = ""  -- fake /data/expenses.txt
io.open = function(_, mode)
  if mode == "r" then return nil end
  local buf = {}
  return { write = function(_, s) buf[#buf + 1] = s end,
           close = function() disk = (mode == "a" and disk or "") .. table.concat(buf) end }
end
EXP_TEST = {}
dofile("app/lua/main.lua")
local A = EXP_TEST.api
local L = A.labels
local function txt(o) return o.s end

-- date math round-trips over 1970..2100
for day = 0, 47500, 7 do
  local y, m, d = A.civil(day)
  assert(A.days_from_civil(y, m, d) == day, "date round trip " .. day)
end
local y, m, d = A.civil(A.days_from_civil(2024, 2, 29)); assert(y == 2024 and m == 2 and d == 29)
assert(A.commas(1234567) == "1,234,567" and A.commas(999) == "999" and A.commas(0) == "0")

-- clock: Thu 23 Oct 2026, 14:05 (12h band: 2 pm)
local c = A.clk
c.y, c.mo, c.d, c.h, c.mi, c.is24, c.am = 2026, 10, 23, 2, 5, false, false

local function add(keys, cat)
  A.go("home"); A.draft.a = 0
  A.go("amount")
  for k in keys:gmatch("%S+") do A.amount_key(k) end
  A.draft.c = cat; A.draft.n = ""; A.go("note")
  A.save_draft()
end

-- 1,250 food today, typed note "Hi" (4 4 pause 4 4 4)
A.go("amount"); A.amount_key("1"); A.amount_key("2"); A.amount_key("5"); A.amount_key("0")
A.amount_key("del"); A.amount_key("0"); assert(A.draft.a == 1250)
A.draft.c = 1; A.go("note"); A.go("type")
A.type_key(4); A.type_key(4)                -- "H" (g -> h)
for _ = 1, 10 do A.tick() end               -- letter commits after 0.9 s
A.type_key(4); A.type_key(4); A.type_key(4) -- "i"
A.type_key(12)
assert(A.draft.n == "Hi", "typed note: " .. A.draft.n)
A.save_draft()
assert(A.current() == "home" and #A.entries == 1)
assert(disk:match("^%d+ 1250 1 Hi\n$"), "saved line: " .. disk)
assert(A.entries[1].t % 86400 == 14 * 3600 + 5 * 60, "12h clock -> 14:05")

add("5 0 0", 2) -- 500 transport today
-- two days ago (Tue) 300 groceries; last month same-ish period 1000
c.d = 21; add("3 0 0", 5)
c.mo, c.d = 9, 10; add("1 0 0 0", 1)
c.mo, c.d = 10, 23; A.go("home")
assert(txt(L.h_total) == "Rs 2,050", txt(L.h_total))
assert(txt(L.h_today) == "Rs 1,750", txt(L.h_today))
assert(txt(L.wk_total) == "Rs 2,050", txt(L.wk_total))
assert(txt(L.h_avg) == "Rs 89", txt(L.h_avg)) -- 2050 / 23
assert(txt(L.h_delta) == "105% more than last month", txt(L.h_delta))

-- chips: your recent note first
A.draft.c = 1; A.draft.n = ""; A.go("note")
assert(A.chips[1].note == "Hi" and A.chips[2].note == "Lunch", A.chips[1].note)
A.chips[2].obj.cb(nil, 4); assert(A.draft.n == "Lunch")
A.chips[2].obj.cb(nil, 4); assert(A.draft.n == "", "tap again clears")

-- month view + list + delete
A.set_sel(2026 * 12 + 9); A.go("month")
assert(txt(L.m_total) == "Rs 2,050", tostring(txt(L.m_total)))
A.open_list(2026 * 12 + 9)
assert(txt(L.l_sub) == "3 expenses, Rs 2,050", txt(L.l_sub))
A.rows[1].b.obj.cb(nil, 4) -- newest: 300 groceries
assert(A.current() == "detail")
A.d_del.obj.cb(nil, 4); assert(A.current() == "detail", "first tap only arms")
A.d_del.obj.cb(nil, 4); assert(A.current() == "list")
assert(txt(L.l_sub) == "2 expenses, Rs 1,750", txt(L.l_sub))
local n = 0; for _ in disk:gmatch("\n") do n = n + 1 end; assert(n == 3, "file rewritten")

-- amount cap 8 digits, 000 on empty stays 0
A.go("amount"); A.draft.a = 0; A.amount_key("000"); assert(A.draft.a == 0)
for _ = 1, 12 do A.amount_key("9") end; assert(A.draft.a == 99999999)
print("all expense checks passed")
