---@type mod_buf_select
local buf_select = require('tsql.buf_select')

---@module 'tsql'
local M = {}

M.ts_query = {}
---@class TSQuery
M.TSQuery = {}
M.sink_by = {}
---@module 'tsql.format'
---@alias Format fun(self, nodes: QNode[])
M.format = {}
---@class Tsql
M.Tsql = {}

---NOTE: re-export with implementation
M.buf_match = require('tsql.buf_select')

function M.ts_query.from_scm(treesitter_query)
    -- TODO: implement
    return M.TSQuery
end

function M.TSQuery:find_locs(files)
    -- TODO: implement
    return {}
end

function M.sink_by.highlight()
    -- TODO: implement
end

---@type Format
function M.format.display()
    -- TODO: implement
end

---@type Format
function M.format.dump()
    -- TODO: implement
end

---@param format Format
function M.sink_by.print(format)
    -- TODO: implement
end

---@param format Format
function M.sink_by.nvim_yank_buf(format)
    -- TODO: implement
end

---@return Tsql
---@param external_dsl string
function M.s(external_dsl)
    -- TODO: implement
end

---@return Tsql
---@param buf_match BufMatch
---@param codeql TSQuery
---@param sink Sink
function M.t(buf_match, codeql, sink)
    -- TODO: implement
end

---NOTE: This is now exiting the functional core and entering
--- imperative shell
function M.Tsql:do_nvim()
    -- TODO: implement
end

return M
