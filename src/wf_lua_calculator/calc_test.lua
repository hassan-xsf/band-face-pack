-- Desktop check: stub lvgl, press keys, assert display. Run: lua calc_test.lua
local function obj(props)
  local o = { props = props or {} }
  function o:clear_flag() end
  function o:add_flag() end
  function o:set(p) for k, v in pairs(p) do self.props[k] = v end end
  function o:onevent(_, f) self.cb = f end
  return o
end
package.preload.lvgl = function()
  return {
    HOR_RES = function() return 336 end, VER_RES = function() return 480 end,
    OPA = function(x) return x end, FLAG = {}, EVENT = { ALL = 0, PRESSED = 1, RELEASED = 2, PRESS_LOST = 3, CLICKED = 4 },
    ALIGN = { CENTER = 0, TOP_MID = 1, TOP_RIGHT = 2, TOP_LEFT = 3 },
    Font = function() return {} end,
    Object = function(_, p) return obj(p) end,
    Label = function(_, p) return obj(p) end,
  }
end
CALC_TEST = {}
dofile("app/lua/main.lua")
local T = CALC_TEST
local function tap(seq)
  for k in seq:gmatch("%S+") do T.keys[k].obj.cb(nil, 4) end -- CLICKED through the real handler
  return T.display.props.text
end
local function check(seq, want)
  tap("AC"); tap("AC")
  local got = tap(seq)
  assert(got == want, seq .. " => " .. tostring(got) .. " (want " .. want .. ")")
end
check("1 2 + 3 =", "15")
check("7 - 1 0 =", "-3")
check("6 x 7 =", "42")
check("1 / 3 =", "0.3333333333")
check("1 / 0 =", "Error")
check("2 + 3 x 4 =", "20")         -- chained left to right
check("1 . 5 + . 5 =", "2")
check("9 < 8", "8")
check("5 +/-", "-5")
check("2 0 0 + 1 0 %", "20")       -- 10% of 200
check("2 0 0 + 1 0 % =", "220")
check("5 0 x 1 0 % =", "5")
check("5 0 %", "0.5")
check("2 + 3 = = =", "11")          -- = repeats
check("1 2 3 4 5 6 7", "1,234,567")
check("1 0 0 0 0 0 0 0 x 1 0 0 0 0 0 0 0 =", "1e+14")
check("5 - 5 =", "0")
check("0 . 1 + 0 . 2 =", "0.3")
-- C clears the entry only, AC clears everything
tap("AC"); tap("AC"); tap("9 + 5 AC 2 =")
assert(T.display.props.text == "11", "C should keep 9 +")
assert(T.keys.AC.label.props.text == "AC")
tap("4"); assert(T.keys.AC.label.props.text == "C")
-- operator highlight
tap("AC AC 3 +"); assert(T.keys["+"].fg ~= 0xFFFFFF and T.keys["+"].bg == 0xFFFFFF, "+ should be highlighted")
tap("4"); assert(T.keys["+"].bg ~= 0xFFFFFF, "highlight should clear when typing")
assert(T.expr.props.text == "3 +")
tap("="); assert(T.expr.props.text == "3 + 4 =")
-- error recovers only with AC
tap("AC AC 1 / 0 = 5"); assert(T.display.props.text == "Error")
tap("AC 5"); assert(T.display.props.text == "5")
print("all calc checks passed")
