# TerminalEventDemo

MoonBit demo application for testing the MVP integration loop:

TerminalEvent C++ backend -> MoonBit binding -> LunarTUI adapter -> LunarTUI widget event handling -> redraw.

Run from this directory:

```powershell
moon run cmd/main
```

The current TerminalEvent backend is POSIX-oriented. On Windows, raw mode is expected to report unavailable until a Windows console backend is implemented or the demo is run in a POSIX terminal environment.
