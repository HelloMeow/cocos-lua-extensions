local M = class("Queue")

function M:ctor()
	self.q_ = {}
	self.f_ = 0 	-- first index
	self.l_ = -1 	-- last index
	return self
end

function M:push(v)
	self.l_ = self.l_ + 1
	self.q_[self.l_] = v
end

function M:pop()
	if self:isEmpty() then return nil end
	local v = self.q_[self.f_]
	self.q_[self.f_] = nil -- allow gc
	self.f_ = self.f_ + 1
	return v
end

function M:insertAtFirst(v)
	self.f_ = self.f_ - 1
	self.q_[self.f_] = v
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

return M