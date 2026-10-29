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
    version = '*', -- latest tagged release; use `version = false` to track main
    opts = {
        picker = 'snacks', -- optional
        picker_opts = { layout = { preset = 'dropdown' } }, -- optional, passed to the picker
    },
    cmd = { 'DjangoRoutes', 'DjangoRoutesAuto' },
    keys = {
        { '<leader>dr', '<cmd>DjangoRoutes<cr>', desc = 'Django routes' },
        { '<leader>dR', '<cmd>DjangoRoutesAuto<cr>', desc = 'Django routes (reverse / url tag)' },
    },
}
```

## Commands

- `:DjangoRoutes [picker]` - inserts the bare route name, eg `admin:index`.
- `:DjangoRoutesAuto [picker]` - inserts the route wrapped to suit the current filetype:

  | Filetype             | Inserted                    |
  | -------------------- | --------------------------- |
  | `python`             | `reverse("admin:index")`    |
  | `htmldjango`, `html` | `{% url 'admin:index' %}`   |
  | anything else        | `admin:index`               |

  If you've already typed the opening quote of a call's first argument or a template tag - eg
  `reverse("`, `redirect('`, `{% url '` - it inserts just the name, so you don't get
  `reverse("reverse("..."))`. This works with the cursor on either quote of `""`, or on a lone
  opening quote. It doesn't add the `reverse` import - leave that to your LSP / ruff.

Both commands normally insert before the cursor (like `P`). But if the cursor is on the first
character of an empty pair - `""`, `''`, `()`, `[]`, `{}` or `><` - they insert inside it. With
`:DjangoRoutesAuto`, `redirect()` → `redirect(reverse("admin:index"))` and `<a href="">` →
`<a href="{% url ... %}">`.

`[picker]` is optional: `snacks`, `telescope` or `select`.

To use the filetype-aware insert from Lua, pass it as `on_choose`:

```lua
require('django-routes').pick({ on_choose = require('django-routes').insert_for_filetype })
```

## Options

| Option        | Default                                                    |
| ------------- | ---------------------------------------------------------- |
| `cmd`         | `{ './manage.py', 'show_urls', '--skip-checks', '--format', 'json' }` |
| `picker`      | `nil` (auto) - `'snacks'`, `'telescope'`, `'select'`, or `function(routes, on_choose, picker_opts)` |
| `picker_opts` | `{}`                                                       |
| `on_choose`   | inserts `route.name` at the cursor; receives `{ url, view, name, text }` |
| `wrappers`    | see below                                                  |

`wrappers` sets what `:DjangoRoutesAuto` inserts per filetype; `{name}` is replaced with the route
name. Your table is merged with the defaults, so you only need to list changes. Set a filetype to
`false` to insert the bare name for it. Unlike the other options, it's only read from `setup()` /
`opts`, not per-call:

```lua
opts = {
    wrappers = {
        python = 'reverse_lazy("{name}")',  -- default: 'reverse("{name}")'
        jinja = "{{ url('{name}') }}",      -- add a filetype
        html = false,                       -- bare name in plain html
    },
}
```

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
