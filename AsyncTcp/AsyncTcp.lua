local M = {}
local scheduler = require("scheduler")
local headers = require("socket.headers")
local ltn12  = require("ltn12")
local url    = require("socket.url")
local dispatcher = cc.Director:getInstance():getEventDispatcher()
local base = _G

local default_ssl_params =
{
  protocol = "tlsv1_2",
  options  = "all",
  verify   = "none",
  mode     = "client",
}

--[[
    NOTE:
    * for now only one request at the same time is allowed

    INPUT:
    * ssl_params
    * params


    local AsyncTcp = require "AsyncTcp"
    local atcp = AsyncTcp:ctor()
    atcp:conn(params, onresp, ssl_params)
]]
local _DBG = 4
local logD = function(...)
    if _DBG >= 5 then
        hmlog.debug('AsyncTcp', ...)
    end
end
local logI = function(...)
    if _DBG >= 4 then
        hmlog.debug('AsyncTcp', ...)
    end
end

function M:getInstance()
    if not _atcp then
        _atcp = M:ctor()
    end
    return _atcp
end

-- constants
local SOCKET_TICK_TIME = 0.001
local schedule_send_select    = 'schedule_send_select'
local schedule_check_conn     = 'schedule_check_conn'
local schedule_handshake      = 'schedule_handshake'
local schedule_timeout        = 'schedule_timeout'
local schedule_receive_select = 'schedule_receive_select'

-- local STATUS_ALREADY_CONNECTED = "already connected"
local timeout_seconds = 2

-- Error code
local err_code_timeout    = 'EHTTP_TIMEOUT'
local err_code_connection = 'EHTTP_CONNECTION'

-- Callback type
local callback_on_connected = 'callback_on_connected'
local callback_on_received = 'callback_on_received'

local USERAGENT = socket._VERSION

-- send
local function sendrequestline(sock, method, uri)
    local reqline = string.format("%s %s HTTP/1.1\r\n", method or "GET", uri)
    logD("sendrequestline", reqline)
    return socket.try(sock:send(reqline))
end

local function sendheaders(sock, tosend)
    local canonic = headers.canonic
    local h = "\r\n"
    for f, v in base.pairs(tosend) do
        h = (canonic[f] or f) .. ": " .. v .. "\r\n" .. h
    end
    logD("sendheaders", h)
    socket.try(sock:send(h))
    return 1
end

local function sendbody(sock, headers, source, step)
    logD("sendbody")
    source = source or ltn12.source.empty()
    step = step or ltn12.pump.step
    -- if we don't know the size in advance, send chunked and hope for the best
    local mode = "http-chunked"
    if headers["content-length"] then mode = "keep-open" end
    return (ltn12.pump.all(source, socket.sink(mode, sock), step))
end

-- PRIVATE API
function M:__begin_scheduler(stype, interval)
    logD("__begin_scheduler:" .. stype)
    local func = nil
    interval = interval or SOCKET_TICK_TIME
    if stype == schedule_send_select then
        func = handler(self, self.__tk_send_select)
    elseif stype == schedule_check_conn then
        func = handler(self, self.__tk_check_conn)
    elseif stype == schedule_handshake then
        func = handler(self, self.__tk_handshake)
    elseif stype == schedule_receive_select then
        func = handler(self, self.__tk_receive_select)
    elseif stype == schedule_timeout then
        func = handler(self, self.__tk_timeout)
        self.__timeout_begin_ts = os.time()
    end

    if func then
        self.schedulers_[stype] = scheduler.scheduleGlobal(func, interval)
    end
end

-- PRIVATE API
function M:__stop_scheduler(stype)
    logD("__stop_scheduler", stype)
    if self.schedulers_[stype] then
        scheduler.unscheduleGlobal(self.schedulers_[stype])
        self.schedulers_[stype] = nil
    end
end

function M:__stop_all_schedulers()
    self:__stop_scheduler(schedule_timeout)
    self:__stop_scheduler(schedule_check_conn)
    self:__stop_scheduler(schedule_send_select)
    self:__stop_scheduler(schedule_handshake)
    self:__stop_scheduler(schedule_receive_select)
end

-- PRIVATE API
-- send request data
function M:__send_request_data()
  logD("__send_request_data")
  sendrequestline(self.sock, self.params.method, self.params.uri)
  sendheaders(self.sock, self.params.headers)
  sendbody(self.sock, self.params.headers, self.params.source, self.params.step)
