local M = {}
local table_remove = table.remove
function M.filter(array, fn)
    if not array then return {} end
    local ret = {}
    for _, elem in ipairs(array) do
        if fn(elem, _) then ret[#ret+1] = elem end
    end
    return ret
end

function M.remove(array, fn, removeall)
    local c, i, max = 0, 1, #array
    while i <= max do
        if fn(array[i]) then
            table_remove(array, i)
            c = c + 1
            i = i - 1
            max = max - 1
            if not removeall then break end
        end
        i = i + 1
    end
    return c
end

function M.todict(array, fn)
    if not array then return {} end
    local t = {}
    for i, v in ipairs(array) do
        local newk, newv = fn(v, i)
        t[newk] = newv
    end
    return t
end

function M.reverse(array)
    local t = {}
    for i=#array, 1, -1 do
        t[#t+1] = array[i]
    end
    return t
end

-- 随机打乱数组a内元素顺序
-- RANDOM-IN-POSITION (算法导论)
function M.shuffle(a)
  local ret = {}
  table.walk(a, function(v) ret[#ret+1]=v end)
  for i=1, #ret do
    local j = math.random(i, #ret)
    ret[i], ret[j] = ret[j], ret[i]
  end
  return ret
end

--随机从数组a中选择m个，如果m==1，直接返回被选中的元素
function M.randompick(a, m)
  local num = m
  if a==nil then return nil end
  if m>#a then m=#a end
  local r = {}

  for _, v in ipairs(a) do
    r[#r+1] = v
  end

  for i=1, #a-m do
    table.remove(r, math.random(1, #r))
  end

  return r
end

function M.removeAt(arr, idx)
  assert(idx>0 and #arr >= idx)
  for i=idx+1, #arr do
    arr[i-1] = arr[i]
  end
  arr[#arr] = nil
  return arr
end

function M.reverse(a)
  local ret = {}
  for i=#a,1,-1 do
    ret[#ret+1] = a[i]
  end
  return ret
end

function M.unique(arr)
  -- find unique and their counts
  table.sort(arr) -- ascending order
  local ret = {{arr[1], 1}}
  local idx = 1
  for i=2, #arr do
    if arr[i] == ret[idx][1] then
      ret[idx][2] = ret[idx][2] + 1
    else
      idx = idx + 1
      ret[idx] = {arr[i], 1}
    end
  end
  return ret -- {{unique_elem, occurrence}, ...}
end

function M.substract(a, b)
  assert(#a > 0 and #b > 0)
  local ret = {}

  local tmp = {}
  for i,v in ipairs(b) do
    tmp[v] = true
  end

  for i,v in ipairs(a) do
    if not tmp[v] then
      ret[#ret+1] = v
    end
  end

  return ret
end

function M.append(a, b)
  assert(a and b and tolua.type(a)=='table' and tolua.type(b)=='table')
  for i,v in ipairs(b) do
    a[#a+1] = v
  end
  return a
end

function M.clone(a)
  local ret = {}
  for i,v in ipairs(a) do
    ret[#ret+1] = v
  end
  return ret
end

return M