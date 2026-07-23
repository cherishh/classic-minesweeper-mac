import AppKit

struct RetroMenuItem {
    let title: String
    var shortcut: String = ""
    var checked = false
    var enabled = true
    var separator = false
    let action: (() -> Void)?

    static func line() -> RetroMenuItem {
        RetroMenuItem(title: "", enabled: false, separator: true, action: nil)
    }
}

@MainActor
final class RetroMenuWindow: NSWindow {
    init(items: [RetroMenuItem], width: CGFloat = 190, onDismiss: @escaping () -> Void) {
        let itemHeight: CGFloat = 20
        let separatorHeight: CGFloat = 8
        let height = items.reduce(CGFloat(4)) {
            $0 + ($1.separator ? separatorHeight : itemHeight)
        }
        let view = RetroMenuView(
            frame: NSRect(x: 0, y: 0, width: width, height: height),
            items: items,
            onDismiss: onDismiss
        )
        super.init(
            contentRect: view.bounds,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        isOpaque = true
        backgroundColor = RetroPalette.face
        hasShadow = true
        level = .popUpMenu
        contentView = view
        acceptsMouseMovedEvents = true
        collectionBehavior = [.transient, .ignoresCycle]
    }

    override var canBecomeKey: Bool { true }
}

@MainActor
final class RetroMenuView: NSView {
    private let items: [RetroMenuItem]
    private let onDismiss: () -> Void
    private var hoveredIndex: Int?

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
            y += 20
        }
    }

    override func mouseMoved(with event: NSEvent) {
        hoveredIndex = index(at: convert(event.locationInWindow, from: nil))
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        hoveredIndex = nil
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let index = index(at: point), items[index].enabled, !items[index].separator else {
            dismiss()
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
        window?.orderOut(nil)
        let dismissHandler = onDismiss
        DispatchQueue.main.async {
            dismissHandler()
        }
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