end

function M:__deal_error(err, code)
    -- TBD
    logD("__deal_error", err, code)
    self.code_ = code or err_code_connection
    self:__notify_callback(callback_on_received,
        {code=self.code_, headers=self.headers_, status=self.status_, body=self.body_})
    self.__stop_all_schedulers()
end

function M:__parse_header_line(line)
    -- TBD
    -- logD("__parse_header_line", line)
    local name, value = socket.skip(2, string.find(line, "^(.-):%s*(.*)"))
    if not (name and value) then
        hmlog.error("malformed reponse headers")
        return
    end
    return string.lower(name), value
end

function M:__set_headers(name, value)
    -- TBD
    local headers = self.headers_
    if headers[name] then
        headers[name] = headers[name] .. ", " .. value
    else
        headers[name] = value
    end
    -- logD("self.headers_", self.headers_)
end

function M:__shouldreceivebody(code, method)
    if method == "HEAD" then return nil end
    if code == 204 or code == 304 then return nil end
    if code >= 100 and code < 200 then return nil end
    if code == 500 then return nil end -- WJ 20151016 500会返回一大堆body，无用
    logD("__shouldreceivebody", true)
    return 1
end

function M:__receive_done()
    logD("__receive_done")
    self.sock:close()
    self:__stop_scheduler(schedule_receive_select)
    self:__notify_callback(callback_on_received,
        {code=self.code_, headers=self.headers_, status=self.status_, body=self.body_})
end

