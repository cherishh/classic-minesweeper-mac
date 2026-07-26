import AppKit
import CoreText

enum AppLinks {
    static let privacy = URL(string: "https://cherishh.github.io/classic-minesweeper-mac/privacy.html")!
    static let support = URL(string: "https://cherishh.github.io/classic-minesweeper-mac/support.html")!
    static let website = URL(string: "https://github.com/cherishh/classic-minesweeper-mac")!
}

final class RetroMainWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

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

        #if DEBUG
        configureCaptureModelIfNeeded()
        #endif

        let view = WinMineView(model: model)
        let logicalSize = view.preferredSize
        let size = scaledSize(logicalSize, by: view.windowSizePreset.scale)
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let origin = NSPoint(
            x: floor(screen.midX - size.width / 2),
            y: floor(screen.midY - size.height / 2)
        )
        let window = RetroMainWindow(
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
        window.title = "Classic Minesweeper"
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

        #if DEBUG
        view.showCaptureOverlayIfNeeded()
        #endif
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

    #if DEBUG
    private func configureCaptureModelIfNeeded() {
        guard let state = ProcessInfo.processInfo.environment["CLASSIC_MINES_CAPTURE_STATE"] else {
            return
        }

        if state.hasPrefix("expert") {
            model.newGame(.expert)
        } else if state.hasPrefix("intermediate") {
            model.newGame(.intermediate)
        } else {
            model.newGame(.beginner)
        }

        guard state.hasSuffix("playing") else { return }
        let center = model.index(column: model.width / 2, row: model.height / 2) ?? 0
        model.reveal(at: center)
        let additionalOpenings = model.cells.indices.filter {
            !model.cells[$0].hasMine
                && !model.cells[$0].revealed
                && model.cells[$0].adjacentMines == 0
        }
        for index in additionalOpenings.prefix(2) {
            model.reveal(at: index)
        }
        for index in model.cells.indices where !model.cells[index].revealed {
            model.toggleMark(at: index)
            if model.flagCount == min(5, model.mineCount) { break }
        }
    }
    #endif

    private func configureMainMenu() {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(menuItem(title: "About Classic Minesweeper", action: #selector(showAboutPanel)))
        appMenu.addItem(menuItem(title: "Privacy Policy", action: #selector(openPrivacyPolicy)))
        appMenu.addItem(menuItem(title: "Support", action: #selector(openSupport)))
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Classic Minesweeper", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        NSApp.mainMenu = mainMenu
    }

    private func menuItem(title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc private func showAboutPanel() {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Classic Minesweeper",
            .credits: NSAttributedString(
                string: "A native recreation of the classic desktop puzzle.\nCreated by tuxi.",
                attributes: [.font: NSFont.systemFont(ofSize: 11)]
            )
        ])
    }

    @objc private func openPrivacyPolicy() {
        NSWorkspace.shared.open(AppLinks.privacy)
    }

    @objc private func openSupport() {
        NSWorkspace.shared.open(AppLinks.support)
    }
}
