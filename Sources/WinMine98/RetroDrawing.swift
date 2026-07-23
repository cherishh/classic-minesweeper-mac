import AppKit
import CoreText

enum RetroPalette {
    private static func rgb(_ red: Int, _ green: Int, _ blue: Int) -> NSColor {
        NSColor(
            srgbRed: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: 1
        )
    }

    static let face = rgb(196, 196, 196)
    static let light = rgb(240, 240, 240)
    static let highlight = rgb(224, 224, 224)
    static let shadow = rgb(126, 126, 126)
    static let darkShadow = rgb(37, 37, 37)
    static let titleStart = rgb(2, 0, 128)
    static let titleEnd = titleStart
    static let disabled = NSColor(calibratedWhite: 0.45, alpha: 1)
    static let digitOn = rgb(236, 51, 36)
    static let digitOff = rgb(128, 0, 64)
}

enum BevelStyle {
    case raised
    case sunken
}

func pixelFill(_ rect: NSRect, _ color: NSColor) {
    color.setFill()
    NSBezierPath(rect: rect.integral).fill()
}

private let retroAssetCache = NSCache<NSString, NSImage>()
private let retroTextCache = NSCache<NSString, NSImage>()

private func drawPixelImage(_ image: NSImage, in rect: NSRect) {
    let context = NSGraphicsContext.current?.cgContext
    context?.setAllowsAntialiasing(false)
    context?.setShouldAntialias(false)
    context?.interpolationQuality = .none
    image.draw(
        in: rect.integral,
        from: NSRect(origin: .zero, size: image.size),
        operation: .sourceOver,
        fraction: 1,
        respectFlipped: true,
        hints: [.interpolation: NSImageInterpolation.none]
    )
}

@discardableResult
func drawPixelAsset(_ name: String, in rect: NSRect) -> Bool {
    let key = name as NSString
    let image: NSImage
    if let cached = retroAssetCache.object(forKey: key) {
        image = cached
    } else {
        guard
            let url = Bundle.main.url(
                forResource: name,
                withExtension: "png",
                subdirectory: "RetroAssets"
            ),
            let loaded = NSImage(contentsOf: url)
        else {
            return false
        }
        retroAssetCache.setObject(loaded, forKey: key)
        image = loaded
    }

    drawPixelImage(image, in: rect)
    return true
}

func drawBevel(_ rect: NSRect, style: BevelStyle, thickness: CGFloat = 2, fill: NSColor = RetroPalette.face) {
    pixelFill(rect, fill)
    for inset in 0..<Int(thickness) {
        let amount = CGFloat(inset)
        let r = rect.insetBy(dx: amount, dy: amount)
        let upper = style == .raised
            ? (inset == 0 ? RetroPalette.light : RetroPalette.highlight)
            : (inset == 0 ? RetroPalette.darkShadow : RetroPalette.shadow)
        let lower = style == .raised
            ? (inset == 0 ? RetroPalette.darkShadow : RetroPalette.shadow)
            : (inset == 0 ? RetroPalette.light : RetroPalette.highlight)

        pixelFill(NSRect(x: r.minX, y: r.minY, width: r.width, height: 1), upper)
        pixelFill(NSRect(x: r.minX, y: r.minY, width: 1, height: r.height), upper)
        pixelFill(NSRect(x: r.minX, y: r.maxY - 1, width: r.width, height: 1), lower)
        pixelFill(NSRect(x: r.maxX - 1, y: r.minY, width: 1, height: r.height), lower)
    }
}

func retroFont(size: CGFloat = 12, bold: Bool = false) -> NSFont {
    let name = bold ? "MS-Sans-Serif-Bold" : "MS-Sans-Serif"
    return NSFont(name: name, size: size)
        ?? NSFont(name: bold ? "Geneva-Bold" : "Geneva", size: size)
        ?? (bold ? NSFont.boldSystemFont(ofSize: size) : NSFont.systemFont(ofSize: size))
}

private func retroTextCacheKey(
    _ text: String,
    color: NSColor,
    size: CGFloat,
    bold: Bool
) -> NSString {
    let rgb = color.usingColorSpace(.deviceRGB) ?? color
    return String(
        format: "%@|%.2f|%d|%.4f|%.4f|%.4f|%.4f",
        text,
        size,
        bold ? 1 : 0,
        rgb.redComponent,
        rgb.greenComponent,
        rgb.blueComponent,
        rgb.alphaComponent
    ) as NSString
}

