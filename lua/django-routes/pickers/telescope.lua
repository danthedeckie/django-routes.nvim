local M = {}

function M.available()
    return pcall(require, 'telescope')
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
