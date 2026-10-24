-- Desktop check: stub lvgl, play games, assert rules + CPU strength. Run: lua ttt_test.lua
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
    ALIGN = { CENTER = 0, TOP_MID = 1, TOP_LEFT = 3 },
    Font = function() return {} end,
    Object = function(_, p) return obj(p) end,
    Label = function(_, p) return obj(p) end,
    Timer = function(p) local t = obj(p); function t:pause() end; function t:resume() end; return t end,
  }
end
SCRIPT_PATH = "app/lua/"
io.open = function() return nil end -- no save file on the PC
TTT_TEST = {}
dofile("app/lua/main.lua")
local A = TTT_TEST.api
local function tap(i) A.cells[i].obj.cb(nil, 4) end
local function settle() for _ = 1, 60 do A.tick() end end

-- 2 players: X wins the top row, score counts, line highlighted, tap restarts
A.set_mode(3); A.new_game(); A.new_game() -- make X start
local turn = A.state(); if turn ~= "x" then A.new_game() end
for _, i in ipairs({1, 4, 2, 5, 3}) do tap(i) end
local _, over, score = A.state()
assert(over and score.x == 1, "X should win")
assert(A.cells[1].bg ~= A.cells[4].bg, "win line highlighted")
tap(4); assert(next(A.board()) == nil, "tap after game over starts a new one")
tap(5); tap(5); assert(A.board()[5] == "o" or A.board()[5] == "x")
local n = 0; for _ in pairs(A.board()) do n = n + 1 end; assert(n == 1, "occupied cell ignored")

-- Hard CPU never loses: 300 games against a random player
A.set_mode(2)
local losses = 0
for g = 1, 300 do
  A.new_game()
  for _ = 1, 20 do
    local t, o = A.state(); if o then break end
    if t == "x" then
      local free = {}; for i = 1, 9 do if not A.board()[i] then free[#free + 1] = i end end
      tap(free[math.random(#free)])
    else settle() end
  end
  if A.winner(A.board()) == "x" then losses = losses + 1 end
end
assert(losses == 0, "hard CPU lost " .. losses)
local _, _, sc = A.state()
print(string.format("hard vs random: cpu %d, draws %d, you %d", sc.o, sc.d, sc.x))
-- switch check: root + cells bubble, cells use SHORT_CLICKED
print("all tic tac toe checks passed")