private func retroTextImage(
    _ text: String,
    color: NSColor,
    size: CGFloat,
    bold: Bool
) -> NSImage {
    let key = retroTextCacheKey(text, color: color, size: size, bold: bold)
    if let cached = retroTextCache.object(forKey: key) {
        return cached
    }

    let attributes: [NSAttributedString.Key: Any] = [
        .font: retroFont(size: size, bold: bold),
        .foregroundColor: color
    ]
    let line = CTLineCreateWithAttributedString(
        NSAttributedString(string: text, attributes: attributes)
    )
    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    var leading: CGFloat = 0
    let measuredWidth = CTLineGetTypographicBounds(
        line,
        &ascent,
        &descent,
        &leading
    )
    let pixelAscent = ceil(ascent)
    let pixelDescent = ceil(descent)
    let pixelWidth = max(1, Int(ceil(measuredWidth)))
    let pixelHeight = max(1, Int(pixelAscent + pixelDescent + ceil(leading)))
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let bitmap = CGContext(
        data: nil,
        width: pixelWidth,
        height: pixelHeight,
        bitsPerComponent: 8,
        bytesPerRow: pixelWidth * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        return NSImage(size: NSSize(width: pixelWidth, height: pixelHeight))
    }

    bitmap.setAllowsAntialiasing(false)
    bitmap.setShouldAntialias(false)
    bitmap.setShouldSmoothFonts(false)
    bitmap.setShouldSubpixelPositionFonts(false)
    bitmap.setShouldSubpixelQuantizeFonts(false)
    bitmap.textMatrix = .identity
    bitmap.textPosition = CGPoint(x: 0, y: pixelDescent)
    CTLineDraw(line, bitmap)

    guard let cgImage = bitmap.makeImage() else {
        return NSImage(size: NSSize(width: pixelWidth, height: pixelHeight))
    }
    let image = NSImage(
        cgImage: cgImage,
        size: NSSize(width: pixelWidth, height: pixelHeight)
    )
    retroTextCache.setObject(image, forKey: key)
    return image
}

func retroTextSize(
    _ text: String,
    size: CGFloat = 12,
    bold: Bool = false
) -> NSSize {
    retroTextImage(text, color: .black, size: size, bold: bold).size
}

func drawRetroText(
    _ text: String,
    at point: NSPoint,
    color: NSColor = .black,
    size: CGFloat = 12,
    bold: Bool = false
) {
    let image = retroTextImage(text, color: color, size: size, bold: bold)
    drawPixelImage(
        image,
        in: NSRect(origin: point, size: image.size)
    )
}

func drawCenteredRetroText(
    _ text: String,
    in rect: NSRect,
    color: NSColor = .black,
    size: CGFloat = 12,
    bold: Bool = false
) {
    let image = retroTextImage(text, color: color, size: size, bold: bold)
    let measured = image.size
    let point = NSPoint(
        x: floor(rect.midX - measured.width / 2),
        y: floor(rect.midY - measured.height / 2)
    )
    drawPixelImage(image, in: NSRect(origin: point, size: measured))
}

func drawRaisedButton(_ rect: NSRect, pressed: Bool, enabled: Bool = true) {
    drawBevel(rect, style: pressed ? .sunken : .raised, thickness: 2)
    if !enabled {
        pixelFill(rect.insetBy(dx: 2, dy: 2), RetroPalette.face)
    }
}

func drawTitleBarIcon(in rect: NSRect) {
    let ox = floor(rect.minX)
    let oy = floor(rect.minY)
    pixelFill(NSRect(x: ox + 3, y: oy + 3, width: 10, height: 10), .black)
    pixelFill(NSRect(x: ox + 1, y: oy + 6, width: 14, height: 4), .black)
    pixelFill(NSRect(x: ox + 6, y: oy + 1, width: 4, height: 14), .black)
    pixelFill(NSRect(x: ox + 5, y: oy + 4, width: 6, height: 6), RetroPalette.shadow)
    pixelFill(NSRect(x: ox + 6, y: oy + 5, width: 2, height: 2), .white)
}

