local M = class("hmlog")
local inspect = require "inspect"

local fp = assert(io.open(cc.FileUtils:getInstance():getWritablePath() .. '/hmlog.txt', 'a+'))

function M.dumb(...)
	local arg = {...}
	print(inspect(arg))
	fp:write('HMLog :: ')
	fp:write(inspect(arg))
	fp:write('\n')
	fp:flush()
end

function M.clear()
	fp:close()
	assert(cc.FileUtils:getInstance():removeFile(cc.FileUtils:getInstance():getWritablePath() .. '/hmlog.txt'),
		"remove hmlog.log failed")
	fp = assert(io.open(cc.FileUtils:getInstance():getWritablePath() .. '/hmlog.txt', 'a+'))
end

local _msgTable = {
	nil, -- level
	nil, -- time
	nil, -- line
	nil, -- file
	nil, -- data
}

function M._log(lv, file, line, ...)
	local arg = {...}
	local time = string.format('%.5f', os.clock())
	_msgTable[1] = lv
	_msgTable[2] = time
	_msgTable[3] = string.format('%3d', line)
	_msgTable[4] = file
	_msgTable[5] = inspect(arg)
	local msg = table.concat(_msgTable, '|')
	-- output on quick-console
	-- print(msg)
	-- output on Xcode console
	release_print(msg)
	-- write to file
	fp:write(msg)
	fp:write('\n')
	fp:flush()
end
-- 
function M.error(...)
	if HMLOG_LEVEL >= 1 then
		M._log('E', __FILE__(), __LINE__(), ...)
	end
end

function M.warn(...)
	if HMLOG_LEVEL >= 2 then
		M._log('W', __FILE__(), __LINE__(), ...)
	end
end

function M.info(...)
	if HMLOG_LEVEL >= 3 then
		M._log('I', __FILE__(), __LINE__(), ...)
	end
end

function M.debug(...)
	if HMLOG_LEVEL >= 4 then
		M._log('D', __FILE__(), __LINE__(), ...)
	end
end

-- just print
function M.printI(format, ...)
	if HMLOG_LEVEL >= 3 then
		M._log('I', "", 999, string.format(format, ...))
	end
end

-- log with format
function M.infof(format, ...)
	if HMLOG_LEVEL >= 3 then
		M._log('I', __FILE__(), __LINE__(), string.format(format, ...))
	end
end
function M.debugf(format, ...)
	if HMLOG_LEVEL >= 4 then
		M._log('D', __FILE__(), __LINE__(), string.format(format, ...))
	end
end

cc.exports.__FILE__ = function() return debug.getinfo(3, 'S').source end
cc.exports.__LINE__ = function() return debug.getinfo(3, 'l').currentline end
return M