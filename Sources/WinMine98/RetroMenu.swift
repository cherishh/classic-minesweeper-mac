import AppKit

struct RetroMenuItem {
    let title: String
    let shortcut: String
    let checked: Bool
    let enabled: Bool
    let separator: Bool
    let submenu: [RetroMenuItem]?
    let action: (() -> Void)?

    init(
        title: String,
        shortcut: String = "",
        checked: Bool = false,
        enabled: Bool = true,
        separator: Bool = false,
        submenu: [RetroMenuItem]? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.shortcut = shortcut
        self.checked = checked
        self.enabled = enabled
        self.separator = separator
        self.submenu = submenu
        self.action = action
    }

    static func line() -> RetroMenuItem {
        RetroMenuItem(title: "", enabled: false, separator: true)
    }
}

@MainActor
final class RetroMenuWindow: NSWindow {
    private let interfaceScale: CGFloat
    private let dismissHandler: () -> Void
    private var submenuWindow: RetroMenuWindow?

    init(
        items: [RetroMenuItem],
        width: CGFloat = 190,
        scale: CGFloat = 1,
        onDismiss: @escaping () -> Void
    ) {
        interfaceScale = scale
        dismissHandler = onDismiss
        let itemHeight: CGFloat = 20
        let separatorHeight: CGFloat = 8
        let height = items.reduce(CGFloat(4)) {
            $0 + ($1.separator ? separatorHeight : itemHeight)
        }
        let logicalFrame = NSRect(x: 0, y: 0, width: width, height: height)
        let displayFrame = NSRect(
            x: 0,
            y: 0,
            width: width * scale,
            height: height * scale
        )
        let view = RetroMenuView(
            frame: displayFrame,
            items: items,
            onDismiss: {}
        )
        super.init(
            contentRect: displayFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        contentView = view
        view.frame = displayFrame
        view.bounds = logicalFrame
        view.onDismiss = { [weak self] in
            self?.dismissAndNotify()
        }
        view.onShowSubmenu = { [weak self] items, itemRect in
            self?.showSubmenu(items: items, beside: itemRect)
        }
        view.onHideSubmenu = { [weak self] in
            self?.closeSubmenu()
        }
        isOpaque = true
        backgroundColor = RetroPalette.face
        hasShadow = true
        level = .popUpMenu
        acceptsMouseMovedEvents = true
        collectionBehavior = [.transient, .ignoresCycle]
    }

    override var canBecomeKey: Bool { true }

    func orderOutMenuTree() {
        closeSubmenu()
        orderOut(nil)
    }

    private func dismissAndNotify() {
        orderOutMenuTree()
        let handler = dismissHandler
        DispatchQueue.main.async {
            handler()
        }
    }

    private func showSubmenu(items: [RetroMenuItem], beside itemRect: NSRect) {
        closeSubmenu()
        let submenuWidth = items.reduce(CGFloat(116)) {
            max($0, retroTextSize($1.title, size: 11).width + 40)
        }
        let submenu = RetroMenuWindow(
            items: items,
            width: submenuWidth,
            scale: interfaceScale
        ) { [weak self] in
            self?.dismissAndNotify()
        }
        let topLeft = NSPoint(
            x: frame.maxX - 2 * interfaceScale,
            y: frame.maxY - itemRect.minY * interfaceScale
        )
        submenu.setFrameTopLeftPoint(topLeft)
        addChildWindow(submenu, ordered: .above)
        submenuWindow = submenu
        submenu.makeKeyAndOrderFront(nil)
    }

    private func closeSubmenu() {
        guard let submenuWindow else { return }
        removeChildWindow(submenuWindow)
        submenuWindow.orderOutMenuTree()
        self.submenuWindow = nil
    }
}

@MainActor
final class RetroMenuView: NSView {
    private let items: [RetroMenuItem]
    private var hoveredIndex: Int?
    var onDismiss: () -> Void
    var onShowSubmenu: (([RetroMenuItem], NSRect) -> Void)?
    var onHideSubmenu: (() -> Void)?

    override var isFlipped: Bool { true }

