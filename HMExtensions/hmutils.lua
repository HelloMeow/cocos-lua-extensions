local M = {}

function M.autoIncCounter(startvalue, step)
    local counter = startvalue or 0
    step = step or 1
    return function()
        counter = counter + step
        return counter
    end
end

function M.memoize(fn)
    fn = fn or function(x) return nil end
    return setmetatable({},
		{
			__index = function(t, k)
	           local val = fn(k)
	           t[k] = val
	           return val
	        end,
			__call  = function(t, k)
	           return t[k]
		    end
		})
end

function M.bool2str(b)
	return b and "true" or "false"
end

function M.ccpEqual(a, b)
	return a.x == b.x and a.y == b.y 
end

return M
