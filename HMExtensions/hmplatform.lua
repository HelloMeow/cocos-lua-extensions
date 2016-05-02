local M = {}

--[[
]]

function M.fullPathForFilename(filename)
    if not filename or filename == "" or tolua.type(filename) ~= "string" then return nil end

    local fullpath = cc.FileUtils:getInstance():fullPathForFilename(filename)

    if device.platform == "ios" then
        return fullpath
    elseif device.platform == "android" then
        if fullpath:sub(1,1) ~= "/" then
            if fullpath:sub(1, 7) == "assets/" then
                return fullpath:sub(8)
            end
        end
    end
    return fullpath
end

return M
