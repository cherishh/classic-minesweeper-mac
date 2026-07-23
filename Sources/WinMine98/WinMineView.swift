import AppKit

enum WindowSizePreset: String, CaseIterable {
    case small
    case medium
    case large

    static let defaultsKey = "window.sizePreset"

    var title: String {
        switch self {
        case .small: "Small (Original)"
        case .medium: "Medium"
        case .large: "Large"
        }
    }

    var scale: CGFloat {
        switch self {
        case .small: 1
        case .medium: 1.5
        case .large: 2
        }
    }
}

@MainActor
final class WinMineView: NSView {
    static let cellSize: CGFloat = 16
    static let horizontalChrome: CGFloat = 25
    static let verticalChrome: CGFloat = 104

    let model: GameModel
    var requestResize: (() -> Void)?
    var requestWindowScale: ((CGFloat) -> Void)?
    private(set) var windowSizePreset: WindowSizePreset

    private var leftDown = false
    private var rightDown = false
    private var leftCell: Int?
    private var rightCell: Int?
    private var hoverCell: Int?
    private var chordCell: Int?
    private var facePressed = false
    private var windowControlPressed: String?
    private var menuWindow: RetroMenuWindow?
    private var dialogWindow: RetroDialogWindow?

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    var preferredSize: NSSize {
        NSSize(
            width: CGFloat(model.width) * Self.cellSize + Self.horizontalChrome,
            height: CGFloat(model.height) * Self.cellSize + Self.verticalChrome
        )
    }

    private var titleRect: NSRect { NSRect(x: 2, y: 2, width: bounds.width - 5, height: 18) }
    private var menuBarRect: NSRect { NSRect(x: 2, y: 20, width: bounds.width - 5, height: 19) }
    private var gameMenuRect: NSRect { NSRect(x: 6, y: 20, width: 38, height: 19) }
    private var helpMenuRect: NSRect { NSRect(x: 44, y: 20, width: 34, height: 19) }
    private var closeRect: NSRect { NSRect(x: bounds.width - 17, y: 4, width: 14, height: 14) }
    private var maximizeRect: NSRect { NSRect(x: bounds.width - 32, y: 4, width: 14, height: 14) }
    private var minimizeRect: NSRect { NSRect(x: bounds.width - 47, y: 4, width: 14, height: 14) }
    private var headerRect: NSRect { NSRect(x: 10, y: 48, width: bounds.width - 20, height: 33) }
    private var mineDisplayRect: NSRect { NSRect(x: 19, y: 53, width: 41, height: 24) }
    private var timeDisplayRect: NSRect { NSRect(x: bounds.width - 59, y: 53, width: 41, height: 24) }
    private var faceRect: NSRect { NSRect(x: floor(bounds.midX - 12.5), y: 52, width: 26, height: 26) }
    private var gridFrameRect: NSRect {
        NSRect(
            x: 10,
            y: 88,
            width: CGFloat(model.width) * Self.cellSize + 6,
            height: CGFloat(model.height) * Self.cellSize + 6
        )
    }
    private var gridOrigin: NSPoint { NSPoint(x: 13, y: 91) }
    private var interfaceScale: CGFloat {
        guard bounds.width > 0 else { return 1 }
        return max(frame.width / bounds.width, 1)
    }

