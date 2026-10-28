vim.api.nvim_create_user_command('DjangoRoutes', function(command)
    local picker = command.args ~= '' and command.args or nil
    require('django-routes').pick({ picker = picker })
end, {
    nargs = '?',
    complete = function() return { 'snacks', 'telescope', 'select' } end,
    desc = 'Pick a Django route and insert its name',
})
