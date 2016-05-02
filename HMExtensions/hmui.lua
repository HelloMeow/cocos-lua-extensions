local M = {}
local HMButton = require "HMButton"
local log      = require "hmlog"
local HMButler = require "HMButler"
--[[

local verticalAlignment = {
    cc.VERTICAL_TEXT_ALIGNMENT_TOP,
    cc.VERTICAL_TEXT_ALIGNMENT_CENTER,
    cc.VERTICAL_TEXT_ALIGNMENT_BOTTOM,
}

local horizontalAlignment = {
  cc.TEXT_ALIGNMENT_LEFT,
  cc.TEXT_ALIGNMENT_RIGHT,
  cc.TEXT_ALIGNMENT_CENTER,
}

]]

function M.newTTFLabel(params)
    assert(type(params) == "table", "newTTFLabel() invalid params")

    local text         = tostring(params.text)
    local font         = params.font or znn.DEFAULT_TTF_FONT
    local size         = params.size or znn.DEFAULT_TTF_FONT_SIZE
    local color        = params.color or znn.COLOR_BLACK
    local textAlign    = params.align or cc.TEXT_ALIGNMENT_LEFT
    local textValign   = params.valign or cc.VERTICAL_TEXT_ALIGNMENT_CENTER
    local x, y         = params.x, params.y
    local dimensions   = params.dimensions
    local maxwidth     = params.maxwidth
    local outlineWidth = params.outlineWidth or 0
    local outlineColor = params.outlineColor or znn.COLOR_BLACK

    assert(type(size) == "number",
           "[framework.ui] newTTFLabel() invalid params.size")

    local label
    if dimensions then
        label = cc.Label:createWithTTF(text, font, size, dimensions, textAlign, textValign)
    else
        label = cc.Label:createWithTTF(text, font, size)
    end

    label:setTextColor(color)
    label:setAlignment(textAlign, textValign)

    if maxwidth then label:setMaxLineWidth(maxwidth) end

    if outlineWidth > 0 then
      label:enableOutline(outlineColor, outlineWidth)
    end

    return label
end