    init(model: GameModel) {
        self.model = model
        let savedPreset = UserDefaults.standard.string(forKey: WindowSizePreset.defaultsKey)
        self.windowSizePreset = savedPreset.flatMap(WindowSizePreset.init(rawValue:)) ?? .medium
        super.init(frame: .zero)
        model.onChange = { [weak self] in
            self?.needsDisplay = true
        }
        model.onWin = { [weak self] difficulty, seconds in
            self?.handleWin(difficulty: difficulty, seconds: seconds)
        }
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.activeAlways, .inVisibleRect, .mouseMoved, .mouseEnteredAndExited],
            owner: self
        ))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        NSGraphicsContext.current?.cgContext.setAllowsAntialiasing(false)
        NSGraphicsContext.current?.cgContext.setShouldAntialias(false)

        drawBevel(bounds, style: .raised, thickness: 3)
        drawTitleBar()
        pixelFill(menuBarRect, RetroPalette.face)
        drawRetroText("Game", at: NSPoint(x: 8, y: 21), size: 11)
        drawRetroText("Help", at: NSPoint(x: 46, y: 21), size: 11)

        drawBevel(
            NSRect(x: 1, y: 39, width: bounds.width - 2, height: bounds.height - 41),
            style: .raised,
            thickness: 2
        )
        drawBevel(headerRect, style: .sunken, thickness: 3)
        drawSegmentDisplay(model.remainingMineDisplay, in: mineDisplayRect)
        drawSegmentDisplay(model.elapsedSeconds, in: timeDisplayRect)

        let expression: String
        if facePressed {
            expression = "neutral"
        } else if leftDown && hoverCell != nil {
            expression = "surprised"
        } else if model.phase == .lost {
            expression = "dead"
        } else if model.phase == .won {
            expression = "cool"
        } else {
            expression = "neutral"
        }
        if expression == "neutral", !facePressed,
           drawPixelAsset("face-neutral-full", in: faceRect) {
            // The original WinMine face sprite includes its own 26 x 26 bevel.
        } else {
            drawRaisedButton(faceRect, pressed: facePressed)
            let assetName: String
            switch expression {
            case "neutral": assetName = "face-neutral"
            case "surprised": assetName = "face-surprised"
            case "dead": assetName = "face-dead"
            case "cool": assetName = "face-cool"
            default: assetName = "face-neutral"
            }
            let offset: CGFloat = facePressed ? 5 : 4
            if !drawPixelAsset(
                assetName,
                in: NSRect(
                    x: faceRect.minX + offset,
                    y: faceRect.minY + offset,
                    width: 17,
                    height: 17
                )
            ) {
                drawSmiley(in: faceRect, expression: expression, pressed: facePressed)
            }
        }

        drawBevel(gridFrameRect, style: .sunken, thickness: 3)
        drawBoard()
    }

    private func drawTitleBar() {
        pixelFill(titleRect, RetroPalette.titleStart)
        if !drawPixelAsset("app-icon-16", in: NSRect(x: 4, y: 3, width: 16, height: 16)) {
            drawTitleBarIcon(in: NSRect(x: 4, y: 3, width: 16, height: 16))
        }
        drawRetroText(
            "Minesweeper",
            at: NSPoint(x: 21, y: 4),
            color: .white,
            size: 11,
            bold: false
        )
        drawWindowControl(minimizeRect, kind: "min", pressed: false)
        drawWindowControl(maximizeRect, kind: "max", pressed: false, enabled: false)
        drawWindowControl(closeRect, kind: "close", pressed: false)
        if windowControlPressed == "min" {
            drawWindowControl(minimizeRect, kind: "min", pressed: true)
        } else if windowControlPressed == "close" {
            drawWindowControl(closeRect, kind: "close", pressed: true)
        }
    }

    private func drawBoard() {
        for index in model.cells.indices {
            let column = index % model.width
            let row = index / model.width
            let rect = NSRect(
                x: gridOrigin.x + CGFloat(column) * Self.cellSize,
                y: gridOrigin.y + CGFloat(row) * Self.cellSize,
                width: Self.cellSize,
                height: Self.cellSize
            )
            drawCell(index: index, rect: rect)
        }
    }

    private func drawCell(index: Int, rect: NSRect) {
        let cell = model.cells[index]
        let pressed = shouldDrawPressed(index: index)

        if cell.revealed || pressed {
            pixelFill(rect, RetroPalette.face)
            pixelFill(NSRect(x: rect.minX, y: rect.minY, width: rect.width, height: 1), RetroPalette.shadow)
            pixelFill(NSRect(x: rect.minX, y: rect.minY, width: 1, height: rect.height), RetroPalette.shadow)
        } else {
            if !drawPixelAsset("cell-covered", in: rect) {
                drawBevel(rect, style: .raised, thickness: 1)
            }
        }

        if cell.revealed {
            if cell.hasMine {
                if model.explodedIndex == index {
                    pixelFill(rect, .red)
                }
                if !drawPixelAsset(
                    "mine",
                    in: rect
                ) {
                    drawMineGlyph(in: rect, exploded: model.explodedIndex == index)
                }
            } else if cell.adjacentMines > 0 {
                drawCellNumber(cell.adjacentMines, in: rect, colored: model.colorsEnabled)
            }
        } else {
            switch cell.mark {
            case .flag:
                if !drawPixelAsset(
                    "flag",
                    in: NSRect(x: rect.minX + 3, y: rect.minY + 3, width: 10, height: 10)
                ) {
                    drawFlagGlyph(in: rect)
                }
                if model.phase == .lost && !cell.hasMine {
                    drawWrongFlagCross(in: rect)
                }
            case .question:
                if !pressed, !drawPixelAsset(
                    "question-mark",
                    in: NSRect(x: rect.minX + 3, y: rect.minY + 3, width: 10, height: 10)
                ) {
                    drawQuestionGlyph(in: rect)
                }
            case .none:
                break
            }
        }
    }

    private func shouldDrawPressed(index: Int) -> Bool {
        if let chordCell, leftDown && rightDown {
            return model.neighbors(of: chordCell).contains(index)
                && !model.cells[index].revealed
                && model.cells[index].mark != .flag
        }
        return leftDown && leftCell == index && !model.cells[index].revealed && model.cells[index].mark != .flag
    }

    override func mouseMoved(with event: NSEvent) {
        hoverCell = cellIndex(at: convert(event.locationInWindow, from: nil))
        if leftDown {
            leftCell = hoverCell
        }
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        hoverCell = nil
        if leftDown { leftCell = nil }
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        closeMenu()
        let point = convert(event.locationInWindow, from: nil)

        if closeRect.contains(point) {
            windowControlPressed = "close"
            needsDisplay = true
            return
        }
        if minimizeRect.contains(point) {
            windowControlPressed = "min"
            needsDisplay = true
            return
        }
        if gameMenuRect.contains(point) {
            showGameMenu()
            return
        }
        if helpMenuRect.contains(point) {
            showHelpMenu()
            return
        }
        if faceRect.contains(point) {
            facePressed = true
            needsDisplay = true
            return
        }
        if titleRect.contains(point), !maximizeRect.contains(point) {
            window?.performDrag(with: event)
            return
        }

        leftDown = true
        leftCell = cellIndex(at: point)
        hoverCell = leftCell
        if rightDown, let hoverCell, model.cells[hoverCell].revealed {
            chordCell = hoverCell
        }
        needsDisplay = true
    }

    override func rightMouseDown(with event: NSEvent) {
        closeMenu()
        let point = convert(event.locationInWindow, from: nil)
        rightDown = true
        rightCell = cellIndex(at: point)
        hoverCell = rightCell
        if leftDown, let hoverCell, model.cells[hoverCell].revealed {
            chordCell = hoverCell
        }
        needsDisplay = true
    }

    override func otherMouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if let index = cellIndex(at: point), model.cells[index].revealed {
            chordCell = index
            leftDown = true
            rightDown = true
            needsDisplay = true
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        hoverCell = cellIndex(at: point)
        leftCell = hoverCell
        if leftDown && rightDown, let hoverCell, model.cells[hoverCell].revealed {
            chordCell = hoverCell
        }
        needsDisplay = true
    }

    override func rightMouseDragged(with event: NSEvent) {
        hoverCell = cellIndex(at: convert(event.locationInWindow, from: nil))
        rightCell = hoverCell
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if let control = windowControlPressed {
            windowControlPressed = nil
            needsDisplay = true
            if control == "close", closeRect.contains(point) {
                NSApp.terminate(nil)
            } else if control == "min", minimizeRect.contains(point) {
                window?.miniaturize(nil)
            }
            return
        }

        if facePressed {
            let restart = faceRect.contains(point)
            facePressed = false
            needsDisplay = true
            if restart { restartCurrentGame() }
            return
        }

        if leftDown && rightDown {
            if let chordCell { model.chord(at: chordCell) }
            leftDown = false
            chordCell = nil
            leftCell = nil
            needsDisplay = true
            return
        }

        let releasedIndex = cellIndex(at: point)
        if leftDown, releasedIndex == leftCell, let index = releasedIndex {
            if model.cells[index].revealed {
                model.chord(at: index)
            } else {
                model.reveal(at: index)
            }
        }
        leftDown = false
        leftCell = nil
        chordCell = nil
        needsDisplay = true
    }

    override func rightMouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if leftDown && rightDown {
            if let chordCell { model.chord(at: chordCell) }
            rightDown = false
            chordCell = nil
            rightCell = nil
            needsDisplay = true
            return
        }

        let releasedIndex = cellIndex(at: point)
        if rightDown, releasedIndex == rightCell, let index = releasedIndex {
            model.toggleMark(at: index)
        }
        rightDown = false
        rightCell = nil
        chordCell = nil
        needsDisplay = true
    }

    override func otherMouseUp(with event: NSEvent) {
        if let chordCell { model.chord(at: chordCell) }
        leftDown = false
        rightDown = false
        chordCell = nil
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 120:
            restartCurrentGame()
        case 53:
            closeMenu()
        default:
            super.keyDown(with: event)
        }
    }

    private func cellIndex(at point: NSPoint) -> Int? {
        let x = point.x - gridOrigin.x
        let y = point.y - gridOrigin.y
        guard x >= 0, y >= 0 else { return nil }
        let column = Int(floor(x / Self.cellSize))
        let row = Int(floor(y / Self.cellSize))
        return model.index(column: column, row: row)
    }

    private func restartCurrentGame() {
        if model.difficulty == .custom {
            model.newCustomGame(width: model.width, height: model.height, mines: model.mineCount)
        } else {
            model.newGame(model.difficulty)
        }
        requestResize?()
    }

    private func chooseDifficulty(_ difficulty: Difficulty) {
        model.newGame(difficulty)
        requestResize?()
    }

    private func chooseWindowSize(_ preset: WindowSizePreset) {
        guard preset != windowSizePreset else { return }
        windowSizePreset = preset
        UserDefaults.standard.set(preset.rawValue, forKey: WindowSizePreset.defaultsKey)
        requestWindowScale?(preset.scale)
    }

    private func showGameMenu() {
        closeMenu()
        let current = model.difficulty
        let windowSizeItems = WindowSizePreset.allCases.map { preset in
            RetroMenuItem(
                title: preset.title,
                checked: windowSizePreset == preset,
                action: { [weak self] in self?.chooseWindowSize(preset) }
            )
        }
        let items = [
            RetroMenuItem(title: "New", shortcut: "F2", action: { [weak self] in self?.restartCurrentGame() }),
            .line(),
            RetroMenuItem(title: "Beginner", checked: current == .beginner, action: { [weak self] in self?.chooseDifficulty(.beginner) }),
            RetroMenuItem(title: "Intermediate", checked: current == .intermediate, action: { [weak self] in self?.chooseDifficulty(.intermediate) }),
            RetroMenuItem(title: "Expert", checked: current == .expert, action: { [weak self] in self?.chooseDifficulty(.expert) }),
            RetroMenuItem(title: "Custom...", checked: current == .custom, action: { [weak self] in self?.showCustomDialog() }),
            .line(),
            RetroMenuItem(title: "Marks (?)", checked: model.marksEnabled, action: { [weak self] in
                guard let self else { return }
                self.model.marksEnabled.toggle()
                self.needsDisplay = true
            }),
            RetroMenuItem(title: "Color", checked: model.colorsEnabled, action: { [weak self] in
                guard let self else { return }
                self.model.colorsEnabled.toggle()
                self.needsDisplay = true
            }),
            RetroMenuItem(title: "Window Size", submenu: windowSizeItems),
            .line(),
            RetroMenuItem(title: "Best Times...", action: { [weak self] in self?.showBestTimes() }),
            .line(),
            RetroMenuItem(title: "Exit", action: { NSApp.terminate(nil) })
        ]
        showMenu(items: items, under: gameMenuRect, width: 188)
    }

    private func showHelpMenu() {
        closeMenu()
        let items = [
            RetroMenuItem(title: "About...", action: { [weak self] in self?.showAbout() })
        ]
        showMenu(items: items, under: helpMenuRect, width: 185)
    }

    private func showMenu(items: [RetroMenuItem], under rect: NSRect, width: CGFloat) {
        guard let parentWindow = window else { return }
        let menu = RetroMenuWindow(
            items: items,
            width: width,
            scale: interfaceScale
        ) { [weak self, weak parentWindow] in
            guard let self else { return }
            if let activeMenu = self.menuWindow {
                parentWindow?.removeChildWindow(activeMenu)
                activeMenu.orderOut(nil)
            }
            self.menuWindow = nil
            parentWindow?.makeKeyAndOrderFront(nil)
            if let parentWindow {
                parentWindow.makeFirstResponder(self)
            }
        }
        let localAnchor = NSRect(x: rect.minX, y: rect.maxY, width: 1, height: 1)
        let windowAnchor = convert(localAnchor, to: nil)
        let screenAnchor = parentWindow.convertToScreen(windowAnchor)
        menu.setFrameTopLeftPoint(NSPoint(x: screenAnchor.minX, y: screenAnchor.minY))
        parentWindow.addChildWindow(menu, ordered: .above)
        menuWindow = menu
        menu.makeKeyAndOrderFront(nil)
    }

    private func closeMenu() {
        if let menuWindow, let parent = menuWindow.parent {
            parent.removeChildWindow(menuWindow)
        }
        menuWindow?.orderOutMenuTree()
        menuWindow = nil
    }

    private func showCustomDialog() {
        let content = CustomFieldDialogView(frame: .zero)
        content.configure(width: model.width, height: model.height, mines: model.mineCount)
        content.submit = { [weak self] width, height, mines in
            self?.model.newCustomGame(width: width, height: height, mines: mines)
            self?.requestResize?()
        }
        showDialog(title: "Custom Field", size: NSSize(width: 250, height: 178), content: content)
    }

    private func showBestTimes() {
        let defaults = UserDefaults.standard
        let beginner = defaults.object(forKey: "best.beginner") as? Int ?? 999
        let intermediate = defaults.object(forKey: "best.intermediate") as? Int ?? 999
        let expert = defaults.object(forKey: "best.expert") as? Int ?? 999
        let content = MessageDialogView(frame: .zero)
        content.lines = [
            "Beginner:       \(beginner) seconds",
            "Intermediate:   \(intermediate) seconds",
            "Expert:         \(expert) seconds"
        ]
        content.secondaryTitle = "Reset Scores"
        content.secondaryAction = { [weak self, weak content] in
            ["beginner", "intermediate", "expert"].forEach {
                defaults.removeObject(forKey: "best.\($0)")
            }
            content?.lines = [
                "Beginner:       999 seconds",
                "Intermediate:   999 seconds",
                "Expert:         999 seconds"
            ]
            content?.needsDisplay = true
            self?.dialogWindow?.makeKeyAndOrderFront(nil)
        }
        showDialog(title: "Fastest Mine Sweepers", size: NSSize(width: 292, height: 150), content: content)
    }

    private func showAbout() {
        let content = MessageDialogView(frame: .zero)
        content.lines = [
            "Minesweeper",
            "Windows 98 edition for macOS",
            "A pixel-faithful native recreation.",
            "tuxi · https://tuxi.dev"
        ]
        content.linkLineIndex = 3
        content.linkText = "https://tuxi.dev"
        content.linkURL = URL(string: "https://tuxi.dev")
        showDialog(title: "About Minesweeper", size: NSSize(width: 320, height: 162), content: content)
    }

    private func showDialog(title: String, size: NSSize, content: RetroDialogView) {
        dismissDialog()
        guard let parent = window else { return }
        let scale = interfaceScale
        let displaySize = NSSize(width: size.width * scale, height: size.height * scale)
        let dialog = RetroDialogWindow(title: title, size: size, scale: scale, content: content)
        content.closeHandler = { [weak self] in
            self?.dismissDialog()
        }
        let parentFrame = parent.frame
        let origin = NSPoint(
            x: floor(parentFrame.midX - displaySize.width / 2),
            y: floor(parentFrame.midY - displaySize.height / 2)
        )
        dialog.setFrameOrigin(origin)
        parent.addChildWindow(dialog, ordered: .above)
        dialogWindow = dialog
        dialog.makeKeyAndOrderFront(nil)
    }

    private func dismissDialog() {
        guard let dialog = dialogWindow else { return }
        dialog.orderOut(nil)
        let parent = dialog.parent
        DispatchQueue.main.async { [weak self, weak parent, dialog] in
            parent?.removeChildWindow(dialog)
            if self?.dialogWindow === dialog {
                self?.dialogWindow = nil
            }
        }
    }

    private func handleWin(difficulty: Difficulty, seconds: Int) {
        guard difficulty != .custom else { return }
        let key = "best.\(difficulty.rawValue)"
        let oldBest = UserDefaults.standard.object(forKey: key) as? Int ?? 999
        guard seconds < oldBest else { return }
        UserDefaults.standard.set(seconds, forKey: key)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            let content = MessageDialogView(frame: .zero)
            content.lines = [
                "You have the fastest time",
                "for \(difficulty.menuTitle.lowercased()) level:",
                "\(seconds) seconds"
            ]
            self?.showDialog(title: "Fastest Mine Sweeper", size: NSSize(width: 270, height: 142), content: content)
        }
    }
}
