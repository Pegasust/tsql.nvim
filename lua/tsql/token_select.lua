local M = {}

---@class FileLoc
---@field 
M.FileLoc = {
}

---@class QNode
M.QNode = {}

---@class TSQuery
---@field find_nodes fun(self: TSQuery, bufs: QBuf[]): TSNode[]
M.TSQuery = {}

---@param treesitter_q string Treesitter DSL for query
---TODO: some examples of `treesitter_q` here
---
---@return TSQuery
function M.from_ts_scm(treesitter_q)
    
end

return M

