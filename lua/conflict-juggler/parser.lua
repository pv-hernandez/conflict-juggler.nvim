local Conflict = require('conflict-juggler.conflict')

-- Color group for Terminal and GUI mode.
---@class ColorGroup
---@field gui string Color string for GUI mode.
---@field term string Color string for Terminal mode.

-- Highlight metadata.  If any other field is set other than `group_name`, the
-- highlight group is created with those settings.  If only `group_name` is set
-- the highlight group is only linked to that name.
---@class Highlight
---@field group_name string Name for the highlight group.
---@field background? ColorGroup Background color of highlight.
---@field foreground? ColorGroup Foreground color of highlight.
---@field special? ColorGroup Special color of highlight.
---@field mode? HighlightMode[] Mode of highlight.

-- Configuration for highlighting the conflict regions.
---@class ConflictJugglerConfigHighlight : HighlightConfig
---@field enabled boolean Enable the highlighting.
---@field debounce_time integer Number of milliseconds for debouncing the
---                             highlighter.
---@field pattern string Pattern for the highlighting auto_cmd.

-- Constructor parameters for the parser
---@class PartialConflictParser : ConflictParser
---@field conflicts? Conflict[] Conflict blocks found by the parser.
---@field top_level? integer The nesting level (how many conflict blocks deep)
---                          of the current position.

---@class ConflictParser
---@field config ConflictJuggler Plugin internal state.
---@field conflicts Conflict[] Conflict blocks found by the parser.
---@field top_level integer The nesting level (how many conflict blocks deep)
---                         of the current position.
local P = {}

---@param o PartialConflictParser
---@return ConflictParser
function P:new(o)
    o = vim.tbl_deep_extend('keep', o, {
        conflicts = {},
        top_level = -1,
    })
    if not o.config then
        error('The parser requires the config option')
    end
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Use treesitter parser to extract conflict blocks.
---@param bufnr integer Buffer number to parse.
---@param start integer Line number to start parsing.
---@param stop integer Line number to stop parsing
function P:parse(bufnr, start, stop)
    local state = self.config._state[bufnr]
    if not state then
        return
    end

    local lang = self.config._config.treesitter.lang
    local query = vim.treesitter.query.get(lang, 'conflicts')
    if not query then
        error(
            string.format(
                '[ConflictJuggler]: Query `conflicts` not defined for ' ..
                'language `%s`',
                lang
            )
        )
    end

    self.top_level = -1

    for _, match in query:iter_matches(
        state.tree[1]:root(), bufnr, start, stop, { all = true }
    ) do
        local conflict_opts = {
            level = 0,
        }

        for id, nodes in pairs(match) do
            local name = query.captures[id]
            local node = nodes[1]
            if name == 'conflict' then
                conflict_opts.level = 0
                while node do
                    local parent = node:parent()
                    if not parent then
                        break
                    end
                    node = parent
                    if node:type() == 'conflict' then
                        conflict_opts.level = conflict_opts.level + 1
                    end
                end
                goto continue
            end

            conflict_opts[name] = node:start()
            ::continue::
        end

        local conflict = Conflict:new(conflict_opts)
        table.insert(self.conflicts, conflict)
        self.top_level = math.max(self.top_level, conflict.level)
    end
end

return P
