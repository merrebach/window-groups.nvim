# Closing buffers: the neighbour takes over; an empty group closes its window.
Output demo/.out/close-buffer.mp4
Source demo/tapes/_settings.tape

Hide
Type "cd demo/project && clear && nvim -u ../init.lua src/app/init.lua" Enter
Sleep 1.5s
Type ":e src/app/store.lua" Enter
Type ":e src/app/view.lua" Enter
Type " sl" Sleep 200ms
Type ":e src/config.lua" Enter
Type ":e tests/store_spec.lua" Enter
Type ":e todos.json" Enter
Type "[b"
Type ":echo" Enter
Sleep 500ms
Show

Sleep 1s
Type " q" Sleep 1.5s
Type " q" Sleep 1.5s
Type " q" Sleep 1.8s
Type "[b" Sleep 1s
Type " bq" Sleep 2.5s
