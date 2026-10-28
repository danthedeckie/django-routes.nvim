vim.api.nvim_create_user_command('DjangoRoutes', function(command)
    local picker = command.args ~= '' and command.args or nil
    require('django-routes').pick({ picker = picker })
end, {
    nargs = '?',
    complete = function() return { 'snacks', 'telescope', 'select' } end,
    desc = 'Pick a Django route and insert its name',
})

vim.api.nvim_create_user_command('DjangoRoutesAuto', function(command)
    local django_routes = require('django-routes')
    local picker = command.args ~= '' and command.args or nil
    django_routes.pick({ picker = picker, on_choose = django_routes.insert_for_filetype })
end, {
    nargs = '?',
    complete = function() return { 'snacks', 'telescope', 'select' } end,
    desc = 'Pick a Django route and insert it as reverse() / {% url %} for the filetype',
})
