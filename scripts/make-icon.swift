// Renders the app icon (a white worm on a green squircle) into an .iconset folder.
// Usage: swift scripts/make-icon.swift <output.iconset>
import AppKit

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset"
try FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func render(pixels px: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    defer { NSGraphicsContext.restoreGraphicsState() }

    let s = CGFloat(px)

    // macOS icon grid: 824pt squircle centered on a 1024pt canvas.
    let inset = s * 100 / 1024
    let tile = NSRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    let radius = tile.width * 0.225
    let background = NSBezierPath(roundedRect: tile, xRadius: radius, yRadius: radius)
    NSGradient(
        starting: NSColor(calibratedRed: 0.42, green: 0.85, blue: 0.58, alpha: 1),
        ending: NSColor(calibratedRed: 0.09, green: 0.52, blue: 0.43, alpha: 1)
    )!.draw(in: background, angle: -90)

    // Worm body: a sine wave, same shape as the menu bar icon.
    let left = tile.minX + tile.width * 0.17
    let right = tile.maxX - tile.width * 0.25
    let midY = tile.midY
    let amplitude = tile.height * 0.12

    let body = NSBezierPath()
    body.lineWidth = tile.width * 0.11
    body.lineCapStyle = .round
    body.lineJoinStyle = .round

    var head = CGPoint.zero
    let steps = 120
    for i in 0...steps {
        let t = CGFloat(i) / CGFloat(steps)
        let point = CGPoint(
            x: left + t * (right - left),
            y: midY + amplitude * sin(t * 2 * .pi * 1.25 + 0.6)
        )
        if i == 0 { body.move(to: point) } else { body.line(to: point) }
        head = point
    }

    NSColor.white.set()
    body.stroke()

    let headRadius = body.lineWidth * 0.95
    NSBezierPath(ovalIn: NSRect(x: head.x - headRadius, y: head.y - headRadius,
                                width: headRadius * 2, height: headRadius * 2)).fill()

    // Eye
    let eyeRadius = headRadius * 0.28
    let eye = CGPoint(x: head.x + headRadius * 0.3, y: head.y + headRadius * 0.25)
    NSColor(calibratedRed: 0.07, green: 0.35, blue: 0.29, alpha: 1).set()
    NSBezierPath(ovalIn: NSRect(x: eye.x - eyeRadius, y: eye.y - eyeRadius,
                                width: eyeRadius * 2, height: eyeRadius * 2)).fill()

    return rep.representation(using: .png, properties: [:])!
}

let variants: [(name: String, pixels: Int)] = [
    ("16x16", 16), ("16x16@2x", 32),
    ("32x32", 32), ("32x32@2x", 64),
    ("128x128", 128), ("128x128@2x", 256),
    ("256x256", 256), ("256x256@2x", 512),
    ("512x512", 512), ("512x512@2x", 1024),
]

for variant in variants {
    let url = URL(fileURLWithPath: outDir).appendingPathComponent("icon_\(variant.name).png")
    try render(pixels: variant.pixels).write(to: url)
}
print("Wrote \(variants.count) icons to \(outDir)")
