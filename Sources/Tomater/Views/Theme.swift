import SwiftUI

/// The limited 8-bit palette.
enum Pal {
    static let bg = Color(hex: 0x1C1A33)
    static let panel = Color(hex: 0x2C2A52)
    static let panelHi = Color(hex: 0x413E72)
    static let ink = Color(hex: 0x0D0C1A)
    static let cream = Color(hex: 0xF6ECD2)
    static let dim = Color(hex: 0x8D88BC)
    static let tomato = Color(hex: 0xEF4A3C)
    static let tomatoDark = Color(hex: 0xA42A2B)
    static let blush = Color(hex: 0xFF9C8C)
    static let leaf = Color(hex: 0x56C96E)
    static let leafDark = Color(hex: 0x2B7D43)
    static let lagoon = Color(hex: 0x42BCE0)
    static let lagoonDark = Color(hex: 0x23799A)
    static let gold = Color(hex: 0xF7C948)
    static let brown = Color(hex: 0x8A5A3B)
    static let sand = Color(hex: 0xF1D58A)
    static let steel = Color(hex: 0xC9C6E6)

    static func accent(_ phase: Phase) -> Color {
        switch phase {
        case .work: return tomato
        case .shortBreak: return leaf
        case .longBreak: return lagoon
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

/// A rectangle with stepped (notched) corners.
struct PixelRect: Shape {
    var step: CGFloat = 3

    func path(in r: CGRect) -> Path {
        let s = step
        var p = Path()
        p.move(to: CGPoint(x: r.minX + s, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - s, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - s, y: r.minY + s))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + s))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - s))
        p.addLine(to: CGPoint(x: r.maxX - s, y: r.maxY - s))
        p.addLine(to: CGPoint(x: r.maxX - s, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + s, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + s, y: r.maxY - s))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY - s))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + s))
        p.addLine(to: CGPoint(x: r.minX + s, y: r.minY + s))
        p.closeSubpath()
        return p
    }
}

/// Chunky outlined block with a bevel and a hard drop shadow.
struct PixelFrame: View {
    var fill: Color
    var depth: CGFloat = 4
    private let px: CGFloat = 3

    var body: some View {
        ZStack {
            PixelRect(step: px).fill(Color.black.opacity(0.45)).offset(y: depth)
            PixelRect(step: px).fill(Pal.ink)
            PixelRect(step: px).fill(fill).padding(px)
            VStack(spacing: 0) {
                Rectangle().fill(.white.opacity(0.2)).frame(height: px)
                Spacer(minLength: 0)
                Rectangle().fill(.black.opacity(0.2)).frame(height: px)
            }
            .padding(.horizontal, px * 2)
            .padding(.vertical, px)
        }
    }
}

/// Block button that drops onto its shadow when pressed. No easing: it snaps, like a sprite.
struct PixelButtonStyle: ButtonStyle {
    var fill: Color
    var depth: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .background(PixelFrame(fill: fill, depth: pressed ? 0 : depth))
            .offset(y: pressed ? depth : 0)
            .contentShape(Rectangle())
    }
}

struct PixelPanel<Content: View>: View {
    var fill: Color = Pal.panel
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(PixelFrame(fill: fill))
    }
}

/// Text that blinks on and off, like an arcade attract screen.
struct BlinkingText: View {
    let text: String
    var color: Color = Pal.cream

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.55)) { context in
            let on = Int(context.date.timeIntervalSinceReferenceDate / 0.55) % 2 == 0
            PixelText(text, scale: 2, color: color, shadow: Pal.ink)
                .opacity(on ? 1 : 0)
        }
    }
}

/// Fixed field of pixel stars behind everything.
struct Starfield: View {
    var body: some View {
        Canvas { context, size in
            var seed: UInt64 = 7
            func random() -> CGFloat {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return CGFloat(seed >> 33) / CGFloat(UInt64(1) << 31)
            }
            for _ in 0..<46 {
                let x = (random() * size.width / 3).rounded(.down) * 3
                let y = (random() * size.height / 3).rounded(.down) * 3
                let big = random() > 0.85
                let side: CGFloat = big ? 3 : 2
                context.fill(Path(CGRect(x: x, y: y, width: side, height: side)),
                             with: .color(Pal.cream.opacity(big ? 0.45 : 0.18)))
            }
        }
    }
}
