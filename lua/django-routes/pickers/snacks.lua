local routes_lib = require('django-routes.routes')

local M = {}

function M.available()
    return pcall(require, 'snacks.picker')
end

-- Routes have no file, so give layouts that include a preview window something useful to show.
local function with_preview(route)
    local preview = { text = routes_lib.describe(route), loc = false }
    return vim.tbl_extend('force', route, { preview = preview })
end

function M.pick(routes, on_choose, picker_opts)
    require('snacks').picker.pick(vim.tbl_deep_extend('force', {
        title = 'Django Routes',
        items = vim.tbl_map(with_preview, routes),
        format = 'text',
        preview = 'preview',
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
