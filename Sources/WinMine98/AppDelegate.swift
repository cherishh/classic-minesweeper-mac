import AppKit
import CoreText

@MainActor
private final class ScaledGameContainerView: NSView {
    let gameView: WinMineView

    init(gameView: WinMineView) {
        self.gameView = gameView
        super.init(frame: .zero)
        addSubview(gameView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        gameView.frame = bounds
        gameView.bounds = NSRect(origin: .zero, size: gameView.preferredSize)
    }

    func refreshLogicalSize() {
        needsLayout = true
        layoutSubtreeIfNeeded()
        gameView.needsDisplay = true
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: NSWindow?
    private var gameView: WinMineView?
    private var gameContainer: ScaledGameContainerView?
    private let model = GameModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerPixelFonts()
        NSApp.setActivationPolicy(.regular)
        configureMainMenu()

        let view = WinMineView(model: model)
        let logicalSize = view.preferredSize
        let size = scaledSize(logicalSize, by: view.windowSizePreset.scale)
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
        let container = ScaledGameContainerView(gameView: view)
        window.isOpaque = true
        window.backgroundColor = RetroPalette.face
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.acceptsMouseMovedEvents = true
        window.delegate = self
        window.contentView = container
        container.refreshLogicalSize()
        window.title = "Minesweeper"
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(view)

        view.requestResize = { [weak self] in
            self?.resizeWindowForGame()
        }
        view.requestWindowScale = { [weak self] scale in
            self?.resizeWindowForGame(interfaceScale: scale)
        }
        self.window = window
        self.gameView = view
        self.gameContainer = container

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

    private func resizeWindowForGame(interfaceScale requestedScale: CGFloat? = nil) {
        guard let window, let view = gameView else { return }
        let oldLogicalWidth = max(view.bounds.width, 1)
        let currentScale = max(view.frame.width / oldLogicalWidth, 1)
        let interfaceScale = requestedScale ?? currentScale
        let newLogicalSize = view.preferredSize
        let newSize = scaledSize(newLogicalSize, by: interfaceScale)
        let oldFrame = window.frame
        let newFrame = NSRect(
            x: oldFrame.minX,
            y: oldFrame.maxY - newSize.height,
            width: newSize.width,
            height: newSize.height
        )
        window.setFrame(newFrame, display: true, animate: false)
        gameContainer?.refreshLogicalSize()
        window.makeFirstResponder(view)
    }

    private func scaledSize(_ size: NSSize, by scale: CGFloat) -> NSSize {
        NSSize(width: size.width * scale, height: size.height * scale)
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
