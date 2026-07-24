# WinMine 98 for macOS

A native Apple Silicon recreation of the Windows 98 edition of Minesweeper.

Requires **macOS 13+** and **Apple Silicon** (M1 / M2 / M3 / M4…).

## Download & open（下载后如何打开）

GitHub 上的安装包未经过 Apple 公证，首次打开时系统会提示无法验证。

> **注意：** 在较新的 macOS（Sonoma / Sequoia 及以后）上，**右键 → 打开 无效**，仍会只出现 *Move to Trash / Done*。请用下面两种方式之一。

### 方法一：终端（最省事、最稳）

下载并解压后，在「终端」执行（路径按实际位置改）：

```sh
xattr -cr ~/Downloads/Minesweeper.app
open ~/Downloads/Minesweeper.app
```

若 app 在「下载」以外的文件夹，把路径换成真实位置，例如：

```sh
xattr -cr ~/Desktop/Minesweeper.app && open ~/Desktop/Minesweeper.app
```

`xattr -cr` 会去掉下载隔离标记，之后即可正常双击打开。

### 方法二：系统设置

1. 双击 `Minesweeper.app`
2. 弹出 **“Minesweeper” Not Opened** 时，点 **Done / 完成**（**不要**点 Move to Trash）
3. 打开 **系统设置 → 隐私与安全性**
4. 向下滚动，找到刚出现的 **“Minesweeper”已被阻止使用**（或类似文案）
5. 点 **仍要打开** → 再确认 **打开**

若设置里暂时看不到该提示：再双击一次 app → 再点 **Done**，然后立刻回到「隐私与安全性」查看。

---

If macOS says *“Apple could not verify Minesweeper”*:

**Right-click → Open no longer works** on recent macOS. Use:

```sh
xattr -cr ~/Downloads/Minesweeper.app && open ~/Downloads/Minesweeper.app
```

Or: click **Done** → **System Settings → Privacy & Security** → **Open Anyway**.
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
