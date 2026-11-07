#!/usr/bin/env bash
# Records the README demos with VHS (https://github.com/charmbracelet/vhs).
# Usage: demo/record.sh [tape-name ...]   (default: all tapes)
set -euo pipefail

cd "$(dirname "$0")/.."
# VHS=/path/to/vhs overrides the binary. v0.12.0 exits 0 without writing any
# output (charmbracelet/vhs#787); use v0.11.0 until a fixed release ships:
#   GOBIN=~/.local/bin go install github.com/charmbracelet/vhs@v0.11.0
VHS="${VHS:-vhs}"
command -v "$VHS" >/dev/null || { echo "vhs not found: install it first (e.g. pacman -S vhs, brew install vhs)"; exit 1; }
if "$VHS" --version | grep -q "v0\.12\.0"; then
	echo "vhs v0.12.0 writes no output (charmbracelet/vhs#787), use v0.11.0 via VHS=..." >&2
	exit 1
fi

export NVIM_APPNAME=window-groups-demo
state="${XDG_STATE_HOME:-$HOME/.local/state}/$NVIM_APPNAME"

mkdir -p demo/.out assets

# Fetch demo dependencies once, outside the recording.
nvim --headless -u demo/init.lua +qa

# Cap memory of each recording so a runaway ffmpeg cannot take down other
# processes (needs a systemd user session; runs uncapped otherwise).
run_capped() {
	if command -v systemd-run >/dev/null && systemctl --user show-environment >/dev/null 2>&1; then
		systemd-run --user --scope -q -p MemoryMax=6G -p MemorySwapMax=0 "$@"
	else
		"$@"
	fi
}

tapes=("$@")
[ ${#tapes[@]} -eq 0 ] && tapes=(demo move-buffer single-membership close-buffer session)

for tape in "${tapes[@]}"; do
	rm -rf "$state" # fresh sessions and shada for every recording
	echo "==> $tape"
	run_capped "$VHS" "demo/tapes/$tape.tape"
	# Two-pass GIF conversion: vhs' single-pass palette filter can exhaust
	# memory with some ffmpeg versions and then fails silently.
	run_capped ffmpeg -hide_banner -loglevel error -y -i "demo/.out/$tape.mp4" \
		-vf "fps=20,palettegen=stats_mode=diff" "demo/.out/$tape.png"
	run_capped ffmpeg -hide_banner -loglevel error -y -i "demo/.out/$tape.mp4" -i "demo/.out/$tape.png" \
		-lavfi "fps=20[v];[v][1:v]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
		"assets/$tape.gif"
	echo "    assets/$tape.gif"
done
