import AppKit

/// Draws the menu bar worm. `amplitude` 0 = lying flat (resting);
/// a positive amplitude with a changing `phase` = wiggling.
enum WiggleIcon {
    static func image(phase: CGFloat, amplitude: CGFloat) -> NSImage {
        let size = NSSize(width: 22, height: 18)
        let image = NSImage(size: size, flipped: false) { _ in
            let left: CGFloat = 3
            let right: CGFloat = size.width - 5
            let midY = size.height / 2
            let steps = 28

            let body = NSBezierPath()
            body.lineWidth = 2.6
            body.lineCapStyle = .round
            body.lineJoinStyle = .round

            var head = CGPoint.zero
            for i in 0...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let point = CGPoint(
                    x: left + t * (right - left),
                    y: midY + amplitude * sin(t * 2 * .pi * 1.25 + phase)
                )
                if i == 0 { body.move(to: point) } else { body.line(to: point) }
                head = point
            }

            NSColor.black.set()
            body.stroke()
            let r: CGFloat = 2.5
            NSBezierPath(ovalIn: NSRect(x: head.x - r, y: head.y - r, width: r * 2, height: r * 2)).fill()
            return true
        }
        image.isTemplate = true // adapts to light/dark menu bar
        return image
    }
}