func drawWindowControl(_ rect: NSRect, kind: String, pressed: Bool, enabled: Bool = true) {
    drawClassicCaptionButton(rect, pressed: pressed)
    let offset: CGFloat = pressed ? 1 : 0

    switch kind {
    case "min":
        pixelFill(
            NSRect(
                x: rect.minX + 4 + offset,
                y: rect.minY + 9 + offset,
                width: 6,
                height: 2
            ),
            enabled ? .black : NSColor(calibratedWhite: 0.5, alpha: 1)
        )
    case "max":
        let x = rect.minX + 2 + offset
        let y = rect.minY + 2 + offset
        if !enabled {
            drawMaximizeGlyph(
                at: NSPoint(x: x + 1, y: y + 1),
                color: .white
            )
        }
        drawMaximizeGlyph(
            at: NSPoint(x: x, y: y),
            color: enabled ? .black : NSColor(calibratedWhite: 0.5, alpha: 1)
        )
    case "close":
        drawCloseGlyph(
            at: NSPoint(
                x: rect.minX + 3 + offset,
                y: rect.minY + 3 + offset
            ),
            color: enabled ? .black : NSColor(calibratedWhite: 0.5, alpha: 1)
        )
    default:
        break
    }
}

private func drawClassicCaptionButton(_ rect: NSRect, pressed: Bool) {
    pixelFill(rect, NSColor(calibratedWhite: 0.75, alpha: 1))
    if pressed {
        pixelFill(NSRect(x: rect.minX, y: rect.minY, width: rect.width, height: 1), .black)
        pixelFill(NSRect(x: rect.minX, y: rect.minY, width: 1, height: rect.height), .black)
        pixelFill(
            NSRect(x: rect.minX + 1, y: rect.minY + 1, width: rect.width - 2, height: 1),
            NSColor(calibratedWhite: 0.5, alpha: 1)
        )
        pixelFill(
            NSRect(x: rect.minX + 1, y: rect.minY + 1, width: 1, height: rect.height - 2),
            NSColor(calibratedWhite: 0.5, alpha: 1)
        )
        return
    }

    pixelFill(NSRect(x: rect.minX, y: rect.minY, width: rect.width, height: 1), .white)
    pixelFill(NSRect(x: rect.minX, y: rect.minY, width: 1, height: rect.height), .white)
    pixelFill(
        NSRect(x: rect.minX + 1, y: rect.minY + 1, width: rect.width - 2, height: 1),
        NSColor(calibratedWhite: 0.875, alpha: 1)
    )
    pixelFill(
        NSRect(x: rect.minX + 1, y: rect.minY + 1, width: 1, height: rect.height - 2),
        NSColor(calibratedWhite: 0.875, alpha: 1)
    )
    pixelFill(
        NSRect(x: rect.minX, y: rect.maxY - 1, width: rect.width, height: 1),
        .black
    )
    pixelFill(
        NSRect(x: rect.maxX - 1, y: rect.minY, width: 1, height: rect.height),
        .black
    )
    pixelFill(
        NSRect(x: rect.minX + 1, y: rect.maxY - 2, width: rect.width - 2, height: 1),
        NSColor(calibratedWhite: 0.5, alpha: 1)
    )
    pixelFill(
        NSRect(x: rect.maxX - 2, y: rect.minY + 1, width: 1, height: rect.height - 2),
        NSColor(calibratedWhite: 0.5, alpha: 1)
    )
}

private func drawMaximizeGlyph(at point: NSPoint, color: NSColor) {
    pixelFill(NSRect(x: point.x, y: point.y, width: 9, height: 2), color)
    pixelFill(NSRect(x: point.x, y: point.y + 2, width: 1, height: 7), color)
    pixelFill(NSRect(x: point.x + 8, y: point.y + 2, width: 1, height: 7), color)
    pixelFill(NSRect(x: point.x, y: point.y + 8, width: 9, height: 1), color)
}

private func drawCloseGlyph(at point: NSPoint, color: NSColor) {
    let rows = [
        "##....##",
        ".##..##.",
        "..####..",
        "...##...",
        "..####..",
        ".##..##.",
        "##....##"
    ]
    for (row, pixels) in rows.enumerated() {
        for (column, pixel) in pixels.enumerated() where pixel == "#" {
            pixelFill(
                NSRect(
                    x: point.x + CGFloat(column),
                    y: point.y + CGFloat(row),
                    width: 1,
                    height: 1
                ),
                color
            )
        }
    }
}

private let sevenSegments: [Int: Set<Int>] = [
    0: [0, 1, 2, 4, 5, 6],
    1: [2, 5],
    2: [0, 2, 3, 4, 6],
    3: [0, 2, 3, 5, 6],
    4: [1, 2, 3, 5],
    5: [0, 1, 3, 5, 6],
    6: [0, 1, 3, 4, 5, 6],
    7: [0, 2, 5],
    8: [0, 1, 2, 3, 4, 5, 6],
    9: [0, 1, 2, 3, 5, 6]
]

