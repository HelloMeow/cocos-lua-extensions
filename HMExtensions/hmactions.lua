local M = {}
local scheduler = require "scheduler"

function M.newBounceAction(params)
    local repeattimes = params.rt or 1
    local duration    = params.dt or 1
    local distancexy  = params.disxy
    local target      = params.target
    assert(target)

    local act = cc.Sequence:create(
        cc.MoveBy:create(duration/2, cc.p(distancexy.x, distancexy.y)),
        cc.MoveBy:create(duration/2, cc.p(-1*distancexy.x, -1*distancexy.y))
    )
    if repeattimes == -1 then
        return cc.RepeatForever:create(act)
    else
        return cc.Repeat:create(act, repeattimes)
        -- 这么写不行，必须在函数外写CallFunc
        -- return cc.CallFunc:create(function()target:runAction(cc.Repeat:create(act, repeattimes))end)
    end
    --[[
    20160316 wj
    Now cc.Sequence cannot include cc.RepeatForever directly.
    So a compromised way is to wrap the cc.RepeatForever with a cc.CallFunc
    e.g:
        -- this will fail
        target:runAction(cc.Sequence:create(cc.FadeIn:create(0.8), cc.RepeatForever:create(cc.Blink:create())))
        -- this will work
        target:runAction(
            cc.Sequence:create(
                cc.FadeIn:create(0.8),
                cc.CallFunc:create(target:runAction(cc.RepeatForever:create(cc.Blink:create())))))
    --]]
end

function M.newBlackInOutAction()
    local uifunc = require "uifunc"
    local log = require "hmlog"
    --
    local sp = hm.ui.btnExtends(hm.ui.newLayerColor(display.width, display.height, hm.color.c4b(0)))
    hm.ui.addToCenter(sp, cc.Director:getInstance():getRunningScene())
    sp:setCascadeOpacityEnabled(true)
    sp:setOpacity(0)
    local dt = 1
    return cc.TargetedAction:create(sp, cc.Sequence:create(
        cc.FadeIn:create(dt),
        cc.FadeOut:create(dt),
        cc.RemoveSelf:create()
        ))
end

function M.newBlackInAction(duration)
    local uifunc = require "uifunc"
    local log = require "hmlog"
    --
    duration = checkint(duration)
    local sp = hm.ui.btnExtends(hm.ui.newLayerColor(display.width, display.height, hm.color.c4b(0)))
    hm.ui.addToCenter(sp, cc.Director:getInstance():getRunningScene())
    sp:setCascadeOpacityEnabled(true)
    sp:setOpacity(0)

    local dt = 1
    if duration == -1 then
        -- 一直显示，接近结局的时候需要这样
        return cc.TargetedAction:create(sp, cc.FadeIn:create(dt))
    else
        return cc.TargetedAction:create(sp, cc.Sequence:create(
            cc.FadeIn:create(dt),
            cc.DelayTime:create(duration),
            cc.FadeOut:create(dt),
            cc.RemoveSelf:create()
            ))
    end
end

--[[
    瓢虫特效，随机停止n秒重复播放
    Example:

    local a = hm.actions.newLadybugAction()
    hm.ui.addToCenter(a.node, res)
    a.run()

]]
function M.newLadybugAction()
    local node = hm.ui.createUi("aniBug.lua")
    local ani = hm.ui.createTimeline("aniBug.lua")
    node:runAction(ani)

    local runningscene = cc.Director:getInstance():getRunningScene()

    all = {}
    all.node = node

    all.run = function()
        local d = 1
        local function cb()
            if d == 0 then
                ani:gotoFrameAndPlay(0, 20, false)
                d = math.random(1, 5)
                hmlog.debug('delay = ', d)
            else
                d = d - 1
                hmlog.debug("now d = " .. d)
            end
        end
        -- TBD not very good
        runningscene:runAction(cc.RepeatForever:create(cc.Sequence:create(
                       cc.CallFunc:create(cb),
                       cc.DelayTime:create(d))))

        all.ticker_ = scheduler.scheduleGlobal(cb, 1)
    end

    all.stop = function()
        if all.ticker_ then scheduler.unscheduleGlobal(all.ticker_) end
    end

    return all
end

return M
