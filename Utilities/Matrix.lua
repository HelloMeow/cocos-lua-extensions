local M = class("Matrix")

function M:ctor(rows, cols)
    assert(rows>0 and cols>0)
    self.rows = rows
    self.cols = cols
    self.v_ = {}
end

function M:set(r, c, value)
    self.v_[self:__rc2idx(r, c)] = value
end

function M:get(r, c)
    return self.v_[self:__rc2idx(r, c)]
end

function M:__rc2idx(r, c)
    return (r - 1) * self.cols + c -- 1, ..., rows*cols-rows+cols
end

function M:traverse(func)
    for i=1, self.rows do
        for j=1, self.cols do
            func(i, j, self:get(i, j))
        end
    end
end

return M