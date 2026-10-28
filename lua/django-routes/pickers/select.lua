-- Fallback using `vim.ui.select`, so it works with whatever (if anything) overrides that.
local M = {}

function M.available()
    return true
end

function M.pick(routes, on_choose, picker_opts)
    local select_opts = vim.tbl_extend('force', {
        prompt = 'Django Routes',
        format_item = function(route) return route.text end,
    }, picker_opts or {})
    vim.ui.select(routes, select_opts, function(route)
        if route then
            on_choose(route)
        end
    end)
end

return M
