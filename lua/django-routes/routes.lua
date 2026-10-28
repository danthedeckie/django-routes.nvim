-- Fetching and parsing routes from django-extensions' `show_urls --format json`.
local M = {}

-- Cap the padding so one very long URL doesn't push every row's view/name columns right.
local MAX_URL_PADDING = 60

local function add_display_text(routes)
    local url_width = 0
    for _, route in ipairs(routes) do
        url_width = math.max(url_width, #route.url)
    end
    local row_format = '%-' .. math.min(url_width, MAX_URL_PADDING) .. 's  %s  %s'

    for _, route in ipairs(routes) do
        route.text = string.format(row_format, route.url, route.view, route.name)
    end
end

--- Parse `show_urls --format json` output into a list of routes, each with `url`, `view`,
--- `name` and an aligned `text` for display / fuzzy matching.
--- Unnamed routes are dropped, as they can't be used with `reverse()` / `{% url %}`.
function M.parse(output)
    local routes = {}
    for _, entry in ipairs(vim.json.decode(output)) do
        if entry.name and entry.name ~= '' then
            table.insert(routes, { url = entry.url, view = entry.module, name = entry.name })
        end
    end
    add_display_text(routes)
    return routes
end

local function notify_error(message)
    vim.notify('django-routes: ' .. message, vim.log.levels.ERROR)
end

local function command_failure_message(result)
    local output = vim.trim(result.stderr or '')
    if output == '' then
        output = vim.trim(result.stdout or '')
    end
    return 'command exited with code ' .. result.code .. '\n' .. output
end

local function handle_result(result, callback)
    if result.code ~= 0 then
        notify_error(command_failure_message(result))
        return
    end
    local ok, routes = pcall(M.parse, result.stdout or '')
    if not ok then
        notify_error('could not parse show_urls output: ' .. tostring(routes))
        return
    end
    callback(routes)
end

--- Run `cmd` asynchronously from the Django project root (nearest `manage.py` above the current
--- buffer, else cwd) and call `callback(routes)` on the main loop when done.
function M.fetch(cmd, callback)
    local cwd = vim.fs.root(0, 'manage.py') or vim.fn.getcwd()
    local ok, err = pcall(vim.system, cmd, { text = true, cwd = cwd }, function(result)
        vim.schedule(function() handle_result(result, callback) end)
    end)
    if not ok then
        notify_error(tostring(err))
    end
end

return M
