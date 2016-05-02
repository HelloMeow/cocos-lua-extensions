local M = {}
local DEBUG = false
local log = require "hmlog"
if not DEBUG then
    log = {debug=function()end}
end

local t = {}

-- set(k, nil) means remove k
function M.set(k, v)
    t[k] = v
    log.debug("MemKV.set",k,v)
end

function M.get(k, default)
    return table.get(t, k, default)
end

function M.remove(k)
    t[k] = nil
    log.debug("MemKV.remove "..k)
end

function M.clear()
    t = {}
    log.debug("MemKV.clear")
end

return M