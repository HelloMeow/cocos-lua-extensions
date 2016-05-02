local M = {}
local logd = require "hmlog".debug
local DEBUG = 0

local t = {}
local mkv
local pkv

-- set(k, nil) means remove k
function M.set(k, v)
    assert(mkv, 'Set memKV first!')

    if v == nil then
        mkv.remove(k)
        if pkv then pkv.remove(k) end
    else
        mkv.set(k, v)
        if pkv then pkv.set(k, v) end
    end

    if DEBUG>0 then logd("GlobalSwitch:set "..k.." to "..tostring(v)) end
end

function M.get(k, default)
    assert(mkv, 'Set memKV first!')
    return mkv.get(k, default)
end

function M.setMem(k, v)
    if v == nil then
        mkv.remove(k)
    else
        mkv.set(k, v)
    end
end

function M.getMem(k, default)
    return mkv.get(k, default)
end

function M.setMemKV(v)  mkv = v end
function M.setPermKV(v) pkv = v end

function M.loadFromDb()
    for k, v in pairs(pkv.allKVs()) do
        mkv.set(k, v)
    end
end

return M
