local routes = require('django-routes.routes')

local M = {}

-- Picker adapters tried in order when `picker` isn't configured.
local AUTO_DETECT_ORDER = { 'snacks', 'telescope', 'select' }

-- Text ending in the opening quote of the first string argument of any call (eg `reverse("`,
-- `redirect('`) or of a template tag (eg `{% url '`), where the bare name belongs.
local OPENING_QUOTE_PATTERNS = { '%(%s*[\'"]$', '{%%[^}\'"]*[\'"]$' }

-- With the cursor on the first character of one of these, text goes inside rather than before.
local EMPTY_PAIRS = {
    ['""'] = true, ["''"] = true, ['()'] = true, ['[]'] = true, ['{}'] = true, ['><'] = true,
}

local function ends_with_opening_quote(text)
    for _, pattern in ipairs(OPENING_QUOTE_PATTERNS) do
        if text:find(pattern) then
            return true
        end
    end
    return false
end

--- Returns `inside_string, insert_after` for the cursor position. In normal mode the cursor is
--- usually *on* the opening character just typed (`reverse(|"")`, `redirect|()`, `>|<`), so text
--- must go after it.
local function insert_position()
    local column = vim.api.nvim_win_get_cursor(0)[2]
    local line = vim.api.nvim_get_current_line()
    local on_empty_pair = EMPTY_PAIRS[line:sub(column + 1, column + 2)] ~= nil
    local insert_after = on_empty_pair or ends_with_opening_quote(line:sub(1, column + 1))
    local text_before = line:sub(1, insert_after and column + 1 or column)
    return ends_with_opening_quote(text_before), insert_after
end

local function put_text(text, insert_after)
    vim.api.nvim_put({ text }, 'c', insert_after, true)
end

--- Default action: insert the route name at the cursor (inside an empty pair, eg `""` or `()`,
--- if the cursor is on its opening character).
function M.insert_name(route)
    local _, insert_after = insert_position()
    put_text(route.name, insert_after)
end

--- Insert the route wrapped for the current filetype (eg `reverse("name")` in python), using
--- `config.wrappers`. Inserts the bare name for other filetypes, or if already inside a call/tag.
function M.insert_for_filetype(route)
    local wrapper = M.config.wrappers[vim.bo.filetype]
    local inside_string, insert_after = insert_position()
    if not wrapper or inside_string then
        return put_text(route.name, insert_after)
    end
    put_text((wrapper:gsub('{name}', function() return route.name end)), insert_after)
end

M.config = {
    cmd = { './manage.py', 'show_urls', '--skip-checks', '--format', 'json' },
    -- 'snacks' | 'telescope' | 'select' | function(routes, on_choose, picker_opts).
    -- nil means use the first one available.
    picker = nil,
    -- Passed through to the underlying picker (eg `{ layout = { preset = 'dropdown' } }`).
    picker_opts = {},
    on_choose = M.insert_name,
    -- Used by `insert_for_filetype` (set via `setup()` only). `{name}` is the route name.
    wrappers = {
        python = 'reverse("{name}")',
        htmldjango = "{% url '{name}' %}",
        html = "{% url '{name}' %}",
    },
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

-- Pickers can leave the cursor shifted (eg leaving their insert-mode prompt moves it left one),
-- so put it back where it was when the picker opened before running `on_choose`.
local function restoring_cursor(on_choose)
    local window = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(window)
    return function(route)
        if vim.api.nvim_win_is_valid(window) then
            vim.api.nvim_set_current_win(window)
            vim.api.nvim_win_set_cursor(window, cursor)
        end
        on_choose(route)
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
    local on_choose = restoring_cursor(config.on_choose)
    routes.fetch(config.cmd, function(route_list)
        if #route_list == 0 then
            vim.notify('django-routes: no named routes found', vim.log.levels.WARN)
            return
        end
        pick(route_list, on_choose, config.picker_opts)
    end)
end

return M
