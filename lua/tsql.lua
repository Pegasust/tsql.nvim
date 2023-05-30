---TODO: how does this work with changing texts?
---TODO: add reducer as formatter
---TODO: Add reducer as buf_select predicate

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
                    M.config.nvim_ns,
                    M.config.nvim_hl_group,
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

---NOTE: requires nvim runtime
function M.Tsql:q_nodes()
    return self.codeql:find_nodes(
        self.buf_match:filter_on(M.nvim_get_qbufs())
    )
end

---NOTE: This is now exiting the functional core and entering
--- imperative shell
--- @param store StaticStore
function M.Tsql:do_nvim(store)
    self.sink:sink(self:q_nodes())
    store:add_highlight(self)
end

---@param config RtConfig
---@param store StaticStore
function M._delete_all_highlights(config, store)
    ---@type table<integer, QBuf>
    local bufs = {}
    for _, highlight_q in pairs(store.highlighting) do
        for _, qnode in ipairs(highlight_q:q_nodes()) do
            table.insert(bufs, qnode.buf.bufnr, qnode.buf)
        end
    end

    for _, buf in pairs(bufs) do
        vim.api.nvim_buf_clear_namespace(buf.bufnr, config.nvim_ns, 0, -1)
    end
    store:clear_highlights()
end

---NOTE: Collocated with `M.setup`
---@class Config
---@field nvim_hl_group string
local Config = {}
---@type Config
M.config_default = {
    nvim_hl_group = "Search"
}

---@class RtConfig: Config
---@field nvim_ns number
M.RtConfig = {}
---@type RtConfig
M.config = {}

---@class StaticStore
---@field highlighting Tsql[]
---This is needed to undo the highlighting done by this plugin and potentially
---subscribe to the changing buffers to re-highlight if necessary
M.Store = {}
M.Store.__index = M.Store

---@param tsql Tsql
function M.Store:add_highlight(tsql)
    table.insert(self.highlighting, tsql)
end

function M.Store:clear_highlights()
    self.highlighting = {}
end

---@return StaticStore
function M.Store:new()
    local o = { highlighting = {} }
    setmetatable(o, self)
    return o
end

function M.clear_highlights()
    return M._delete_all_highlights(M.config, M.store)
end

---@param config Config
function M.setup(config)
    M.config = vim.tbl_deep_extend("force", M.config, config or M.config_default)
    M.config.nvim_ns = vim.api.nvim_create_namespace("tsql")

    vim.api.nvim_create_user_command("Noh", M.clear_highlights)

    M.store = M.Store:new()
end

return M
