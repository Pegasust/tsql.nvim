---@module 'tsql.token_select'
---@class mod_token_select
local M = {}

---@class mod_ts_query
M.ts_query = {}
---@class TSQuery
---@field query string the passthru for treesitter language parser
M.TSQuery = {}

---@class FileLoc
---@field row_0 number 0-index row location
---@field col_0 number 0-index col location
M.FileLoc = {}
M.FileLoc.__index = M.FileLoc

---@class QNode
---@field start FileLoc
---@field end_ex_col FileLoc
---@field buf QBuf
M.QNode = {}
M.QNode.__index = M.QNode

---@param treesitter_query string the passthru for treesitter language
---parser
---@return TSQuery
function M.ts_query.from_scm(treesitter_query)
    return {
        query = treesitter_query
    }
end

---@param files QBuf[]
---@return QNode[]
function M.TSQuery:find_nodes(files)
    local result = {}
    for _, file in ipairs(files) do
        local parser = vim.treesitter.get_parser(file.bufnr, file.filetype)
        local tree = parser:parse()[1]
        local root = tree:root()
        ---@type Query
        local query = vim.treesitter.parse_query(file.lang, self.query)
        for _, match, _ in query:iter_matches(root, file.bufnr, 0, -1) do
            for id, node in pairs(match) do
                local start_row, start_col, end_row, end_col = node:range(false)
                local start = { row_0 = start_row, col_0 = start_col }
                -- NOTE: Will need to validate that this is correct to be exclusive
                -- :lua local parser = vim.treesitter.get_parser(0, 'lua'); local tree = parser:parse()[1]; local query = vim.treesitter.parse_query('lua', '(identifier) @name'); for id, node in query:iter_captures(tree:root(), 0) do local name = query.captures[id]; if name == 'name' and vim.treesitter.get_node_text(node, 0) == 'TSQuery' then local sr, sc, er, ec = node:range(); print(string.format("TSQuery Start: (%d, %d), End: (%d, %d)", sr, sc, er, ec)); end; end
                local end_ex_col = { row_0 = end_row, col_0 = end_col }
                local qnode = { buf = file, start = start, end_ex_col = end_ex_col }
                setmetatable(qnode, M.QNode)
                table.insert(result, qnode)
            end
        end
    end
    return result
end

return M
