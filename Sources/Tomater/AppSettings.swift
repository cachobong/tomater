import Foundation
import Combine

/// The look of the window. `auto` is day from 6:00 AM to 5:59 PM and night at other times.
enum Theme: String, CaseIterable {
    case auto, day, night
}

/// User preferences, saved in UserDefaults.
final class AppSettings: ObservableObject {
    private let defaults = UserDefaults.standard

    @Published var workMinutes: Int { didSet { defaults.set(workMinutes, forKey: Keys.work) } }
    @Published var breakMinutes: Int { didSet { defaults.set(breakMinutes, forKey: Keys.shortBreak) } }
    @Published var longBreakMinutes: Int { didSet { defaults.set(longBreakMinutes, forKey: Keys.longBreak) } }
    @Published var longBreakEvery: Int { didSet { defaults.set(longBreakEvery, forKey: Keys.longEvery) } }
    @Published var autostartWork: Bool { didSet { defaults.set(autostartWork, forKey: Keys.autostart) } }
    @Published var interruptMe: Bool { didSet { defaults.set(interruptMe, forKey: Keys.interrupt) } }
    @Published var hideDockIcon: Bool { didSet { defaults.set(hideDockIcon, forKey: Keys.hideDock) } }
    @Published var theme: Theme { didSet { defaults.set(theme.rawValue, forKey: Keys.theme) } }
    @Published var showMenuBarTimer: Bool {
        didSet {
            defaults.set(showMenuBarTimer, forKey: Keys.menuBar)
            // With no menu bar item and no dock icon the app would be unreachable.
            if !showMenuBarTimer { hideDockIcon = false }
        }
    }

    private enum Keys {
        static let work = "workMinutes"
        static let shortBreak = "breakMinutes"
        static let longBreak = "longBreakMinutes"
        static let longEvery = "longBreakEvery"
        static let autostart = "autostartWork"
        static let menuBar = "showMenuBarTimer"
        static let interrupt = "interruptMe"
        static let hideDock = "hideDockIcon"
        static let theme = "theme"
    }

    init() {
        defaults.register(defaults: [
            Keys.work: 50,
            Keys.shortBreak: 10,
            Keys.longBreak: 30,
            Keys.longEvery: 3,
            Keys.autostart: false,
            Keys.menuBar: true,
            Keys.interrupt: true,
            Keys.hideDock: true,
        ])
        workMinutes = defaults.integer(forKey: Keys.work)
        breakMinutes = defaults.integer(forKey: Keys.shortBreak)
        longBreakMinutes = defaults.integer(forKey: Keys.longBreak)
        longBreakEvery = defaults.integer(forKey: Keys.longEvery)
        autostartWork = defaults.bool(forKey: Keys.autostart)
        showMenuBarTimer = defaults.bool(forKey: Keys.menuBar)
        interruptMe = defaults.bool(forKey: Keys.interrupt)
        hideDockIcon = defaults.bool(forKey: Keys.hideDock) && defaults.bool(forKey: Keys.menuBar)
        theme = Theme(rawValue: defaults.string(forKey: Keys.theme) ?? "") ?? .auto
    }
}
