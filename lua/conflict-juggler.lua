local P = require('conflict-juggler.parser')

-- ConflictJuggler plugin module
---@class ConflictJuggler
local M = {}

-- Configuration options for ConflictJuggler plugin.
---@class ConflictJugglerConfig
---@field highlight ConflictJugglerConfigHighlight Highlighting config.
---@field markers ConflictMarkers Patterns of the conflict block.

-- Partial configuration options for ConflictJuggler plugin.
---@class ConflictJugglerOpts
---@field highlight? ConflictJugglerConfigHighlight Highlighting config.
---@field markers? ConflictMarkers Patterns of the conflict block.

-- ConflictJuggler default config
---@type ConflictJugglerConfig
local default_config = {
    highlight = {
        enabled = true,
        namespace = 'ConflictJuggler',
        ours_header = {
            group_name = "ConflictOursHeader",
            background = {
                gui = "Green",
                term = "Green",
            },
            foreground = {
                gui = 'fg',
                term = 'fg',
            }
        },
        ours = {
            group_name = "ConflictOursBody",
            background = {
                gui = "DarkGreen",
                term = "DarkGreen",
            },
            foreground = {
                gui = 'fg',
                term = 'fg',
            }
        },
        base_header = {
            group_name = "ConflictBaseHeader",
            background = {
                gui = "Gray",
                term = "Gray",
            },
            foreground = {
                gui = 'fg',
                term = 'fg',
            }
        },
        base = {
            group_name = "ConflictBaseBody",
            background = {
                gui = "DarkGray",
                term = "DarkGray",
            },
            foreground = {
                gui = 'fg',
                term = 'fg',
            }
        },
        theirs_header = {
            group_name = "ConflictTheirsHeader",
            background = {
                gui = "Blue",
                term = "Blue",
            },
            foreground = {
                gui = 'fg',
                term = 'fg',
            }
        },
        theirs = {
            group_name = "ConflictTheirsBody",
            background = {
                gui = "DarkBlue",
                term = "DarkBlue",
            },
            foreground = {
                gui = 'fg',
                term = 'fg',
            }
        },
        theirs_footer = {
            group_name = "ConflictTheirsFooter",
            background = {
                gui = "Blue",
                term = "Blue",
            },
            foreground = {
                gui = 'fg',
                term = 'fg',
            }
        },
    },
    markers = {
        ours = '^<<<<<<<%s*(.-)$',
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

    if not M._config.highlight.enabled then
        return
    end

    local h = M._config.highlight

    ---@param hl Highlight
    ---@return string[]
    local hl_to_args = function(hl)
        local args = {}
        table.insert(args, hl.group_name)

        local bg = hl.background or {}
        local fg = hl.foreground or {}
        local sp = hl.special or {}

        local guibg = bg.gui
        if guibg then
            table.insert(args, 'guibg=' .. guibg)
        end

        local guifg = fg.gui
        if guifg then
            table.insert(args, 'guifg=' .. guifg)
        end

        local guisp = sp.gui
        if guisp then
            table.insert(args, 'guisp=' .. guisp)
        end

        local ctermbg = bg.term
        if ctermbg then
            table.insert(args, 'ctermbg=' .. ctermbg)
        end

        local ctermfg = fg.term
        if ctermfg then
            table.insert(args, 'ctermfg=' .. ctermfg)
        end

        local mode_str = ''
        for _, value in ipairs(hl.mode or {}) do
            mode_str = mode_str .. ',' .. value
        end
        mode_str = string.sub(mode_str, 2)
        if mode_str ~= '' then
            table.insert(args, 'cterm=' .. mode_str)
            table.insert(args, 'gui=' .. mode_str)
        end


        if guisp then
            table.insert(args, 'guisp=' .. guisp)
        end

        return args
    end

    vim.cmd({ cmd = 'highlight', args = { 'default', unpack(hl_to_args(h.ours_header)) } })
    vim.cmd({ cmd = 'highlight', args = { 'default', unpack(hl_to_args(h.ours)) } })
    vim.cmd({ cmd = 'highlight', args = { 'default', unpack(hl_to_args(h.base_header)) } })
    vim.cmd({ cmd = 'highlight', args = { 'default', unpack(hl_to_args(h.base)) } })
    vim.cmd({ cmd = 'highlight', args = { 'default', unpack(hl_to_args(h.theirs_header)) } })
    vim.cmd({ cmd = 'highlight', args = { 'default', unpack(hl_to_args(h.theirs)) } })
    vim.cmd({ cmd = 'highlight', args = { 'default', unpack(hl_to_args(h.theirs_footer)) } })
end

function M.deactivate()
    if not M._config.highlight.enabled then
        return
    end

    -- vim.api.nvim_create_namespace(M._config.highlight.namespace)

    local h = M._config.highlight

    vim.cmd({ cmd = 'highlight', args = { 'clear', h.ours_header.group_name } })
    vim.cmd({ cmd = 'highlight', args = { 'clear', h.ours.group_name } })
    vim.cmd({ cmd = 'highlight', args = { 'clear', h.base_header.group_name } })
    vim.cmd({ cmd = 'highlight', args = { 'clear', h.base.group_name } })
    vim.cmd({ cmd = 'highlight', args = { 'clear', h.theirs_header.group_name } })
    vim.cmd({ cmd = 'highlight', args = { 'clear', h.theirs.group_name } })
    vim.cmd({ cmd = 'highlight', args = { 'clear', h.theirs_footer.group_name } })
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

-- Highlight all conflict lines in the current buffer.
function M.highlight()
    if not M._config.highlight.enabled then
        return
    end

    local parser = P:new({ markers = M._config.markers })

    local buffer_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    parser:parse(buffer_content)

    local ns_id = vim.api.nvim_create_namespace(M._config.highlight.namespace)
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)

    for i = #parser.conflicts, 1, -1 do
        local conflict = parser.conflicts[i]

        if conflict.level == parser.top_level then
            conflict:highlight(0, M._config.highlight)
        end
    end
end

return M
