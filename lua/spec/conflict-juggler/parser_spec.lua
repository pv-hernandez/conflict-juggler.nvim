local Parser = require('conflict-juggler.parser')


describe('parse conflicts', function()
    local markers = {
        ours = '^<<<<<<<%s*(.-)$',
        base = '^|||||||%s*(.-)$',
        sep = '^=======%s*(.-)$',
        theirs = '^>>>>>>>%s*(.-)$',
    }

    it('should not detect conflicts', function()
        local input_lines = {
            'some',
            'text',
            'without',
            'conflicts',
        }

        local parser = Parser:new({ markers = markers })

        parser:parse(input_lines)

        assert.is.same({}, parser.state)
        assert.is.same({}, parser.state_stack)
        assert.is.equal(-1, parser.top_level)
        assert.is.equal(0, #parser.conflicts)
    end)

    it('should detect an empty conflict', function()
        local input_lines = {
            '<<<<<<<',
            '|||||||',
            '=======',
            '>>>>>>>',
        }

        local parser = Parser:new({ markers = markers })

        parser:parse(input_lines)

        assert.is.same({}, parser.state)
        assert.is.same({}, parser.state_stack)
        assert.is.equal(0, parser.top_level)
        assert.is.equal(1, #parser.conflicts)
        assert.is.equal(1, parser.conflicts[1].start_line)
        assert.is.equal(2, parser.conflicts[1].common_line)
        assert.is.equal(3, parser.conflicts[1].sep_line)
        assert.is.equal(4, parser.conflicts[1].end_line)
        assert.is.equal(0, parser.conflicts[1].level)
    end)
    it('should detect an empty conflict without common line', function()
        local input_lines = {
            '<<<<<<<',
            '=======',
            '>>>>>>>',
        }

        local parser = Parser:new({ markers = markers })

        parser:parse(input_lines)

        assert.is.same({}, parser.state)
        assert.is.same({}, parser.state_stack)
        assert.is.equal(0, parser.top_level)
        assert.is.equal(1, #parser.conflicts)
        assert.is.equal(1, parser.conflicts[1].start_line)
        assert.is.Nil(parser.conflicts[1].common_line)
        assert.is.equal(2, parser.conflicts[1].sep_line)
        assert.is.equal(3, parser.conflicts[1].end_line)
        assert.is.equal(0, parser.conflicts[1].level)
    end)

    it('should detect a single line conflict', function()
        local input_lines = {
            '<<<<<<<',
            'a',
            '|||||||',
            'c',
            '=======',
            'b',
            '>>>>>>>',
        }

        local parser = Parser:new({ markers = markers })

        parser:parse(input_lines)

        assert.is.same({}, parser.state)
        assert.is.same({}, parser.state_stack)
        assert.is.equal(0, parser.top_level)
        assert.is.equal(1, #parser.conflicts)
        assert.is.equal(1, parser.conflicts[1].start_line)
        assert.is.equal(3, parser.conflicts[1].common_line)
        assert.is.equal(5, parser.conflicts[1].sep_line)
        assert.is.equal(7, parser.conflicts[1].end_line)
        assert.is.equal(0, parser.conflicts[1].level)
    end)
    it('should detect a single line conflict without common line', function()
        local input_lines = {
            '<<<<<<<',
            'a',
            '=======',
            'b',
            '>>>>>>>',
        }

        local parser = Parser:new({ markers = markers })

        parser:parse(input_lines)

        assert.is.same({}, parser.state)
        assert.is.same({}, parser.state_stack)
        assert.is.equal(0, parser.top_level)
        assert.is.equal(1, #parser.conflicts)
        assert.is.equal(1, parser.conflicts[1].start_line)
        assert.is.Nil(parser.conflicts[1].common_line)
        assert.is.equal(3, parser.conflicts[1].sep_line)
        assert.is.equal(5, parser.conflicts[1].end_line)
        assert.is.equal(0, parser.conflicts[1].level)
    end)

    it('should detect a conflict with prefix text', function()
        local input_lines = {
            'prefix',
            'text',
            '<<<<<<<',
            'a',
            '|||||||',
            'c',
            '=======',
            'b',
            '>>>>>>>',
        }

        local parser = Parser:new({ markers = markers })

        parser:parse(input_lines)

        assert.is.same({}, parser.state)
        assert.is.same({}, parser.state_stack)
        assert.is.equal(0, parser.top_level)
        assert.is.equal(1, #parser.conflicts)
        assert.is.equal(3, parser.conflicts[1].start_line)
        assert.is.equal(5, parser.conflicts[1].common_line)
        assert.is.equal(7, parser.conflicts[1].sep_line)
        assert.is.equal(9, parser.conflicts[1].end_line)
        assert.is.equal(0, parser.conflicts[1].level)
    end)
    it('should detect a conflict with prefix text without common line', function()
        local input_lines = {
            'prefix',
            'text',
            '<<<<<<<',
            'a',
            '=======',
            'b',
            '>>>>>>>',
        }

        local parser = Parser:new({ markers = markers })

        parser:parse(input_lines)

        assert.is.same({}, parser.state)
        assert.is.same({}, parser.state_stack)
        assert.is.equal(0, parser.top_level)
        assert.is.equal(1, #parser.conflicts)
        assert.is.equal(3, parser.conflicts[1].start_line)
        assert.is.Nil(parser.conflicts[1].common_line)
        assert.is.equal(5, parser.conflicts[1].sep_line)
        assert.is.equal(7, parser.conflicts[1].end_line)
        assert.is.equal(0, parser.conflicts[1].level)
    end)

    it('should detect a conflict with suffix text', function()
        local input_lines = {
            '<<<<<<<',
            'a',
            '|||||||',
            'c',
            '=======',
            'b',
            '>>>>>>>',
            'suffix',
            'text',
        }

        local parser = Parser:new({ markers = markers })

        parser:parse(input_lines)

        assert.is.same({}, parser.state)
        assert.is.same({}, parser.state_stack)
        assert.is.equal(0, parser.top_level)
        assert.is.equal(1, #parser.conflicts)
        assert.is.equal(1, parser.conflicts[1].start_line)
        assert.is.equal(3, parser.conflicts[1].common_line)
        assert.is.equal(5, parser.conflicts[1].sep_line)
        assert.is.equal(7, parser.conflicts[1].end_line)
        assert.is.equal(0, parser.conflicts[1].level)
    end)
    it('should detect a conflict with suffix text without common line', function()
        local input_lines = {
            '<<<<<<<',
            'a',
            '=======',
            'b',
            '>>>>>>>',
            'suffix',
            'text',
        }

        local parser = Parser:new({ markers = markers })

        parser:parse(input_lines)

        assert.is.same({}, parser.state)
        assert.is.same({}, parser.state_stack)
        assert.is.equal(0, parser.top_level)
        assert.is.equal(1, #parser.conflicts)
        assert.is.equal(1, parser.conflicts[1].start_line)
        assert.is.Nil(parser.conflicts[1].common_line)
        assert.is.equal(3, parser.conflicts[1].sep_line)
        assert.is.equal(5, parser.conflicts[1].end_line)
        assert.is.equal(0, parser.conflicts[1].level)
    end)

    it('should detect a conflict with prefix and suffix text', function()
        local input_lines = {
            'prefix',
            'text',
            '<<<<<<<',
            'a',
            '|||||||',
            'c',
            '=======',
            'b',
            '>>>>>>>',
            'suffix',
            'text',
        }

        local parser = Parser:new({ markers = markers })

        parser:parse(input_lines)

        assert.is.same({}, parser.state)
        assert.is.same({}, parser.state_stack)
        assert.is.equal(0, parser.top_level)
        assert.is.equal(1, #parser.conflicts)
        assert.is.equal(3, parser.conflicts[1].start_line)
        assert.is.equal(5, parser.conflicts[1].common_line)
        assert.is.equal(7, parser.conflicts[1].sep_line)
        assert.is.equal(9, parser.conflicts[1].end_line)
        assert.is.equal(0, parser.conflicts[1].level)
    end)
    it('should detect a conflict with prefix and suffix text without common line', function()
        local input_lines = {
            'prefix',
            'text',
            '<<<<<<<',
            'a',
            '=======',
            'b',
            '>>>>>>>',
            'suffix',
            'text',
        }

        local parser = Parser:new({ markers = markers })

        parser:parse(input_lines)

        assert.is.same({}, parser.state)
        assert.is.same({}, parser.state_stack)
        assert.is.equal(0, parser.top_level)
        assert.is.equal(1, #parser.conflicts)
        assert.is.equal(3, parser.conflicts[1].start_line)
        assert.is.Nil(parser.conflicts[1].common_line)
        assert.is.equal(5, parser.conflicts[1].sep_line)
        assert.is.equal(7, parser.conflicts[1].end_line)
        assert.is.equal(0, parser.conflicts[1].level)
    end)

    it('should detect multiple conflicts', function()
        local input_lines = {
            '<<<<<<< aa',
            'a',
            '||||||| bb',
            'c',
            '======= cc',
            'b',
            '>>>>>>> dd',
            'text',
            '<<<<<<< aa',
            'a',
            '======= cc',
            'b',
            '>>>>>>> dd',
            'more text',
            '<<<<<<< aa',
            'a',
            '||||||| bb',
            'c',
            '======= cc',
            'b',
            '>>>>>>> dd',
        }

        local parser = Parser:new({ markers = markers })

        parser:parse(input_lines)

        assert.is.same({}, parser.state)
        assert.is.same({}, parser.state_stack)
        assert.is.equal(0, parser.top_level)
        assert.is.equal(3, #parser.conflicts)

        assert.is.equal(1, parser.conflicts[1].start_line)
        assert.is.equal(3, parser.conflicts[1].common_line)
        assert.is.equal(5, parser.conflicts[1].sep_line)
        assert.is.equal(7, parser.conflicts[1].end_line)
        assert.is.equal(0, parser.conflicts[1].level)

        assert.is.equal(9, parser.conflicts[2].start_line)
        assert.is.Nil(parser.conflicts[2].common_line)
        assert.is.equal(11, parser.conflicts[2].sep_line)
        assert.is.equal(13, parser.conflicts[2].end_line)
        assert.is.equal(0, parser.conflicts[2].level)

        assert.is.equal(15, parser.conflicts[3].start_line)
        assert.is.equal(17, parser.conflicts[3].common_line)
        assert.is.equal(19, parser.conflicts[3].sep_line)
        assert.is.equal(21, parser.conflicts[3].end_line)
        assert.is.equal(0, parser.conflicts[3].level)
    end)

    it('should detect nested conflicts', function()
        local input_lines = {
            '<<<<<<< aa',
            'a',
            '<<<<<<< aaa',
            'aa',
            '||||||| bbb',
            'cc',
            '======= ccc',
            'bb',
            '>>>>>>> ddd',
            '||||||| bb',
            'c',
            '<<<<<<< aaa',
            'ba',
            '||||||| bbb',
            'vc',
            '======= ccc',
            'ab',
            '>>>>>>> ddd',
            '======= cc',
            'b',
            '<<<<<<< aaa',
            'ba',
            '||||||| bbb',
            'vc',
            '======= ccc',
            'ab',
            '>>>>>>> ddd',
            '>>>>>>> dd',
        }

        local parser = Parser:new({ markers = markers })

        parser:parse(input_lines)

        assert.is.same({}, parser.state)
        assert.is.same({}, parser.state_stack)
        assert.is.equal(0, parser.top_level)
        assert.is.equal(4, #parser.conflicts)

        assert.is.equal(3, parser.conflicts[1].start_line)
        assert.is.equal(5, parser.conflicts[1].common_line)
        assert.is.equal(7, parser.conflicts[1].sep_line)
        assert.is.equal(9, parser.conflicts[1].end_line)
        assert.is.equal(1, parser.conflicts[1].level)

        assert.is.equal(12, parser.conflicts[2].start_line)
        assert.is.equal(14, parser.conflicts[2].common_line)
        assert.is.equal(16, parser.conflicts[2].sep_line)
        assert.is.equal(18, parser.conflicts[2].end_line)
        assert.is.equal(1, parser.conflicts[2].level)

        assert.is.equal(21, parser.conflicts[3].start_line)
        assert.is.equal(23, parser.conflicts[3].common_line)
        assert.is.equal(25, parser.conflicts[3].sep_line)
        assert.is.equal(27, parser.conflicts[3].end_line)
        assert.is.equal(1, parser.conflicts[3].level)

        assert.is.equal(1, parser.conflicts[4].start_line)
        assert.is.equal(10, parser.conflicts[4].common_line)
        assert.is.equal(19, parser.conflicts[4].sep_line)
        assert.is.equal(28, parser.conflicts[4].end_line)
        assert.is.equal(0, parser.conflicts[4].level)
    end)

    describe('should not crash on malformed conflicts', function()
        local marker_types = {
            { name = 'start',  value = '<<<<<<<' },
            { name = 'common', value = '|||||||' },
            { name = 'sep',    value = '=======' },
            { name = 'end',    value = '>>>>>>>' },
        }
        local max_len = 4
        for iterator = 0, ((#marker_types) ^ max_len) - 1 do
            local picker = iterator
            local name = ''
            local picks = {}
            local input_lines = {}
            repeat
                local pick = picker % #marker_types
                table.insert(picks, pick)
                if #picks >= 3 and picks[#picks - 2] == 0 and picks[#picks - 1] == 2 and picks[#picks] == 3 then
                    goto continue
                elseif #picks >= 4 and picks[#picks - 3] == 0 and picks[#picks - 2] == 1 and picks[#picks - 1] == 2 and picks[#picks] == 3 then
                    goto continue
                end

                local marker = marker_types[pick + 1]
                picker = (picker - pick) / #marker_types

                table.insert(input_lines, marker.value)
                if #picks > 1 then
                    if picker == 0 then
                        name = name .. ' and '
                    else
                        name = name .. ', '
                    end
                end
                name = name .. marker.name
            until picker <= 0

            name = name .. ' conflict marker'
            if #input_lines == 1 then
                name = 'only ' .. name
            else
                name = name .. 's'
            end

            it(name, function()
                local parser = Parser:new({ markers = markers })

                local ok = pcall(Parser.parse, parser, input_lines)

                assert.is.True(ok)
                assert.is.equal(0, #parser.conflicts)
            end)

            ::continue::
        end
    end)
end)
