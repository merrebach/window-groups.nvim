# Move a buffer from one group to the neighbouring window's group.
Output demo/.out/move-buffer.mp4
Source demo/tapes/_settings.tape

Hide
Type "cd demo/project && clear && nvim -u ../init.lua src/app/init.lua" Enter
Sleep 1.5s
Type ":e src/app/store.lua" Enter
Type ":e src/app/view.lua" Enter
Type " sl" Sleep 200ms
Type ":e src/config.lua" Enter
Ctrl+h
Type ":e todos.json" Enter
Type ":echo" Enter
Sleep 500ms
Show

Sleep 1s
Type " bml" Sleep 1.8s
Ctrl+h Sleep 1s
Type "[b" Sleep 1s
Type " bml" Sleep 1.8s
Type " bmh" Sleep 1.8s
Ctrl+l Sleep 1s
Type " bmh" Sleep 1.8s
Ctrl+l Sleep 1s
Type " bmh" Sleep 2.5s
