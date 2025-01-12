local P = require('conflict-juggler.parser')
local HL = require('conflict-juggler.highlight')

---@alias LineRange { start_row: integer, end_row: integer }

---@class BufferState
---@field parser vim.treesitter.LanguageTree The parser instance attached to
---                                          the buffer.
---@field debouncer uv.uv_timer_t Timer to debounce parsing.
---@field tree table<integer, TSTree> The most recent parser result.
---@field queue LineRange[] The queue of
---                                                        modified ranges
---                                                        pending parse.
---@field extmarks integer[] List of extmarks currently created.
---@field valid boolean Flag telling if the buffer is valid.

-- ConflictJuggler plugin module
---@class ConflictJuggler
---@field _state table<integer, BufferState> Internal state per buffer
---@field _highlight_enabled boolean
local M = {
    _state = {},
    _highlight_enabled = false,
}

-- Configuration for using the git merge conflict parser implemented using
-- tree-sitter.
---@class ConflictJugglerTreeSitterConfig
---@field install_info table Nvim-Treesitter configuration for installing the
---                          git conflict tree-sitter parser.
---@field filetype string | string[] Filetypes for the git conflict parser.
---@field lang string Language name for the git conflict parser.

-- Configuration for using the git merge conflict parser implemented using
-- tree-sitter.
---@class ConflictJugglerTreeSitterOpts : ConflictJugglerTreeSitterConfig
---@field install_info? table Nvim-Treesitter configuration for installing the
---                          git conflict tree-sitter parser.
---@field filetype? string | string[] Filetypes for the git conflict parser.
---@field lang? string Language name for the git conflict parser.

-- Configuration options for ConflictJuggler plugin.
---@class ConflictJugglerConfig
---@field highlight ConflictJugglerConfigHighlight Highlighting config.
---@field treesitter ConflictJugglerTreeSitterConfig Config for tree-sitter
---                                                  parsing.

-- Partial configuration options for ConflictJuggler plugin.
---@class ConflictJugglerOpts : ConflictJugglerConfig
---@field highlight? ConflictJugglerConfigHighlight Highlighting config.
---@field treesitter? ConflictJugglerTreeSitterOpts Config for tree-sitter
---                                                 parsing.

-- ConflictJuggler default config
---@type ConflictJugglerConfig
local default_config = {
    highlight = {
        enabled = true,
        debounce_time = 100,
        namespace = 'ConflictJuggler',
        pattern = '*',
        start = {
            group_name = 'ConflictStart',
            mode = { HL.bold },
            background = {
                gui = '#465E3C',
                term = '113',
            },
        },
        start_label = {
            group_name = 'ConflictStartLabel',
            mode = { HL.bold, HL.italic },
            background = {
                gui = '#465E3C',
                term = '113',
            },
        },
        ours = {
            group_name = 'ConflictOurs',
            background = {
                gui = '#394634',
                term = '22',
            },
        },
        common_sep = {
            group_name = 'ConflictCommonSep',
            mode = { HL.bold },
            background = {
                gui = '#363944',
                term = '237',
            },
        },
        common_sep_label = {
            group_name = 'ConflictCommonSepLabel',
            mode = { HL.bold, HL.italic },
            background = {
                gui = '#363944',
                term = '237',
            },
        },
        common = {
            group_name = 'ConflictCommon',
            background = {
                gui = '#33353F',
                term = '236',
            },
        },
        sep = {
            group_name = 'ConflictSep',
            mode = { HL.bold },
            background = {
                gui = '#222327',
                term = '232',
            },
        },
        sep_label = {
            group_name = 'ConflictSepLabel',
            mode = { HL.bold, HL.italic },
            background = {
                gui = '#222327',
                term = '232',
            },
        },
        theirs = {
            group_name = 'ConflictTheirs',
            background = {
                gui = '#354157',
                term = '17',
            },
        },
        end_ = {
            group_name = 'ConflictEnd',
            mode = { HL.bold },
            background = {
                gui = '#394C70',
                term = '18',
            },
        },
        end_label = {
            group_name = 'ConflictEndLabel',
            mode = { HL.bold, HL.italic },
            background = {
                gui = '#394C70',
                term = '18',
            },
        },
    },
    treesitter = {
        lang = 'git_merge_conflict',
        filetype = 'git_merge_conflict',
        install_info = {
            url = 'https://github.com/pv-hernandez/tree-sitter-git-merge-conflict',
            files = { 'src/parser.c' },
            branch = 'v1.0.0',
            generate_requires_npm = false,
            requires_generate_from_grammar = false,
        },
    },
}

