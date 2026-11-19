import AppKit

/// One-color pixel icons for the menu bar. They are template images, so macOS tints them
/// black or white to match the menu bar.
enum MenuBarIcon {
    static func image(for phase: Phase) -> NSImage { icons[phase]! }

    // Each sprite keeps only the listed palette letters. Other pixels (outlines, eyes, coffee)
    // become holes, which draws the details inside the silhouette.
    private static let icons: [Phase: NSImage] = [
        .work: make(Sprites.tomato, fill: "rRhpgG"),
        .shortBreak: make(Sprites.coffee, fill: "kcew"),
        .longBreak: make(Sprites.island, fill: "gGbyS"),
    ]

    static func make(_ rows: [String], fill: String) -> NSImage {
        let lit = Set(fill)
        let image = NSImage(size: NSSize(width: 16, height: 16), flipped: true) { _ in
            NSColor.black.setFill()
            for (y, row) in rows.enumerated() {
                for (x, pixel) in row.enumerated() where lit.contains(pixel) {
                    NSRect(x: x, y: y, width: 1, height: 1).fill()
                }
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
