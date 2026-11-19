import Foundation
import Combine

enum Phase: Equatable {
    case work, shortBreak, longBreak

    var isBreak: Bool { self != .work }

    var title: String {
        switch self {
        case .work: return "Focus time"
        case .shortBreak: return "Short break"
        case .longBreak: return "Long break"
        }
    }
}

enum Screen { case timer, stats, settings }

@MainActor
final class TimerModel: ObservableObject {
    @Published private(set) var phase: Phase = .work
    @Published private(set) var remaining: TimeInterval = 0
    @Published private(set) var isRunning = false
    /// Work timers finished since the last long break.
    @Published private(set) var cycleCount = 0
    @Published private(set) var todayCount = 0
    /// Goes up each time a work timer is saved, so the stats screen can reload.
    @Published private(set) var statsVersion = 0
    @Published var screen: Screen = .timer

    let settings: AppSettings
    let store: StatsStore
    /// Called after a phase ends. The argument is the phase that ended.
    var onPhaseFinished: ((Phase) -> Void)?

    private var endDate: Date?
    private var ticker: Timer?
    /// True until the current phase is started for the first time.
    @Published private(set) var isFresh = true
    private var cancellables = Set<AnyCancellable>()

    init(settings: AppSettings, store: StatsStore) {
        self.settings = settings
        self.store = store
        remaining = duration(of: .work)
        todayCount = store.countToday()

        settings.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.settingsChanged() }
            .store(in: &cancellables)
    }

    var total: TimeInterval { duration(of: phase) }
    var progress: Double { total > 0 ? min(1, max(0, 1 - remaining / total)) : 0 }

    var timeString: String {
        let secs = Int(remaining.rounded(.up))
        return String(format: "%02d:%02d", secs / 60, secs % 60)
    }

    func duration(of phase: Phase) -> TimeInterval {
        switch phase {
        case .work: return TimeInterval(settings.workMinutes * 60)
        case .shortBreak: return TimeInterval(settings.breakMinutes * 60)
        case .longBreak: return TimeInterval(settings.longBreakMinutes * 60)
        }
    }

    func toggle() { isRunning ? pause() : start() }

    func start() {
        guard !isRunning else { return }
        todayCount = store.countToday()
        endDate = Date().addingTimeInterval(remaining)
        isRunning = true
        isFresh = false
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    func pause() {
        guard isRunning else { return }
        tick()
        stopTicker()
    }

    /// Resets to a fresh, stopped work timer.
    func stop() {
        stopTicker()
        if phase == .longBreak { cycleCount = 0 }
        phase = .work
        isFresh = true
        remaining = duration(of: .work)
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
        isRunning = false
        endDate = nil
    }

    private func tick() {
        guard let endDate else { return }
        let left = endDate.timeIntervalSinceNow
        if left <= 0 { finish() } else { remaining = left }
    }

    private func finish() {
        stopTicker()
        let finished = phase

        if finished == .work {
            store.add(Date())
            todayCount = store.countToday()
            statsVersion += 1
            cycleCount += 1
            phase = cycleCount >= settings.longBreakEvery ? .longBreak : .shortBreak
        } else {
            if finished == .longBreak { cycleCount = 0 }
            phase = .work
        }
        isFresh = true
        remaining = duration(of: phase)

        // A break always starts by itself. The next work timer starts by itself only if the user wants it.
        if phase.isBreak || settings.autostartWork { start() }
        onPhaseFinished?(finished)
    }

    private func settingsChanged() {
        if isFresh { remaining = duration(of: phase) }
    }
}
