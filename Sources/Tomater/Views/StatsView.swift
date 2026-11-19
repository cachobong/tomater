import SwiftUI

struct StatsView: View {
    @ObservedObject var model: TimerModel
    @State private var thisWeek = Array(repeating: 0, count: 7)
    @State private var lastWeek = Array(repeating: 0, count: 7)
    @State private var todayIndex = 0

    private var maxValue: Int { max(thisWeek.max() ?? 0, lastWeek.max() ?? 0, 1) }
    private var best: Int { max(thisWeek.max() ?? 0, lastWeek.max() ?? 0) }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                ScoreBox(label: "TODAY", value: model.todayCount, color: Pal.gold)
                ScoreBox(label: "WEEK", value: thisWeek.reduce(0, +), color: Pal.cream)
                ScoreBox(label: "BEST", value: best, color: Pal.tomato)
                    .help("Best day in the last two weeks")
            }

            WeekChart(title: "THIS WEEK", counts: thisWeek, maxValue: maxValue, highlight: todayIndex, color: Pal.tomato)
            WeekChart(title: "LAST WEEK", counts: lastWeek, maxValue: maxValue, highlight: nil, color: Pal.tomatoDark)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear(perform: reload)
        .onChange(of: model.statsVersion) { reload() }
    }

    private func reload() {
        let cal = Calendar.current
        let now = Date()
        let weekStart = cal.dateInterval(of: .weekOfYear, for: now)!.start
        let lastWeekStart = cal.date(byAdding: .day, value: -7, to: weekStart)!
        thisWeek = model.store.dailyCounts(weekStart: weekStart)
        lastWeek = model.store.dailyCounts(weekStart: lastWeekStart)
        todayIndex = cal.dateComponents([.day], from: weekStart, to: cal.startOfDay(for: now)).day ?? 0
    }
}

private struct ScoreBox: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            PixelText(label, color: Pal.dim)
            PixelText(String(format: "%02d", value), scale: 4, color: color, shadow: Pal.ink)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(PixelFrame(fill: Pal.panel))
    }
}

private struct WeekChart: View {
    let title: String
    let counts: [Int]
    let maxValue: Int
    let highlight: Int?
    let color: Color
    /// Number of block rows shown so far. It steps up so the bars build block by block.
    @State private var built = 0

    private let barArea: CGFloat = 54
    private static let letters = ["S", "M", "T", "W", "T", "F", "S"]

    private var dayLabels: [String] {
        let first = Calendar.current.firstWeekday - 1
        return (0..<7).map { Self.letters[(first + $0) % 7] }
    }

    var body: some View {
        PixelPanel {
            VStack(alignment: .leading, spacing: 10) {
                PixelText(title, color: Pal.cream)
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(0..<7, id: \.self) { day in
                        let count = counts[day]
                        let isToday = day == highlight
                        VStack(spacing: 5) {
                            PixelText("\(count)", color: count > 0 ? color : Pal.dim)
                            BlockBar(count: min(count, built), maxValue: maxValue, height: barArea, color: color)
                            PixelText(dayLabels[day], color: isToday ? Pal.ink : Pal.dim)
                                .frame(width: 22, height: 22)
                                .background(Rectangle().fill(isToday ? Pal.gold : .clear))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .task(id: counts) {
            built = 0
            for step in 0...maxValue {
                built = step
                try? await Task.sleep(for: .milliseconds(55))
            }
        }
    }
}

/// A bar made of stacked blocks, one block per pomodoro (blocks shrink when the scale is large).
private struct BlockBar: View {
    let count: Int
    let maxValue: Int
    let height: CGFloat
    let color: Color
    private let width: CGFloat = 18
    private let gap: CGFloat = 2

    var body: some View {
        Canvas { context, size in
            let block = max(2, ((height + gap) / CGFloat(max(maxValue, 1)) - gap).rounded(.down)).clamped(to: 2...9)
            if count == 0 {
                context.fill(Path(CGRect(x: 0, y: size.height - 3, width: width, height: 3)),
                             with: .color(Pal.panelHi))
                return
            }
            for index in 0..<count {
                let y = size.height - CGFloat(index + 1) * (block + gap) + gap
                let rect = CGRect(x: 0, y: y, width: width, height: block)
                context.fill(Path(rect), with: .color(color))
                context.fill(Path(CGRect(x: 0, y: y, width: width, height: 1)), with: .color(.white.opacity(0.25)))
            }
        }
        .frame(width: width, height: height)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self { min(max(self, range.lowerBound), range.upperBound) }
}
