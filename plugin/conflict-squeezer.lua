vim.api.create_user_command(
    'ConflictSqueezer',
    function()
        require('conflict-squeeser').squeeze_conflicts()
    end,
    { nargs = 0, desc = 'Resolves common parts of a conflict block in the current buffer' }
)
