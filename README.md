# WinMine 98 for macOS

A native Apple Silicon recreation of the Windows 98 edition of Minesweeper.

## Build

```sh
./scripts/build-app.sh
```

The runnable application is written to `dist/Minesweeper.app`.
Building requires macOS 13 or later, Apple Silicon, and the Xcode command-line
tools.

## Controls

- Left click: uncover a square
- Right click: flag / question / clear
- Both mouse buttons, or middle click: chord around a revealed number
- F2: new game

The app uses an entirely custom-drawn, borderless AppKit window so the visible
chrome remains faithful to Windows 98 rather than adopting macOS window styling.

Created by [tuxi](https://tuxi.dev).
