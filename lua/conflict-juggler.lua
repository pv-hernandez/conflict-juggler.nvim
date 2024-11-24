local P = require('conflict-juggler.parser')

-- ConflictJuggler plugin module
---@class ConflictJuggler
local M = {}

-- Configuration options for ConflictJuggler plugin.
---@class ConflictJugglerConfig
---@field markers ConflictMarkers Patterns of the conflict block.

-- Partial configuration options for ConflictJuggler plugin.
---@class ConflictJugglerOpts
---@field markers? ConflictMarkers Patterns of the conflict block.

-- ConflictJuggler default config
---@type ConflictJugglerConfig
local default_config = {
    markers = {
        ours = '^<<<<<<<%s*(,-)$',
        base = '^|||||||%s*(.-)$',
        sep = '^=======%s*(.-)$',
        theirs = '^>>>>>>>%s*(.-)$',
    },
}

-- Initializes the plugin.
---@param opts? ConflictJugglerOpts
function M.setup(opts)
    ---@type ConflictJugglerConfig
    local config = vim.tbl_deep_extend('keep', opts or {}, default_config)
    M._config = config
end

-- Moves common lines from inside conflict blocks out of the blocks.
---@param range_start integer Range starting line
---@param range_end integer Range ending line
function M.simplify_conflicts(range_start, range_end)
    local parser = P:new({ markers = M._config.markers })

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