func drawSegmentDisplay(_ value: Int, in rect: NSRect) {
    drawBevel(rect, style: .sunken, thickness: 2, fill: .black)
    let display = rect.insetBy(dx: 2, dy: 2)
    pixelFill(display, .black)

    let clamped = min(999, max(-99, value))
    let text: [Int?]
    if clamped < 0 {
        let magnitude = abs(clamped)
        text = [nil, magnitude / 10, magnitude % 10]
    } else {
        text = [clamped / 100, (clamped / 10) % 10, clamped % 10]
    }

    let context = NSGraphicsContext.current
    context?.saveGraphicsState()
    NSBezierPath(rect: display).addClip()
    for (position, digit) in text.enumerated() {
        let origin = NSPoint(
            x: display.minX + CGFloat(position * 12),
            y: display.minY
        )
        if digit == nil {
            drawSegment(3, at: origin, active: true)
        } else if let digit {
            let active = sevenSegments[digit] ?? []
            for segment in 0..<7 {
                drawSegment(segment, at: origin, active: active.contains(segment))
            }
        }
    }
    context?.restoreGraphicsState()
}

private func drawSegment(_ segment: Int, at origin: NSPoint, active: Bool) {
    let x = origin.x
    let y = origin.y
    let points: [NSPoint]
    switch segment {
    case 0:
        points = [
            NSPoint(x: x + 2, y: y + 1), NSPoint(x: x + 3, y: y),
            NSPoint(x: x + 8, y: y), NSPoint(x: x + 9, y: y + 1),
            NSPoint(x: x + 8, y: y + 3), NSPoint(x: x + 3, y: y + 3)
        ]
    case 1:
        points = [
            NSPoint(x: x + 1, y: y + 3), NSPoint(x: x + 2, y: y + 2),
            NSPoint(x: x + 3, y: y + 3), NSPoint(x: x + 3, y: y + 9),
            NSPoint(x: x + 2, y: y + 10), NSPoint(x: x + 1, y: y + 9)
        ]
    case 2:
        points = [
            NSPoint(x: x + 8, y: y + 3), NSPoint(x: x + 9, y: y + 2),
            NSPoint(x: x + 10, y: y + 3), NSPoint(x: x + 10, y: y + 9),
            NSPoint(x: x + 9, y: y + 10), NSPoint(x: x + 8, y: y + 9)
        ]
    case 3:
        points = [
            NSPoint(x: x + 2, y: y + 10), NSPoint(x: x + 3, y: y + 9),
            NSPoint(x: x + 8, y: y + 9), NSPoint(x: x + 9, y: y + 10),
            NSPoint(x: x + 8, y: y + 12), NSPoint(x: x + 3, y: y + 12)
        ]
    case 4:
        points = [
            NSPoint(x: x + 1, y: y + 12), NSPoint(x: x + 2, y: y + 11),
            NSPoint(x: x + 3, y: y + 12), NSPoint(x: x + 3, y: y + 18),
            NSPoint(x: x + 2, y: y + 19), NSPoint(x: x + 1, y: y + 18)
        ]
    case 5:
        points = [
            NSPoint(x: x + 8, y: y + 12), NSPoint(x: x + 9, y: y + 11),
            NSPoint(x: x + 10, y: y + 12), NSPoint(x: x + 10, y: y + 18),
            NSPoint(x: x + 9, y: y + 19), NSPoint(x: x + 8, y: y + 18)
        ]
    default:
        points = [
            NSPoint(x: x + 2, y: y + 19), NSPoint(x: x + 3, y: y + 18),
            NSPoint(x: x + 8, y: y + 18), NSPoint(x: x + 9, y: y + 19),
            NSPoint(x: x + 8, y: y + 21), NSPoint(x: x + 3, y: y + 21)
        ]
    }
    let path = NSBezierPath()
    path.move(to: points[0])
    for point in points.dropFirst() {
        path.line(to: point)
    }
    path.close()
    if active {
        RetroPalette.digitOn.setFill()
        path.fill()
    } else {
        let context = NSGraphicsContext.current
        context?.saveGraphicsState()
        path.addClip()
        for py in Int(floor(y))...Int(ceil(y + 21)) {
            for px in Int(floor(x))...Int(ceil(x + 10)) where (px + py) % 2 == 0 {
                pixelFill(
                    NSRect(x: CGFloat(px), y: CGFloat(py), width: 1, height: 1),
                    RetroPalette.digitOff
                )
            }
        }
        context?.restoreGraphicsState()
    }
}

