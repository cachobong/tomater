import SwiftUI

/// A pixel-art image. Each character of `rows` is one pixel; "." is transparent.
struct Sprite: View {
    let rows: [String]
    let palette: [Character: Color]
    var scale: CGFloat = 3

    var body: some View {
        let columns = rows.map(\.count).max() ?? 0
        Canvas { context, _ in
            var paths: [Character: Path] = [:]
            for (y, row) in rows.enumerated() {
                for (x, pixel) in row.enumerated() where pixel != "." {
                    paths[pixel, default: Path()].addRect(CGRect(
                        x: CGFloat(x) * scale, y: CGFloat(y) * scale, width: scale, height: scale))
                }
            }
            for (key, path) in paths {
                if let color = palette[key] { context.fill(path, with: .color(color)) }
            }
        }
        .frame(width: CGFloat(columns) * scale, height: CGFloat(rows.count) * scale)
    }

    /// One-color sprite: every "x" pixel uses `color`.
    init(_ rows: [String], color: Color, scale: CGFloat = 3) {
        self.rows = rows
        self.palette = ["x": color]
        self.scale = scale
    }

    init(_ rows: [String], palette: [Character: Color], scale: CGFloat = 3) {
        self.rows = rows
        self.palette = palette
        self.scale = scale
    }
}

enum Sprites {
    static let palette: [Character: Color] = [
        "k": Pal.ink, "r": Pal.tomato, "R": Pal.tomatoDark, "h": Pal.blush, "p": Pal.blush,
        "g": Pal.leaf, "G": Pal.leafDark, "c": Pal.cream, "b": Pal.brown, "w": Pal.dim,
        "s": Pal.lagoon, "S": Pal.lagoonDark, "y": Pal.sand, "e": Pal.steel,
    ]

    static let tomato = [
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

    static let coffee = [
        "................",
        "....w...w.......",
        ".....w...w......",
        "....w...w.......",
        "................",
        ".kkkkkkkkkkk....",
        ".kbbbbbbbbbkkk..",
        ".kccccccccck.k..",
        ".kccccccccck.k..",
        ".kccccccccckkk..",
        "..kcccccccck....",
        "...kcccccck.....",
        "kkkkkkkkkkkkkk..",
        ".keeeeeeeeeek...",
        "..kkkkkkkkkk....",
        "................",
    ]

    static let island = [
        "................",
        "...gggg.gggg....",
        ".ggGGggggggGGgg.",
        "gG..gGGbGGg..Gg.",
        "g..g..bb..g...g.",
        ".......b........",
        ".......b........",
        "........b.......",
        "........b.......",
        "........b.......",
        "........b.......",
        "....yyyyyyyy....",
        "..yyyyyyyyyyyy..",
        "ssssssssssssssss",
        "sSsssSsssSsssSss",
        "ssssssssssssssss",
    ]

    static func art(for phase: Phase) -> [String] {
        switch phase {
        case .work: return tomato
        case .shortBreak: return coffee
        case .longBreak: return island
        }
    }

    static let star = [
        "...x...",
        "..xxx..",
        "xxxxxxx",
        ".xxxxx.",
        "..xxx..",
        ".xx.xx.",
        "xx...xx",
    ]

    static let play = [
        "x....",
        "xx...",
        "xxx..",
        "xxxx.",
        "xxxxx",
        "xxxx.",
        "xxx..",
        "xx...",
        "x....",
    ]

    static let pause = Array(repeating: "xx...xx", count: 7)
    static let stop = Array(repeating: "xxxxxx", count: 6)

    static let arrowLeft = ["...x", "..xx", ".xxx", "xxxx", ".xxx", "..xx", "...x"]
    static let arrowRight = ["x...", "xx..", "xxx.", "xxxx", "xxx.", "xx..", "x..."]

    static let clock = [
        "..xxxxx..",
        ".x.....x.",
        "x...x...x",
        "x...x...x",
        "x...xxx.x",
        "x.......x",
        "x.......x",
        ".x.....x.",
        "..xxxxx..",
    ]

    static let bars = [
        "......xx.",
        "......xx.",
        "...xx.xx.",
        "...xx.xx.",
        "xx.xx.xx.",
        "xx.xx.xx.",
        "xx.xx.xx.",
        "xx.xx.xx.",
        "xxxxxxxxx",
    ]

    static let gear = [
        "....x....",
        ".x.xxx.x.",
        "..xxxxx..",
        ".xx...xx.",
        "xxx...xxx",
        ".xx...xx.",
        "..xxxxx..",
        ".x.xxx.x.",
        "....x....",
    ]
}
