# Groups survive a restart with the built-in session autosave.
Output demo/.out/session.mp4
Source demo/tapes/_settings.tape
Env WG_DEMO_AUTOSAVE "1"

Hide
Type "cd demo/project && clear && nvim -u ../init.lua src/app/init.lua" Enter
Sleep 1.5s
Type ":e src/app/store.lua" Enter
Type ":e src/app/view.lua" Enter
Type " sl" Sleep 200ms
Type ":e src/config.lua" Enter
Type ":e tests/store_spec.lua" Enter
Type ":echo" Enter
Sleep 500ms
Show

Sleep 1.5s
Type ":qa" Sleep 500ms Enter
Sleep 1.2s
Type "nvim -u ../init.lua" Sleep 600ms Enter
Sleep 2s
Type "]b" Sleep 1s
Ctrl+h Sleep 1s
Type "]b" Sleep 2.5s
