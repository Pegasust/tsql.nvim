---@type mod_buf_select
local buf_select = require('tsql.buf_select')
---@type mod_token_select
local token_select = require('tsql.token_select')

---@module 'tsql'
local M = {}

---@class mod_sink_by
M.sink_by = {}

---@class mod_format
---@alias Format fun(nodes: QNode[]): string
M.format = {}

M.nvim_ns = vim.api.nvim_create_namespace("tsql")
M.nvim_hl_group = "Search"

---@class Sink
---@field sink fun(self, nodes: QNode[])
M.Sink = {}
M.Sink.__index = M.Sink

---@return Sink
function M.sink_by.highlight()
    return setmetatable({
        ---@type fun(nodes: QNode[])
        sink = function(nodes)
            for _, node in ipairs(nodes) do
                vim.highlight.range(
                    node.buf.bufnr,
                    M.nvim_ns,
                    M.nvim_hl_group,
                    { node.start.row_0, node.start.col_0 },
                    { node.end_ex_col.row_0, node.end_ex_col.col_0 },
                    {}
                )
            end
        end
    }, M.Sink)
end

---@type Format
---Something that can be represented in string in a concise/DSL format.
---In the context of QNode, it should just be the text content. If it's multiline,
---just join by newline
---
---`vim.api.nvim_buf_get_text(
---  bufnr: number,
---  start_row: number,
---  start_col: number,
---  end_row: number,
---  end_col_exclusive: number,
---  opt: {}
---) -> string[]` return value is array of lines, empty array for unloaded buffer
function M.format.display(nodes)
    local texts = {}
    for _, node in ipairs(nodes) do
        local text = vim.api.nvim_buf_get_text(node.buf.bufnr, node.start.row_0, node.start.col_0, node.end_ex_col.row_0,
            node.end_ex_col.col_0)
        table.insert(texts, table.concat(text, '\n'))
    end
    return table.concat(texts, '\n\n')
end

---@type Format
---Something like a JSON if natively possible, or RON for Rust for clarity
---Basically return a string that is pretty-printed that represents
---a Lua table onto string
function M.format.dump(nodes)
    return vim.inspect(nodes, { newline = '\n', indent = '  ' })
end

---@param format Format
---@return Sink
function M.sink_by.print(format)
    return setmetatable({
        ---@type fun(nodes: QNode[])
        sink = function(nodes)
            print(format(nodes))
        end
    }, M.Sink)
end

---@param format Format
---@return Sink
function M.sink_by.nvim_yank_buf(format)
    return setmetatable({
        ---@type fun(nodes: QNode[])
        sink = function(nodes)
            local text = format(nodes)
            vim.fn.setreg('"', text)
        end
    }, M.Sink)
end

---NOTE: re-export with implementation
M.buf_match = buf_select.buf_match
M.BufMatch = buf_select.BufMatch
M.QBuf = buf_select.QBuf
M.nvim_get_qbufs = buf_select.nvim_get_qbufs

M.ts_query = token_select.ts_query
M.TSQuery = token_select.TSQuery

---@class Tsql
---@field buf_match BufMatch
---@field codeql TSQuery
---@field sink Sink
M.Tsql = {}
M.Tsql.__index = M.Tsql

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
    return setmetatable({
        buf_match = buf_match,
        codeql = codeql,
        sink = sink
    }, M.Tsql)
end

---NOTE: This is now exiting the functional core and entering
--- imperative shell
function M.Tsql:do_nvim()
    self.sink:sink(
        self.codeql:find_nodes(
            self.buf_match:filter_on(M.nvim_get_qbufs())
        )
    )
end

return M
