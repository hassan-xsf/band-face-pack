-- port prelude (added by port/port.py): runs a face designed for 336x480 on a
-- SW x SH screen. The face still sees a 336x480 screen; every size, position
-- and font it passes to lvgl is scaled by S and the face is centred at (OX, OY).
-- Its PNGs were already scaled by the same S at build time.
do
    local S, OX, OY, SW, SH = __S__, __OX__, __OY__, __SW__, __SH__
    local real_require, floor = require, math.floor
    local lv = real_require("lvgl")

    local PX = { x = 1, y = 1, w = 1, h = 1, radius = 1, border_width = 1, outline_width = 1,
        outline_pad = 1, shadow_width = 1, shadow_ofs_x = 1, shadow_ofs_y = 1, line_width = 1,
        arc_width = 1, pad_all = 1, pad_top = 1, pad_bottom = 1, pad_left = 1, pad_right = 1,
        pad_row = 1, pad_column = 1, text_letter_space = 1, text_line_space = 1 }
    -- big values are lvgl specials (LV_RADIUS_CIRCLE, LV_SIZE_CONTENT, LV_PCT): leave them
    local function px(v)
        if type(v) ~= "number" or v >= 2000 or v <= -2000 then return v end
        return floor(v * S + 0.5)
    end
    local function props(t)
        if type(t) ~= "table" then return t end
        local o = {}
        for k, v in pairs(t) do
            if PX[k] then o[k] = px(v)
            elseif k == "align" and type(v) == "table" then
                o[k] = { type = v.type, x_ofs = px(v.x_ofs or 0), y_ofs = px(v.y_ofs or 0) }
            else o[k] = v end
        end
        return o
    end

    -- objects are wrapped so every method call goes through the scaling
    local P, methods = {}, {}
    local function wrap(o) return o ~= nil and setmetatable({ __real = o }, P) or nil end
    local function unwrap(v) return type(v) == "table" and rawget(v, "__real") or v end
    local function unwrap_all(...)
        local t = table.pack(...)
        for i = 1, t.n do t[i] = unwrap(t[i]) end
        return table.unpack(t, 1, t.n)
    end
    P.__index = function(_, k)
        local m = methods[k]
        if m then return m end
        if k == "set" then
            m = function(p, t) return p.__real:set(props(t)) end
        elseif k == "onevent" then
            m = function(p, code, cb, ...)
                return p.__real:onevent(code, function(_, ...) return cb(p, ...) end, ...)
            end
        elseif type(k) == "string" and k:match("^on%u") then -- onClicked, onPressed, ...
            m = function(p, cb, ...)
                local r = p.__real
                return r[k](r, function(_, ...) return cb(p, ...) end, ...)
            end
        elseif type(k) == "string" and k:match("^%u") then -- obj:Image{}, obj:Label{}, ...
            m = function(p, t, ...) local r = p.__real; return wrap(r[k](r, props(t), ...)) end
        else
            m = function(p, ...) local r = p.__real; return r[k](r, unwrap_all(...)) end
        end
        methods[k] = m
        return m
    end

    -- a black full-screen stage holds the face; it passes touches through like a root must
    local stage
    local function get_stage()
        if not stage then
            stage = lv.Object(nil, { x = 0, y = 0, w = SW, h = SH, bg_color = 0, bg_opa = lv.OPA(100),
                border_width = 0, pad_all = 0, radius = 0 })
            stage:clear_flag(lv.FLAG.CLICKABLE)
            stage:clear_flag(lv.FLAG.SCROLLABLE)
            stage:add_flag(lv.FLAG.EVENT_BUBBLE)
        end
        return stage
    end
    local function make(kind)
        return function(parent, t, ...)
            if parent == nil then
                local o = props(t or {})
                o.x, o.y = (o.x or 0) + OX, (o.y or 0) + OY
                return wrap(lv[kind](get_stage(), o, ...))
            end
            return wrap(lv[kind](unwrap(parent), props(t), ...))
        end
    end

    local L = setmetatable({
        HOR_RES = function() return 336 end,
        VER_RES = function() return 480 end,
        Object = make("Object"),
        Label = make("Label"),
        Image = make("Image"),
        Font = function(name, size, ...) return lv.Font(name, math.max(8, px(size or 20)), ...) end,
    }, { __index = lv })

    local ok_dm, dm = pcall(real_require, "dataman")
    local D = ok_dm and type(dm) == "table" and setmetatable({
        subscribe = function(name, o, ...) return dm.subscribe(name, unwrap(o), ...) end,
    }, { __index = dm }) or nil

    require = function(name)
        if name == "lvgl" then return L end
        if name == "dataman" then
            if not D then error("dataman not available") end
            return D
        end
        return real_require(name)
    end
    if rawget(_G, "lvgl") then lvgl = L end
    if D and rawget(_G, "dataman") then dataman = D end
end
