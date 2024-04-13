local Conflict = require('conflict-squeezer.conflict')

local CONFLICT_START = '<<<<<<<'
local CONFLICT_COMMON = '|||||||'
local CONFLICT_SEP = '======='
local CONFLICT_END = '>>>>>>>'

---@class Token
---@field token_type string
---@field line integer
---@field column integer
---@field length integer
---@field value string
local Token = {}

---@param o Token
---@return Token
function Token:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

---@param line_number integer
---@param line string
---@return Token
function Token.start_token(line_number, line)
    return Token:new{
        token_type = CONFLICT_START,
        line = line_number,
        column = 0,
        length = #line,
        value = line,
    }
end

---@param line_number integer
---@param line string
---@return Token
function Token.common_token(line_number, line)
    return Token:new{
        token_type = CONFLICT_COMMON,
        line = line_number,
        column = 0,
        length = #line,
        value = line,
    }
end

---@param line_number integer
---@param line string
---@return Token
function Token.sep_token(line_number, line)
    return Token:new{
        token_type = CONFLICT_SEP,
        line = line_number,
        column = 0,
        length = #line,
        value = line,
    }
end

---@param line_number integer
---@param line string
---@return Token
function Token.end_token(line_number, line)
    return Token:new{
        token_type = CONFLICT_END,
        line = line_number,
        column = 0,
        length = #line,
        value = line,
    }
end

---@class State
---@field start_token? Token
---@field common_token? Token
---@field sep_token? Token
---@field end_token? Token
local St = {}

---@class ConflictParser
---@field state State
---@field state_stack State[]
---@field conflicts Conflict[]
---@field top_level integer
local CP = {}

---@param o? ConflictParser
---@return ConflictParser
function CP:new(o)
    o = vim.tbl_deep_extend("keep", o or {}, {
        state = {},
        state_stack = {},
        conflicts = {},
        top_level = -1,
    })
    setmetatable(o, self)
    self.__index = self
    return o
end

---@private
---@param line_number integer
---@param line string
function CP:parse_line(line_number, line)
    local is_start = function()
        return string.sub(line, 1, #CONFLICT_START) == CONFLICT_START
    end
    local is_common = function()
        return string.sub(line, 1, #CONFLICT_COMMON) == CONFLICT_COMMON
    end
    local is_sep = function()
        return string.sub(line, 1, #CONFLICT_SEP) == CONFLICT_SEP
    end
    local is_end = function()
        return string.sub(line, 1, #CONFLICT_END) == CONFLICT_END
    end

    if self.state.sep_token then
        -- expecting end or start
        if is_end() then
            self.state.end_token = Token.end_token(line_number, line)
            local conflict = Conflict:new{
                level = #self.state_stack,
                start_line = self.state.start_token.line,
                common_line = self.state.common_token and self.state.common_token.line or nil,
                sep_line = self.state.sep_token.line,
                end_line = self.state.end_token.line,
            }
            table.insert(self.conflicts, conflict)
            if self.top_level == -1 or self.top_level > conflict.level then
                self.top_level = conflict.level
            end

            self.state = table.remove(self.state_stack) or {}
        elseif is_start() then
            table.insert(self.state_stack, self.state)
            self.state = {
                start_token = Token.start_token(line_number, line)
            }
        end
    elseif self.state.common_token then
        -- expecting sep or start
        if is_sep() then
            self.state.sep_token = Token.sep_token(line_number, line)
        elseif is_start() then
            table.insert(self.state_stack, self.state)
            self.state = {
                start_token = Token.start_token(line_number, line)
            }
        end
    elseif self.state.start_token then
        -- expecting common sep or start
        if is_common() then
            self.state.common_token = Token.common_token(line_number, line)
        elseif is_sep() then
            self.state.sep_token = Token.sep_token(line_number, line)
        elseif is_start() then
            table.insert(self.state_stack, self.state)
            self.state = {
                start_token = Token.start_token(line_number, line)
            }
        end
    else
        -- expecting start
        if is_start() then
            self.state.start_token = Token.start_token(line_number, line)
        end
    end
end

---@param lines string[]
function CP:parse(lines)
    for line_number, line in ipairs(lines) do
        self:parse_line(line_number, line)
    end
end

return CP
