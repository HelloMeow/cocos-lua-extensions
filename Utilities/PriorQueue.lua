local M = class("PriorQueue", require "Queue")

function M:ctor()
    M.super.ctor(self)
    self.cmp_ = function(a, b) return a>b end
    return self
end

function M:push(v)
    local k = self.f_
    for i=self.f_, self.l_ do
        if self.cmp_(v, self.q_[i]) then
            k = i
            break
        end
    end
    self:insertat(v, k)
end

function M:insertat(v, i)
    local j = self.l_
    while j>=i do
        self.q_[j+1] = self.q_[j]
        j = j - 1
    end
    self.q_[i] = v
    self.l_ = self.l_ + 1
end

function M:setcomp(f)
    self.cmp_ = f or self.cmp_
end

return M