---@type table<string, fun(h: ConflictJugglerConfigHighlight): Highlight>
local group_links = {
    ['@conflict.start'] = function(h) return h.start end,
    ['@conflict.start.label'] = function(h) return h.start_label end,
    ['@conflict.ours'] = function(h) return h.ours end,
    ['@conflict.common_sep'] = function(h) return h.common_sep end,
    ['@conflict.common_sep.label'] = function(h) return h.common_sep_label end,
    ['@conflict.common'] = function(h) return h.common end,
    ['@conflict.sep'] = function(h) return h.sep end,
    ['@conflict.sep.label'] = function(h) return h.sep_label end,
    ['@conflict.theirs'] = function(h) return h.theirs end,
    ['@conflict.end'] = function(h) return h.end_ end,
    ['@conflict.end.label'] = function(h) return h.end_label end,
}

-- Converts a highlight config into arguments to the `:highlight` vim command
---@param hl Highlight
---@return string[]?
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

    if #args == 1 then
        return nil
    end

    return args
end

local function highlight_factory()
    local config = M._config
    local lang = config.treesitter.lang
    local query_name = 'highlights'
    local ns = vim.api.nvim_create_namespace(config.highlight.namespace)
    local query = vim.treesitter.query.get(lang, query_name)

    if not query then
        error(
            string.format(
                '[ConflictJuggler]: The query `%s` was not found for lang `%s`',
                query_name,
                lang
            )
        )
    end

    ---@param bufnr integer
    ---@return fun()
    local function _draw(bufnr)
        return function()
            local s = M._state[bufnr]
            if not s then
                return
            end
            if not vim.api.nvim_buf_is_valid(bufnr) then
                s.valid = false
                return
            end

            vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
            s.extmarks = {}
            for id, node in query:iter_captures(s.tree[1]:root(), bufnr) do
                local name = query.captures[id]
                local row1, col1, row2, col2 = node:range()
                table.insert(
                    s.extmarks,
                    vim.api.nvim_buf_set_extmark(
                        bufnr, ns, row1, col1,
                        {
                            end_row = row2,
                            end_col = col2,
                            hl_eol = true,
                            hl_group = '@' .. name,
                        }
                    )
                )
            end
        end
    end

    ---@param bufnr integer
    ---@return fun()
    local function _parse(bufnr)
        return function()
            local s = M._state[bufnr]
            if not s then
                return
            end
            local start_row = nil
            local end_row = nil
            local queue = s.queue
            s.queue = {}
            for _, r in ipairs(queue) do
                start_row = math.min(r.start_row, start_row or r.start_row)
                end_row = math.max(r.end_row, end_row or r.end_row)
            end
            local range = nil
            if start_row and end_row then
                range = { start_row, end_row }
            end

            local ok = false
            local tree = nil
            ok, tree = pcall(s.parser.parse, s.parser, range)
            if not ok then
                s.valid = false
                return
            end
            s.tree = tree
            vim.schedule(_draw(bufnr))
        end
    end

    ---@param bufnr integer The buffer number.
    ---@param start_row? integer The first row changed.
    ---@param end_row? integer The last row changed.
    ---@return boolean?
    return function(_, bufnr, _, start_row, end_row)
        local s = M._state[bufnr]
        if not s or not s.valid then
            return true
        end
        s.debouncer:stop()
        if start_row and end_row then
            table.insert(s.queue, { start_row = start_row, end_row = end_row })
        end
        s.debouncer:start(M._config.highlight.debounce_time, 0, _parse(bufnr))
    end
end

---@param bufnr integer The buffer number
local function detach(_, bufnr)
    local s = M._state[bufnr]

    if not s then
        return
    end

    s.debouncer:stop()
    s.debouncer:close()
    s.parser:destroy()
    local ns = vim.api.nvim_create_namespace(M._config.highlight.namespace)
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    M._state[bufnr] = nil
end

