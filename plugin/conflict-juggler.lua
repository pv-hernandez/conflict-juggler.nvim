vim.api.nvim_create_user_command('ConflictJuggler', function(args)
    local line1 = args.line1
    local line2 = args.line2
    require('conflict-juggler').simplify_conflicts(line1, line2)
end, {
    nargs = 0,
    range = '%',
    desc = 'Resolves common parts of a conflict block in the current buffer',
})
