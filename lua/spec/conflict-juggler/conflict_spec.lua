local Conflict = require('conflict-juggler.conflict')

describe('simplify conflicts', function()
    it('should simplify identical zero line block with common line', function()
        local conflict_lines = {
            '<<<<<<< a',
            '||||||| b',
            'common text',
            '======= c',
            '>>>>>>> d',
        }
        local expected_lines = {}

        local conflict = Conflict:new({
            level = 0,
            start_line = 1,
            common_line = 2,
            sep_line = 4,
            end_line = 5,
        })

        conflict:simplify(conflict_lines)

        assert.same(expected_lines, conflict_lines)
    end)
    it(
        'should simplify identical zero line block without common line',
        function()
            local conflict_lines = {
                '<<<<<<< a',
                '======= c',
                '>>>>>>> d',
            }
            local expected_lines = {}

            local conflict = Conflict:new({
                level = 0,
                start_line = 1,
                common_line = nil,
                sep_line = 2,
                end_line = 3,
            })

            conflict:simplify(conflict_lines)

            assert.same(expected_lines, conflict_lines)
        end
    )
    it('should simplify identical one line block with common line', function()
        local conflict_lines = {
            '<<<<<<< a',
            'sample text',
            '||||||| b',
            'common text',
            '======= c',
            'sample text',
            '>>>>>>> d',
        }
        local expected_lines = {
            'sample text',
        }

        local conflict = Conflict:new({
            level = 0,
            start_line = 1,
            common_line = 3,
            sep_line = 5,
            end_line = 7,
        })

        conflict:simplify(conflict_lines)

        assert.same(expected_lines, conflict_lines)
    end)
    it(
        'should simplify identical one line block without common line',
        function()
            local conflict_lines = {
                '<<<<<<< a',
                'sample text',
                '======= c',
                'sample text',
                '>>>>>>> d',
            }
            local expected_lines = {
                'sample text',
            }

            local conflict = Conflict:new({
                level = 0,
                start_line = 1,
                common_line = nil,
                sep_line = 3,
                end_line = 5,
            })

            conflict:simplify(conflict_lines)

            assert.same(expected_lines, conflict_lines)
        end
    )
    it(
        'should simplify prefix with same length block with common line',
        function()
            local conflict_lines = {
                '<<<<<<< a',
                'sample text',
                'conflict a',
                '||||||| c',
                'common text',
                'conflict text',
                '======= d',
                'sample text',
                'conflict b',
                '>>>>>>> e',
            }
            local expected_lines = {
                'sample text',
                '<<<<<<< a',
                'conflict a',
                '||||||| c',
                'common text',
                'conflict text',
                '======= d',
                'conflict b',
                '>>>>>>> e',
            }

            local conflict = Conflict:new({
                level = 0,
                start_line = 1,
                common_line = 4,
                sep_line = 7,
                end_line = 10,
            })

            conflict:simplify(conflict_lines)

            assert.same(expected_lines, conflict_lines)
        end
    )
    it(
        'should simplify prefix with same length block without common line',
        function()
            local conflict_lines = {
                '<<<<<<< a',
                'sample text',
                'conflict a',
                '======= c',
                'sample text',
                'conflict b',
                '>>>>>>> d',
            }
            local expected_lines = {
                'sample text',
                '<<<<<<< a',
                'conflict a',
                '======= c',
                'conflict b',
                '>>>>>>> d',
            }

            local conflict = Conflict:new({
                level = 0,
                start_line = 1,
                common_line = nil,
                sep_line = 4,
                end_line = 7,
            })

            conflict:simplify(conflict_lines)

            assert.same(expected_lines, conflict_lines)
        end
    )
    it(
        'should simplify suffix with same length block with common line',
        function()
            local conflict_lines = {
                '<<<<<<< a',
                'conflict a',
                'sample text',
                '||||||| c',
                'conflict text',
                'common text',
                '======= d',
                'conflict b',
                'sample text',
                '>>>>>>> e',
            }
            local expected_lines = {
                '<<<<<<< a',
                'conflict a',
                '||||||| c',
                'conflict text',
                'common text',
                '======= d',
                'conflict b',
                '>>>>>>> e',
                'sample text',
            }

            local conflict = Conflict:new({
                level = 0,
                start_line = 1,
                common_line = 4,
                sep_line = 7,
                end_line = 10,
            })

            conflict:simplify(conflict_lines)

            assert.same(expected_lines, conflict_lines)
        end
    )
    it(
        'should simplify suffix with same length block without common line',
        function()
            local conflict_lines = {
                '<<<<<<< a',
                'conflict a',
                'sample text',
                '======= c',
                'conflict b',
                'sample text',
                '>>>>>>> d',
            }
            local expected_lines = {
                '<<<<<<< a',
                'conflict a',
                '======= c',
                'conflict b',
                '>>>>>>> d',
                'sample text',
            }

            local conflict = Conflict:new({
                level = 0,
                start_line = 1,
                common_line = nil,
                sep_line = 4,
                end_line = 7,
            })

            conflict:simplify(conflict_lines)

            assert.same(expected_lines, conflict_lines)
        end
    )
    it(
        'should simplify prefix with larger left block with common line',
        function()
            local conflict_lines = {
                '<<<<<<< a',
                'sample text',
                'conflict a',
                'conflict a',
                '||||||| c',
                'common text',
                'conflict text',
                '======= d',
                'sample text',
                'conflict b',
                '>>>>>>> e',
            }
            local expected_lines = {
                'sample text',
                '<<<<<<< a',
                'conflict a',
                'conflict a',
                '||||||| c',
                'common text',
                'conflict text',
                '======= d',
                'conflict b',
                '>>>>>>> e',
            }

            local conflict = Conflict:new({
                level = 0,
                start_line = 1,
                common_line = 5,
                sep_line = 8,
                end_line = 11,
            })

            conflict:simplify(conflict_lines)

            assert.same(expected_lines, conflict_lines)
        end
    )
    it(
        'should simplify prefix with larger left block without common line',
        function()
            local conflict_lines = {
                '<<<<<<< a',
                'sample text',
                'conflict a',
                'conflict a',
                '======= c',
                'sample text',
                'conflict b',
                '>>>>>>> d',
            }
            local expected_lines = {
                'sample text',
                '<<<<<<< a',
                'conflict a',
                'conflict a',
                '======= c',
                'conflict b',
                '>>>>>>> d',
            }

            local conflict = Conflict:new({
                level = 0,
                start_line = 1,
                common_line = nil,
                sep_line = 5,
                end_line = 8,
            })

            conflict:simplify(conflict_lines)

            assert.same(expected_lines, conflict_lines)
        end
    )
    it(
        'should simplify suffix with larger left block with common line',
        function()
            local conflict_lines = {
                '<<<<<<< a',
                'conflict a',
                'conflict a',
                'sample text',
                '||||||| c',
                'common text',
                'conflict text',
                '======= d',
                'conflict b',
                'sample text',
                '>>>>>>> e',
            }
            local expected_lines = {
                '<<<<<<< a',
                'conflict a',
                'conflict a',
                '||||||| c',
                'common text',
                'conflict text',
                '======= d',
                'conflict b',
                '>>>>>>> e',
                'sample text',
            }

            local conflict = Conflict:new({
                level = 0,
                start_line = 1,
                common_line = 5,
                sep_line = 8,
                end_line = 11,
            })

            conflict:simplify(conflict_lines)

            assert.same(expected_lines, conflict_lines)
        end
    )
    it(
        'should simplify suffix with larger left block without common line',
        function()
            local conflict_lines = {
                '<<<<<<< a',
                'conflict a',
                'conflict a',
                'sample text',
                '======= c',
                'conflict b',
                'sample text',
                '>>>>>>> d',
            }
            local expected_lines = {
                '<<<<<<< a',
                'conflict a',
                'conflict a',
                '======= c',
                'conflict b',
                '>>>>>>> d',
                'sample text',
            }

            local conflict = Conflict:new({
                level = 0,
                start_line = 1,
                common_line = nil,
                sep_line = 5,
                end_line = 8,
            })

            conflict:simplify(conflict_lines)

            assert.same(expected_lines, conflict_lines)
        end
    )
    it(
        'should simplify prefix with larger right block with common line',
        function()
            local conflict_lines = {
                '<<<<<<< a',
                'sample text',
                'conflict a',
                '||||||| c',
                'common text',
                'conflict text',
                '======= d',
                'sample text',
                'conflict b',
                'conflict b',
                '>>>>>>> e',
            }
            local expected_lines = {
                'sample text',
                '<<<<<<< a',
                'conflict a',
                '||||||| c',
                'common text',
                'conflict text',
                '======= d',
                'conflict b',
                'conflict b',
                '>>>>>>> e',
            }

            local conflict = Conflict:new({
                level = 0,
                start_line = 1,
                common_line = 4,
                sep_line = 7,
                end_line = 11,
            })

            conflict:simplify(conflict_lines)

            assert.same(expected_lines, conflict_lines)
        end
    )
    it(
        'should simplify prefix with larger right block without common line',
        function()
            local conflict_lines = {
                '<<<<<<< a',
                'sample text',
                'conflict a',
                '======= c',
                'sample text',
                'conflict b',
                'conflict b',
                '>>>>>>> d',
            }
            local expected_lines = {
                'sample text',
                '<<<<<<< a',
                'conflict a',
                '======= c',
                'conflict b',
                'conflict b',
                '>>>>>>> d',
            }

            local conflict = Conflict:new({
                level = 0,
                start_line = 1,
                common_line = nil,
                sep_line = 4,
                end_line = 8,
            })

            conflict:simplify(conflict_lines)

            assert.same(expected_lines, conflict_lines)
        end
    )
    it(
        'should simplify suffix with larger right block with common line',
        function()
            local conflict_lines = {
                '<<<<<<< a',
                'conflict a',
                'sample text',
                '||||||| c',
                'common text',
                'conflict text',
                '======= d',
                'conflict b',
                'conflict b',
                'sample text',
                '>>>>>>> e',
            }
            local expected_lines = {
                '<<<<<<< a',
                'conflict a',
                '||||||| c',
                'common text',
                'conflict text',
                '======= d',
                'conflict b',
                'conflict b',
                '>>>>>>> e',
                'sample text',
            }

            local conflict = Conflict:new({
                level = 0,
                start_line = 1,
                common_line = 4,
                sep_line = 7,
                end_line = 11,
            })

            conflict:simplify(conflict_lines)

            assert.same(expected_lines, conflict_lines)
        end
    )
    it(
        'should simplify suffix with larger right block without common line',
        function()
            local conflict_lines = {
                '<<<<<<< a',
                'conflict a',
                'sample text',
                '======= c',
                'conflict b',
                'conflict b',
                'sample text',
                '>>>>>>> d',
            }
            local expected_lines = {
                '<<<<<<< a',
                'conflict a',
                '======= c',
                'conflict b',
                'conflict b',
                '>>>>>>> d',
                'sample text',
            }

            local conflict = Conflict:new({
                level = 0,
                start_line = 1,
                common_line = nil,
                sep_line = 4,
                end_line = 8,
            })

            conflict:simplify(conflict_lines)

            assert.same(expected_lines, conflict_lines)
        end
    )
end)
