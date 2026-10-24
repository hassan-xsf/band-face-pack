-- Desktop check: stub lvgl, drive menu -> play -> game over. Run: lua flappy_test.lua
local objs, used = {}, {}
local function obj(p)
  local o = { props = p or {}, hidden = false }
  if o.props.src then used[o.props.src] = true end
  function o:clear_flag(f) if f == "HIDDEN" then self.hidden = false end; if f == "C" then self.click = false end end
  function o:add_flag(f) if f == "HIDDEN" then self.hidden = true end; if f == "C" then self.click = true end end
  function o:set(q)
    for k, v in pairs(q) do self.props[k] = v end
    if q.src then used[q.src] = true end
  end
  function o:onevent(_, f) self.ev = f end
  function o:Image(q) local c = obj(q); c.parent = self; objs[#objs + 1] = c; return c end
  return o
end
local timer
local EV = { ALL = 0, PRESSED = 1, RELEASED = 2, PRESS_LOST = 3, CLICKED = 4 }
package.preload.lvgl = function()
  return {
    HOR_RES = function() return 336 end, VER_RES = function() return 480 end,
    OPA = function(x) return x end,
    FLAG = { HIDDEN = "HIDDEN", SCROLLABLE = "S", CLICKABLE = "C", EVENT_BUBBLE = "B" },
    EVENT = EV,
    Object = function(_, p) return obj(p) end,
    Timer = function(t) timer = t; return { pause = function() end, resume = function() end } end,
  }
end
SCRIPT_PATH = "app/lua/"
FLAPPY_TEST = {}
dofile("app/lua/main.lua")
local api, g = FLAPPY_TEST.api, FLAPPY_TEST.api.g
assert(timer and timer.period == 16, "60 fps timer")

local function click(file, parent)
  for _, o in ipairs(objs) do
    if o.props.src == SCRIPT_PATH .. file and (not parent or o.parent == parent) then
      o.ev(o, EV.PRESSED); o.ev(o, EV.RELEASED); o.ev(o, EV.CLICKED); return
    end
  end
  error("no button " .. file)
end
local function tap() api.root.ev(api.root, EV.PRESSED) end
local function run(n, k) for _ = 1, n do api.step(k or 1) end end

assert(g.state == "menu" and api.root.click == false, "menu lets taps through to the band"); run(30)
tap(); assert(g.state == "menu", "tap on menu background does nothing")
click("btn_score.png"); assert(g.state == "board"); tap(); assert(g.state == "menu", "board closes on tap")
click("pill_day.png"); assert(api.cfg.night, "theme toggles")
click("pill_bird_y.png"); assert(api.cfg.color == 2, "bird colour cycles")

click("btn_play.png", api.menu); assert(g.state == "ready")
local y0 = g.by; run(20); assert(math.abs(g.by - y0) < 6, "no gravity in ready")
assert(api.root.click, "ready takes taps"); tap(); assert(g.state == "play")
run(300); assert(g.state == "over", "falls and dies")
assert(g.by <= api.BASE_Y, "bird stays above ground")

-- autopilot at 60 fps and at 30 fps (k=2): flap when below next gap centre
for _, k in ipairs({ 1, 2 }) do
  click("btn_play.png", nil)
  for _, o in ipairs(objs) do -- the game-over Play button
    if o.props.src == SCRIPT_PATH .. "btn_play.png" and o.parent ~= api.menu then o.ev(o, EV.CLICKED) end
  end
  assert(g.state == "ready"); tap()
  for _ = 1, 6000 // k do
    if g.state ~= "play" then break end
    local target
    for _, p in ipairs(api.pipes) do
      if p.x + 52 >= api.BIRD_X - 14 and (not target or p.x < target.x) then target = p end
    end
    if target and g.by > target.gap_y + api.GAP / 2 + 8 and g.vy >= 0 then tap() end
    api.step(k)
  end
  assert(g.score >= 10, "autopilot k=" .. k .. " scored " .. g.score)
  print("k=" .. k .. " score " .. g.score .. " state " .. g.state)
  run(200)
  assert(g.state == "over" and not api.over_btns[1].hidden, "game over panel + buttons shown")
  assert(api.root.click == false, "game over lets taps through to the band")
end
assert(api.cfg.best >= 10, "best saved in cfg")

-- every sprite the game referenced exists on disk
local n = 0
for path in pairs(used) do
  local f = assert(io.open(path, "rb"), "missing sprite " .. path); f:close(); n = n + 1
end
print("all flappy checks passed (" .. n .. " sprites referenced)")
