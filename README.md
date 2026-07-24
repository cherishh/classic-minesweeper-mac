# WinMine 98 for macOS

A native Apple Silicon recreation of the Windows 98 edition of Minesweeper.

Requires **macOS 13+** and **Apple Silicon** (M1 / M2 / M3 / M4…).

## Download & open（下载与运行）

从 [GitHub Releases](https://github.com/cherishh/classic-minesweeper-mac/releases/latest)
下载 `Minesweeper-macOS-arm64.zip`，解压后双击 `Minesweeper.app` 即可。

首次启动时，macOS 可能显示“从互联网下载”的确认框，点击
**打开 / Open**。

**English:** Download the ZIP, unzip it, and double-click `Minesweeper.app`.
Click **Open** if macOS shows a first-launch confirmation.

## Controls

- Left click: uncover a square
- Right click: flag / question / clear
- Both mouse buttons, or middle click: chord around a revealed number
- F2: new game

The app uses an entirely custom-drawn, borderless AppKit window so the visible
chrome remains faithful to Windows 98 rather than adopting macOS window styling.

## Build from source

```sh
./scripts/build-app.sh
```

Output: `dist/Minesweeper.app`. Needs macOS 13+, Apple Silicon, and Xcode CLT.

Created by [tuxi](https://tuxi.dev).
