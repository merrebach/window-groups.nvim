# Shared settings, sourced by every demo tape. Run tapes via demo/record.sh.
# No WindowBar/BorderRadius: their loop filter makes ffmpeg 9 buffer without
# bound (charmbracelet/vhs#581) and can eat all memory.
Set Shell "bash"
Set FontFamily "JetBrainsMono Nerd Font Mono"
Set FontSize 16
Set Width 1400
Set Height 800
Set Padding 16
Set Framerate 30
Set TypingSpeed 45ms
Set Theme "Catppuccin Mocha"
Env NVIM_APPNAME "window-groups-demo"
