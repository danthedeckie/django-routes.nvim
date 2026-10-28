local M = {}

function M.available()
    return pcall(require, 'snacks.picker')
end

function M.pick(routes, on_choose, picker_opts)
    require('snacks').picker.pick(vim.tbl_deep_extend('force', {
        title = 'Django Routes',
        items = routes,
        format = 'text',
        layout = { preset = 'select' },
        confirm = function(picker, item)
            picker:close()
            if item then
                -- Defer so the picker has handed focus back to the original window.
                vim.schedule(function() on_choose(item) end)
            end
        end,
    }, picker_opts or {}))
end

return M
