---@class Conflict A conflict block with line numbers for the conflict markers.
---@field level integer The nesting level of this conflict.
---@field start_line integer The line number of the <<<<<<< marker.
---@field common_line? integer The line number of the ||||||| marker.
---@field sep_line integer The line number of the ======= marker.
---@field end_line integer The line number of the >>>>>>> marker.
local C = {}

---@param o Conflict
---@return Conflict
function C:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

---@param lines string[]
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

    -- Execute changes in reverse order to preserve line numbers for later operations

    -- If there are no common parts and the conflict is not empty we return without modifying
    if
        common_head_len <= 0
        and common_tail_len <= 0
        and (left_len > 0 or right_len > 0)
    then
        return
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
        return
    end

    -- If the head and tail overlap, the conflict is ambigous and should not be resolved automatically.
    if
        common_head_len + common_tail_len > left_len
        or common_head_len + common_tail_len > right_len
    then
        return
    end

    -- If there is a common tail we resolve the tail (move end marker up before the tail)
    if common_tail_len > 0 then
        local end_line = table.remove(lines, self.end_line)
        table.insert(lines, self.end_line - common_tail_len, end_line)
    end

    -- If there is a common head we resolve the head (remove head from the right)
    if common_head_len > 0 then
        local right_head_end = self.sep_line + common_head_len
        local right_head_start = self.sep_line + 1
        for l = right_head_end, right_head_start, -1 do
            table.remove(lines, l)
        end
    end

    -- If there is a common tail we resolve the tail (remove tail from the left)
    if common_tail_len > 0 then
        local left_tail_end = self.start_line + left_len
        local left_tail_start = self.start_line + left_len - common_tail_len + 1
        for l = left_tail_end, left_tail_start, -1 do
            table.remove(lines, l)
        end
    end

    -- If there is a common head we resolve the head (move start marker down after head)
    if common_head_len > 0 then
        local start_line = table.remove(lines, self.start_line)
        table.insert(lines, self.start_line + common_head_len, start_line)
    end
end

return C
