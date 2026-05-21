# window-groups.nvim

Window-scoped buffer groups for Neovim. Each split window maintains its own ordered list of buffers, rendered as a tab strip in the winbar. Buffers have single-membership — opening a buffer already owned by another window redirects focus there instead of duplicating it.

Think VS Code editor groups, not Vim tabpages.

## Requirements

- Neovim >= 0.10
- Optional: [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) or [mini.icons](https://github.com/echasnovski/mini.icons) for file icons in the winbar

## Installation

**lazy.nvim** (recommended)
```lua
{
  "merrebach/window-groups.nvim",
  config = function()
    require("window_groups").setup({})
  end,
}
```

**packer.nvim**
```lua
use {
  "merrebach/window-groups.nvim",
  config = function()
    require("window_groups").setup({})
  end,
}
```

**mini.deps**
```lua
MiniDeps.add("merrebach/window-groups.nvim")
require("window_groups").setup({})
```

**vim-plug**
```vim
Plug 'merrebach/window-groups.nvim'
" then in your init.lua or after plug#end():
lua require("window_groups").setup({})
```

## Setup

All options with their defaults:

```lua
require("window_groups").setup({
  -- Filetypes merged with built-in exclusions: neo-tree, snacks_dashboard, dashboard
  exclude_filetypes = {},

  -- Set to false if you manage vim.o.winbar yourself (heirline, lualine, etc.)
  winbar = true,

  -- Custom icon resolver. nil = auto-detect: nvim-web-devicons → mini.icons → plain text
  -- Signature: function(buf: integer) -> icon: string, hl_name: string|nil
  get_icon = nil,

  -- Override fallback highlight specs. Applied on top of colorscheme-defined values.
  highlights = {
    active   = {},
    current  = {},
    inactive = {},
    sep      = {},
    fill     = {},
  },

  -- Default keymaps. Pass false to disable all, or a table to replace entirely.
  -- See the Keymaps section for the full default set.
  keys = nil,  -- nil → register defaults
})
```

## Keymaps

Default keymaps registered by `setup()`:

| Key | Action |
|---|---|
| `<leader>q` | Close current buffer |
| `<leader>bq` | Close all buffers in current window's group |
| `]b` | Cycle to next buffer in group |
| `[b` | Cycle to previous buffer in group |
| `<leader>bmh` | Move buffer to left window |
| `<leader>bmj` | Move buffer to bottom window |
| `<leader>bmk` | Move buffer to top window |
| `<leader>bml` | Move buffer to right window |

**Disable all default keymaps:**
```lua
require("window_groups").setup({ keys = false })
```

**Replace with your own keymaps:**
```lua
require("window_groups").setup({
  keys = {
    { "<leader>x",  function() require("window_groups").close_buf() end,   desc = "Close buffer" },
    { "<leader>X",  function() require("window_groups").close_group() end, desc = "Close group" },
    { "<Tab>",      function() require("window_groups").cycle("next") end,  desc = "Next buffer" },
    { "<S-Tab>",    function() require("window_groups").cycle("prev") end,  desc = "Prev buffer" },
  },
})
```

**lazy.nvim: use the `keys` spec for lazy-loading** (advanced — not needed for most setups):
```lua
{
  "merrebach/window-groups.nvim",
  config = function()
    require("window_groups").setup({ keys = false })  -- don't register again inside setup
  end,
  keys = {
    { "<leader>q",  function() require("window_groups").close_buf() end,   desc = "Close buffer" },
    { "<leader>bq", function() require("window_groups").close_group() end, desc = "Close group" },
    { "]b",         function() require("window_groups").cycle("next") end,  desc = "Next buffer" },
    { "[b",         function() require("window_groups").cycle("prev") end,  desc = "Prev buffer" },
  },
}
```

> **Note:** lazy-loading window-groups is not recommended. The plugin must run at startup to seed the initial window group and set up the winbar.

## API

```lua
local wg = require("window_groups")

-- Buffer lifecycle
wg.close_buf()                      -- close current buffer, show neighbor; close window if group empty
wg.close_group()                    -- close all buffers in current window's group and close the window

-- Navigation
wg.cycle("next" | "prev")           -- cycle through buffers in current window's group

-- Layout
wg.move_buf("h" | "j" | "k" | "l") -- move current buffer to the neighbor window in that direction
wg.split("h" | "j" | "k" | "l")    -- open a split, carry current buffer into the new window

-- Introspection
wg.eligible(buf)                    -- bool: can this buffer join a group
wg.list(win)                        -- ordered buffer list for a window (integers)
wg.add(win, buf)                    -- add buffer to window's group
wg.remove(win, buf)                 -- remove buffer from window's group
```

## Highlights

Set any of these groups in your colorscheme. If a group is not defined, fallbacks are derived from `TabLine`, `TabLineSel`, and `Normal` at setup time and refreshed on `ColorScheme`.

| Group | Meaning |
|---|---|
| `GroupsActive` | Tab in the focused window, currently visible buffer |
| `GroupsCurrent` | Tab in an unfocused window, currently visible buffer |
| `GroupsInactive` | Tab whose buffer is not currently visible |
| `GroupsSep` | Separator `│` between tabs |
| `GroupsFill` | Winbar space after all tabs |

**Override a single key via setup:**
```lua
require("window_groups").setup({
  highlights = {
    active = { fg = "#d4c5a9", bold = true },  -- bold active tab, custom foreground
  },
})
```

**Override all groups at once:**
```lua
require("window_groups").setup({
  highlights = {
    active   = { fg = "#d4c5a9", bg = "#3d3d3d", bold = true },
    current  = { fg = "#9a9a8a", bg = "#2a2a2a" },
    inactive = { fg = "#5a5a4a", bg = "#2a2a2a" },
    sep      = { fg = "#3d3d3d", bg = "#2a2a2a" },
    fill     = { bg = "#2a2a2a" },
  },
})
```

**Define groups directly in your colorscheme** (takes precedence over setup overrides):
```lua
vim.api.nvim_set_hl(0, "GroupsActive",   { bg = "#3d3d3d", fg = "#d4c5a9", bold = true })
vim.api.nvim_set_hl(0, "GroupsCurrent",  { bg = "#2a2a2a", fg = "#9a9a8a" })
vim.api.nvim_set_hl(0, "GroupsInactive", { bg = "#2a2a2a", fg = "#5a5a4a" })
vim.api.nvim_set_hl(0, "GroupsSep",      { bg = "#2a2a2a", fg = "#3d3d3d" })
vim.api.nvim_set_hl(0, "GroupsFill",     { bg = "#2a2a2a" })
```

If you use [singularity.nvim](https://github.com/merrebach/singularity.nvim), all highlight groups are defined automatically when `integrations.window_groups = true` (default).

## Filetypes

Add filetypes that should not participate in groups. These are merged with the built-in exclusions (`neo-tree`, `snacks_dashboard`, `dashboard`):

```lua
require("window_groups").setup({
  exclude_filetypes = { "NvimTree", "Outline", "aerial", "toggleterm" },
})
```

Windows showing an excluded filetype get no winbar strip and their buffers are never added to any group.

## Icon providers

`get_icon` lets you supply your own resolver instead of the auto-detected one:

```lua
-- Always use a fixed icon regardless of filetype
require("window_groups").setup({
  get_icon = function(buf)
    return "•", nil  -- icon string, optional highlight name
  end,
})

-- Use nvim-web-devicons explicitly, ignoring mini.icons even if present
require("window_groups").setup({
  get_icon = function(buf)
    local ok, devicons = pcall(require, "nvim-web-devicons")
    if not ok then return "", nil end
    local name = vim.api.nvim_buf_get_name(buf)
    local icon, hl = devicons.get_icon(name, vim.fn.fnamemodify(name, ":e"), { default = true })
    return icon or "", hl
  end,
})
```

## Behaviour notes

- **Single-membership is per-tabpage.** A buffer can appear in different groups across tabpages. Within one tabpage it belongs to at most one group.
- **Winbar only appears on editor windows.** Floats, explorer sidebars, help, quickfix, and terminal windows render no winbar strip.
- **`setup()` is idempotent.** Calling it more than once is a no-op.
- **`move_buf` fails silently on non-editor neighbors.** If the neighbor window is a sidebar or float, a warning is shown and the buffer stays where it is.
- **`close_buf` on an ineligible buffer** (terminal, scratch) falls back to `:bdelete` — no group logic applies.
- **`split` with no eligible buffer** opens a blank scratch split with no group entry.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) and `CONTEXT.md` for the domain glossary.

```sh
make install-hooks   # install pre-commit lint hook
make lint            # run luacheck
make test            # run plenary tests (requires Neovim in PATH)
```

## License

MIT — see [LICENSE](LICENSE).