func drawSmiley(in rect: NSRect, expression: String, pressed: Bool) {
    drawRaisedButton(rect, pressed: pressed)
    let cx = floor(rect.midX)
    let cy = floor(rect.midY)
    let yellow = NSColor(calibratedRed: 1, green: 1, blue: 0, alpha: 1)

    pixelFill(NSRect(x: cx - 5, y: cy - 7, width: 10, height: 1), .black)
    pixelFill(NSRect(x: cx - 7, y: cy - 5, width: 1, height: 10), .black)
    pixelFill(NSRect(x: cx + 6, y: cy - 5, width: 1, height: 10), .black)
    pixelFill(NSRect(x: cx - 5, y: cy + 6, width: 10, height: 1), .black)
    pixelFill(NSRect(x: cx - 6, y: cy - 6, width: 12, height: 12), yellow)
    pixelFill(NSRect(x: cx - 5, y: cy - 7, width: 10, height: 1), .black)
    pixelFill(NSRect(x: cx - 7, y: cy - 5, width: 1, height: 10), .black)
    pixelFill(NSRect(x: cx + 6, y: cy - 5, width: 1, height: 10), .black)
    pixelFill(NSRect(x: cx - 5, y: cy + 6, width: 10, height: 1), .black)
    pixelFill(NSRect(x: cx - 6, y: cy - 6, width: 1, height: 1), .black)
    pixelFill(NSRect(x: cx + 5, y: cy - 6, width: 1, height: 1), .black)
    pixelFill(NSRect(x: cx - 6, y: cy + 5, width: 1, height: 1), .black)
    pixelFill(NSRect(x: cx + 5, y: cy + 5, width: 1, height: 1), .black)

    switch expression {
    case "surprised":
        pixelFill(NSRect(x: cx - 4, y: cy - 3, width: 2, height: 3), .black)
        pixelFill(NSRect(x: cx + 2, y: cy - 3, width: 2, height: 3), .black)
        pixelFill(NSRect(x: cx - 2, y: cy + 2, width: 4, height: 3), .black)
        pixelFill(NSRect(x: cx - 1, y: cy + 3, width: 2, height: 1), yellow)
    case "dead":
        pixelFill(NSRect(x: cx - 4, y: cy - 3, width: 1, height: 1), .black)
        pixelFill(NSRect(x: cx - 2, y: cy - 1, width: 1, height: 1), .black)
        pixelFill(NSRect(x: cx - 2, y: cy - 3, width: 1, height: 1), .black)
        pixelFill(NSRect(x: cx - 4, y: cy - 1, width: 1, height: 1), .black)
        pixelFill(NSRect(x: cx + 2, y: cy - 3, width: 1, height: 1), .black)
        pixelFill(NSRect(x: cx + 4, y: cy - 1, width: 1, height: 1), .black)
        pixelFill(NSRect(x: cx + 4, y: cy - 3, width: 1, height: 1), .black)
        pixelFill(NSRect(x: cx + 2, y: cy - 1, width: 1, height: 1), .black)
        pixelFill(NSRect(x: cx - 3, y: cy + 3, width: 6, height: 1), .black)
        pixelFill(NSRect(x: cx - 4, y: cy + 4, width: 1, height: 1), .black)
        pixelFill(NSRect(x: cx + 3, y: cy + 4, width: 1, height: 1), .black)
    case "cool":
        pixelFill(NSRect(x: cx - 5, y: cy - 3, width: 4, height: 3), .black)
        pixelFill(NSRect(x: cx + 1, y: cy - 3, width: 4, height: 3), .black)
        pixelFill(NSRect(x: cx - 1, y: cy - 2, width: 2, height: 1), .black)
        pixelFill(NSRect(x: cx - 3, y: cy + 3, width: 6, height: 1), .black)
        pixelFill(NSRect(x: cx - 2, y: cy + 4, width: 4, height: 1), .black)
    default:
        pixelFill(NSRect(x: cx - 4, y: cy - 3, width: 2, height: 3), .black)
        pixelFill(NSRect(x: cx + 2, y: cy - 3, width: 2, height: 3), .black)
        pixelFill(NSRect(x: cx - 4, y: cy + 2, width: 1, height: 1), .black)
        pixelFill(NSRect(x: cx - 3, y: cy + 3, width: 6, height: 1), .black)
        pixelFill(NSRect(x: cx + 3, y: cy + 2, width: 1, height: 1), .black)
    }
}

