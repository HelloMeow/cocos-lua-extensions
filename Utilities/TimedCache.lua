local M = class("TimedCache")
local CE = class("TCacheElem")
local DEBUG = false
--[[

	life: 单位是秒，如果-1，代表永远有效
]]

function CE:ctor(k, v, life, cleaner)
	self.k = k
	self.v = v
	self.life = life
	self.now = os.time()
	self.cleaner = cleaner
	if DEBUG then hmlog.debug(''..self.__cname..' SET '..tostring(k)..' with life:'..life) end
end

function CE:update(v, life)
	hmlog.debug(''..self.__cname..' UPD '..tostring(k)..' with life:'..life)
	self.v = v
	self.life = life
	self.now = os.time()
end

function CE:get(k)
	if self.life == -1 or os.time() < self.now + self.life then
		if DEBUG then hmlog.debug(''..self.__cname..' GET '..tostring(k)) end
		return self.v
	end
	if DEBUG then hmlog.debug(''..self.__cname..' EPR '..tostring(k)) end
	self.cleaner:clean(self)
	return nil
end

M.instance = M.new()

function M:getInstance()
	if not M.instance.initDone_ then
		M.instance.initDone_ = true
		M.instance:init()
	end
	return M.instance
end

function M:init()
	self.cache_ = {}
end

function M:set(k, v, life)
	if self.cache_[k] then
		if DEBUG then hmlog.debug(''..self.__cname..' UPD '..tostring(k)..'with life:'..life) end
		self.cache_[k]:update(v, life)
	else
		self.cache_[k] = CE.new(k, v, life, self)
	end
	return k
end

function M:get(k)
	local ce = self.cache_[k]
	if ce then return ce:get(k) end
	return nil
end

function M:clean(ce)
	self.cache_[ce.k] = nil
end

function M:cleanAll()
	self.cache_ = {}
end

return M