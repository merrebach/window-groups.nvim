# Overview: every window keeps its own group of buffers.
Output demo/.out/demo.mp4
Source demo/tapes/_settings.tape

Hide
Type "cd demo/project && clear && nvim -u ../init.lua src/app/init.lua" Enter
Sleep 1.5s
Show

Sleep 800ms
Type ":e src/app/store.lua" Sleep 300ms Enter
Sleep 900ms
Type ":e src/app/view.lua" Sleep 300ms Enter
Sleep 1s
Type "]b" Sleep 1s
Type "]b" Sleep 1.2s

Type " sl" Sleep 1.5s
Type ":e src/config.lua" Sleep 300ms Enter
Sleep 900ms
Type ":e tests/store_spec.lua" Sleep 300ms Enter
Sleep 1.2s

Ctrl+h Sleep 1.2s
Type "[b" Sleep 1s
Ctrl+l Sleep 1.2s
Type "[b" Sleep 2s
