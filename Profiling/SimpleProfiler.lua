local M = {}
local hmlog = require "hmlog"
--[[

	Usage:

	local pf = require("path/to/ProfSimple")

	-- start profiling
	pf.start()

	-- stop profiling
	pf.stop()

	-- save results [by default, save as file 'profile.txt']
	-- sort by total_time desc by default
	pf.print()

	----------------------------------------------------------------------------
	TODO:

	* support multiple sort criteria
	* support configuration files
	* support pause/resume
	* ...
]]

--[[
	Configurations
]]

-- function type
local FUNC_TYPE_INCLUDES = {
	"Lua",
}

-- source file
local FILE_EXCLUDES = {
	"cocos",
	"inspect",
	"hmlog",
	"app.libs",
}

-- sort by ?
local SORT_BY = 'total_time'

-- trace type
local TRACE_MASK = "cr"

-- print function
local fp = assert(io.open(cc.FileUtils:getInstance():getWritablePath() .. '/profile.txt', 'a+'))
function _clearfile()
	fp:close()
	assert(cc.FileUtils:getInstance():removeFile(cc.FileUtils:getInstance():getWritablePath() .. '/profile.txt'),
		"remove profile.txt failed")
	fp = assert(io.open(cc.FileUtils:getInstance():getWritablePath() .. '/profile.txt', 'a+'))
end
function _write2file(s)
	fp:write(s)
	fp:write('\n')
	fp:flush()
end
local PRINT = _write2file

--[[
	utilities
]]

local function _strBeginsWith(s, subs)
  if not s or not subs then return false end
  return string.find(s, subs) == 1
end

local function _strEndsWith(s, subs)
	return _strBeginsWith(string.reverse(s), string.reverse(subs))
end

--[[
	Record
]]
local R = {}
function R._get(file, func)
	if not R.t[file] then R.t[file] = {} end

	local t_file = R.t[file]

	if not t_file[func] then
		local t_func = {}
		t_file[func] = t_func

		t_func.log 			= ""
		t_func.calls 		= 0
		t_func.enter_time  	= 0
		t_func.total_time  	= 0

		return t_func
	else
		return t_file[func]
	end
end

function R.enterfunc(file, func)
	local t_func = R._get(file, func)

	t_func.log = t_func.log .. 'c'
	t_func.enter_time = os.clock()
end
function R.leavefunc(file, func)
	local t_func = R._get(file, func)

	if _strEndsWith(t_func.log, 'c') then
		t_func.calls = t_func.calls + 1
		t_func.total_time = t_func.total_time + os.clock() - t_func.enter_time
	end
	t_func.enter_time = 0
	t_func.log = t_func.log .. 'r'
end
function R._sort()

	local sorted = {}

	function insert_sorted(sorted, t_func)
		-- desc
		for i, v in ipairs(sorted) do
			if v.total_time <= t_func.total_time then
				table.insert(sorted, i, t_func)
				return
			end
		end
		sorted[#sorted + 1] = t_func
	end

	for file, t_file in pairs(R.t) do
		for func, t_func in pairs(t_file) do
			t_func.func = func
			t_func.file = file
			insert_sorted(sorted, t_func)
		end
	end

	return sorted
end
function R.print()
	PRINT("total time : " .. R.total_time .. '\n')
	PRINT(R.fmt("file", "func", "call times", "avr. time", "total time"))
	PRINT(string.rep("-", 40+30+12+25+20))
	local sorted = R._sort()

	for _, v in ipairs(sorted) do
		PRINT(R.fmt(v.file, v.func, v.calls, v.total_time/v.calls, v.total_time))
	end
end
function R.fmt(file, func, calls, avrtime, totaltime)
	return string.format("%-40s%-30s%-12s%-25s%-20s",
		file, func, calls, avrtime, totaltime)
end
function R.reset()
	R.t = {}
	_clearfile()
end
function R.start()
	R.reset()
	R.total_time = os.clock()
end
function R.stop()
	R.total_time = os.clock() - R.total_time
end

local _trace

--[[
	Public API
]]
-- methods
function M.start()
	if M.on_ then hmlog.warn("ProfSimple already on~!") return end
	M.on_ = true
	R.start()
	debug.sethook(_trace, TRACE_MASK)
end

function M.stop()
	debug.sethook()
	M.on_ = false
	R.stop()
end

function M.print()
	R.print()
end

--[[
	Private API
]]

local function _func_allowed(t)
	for _,v in ipairs(FUNC_TYPE_INCLUDES) do
		if t == v then return true end
	end
	return false
end

local function _file_allowed(f)
	for _,v in ipairs(FILE_EXCLUDES) do
		if string.find(f, v) then return false end
	end
	return true
end


_trace = function(event)
    local d = debug.getinfo(2, 'nS')
    local file = d.source
    local func_type = d.what
    local func = d.name

    if not file or not func_type or not func then return end
    if not _file_allowed(file) then return end
    if not _func_allowed(func_type) then return end

    if event == 'call' then R.enterfunc(file, func) end
    if event == 'return' then R.leavefunc(file, func) end
end




return M