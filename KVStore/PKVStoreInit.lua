local M = {}
local _cp = require 'coatp.Persistent'
local log = require "hmlog"

function M.init(dbpath)
    log.debug("Create Table PKVStore")
    local cls = _cp.persistent('PKVStore')
    cls.has_p.key          = {is = 'rw', isa = 'string'}
    cls.has_p.value        = {is = 'rw', isa = 'string'}
    cls.has_p.vtype        = {is = 'rw', isa = 'string'}

    local sql_create = [[
      CREATE TABLE PKVStore (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        key         TEXT    UNIQUE,
        value       TEXT    default(''),
        vtype       TEXT
      )
    ]]

    PKVStore.establish_connection('sqlite3', dbpath):execute(sql_create)
end

return M