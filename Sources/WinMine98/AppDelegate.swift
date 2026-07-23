import AppKit
import CoreText

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: NSWindow?
    private var gameView: WinMineView?
    private let model = GameModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerPixelFonts()
        NSApp.setActivationPolicy(.regular)
        configureMainMenu()

        let view = WinMineView(model: model)
        let size = view.preferredSize
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let origin = NSPoint(
            x: floor(screen.midX - size.width / 2),
            y: floor(screen.midY - size.height / 2)
        )
        let window = NSWindow(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = true
        window.backgroundColor = RetroPalette.face
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.acceptsMouseMovedEvents = true
        window.delegate = self
        window.contentView = view
        window.title = "Minesweeper"
        window.setFrameAutosaveName("WinMine98MainWindow")
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(view)

        view.requestResize = { [weak self] in
            self?.resizeWindowForGame()
        }
        self.window = window
        self.gameView = view

        NSApp.activate(ignoringOtherApps: true)
    }

    private func registerPixelFonts() {
        let fontNames = [
            "PixelatedMSSansSerif",
            "PixelatedMSSansSerifBold"
        ]
        for fontName in fontNames {
            guard let url = Bundle.main.url(
                forResource: fontName,
                withExtension: "ttf",
                subdirectory: "Fonts"
            ) else {
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func windowDidBecomeKey(_ notification: Notification) {
        if let gameView {
            window?.makeFirstResponder(gameView)
        }
    }

    private func resizeWindowForGame() {
        guard let window, let view = gameView else { return }
        let newSize = view.preferredSize
        let oldFrame = window.frame
        let newFrame = NSRect(
            x: oldFrame.minX,
            y: oldFrame.maxY - newSize.height,
            width: newSize.width,
            height: newSize.height
        )
        window.setFrame(newFrame, display: true, animate: false)
        view.frame = NSRect(origin: .zero, size: newSize)
        view.needsDisplay = true
        window.makeFirstResponder(view)
    }

    private func configureMainMenu() {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Minesweeper", action: nil, keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Minesweeper", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        NSApp.mainMenu = mainMenu
    }
}