---@param config ConflictJugglerConfig
local function setup_treesitter(config)
    local lang = M._config.treesitter.lang
    local ok = pcall(vim.treesitter.language.add, lang)
    if not ok then
        local parsers = require('nvim-treesitter.parsers')
        local parser_config = parsers.get_parser_configs()
        parser_config[config.treesitter.lang] = {
            install_info = config.treesitter.install_info,
            filetype = config.treesitter.filetype,
        }
        vim.cmd({ cmd = 'TSInstallSync!', args = { config.treesitter.lang } })

        vim.treesitter.language.add(lang)
    end

    local required_queries = { 'highlights', 'conflicts' }

    for _, query_name in ipairs(required_queries) do
        local query = vim.treesitter.query.get(lang, query_name)

        if not query then
            error(
                string.format(
                    '[ConflictJuggler]: The query query named `%s` for ' ..
                    'language `%s` was not found.',
                    query_name,
                    lang
                ),
                vim.log.levels.WARN
            )
        end
    end
end

---@param config ConflictJugglerConfig
local function setup_highlight(config)
    local h = config.highlight

    for group, hl_config in pairs(group_links) do
        local hl = hl_config(h)
        local args = hl_to_args(hl)
        if args then
            vim.cmd({
                cmd = 'highlight',
                args = { 'default', unpack(args) },
            })
        end
        vim.cmd({
            cmd = 'highlight',
            args = { 'link', group, hl.group_name },
        })
    end

    local highlight = highlight_factory()
    local augroup = vim.api.nvim_create_augroup('ConflictJugglerHighlight', {})
    vim.api.nvim_create_autocmd(
        { 'BufReadPost', 'FileChangedShellPost', 'ShellFilterPost', 'StdinReadPost' },
        {
            pattern = M._config.highlight.pattern,
            group = augroup,
            desc = 'Update ConflictJuggler highlights',
            callback = function(args)
                if M._state[args.buf] then
                    return
                end
                local debouncer = vim.uv.new_timer()
                if not debouncer then
                    return
                end

                M._state[args.buf] = {
                    parser = vim.treesitter.get_parser(args.buf, M._config.treesitter.lang),
                    debouncer = debouncer,
                    tree = {},
                    queue = {},
                    extmarks = {},
                    valid = true,
                }

                vim.api.nvim_buf_attach(
                    args.buf,
                    true, {
                        on_lines = highlight,
                        on_detach = detach,
                    })

                highlight('lines', args.buf, -1, nil, nil)
            end,
        }
    )

    vim.api.nvim_create_autocmd(
        { 'BufWipeout' },
        {
            pattern = M._config.highlight.pattern,
            group = augroup,
            desc = 'Cleanup ConflictJuggler internal state of deleted buffer',
            callback = function(args)
                local s = M._state[args.buf]
                if not s then
                    return
                end
                s.valid = false
            end,
        }
    )
end

-- Initializes the plugin.
---@param opts? ConflictJugglerOpts
function M.setup(opts)
    local config = vim.tbl_deep_extend('keep', opts or {}, default_config)
    ---@cast config ConflictJugglerConfig
    M._config = config

    setup_treesitter(config)

    if config.highlight.enabled then
        setup_highlight(config)
        M._highlight_enabled = true
    end
end

-- Frees the resources user by the plugin.
function M.deactivate()
    if M._highlight_enabled then
        local ns = vim.api.nvim_create_namespace(M._config.highlight.namespace)

        for bufnr, state in pairs(M._state) do
            state.valid = false
            state.debouncer:stop()
            state.debouncer:close()
            state.parser:destroy()

            vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
        end
        M._state = {}

        local h = M._config.highlight
        for group, hl_config in pairs(group_links) do
            local hl = hl_config(h)
            local args = hl_to_args(hl)
            if args then
                vim.cmd({ cmd = 'highlight', args = { 'clear', hl.group_name } })
            end
            vim.cmd({ cmd = 'highlight', args = { 'clear', group } })
        end

        vim.api.nvim_del_augroup_by_name('ConflictJugglerHighlight')
    end
end

-- Moves common lines from inside conflict blocks out of the blocks.
---@param range_start integer Range starting line
---@param range_end integer Range ending line
function M.simplify_conflicts(range_start, range_end)
    local parser = P:new({ config = M })

    local buffer_content =
        vim.api.nvim_buf_get_lines(0, range_start - 1, range_end, false)

    parser:parse(0, range_start, range_end)

    local modified = false
    for i = #parser.conflicts, 1, -1 do
        local conflict = parser.conflicts[i]
        if conflict.level == parser.top_level then
            modified = modified or conflict:simplify(buffer_content)
        end
    end

    if modified then
        vim.api.nvim_buf_set_lines(
            0,
            range_start - 1,
            range_end,
            false,
            buffer_content
        )
    end
end

return M
