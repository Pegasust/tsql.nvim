---@module 'buf_select'
---@class mod_buf_select
local M = {}

---@alias MatchPredicate fun(nodes: QBuf): boolean

---@class QBuf
---@field bufnr number representing the vim runtime's bufnr, 0 is current buf
---@field path string the absolute path to the buffer. This uses
---`vim.api.nvim_buf_get_name(bufnr: number) -> string`
---Assume [""] if it's erroneous (like a terminal buffer)
---@field filetype string the associated filetypes gotten from. This uses
---`vim.api.nvim_buf_get_option(bufnr: number, 'filetype')`
---@field lang string The language of the treesitter parser. This is gotten
---from `vim.treesitter.get_parser(bufnr: number):lang() -> string [may fail]`
---@field is_loaded boolean whether it is loaded
M.QBuf = {}

---@return string language
---NOTE: may fail with string
local function get_lang(bufnr)
    local status, lang = pcall(function()
        return vim.treesitter.get_parser(bufnr):lang()
    end)

    if not status then
        local path = vim.api.nvim_buf_get_name(bufnr)
        error(string.format("Error determining language for buffer %d: %s", bufnr, path))
    end

    return lang
end

---@param bufnr number
---@param path string
---@param filetype string
---@param lang string
---@param is_loaded boolean
---@return QBuf
function M.QBuf:new(bufnr, path, filetype, lang, is_loaded)
    assert(type(bufnr) == "number", "bufnr must be a number")
    assert(type(path) == "string", "path must be a string")
    assert(type(filetype) == "string", "filetype must be a string")
    assert(type(lang) == "string", "lang must be a string")
    assert(type(is_loaded) == "boolean", "is_loaded must be a boolean")

    local qbuf = {
        bufnr = bufnr,
        path = path,
        filetype = filetype,
        lang = lang,
        is_loaded = is_loaded
    }
    setmetatable(qbuf, self)
    self.__index = self
    return qbuf
end

---@param bufnr number
function M.QBuf.from_nvim_bufnr(bufnr)
    local path = vim.api.nvim_buf_get_name(bufnr)
    local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')

    local status, lang = pcall(get_lang, bufnr)
    local is_loaded = status

    return M.QBuf:new(bufnr, path, filetype, lang, is_loaded)
end

M.buf_match = {}
---@class BufMatch
---@field not_ fun(self): BufMatch
---@field or_ fun(self, q: BufMatch): BufMatch
---@field then_ fun(self, q: BufMatch): BufMatch
---@field filter_on fun(self, q: QBuf[]): QBuf[]
M.BufMatch = {}

function M.buf_match.is_loaded()
    return M.BufMatch.new(function(buf)
        return buf.is_loaded
    end)
end

---@param match_fn fun(buf: QBuf): boolean
---@return BufMatch
---NOTE: assigns `match_fn` private field
function M.BufMatch.new(match_fn)
    local self = setmetatable({}, M.BufMatch)
    self.match_fn = match_fn
    return self
end

---@vararg string OR for filetypes. It doesn't make a lot of sense for AND filetypes
---@return BufMatch
function M.buf_match.filetype(...)
    local filetypes = { ... }
    return M.BufMatch.new(function(buf)
        for _, filetype in ipairs(filetypes) do
            if buf.filetype == filetype then
                return true
            end
        end
        return false
    end)
end

function M.buf_match.any()
    return M.BufMatch.new(function(_) return true end)
end

---@vararg string OR for path
---@return BufMatch
function M.buf_match.path(...)
    local paths = { ... }
    return M.BufMatch.new(function(buf)
        for _, path in ipairs(paths) do
            if string.find(buf.path, path) ~= nil then
                return true
            end
        end
        return false
    end)
end

---@vararg string OR for path
---@return BufMatch _ f
function M.buf_match.path_or(...)
    return M.buf_match.path(...)
end

---@vararg string AND for path
---@return BufMatch
function M.buf_match.path_and(...)
    local paths = { ... }
    return M.BufMatch.new(function(buf)
        for _, path in ipairs(paths) do
            if string.find(buf.path, path) == nil then
                return false
            end
        end
        return true
    end)
end

---@vararg string
---@return BufMatch
function M.buf_match.ext(...)
    local exts = { ... }
    return M.BufMatch.new(function(buf)
        for _, ext in ipairs(exts) do
            if buf.path:sub(- #ext) == ext then
                return true
            end
        end
        return false
    end)
end

---@param q BufMatch
---@return BufMatch
function M.BufMatch:or_(q)
    return M.BufMatch.new(function(buf)
        return self.matched_fn --[[@as MatchPredicate]](buf)
            or q.matched_fn --[[@as MatchPredicate]](buf)
    end)
end

---@param q BufMatch
---@return BufMatch
function M.BufMatch:then_(q)
    return M.BufMatch.new(function(buf)
        return self.matched_fn --[[@as MatchPredicate]](buf)
            and q.matched_fn --[[@as MatchPredicate]](buf)
    end)
end

---@return BufMatch
function M.BufMatch:not_()
    return M.BufMatch.new(function(buf)
        return not self.matched_fn --[[@as MatchPredicate]](buf)
    end)
end

---@param itr QBuf[]
---@return QBuf[]
function M.BufMatch:filter_on(itr)
    ---@type QBuf[]
    local matched = {}
    for _, buf in ipairs(itr) do
        if (self.match_fn --[[@as MatchPredicate]])(buf) then
            table.insert(matched, buf)
        end
    end
    return matched
end

---@return number[] bufnrs that can be loaded or not loaded
local function list_bufs()
    return vim.api.nvim_list_bufs()
end

---@return QBuf[]
function M.nvim_get_qbufs()
    local bufnrs = list_bufs()
    local qbufs = {}

    for _, bufnr in ipairs(bufnrs) do
        local path = vim.api.nvim_buf_get_name(bufnr)
        local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')

        local status, lang = pcall(get_lang, bufnr)
        local is_loaded = status

        local qbuf = {
            bufnr = bufnr,
            path = path,
            filetype = filetype,
            lang = lang,
            is_loaded = is_loaded
        }

        table.insert(qbufs, qbuf)
    end

    return qbufs
end

return M
