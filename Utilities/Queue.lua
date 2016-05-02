local M = class("Queue")

local QDEBUG = 0
local hmlog = hm.log

function M:ctor()
	self:clear()
	return self
end

function M:push(v)
	self.l_ = self.l_ + 1
	self.q_[self.l_] = v
	if QDEBUG ~= 0 then hmlog.debug("Queue done push, size = " .. self:size()) end
end

function M:top()
	if self:isEmpty() then return nil end
	return self.q_[self.f_]
end

function M:pop()
	if self:isEmpty() then return nil end
	local v = self.q_[self.f_]
	self.q_[self.f_] = nil -- allow gc
	self.f_ = self.f_ + 1
	if QDEBUG ~= 0 then hmlog.debug("Queue done pop, size = " .. self:size()) end
	return v
end

function M:insertAtFirst(v)
	self.f_ = self.f_ - 1
	self.q_[self.f_] = v
	if QDEBUG ~= 0 then hmlog.debug("Queue done push first, size = " .. self:size()) end
end

function M:isEmpty()
	return self.f_ > self.l_
end

function M:size()
	return self.l_ - self.f_ + 1
end

function M:first()
	return self.q_[self.f_]
end

function M:clear()
	self.q_ = {}
	self.f_ = 0 	-- first index
	self.l_ = -1 	-- last index
end

return M