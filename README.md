# WinMine 98 for macOS

A native Apple Silicon recreation of the Windows 98 edition of Minesweeper.

Requires **macOS 13+** and **Apple Silicon** (M1 / M2 / M3 / M4…).

## Download & open（下载后如何打开）

GitHub 上的安装包未经过 Apple 公证，首次打开时系统会提示无法验证。按下面任选一种方式即可。

### 方法一：系统设置（推荐，macOS Sonoma / Sequoia）

1. 下载并解压，得到 `Minesweeper.app`
2. 双击打开；若弹出 **“Minesweeper” Not Opened** / **无法打开**，点 **Done** / **完成**（不要点 Move to Trash）
3. 打开 **系统设置 → 隐私与安全性**
4. 向下滚动，找到 **“Minesweeper”已被阻止使用**
5. 点 **仍要打开** → 再确认一次 **打开**

以后再开就不会再拦。

### 方法二：右键打开

1. 在 Finder 中 **按住 Control 点击**（或右键）`Minesweeper.app`
2. 选择 **打开**
3. 在对话框中再点 **打开**

### 方法三：终端（一次搞定）

把路径换成你实际的解压位置：

```sh
xattr -cr ~/Downloads/Minesweeper.app
open ~/Downloads/Minesweeper.app
```

---

If macOS says *“Apple could not verify Minesweeper”*:

1. Click **Done** (not Move to Trash)
2. **System Settings → Privacy & Security** → scroll down → **Open Anyway**
3. Or Control-click the app → **Open** → **Open**

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

Signing / notarization notes (when you renew Developer Program membership): [docs/SIGNING.md](docs/SIGNING.md).

Created by [tuxi](https://tuxi.dev).
