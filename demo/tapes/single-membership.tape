# A buffer lives in exactly one group: opening it elsewhere jumps to its owner.
Output demo/.out/single-membership.mp4
Source demo/tapes/_settings.tape

Hide
Type "cd demo/project && clear && nvim -u ../init.lua src/app/init.lua" Enter
Sleep 1.5s
Type ":e src/app/store.lua" Enter
Type ":e src/app/view.lua" Enter
Type " sl" Sleep 200ms
Type ":e src/config.lua" Enter
Type ":echo" Enter
Sleep 500ms
Show

Sleep 1s
Type ":e src/app/store.lua" Sleep 500ms Enter
Sleep 2s
Ctrl+l Sleep 1s
Type ":e src/app/init.lua" Sleep 500ms Enter
Sleep 2.5s
