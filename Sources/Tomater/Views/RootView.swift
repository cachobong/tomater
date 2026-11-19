import SwiftUI

struct RootView: View {
    @ObservedObject var model: TimerModel
    @ObservedObject var settings: AppSettings

    private var accent: Color { Pal.accent(model.phase) }

    var body: some View {
        ZStack(alignment: .top) {
            Pal.bg
            Starfield()

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Spacer()
                    TabButton(icon: Sprites.clock, screen: .timer, current: $model.screen, accent: accent)
                    TabButton(icon: Sprites.bars, screen: .stats, current: $model.screen, accent: accent)
                    TabButton(icon: Sprites.gear, screen: .settings, current: $model.screen, accent: accent)
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .frame(height: 50, alignment: .top)

                // Screens swap instantly, like a game changing scenes.
                switch model.screen {
                case .timer: TimerView(model: model, settings: settings)
                case .stats: StatsView(model: model)
                case .settings: SettingsView(settings: settings)
                }
            }
        }
        .ignoresSafeArea()
        .frame(width: 360, height: 500)
    }
}

private struct TabButton: View {
    let icon: [String]
    let screen: Screen
    @Binding var current: Screen
    let accent: Color
    @State private var hovering = false

    private var selected: Bool { current == screen }

    var body: some View {
        Button { current = screen } label: {
            Sprite(icon, color: selected ? Pal.ink : (hovering ? Pal.text : Pal.dim), scale: 2)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(PixelButtonStyle(fill: selected ? accent : Pal.panel, depth: 3))
        .onHover { hovering = $0 }
    }
}
