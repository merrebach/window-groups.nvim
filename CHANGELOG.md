# Changelog

All notable changes to this project are documented in this file. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Demo recordings in the README, reproducible with `make demo` (VHS tapes in
  `demo/`).

### Fixed

- Highlight groups are empty after switching colorschemes: fallbacks are now
  re-applied when `:hi clear` wiped them, colorscheme-defined groups still win.
- File names containing `%` are rendered wrongly in the winbar.
- `close_buf` removed a modified buffer from its group although deleting it
  failed, leaving it listed but in no group. It now refuses and keeps the
  buffer. `close_group` keeps modified buffers in the group and the window open.
- Help, quickfix, terminal and file tree windows showed an empty winbar row.
  The winbar is now set per window, only on windows with a group.
- `move_buf` of the last buffer in a group left a hidden scratch buffer in the
  source window, which then blocked moving back (#18). The emptied window now
  closes, as with `close_buf`.
- Opening a buffer owned by another window focused that window but kept
  showing its previous buffer. The owner now shows the opened buffer.

## [0.2.0] - 2026-09-27

### Added

- Session persistence for groups (#1). Every `:mksession` file now carries the
  groups of all windows and restores them when sourced — with plain
  `:mksession`, `nvim -S`, and session managers built on `:mksession`.
- Built-in per-directory session management behind `session.autosave`
  (default `false`): save on exit, restore on `nvim` or `nvim <dir>`.
- `:WindowGroupsSession save|load|delete` and the `window_groups.session` Lua
  API (`save`, `load`, `delete`, `path`).
- `session` config block: `autosave`, `dir`, `options`, `skip_missing`.

### Changed

- The group redirect on `BufWinEnter` is paused while a session loads.

## [0.1.0] - 2026-05-21

Initial release.

[Unreleased]: https://github.com/merrebach/window-groups.nvim/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/merrebach/window-groups.nvim/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/merrebach/window-groups.nvim/releases/tag/neovim-plugin
