---@class Conflict
---@field level number
---@field start_line number
---@field common_line? number
---@field sep_line number
---@field end_line number
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
function C:squeeze(lines)
    local left_len = (self.common_line or self.sep_line) - self.start_line
    local right_len = self.end_line - self.sep_line

    -- Find the common head
    local common_head_len = 0
    while common_head_len < left_len and common_head_len < right_len do
        local left_line = common_head_len + self.start_line
        local right_line = common_head_len + self.sep_line
        if lines[left_line] ~= lines[right_line] then
            break
        end
        common_head_len = common_head_len + 1
    end

    -- Find the common tail
    local common_tail_len = 0
    while common_tail_len < left_len and common_tail_len < right_len do
        local left_line = left_len - 1 - common_tail_len + self.start_line
        local right_line = right_len - 1 - common_tail_len + self.sep_line
        if lines[left_line] ~= lines[right_line] then
            break
        end
        common_tail_len = common_tail_len + 1
    end

    -- If both sides are the same we resolve the conflict and return
    if common_head_len == common_tail_len and left_len == right_len and common_head_len == left_len then
        local l = self.common_line or self.sep_line
        while l <= self.end_line do
            table.remove(lines, l)
        end
        table.remove(lines, self.start_line)
        return
    end

    -- If there is a common tail we resolve the tail
    if common_tail_len > 0 then
        local end_line = table.remove(lines, self.end_line)
        table.insert(lines, self.end_line - common_tail_len, end_line)

        local l = self.start_line + left_len - 1
        while l > self.start_line + left_len - 1 - common_tail_len do
            table.remove(lines, l)
        end
    end

    -- If ther is a common head we resolve the head
    if common_head_len > 0 then
        local l = self.sep_line + 1
        while l < self.sep_line + common_tail_len do
            table.remove(lines, l)
        end

        local start_line = table.remove(lines, self.start_line)
        table.insert(lines, self.start_line + common_head_len - 1, start_line)
    end
end

return C
