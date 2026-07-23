import AppKit

@MainActor
final class RetroDialogWindow: NSWindow {
    init(title: String, size: NSSize, scale: CGFloat = 1, content: RetroDialogView) {
        let logicalFrame = NSRect(origin: .zero, size: size)
        let displayFrame = NSRect(
            origin: .zero,
            size: NSSize(width: size.width * scale, height: size.height * scale)
        )
        super.init(contentRect: displayFrame, styleMask: .borderless, backing: .buffered, defer: false)
        content.titleText = title
        contentView = content
        content.frame = displayFrame
        content.bounds = logicalFrame
        isOpaque = true
        backgroundColor = RetroPalette.face
        hasShadow = true
        level = .modalPanel
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { true }
}

@MainActor
class RetroDialogView: NSView {
    var titleText = ""
    var closeHandler: (() -> Void)?
    private var closePressed = false

    override var isFlipped: Bool { true }
    var titleRect: NSRect { NSRect(x: 3, y: 3, width: bounds.width - 6, height: 18) }
    var closeRect: NSRect { NSRect(x: bounds.width - 21, y: 5, width: 16, height: 14) }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        NSGraphicsContext.current?.cgContext.setAllowsAntialiasing(false)
        drawBevel(bounds, style: .raised, thickness: 3)
        let gradient = NSGradient(starting: RetroPalette.titleStart, ending: RetroPalette.titleEnd)
        gradient?.draw(in: titleRect, angle: 0)
        drawRetroText(titleText, at: NSPoint(x: 7, y: 5), color: .white, size: 11, bold: true)
        drawWindowControl(closeRect, kind: "close", pressed: closePressed)
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if closeRect.contains(point) {
            closePressed = true
            needsDisplay = true
        } else if titleRect.contains(point) {
            window?.performDrag(with: event)
        }
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if closePressed {
            closePressed = false
            needsDisplay = true
            if closeRect.contains(point) {
                closeHandler?()
            }
        }
    }

    func drawButton(_ title: String, rect: NSRect, pressed: Bool = false, enabled: Bool = true) {
        drawRaisedButton(rect, pressed: pressed, enabled: enabled)
        drawCenteredRetroText(title, in: rect.offsetBy(dx: pressed ? 1 : 0, dy: pressed ? 1 : 0), color: enabled ? .black : RetroPalette.shadow, size: 11)
    }
}

@MainActor
final class CustomFieldDialogView: RetroDialogView {
    var initialWidth = 8
    var initialHeight = 8
    var initialMines = 10
    var submit: ((Int, Int, Int) -> Void)?

    private var values = ["8", "8", "10"]
    private var selectedField = 0
    private var pressedButton: String?

    private let fieldRects = [
        NSRect(x: 128, y: 42, width: 64, height: 22),
        NSRect(x: 128, y: 70, width: 64, height: 22),
        NSRect(x: 128, y: 98, width: 64, height: 22)
    ]
    private let okRect = NSRect(x: 44, y: 139, width: 72, height: 25)
    private let cancelRect = NSRect(x: 132, y: 139, width: 72, height: 25)

    func configure(width: Int, height: Int, mines: Int) {
        values = ["\(height)", "\(width)", "\(mines)"]
        selectedField = 0
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawRetroText("Height:", at: NSPoint(x: 46, y: 44), size: 11)
        drawRetroText("Width:", at: NSPoint(x: 46, y: 72), size: 11)
        drawRetroText("Mines:", at: NSPoint(x: 46, y: 100), size: 11)

        for index in fieldRects.indices {
            let rect = fieldRects[index]
            drawBevel(rect, style: .sunken, thickness: 2, fill: .white)
            pixelFill(rect.insetBy(dx: 2, dy: 2), .white)
            drawRetroText(values[index], at: NSPoint(x: rect.minX + 5, y: rect.minY + 3), size: 11)
            if index == selectedField {
                pixelFill(NSRect(x: rect.minX + 4, y: rect.maxY - 5, width: max(2, CGFloat(values[index].count * 7)), height: 1), .black)
            }
        }
        drawButton("OK", rect: okRect, pressed: pressedButton == "ok")
        drawButton("Cancel", rect: cancelRect, pressed: pressedButton == "cancel")
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        for index in fieldRects.indices where fieldRects[index].contains(point) {
            selectedField = index
            needsDisplay = true
            return
        }
        if okRect.contains(point) {
            pressedButton = "ok"
            needsDisplay = true
            return
        }
        if cancelRect.contains(point) {
            pressedButton = "cancel"
            needsDisplay = true
            return
        }
        super.mouseDown(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let button = pressedButton
        pressedButton = nil
        needsDisplay = true
        if button == "ok", okRect.contains(point) {
            apply()
        } else if button == "cancel", cancelRect.contains(point) {
            closeHandler?()
        } else {
            super.mouseUp(with: event)
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            closeHandler?()
            return
        }
        if event.keyCode == 36 || event.keyCode == 76 {
            apply()
            return
        }
        if event.keyCode == 48 {
            selectedField = (selectedField + 1) % values.count
            needsDisplay = true
            return
        }
        if event.keyCode == 51 {
            if !values[selectedField].isEmpty {
                values[selectedField].removeLast()
                needsDisplay = true
            }
            return
        }
        if let characters = event.charactersIgnoringModifiers {
            let digits = characters.filter(\.isNumber)
            if !digits.isEmpty, values[selectedField].count < 3 {
                if values[selectedField] == "0" {
                    values[selectedField] = ""
                }
                values[selectedField].append(contentsOf: digits.prefix(3 - values[selectedField].count))
                needsDisplay = true
                return
            }
        }
        super.keyDown(with: event)
    }

    private func apply() {
        let height = Int(values[0]) ?? 8
        let width = Int(values[1]) ?? 8
        let mines = Int(values[2]) ?? 10
        closeHandler?()
        submit?(width, height, mines)
    }
}

@MainActor
final class MessageDialogView: RetroDialogView {
    var lines: [String] = []
    var buttonTitle = "OK"
    var secondaryTitle: String?
    var secondaryAction: (() -> Void)?
    var linkLineIndex: Int?
    var linkText: String?
    var linkURL: URL?
    private var pressedButton: String?

