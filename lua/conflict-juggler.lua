local CP = require('conflict-juggler.parser')

---@class ConflictJuggler
local M = {}

---@class ConflictJugglerConfig
local CJC = {}

---@param opts? ConflictJugglerConfig
function M.setup(opts)
    opts = opts or {}
    M._config = opts
end

-- Moves common lines from inside conflict blocks out of the blocks.
---@param range_start integer Range starting line
---@param range_end integer Range ending line
function M.simplify_conflicts(range_start, range_end)
    local parser = CP:new()

    local buffer_content =
        vim.api.nvim_buf_get_lines(0, range_start - 1, range_end, false)

    parser:parse(buffer_content)

    for i = #parser.conflicts, 1, -1 do
        local conflict = parser.conflicts[i]

        if conflict.level == parser.top_level then
            conflict:simplify(buffer_content)
        end
    end

    vim.api.nvim_buf_set_lines(
        0,
        range_start - 1,
        range_end,
        false,
        buffer_content
    )
end

return M
