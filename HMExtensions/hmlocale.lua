local M = {}
local log = require "hmlog"
function M.getCharList(str)
  -- 支持中文字符串的获取
  local list = {}
  local len = string.len(str)
  local i = 1
  while i <= len do
      local c = string.byte(str, i)
      local shift = 1
      if c > 0 and c <= 127 then
          shift = 1
      elseif (c >= 192 and c <= 223) then
          shift = 2
      elseif (c >= 224 and c <= 239) then
          shift = 3
      elseif (c >= 240 and c <= 247) then
          shift = 4
      end
      local char = string.sub(str, i, i+shift-1)
      i = i + shift
      table.insert(list, char)
  end
  return list
end

function M.getChineseNum(num)
  assert(num >= 0 and num < 100)
  num = checkint(num) -- must be int

  local map0 = {"零", "壹", "贰", "叁", "肆", "伍", "陆", "柒", "捌", "玖"}

  if num < 10 then return map0[num+1] end

  local m1 = math.fmod(num, 10)
  local m2 = math.floor(num / 10)

  local t = {}
  if m2 > 1 then t[#t+1] = map0[m2+1] end
  if m2 > 0 then t[#t+1] = '拾' end
  if m1 > 0 then t[#t+1] = map0[m1+1] end
  return table.concat(t)
end

function M.reverseChineseString(s)
  return table.concat(hm.array.reverse(M.getCharList(s)))
end

function M.minutf8charsforwidth(font, size, width)
    -- single utf8 char size
    local size1 = hm.ui.newTTFLabel({text="是", font=font, size=size}):getContentSize()
    return math.floor(width/size1.width)
end

function M.splitstring(str, cnt)
    str = str or ""
    cnt = cnt or 1

    local t = hm.locale.getCharList(str)

    local ret = {}

    for i=1, math.ceil(#t/cnt) do
        local st = {}
        for j=1, cnt do
            st[#st + 1] = t[j + (i-1)*cnt]
        end
        ret[#ret+1] = table.concat(st)
    end

    return ret
end

return M