local routes_lib = require('django-routes.routes')

local M = {}

function M.available()
    return pcall(require, 'telescope')
end

local function route_previewer()
    return require('telescope.previewers').new_buffer_previewer({
        title = 'Route',
        define_preview = function(self, entry)
            local lines = vim.split(routes_lib.describe(entry.value), '\n')
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        end,
    })
end

function M.pick(routes, on_choose, picker_opts)
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    local finders = require('telescope.finders')
    local pickers = require('telescope.pickers')
    local conf = require('telescope.config').values

    picker_opts = picker_opts or {}
    pickers.new(picker_opts, {
        prompt_title = 'Django Routes',
        finder = finders.new_table({
            results = routes,
            entry_maker = function(route)
                return { value = route, display = route.text, ordinal = route.text }
            end,
        }),
        sorter = conf.generic_sorter(picker_opts),
        previewer = route_previewer(),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                if selection then
                    on_choose(selection.value)
                end
            end)
            return true
        end,
    }):find()
end

return M
