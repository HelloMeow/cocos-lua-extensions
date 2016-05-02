local M = {}

function M.c3b(hex)
  local b = bit.band(hex, 0xff)
  hex = bit.rshift(hex, 8)
  local g = bit.band(hex, 0xff)
  hex = bit.rshift(hex, 8)
  local r = bit.band(hex, 0xff)
  return cc.c3b(r, g, b)
end

function M.c4b(hex, alpha)
  local c3 = M.c3b(hex)
  alpha = alpha or 0xff
  return cc.c4b(c3.r, c3.g, c3.b, alpha)
end

function M.c4f(hex, alpha)
  local c3 = M.c3b(hex)
  alpha = alpha or 0xff
  return cc.c4f(c3.r/255.0, c3.g/255.0, c3.b/255.0, alpha/255.0)
end

function M.randc3b()
  return cc.c3b(math.random(0, 255), math.random(0, 255), math.random(0, 255))
end

function M.randc4b(alpha)
  alpha = alpha or math.random(0, 255)
  return cc.c4b(math.random(0, 255), math.random(0, 255), math.random(0, 255), alpha)
end

return M