    init(frame: NSRect, items: [RetroMenuItem], onDismiss: @escaping () -> Void) {
        self.items = items
        self.onDismiss = onDismiss
        super.init(frame: frame)
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited],
            owner: self
        ))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let context = NSGraphicsContext.current?.cgContext
        context?.setAllowsAntialiasing(false)
        context?.setShouldAntialias(false)
        context?.setShouldSmoothFonts(false)
        drawBevel(bounds, style: .raised, thickness: 2)

        var y: CGFloat = 2
        for (index, item) in items.enumerated() {
            if item.separator {
                pixelFill(NSRect(x: 2, y: y + 3, width: bounds.width - 4, height: 1), RetroPalette.shadow)
                pixelFill(NSRect(x: 2, y: y + 4, width: bounds.width - 4, height: 1), .white)
                y += 8
                continue
            }

            let itemRect = NSRect(x: 2, y: y, width: bounds.width - 4, height: 20)
            let highlighted = hoveredIndex == index && item.enabled
            if highlighted {
                pixelFill(itemRect, RetroPalette.titleStart)
            }
            if item.checked {
                drawRetroText("✓", at: NSPoint(x: 7, y: y + 3), color: highlighted ? .white : .black, size: 11)
            }
            drawRetroText(
                item.title,
                at: NSPoint(x: 25, y: y + 3),
                color: item.enabled ? (highlighted ? .white : .black) : RetroPalette.shadow,
                size: 11
            )
            if !item.shortcut.isEmpty {
                let width = retroTextSize(item.shortcut, size: 11).width
                drawRetroText(
                    item.shortcut,
                    at: NSPoint(x: bounds.width - width - 10, y: y + 3),
                    color: item.enabled ? (highlighted ? .white : .black) : RetroPalette.shadow,
                    size: 11
                )
            }
            if item.submenu != nil {
                let arrowColor = item.enabled
                    ? (highlighted ? NSColor.white : NSColor.black)
                    : RetroPalette.shadow
                let arrowX = bounds.width - 9
                for offset in 0..<4 {
                    pixelFill(
                        NSRect(
                            x: arrowX + CGFloat(offset),
                            y: y + 7 + CGFloat(offset),
                            width: 1,
                            height: CGFloat(7 - offset * 2)
                        ),
                        arrowColor
                    )
                }
            }
            y += 20
        }
    }

    override func mouseMoved(with event: NSEvent) {
        let newIndex = index(at: convert(event.locationInWindow, from: nil))
        guard newIndex != hoveredIndex else { return }
        hoveredIndex = newIndex
        updateSubmenu()
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        if let hoveredIndex, items[hoveredIndex].submenu != nil {
            return
        }
        hoveredIndex = nil
        onHideSubmenu?()
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let index = index(at: point), items[index].enabled, !items[index].separator else {
            dismiss()
            return
        }
        if let submenu = items[index].submenu {
            hoveredIndex = index
            onShowSubmenu?(submenu, itemRect(at: index))
            needsDisplay = true
            return
        }
        let action = items[index].action
        dismiss()
        action?()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            dismiss()
        } else {
            super.keyDown(with: event)
        }
    }

    private func dismiss() {
        let dismissHandler = onDismiss
        DispatchQueue.main.async {
            dismissHandler()
        }
    }

    private func updateSubmenu() {
        guard
            let hoveredIndex,
            let submenu = items[hoveredIndex].submenu
        else {
            onHideSubmenu?()
            return
        }
        onShowSubmenu?(submenu, itemRect(at: hoveredIndex))
    }

    private func itemRect(at targetIndex: Int) -> NSRect {
        var y: CGFloat = 2
        for (index, item) in items.enumerated() {
            let height: CGFloat = item.separator ? 8 : 20
            if index == targetIndex {
                return NSRect(x: 2, y: y, width: bounds.width - 4, height: height)
            }
            y += height
        }
        return .zero
    }

    private func index(at point: NSPoint) -> Int? {
        var y: CGFloat = 2
        for (index, item) in items.enumerated() {
            let height: CGFloat = item.separator ? 8 : 20
            if point.y >= y, point.y < y + height {
                return item.separator ? nil : index
            }
            y += height
        }
        return nil
    }
}
