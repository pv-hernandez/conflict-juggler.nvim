-- Conflict block metadata found by a parser.
---@class Conflict A conflict block with line numbers for the conflict markers.
---@field level integer The nesting level of this conflict.
---@field start_line integer The line number of the <<<<<<< marker.
---@field common_line? integer The line number of the ||||||| marker.
---@field sep_line integer The line number of the ======= marker.
---@field end_line integer The line number of the >>>>>>> marker.
local C = {}

-- Construct a new Conflict instance.
---@param o Conflict
---@return Conflict
function C:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Moves common lines inside the conflict block to the outside.  If the
-- conflict block becomes empty, it is removed.  If there is an ambiguity in
-- which part of the conflict should be moved, the conflict region is not
-- changed.
--
-- One example of an ambiguous conflict is the following:
-- ```
-- <<<<<<< HEAD
-- a
-- b
-- a
-- =======
-- a
-- >>>>>>> remote
-- ```
--
--  In this conflict the line `a` could end up above the conflict, or below.
--
---@param lines string[] Text split into lines that will be simplified by this
---                      conflict definition.  The array is mutated in place.
---@return boolean modified Returns true if the simplification modified the lines.
function C:simplify(lines)
    local left_len = (self.common_line or self.sep_line) - self.start_line - 1
    local right_len = self.end_line - self.sep_line - 1

    -- Find the common head
    local common_head_len = 0
    while common_head_len < left_len and common_head_len < right_len do
        local left_line = common_head_len + self.start_line + 1
        local right_line = common_head_len + self.sep_line + 1
        if lines[left_line] ~= lines[right_line] then
            break
        end
        common_head_len = common_head_len + 1
    end

    -- Find the common tail
    local common_tail_len = 0
    while common_tail_len < left_len and common_tail_len < right_len do
        local left_line = left_len - common_tail_len + self.start_line
        local right_line = right_len - common_tail_len + self.sep_line
        if lines[left_line] ~= lines[right_line] then
            break
        end
        common_tail_len = common_tail_len + 1
    end

    -- Execute changes in reverse order to preserve line numbers for later
    -- operations

    -- If there are no common parts and the conflict is not empty we return
    -- without modifying
    if
        common_head_len <= 0
        and common_tail_len <= 0
        and (left_len > 0 or right_len > 0)
    then
        return false
    end

    -- If both sides are the same we resolve the conflict and return
    if
        common_head_len == common_tail_len
        and left_len == right_len
        and common_head_len == left_len
    then
        for l = self.end_line, self.common_line or self.sep_line, -1 do
            table.remove(lines, l)
        end
        table.remove(lines, self.start_line)
        return true
    end

    -- If the head and tail overlap, the conflict is ambigous and should not be
    -- resolved automatically.
    if
        common_head_len + common_tail_len > left_len
        or common_head_len + common_tail_len > right_len
    then
        return false
    end

    local modified = false

    -- If there is a common tail we resolve the tail (move end marker up before
    -- the tail)
    if common_tail_len > 0 then
        local end_line = table.remove(lines, self.end_line)
        table.insert(lines, self.end_line - common_tail_len, end_line)
        modified = true
    end

    -- If there is a common head we resolve the head (remove head from the
    -- right)
    if common_head_len > 0 then
        local right_head_end = self.sep_line + common_head_len
        local right_head_start = self.sep_line + 1
        for l = right_head_end, right_head_start, -1 do
            table.remove(lines, l)
            modified = true
        end
    end

    -- If there is a common tail we resolve the tail (remove tail from the
    -- left)
    if common_tail_len > 0 then
        local left_tail_end = self.start_line + left_len
        local left_tail_start = self.start_line + left_len - common_tail_len + 1
        for l = left_tail_end, left_tail_start, -1 do
            table.remove(lines, l)
            modified = true
        end
    end

    -- If there is a common head we resolve the head (move start marker down
    -- after head)
    if common_head_len > 0 then
        local start_line = table.remove(lines, self.start_line)
        table.insert(lines, self.start_line + common_head_len, start_line)
        modified = true
    end

    return modified
end

---@class HighlightConfig
---@field namespace string Name for the highlight namespace.
---@field start Highlight How to highlight the first line of the conflict
---                       block.
---@field start_label Highlight How to highlight the label at the first line
---                             of the conflict block.
---@field ours Highlight How to highlight `ours` region.
---@field common_sep Highlight How to highlight the line separating `ours` and
---                            `common`.
---@field common_sep_label Highlight How to highlight the label at the line
---                                  separating `ours` and `common`.
---@field common Highlight How to highlight the `common` region.
---@field sep Highlight How to highlight the line separating `base` (or `ours`
---                     if `base` is not present) from `theirs`.
---@field sep_label Highlight How to highlight the label at the line separating
---                           `base` (or `ours` if `base` is not present) from
---                           `theirs`.
---@field theirs Highlight How to highlight the `theirs` region.
---@field end_ Highlight How to highlight the last line of the conflict block.
---@field end_label Highlight How to highlight the label at the last line of
---                           the conflict block.

-- Apply highlighting to the text in this conflict region.
---@param bufnr number Buffer number for highlighting
---@param highlight HighlightConfig Highlighting configuration
function C:highlight(bufnr, highlight)
    local ns_id = vim.api.nvim_create_namespace(highlight.namespace)

    ---@param group string
    ---@param line number
    ---@param end_line number?
    local function add_hl(group, line, end_line)
        if not end_line then
            end_line = line
        end
        vim.api.nvim_buf_set_extmark(
            bufnr, ns_id, line - 1, 0,
            {
                end_row = end_line,
                hl_group = group,
                hl_eol = true,
            }
        )
    end

    add_hl(highlight.start.group_name, self.start_line)
    add_hl(highlight.ours.group_name, self.start_line + 1, (self.common_line or self.sep_line) - 1)

    if self.common_line then
        add_hl(highlight.common_sep.group_name, self.common_line)
        add_hl(highlight.common.group_name, self.common_line + 1, self.sep_line - 1)
    end

    add_hl(highlight.sep.group_name, self.sep_line)
    add_hl(highlight.theirs.group_name, self.sep_line + 1, self.end_line - 1)
    add_hl(highlight.end_.group_name, self.end_line)
end

return C
