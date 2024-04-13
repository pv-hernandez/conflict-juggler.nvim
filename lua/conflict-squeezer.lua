local CP = require('conflict-squeezer.parser')

---@class ConflictSqueezer
local M = {}

---@class ConflictSqueezerConfig
local CSC = {}

---@param opts? ConflictSqueezerConfig
function M.setup(opts)
    opts = opts or {}
    M._config = opts
end

function M.squeeze_conflicts()
    local parser = CP:new()

    local buffer_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    parser:parse(buffer_content)

    for i = #parser.conflicts, 1, -1 do
        local conflict = parser.conflicts[i]

        if conflict.level == parser.top_level then
            conflict:squeeze(buffer_content)
        end
    end

    vim.api.nvim_buf_set_lines(0, 0, -1, false, buffer_content)
end

return M
