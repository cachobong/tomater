import SwiftUI

struct TimerView: View {
    @ObservedObject var model: TimerModel
    @ObservedObject var settings: AppSettings

    private var accent: Color { Pal.accent(model.phase) }

    private var stageTitle: String {
        switch model.phase {
        case .work: return "FOCUS!"
        case .shortBreak: return "BREAK"
        case .longBreak: return "BONUS BREAK"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // HUD: today's score on the left, stars toward the long break on the right.
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    PixelText("SCORE", color: Pal.dim)
                    PixelText(String(format: "%03d", model.todayCount), color: Pal.gold, shadow: Pal.shadow)
                }
                .help("Pomodoros finished today")
                Spacer()
                StarMeter(filled: model.cycleCount, total: settings.longBreakEvery)
            }
            .padding(.horizontal, 22)

            Spacer(minLength: 0)

            PixelText(stageTitle, scale: 3, color: accent, shadow: Pal.shadow)

            BobbingSprite(art: Sprites.art(for: model.phase), moving: model.isRunning)
                .padding(.top, 14)

            PixelText(model.timeString, scale: 7, color: Pal.text, shadow: Pal.shadow)
                .padding(.top, 16)

            TimeBar(remaining: model.remaining, total: model.total, accent: accent, running: model.isRunning)
                .padding(.top, 14)

            Spacer(minLength: 0)

            HStack(spacing: 20) {
                Button(action: model.stop) {
                    Sprite(Sprites.stop, color: Pal.text, scale: 3)
                        .frame(width: 52, height: 52)
                }
                .buttonStyle(PixelButtonStyle(fill: Pal.panel))
                .help("Stop and reset")

                Button(action: model.toggle) {
                    Sprite(model.isRunning ? Sprites.pause : Sprites.play, color: Pal.ink, scale: 4)
                        .offset(x: model.isRunning ? 0 : 2)
                        .frame(width: 76, height: 76)
                }
                .buttonStyle(PixelButtonStyle(fill: accent, depth: 6))
                .keyboardShortcut(.space, modifiers: [])
                .help(model.isRunning ? "Pause" : "Start")

                // Keeps the play button centered.
                Color.clear.frame(width: 52, height: 52)
            }

            Group {
                if model.isRunning {
                    PixelText(model.phase.isBreak ? "REST UP" : "STAY ON TARGET", color: Pal.dim)
                } else if model.isFresh {
                    BlinkingText(text: "PRESS START")
                } else {
                    BlinkingText(text: "PAUSED", color: Pal.gold)
                }
            }
            .frame(height: 16)
            .padding(.top, 22)
            .padding(.bottom, 22)
        }
    }
}

/// The phase sprite. It hops between two frames while the timer runs.
private struct BobbingSprite: View {
    let art: [String]
    let moving: Bool
    private let scale: CGFloat = 5

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.4, paused: !moving)) { context in
            let up = moving && Int(context.date.timeIntervalSinceReferenceDate / 0.4) % 2 == 0
            VStack(spacing: 4) {
                Sprite(art, palette: Sprites.palette, scale: scale)
                    .offset(y: up ? -scale : 0)
                // Ground shadow shrinks when the sprite hops.
                Rectangle()
                    .fill(Pal.ink.opacity(0.6))
                    .frame(width: up ? 40 : 60, height: 5)
            }
        }
    }
}

/// Health-bar style timer: blocks drain as time runs out.
private struct TimeBar: View {
    let remaining: TimeInterval
    let total: TimeInterval
    let accent: Color
    let running: Bool
    private let segments = 20

    var body: some View {
        let lit = total > 0 ? Int((remaining / total * Double(segments)).rounded(.up)) : 0
        TimelineView(.periodic(from: .now, by: 0.3)) { context in
            // The last blocks blink when time is almost up.
            let blinkOff = running && lit <= 3 && Int(context.date.timeIntervalSinceReferenceDate / 0.3) % 2 == 0
            HStack(spacing: 3) {
                ForEach(0..<segments, id: \.self) { index in
                    Rectangle()
                        .fill(index < lit ? (blinkOff ? Pal.panelHi : accent) : Pal.ink.opacity(0.6))
                        .frame(width: 11, height: 12)
                }
            }
            .padding(7)
            .background(PixelFrame(fill: Pal.panel, depth: 3))
        }
    }
}

private struct StarMeter: View {
    let filled: Int
    let total: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<max(total, 1), id: \.self) { index in
                Sprite(Sprites.star, color: index < filled ? Pal.gold : Pal.panelHi, scale: 2)
            }
        }
        .help("Pomodoros until the long break")
    }
}