func drawMineGlyph(in rect: NSRect, exploded: Bool) {
    if exploded {
        pixelFill(rect, .red)
    }
    let cx = floor(rect.midX)
    let cy = floor(rect.midY)
    pixelFill(NSRect(x: cx - 4, y: cy - 4, width: 8, height: 8), .black)
    pixelFill(NSRect(x: cx - 6, y: cy - 1, width: 12, height: 2), .black)
    pixelFill(NSRect(x: cx - 1, y: cy - 6, width: 2, height: 12), .black)
    pixelFill(NSRect(x: cx - 5, y: cy - 5, width: 2, height: 2), .black)
    pixelFill(NSRect(x: cx + 3, y: cy + 3, width: 2, height: 2), .black)
    pixelFill(NSRect(x: cx + 3, y: cy - 5, width: 2, height: 2), .black)
    pixelFill(NSRect(x: cx - 5, y: cy + 3, width: 2, height: 2), .black)
    pixelFill(NSRect(x: cx - 2, y: cy - 2, width: 2, height: 2), .white)
}

func drawFlagGlyph(in rect: NSRect) {
    let x = floor(rect.midX)
    let y = floor(rect.midY)
    pixelFill(NSRect(x: x, y: y - 5, width: 2, height: 10), .black)
    pixelFill(NSRect(x: x - 5, y: y + 4, width: 10, height: 2), .black)
    pixelFill(NSRect(x: x - 3, y: y + 2, width: 6, height: 2), .black)
    pixelFill(NSRect(x: x - 5, y: y - 5, width: 5, height: 5), .red)
    pixelFill(NSRect(x: x - 4, y: y - 4, width: 4, height: 1), .red)
    pixelFill(NSRect(x: x - 3, y: y - 3, width: 3, height: 1), .red)
    pixelFill(NSRect(x: x - 2, y: y - 2, width: 2, height: 1), .red)
}

func drawWrongFlagCross(in rect: NSRect) {
    for i in 0..<10 {
        pixelFill(NSRect(x: rect.minX + 3 + CGFloat(i), y: rect.minY + 3 + CGFloat(i), width: 2, height: 2), .red)
        pixelFill(NSRect(x: rect.maxX - 5 - CGFloat(i), y: rect.minY + 3 + CGFloat(i), width: 2, height: 2), .red)
    }
}

func drawQuestionGlyph(in rect: NSRect) {
    drawCenteredRetroText("?", in: rect.offsetBy(dx: 0, dy: -1), size: 12, bold: true)
}

private let numberPatterns: [Int: [String]] = [
    1: ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
    2: ["01110", "10001", "00001", "00010", "00100", "01000", "11111"],
    3: ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
    4: ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
    5: ["11111", "10000", "10000", "11110", "00001", "00001", "11110"],
    6: ["01110", "10000", "10000", "11110", "10001", "10001", "01110"],
    7: ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
    8: ["01110", "10001", "10001", "01110", "10001", "10001", "01110"]
]

func drawCellNumber(_ number: Int, in rect: NSRect, colored: Bool) {
    if colored, drawPixelAsset(
        "number-\(number)",
        in: NSRect(x: rect.minX + 3, y: rect.minY + 3, width: 10, height: 10)
    ) {
        return
    }

    let colors: [Int: NSColor] = [
        1: NSColor.blue,
        2: NSColor(calibratedRed: 0, green: 128 / 255, blue: 0, alpha: 1),
        3: NSColor.red,
        4: NSColor(calibratedRed: 0, green: 0, blue: 128 / 255, alpha: 1),
        5: NSColor(calibratedRed: 128 / 255, green: 0, blue: 0, alpha: 1),
        6: NSColor(calibratedRed: 0, green: 128 / 255, blue: 128 / 255, alpha: 1),
        7: NSColor.black,
        8: NSColor.gray
    ]
    guard let pattern = numberPatterns[number] else { return }
    let color = colored ? (colors[number] ?? .black) : .black
    let ox = floor(rect.minX + 3)
    let oy = floor(rect.minY + 1)
    for (row, line) in pattern.enumerated() {
        for (column, character) in line.enumerated() where character == "1" {
            pixelFill(
                NSRect(x: ox + CGFloat(column * 2), y: oy + CGFloat(row * 2), width: 2, height: 2),
                color
            )
        }
    }
}
