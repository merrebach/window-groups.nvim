# window-groups.nvim

Window-scoped buffer groups for Neovim. Each split window maintains its own
ordered list of buffers, rendered as a tab strip in the winbar. Buffers have
single-membership — opening a buffer already owned by another window redirects
focus there instead of duplicating it.

Think VS Code editor groups, not Vim tabpages.

## Requirements

- Neovim >= 0.10
- Optional: [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons)
  or [mini.icons](https://github.com/echasnovski/mini.icons) for file icons in
  the winbar

## Installation

**lazy.nvim** (recommended)

```lua
{
  "merrebach/window-groups.nvim",
  lazy = false, -- required for session autoload, see "Sessions → Loading order"
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

  -- Set to false to disable the group boundary accent and WinSeparator styling.
  border = true,

  -- Character rendered at the left edge of each winbar to signal a group boundary.
  border_char = "▎",

  -- Custom icon resolver. nil = auto-detect: nvim-web-devicons → mini.icons → plain text
  -- Signature: function(buf: integer) -> icon: string, hl_name: string|nil
  get_icon = nil,

  -- Override fallback highlight specs. Applied on top of colorscheme-defined values.
  highlights = {
    active          = {},   -- focused window's tab in the tabline
    current         = {},   -- active buffer in an unfocused window's tab
    inactive        = {},   -- unfocused window's tab in the tabline
    sep             = {},   -- separator between tabs
    fill            = {},   -- empty space to the right of all tabs
    accent_active   = {},   -- border_char in the focused window
    accent_inactive = {},   -- border_char in unfocused windows
    winsep_active   = {},   -- WinSeparator for the focused window
    winsep_inactive = {},   -- WinSeparator for unfocused windows
  },

  -- Session persistence. See the Sessions section.
  session = {
    -- Built-in per-cwd sessions: save on exit, restore on a bare `nvim` start.
    -- One switch for both directions. Off by default.
    autosave = false,
    -- Where built-in sessions are stored (one file per working directory).
    dir = vim.fn.stdpath("state") .. "/window-groups/sessions",
    -- 'sessionoptions' used for built-in sessions. Your own value is untouched.
    options = "buffers,curdir,folds,tabpages,winsize",
    -- Drop files from groups that no longer exist when a session is restored.
    skip_missing = true,
  },

  -- Default keymaps. Pass false to disable all, or a table to replace entirely.
  -- See the Keymaps section for the full default set.
  keys = nil,  -- nil → register defaults
})
```

## Keymaps

Default keymaps registered by `setup()`:

| Key           | Action                                      |
| ------------- | ------------------------------------------- |
| `<leader>q`   | Close current buffer                        |
| `<leader>bq`  | Close all buffers in current window's group |
| `]b`          | Cycle to next buffer in group               |
| `[b`          | Cycle to previous buffer in group           |
| `<leader>bmh` | Move buffer to left window                  |
| `<leader>bmj` | Move buffer to bottom window                |
| `<leader>bmk` | Move buffer to top window                   |
| `<leader>bml` | Move buffer to right window                 |

**Disable all default keymaps:**

```lua
require("window_groups").setup({ keys = false })
```

**Replace with your own keymaps:**

```lua
require("window_groups").setup({
  keys = {
    { "<leader>x",   function() require("window_groups").close_buf() end,          desc = "Close buffer" },
    { "<leader>X",   function() require("window_groups").close_group() end,        desc = "Close group" },
    { "<Tab>",       function() require("window_groups").cycle("next") end,         desc = "Next buffer" },
    { "<S-Tab>",     function() require("window_groups").cycle("prev") end,         desc = "Prev buffer" },
    { "<leader>bmh", function() require("window_groups").move_buf("left") end,     desc = "Move buf left" },
    { "<leader>bml", function() require("window_groups").move_buf("right") end,    desc = "Move buf right" },
    { "<leader>bmk", function() require("window_groups").move_buf("up") end,       desc = "Move buf up" },
    { "<leader>bmj", function() require("window_groups").move_buf("down") end,     desc = "Move buf down" },
  },
})
```

**lazy.nvim: use the `keys` spec for lazy-loading** (advanced — not needed for
most setups):

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

> **Note:** lazy-loading window-groups is not recommended. The plugin must run
> at startup to seed the initial window group and set up the winbar. With
> `session.autosave = true`, a `keys`-triggered plugin also never restores your
> session on startup — see [Loading order](#loading-order-and-lazy-loading).

## API

```lua
local wg = require("window_groups")

-- Buffer lifecycle
wg.close_buf()                      -- close current buffer, show neighbor; close window if group empty
wg.close_group()                    -- close all buffers in current window's group and close the window

-- Navigation
wg.cycle("next" | "prev")           -- cycle through buffers in current window's group

-- Layout
wg.move_buf("left" | "right" | "up" | "down") -- move current buffer to the neighbor window in that direction
wg.split("left" | "right" | "up" | "down")    -- open a split, carry current buffer into the new window

-- Sessions
local session = require("window_groups.session")
session.save()                      -- save the session of the cwd (same as :WindowGroupsSession save)
session.load()                      -- load the session of the cwd
session.delete()                    -- delete the session of the cwd
session.path()                      -- path of the session file for the cwd

-- Introspection
wg.eligible(buf)                    -- bool: can this buffer join a group
wg.list(win)                        -- ordered buffer list for a window (integers)
wg.add(win, buf)                    -- add buffer to window's group
wg.remove(win, buf)                 -- remove buffer from window's group
```

## Sessions

Vim's `:mksession` restores windows, tabpages and buffers, but not the groups
this plugin keeps per window. window-groups.nvim closes that gap natively,
without depending on any session plugin. There are two layers:

1. **Groups travel with every `:mksession`** — always on, nothing to configure.
2. **Built-in session management** — optional, enabled with
   `session.autosave = true`.

### Groups in any session file

Whenever a session file is written with `:mksession`, the plugin appends one
line carrying the groups of every window to that same file. Sourcing the file
restores the layout first and then the groups. This works with:

- plain `:mksession` / `:source`
- session managers built on `:mksession`, e.g. persistence.nvim, auto-session,
  mini.sessions

No extra files are created. If the plugin is not installed when a session is
sourced, the appended line is skipped silently and the session still loads.
Sessions saved before this feature existed load fine too: each window then
starts with a group containing the buffer it shows.

Details worth knowing:

- Files are stored by absolute path. With `skip_missing = true` (default),
  files deleted since the session was saved are dropped from their group.
- Restored buffers stay unloaded until you switch to them, so large groups
  restore quickly.
- If `'sessionoptions'` lacks `tabpages`, only the current tabpage's groups are
  stored — just like `:mksession` itself.

### Built-in session management

With `session.autosave = true` the plugin manages one session per working
directory:

- **On exit** (`VimLeavePre`) it saves the session to
  `session.dir/<encoded cwd>.vim`. If no window shows a file, nothing is
  written, so an empty editor never overwrites a good session.
- **On startup** it restores the session of the cwd, but only when *all* of
  these hold:
  - `nvim` was started without file arguments (`nvim`, not `nvim foo.lua`)
  - nothing is piped via stdin
  - a UI is attached (not `--headless`)
  - no file has been opened yet
  - a session for the cwd exists

Saving and restoring share one switch on purpose: neither is useful alone.

```lua
require("window_groups").setup({
  session = { autosave = true },
})
```

### Loading order and lazy-loading

> **Important:** automatic restore runs on `VimEnter`. **The plugin must be
> loaded — and `setup()` called — during startup**, or there is nothing left to
> trigger it.

| How the plugin is loaded                       | Autoload on startup |
| ---------------------------------------------- | ------------------- |
| `lazy = false` / plain `setup()` in `init.lua` | ✅ works            |
| lazy.nvim `event = "VeryLazy"`                 | ✅ works (see below) |
| lazy.nvim `keys`, `cmd` or `ft` triggers       | ❌ never restores   |

- **Recommended:** load eagerly. With lazy.nvim, set `lazy = false` (as in the
  Installation snippet). Make sure this is not overridden by
  `defaults = { lazy = true }` in your lazy.nvim config.
- **`VeryLazy` works:** when `setup()` runs after startup has finished, it
  detects this (`v:vim_did_enter`) and restores immediately instead of waiting
  for `VimEnter`. The restore still only happens if the conditions above hold,
  e.g. no file has been opened in the meantime.
- **`keys` / `cmd` / `ft` do not work:** the plugin only loads once you press a
  key, run a command or open a file type — by then you are already editing and
  the restore conditions no longer hold. Saving on exit still works in that
  case, restoring does not.
- **Dashboards:** a start screen (snacks.nvim dashboard, alpha, …) does not
  count as "a file has been opened", so it does not prevent the restore.

To check what happens in your setup, start `nvim` in a project with a saved
session and run `:WindowGroupsSession load` manually — if that restores the
groups but startup does not, the plugin is loaded too late.

### Commands

`:WindowGroupsSession {subcommand}` works regardless of `autosave`, so you can
try sessions before turning on automation:

| Command                       | Action                                   |
| ----------------------------- | ---------------------------------------- |
| `:WindowGroupsSession save`   | Save the session of the current cwd      |
| `:WindowGroupsSession load`   | Load the session of the current cwd      |
| `:WindowGroupsSession delete` | Delete the session of the current cwd    |

### Using another session manager

If you already use a session manager built on `:mksession`, keep
`autosave = false` (the default). Your manager saves and restores as before and
the groups travel along automatically. Enabling `autosave` as well would make
two managers restore on startup.

resession.nvim does not use `:mksession`, so groups are not persisted with it.

### Known limitations

- Sidebars such as neo-tree are not files. Depending on `'sessionoptions'`,
  `:mksession` either drops their windows or brings them back empty. Reopen the
  sidebar after restoring.
- Unnamed buffers (`[No Name]`) are not stored.
- A group whose shown file was deleted is matched to a window by position.

## Highlights

Set any of these groups in your colorscheme. If a group is not defined,
fallbacks are derived from `TabLine`, `TabLineSel`, and `Normal` at setup time
and refreshed on `ColorScheme`.

| Group                  | Meaning                                              |
| ---------------------- | ---------------------------------------------------- |
| `GroupsActive`         | Tab in the focused window, currently visible buffer  |
| `GroupsCurrent`        | Tab in an unfocused window, currently visible buffer |
| `GroupsInactive`       | Tab whose buffer is not currently visible            |
| `GroupsSep`            | Separator `│` between tabs                           |
| `GroupsFill`           | Winbar space after all tabs                          |
| `GroupsAccentActive`   | `border_char` in the focused window's winbar         |
| `GroupsAccentInactive` | `border_char` in unfocused windows' winbars          |
| `GroupsWinSepActive`   | `WinSeparator` override for the focused window       |
| `GroupsWinSepInactive` | `WinSeparator` override for unfocused windows        |

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
    active          = { fg = "#d4c5a9", bg = "#3d3d3d", bold = true },
    current         = { fg = "#9a9a8a", bg = "#2a2a2a" },
    inactive        = { fg = "#5a5a4a", bg = "#2a2a2a" },
    sep             = { fg = "#3d3d3d", bg = "#2a2a2a" },
    fill            = { bg = "#2a2a2a" },
    accent_active   = { fg = "#e06c75" },
    accent_inactive = { fg = "#4b5263" },
    winsep_active   = { fg = "#e06c75" },
    winsep_inactive = { fg = "#3b4048" },
  },
})
```

**Define groups directly in your colorscheme** (takes precedence over setup
overrides):

```lua
vim.api.nvim_set_hl(0, "GroupsActive",        { bg = "#3d3d3d", fg = "#d4c5a9", bold = true })
vim.api.nvim_set_hl(0, "GroupsCurrent",       { bg = "#2a2a2a", fg = "#9a9a8a" })
vim.api.nvim_set_hl(0, "GroupsInactive",      { bg = "#2a2a2a", fg = "#5a5a4a" })
vim.api.nvim_set_hl(0, "GroupsSep",           { bg = "#2a2a2a", fg = "#3d3d3d" })
vim.api.nvim_set_hl(0, "GroupsFill",          { bg = "#2a2a2a" })
vim.api.nvim_set_hl(0, "GroupsAccentActive",  { fg = "#e06c75" })
vim.api.nvim_set_hl(0, "GroupsAccentInactive",{ fg = "#4b5263" })
vim.api.nvim_set_hl(0, "GroupsWinSepActive",  { fg = "#e06c75" })
vim.api.nvim_set_hl(0, "GroupsWinSepInactive",{ fg = "#3b4048" })
```

If you use [singularity.nvim](https://github.com/merrebach/singularity.nvim),
all highlight groups are defined automatically when
`integrations.window_groups = true` (default).

## Filetypes

Add filetypes that should not participate in groups. These are merged with the
built-in exclusions (`neo-tree`, `snacks_dashboard`, `dashboard`):

```lua
require("window_groups").setup({
  exclude_filetypes = { "NvimTree", "Outline", "aerial", "toggleterm" },
})
```

Windows showing an excluded filetype get no winbar strip and their buffers are
never added to any group.

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

- **Single-membership is per-tabpage.** A buffer can appear in different groups
  across tabpages. Within one tabpage it belongs to at most one group.
- **Winbar only appears on editor windows.** Floats, explorer sidebars, help,
  quickfix, and terminal windows render no winbar strip.
- **`setup()` is idempotent.** Calling it more than once is a no-op.
- **`move_buf` fails silently on non-editor neighbors.** If the neighbor window
  is a sidebar or float, a warning is shown and the buffer stays where it is.
- **`close_buf` on an ineligible buffer** (terminal, scratch) falls back to
  `:bdelete` — no group logic applies.
- **`split` with no eligible buffer** opens a blank scratch split with no group
  entry.
- **Groups are not rebuilt while a session loads.** The usual "focus the owning
  window" redirect is suspended until the session has finished loading.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) and `CONTEXT.md` for the domain
glossary.

```sh
make install-hooks   # install pre-commit lint hook
make lint            # run luacheck
make test            # run plenary tests (requires Neovim in PATH)
```

## License

MIT — see [LICENSE](LICENSE).
