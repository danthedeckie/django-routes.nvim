# django-routes.nvim

Neovim picker for a Django project's named URL routes. Pick one and its name (eg `admin:index`)
is inserted at the cursor - handy for `reverse()` and `{% url %}`.

Routes come from `./manage.py show_urls`
([django-extensions](https://django-extensions.readthedocs.io/)), run from the nearest directory
containing `manage.py` (falling back to the cwd). Unnamed routes are skipped.

## Pickers

Works with [snacks.nvim](https://github.com/folke/snacks.nvim) picker,
[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim), or plain `vim.ui.select`.
By default it uses the first of those that's available.

## Install (lazy.nvim)

```lua
{
    'danthedeckie/django-routes.nvim',
    opts = {
        picker = 'snacks', -- optional
        picker_opts = { layout = { preset = 'dropdown' } }, -- optional, passed to the picker
    },
    cmd = 'DjangoRoutes',
    keys = {
        { '<leader>dr', function() require('django-routes').pick() end, desc = 'Django routes' },
    },
}
```

Or run `:DjangoRoutes [snacks|telescope|select]`.

## Options

| Option        | Default                                                    |
| ------------- | ---------------------------------------------------------- |
| `cmd`         | `{ './manage.py', 'show_urls', '--skip-checks', '--format', 'json' }` |
| `picker`      | `nil` (auto) - `'snacks'`, `'telescope'`, `'select'`, or `function(routes, on_choose, picker_opts)` |
| `picker_opts` | `{}`                                                       |
| `on_choose`   | inserts `route.name` at the cursor; receives `{ url, view, name, text }` |

If your venv isn't activated in nvim, set `cmd` to eg
`{ 'uv', 'run', 'manage.py', 'show_urls', '--skip-checks', '--format', 'json' }`.
It must output `show_urls`' JSON format.

Any option can also be passed per-call: `require('django-routes').pick({ on_choose = ... })`.

## License

[0BSD](LICENSE)

## AI / LLM Disclaimer

This is based on some scrappy hacky ancient hand-written code from my init.lua,
and then asking Claude to turn it into a separate plugin.

It works well enough for my use, but I'm not massively interested in adding loads of features
or spending loads of time on this.

Feel 100% free to take this base and turn it into something better or cooler.
