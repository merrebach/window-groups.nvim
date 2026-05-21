# Window-scoped Buffer Groups

Buffers are scoped per Window via autocmds and a winbar renderer (single-membership, `winid`-keyed) rather than per-tabpage (`scope.nvim`) or via a global bufferline. Only window-scoped groups give side-by-side visible tab strips, matching the VS Code editor-group mental model. The cost is hand-rolled state (`vim.w.group_bufs`), a custom winbar renderer, and `BufWinEnter`/`WinClosed`/`WinNew` autocmds that may conflict with plugins that programmatically open buffers in non-owning windows; this is accepted over the maturity of `scope.nvim` because tabpages cannot render two groups simultaneously.

`find_owner` searches only the current tabpage (`nvim_tabpage_list_wins(0)`). Cross-tabpage single-ownership is not enforced — each tabpage is an independent workspace with its own Group state.
