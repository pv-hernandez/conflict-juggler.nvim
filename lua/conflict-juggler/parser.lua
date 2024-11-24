local Conflict = require('conflict-juggler.conflict')

-- Type of the token
---@enum TokenType
local TokenType = {
    CONFLICT_START = 0,
    CONFLICT_COMMON = 1,
    CONFLICT_SEP = 2,
    CONFLICT_END = 3,
}

-- Lua patterns to identify the conflict block.
---@class ConflictMarkers
---@field ours string Lua pattern to match the line that starts the conflict
---                   `ours` region.  The start of the conflict block.
---@field base string Lua pattern to match the line that starts the conflict
---                   `base` region.  After the `ours` region.
---@field sep string Lua pattern to match the line that ends the conflict
---                  `base` region, or the `ours` region if ther is no `base`
---                  region.  Before the `theirs` region.
---@field theirs string Lua pattern to match the lina that ends the `theirs`
---                     region.  The end of the conflict block.

---@class Token
---@field token_type TokenType
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
    return Token:new({
        token_type = TokenType.CONFLICT_START,
        line = line_number,
        column = 0,
        length = #line,
        value = line,
    })
end

---@param line_number integer
---@param line string
---@return Token
function Token.common_token(line_number, line)
    return Token:new({
        token_type = TokenType.CONFLICT_COMMON,
        line = line_number,
        column = 0,
        length = #line,
        value = line,
    })
end

---@param line_number integer
---@param line string
---@return Token
function Token.sep_token(line_number, line)
    return Token:new({
        token_type = TokenType.CONFLICT_SEP,
        line = line_number,
        column = 0,
        length = #line,
        value = line,
    })
end

---@param line_number integer
---@param line string
---@return Token
function Token.end_token(line_number, line)
    return Token:new({
        token_type = TokenType.CONFLICT_END,
        line = line_number,
        column = 0,
        length = #line,
        value = line,
    })
end

-- Internal state of the parser
---@class State
---@field start_token? Token
---@field common_token? Token
---@field sep_token? Token
---@field end_token? Token

-- Constructor parameters for the parser
---@class ConflictParserOpts
---@field markers ConflictMarkers How to match the conflict regions.

---@class ConflictParser
---@field markers ConflictMarkers How to match the conflict regions.
---@field state State Internal state of the parser.
---@field state_stack State[] Stack of states of the parser.
---@field conflicts Conflict[] Conflict blocks found by the parser.
---@field top_level integer The nesting level (how many conflict blocks deep)
---                         of the current position.
local P = {}

---@param o ConflictParser
---@return ConflictParser
function P:new(o)
    o = vim.tbl_deep_extend('keep', o, {
        state = {},
        state_stack = {},
        conflicts = {},
        top_level = -1,
    })
    if not o.markers then
        error('The parser requires the `markers` option', 2)
    end
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Checks if the `line` matches with the begining of the `ours` conflict region.
---@private
---@param line string
---@return boolean
function P:is_start(line)
    return string.find(line, self.markers.ours) ~= nil
end

-- Checks if the `line` matches with the begining of the `base` conflict region.
---@private
---@param line string
---@return boolean
function P:is_common(line)
    return string.find(line, self.markers.base) ~= nil
end

-- Checks if the `line` matches with the begining of the `theirs` conflict
-- region.
---@private
---@param line string
---@return boolean
function P:is_sep(line)
    return string.find(line, self.markers.sep) ~= nil
end

-- Checks if the `line` matches with the end of the `theirs` conflict region.
---@private
---@param line string
---@return boolean
function P:is_end(line)
    return string.find(line, self.markers.theirs) ~= nil
end

-- Parses a single line of input and updates the parser internal state.
---@private
---@param line_number integer Number of the line being parsed.
---@param line string Value of the line being parsed.
function P:parse_line(line_number, line)
    if self.state.sep_token then
        -- expecting end or start
        if self:is_end(line) then
            self.state.end_token = Token.end_token(line_number, line)
            local conflict = Conflict:new({
                level = #self.state_stack,
                start_line = self.state.start_token.line,
                common_line = self.state.common_token
                        and self.state.common_token.line
                    or nil,
                sep_line = self.state.sep_token.line,
                end_line = self.state.end_token.line,
            })
            table.insert(self.conflicts, conflict)
            if self.top_level == -1 or self.top_level > conflict.level then
                self.top_level = conflict.level
            end

            self.state = table.remove(self.state_stack) or {}
        elseif self:is_start(line) then
            table.insert(self.state_stack, self.state)
            self.state = {
                start_token = Token.start_token(line_number, line),
            }
        end
    elseif self.state.common_token then
        -- expecting sep or start
        if self:is_sep(line) then
            self.state.sep_token = Token.sep_token(line_number, line)
        elseif self:is_start(line) then
            table.insert(self.state_stack, self.state)
            self.state = {
                start_token = Token.start_token(line_number, line),
            }
        end
    elseif self.state.start_token then
        -- expecting common sep or start
        if self:is_common(line) then
            self.state.common_token = Token.common_token(line_number, line)
        elseif self:is_sep(line) then
            self.state.sep_token = Token.sep_token(line_number, line)
        elseif self:is_start(line) then
            table.insert(self.state_stack, self.state)
            self.state = {
                start_token = Token.start_token(line_number, line),
            }
        end
    else
        -- expecting start
        if self:is_start(line) then
            self.state.start_token = Token.start_token(line_number, line)
        end
    end
end

-- Parse all lines to extract conflict blocks.
---@param lines string[] Array of lines to be parsed.
function P:parse(lines)
    for line_number, line in ipairs(lines) do
        self:parse_line(line_number, line)
    end
end

return P
