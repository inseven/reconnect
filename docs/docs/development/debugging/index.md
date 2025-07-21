---
title: Debugging
---

Debugging Reconnect is a little more awkward than normal since plptools uses signals internally which are trapped by Xcode and lldb by default, causing the debugger to pause regularly. You can disable this automatic behavior by adding the following line to `~/.lldbinit-Xcode`:

```
process handle SIGUSR1 -n true -p true -s false
```

> [!WARNING]
> Changing `~/.lldbinit-Xcode` will cause Xcode to ignore `SIGUSR1` for all projects.
