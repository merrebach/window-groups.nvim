# Contributing

## Reporting bugs

Use the [Bug Report](.github/ISSUE_TEMPLATE/bug_report.md) issue template. Include your Neovim version (`nvim --version`), minimal reproduction steps, and what you expected vs what happened.

## Suggesting features

Use the [Feature Request](.github/ISSUE_TEMPLATE/feature_request.md) issue template. Explain the use case — what you are trying to accomplish and why the current API does not cover it.

## Submitting pull requests

1. Fork the repo and create a branch from `main`.
2. Make your changes. Keep the scope tight — one fix or feature per PR.
3. Run `make lint` and `make test` locally. Both must pass.
4. Open a PR against `main` with a clear description of what changed and why.

## Code style

- **No comments** unless the *why* is non-obvious. A hidden constraint, a subtle invariant, a specific bug workaround.
- **No docstrings**. Function names and parameter names should be self-explanatory.
- All Lua must pass `luacheck lua/ tests/` with zero warnings. The `.luacheckrc` in the repo configures the rules.
- Follow the existing patterns in `init.lua`. Read `CONTEXT.md` for the domain vocabulary before adding new behaviour.

## Tests

New behaviour needs a test in `tests/window_groups/`. Use the existing spec files as templates. Run the full suite with:

```sh
make test
```

Tests run with plenary.nvim in a headless Neovim instance.

## Demo recordings

The GIFs in `assets/` are recorded with [VHS](https://github.com/charmbracelet/vhs)
from the tapes in `demo/tapes/`. Re-record them when the winbar or a recorded
behaviour changes:

```sh
make demo                          # all tapes
demo/record.sh move-buffer         # a single tape
```

`demo/init.lua` is an isolated config (`NVIM_APPNAME=window-groups-demo`), so
recording never touches your own config, state or sessions. It needs
`ffmpeg`, `ttyd` and a Nerd Font (JetBrainsMono Nerd Font Mono by default).

VHS v0.12.0 finishes without writing any file
([charmbracelet/vhs#787](https://github.com/charmbracelet/vhs/issues/787)).
Until a fixed release ships, install v0.11.0 and point `VHS` at it:

```sh
GOBIN=~/.local/bin go install github.com/charmbracelet/vhs@v0.11.0
VHS=~/.local/bin/vhs make demo
```

## Architecture

Before adding something significant, read:

- `CONTEXT.md` — domain glossary (group, eligible, owner, etc.)
- `docs/adr/0001-window-scoped-groups.md` — core design decisions

If your change introduces a new hard-to-reverse decision, consider whether an ADR is warranted.
