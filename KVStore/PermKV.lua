local M = {}

local json = require "cjson"
local log  = require "hmlog"

function M.set(k, v)
    assert(k and v ~= nil)
    k = tostring(k)
    local record = PKVStore.find_by_key(k)()
    if not record then
        record = PKVStore {key=k}
    end
    record.vtype = type(v)
    record.value = json.encode(v)
    record:save()
end

function M.remove(k)
    assert(k)
    k = tostring(k)
    local record = PKVStore.find_by_key(k)()
    if record then
        record:delete()
    end
end

function M.get(k, default)
    assert(k)
    local record = PKVStore.find_by_key(tostring(k))()
    if record then return json.decode(record.value) or default
    else return default end
end

function M.allKVs()
    local t = {}
    for r in PKVStore.find_by_sql "select * from PKVStore" do
        if r.vtype == "number" then
            t[r.key] = checknumber(r.value)
        elseif r.vtype == "boolean" then
            if r.value == "true" then
                t[r.key] = true
            else
                t[r.key] = false
            end
        elseif r.vtype == "table" then
            t[r.key] = json.decode(r.value)
        else
            t[r.key] = r.value
        end
    end
    return t
end

function M.clear()
    -- TBD
    require "hmlog".warn("Not implemented")
end

return M