function M.newVerticalLabel(params)
    local text   = table.get(params, 'text', '')
    local font   = table.get(params, 'font', znn.FONT_BLI)
    local size   = table.get(params, 'size', 30)
    local color  = table.get(params, 'color', znn.COLOR_BLACK)
    local align  = params.align or cc.TEXT_ALIGNMENT_CENTER
    local valign = params.valign or cc.VERTICAL_TEXT_ALIGNMENT_CENTER

    local chars = hm.locale.getCharList(text)
    assert(#chars>=1)
    -- get the size of a single charactor
    local lbl = M.newTTFLabel({text=chars[1], font=font, size=size, align=align, valign=valign})
    local charsize = lbl:getContentSize()

    -- local lbldesc = M.newTTFLabel({
    --   text       = text,
    --   size       = size,
    --   font       = font,
    --   color      = color,
    --   maxwidth   = charsize.width,
    --   textAlign  = align,
    --   textValign = valign
    --   })
    -- RichLabel cannot proceed string.sub with Chinese num correctly.
    local RichLabel = require "richlabel.RichLabel"
    local lbldesc = RichLabel.new({
        fontName = font,
        fontSize = size,
        maxWidth = charsize.width,
        fontColor = color,
    })
    lbldesc:setString(text)

    return lbldesc
end

function M.newEditBox(params)
    local imageNormal = params.image
    local imagePressed = params.imagePressed
    local imageDisabled = params.imageDisabled
    local size = params.size

    if type(imageNormal) == "string" then
        imageNormal = M.newScale9Sprite(imageNormal, size)
    end
    if type(imagePressed) == "string" then
        imagePressed = M.newScale9Sprite(imagePressed, size)
    end
    if type(imageDisabled) == "string" then
        imageDisabled = M.newScale9Sprite(imageDisabled, size)
    end

    local editbox = CCEditBox:create(params.size, imageNormal, imagePressed, imageDisabled)

    return editbox
end

function M.newLayerColor(size, c4b)
  c4b = c4b or hm.color.randc4b()
  size = size or cc.size(100, 100)
  local l = cc.LayerColor:create(c4b, size.width, size.height)
  l:ignoreAnchorPointForPosition(false)
  return l
end

function M.newLayer(size)
  size = size or cc.size(100, 100)
  local l = cc.Layer:create()
  l:ignoreAnchorPointForPosition(false)
  l:setContentSize(size)
  return l
end

-------------------------
-- new sprite
-------------------------

local function __newSprite(value)
  if tolua.type(value) == "cc.Texture2D" then
    return cc.Sprite:createWithTexture(value)

  elseif tolua.type(value) == "cc.Sprite" then
    return cc.Sprite:createWithTexture(value:getTexture())
    
  else
    if cc.FileUtils:getInstance():isFileExist(HMButler.getImgFullPath(value)) then
      return cc.Sprite:create(HMButler.getImgFullPath(value))
    else
      return hm.ui.newSpriteFrame(value)
    end
  end
end

function M.newSprite(value)
  assert(value)
  if HM_USE_RES_PAC then
    return M.newSpriteFromPackage(HMButler.getImgFullPath(value))
  else
    return __newSprite(value)
  end
end

function M.newImageView(value)
  if cc.FileUtils:getInstance():isFileExist(HMButler.getImgFullPath(value)) then
      return ccui.ImageView:create(HMButler.getImgFullPath(value))
  end
end

function M.newScale9Sprite(imgPath, size)
  local sp = M.newSprite(imgPath)
  local s9sp = ccui.Scale9Sprite:create()
  s9sp:updateWithSprite(sp, cc.rect(0, 0, sp:getContentSize().width, sp:getContentSize().height),
    false, cc.rect(sp:getContentSize().width/2, sp:getContentSize().height/2, 1, 1))
  s9sp:setContentSize(boundsize(size, sp:getContentSize()))
  return s9sp
end

function M.newSpriteFrame(imgpath)
  return cc.Sprite:createWithSpriteFrameName(imgpath)
end

function M.newSpriteFromPackage(imgname)
  local content, size = HMButler:getInstance():getFileInPackage(imgname)
  if content then
    local img = hm.XImage:createWithData(content, size)
    local tex = cc.Texture2D:new()
    tex:initWithImage(img)
    return __newSprite(tex)
  else
    log.warn(string.format("File [%s] not exist!", imgpath))
    return nil
  end
end

----------------------
-- new button
----------------------
function M.newButton(paras)
  --[[
    normal  = "",
    pressed = "",
    diabled = "",
    cb      = yyy,
    gray    = true/false,
    userdata= zzz,
    presseffect = true,
    plist = true/false -- default is false
  ]]
  paras = paras or {}
  assert(paras.normal)

  local texLocation = paras.plist and 1 or 0

  local presseffect = paras.presseffect and true or false

  local imgN, imgP, imgD
  if texLocation == 0 then
    imgN = HMButler.getImgFullPath(paras.normal)
    -- assert(cc.FileUtils:getInstance():isFileExist(imgN),
    --   string.format('image normal [%s] does not exist!', imgN))
    imgP = paras.pressed and HMButler.getImgFullPath(paras.pressed) or imgN
    imgD = paras.disabled and HMButler.getImgFullPath(paras.disabled) or imgN
  else
    imgN = paras.normal
    imgP = paras.pressed or imgN
    imgD = paras.disabled or imgN
  end

  local cb = paras.cb or function()end
  local gray = paras.gray or false
  local udata = paras.userdata

  local btn = HMButton:create()
  btn:setPressedActionEnabled(presseffect)
  btn:setPropagateTouchEvents(true)
  -- btn:loadTextures(imgN, imgP, imgD, texLocation)
  btn:loadTextureNormal(imgN, texLocation)
  btn:loadTexturePressed(imgP, texLocation)
  btn:loadTextureDisabled(imgD, texLocation)
  btn:addTouchEventListener(function(s, e)
    if e == ccui.TouchEventType.ended then cb(s, e, udata) end
  end)
  return btn
end

function M.newFSButton(purecb, userdata) --Full Screen
  return M.newButtonForSize(display.size, purecb, userdata)
end

function M.newButtonForSize(size, pureCallback, userdata)
  local btn = HMButton:create()
  btn:setContentSize(size)
  btn:ignoreContentAdaptWithSize(false)
  btn:setPressedActionEnabled(true)
  btn:setPropagateTouchEvents(false)
  if pureCallback then
    local wrappedCallback = function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
          pureCallback(sender, eventType, userdata)
        end
    end
    btn:addTouchEventListener(wrappedCallback)
  end
  return btn
end

---
--@function btnExtends
--@description add a button to given obj with the same content size
--@params obj CCNode
--@return btn
function M.btnExtends(obj)
  return require("HMButton").extend(obj)
end

---
--@function dialogExtends
--@description add a HMDialog instance to given obj, so it will be under the management of DialogQueue
--@params layer CCLayer
--@return layer
function M.dialogExtends(layer)
  if layer then
    M.addToCenter(require "HMDialog".new(), layer)
  end
  return layer
end

function M.replaceNode( old, new )
    assert(old, 'old is nil')
    assert(new, 'new is nil')
    new:setName(old:getName())
    new:addTo(old:getParent())
    new:setOrderOfArrival(old:getOrderOfArrival())
    new:setAnchorPoint(old:getAnchorPoint())
    new:setPosition(old:getPosition())
    if new.setFlippedX and old.setFlippedX then
      new:setFlippedX(old:isFlippedX())
    end
    if new.setFlippedY and old.setFlippedY then
      new:setFlippedY(old:isFlippedY())
    end
    if new.setRotation then
      new:setRotation(old:getRotation())
    end
    new:setScaleX(old:getScaleX())
    new:setScaleY(old:getScaleY())
    old:removeSelf()
    return new
end

function M.bindbuttonhandler(btn, handler, userdata)
  btn:addTouchEventListener(function(sender, event)
    if event == ccui.TouchEventType.ended then
      handler(sender, event, userdata)
    end
  end)
  return btn
end

------
function M.positionAt(node, ap, extraPos)
    if node == nil then return cc.p(0, 0) end
    extraPos = extraPos or cc.p(0, 0)
    return cc.p(
      node:getContentSize().width * ap.x  + extraPos.x,
      node:getContentSize().height * ap.y + extraPos.y)
end

function M.worldPositionAt(node, ap)
  return node:convertToWorldSpace(M.positionAt(node, ap))
end

-- function M.worldPositionAt(node, ap)
--   if node == nil then return cc.p(0, 0) end
--   return cc.p(
--     node:getPositionX() + (ap.x - node:getAnchorPoint().x) * node:getContentSize().width,
--     node:getPositionY() + (ap.y - node:getAnchorPoint().y) * node:getContentSize().height)
-- end

function M.addToCenter(node, target)
  return M.addToAp(node, target, znn.AP_CC)
end

function M.addTo(node, target, ap, pos)
  assert(node, "child node is nil")
  assert(target, "parent node is nil")
  ap = ap or cc.p(0, 0)
  pos = pos or cc.p(0, 0)
  node:removeSelf()
  node:addTo(target)
  node:setAnchorPoint(ap)
  node:setPosition(pos)
  return node
end

function M.addToAp(node, target, ap, extraPos)
  return M.addToRelAp(node, target, ap, ap, extraPos)
end

function M.addToRelAp(node, target, nodeAp, relAp, extraPos)
  extraPos = extraPos or cc.p(0, 0)
  return M.addTo(node, target, nodeAp, cc.pAdd( M.positionAt(target, relAp), extraPos))
end

function M.positionAtRelNode( node, ap, extraPos )
  assert(node)
  extraPos = extraPos or cc.p(0, 0)
  local p = cc.p(
    node:getPositionX() + node:getContentSize().width * (ap.x - node:getAnchorPoint().x),
    node:getPositionY() + node:getContentSize().height * (ap.y - node:getAnchorPoint().y))
  return cc.pAdd(extraPos, p)
end

function M.addToRelNode(node, target, nodeAp, relNode, relAp, extraPos)
  assert(node and target and relNode)
  extraPos = extraPos or cc.p(0, 0)
  return M.addTo(node, target, nodeAp, cc.pAdd(extraPos, M.positionAtRelNode(relNode, relAp)))
end

function M.boundsize(sz1, sz2)
  assert(sz1 and sz2)
  return cc.size(math.max(sz1.width, sz2.width), math.max(sz1.height, sz2.height))
end

function M.fullScreenNoBorder(sp)
  local size = sp:getContentSize()
  sp:setScale(math.max(display.width/size.width, display.height/size.height))
  return sp
end

function M.fitScreenWidth(sp)
  local size = sp:getContentSize()
  sp:setScale(display.vwidth/size.width)
  return sp
end

-- plist is a must and has no ext
-- texture is not neccessary
--[[
  Allowed:
  addSpriteFrames("abc")
  addSpriteFrames("abc", "bcd")
  Not Allowed:
  addSpriteFrames("abc.plist")
  addSpriteFrames("abc.plist", "bcd.png")
]]
function M.addSpriteFrames(plist, texture)
  assert(plist)
  local CACHE = cc.SpriteFrameCache:getInstance()

  texture = string.format("%s.png", texture and texture or plist)
  plist = string.format("%s.plist", plist)

  if HM_USE_RES_PAC then
    local plist_content = HMButler:getInstance():getFileInPackage(plist)
    local tex_cont, tex_size = HMButler:getInstance():getFileInPackage(texture)
    local img = hm.XImage:createWithData(tex_cont, tex_size)
    local tex = cc.Texture2D:new()
    tex:initWithImage(img)
    CACHE:addSpriteFramesWithFileContent(plist_content, tex)
  else
    CACHE:addSpriteFrames(plist)
  end
end

return M
