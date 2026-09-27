# Changelog

All notable changes to this project are documented in this file. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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
