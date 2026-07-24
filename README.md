# WinMine 98 for macOS

A native Apple Silicon recreation of the Windows 98 edition of Minesweeper.

Requires **macOS 13+** and **Apple Silicon** (M1 / M2 / M3 / M4…).

## Download & open（下载与运行）

从 [GitHub Releases](https://github.com/cherishh/classic-minesweeper-mac/releases/latest)
下载 `Minesweeper-macOS-arm64.zip`，解压后双击 `Minesweeper.app` 即可。

发布包已经过 **Developer ID 签名和 Apple 公证**，并通过 Gatekeeper
验证，不再需要运行 `xattr` 命令，也不会再出现 **Move to Trash** 提示。
首次启动时，macOS 仍可能显示标准的“从互联网下载”确认框，点击
**Open / 打开** 即可。

**English:** The release is Developer ID signed and Apple-notarized. Download,
unzip, and double-click `Minesweeper.app`; no Terminal workaround is required.

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

Release builds are Developer ID signed and Apple-notarized. See
[docs/SIGNING.md](docs/SIGNING.md) for the release process.

Created by [tuxi](https://tuxi.dev).