    private var okRect: NSRect {
        NSRect(x: bounds.midX - 38, y: bounds.height - 40, width: 76, height: 25)
    }
    private var secondaryRect: NSRect {
        NSRect(x: bounds.midX - 84, y: bounds.height - 40, width: 76, height: 25)
    }
    private var shiftedOKRect: NSRect {
        NSRect(x: bounds.midX + 8, y: bounds.height - 40, width: 76, height: 25)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        for (index, line) in lines.enumerated() {
            if index == linkLineIndex, let layout = linkLayout(at: index), let linkText {
                drawRetroText(layout.prefix, at: layout.prefixOrigin, size: 11)
                drawPixelLink(linkText, at: layout.linkRect.origin)
                if !layout.suffix.isEmpty {
                    drawRetroText(layout.suffix, at: layout.suffixOrigin, size: 11)
                }
            } else {
                drawRetroText(line, at: lineRect(at: index).origin, size: 11)
            }
        }
        if let secondaryTitle {
            drawButton(secondaryTitle, rect: secondaryRect, pressed: pressedButton == "secondary")
            drawButton(buttonTitle, rect: shiftedOKRect, pressed: pressedButton == "ok")
        } else {
            drawButton(buttonTitle, rect: okRect, pressed: pressedButton == "ok")
        }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if let linkRect, linkRect.contains(point) {
            pressedButton = "link"
            return
        }
        let activeOK = secondaryTitle == nil ? okRect : shiftedOKRect
        if activeOK.contains(point) {
            pressedButton = "ok"
            needsDisplay = true
            return
        }
        if secondaryTitle != nil, secondaryRect.contains(point) {
            pressedButton = "secondary"
            needsDisplay = true
            return
        }
        super.mouseDown(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let button = pressedButton
        pressedButton = nil
        needsDisplay = true
        if button == "link", let linkRect, linkRect.contains(point), let linkURL {
            NSWorkspace.shared.open(linkURL)
            return
        }
        let activeOK = secondaryTitle == nil ? okRect : shiftedOKRect
        if button == "ok", activeOK.contains(point) {
            closeHandler?()
        } else if button == "secondary", secondaryRect.contains(point) {
            secondaryAction?()
        } else {
            super.mouseUp(with: event)
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 || event.keyCode == 53 {
            closeHandler?()
        } else {
            super.keyDown(with: event)
        }
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        if let linkRect {
            addCursorRect(linkRect, cursor: .pointingHand)
        }
    }

    private var linkRect: NSRect? {
        linkTextRect?.insetBy(dx: -2, dy: -2)
    }

    private var linkTextRect: NSRect? {
        guard let linkLineIndex else { return nil }
        return linkLayout(at: linkLineIndex)?.linkRect
    }

    private func drawPixelLink(_ text: String, at point: NSPoint) {
        let textSize = retroTextSize(text, size: 11)
        drawRetroText(text, at: point, color: RetroPalette.titleStart, size: 11)
        pixelFill(
            NSRect(x: point.x, y: point.y + textSize.height, width: textSize.width, height: 1),
            RetroPalette.titleStart
        )
    }

    private func linkLayout(at index: Int) -> (
        prefix: String,
        prefixOrigin: NSPoint,
        linkRect: NSRect,
        suffix: String,
        suffixOrigin: NSPoint
    )? {
        guard
            lines.indices.contains(index),
            let linkText,
            let range = lines[index].range(of: linkText)
        else {
            return nil
        }
        let line = lines[index]
        let prefix = String(line[..<range.lowerBound])
        let suffix = String(line[range.upperBound...])
        let prefixSize = retroTextSize(prefix, size: 11)
        let suffixSize = retroTextSize(suffix, size: 11)
        let linkSize = retroTextSize(linkText, size: 11)
        let leadingGap: CGFloat = prefix.isEmpty ? 0 : 2
        let trailingGap: CGFloat = suffix.isEmpty ? 0 : 2
        let totalWidth = prefixSize.width + leadingGap + linkSize.width
            + trailingGap + suffixSize.width
        let row = lineRow(at: index)
        let startX = floor(row.midX - totalWidth / 2)
        let linkRect = NSRect(
            x: startX + prefixSize.width + leadingGap,
            y: floor(row.midY - linkSize.height / 2),
            width: linkSize.width,
            height: linkSize.height
        )
        return (
            prefix: prefix,
            prefixOrigin: NSPoint(
                x: startX,
                y: floor(row.midY - prefixSize.height / 2)
            ),
            linkRect: linkRect,
            suffix: suffix,
            suffixOrigin: NSPoint(
                x: linkRect.maxX + trailingGap,
                y: floor(row.midY - suffixSize.height / 2)
            )
        )
    }

    private func lineRect(at index: Int) -> NSRect {
        let textSize = retroTextSize(lines[index], size: 11)
        let row = lineRow(at: index)
        return NSRect(
            x: floor(row.midX - textSize.width / 2),
            y: floor(row.midY - textSize.height / 2),
            width: textSize.width,
            height: textSize.height
        )
    }

    private func lineRow(at index: Int) -> NSRect {
        NSRect(
            x: 16,
            y: 35 + CGFloat(index * 20),
            width: bounds.width - 32,
            height: 18
        )
    }
}
