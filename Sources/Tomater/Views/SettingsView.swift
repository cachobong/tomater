import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(spacing: 16) {
            PixelPanel {
                VStack(spacing: 14) {
                    NumberRow(label: "FOCUS", value: $settings.workMinutes, range: 1...180, unit: "MIN")
                    NumberRow(label: "BREAK", value: $settings.breakMinutes, range: 1...60, unit: "MIN")
                    NumberRow(label: "LONG BREAK", value: $settings.longBreakMinutes, range: 1...120, unit: "MIN")
                    NumberRow(label: "LONG EVERY", value: $settings.longBreakEvery, range: 1...8, unit: "POM")
                }
            }

            PixelPanel {
                VStack(spacing: 14) {
                    ToggleRow(label: "AUTO-START FOCUS", isOn: $settings.autostartWork)
                        .help("Start the next focus timer when a break ends")
                    ToggleRow(label: "MENU BAR TIMER", isOn: $settings.showMenuBarTimer)
                    ToggleRow(label: "POP UP WHEN DONE", isOn: $settings.interruptMe)
                        .help("Bring the window on top of all windows when a timer ends")
                    ToggleRow(label: "HIDE DOCK ICON", isOn: $settings.hideDockIcon)
                        .disabled(!settings.showMenuBarTimer)
                        .help(settings.showMenuBarTimer ? "" : "Turn on the menu bar timer first")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

private struct NumberRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String

    var body: some View {
        HStack(spacing: 8) {
            PixelText(label)
            Spacer(minLength: 4)
            arrow(Sprites.arrowLeft, enabled: value > range.lowerBound) { value = max(value - 1, range.lowerBound) }
            PixelText(String(format: "%3d", value), color: Pal.gold)
                .frame(width: 36)
            arrow(Sprites.arrowRight, enabled: value < range.upperBound) { value = min(value + 1, range.upperBound) }
            PixelText(unit, color: Pal.dim)
                .frame(width: 34, alignment: .leading)
        }
    }

    private func arrow(_ art: [String], enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Sprite(art, color: Pal.ink, scale: 2)
                .frame(width: 26, height: 26)
        }
        .buttonStyle(PixelButtonStyle(fill: Pal.tomato, depth: 3))
        .buttonRepeatBehavior(.enabled)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
    }
}

private struct ToggleRow: View {
    let label: String
    @Binding var isOn: Bool
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        HStack {
            PixelText(label, color: isEnabled ? Pal.text : Pal.dim)
            Spacer(minLength: 4)
            Button { isOn.toggle() } label: {
                PixelText(isOn ? "ON" : "OFF", color: isOn ? Pal.ink : Pal.dim)
                    .frame(width: 54, height: 26)
            }
            .buttonStyle(PixelButtonStyle(fill: isOn ? Pal.leaf : Pal.panelHi, depth: 3))
            .opacity(isEnabled ? 1 : 0.4)
            .accessibilityValue(isOn ? "On" : "Off")
        }
    }
}
