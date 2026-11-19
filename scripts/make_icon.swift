// Draws the 1024x1024 pixel-art app icon PNG. Usage: swift scripts/make_icon.swift <output.png>
import AppKit

let size: CGFloat = 1024
let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

// Same sprite and palette as Sprites.tomato in the app.
let tomato = [
    ".......kk.......",
    "......kGGk......",
    "..kkk.kGGk.kkk..",
    ".kgggkkggkkgggk.",
    "..kkggggggggkk..",
    ".krrkgkggkgkrrk.",
    ".krhhrrrrrrrrrk.",
    "krhhrrrrrrrrrrrk",
    "krhrrrrrrrrrrrrk",
    "krrrrkrrrrkrrrrk",
    "krrrrkrrrrkrrrrk",
    "krrprrrrrrrrprRk",
    ".krrrrkrrkrrrRk.",
    ".krrrrrkkrrrRRk.",
    "..kkRRRRRRRRkk..",
    "....kkkkkkkk....",
]
let palette: [Character: NSColor] = [
    "k": color(0x0D0C1A), "r": color(0xEF4A3C), "R": color(0xA42A2B), "h": color(0xFF9C8C),
    "p": color(0xFF9C8C), "g": color(0x56C96E), "G": color(0x2B7D43),
]

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
NSGraphicsContext.current?.shouldAntialias = false

// Background: indigo body (macOS icon grid: 824pt inside the 1024 canvas) with stepped corners.
let body = NSRect(x: 100, y: 100, width: 824, height: 824)
let step: CGFloat = 32
func steppedRect(_ r: NSRect, _ s: CGFloat) -> NSBezierPath {
    let p = NSBezierPath()
    p.move(to: NSPoint(x: r.minX + 3 * s, y: r.minY))
    p.line(to: NSPoint(x: r.maxX - 3 * s, y: r.minY)); p.line(to: NSPoint(x: r.maxX - 3 * s, y: r.minY + s))
    p.line(to: NSPoint(x: r.maxX - s, y: r.minY + s)); p.line(to: NSPoint(x: r.maxX - s, y: r.minY + 3 * s))
    p.line(to: NSPoint(x: r.maxX, y: r.minY + 3 * s)); p.line(to: NSPoint(x: r.maxX, y: r.maxY - 3 * s))
    p.line(to: NSPoint(x: r.maxX - s, y: r.maxY - 3 * s)); p.line(to: NSPoint(x: r.maxX - s, y: r.maxY - s))
    p.line(to: NSPoint(x: r.maxX - 3 * s, y: r.maxY - s)); p.line(to: NSPoint(x: r.maxX - 3 * s, y: r.maxY))
    p.line(to: NSPoint(x: r.minX + 3 * s, y: r.maxY)); p.line(to: NSPoint(x: r.minX + 3 * s, y: r.maxY - s))
    p.line(to: NSPoint(x: r.minX + s, y: r.maxY - s)); p.line(to: NSPoint(x: r.minX + s, y: r.maxY - 3 * s))
    p.line(to: NSPoint(x: r.minX, y: r.maxY - 3 * s)); p.line(to: NSPoint(x: r.minX, y: r.minY + 3 * s))
    p.line(to: NSPoint(x: r.minX + s, y: r.minY + 3 * s)); p.line(to: NSPoint(x: r.minX + s, y: r.minY + s))
    p.line(to: NSPoint(x: r.minX + 3 * s, y: r.minY + s))
    p.close()
    return p
}
color(0x0D0C1A).setFill()
steppedRect(body, step).fill()
color(0x2C2A52).setFill()
steppedRect(body.insetBy(dx: 16, dy: 16), step).fill()

// Stars.
let stars: [(CGFloat, CGFloat, CGFloat)] = [(200, 760, 24), (300, 840, 16), (780, 800, 24), (840, 680, 16), (180, 600, 16), (860, 300, 16)]
for (x, y, s) in stars {
    color(0xF6ECD2, s > 16 ? 0.7 : 0.4).setFill()
    NSRect(x: x, y: y, width: s, height: s).fill()
}

// Sprite: 16 px * 36 = 576. Drawn top-down, so flip the row index.
let px: CGFloat = 36
let origin = NSPoint(x: (size - 16 * px) / 2, y: (size - 16 * px) / 2 - 24)
// Ground shadow.
color(0x0D0C1A, 0.6).setFill()
NSRect(x: origin.x + 3 * px, y: origin.y - px * 1.2, width: 10 * px, height: px * 0.6).fill()
for (row, line) in tomato.enumerated() {
    for (col, ch) in line.enumerated() {
        guard let c = palette[ch] else { continue }
        c.setFill()
        NSRect(x: origin.x + CGFloat(col) * px, y: origin.y + CGFloat(15 - row) * px, width: px, height: px).fill()
    }
}

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
print("Wrote \(output)")
