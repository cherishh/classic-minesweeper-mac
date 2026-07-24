# WinMine 98 for macOS

A native Apple Silicon recreation of the Windows 98 edition of Minesweeper.

Requires **macOS 13+** and **Apple Silicon** (M1 / M2 / M3 / M4…).

## Download & open（下载后如何打开）

安装包未做 Apple 公证。双击时可能弹出 *“Minesweeper” Not Opened*，按钮只有 **Move to Trash** / **Done**。

**右键 → 打开在新系统上无效**，请用下面方法。

### 推荐：终端一条命令

1. 下载并解压，得到 `Minesweeper.app`
2. 打开 **终端**，执行（把路径改成你的实际位置）：

```sh
xattr -cr ~/Downloads/Minesweeper.app && open ~/Downloads/Minesweeper.app
```

例子：

| app 位置 | 命令 |
|----------|------|
| 下载文件夹 | `xattr -cr ~/Downloads/Minesweeper.app && open ~/Downloads/Minesweeper.app` |
| 桌面 | `xattr -cr ~/Desktop/Minesweeper.app && open ~/Desktop/Minesweeper.app` |

做完一次后，以后可以正常双击打开。

### 备选：系统设置

1. 双击 app → 点 **Done / 完成**（不要点 Move to Trash）
2. **系统设置 → 隐私与安全性** → 往下滚
3. 找到 **“Minesweeper”已被阻止** → **仍要打开** → **打开**

设置里暂时没有该项时：再双击一次 app → 点 Done，马上回到该页面。

---

**English:** Right-click → Open does **not** work on recent macOS. Run:

```sh
xattr -cr ~/Downloads/Minesweeper.app && open ~/Downloads/Minesweeper.app
```

Or: **Done** → **System Settings → Privacy & Security** → **Open Anyway**.## Controls

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
