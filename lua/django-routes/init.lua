local routes = require('django-routes.routes')

local M = {}

-- Picker adapters tried in order when `picker` isn't configured.
local AUTO_DETECT_ORDER = { 'snacks', 'telescope', 'select' }

--- Default action: insert the route name at the cursor.
function M.insert_name(route)
    vim.api.nvim_put({ route.name }, 'c', false, true)
end

M.config = {
    cmd = { './manage.py', 'show_urls', '--skip-checks', '--format', 'json' },
    -- 'snacks' | 'telescope' | 'select' | function(routes, on_choose, picker_opts).
    -- nil means use the first one available.
    picker = nil,
    -- Passed through to the underlying picker (eg `{ layout = { preset = 'dropdown' } }`).
    picker_opts = {},
    on_choose = M.insert_name,
}

-- `cmd` is a list, so replace it rather than letting older nvims merge it by index.
local function merge_config(base, overrides)
    overrides = overrides or {}
    local merged = vim.tbl_deep_extend('force', base, overrides)
    merged.cmd = overrides.cmd or base.cmd
    return merged
end

function M.setup(opts)
    M.config = merge_config(M.config, opts)
end

local function load_adapter(name)
    local ok, adapter = pcall(require, 'django-routes.pickers.' .. name)
    if ok and adapter.available() then
        return adapter
    end
end

--- Returns a pick function, or nil plus an error message.
local function resolve_picker(picker)
    if type(picker) == 'function' then
        return picker
    end
    if picker then
        local adapter = load_adapter(picker)
        if not adapter then
            return nil, string.format("picker '%s' is unknown or not installed", picker)
        end
        return adapter.pick
    end
    for _, name in ipairs(AUTO_DETECT_ORDER) do
        local adapter = load_adapter(name)
        if adapter then
            return adapter.pick
        end
    end
end

--- Open a picker of the project's named Django routes. `opts` overrides `M.config` for this call.
function M.pick(opts)
    local config = merge_config(M.config, opts)
    local pick, err = resolve_picker(config.picker)
    if not pick then
        vim.notify('django-routes: ' .. err, vim.log.levels.ERROR)
        return
    end
    routes.fetch(config.cmd, function(route_list)
        if #route_list == 0 then
            vim.notify('django-routes: no named routes found', vim.log.levels.WARN)
            return
        end
        pick(route_list, config.on_choose, config.picker_opts)
    end)
end

return M