-- PRIVATE API
function M:__co_receive(sock)
    logD('__co_receive, receive status line')
    self.headers_ = {}

    -- receive status
    self.status_ = sock:receive('*l')
    self.code_ = base.tonumber(socket.skip(2,
        string.find(self.status_, "HTTP/%d*%.%d* (%d%d%d)")))
    logD('* Status *', self.code_, self.status_)
    coroutine.yield()

    logD('__co_receive, receive header')
    -- receive header
    local headerdone = false
    while not headerdone do
        local line, err = sock:receive('*l')
        if err then self:__deal_error(err) break end
        if line ~= "" then
            local name, value = self:__parse_header_line(line)
            self:__set_headers(name, value)
        else
            headerdone = true
            self.contentlength_ = base.tonumber(self.headers_['content-length']) or 0
            logD("* Headers *", self.headers_)
        end
        coroutine.yield()
    end

    logD('__co_receive, receive body')
    -- receive body
    if self:__shouldreceivebody(self.code_, self.params.method) then
        local t = {}
        local bodylength = 0
        local bodydone = false
        while not bodydone do
            local line, err = sock:receive('*l')
            if err then self:__deal_error(err) break end
            if line then t[#t+1] = line end
            bodylength = bodylength + string.len(line) + 1 -- linebreak
            if bodylength >= self.contentlength_ then
                bodydone = true
                self.body_ = table.concat(t)
                logD('* Body *', self.body_)
                self:__receive_done()
            end
            coroutine.yield()
        end
    else
        self:__receive_done()
        coroutine.yield()
    end
end

function M:__tk_timeout()
    if os.time() - self.__timeout_begin_ts >= timeout_seconds then
        logD("__tk_timeout", "Timeout")
        self:__deal_error("Connection timeout", err_code_timeout)
    end
end

-- PRIVATE API
-- receive response non-blocking-ly
function M:__tk_receive_select()
  local r,w,e = socket.select({self.sock}, nil, 0)
  if #r > 0 then
    for _, sock in ipairs(r) do
        coroutine.resume(self.__co_receive_handler, self, sock)
    end
  end
end

function M:__nb_receive()
    logD("__nb_receive")
    self.__co_receive_handler = coroutine.create(self.__co_receive)
    self:__begin_scheduler(schedule_receive_select)
end

--
function M:__addsocket( list, socket)
  for _,sock in ipairs(list) do
    if sock == socket then return end
  end
  list[#list+1] = socket
end
function M:__removesocket( list, socket)
  for _,sock in ipairs(list) do
    if sock == socket then list[_] = nil return end
  end
end

-- ssl handshake
function M:__dohandshake()
    local sock = self.sock
    local success, err = sock:dohandshake()
    logD("__dohandshake", success, err)

    if success then
      self:__removesocket(self._sendreadlist, sock)
      return 1
    end
    if err == 'wantread' then
      self:__addsocket(self._sendreadlist, sock)
    end
end
function M:__tk_handshake()
    local succ = self:__dohandshake(self.sock, self.host, self.port)
    if succ == 1 then
        self:__stop_scheduler(schedule_handshake)
        self:__stop_scheduler(schedule_send_select)
        self:__stop_scheduler(schedule_timeout)
        self:__send_request_data()
        self:__nb_receive()
    end
end
-- PRIVATE API
-- non-blocking handshaking
function M:__nb_handshake()
  local ssock = ssl.wrap(self.sock, self.ssl_params)
  ssock:settimeout(0)
  self.sock = ssock
  self:__begin_scheduler(schedule_handshake)
  self:__begin_scheduler(schedule_timeout)
end

-- PRIVATE API
-- 建立链接时需要select检查状态
function M:__tk_send_select()
  local r,w,e = socket.select(self._sendreadlist, nil, 0)
  if #r > 0 then
    for _, sock in ipairs(r) do
      logD("read::", sock:receive('*l'))
    end
  end
end

-- PRIVATE API
function M:__tk_check_conn()
    local succ, err = self.sock:connect(self.host, self.port)
    logD('__check_conn', "succ", checknil(succ), "err", checknil(err))
    if succ == 1 or err == 'already connected' then
        self:__stop_scheduler(schedule_timeout)
        self:__stop_scheduler(schedule_check_conn)
        self:__notify_callback(callback_on_connected)
    end
end

function M:__add_callback(cbtype, callback)
    if not callback then return end
    self.callbacks_[cbtype] = callback
end


function M:__notify_callback(cbtype, ...)
    logD("__notify_callback", cbtype)
    local callback = self.callbacks_[cbtype]
    -- self.callbacks_[cbtype] = nil
    if callback then callback(...) end
end

function M:__remove_callback(cbtype, callback)
    self.callbacks_[cbtype] = nil
end

function M:ctor()
    self.schedulers_ = {}
    self:_reset()
    return self
end

function M:_reset()
    self:__stop_all_schedulers()
    self.schedulers_ = {}
    self._sendreadlist = {}
    self.callbacks_ = {}
    if self.sock then self.sock:close() end
    self.sock = nil
end

function M:conn(params, callback, ssl_params)
    self:_reset()

    self.params = params
    self.ishttps_ = self:_checksslparams(ssl_params)
    self:_setcallback(callback)

    local sock = socket.tcp()
    sock:settimeout(0)
    self.sock = sock
    self.host = self.params.host
    self.port = self.params.port

    if self.ishttps_ then
        self:_connecthttps(self.params, self.ssl_params)
    else
        self:_connecthttp(self.params)
    end
end

function M:_connecthttp(params)
    logD("_connecthttp")
    self:__add_callback(callback_on_connected, function()
        self:__send_request_data()
        self:__nb_receive()
    end)

    self:__begin_scheduler(schedule_send_select)
    self:__begin_scheduler(schedule_check_conn)
    self:__begin_scheduler(schedule_timeout)
end

function M:_connecthttps(params, ssl_params)
    logD("_connecthttps")
    self:__add_callback(callback_on_connected, handler(self, self.__nb_handshake))

    self:__begin_scheduler(schedule_send_select)
    self:__begin_scheduler(schedule_check_conn)
    self:__begin_scheduler(schedule_timeout)
end

function M:_setcallback(callback)
    if callback then
        local listener_cb_ =
            uifunc.addListener('onReceiveDone', function(e)
                ret = e._usedata
                if callback then
                    callback(ret.code, ret.headers, ret.status, ret.body)
                end
            end)
        self:__add_callback(callback_on_received, function(...)
                hmlog.debug("onreceived")
                uifunc.dispatchEvent('onReceiveDone', ...)
                dispatcher:removeEventListener(listener_cb_)
            end)
    end
end

function M:_checksslparams(ssl_params)
    if ssl_params and tolua.type(ssl_params) == 'table' then
        for k,v in pairs(default_ssl_params) do
            ssl_params[k] = v or default_ssl_params[k]
        end
        self.ssl_params = ssl_params
        return true
    end
    return false
end
return M