vim.api.nvim_create_user_command(
    'ConflictSqueezer',
    function()
        require('conflict-squeezer').squeeze_conflicts()
    end,
    { nargs = 0, desc = 'Resolves common parts of a conflict block in the current buffer' }
)
